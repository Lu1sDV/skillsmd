import pytest
from slugify import slugify


@pytest.mark.parametrize("text,want", [
    ("Ünï Cödé", "uni-code"),            # accents on several letters
    ("e\u0301", "e"),                    # combining-mark (decomposed) input
    ("Ａｂ１", "ab1"),                   # fullwidth -> ASCII via NFKD
    ("a\u00a0b", "a-b"),                 # non-breaking space is a separator
    ("a\t\nb", "a-b"),                   # whitespace runs collapse
    ("x" + "!" * 5 + "y", "x-y"),         # long punctuation run -> one hyphen
    ("日本語", ""),                       # nothing ASCII-representable
    ("ABC123", "abc123"),                # digits kept, case folded
])
def test_slugify_unicode_and_whitespace_returnsExpected(text, want):
    assert slugify(text) == want


def test_slugify_defaultMaxLength_is50():
    assert slugify("x" * 60) == "x" * 50
    assert slugify("x" * 50) == "x" * 50
    assert slugify("x" * 49 + "-y") == "x" * 49  # cut lands on hyphen -> stripped


@pytest.mark.parametrize("max_length", [0, 1, 2, 3, 5, 10])
def test_slugify_anyMaxLength_neverExceedsOrEndsWithHyphen(max_length):
    for text in ["a b c d e f", "ab-cd-ef", "--a--b--", "abcdefghijkl"]:
        out = slugify(text, max_length)
        assert len(out) <= max_length
        assert not out.endswith("-") and not out.startswith("-")


def test_slugify_zeroMaxLength_returnsEmpty():
    assert slugify("hello", 0) == ""


def test_slugify_truncationIsPrefixOfUntruncated():
    full = slugify("The quick brown fox jumps", 1000)
    assert full == "the-quick-brown-fox-jumps"
    for n in range(len(full) + 1):
        assert full.startswith(slugify("The quick brown fox jumps", n))


def test_slugify_isIdempotent():
    once = slugify("  Café -- Münster & Co.  ")
    assert slugify(once) == once


# Spec: "each run of non-alphanumeric characters becomes one hyphen".
# Non-ASCII punctuation is silently dropped instead, gluing words together.
@pytest.mark.xfail(strict=True, reason="non-ASCII punctuation is dropped, not turned into a hyphen")
@pytest.mark.parametrize("text,want", [
    ("foo\u2014bar", "foo-bar"),   # em dash
    ("a\u2013b", "a-b"),           # en dash
    ("a\u201cb", "a-b"),           # curly quote
    ("a\u65e5b", "a-b"),           # CJK char between words
])
def test_slugify_nonAsciiSeparator_becomesHyphen(text, want):
    assert slugify(text) == want
