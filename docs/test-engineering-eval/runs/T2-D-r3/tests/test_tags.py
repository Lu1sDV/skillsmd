import pytest

from tags import top_tags, unique_tags


def test_unique_tags_distinct_across_items():
    items = [{"tags": ["a", "b"]}, {"tags": ["b", "c"]}]
    assert sorted(unique_tags(items)) == ["a", "b", "c"]


def test_unique_tags_each_once_with_in_item_duplicates():
    assert sorted(unique_tags([{"tags": ["a", "a"]}, {"tags": ["a"]}])) == ["a"]


def test_unique_tags_missing_and_empty_tags():
    assert unique_tags([{}, {"tags": []}, {"name": "x"}]) == []
    assert unique_tags([]) == []


def test_top_tags_most_frequent_first():
    items = [{"tags": ["a", "b"]}, {"tags": ["b"]}, {"tags": ["b", "c"]}, {"tags": ["c"]}]
    assert top_tags(items, 3) == ["b", "c", "a"]


def test_top_tags_ties_alphabetical():
    items = [{"tags": ["z", "m"]}, {"tags": ["a"]}]
    assert top_tags(items, 3) == ["a", "m", "z"]


def test_top_tags_limits_to_n():
    items = [{"tags": ["a", "b", "c"]}, {"tags": ["a", "b"]}, {"tags": ["a"]}]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_n_larger_than_distinct():
    assert top_tags([{"tags": ["a"]}], 10) == ["a"]


def test_top_tags_n_zero_and_empty_input():
    assert top_tags([{"tags": ["a"]}], 0) == []
    assert top_tags([], 3) == []
    assert top_tags([{}], 3) == []


def test_top_tags_missing_tags_key_ignored():
    assert top_tags([{}, {"tags": ["a"]}], 1) == ["a"]
