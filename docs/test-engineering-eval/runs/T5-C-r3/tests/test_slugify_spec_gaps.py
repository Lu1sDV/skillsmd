"""Additional slugify tests, expectations derived from SPEC.md (not from the implementation)."""
import pytest
from slugify import slugify


# Partitions the existing tests don't cover: accent forms, case, digits, digit/length edges.
@pytest.mark.parametrize("text,want", [
    ("ÉCOLE", "ecole"),                    # uppercase accented -> lowercase ascii
    ("e\u0301cole", "ecole"),              # decomposed accent (e + combining acute)
    ("Ünïcödé Tëxt", "unicode-text"),      # multiple accents
    ("ABC123", "abc123"),                  # digits kept, no separator inserted
    ("a_b", "a-b"),                        # underscore is non-alphanumeric
    ("a\tb\nc", "a-b-c"),                  # whitespace kinds
    ("  ", ""),                            # whitespace only
    ("x", "x"),
])
def test_slugify_accents_case_and_separators(text, want):
    assert slugify(text) == want


@pytest.mark.parametrize("text,max_length,want", [
    ("abc", 0, ""),                        # zero length
    ("ab cd", 2, "ab"),                    # cut exactly before the hyphen
    ("ab-cd", 3, "ab"),                    # cut right after the hyphen -> no trailing hyphen
    ("a b c d", 1, "a"),
    ("hello world", 100, "hello-world"),   # max_length larger than the slug
])
def test_slugify_truncation_edges(text, max_length, want):
    assert slugify(text, max_length) == want


def test_slugify_default_max_length_is_50():
    assert slugify("a" * 60) == "a" * 50
    assert slugify("a" * 50) == "a" * 50
    # the 50-char cut lands on a hyphen: must not end with one
    assert slugify("a" * 49 + " b") == "a" * 49


def test_slugify_is_idempotent():
    for text in ["Hello World", "Café Münster", "  --a__b--  ", "x" * 80]:
        once = slugify(text)
        assert slugify(once) == once


def test_slugify_output_alphabet():
    out = slugify("Crème Brûlée & Co. (2024)!")
    assert out == "creme-brulee-co-2024"


# Bug discovery: SPEC says "each run of non-alphanumeric characters becomes one hyphen".
# Non-ASCII punctuation/symbols are non-alphanumeric, but the implementation deletes them
# (encode("ascii","ignore")) before the hyphen substitution, so neighbours get glued together.
@pytest.mark.xfail(strict=True, reason="defect: non-ASCII non-alphanumerics are dropped instead of becoming a hyphen")
@pytest.mark.parametrize("text,want", [
    ("foo\u2014bar", "foo-bar"),           # em dash
    ("foo\u2013bar", "foo-bar"),           # en dash
    ("it\u2019s", "it-s"),                 # curly apostrophe
    ("a\u00a9b", "a-b"),                   # copyright sign
    ("a\U0001F600b", "a-b"),               # emoji
])
def test_slugify_non_ascii_punctuation_becomes_hyphen(text, want):
    assert slugify(text) == want
