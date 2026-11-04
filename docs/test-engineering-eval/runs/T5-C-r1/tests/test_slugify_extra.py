"""Additional slugify tests; expected values come from SPEC.md, not from running the code."""
import re

import pytest
from slugify import slugify


@pytest.mark.parametrize("text,want", [
    ("cafe\u0301 Mu\u0308nster", "cafe-munster"),   # decomposed (NFD) accents
    ("HELLO", "hello"),
    ("a1B2", "a1b2"),
    ("\u00c9COLE \u00c0 Paris", "ecole-a-paris"),   # uppercase accented capitals
    ("tab\tand\nnewline", "tab-and-newline"),
    ("a. b, c; d", "a-b-c-d"),
])
def test_slugify_accents_case_and_whitespace(text, want):
    assert slugify(text) == want


def test_slugify_default_max_length_is_50():
    assert slugify("a" * 60) == "a" * 50
    assert slugify("a" * 50) == "a" * 50


def test_slugify_default_truncation_never_ends_in_hyphen():
    # hyphen would be the 50th char; 49 letters + space + letters
    assert slugify("a" * 49 + " bcd") == "a" * 49


@pytest.mark.parametrize("text,max_length,want", [
    ("abc", 0, ""),
    ("ab cd", 1, "a"),
    ("Caf\u00e9 au lait", 5, "cafe"),               # cut lands right after the hyphen
    ("Caf\u00e9 au lait", 6, "cafe-a"),
    ("  ab  ", 2, "ab"),
])
def test_slugify_truncation_edges(text, max_length, want):
    assert slugify(text, max_length) == want


@pytest.mark.parametrize("text", ["Hello, W\u00f6rld! 123", "a  b--c", "x" * 80 + " y", "\u00e9\u00e8 \u00ea"])
@pytest.mark.parametrize("max_length", [1, 3, 7, 50])
def test_slugify_output_invariants(text, max_length):
    out = slugify(text, max_length)
    assert len(out) <= max_length
    assert re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*|", out)   # no edge/double hyphens
    assert slugify(out, max_length) == out                  # idempotent


@pytest.mark.parametrize("text", ["\u65e5\u672c\u8a9e", "\u2014", "\u00a9"])
def test_slugify_no_ascii_alphanumerics_gives_empty(text):
    assert slugify(text) == ""


# Bug discovery: SPEC says every run of non-alphanumeric characters becomes a hyphen.
# The implementation drops non-ASCII chars with no NFKD ASCII form *before* that step,
# so they join neighbouring words instead of separating them.
@pytest.mark.xfail(strict=True, reason="non-ASCII punctuation/symbols are deleted, not turned into a hyphen")
@pytest.mark.parametrize("text,want", [
    ("a\u2014b", "a-b"),        # em dash
    ("a\u20acb", "a-b"),        # euro sign
    ("foo\u00a9bar", "foo-bar"),
    ("a\u2014b c", "a-b-c"),
])
def test_slugify_non_ascii_symbol_is_a_separator(text, want):
    assert slugify(text) == want
