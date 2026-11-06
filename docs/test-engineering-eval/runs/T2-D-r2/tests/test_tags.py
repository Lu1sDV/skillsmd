import pytest
from tags import top_tags, unique_tags


def test_unique_basic():
    items = [{"tags": ["a", "b"]}, {"tags": ["b", "c"]}]
    assert sorted(unique_tags(items)) == ["a", "b", "c"]


def test_unique_each_once_incl_within_item():
    assert sorted(unique_tags([{"tags": ["a", "a"]}, {"tags": ["a"]}])) == ["a"]


def test_unique_missing_or_empty_tags():
    assert sorted(unique_tags([{}, {"tags": []}, {"tags": ["x"]}])) == ["x"]


def test_unique_empty_input():
    assert unique_tags([]) == []


def test_unique_does_not_mutate_input():
    items = [{"tags": ["a"]}]
    unique_tags(items)
    assert items == [{"tags": ["a"]}]


def test_top_most_frequent_first():
    items = [{"tags": ["a", "b"]}, {"tags": ["b"]}, {"tags": ["b", "c"]}, {"tags": ["c"]}]
    assert top_tags(items, 3) == ["b", "c", "a"]


def test_top_ties_alphabetical():
    items = [{"tags": ["z", "m", "a"]}]
    assert top_tags(items, 3) == ["a", "m", "z"]


def test_top_n_limits_result():
    items = [{"tags": ["a", "a", "b"]}]
    assert top_tags(items, 1) == ["a"]


def test_top_n_larger_than_distinct():
    assert top_tags([{"tags": ["a"]}], 10) == ["a"]


def test_top_n_zero():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_empty_and_missing_tags():
    assert top_tags([], 3) == []
    assert top_tags([{}, {"tags": []}], 3) == []


@pytest.mark.xfail(strict=True, reason="unspecified behaviour; current code returns all but the last tag (slice [:-1])")
def test_top_negative_n_returns_nothing():
    # Spec: "the n most frequent tags"; negative n has no sensible meaning -> nothing.
    assert top_tags([{"tags": ["a", "b", "c"]}], -1) == []


@pytest.mark.xfail(strict=True, reason="unspecified behaviour; current code raises TypeError on tags=None")
def test_unique_tags_none_treated_as_absent():
    # Spec: `tags` is optional; an explicit None is the common way to say "absent".
    assert unique_tags([{"tags": None}, {"tags": ["a"]}]) == ["a"]


@pytest.mark.xfail(strict=True, reason="unspecified behaviour; current code raises TypeError on tags=None")
def test_top_tags_none_treated_as_absent():
    assert top_tags([{"tags": None}, {"tags": ["a"]}], 1) == ["a"]
