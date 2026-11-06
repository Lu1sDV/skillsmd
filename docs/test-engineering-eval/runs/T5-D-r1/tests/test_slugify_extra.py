import pytest
from slugify import slugify


def test_default_max_length_is_50():
    assert slugify("a" * 60) == "a" * 50
    assert slugify("a" * 50) == "a" * 50


def test_default_truncation_leaves_no_trailing_hyphen():
    assert slugify("a" * 49 + " b") == "a" * 49


@pytest.mark.parametrize("text,max_length,want", [
    ("abc", 0, ""),
    ("abc", 1, "a"),
    ("a b", 2, "a"),
    ("ab-", 2, "ab"),
    ("", 5, ""),
    ("ab cd", 100, "ab-cd"),
])
def test_truncation_edges(text, max_length, want):
    assert slugify(text, max_length) == want


@pytest.mark.parametrize("text,want", [
    ("x²", "x2"),                 # NFKD compatibility digit
    ("ﬁsh", "fish"),             # ligature
    ("a\u0301b", "ab"),           # combining accent already decomposed
    ("ÀÉÎÕÜ", "aeiou"),           # uppercase accents
    ("a\tb\nc", "a-b-c"),         # whitespace kinds
    ("b…c", "b-c"),               # ellipsis NFKD -> "..."
    ("123", "123"),
])
def test_normalisation(text, want):
    assert slugify(text) == want


@pytest.mark.parametrize("text", ["Hello World", "Café  Münster!", "---x---", "a" * 80])
def test_output_invariants(text):
    out = slugify(text, 20)
    assert out == out.lower() and out.isascii()
    assert len(out) <= 20
    assert not out.startswith("-") and not out.endswith("-")
    assert "--" not in out


def test_idempotent():
    once = slugify("Café Münster & Co.")
    assert slugify(once) == once


# Spec: each run of non-alphanumeric characters becomes one hyphen.
# Characters with no ASCII decomposition are dropped without a hyphen instead.
@pytest.mark.xfail(strict=True, reason="non-decomposable symbol is deleted, not turned into a hyphen")
def test_non_ascii_symbol_separates_words():
    assert slugify("a·b") == "a-b"


@pytest.mark.xfail(strict=True, reason="non-ASCII script between words is deleted without a separator")
def test_non_latin_between_words_separates():
    assert slugify("a日b") == "a-b"


# Spec does not define negative max_length, but slug[:-1] silently drops the last char.
@pytest.mark.xfail(strict=True, reason="negative max_length slices from the end instead of yielding/raising")
def test_negative_max_length_does_not_return_content():
    assert slugify("abc", -1) == ""


@pytest.mark.xfail(strict=True, reason="em dash is deleted, not turned into a hyphen")
def test_em_dash_separates_words():
    assert slugify("a—b") == "a-b"
