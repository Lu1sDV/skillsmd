import pytest
from slugify import slugify


@pytest.mark.parametrize("text,want", [
    ("Hello World", "hello-world"),
    ("  Hello   World  ", "hello-world"),
    ("a--b__c", "a-b-c"),
    ("Café Münster", "cafe-munster"),
    ("Route 66 & 101", "route-66-101"),
    ("", ""),
    ("!!!", ""),
    ("---x---", "x"),
])
def test_slugify_basic(text, want):
    assert slugify(text) == want


@pytest.mark.parametrize("text,max_length,want", [
    ("abcdef", 6, "abcdef"),
    ("abcdefg", 6, "abcdef"),
    ("ab cd ef", 3, "ab"),
    ("ab cd ef", 4, "ab-c"),
    ("ab cd ef", 5, "ab-cd"),
])
def test_slugify_truncation(text, max_length, want):
    assert slugify(text, max_length) == want
