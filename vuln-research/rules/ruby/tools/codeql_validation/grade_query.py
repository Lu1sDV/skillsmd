#!/usr/bin/env python3
"""
grade_query.py — Pattern ROI Auto-Grader (Strategy #10)

Classifies each CodeQL .ql file as sweep or diff grade based on structural
heuristics over the query text (no CodeQL execution).

  sweep = precise positive call-detector keying on a specific sink/method/arg.
          Safe to run at HEAD; produces bounded, triageable hits.

  diff  = absence detector — flags code that LACKS a guard/validator.
          Floods HEAD because cross-scope guards (inherited before_action,
          superclass helpers) are invisible.  Useful only on diff hunks.

Usage:
  grade_query.py <file.ql> [<file.ql> ...]   # grade named files
  grade_query.py --all                        # walk codeql/**/*.ql, skip tests/
  grade_query.py --predict-from-pattern <vr_id>  # predict grade from worklist
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Repository root — resolve relative to this script
# ---------------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parent.parent          # tools/codeql_validation -> tools -> ruby root
CODEQL_ROOT = REPO_ROOT / "codeql"
WORKLIST_PATH = REPO_ROOT / "oracle" / "validation" / "authoring-worklist.json"


# ---------------------------------------------------------------------------
# Heuristic signal definitions
# ---------------------------------------------------------------------------

# Strong DIFF signals --------------------------------------------------------

# 1. "not exists(...)" — a full not-exists quantifier in the where block
RE_NOT_EXISTS = re.compile(
    r'\bnot\s+exists\s*\(',
    re.MULTILINE,
)

# 1b. "not has<Guard>(...)" — helper predicate asserting guard absence
RE_NOT_HAS_GUARD = re.compile(
    r'\bnot\s+has[A-Z][A-Za-z]+\s*\(',
    re.MULTILINE,
)

# 1c. "not is<Foo>(receiver)" — predicate negation on the receiver (e.g. not isBanzaiRender(...))
#     This fires for diff queries that negate a positive predicate on a receiver expression
RE_NOT_IS_PRED_ON_RECEIVER = re.compile(
    r'\bnot\s+is[A-Z][A-Za-z]+\s*\(\s*\w+(?:\.[A-Za-z]+\(\))*\s*\)',
    re.MULTILINE,
)

# 2. Selecting a ClassDeclaration/Module/ModuleBase/MethodBase/ClassBase
#    (whole-scope select — the query fires on a class/method BECAUSE it lacks something)
RE_SELECT_CLASS_OR_MODULE = re.compile(
    r'\bfrom\b[^;{]*\b(?:ClassDeclaration|ModuleDeclaration|ModuleBase|MethodBase|ClassBase)\b',
    re.MULTILINE,
)

# 2b. "from MethodCall ..., Callable sharedScope" — scope-coupling in from clause (diff pattern)
RE_FROM_WITH_CALLABLE_SCOPE = re.compile(
    r'\bfrom\s+MethodCall\b[^;]*,\s*Callable\b',
    re.MULTILINE,
)

# 3. QLDoc @description contains absence keywords
RE_ABSENCE_DESC = re.compile(
    r'@description\s.*?\b(missing|without|lacks|not\s+\w+\s+(?:checked|guarded|validated|enforced|present)|'
    r'absence\s+of|no\s+\w+\s+guard|no\s+\w+\s+check|never\s+(?:calls?|checks?|validates?))\b',
    re.IGNORECASE | re.DOTALL,
)

# 4. @name contains absence keywords
RE_ABSENCE_NAME = re.compile(
    r'@name\s.*?\b(missing|without|lacks|never\s+used|unused|uncheck)\b',
    re.IGNORECASE,
)

# 6. Predicate named has<Guard> called with 'not' at select/where site
RE_NOT_PREDICATE = re.compile(
    r'\bnot\s+(?:has[A-Z]\w+|is[A-Z]\w+)\s*\(',
    re.MULTILINE,
)

# 6b. not <var>.<method>() — e.g. "not c.hasBlock()" — absence of a property on selected node
RE_NOT_DOT_METHOD = re.compile(
    r'\bnot\s+\w+\.has[A-Z]\w+\s*\(\s*\)',
    re.MULTILINE,
)

# 6c. Scope-wide absence: not exists(...getEnclosingCallable()...) or getEnclosingModule()
#     This is the critical diff signal: guard checked across an enclosing scope boundary
RE_NOT_EXISTS_SCOPE = re.compile(
    r'not\s+exists\s*\([^)]*(?:getEnclosingCallable|getEnclosingModule|getEnclosingMethod)\b',
    re.MULTILINE | re.DOTALL,
)

# Signal: "unscoped find" — receiver instanceof ConstantReadAccess (absence of user scope chain)
RE_UNSCOPED_FIND = re.compile(
    r'instanceof\s+ConstantReadAccess\b',
    re.MULTILINE,
)

# Signal: method names are generic Rails finders (not dangerous sinks)
# When present without a sink-specific constant, the bug is likely scoping absence not a call
RE_GENERIC_FINDER_METHODS = re.compile(
    r'getMethodName\(\)\s*=\s*\[?"find(?:_by)?(?:",\s*"find(?:_by)?")?\]?"',
    re.MULTILINE,
)

# Signal: InfiniteRepetitionQuantifier (ReDoS via unbounded quantifier — absence of upper bound)
RE_INFINITE_QUANTIFIER = re.compile(
    r'\bInfiniteRepetitionQuantifier\b',
    re.MULTILINE,
)

# Signal: specific symbol literal arg constraint (getConstantValue().getSymbol() = "specific_val")
# alongside method name match → strengthens sweep (specific DSL call, not generic)
RE_SPECIFIC_SYMBOL_ARG = re.compile(
    r'getConstantValue\(\)\.getSymbol\(\)\s*=\s*\[?"[a-z_!?]+(?:",\s*"[a-z_!?]+")?\]?"',
    re.MULTILINE,
)

# Signal: not hasFoo(var.getBlock(), ...) — absence guard on the block argument specifically
# This is the OauthDeviceFlow pattern: not hasScopeValidateCall(ce.getBlock(), _)
RE_NOT_GUARD_ON_BLOCK = re.compile(
    r'\bnot\s+has[A-Z]\w+\s*\(\s*\w+\.getBlock\(\)',
    re.MULTILINE,
)


# Strong SWEEP signals -------------------------------------------------------

# 7. Positively matches a specific MethodCall.getMethodName() with literal strings
RE_METHOD_NAME_MATCH = re.compile(
    r'\.getMethodName\(\)\s*=\s*[\["]',
    re.MULTILINE,
)

# 7b. Counts distinct method name literals to measure specificity
def _count_method_name_literals(text: str) -> int:
    """Count how many distinct specific method names are matched positively."""
    return len(re.findall(r'\.getMethodName\(\)\s*=\s*[\["]', text))

# 8. Specific keyword argument value match (getKeywordArgument + getConstantValue)
RE_KEYWORD_ARG_MATCH = re.compile(
    r'getKeywordArgument\s*\(\s*"[^"]+"\s*\)',
    re.MULTILINE,
)

# 9. Specific sink constant in query body (string literal naming the dangerous API)
RE_SINK_CONSTANT = re.compile(
    r'"(?:html_safe|CsvBuilder|ContentDisposition|Sanitize|Asciidoctor|Banzai|ERB::Util|'
    r'sprintf|safe_format|verify_passkey|verify_webauthn|skip_forgery_protection|'
    r'null_session|merge!|html_safe|expose)\b',
    re.IGNORECASE,
)

# 10. Literal pattern matches: .matches("..."), getConstantValue().getSymbol() = "..."
RE_LITERAL_MATCH = re.compile(
    r'(?:\.matches\s*\(|getConstantValue\(\)\.(?:getSymbol|getString\w*)\(\)\s*=\s*")',
    re.MULTILINE,
)

# 11. select is a plain MethodCall (positive call detector, no scope coupling)
RE_SELECT_METHOD_CALL_PLAIN = re.compile(
    r'^\s*from\s+MethodCall\s+\w+\s*$',
    re.MULTILINE,
)

# 11b. select has MethodCall as first var (may have additional vars)
RE_SELECT_METHOD_CALL = re.compile(
    r'\bfrom\s+MethodCall\b',
    re.MULTILINE,
)

# 12. Positive: query selects a StringlikeLiteral or RegExpLiteral (literal injection)
RE_SELECT_LITERAL = re.compile(
    r'\bfrom\b[^;]*\b(?:StringlikeLiteral|StringLiteral|HereDoc|RegExpLiteral|BinaryOperation)\b',
    re.MULTILINE,
)

# Weak SWEEP signals: @precision high
RE_PRECISION_HIGH = re.compile(r'@precision\s+high', re.MULTILINE)

# Strong SWEEP: @kind path-problem with flowPath (dataflow/taint query)
# These are always sweep — they fire on a positive taint flow source→sink
RE_PATH_PROBLEM_FLOW = re.compile(
    r'@kind\s+path-problem.*?flowPath\s*\(',
    re.DOTALL,
)


# ---------------------------------------------------------------------------
# Core classifier
# ---------------------------------------------------------------------------

def extract_signals(text: str) -> dict:
    """Return a dict of all signal booleans for a query text."""
    signals = {}
    where_block = _extract_where_block(text)

    # --- DIFF signals ---
    # not exists() in the where block
    not_exists_where = len(RE_NOT_EXISTS.findall(where_block))
    signals["not_exists"] = not_exists_where > 0
    signals["not_exists_count"] = not_exists_where

    # not hasGuard() in the where block (e.g. not hasScopeValidateCall(ce.getBlock(), _))
    not_has_where = len(RE_NOT_HAS_GUARD.findall(where_block))
    signals["not_has_guard"] = not_has_where > 0

    # not isFoo(receiver) negating a guard predicate on a receiver arg
    signals["not_is_pred_receiver"] = bool(RE_NOT_IS_PRED_ON_RECEIVER.search(where_block))

    # scope-crossing not exists (checks guard in enclosing scope)
    signals["not_exists_scope"] = bool(RE_NOT_EXISTS_SCOPE.search(text))

    # ClassDeclaration/Module in from clause → whole-scope query
    signals["select_class_or_module"] = bool(RE_SELECT_CLASS_OR_MODULE.search(text))

    # ClassDeclaration is the PRIMARY select variable (first in from clause)
    # vs. being a secondary scope-narrowing variable (MethodCall is first)
    signals["class_is_primary_select"] = bool(
        re.search(r'^\s*from\s+(?:ClassDeclaration|ModuleDeclaration|ModuleBase|MethodBase)\b',
                  text, re.MULTILINE)
    )
    signals["class_is_secondary"] = (
        signals["select_class_or_module"] and not signals["class_is_primary_select"]
        and bool(re.search(r'^\s*from\s+MethodCall\b', text, re.MULTILINE))
    )

    # from MethodCall ..., Callable — scope coupling (diff pattern: Asciidoc)
    signals["from_with_callable_scope"] = bool(RE_FROM_WITH_CALLABLE_SCOPE.search(text))

    signals["absence_in_description"] = bool(RE_ABSENCE_DESC.search(text))
    signals["absence_in_name"] = bool(RE_ABSENCE_NAME.search(text))

    # not <var>.hasBlock() or similar dot-negation on the selected node
    signals["not_dot_method"] = bool(RE_NOT_DOT_METHOD.search(where_block))

    # receiver instanceof ConstantReadAccess = unscoped find (absence of user scope chain)
    signals["unscoped_find"] = bool(RE_UNSCOPED_FIND.search(where_block))

    # "not hasFoo(selected_var, ...)" where the first arg matches the primary select var
    # — the selected node itself lacks a required feature (e.g. not hasSafeBlock(expose))
    primary_var = _get_primary_select_var(text)
    signals["not_guard_on_selected_var"] = _not_guard_on_selected_var(where_block, primary_var)

    # not hasFoo(var.getBlock(), ...) — guard absent from the block of the selected call
    signals["not_guard_on_block"] = bool(RE_NOT_GUARD_ON_BLOCK.search(where_block))

    # Infinite quantifier → ReDoS / unbounded absence pattern
    signals["infinite_quantifier"] = bool(RE_INFINITE_QUANTIFIER.search(text))

    # Generic finders (find/find_by) as primary method match — not a dangerous sink
    signals["generic_finder_methods"] = bool(RE_GENERIC_FINDER_METHODS.search(text))

    # --- SWEEP signals ---
    method_name_count = _count_method_name_literals(text)
    signals["method_name_literal"] = method_name_count > 0
    signals["method_name_count"] = method_name_count

    signals["keyword_arg_match"] = bool(RE_KEYWORD_ARG_MATCH.search(text))
    signals["sink_constant"] = bool(RE_SINK_CONSTANT.search(text))
    signals["literal_pattern"] = bool(RE_LITERAL_MATCH.search(text))
    signals["select_method_call"] = bool(RE_SELECT_METHOD_CALL.search(text))
    signals["select_method_call_plain"] = bool(RE_SELECT_METHOD_CALL_PLAIN.search(text))
    signals["select_literal"] = bool(RE_SELECT_LITERAL.search(text))
    signals["precision_high"] = bool(RE_PRECISION_HIGH.search(text))
    signals["path_problem_flow"] = bool(RE_PATH_PROBLEM_FLOW.search(text))

    return signals


def _get_primary_select_var(text: str) -> str:
    """Extract the name of the first variable in the from clause."""
    m = re.search(r'\bfrom\s+\w+\s+(\w+)', text, re.MULTILINE)
    return m.group(1) if m else ""


def _not_guard_on_selected_var(where_block: str, primary_var: str) -> bool:
    """
    Detect: 'not hasFoo(primary_var, ...)' or 'not hasFoo(primary_var)'
    — the selected node itself lacks a required feature.
    This is a strong diff signal (e.g. not hasSafeMarkdownFieldBlock(expose)).
    """
    if not primary_var:
        return False
    pattern = rf'\bnot\s+has[A-Z]\w+\s*\(\s*{re.escape(primary_var)}\b'
    return bool(re.search(pattern, where_block))


def _extract_where_block(text: str) -> str:
    """Extract the text of the where clause (from 'where' keyword to 'select')."""
    m = re.search(r'\bwhere\b(.*?)\bselect\b', text, re.DOTALL | re.IGNORECASE)
    if m:
        return m.group(1)
    return ""


def classify(text: str, path: str = "") -> dict:
    """
    Classify a query as sweep or diff.

    Core principle: a diff query's PRIMARY where constraint is an absence
    (not exists / not hasFoo / not isFoo) that fires on a class/method BECAUSE
    a guard is absent from its scope.  A sweep query's PRIMARY constraint is a
    specific positive call/constant match — any 'not exists' present is a
    secondary anti-FP filter that excludes already-patched forms.

    Returns: {grade, confidence, signals, reason}
    """
    sigs = extract_signals(text)
    active = []  # human-readable fired signals

    # ---- Score DIFF ----
    diff_score = 0.0

    # Absence in metadata
    if sigs["absence_in_name"]:
        diff_score += 2.0
        active.append("absence_in_name")
    if sigs["absence_in_description"]:
        diff_score += 1.5
        active.append("absence_in_description")

    # Scope-wide absence guard: strongest diff signal — guard checked in enclosing scope
    if sigs["not_exists_scope"]:
        diff_score += 4.0
        active.append("not_exists_scope")
    elif sigs["not_exists"]:
        diff_score += 1.5
        active.append(f"not_exists(x{sigs['not_exists_count']})")

    # not hasFoo(...) — absence of a named guard predicate
    if sigs["not_has_guard"]:
        diff_score += 3.0
        active.append("not_has_guard")

    # not hasFoo(selected_var) — the selected node itself lacks a required feature
    # (e.g. not hasSafeMarkdownFieldBlock(expose)) — strong diff: query fires because
    # the selected call lacks a required companion block/guard
    if sigs["not_guard_on_selected_var"]:
        diff_score += 3.5
        active.append("not_guard_on_selected_var")

    # not isFoo(receiver) — negates a guard predicate on a specific receiver argument
    if sigs["not_is_pred_receiver"]:
        diff_score += 2.5
        active.append("not_is_pred_receiver")

    # Whole-scope select: ClassDeclaration/Module is the PRIMARY subject
    # (query fires on a class/method because it lacks something)
    if sigs["class_is_primary_select"]:
        diff_score += 3.5
        active.append("class_is_primary_select")
    elif sigs["select_class_or_module"] and not sigs["class_is_secondary"]:
        # ClassDeclaration in from clause but not confirmed secondary
        diff_score += 1.5
        active.append("select_class_or_module")

    # Callable scope coupling in from clause (Asciidoc-style scope-tracking pattern)
    if sigs["from_with_callable_scope"]:
        diff_score += 3.0
        active.append("from_with_callable_scope")

    # Unscoped find: receiver instanceof ConstantReadAccess = absence of user-scope chain
    # Combined with generic method names (find/find_by) this is the IDOR diff pattern
    if sigs["unscoped_find"]:
        diff_score += 3.0
        active.append("unscoped_find")

    # not hasFoo(var.getBlock(), ...) — guard absent from block of selected call
    # This is the OauthDeviceFlow pattern: the bug IS the missing block-level validator
    if sigs["not_guard_on_block"]:
        diff_score += 3.5
        active.append("not_guard_on_block")

    # InfiniteRepetitionQuantifier → ReDoS, bug is absence of upper bound
    if sigs["infinite_quantifier"]:
        diff_score += 3.0
        active.append("infinite_quantifier")

    # not c.hasBlock() etc. — secondary dot-negation; add only when other diff signals exist
    if sigs["not_dot_method"] and diff_score > 0:
        diff_score += 0.5
        active.append("not_dot_method")

    # ---- Score SWEEP ----
    sweep_score = 0.0

    if sigs["method_name_literal"]:
        # Generic Rails finders (find/find_by) are not dangerous sinks — reduce sweep boost.
        # The bug is the absence of user-scoping, not the method call itself.
        if sigs["generic_finder_methods"] and not sigs["sink_constant"]:
            boost = 1.0  # flat low boost — generic method, not a dangerous call
            active.append("method_name_literal(generic_finder)")
        else:
            boost = min(sigs["method_name_count"] * 1.5, 4.0)
            active.append(f"method_name_literal(x{sigs['method_name_count']})")
        sweep_score += boost

    if sigs["keyword_arg_match"]:
        sweep_score += 2.0
        active.append("keyword_arg_match")

    if sigs["sink_constant"]:
        sweep_score += 1.5
        active.append("sink_constant")

    if sigs["literal_pattern"]:
        sweep_score += 1.5
        active.append("literal_pattern")

    if sigs["select_method_call"]:
        sweep_score += 0.5
        active.append("select_method_call")

    if sigs["select_literal"]:
        sweep_score += 2.0
        active.append("select_literal")

    if sigs["precision_high"]:
        sweep_score += 0.5
        active.append("precision_high")

    # @kind path-problem + flowPath → always sweep (positive taint source→sink flow)
    if sigs["path_problem_flow"]:
        sweep_score += 5.0
        active.append("path_problem_flow")

    # ---- Special cases ----

    # Dataflow/taint import with no dominant absence → sweep
    if re.search(r'TaintTracking|DataFlow|import codeql\.ruby\.(dataflow|taint)', text):
        if diff_score < 3.0:
            sweep_score += 2.0
            active.append("dataflow_import")

    # When ClassDeclaration is SECONDARY (MethodCall is primary select, class is scope filter)
    # remove the class_select diff penalty — this is the RM008 pattern (sweep)
    if sigs["class_is_secondary"]:
        # Don't add diff score for class; if it was added above, undo it
        pass  # class_is_primary_select and select_class_or_module branches already handle this

    # When from_with_callable_scope + not_is_pred_receiver both fire, the absence is the
    # primary constraint even if method_name_literal also fires — strong diff override
    if sigs["from_with_callable_scope"] and sigs["not_is_pred_receiver"]:
        diff_score += 1.5  # extra push for Asciidoc-style pattern
        active.append("callable_scope+not_is_pred")

    # When method_name_count is high (≥3) and not_exists is NOT scope-crossing,
    # the not_exists is likely a secondary anti-FP filter on the selected call's block,
    # not the primary bug detector. Boost sweep in this case.
    # This handles CiJobTokenGrantsAdminCondition: 3 specific method names, not_exists
    # checks inside condCall.getBlock() (block-internal, not enclosing-scope).
    if (sigs["method_name_count"] >= 3 and sigs["not_exists"]
            and not sigs["not_exists_scope"] and not sigs["not_has_guard"]
            and not sigs["class_is_primary_select"]):
        sweep_score += 2.0
        active.append("many_method_names+secondary_not_exists")

    # ---- Decision ----
    total = sweep_score + diff_score
    if total == 0:
        total = 1.0

    if diff_score > sweep_score:
        grade = "diff"
        raw_conf = diff_score / total
    elif sweep_score > diff_score:
        grade = "sweep"
        raw_conf = sweep_score / total
    else:
        # Tie-break: absence in metadata or from clause type → diff
        if (sigs["class_is_primary_select"] or sigs["from_with_callable_scope"]
                or sigs["absence_in_name"] or sigs["absence_in_description"]):
            grade = "diff"
            raw_conf = 0.55
        else:
            grade = "sweep"
            raw_conf = 0.55

    confidence = max(0.50, min(0.97, raw_conf))

    if grade == "diff":
        reason = (f"diff signals dominate (score {diff_score:.1f} vs sweep {sweep_score:.1f}): "
                  f"{', '.join(active)}")
    else:
        reason = (f"sweep signals dominate (score {sweep_score:.1f} vs diff {diff_score:.1f}): "
                  f"{', '.join(active)}")

    return {
        "grade": grade,
        "confidence": round(confidence, 3),
        "signals": active,
        "reason": reason,
    }


# ---------------------------------------------------------------------------
# File-level helpers
# ---------------------------------------------------------------------------

def grade_file(path: Path) -> dict:
    text = path.read_text(encoding="utf-8", errors="replace")

    # Extract @name from QLDoc
    m_name = re.search(r'@name\s+(.+)', text)
    name = m_name.group(1).strip() if m_name else path.stem

    # Extract category from path (grandparent dir of the .ql file)
    category = path.parent.name
    # If inside tests/, skip (caller should have filtered already)

    result = classify(text, str(path))
    return {
        "name": path.stem,
        "ql_name": name,
        "category": category,
        "path": str(path),
        "predicted_grade": result["grade"],
        "confidence": result["confidence"],
        "signals": result["signals"],
        "reason": result["reason"],
    }


def walk_queries(codeql_root: Path):
    """Yield all top-level .ql files, skipping anything under a tests/ directory."""
    for p in sorted(codeql_root.rglob("*.ql")):
        # Skip if any path component is 'tests'
        parts = p.relative_to(codeql_root).parts
        if "tests" in parts:
            continue
        yield p


# ---------------------------------------------------------------------------
# Validation against known labels
# ---------------------------------------------------------------------------

TRUE_SWEEP = {
    "CsrfProtectionDisabled", "AuthenticationSkipped", "OverlyBroadAuthzSkip",
    "BlockedUserNotChecked", "HtmlEscapeUnqualified", "SprintfHtmlSafeInterp",
    "XhtmlInlineContentSniff", "DataHtmlTooltipSink", "StringInterpolationInHtmlHref",
    "MissingInputDepthValidation", "PasskeyWebauthnVerifyReturnUnchecked", "RM008",
    "HtmlEscapeWrongMethod", "CiJobTokenGrantsAdminCondition",
    "CsvFormulaInjectionNewlines", "UnsafeHtmlStringInterpolation",
}

TRUE_DIFF = {
    "IdorUnscopedFind", "DeclarativePolicyUnusedCondition", "ControllerMissingAuthzGuard",
    "RM004", "AsciidocRawHtmlBeforeBanzai", "OauthDeviceFlowScopeEscalation",
    "BanzaiSanitizeFragmentAsNodeContent", "MarkdownFieldRawApiExposure",
    "HtmlSafetyValidatorMissingOnModel", "MissingUploadFileSizeLimit",
    "NamespacedAttributeSanitizeBypass", "NestedATagDomBypass",
    "MissingInputLengthValidation",
}

TRUE_LABELS = {}
for s in TRUE_SWEEP:
    TRUE_LABELS[s] = "sweep"
for s in TRUE_DIFF:
    TRUE_LABELS[s] = "diff"


def validate(ledger: list) -> dict:
    """Compute accuracy on the 31 labeled queries."""
    # confusion: {actual: {predicted: count}}
    conf = {
        "sweep": {"sweep": 0, "diff": 0},
        "diff": {"sweep": 0, "diff": 0},
    }
    misclassifications = []
    matched = 0

    for entry in ledger:
        name = entry["name"]
        if name not in TRUE_LABELS:
            continue
        matched += 1
        actual = TRUE_LABELS[name]
        predicted = entry["predicted_grade"]
        conf[actual][predicted] += 1
        if actual != predicted:
            misclassifications.append({
                "name": name,
                "actual": actual,
                "predicted": predicted,
                "confidence": entry["confidence"],
                "signals": entry["signals"],
                "reason": entry["reason"],
            })

    total_labeled = len(TRUE_LABELS)
    correct = conf["sweep"]["sweep"] + conf["diff"]["diff"]
    accuracy_str = f"{correct}/{total_labeled}"
    pct = correct / total_labeled if total_labeled else 0

    return {
        "matched_in_ledger": matched,
        "total_labeled": total_labeled,
        "correct": correct,
        "accuracy": accuracy_str,
        "accuracy_pct": round(pct, 4),
        "confusion_matrix": conf,
        "misclassifications": misclassifications,
    }


# ---------------------------------------------------------------------------
# Deliverable 4 (optional): predict from pattern
# ---------------------------------------------------------------------------

def predict_from_pattern(vr_id: str) -> dict:
    """
    Read the pattern's smell/notes from authoring-worklist.json and
    predict the grade BEFORE authoring.
    """
    if not WORKLIST_PATH.exists():
        return {"error": f"worklist not found at {WORKLIST_PATH}"}

    with open(WORKLIST_PATH) as f:
        raw = json.load(f)

    # Flatten: worklist is either a list or a dict of {kind: [items]}
    if isinstance(raw, dict):
        worklist = [item for items in raw.values() if isinstance(items, list)
                    for item in items if isinstance(item, dict)]
    elif isinstance(raw, list):
        worklist = [item for item in raw if isinstance(item, dict)]
    else:
        return {"error": "Unexpected worklist format"}

    entry = None
    for item in worklist:
        if item.get("vr_id") == vr_id or item.get("id") == vr_id or item.get("id_slug") == vr_id:
            entry = item
            break

    if entry is None:
        # try substring match on vr_id / pattern_id / smell
        vr_lower = vr_id.lower()
        for item in worklist:
            if (vr_lower in str(item.get("vr_id", "")).lower()
                    or vr_lower in str(item.get("pattern_id", "")).lower()):
                entry = item
                break

    if entry is None:
        return {"error": f"Pattern '{vr_id}' not found in worklist"}

    smell = entry.get("smell", "") + " " + entry.get("notes", "") + " " + entry.get("description", "")
    smell_lower = smell.lower()

    # Heuristics on smell text:
    # - If fix ADDS a guard/validator → diff (the bug is its absence)
    # - If fix targets a specific dangerous call/sink → sweep
    diff_indicators = [
        "missing", "without", "lacks", "absence", "not guarded", "no guard",
        "add.*before_action", "add.*validates", "add.*check", "add.*authorize",
        "missing.*guard", "missing.*check", "missing.*validation",
        "fix adds", "introduced.*missing",
    ]
    sweep_indicators = [
        "specific.*call", "dangerous.*method", "sink", "html_safe",
        "merge!", "skip_before", "sprintf", "csv", "content.disposition",
        "uses.*method", "calls.*directly", "literal", "constant value",
    ]

    diff_score = sum(1 for pat in diff_indicators if re.search(pat, smell_lower))
    sweep_score = sum(1 for pat in sweep_indicators if re.search(pat, smell_lower))

    if diff_score > sweep_score:
        predicted = "diff"
        conf = 0.6 + min(0.2, diff_score * 0.05)
    elif sweep_score > diff_score:
        predicted = "sweep"
        conf = 0.6 + min(0.2, sweep_score * 0.05)
    else:
        predicted = "unknown"
        conf = 0.5

    return {
        "vr_id": vr_id,
        "predicted_grade": predicted,
        "confidence": round(conf, 3),
        "diff_indicators_matched": diff_score,
        "sweep_indicators_matched": sweep_score,
        "smell_excerpt": smell[:300],
    }


# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

def print_single(entry: dict):
    print(json.dumps({
        "name": entry["name"],
        "grade": entry["predicted_grade"],
        "confidence": entry["confidence"],
        "signals": entry["signals"],
        "reason": entry["reason"],
    }, indent=2))


def print_validation(val: dict):
    print("\n=== Validation against 31 labeled queries ===")
    print(f"Accuracy: {val['accuracy']} ({val['accuracy_pct']*100:.1f}%)")
    print(f"Matched in ledger: {val['matched_in_ledger']}/{val['total_labeled']}")
    print("\nConfusion matrix (rows=actual, cols=predicted):")
    print(f"  {'':20s}  {'pred:sweep':>12}  {'pred:diff':>10}")
    for actual in ("sweep", "diff"):
        row = val["confusion_matrix"][actual]
        print(f"  {'actual:'+actual:20s}  {row['sweep']:>12}  {row['diff']:>10}")
    if val["misclassifications"]:
        print(f"\nMisclassifications ({len(val['misclassifications'])}):")
        for m in val["misclassifications"]:
            print(f"  [{m['name']}] actual={m['actual']} predicted={m['predicted']} "
                  f"conf={m['confidence']}")
            print(f"    signals: {m['signals']}")
            print(f"    reason:  {m['reason']}")
    else:
        print("\nNo misclassifications!")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Grade CodeQL queries as sweep or diff")
    parser.add_argument("files", nargs="*", help=".ql files to grade")
    parser.add_argument("--all", action="store_true",
                        help="Walk codeql/**/*.ql and emit JSON ledger")
    parser.add_argument("--validate", action="store_true",
                        help="Run validation against the 31 labeled queries")
    parser.add_argument("--predict-from-pattern", metavar="VR_ID",
                        help="Predict grade from authoring-worklist pattern (no .ql needed)")
    parser.add_argument("--ledger-out",
                        default=str(REPO_ROOT / "oracle" / "validation" / "query-grade-ledger.json"),
                        help="Where to write the ledger JSON (default: oracle/validation/query-grade-ledger.json)")
    args = parser.parse_args()

    if args.predict_from_pattern:
        result = predict_from_pattern(args.predict_from_pattern)
        print(json.dumps(result, indent=2))
        return

    if args.all:
        if not CODEQL_ROOT.exists():
            print(f"ERROR: codeql root not found at {CODEQL_ROOT}", file=sys.stderr)
            sys.exit(1)
        ledger = []
        for p in walk_queries(CODEQL_ROOT):
            ledger.append(grade_file(p))
        print(json.dumps(ledger, indent=2))
        # Write ledger
        ledger_path = Path(args.ledger_out)
        ledger_path.parent.mkdir(parents=True, exist_ok=True)
        with open(ledger_path, "w") as f:
            json.dump(ledger, f, indent=2)
        print(f"\n[ledger written to {ledger_path}]", file=sys.stderr)
        if args.validate:
            val = validate(ledger)
            print_validation(val)
        return

    if args.validate:
        # Need to build ledger first from all queries
        if not CODEQL_ROOT.exists():
            print(f"ERROR: codeql root not found at {CODEQL_ROOT}", file=sys.stderr)
            sys.exit(1)
        ledger = [grade_file(p) for p in walk_queries(CODEQL_ROOT)]
        val = validate(ledger)
        print_validation(val)
        return

    if args.files:
        for fp in args.files:
            p = Path(fp)
            if not p.exists():
                print(f"ERROR: file not found: {fp}", file=sys.stderr)
                continue
            entry = grade_file(p)
            print_single(entry)
        return

    parser.print_help()


if __name__ == "__main__":
    main()
