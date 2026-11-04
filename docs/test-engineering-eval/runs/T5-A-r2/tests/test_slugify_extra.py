import re

import pytest
from slugify import slugify


def test_slugify_defaultMaxLength_is50():
    assert slugify("a" * 60) == "a" * 50
    assert slugify("a" * 50) == "a" * 50


def test_slugify_defaultMaxLength_noTrailingHyphenAtCut():
    # hyphen lands exactly at index 49 -> must be trimmed
    assert slugify("a" * 49 + " b") == "a" * 49


def test_slugify_maxLengthZero_returnsEmpty():
    assert slugify("abc", 0) == ""


def test_slugify_maxLengthOne_withLeadingWord():
    assert slugify("ab cd", 1) == "a"


def test_slugify_truncationOnlyHyphensAfterCut_noTrailingHyphen():
    assert slugify("a b c d", 2) == "a"
    assert slugify("a b c d", 3) == "a-b"


@pytest.mark.parametrize("text,want", [
    ("HELLO", "hello"),
    ("ÀÉÎÕÜ", "aeiou"),
    ("naïve façade", "naive-facade"),
    ("e\u0301", "e"),                 # decomposed accent input
    ("ﬁne", "fine"),                  # NFKD compatibility ligature
    ("x2y3", "x2y3"),                 # digits kept, no hyphen injected
    ("a\tb\nc", "a-b-c"),             # whitespace kinds
    ("a.b,c/d", "a-b-c-d"),
    ("-", ""),
    ("   ", ""),
    ("日本語", ""),                   # no ASCII content at all
    ("日本 abc 語", "abc"),
])
def test_slugify_variedInputs_expectedSlug(text, want):
    assert slugify(text) == want


@pytest.mark.parametrize("text", [
    "Hello World", "  ĉa va?  ", "a--b__c", "---", "Route 66 & 101", "x" * 80 + " y",
])
@pytest.mark.parametrize("max_length", [1, 5, 50])
def test_slugify_anyInput_satisfiesInvariants(text, max_length):
    out = slugify(text, max_length)
    assert len(out) <= max_length
    assert out == "" or re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", out)
    assert slugify(out, max_length) == out  # idempotent


@pytest.mark.xfail(strict=True, reason="defect: non-ASCII non-alphanumerics are deleted, not turned into a hyphen (spec: each run of non-alphanumerics -> one hyphen)")
@pytest.mark.parametrize("text,want", [
    ("a€b", "a-b"),
    ("x\u2011y", "x-y"),   # U+2011 non-breaking hyphen
    ("a\u2014b", "a-b"),   # em dash
])
def test_slugify_nonAsciiSeparator_becomesHyphen(text, want):
    assert slugify(text) == want
