export const meta = {
  name: 'author-rules',
  description: 'Create-query stage: author Semgrep detection rules from gold GitLab fixes per uncovered category (Fable), syntax-validate only (full --test deferred)',
  phases: [
    { title: 'Author', detail: 'one Fable agent per category: study gold diffs -> author semgrep rules + BAD/GOOD fixtures -> semgrep --validate', model: 'fable' },
  ],
}

// 4 highest-gap categories with ZERO/low existing rule coverage (from authoring-gap.json)
const CATS = [
  { key: 'redos',            ord: '12', gold: 41 },
  { key: 'ssrf',             ord: '05', gold: 12 },
  { key: 'mass-assignment',  ord: '11', gold: 9  },
  { key: 'path-traversal',   ord: '07', gold: 16 },
]
const ROOT = '/home/x/Personal_Projects/skillsmd/vuln-research/rules/ruby'

const SCHEMA = {
  type: 'object',
  additionalProperties: false,
  required: ['category', 'rules_created', 'rules'],
  properties: {
    category: { type: 'string' },
    rules_created: { type: 'integer' },
    rules: {
      type: 'array',
      items: {
        type: 'object',
        additionalProperties: false,
        required: ['id', 'vr_id', 'yaml_path', 'fixture_path', 'pattern_summary', 'validate_ok', 'expected_head_breadth'],
        properties: {
          id: { type: 'string' },
          vr_id: { type: 'string' },
          yaml_path: { type: 'string' },
          fixture_path: { type: 'string' },
          pattern_summary: { type: 'string', description: 'the vulnerable shape this matches + the fixed shape it must stay silent on' },
          source_shas: { type: 'array', items: { type: 'string' }, description: 'gold fix sha12(s) this pattern was derived from' },
          validate_ok: { type: 'boolean', description: 'did `semgrep --validate` pass on this rule' },
          expected_head_breadth: { type: 'string', description: 'how broadly you expect this to match at GitLab HEAD (precise/moderate/broad) + why' },
        },
      },
    },
    notes: { type: 'string' },
  },
}

function prompt(c) {
  return `You author NEW Semgrep detection rules for the GitLab variant-discovery corpus, for category "${c.key}". You derive them from REAL gold-tier GitLab security fixes (diff-verified). Work in ${ROOT}.

GOAL: turn the recurring vulnerable code shape (the BEFORE side of these fixes) into precise Semgrep rules that will find NEW variants of the same bug class at GitLab HEAD — without flooding false positives.

STEP 1 — study the gold fixes for this category:
  cd ${ROOT}
  python3 -c "import json;d=json.load(open('oracle/validation/authoring/gold-${c.key}.json'));print('count',len(d));[print('---',x['sha'][:12],'|',x.get('sink'),'|',x.get('subject','')[:70]) for x in d]"
That prints the sink + subject for all ${c.gold} fixes. Identify the 2-4 most COMMON, code-detectable sink families.
Then read 5-8 representative diffs IN FULL to nail the exact vulnerable->fixed transformation:
  python3 -c "import json;d=json.load(open('oracle/validation/authoring/gold-${c.key}.json'));[print('=====',x['sha'][:12],'\\n',x['diff'][:3500]) for x in d[:8]]"
The '-' (removed) lines show the vulnerable shape; '+' (added) lines show the fix. Your rule must match the vulnerable shape and STAY SILENT on the fixed shape.

STEP 2 — match the repo convention. Look at an existing rule + its test fixture:
  ls ${ROOT}/semgrep/${c.key}/ ; sed -n '1,60p' $(find ${ROOT}/semgrep/${c.key} -name '*.yaml' | head -1)
  grep -rh "vr-id:" ${ROOT}/semgrep/${c.key}/*.yaml | sort -u   # so you pick UNUSED vr-ids
Each rule file is semgrep/${c.key}/ruby-${c.key}-<slug>.yaml with the structure:
  rules:
    - id: ruby-${c.key}-<slug>
      languages: [ruby]
      severity: ERROR
      message: > (2-4 sentences: the risk + the remediation direction)
      metadata: { vr-id: RB-SG-${c.ord}NN, category: ${c.key}, cwe: ["CWE-NNN"], owasp: "...", confidence: HIGH|MEDIUM, tier: B, source-citation: "derived from GitLab security fix <sha12> (<subject>); CWE-NNN", license: derived-original, references: [...], validated: { parses: true } }
      patterns / pattern-either: <the matchers>
  vr-id: use RB-SG-${c.ord}NN where NN continues AFTER the highest existing one you grepped (avoid collision).

STEP 3 — author 2-4 rules covering the top sink families. For EACH rule, also create the paired test fixture semgrep/${c.key}/ruby-${c.key}-<slug>.rb containing BOTH:
  # ruleid: ruby-${c.key}-<slug>   <- a line with the VULNERABLE shape (must match)
  # ok: ruby-${c.key}-<slug>       <- a line with the SAFE/fixed shape (must NOT match)
Use the semgrep test annotation convention (comment 'ruleid:' above the bad line, 'ok:' above the good line) so a later \`semgrep --test\` can verify it.

STEP 4 — SYNTAX-validate each rule (LIGHT — do NOT run the full --test engine here):
  semgrep --validate --config semgrep/${c.key}/ruby-${c.key}-<slug>.yaml
Fix any parse errors until --validate is clean. (The full --test run is done separately later.)

QUALITY BAR: precise over broad. The vulnerable shape must require the real smell (interpolation into the sink, raw user param, unanchored regex, etc.), not just "this method is called". A rule that matches every Net::HTTP call is useless. Generic across the bug class, never hardcoded to one file/sha.

STEP 5 — persist a manifest to oracle/validation/authoring/authored-${c.key}.json and return via StructuredOutput. category="${c.key}". For each rule set validate_ok from the --validate result, and expected_head_breadth honestly.`
}

phase('Author')
const results = await pipeline(
  CATS,
  (c) => agent(prompt(c), { label: `author:${c.key}`, phase: 'Author', model: 'fable', schema: SCHEMA }),
)

const clean = results.filter(Boolean)
const totalRules = clean.reduce((s, r) => s + (r.rules_created || 0), 0)
const validated = clean.reduce((s, r) => s + (r.rules || []).filter((x) => x.validate_ok).length, 0)
log(`authoring done: ${clean.length} categories, ${totalRules} rules authored, ${validated} pass --validate`)

return {
  categories: clean.length,
  total_rules: totalRules,
  validate_passing: validated,
  per_category: clean.map((r) => ({ category: r.category, n: r.rules_created, ids: (r.rules || []).map((x) => x.id) })),
  all: clean,
}
