import pytest
from slugify import slugify


def test_slugify_default_max_length_is_50():
    assert slugify("a" * 60) == "a" * 50


def test_slugify_default_truncation_does_not_leave_trailing_hyphen():
    text = "a" * 49 + " bbb"  # hyphen lands at index 49, the 50th character
    assert slugify(text) == "a" * 49


@pytest.mark.parametrize("text,max_length,want", [
    ("abc", 0, ""),
    ("ab cd", 2, "ab"),
    ("ab cd", 3, "ab"),       # cut lands right after the hyphen
    ("a-b-c-d", 4, "a-b"),
    ("abc", 100, "abc"),
    ("", 5, ""),
])
def test_slugify_truncation_edges(text, max_length, want):
    assert slugify(text, max_length) == want


@pytest.mark.parametrize("text,want", [
    ("ÀÉÎÕÜ", "aeiou"),               # uppercase accents
    ("naïve façade", "naive-facade"),
    ("ﬁne", "fine"),                  # NFKD compatibility ligature
    ("e\u0301cole", "ecole"),         # already-decomposed combining accent
    ("Ünï-cödé", "uni-code"),
    ("MiXeD CaSe", "mixed-case"),
    ("tab\tand\nnewline", "tab-and-newline"),
    ("a.b,c/d", "a-b-c-d"),
    ("42", "42"),
    ("   ", ""),
])
def test_slugify_more_basic(text, want):
    assert slugify(text) == want


def test_slugify_output_is_lowercase_ascii_slug():
    out = slugify("Crème Brûlée -- 100% Ünïcode!")
    assert out == "creme-brulee-100-unicode"
    assert out.isascii() and out == out.lower()
    assert not out.startswith("-") and not out.endswith("-") and "--" not in out


def test_slugify_is_idempotent():
    once = slugify("  Héllo,   Wörld!! ")
    assert slugify(once) == once


@pytest.mark.parametrize("text,want", [
    ("\u201cquoted\u201d word", "quoted-word"),  # curly quotes at edges, space inside
    ("a\u00a0b", "a-b"),                          # no-break space (NFKD -> space)
    ("rock \u2665 roll", "rock-roll"),            # symbol surrounded by spaces
])
def test_slugify_non_ascii_separators_handled(text, want):
    assert slugify(text) == want


# Spec: "Each run of non-alphanumeric characters becomes one hyphen."
# Non-ASCII punctuation/symbols between letters are non-alphanumeric, but the
# implementation deletes them (encode("ascii", "ignore")) instead of emitting a
# hyphen, gluing neighbouring words together.
@pytest.mark.xfail(strict=True, reason="non-ASCII punctuation is dropped, not turned into a hyphen")
@pytest.mark.parametrize("text,want", [
    ("foo\u2014bar", "foo-bar"),   # em dash
    ("a\u00b7b", "a-b"),           # middle dot
    ("a\u2192b", "a-b"),           # arrow
])
def test_slugify_non_ascii_punctuation_between_words_becomes_hyphen(text, want):
    assert slugify(text) == want
