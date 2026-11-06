"""Extra slugify tests: boundaries, idempotence, Unicode handling.

Naming: test_<unit>_<scenario>_<expectedResult>.
Tests marked xfail(strict=True) encode SPEC.md behaviour that the current code violates;
they flip to a hard failure once the defect is fixed, prompting removal of the marker.
"""
import pytest
from slugify import slugify


# --- length boundaries -------------------------------------------------------

def test_slugify_defaultMaxLength_truncatesAt50():
    assert slugify("x" * 60) == "x" * 50


def test_slugify_exactlyDefaultLength_isUnchanged():
    assert slugify("x" * 50) == "x" * 50


def test_slugify_hyphenAtCutBoundary_noTrailingHyphen():
    # 49 chars, hyphen at index 49 (the 50th char) would be the last kept char
    assert slugify("x" * 49 + " y") == "x" * 49


def test_slugify_hyphenJustInsideLimit_keptWhenFollowedByChar():
    assert slugify("x" * 48 + " yz") == "x" * 48 + "-y"


@pytest.mark.parametrize("max_length,want", [(0, ""), (1, "a"), (2, "a")])
def test_slugify_smallMaxLength_neverEndsWithHyphen(max_length, want):
    assert slugify("a b", max_length) == want


def test_slugify_multipleHyphensAtCut_allStripped():
    # only one hyphen can exist after collapsing, but cut must still strip it
    assert slugify("ab   cd", 3) == "ab"


def test_slugify_maxLengthZero_returnsEmpty():
    assert slugify("abc", 0) == ""


def test_slugify_resultNeverExceedsMaxLength():
    for n in range(0, 12):
        assert len(slugify("Hello, wide World! 123", n)) <= n


# --- normalisation -----------------------------------------------------------

@pytest.mark.parametrize("text,want", [
    ("ÀÉÎÕÜ", "aeiou"),                 # uppercase accents
    ("e\u0301", "e"),                    # decomposed (combining) accent
    ("ﬁsh", "fish"),                     # NFKD compatibility ligature
    ("Ａｂｃ１２３", "abc123"),          # full-width forms
    ("a\u00a0b", "a-b"),                 # non-breaking space is a separator
    ("a\tb\nc", "a-b-c"),                # other whitespace
    ("foo…bar", "foo-bar"),              # ellipsis decomposes to ASCII dots
    ("ABC123def", "abc123def"),
    ("snake_case-and.dots", "snake-case-and-dots"),
])
def test_slugify_unicodeAndPunctuation_normalised(text, want):
    assert slugify(text) == want


@pytest.mark.parametrize("text", ["日本語", "🙂🙂", "€"])
def test_slugify_onlyNonAsciiNonLatin_returnsEmpty(text):
    assert slugify(text) == ""


@pytest.mark.parametrize("text", [
    "Hello World", "  a -- b  ", "Café Münster", "x" * 80, "!!!", "",
])
def test_slugify_appliedTwice_isIdempotent(text):
    once = slugify(text)
    assert slugify(once) == once


@pytest.mark.parametrize("text", ["Hello World", "  a -- b  ", "Route 66 & 101", "a_b"])
def test_slugify_output_onlyLowerAlnumAndSingleHyphens(text):
    out = slugify(text)
    assert out == out.strip("-")
    assert "--" not in out
    assert all(c.isascii() and (c.islower() or c.isdigit() or c == "-") for c in out)


# --- spec violations (see module docstring) ----------------------------------

_DROPPED = "non-ASCII chars with no ASCII decomposition are deleted instead of acting as separators"


@pytest.mark.xfail(strict=True, reason=_DROPPED)
@pytest.mark.parametrize("text,want", [
    ("foo—bar", "foo-bar"),   # em dash
    ("foo–bar", "foo-bar"),   # en dash
    ("a€b", "a-b"),           # currency symbol
    ("a日b", "a-b"),          # CJK between words
    ("a🙂b", "a-b"),
])
def test_slugify_nonAsciiPunctuationBetweenWords_actsAsSeparator(text, want):
    assert slugify(text) == want
