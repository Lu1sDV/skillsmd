import pytest
from slugify import slugify


@pytest.mark.parametrize("text,want", [
    ("Crème Brûlée", "creme-brulee"),
    ("naïve façade", "naive-facade"),
    ("ABC123def", "abc123def"),
    ("a\t\n b", "a-b"),
    ("x.y/z", "x-y-z"),
    ("ﬁne", "fine"),          # NFKD compatibility: ligature -> "fi"
    ("日本語", ""),            # no ASCII alphanumerics survive
    ("日本語 text", "text"),
])
def test_accents_and_edge_inputs(text, want):
    assert slugify(text) == want


def test_default_max_length_is_50():
    assert slugify("a" * 80) == "a" * 50
    assert slugify("a" * 49 + " b") == "a" * 49  # cut at the hyphen, none left trailing
    assert slugify("a" * 48 + " b") == "a" * 48 + "-b"


def test_truncation_strips_hyphen_at_cut():
    assert slugify("abc def", 3) == "abc"
    assert slugify("abc def", 4) == "abc"
    assert slugify("abc def", 5) == "abc-d"


def test_max_length_zero():
    assert slugify("abc", 0) == ""


@pytest.mark.parametrize("text", ["Hello World", "a--b__c", "Café Münster", "---x---", "!!!"])
def test_idempotent(text):
    once = slugify(text)
    assert slugify(once) == once


@pytest.mark.parametrize("text", ["Hello, World! Ünï", "  --  ", "x" * 100 + " y"])
def test_output_invariants(text):
    out = slugify(text, 20)
    assert len(out) <= 20
    assert out == out.lower()
    assert out.isascii()
    assert not out.startswith("-") and not out.endswith("-") and "--" not in out


# Spec: "each run of non-alphanumeric characters becomes one hyphen".
# Non-ASCII punctuation/symbols are non-alphanumeric, so they should separate words.
@pytest.mark.parametrize("text,want", [
    ("a\u2014b", "a-b"),       # em dash
    ("price\u20acfive", "price-five"),  # euro sign
    ("a\u00a0b", "a-b"),       # no-break space (NFKD -> plain space, passes)
    ("\u201cquoted\u201d words", "quoted-words"),
    ("foo\u2022bar", "foo-bar"),  # bullet
])
def test_non_ascii_separators_become_hyphen(text, want):
    assert slugify(text) == want


def test_negative_max_length_does_not_chop_from_end():
    # Unspecified; a negative limit silently slices from the end today.
    assert slugify("abcdef", -1) == ""
