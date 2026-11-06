"""Additional slugify tests; expectations come from SPEC.md, not from running the code."""
import re
import unicodedata

import pytest
from slugify import slugify


def test_default_max_length_is_50():
    assert slugify("a" * 60) == "a" * 50


def test_default_truncation_does_not_leave_trailing_hyphen():
    # the hyphen would be character 50 (1-indexed); it must be dropped
    assert slugify("a" * 49 + " bcd") == "a" * 49


def test_max_length_zero_gives_empty_slug():
    assert slugify("abc", 0) == ""


def test_decomposed_accents_are_stripped():
    # "e" + U+0301 combining acute, "u" + U+0308 combining diaeresis
    assert slugify(unicodedata.normalize("NFD", "Café Münster")) == "cafe-munster"


INPUTS = ["Hello World", "  a  b  ", "a--b__c", "Café Münster", "Route 66 & 101", "", "!!!", "---x---",
          "word " * 20, "x" * 80]


@pytest.mark.parametrize("max_length", [1, 2, 3, 5, 10, 50])
def test_output_shape_and_idempotence(max_length):
    for text in INPUTS:
        out = slugify(text, max_length)
        assert re.fullmatch(r"([a-z0-9]+(-[a-z0-9]+)*)?", out), (text, out)
        assert len(out) <= max_length
        assert slugify(out, max_length) == out


@pytest.mark.xfail(strict=True, reason="defect: non-ASCII punctuation is dropped by encode('ascii','ignore') "
                   "instead of becoming a hyphen (SPEC: each run of non-alphanumeric characters -> one hyphen)")
@pytest.mark.parametrize("text,want", [
    ("a\u2014b", "a-b"),          # em dash
    ("a\u2013b", "a-b"),          # en dash
    ("a\u20acb", "a-b"),          # euro sign
    ("caf\u00e9\u2022bar", "cafe-bar"),  # bullet
])
def test_non_ascii_punctuation_separates_words(text, want):
    assert slugify(text) == want
