"""Additional slugify tests: default max_length, boundaries, invariants, non-ASCII."""
import re

import pytest
from slugify import slugify


def test_slugify_default_max_length_is_50():
    assert slugify("x" * 60) == "x" * 50


def test_slugify_exactly_50_chars_untouched():
    assert slugify("x" * 50) == "x" * 50


def test_slugify_default_truncation_never_ends_in_hyphen():
    # hyphen lands at index 49 -> must be stripped after cut
    text = "a" * 49 + " " + "b" * 10
    assert slugify(text) == "a" * 49


def test_slugify_default_truncation_keeps_hyphen_before_cut():
    text = "a" * 48 + " " + "b" * 10  # hyphen at index 48, kept; 'b' at 49
    assert slugify(text) == "a" * 48 + "-b"


def test_slugify_max_length_zero_returns_empty():
    assert slugify("abc", 0) == ""


def test_slugify_max_length_one():
    assert slugify("ab cd", 1) == "a"


def test_slugify_truncation_to_hyphen_only_prefix_is_empty_not_hyphen():
    assert slugify("a b", 2) == "a"


def test_slugify_truncation_after_collapsed_separator_run():
    assert slugify("a   ---   b", 2) == "a"


@pytest.mark.parametrize("text,want", [
    ("ÀÉÎÕÜ", "aeiou"),
    ("naïve façade", "naive-facade"),
    ("e\u0301cole", "ecole"),            # combining accent (NFD input)
    ("ﬁne", "fine"),                     # compatibility ligature
    ("UPPER Case", "upper-case"),
    ("tab\tnew\nline", "tab-new-line"),
    ("a.b,c;d/e", "a-b-c-d-e"),
    ("123", "123"),
    ("   ", ""),
])
def test_slugify_normalisation(text, want):
    assert slugify(text) == want


def test_slugify_is_idempotent():
    s = slugify("  Café -- Münster & Co.  ")
    assert slugify(s) == s


@pytest.mark.parametrize("text", [
    "Hello World", "  ??  x  ", "Ünï côdé", "a" * 200, "a b " * 40, "--", "日本語 text",
])
@pytest.mark.parametrize("max_length", [1, 2, 5, 50])
def test_slugify_output_invariants(text, max_length):
    out = slugify(text, max_length)
    assert len(out) <= max_length
    assert re.fullmatch(r"([a-z0-9]+(-[a-z0-9]+)*)?", out)


def test_slugify_pure_non_latin_text_yields_empty():
    assert slugify("日本語") == ""


# --- suspected defects: non-decomposable letters are silently dropped ---

@pytest.mark.xfail(strict=True, reason="'ß' has no NFKD decomposition and is dropped: 'strae'")
def test_slugify_sharp_s_is_transliterated():
    assert slugify("Straße") == "strasse"


@pytest.mark.xfail(strict=True, reason="'Ø' has no NFKD decomposition and is dropped: 're'")
def test_slugify_o_slash_keeps_letter():
    assert slugify("Øre") == "ore"


@pytest.mark.xfail(strict=True, reason="non-ASCII char between words is deleted, gluing words: 'ab'")
def test_slugify_non_ascii_between_words_acts_as_separator():
    assert slugify("a日b") == "a-b"


@pytest.mark.xfail(strict=True, reason="en dash is dropped instead of acting as a separator: 'ab'")
def test_slugify_en_dash_acts_as_separator():
    assert slugify("a\u2013b") == "a-b"
