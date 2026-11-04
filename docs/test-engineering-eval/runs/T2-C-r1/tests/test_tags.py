"""Tests for src/tags.py; expected values derived from SPEC.md."""
from tags import top_tags, unique_tags


# --- unique_tags ---

def test_unique_tags_each_tag_once_across_items():
    items = [{"tags": ["a", "b"]}, {"tags": ["b", "c"]}, {"tags": ["a"]}]
    result = unique_tags(items)
    assert len(result) == 3
    assert set(result) == {"a", "b", "c"}


def test_unique_tags_missing_tags_key_is_ignored():
    items = [{"name": "x"}, {"tags": ["a"]}, {}]
    assert unique_tags(items) == ["a"]


def test_unique_tags_empty_input():
    assert unique_tags([]) == []


def test_unique_tags_empty_tag_lists():
    assert unique_tags([{"tags": []}, {"tags": []}]) == []


def test_unique_tags_duplicate_within_one_item():
    assert unique_tags([{"tags": ["a", "a", "a"]}]) == ["a"]


def test_unique_tags_is_case_sensitive():
    # spec says "distinct"; no normalisation is specified
    assert set(unique_tags([{"tags": ["A", "a"]}])) == {"A", "a"}


# --- top_tags ---

def test_top_tags_most_frequent_first():
    items = [
        {"tags": ["a", "b", "c"]},
        {"tags": ["b", "c"]},
        {"tags": ["c"]},
    ]  # c=3, b=2, a=1
    assert top_tags(items, 3) == ["c", "b", "a"]


def test_top_tags_limits_to_n():
    items = [{"tags": ["a", "b", "c"]}, {"tags": ["b", "c"]}, {"tags": ["c"]}]
    assert top_tags(items, 2) == ["c", "b"]
    assert top_tags(items, 1) == ["c"]


def test_top_tags_ties_broken_alphabetically():
    # all count 1, inserted in reverse alphabetical order
    items = [{"tags": ["z", "m", "b", "a"]}]
    assert top_tags(items, 4) == ["a", "b", "m", "z"]


def test_top_tags_tie_break_applies_at_cut_off():
    # x=2, then b and a tied at 1: n=2 must keep alphabetically-first "a"
    items = [{"tags": ["x", "b"]}, {"tags": ["x", "a"]}]
    assert top_tags(items, 2) == ["x", "a"]


def test_top_tags_frequency_beats_alphabetical():
    items = [{"tags": ["z"]}, {"tags": ["z"]}, {"tags": ["a"]}]
    assert top_tags(items, 2) == ["z", "a"]


def test_top_tags_n_larger_than_distinct_tags_returns_all():
    assert top_tags([{"tags": ["b", "a"]}], 10) == ["a", "b"]


def test_top_tags_n_zero_returns_empty():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_empty_input():
    assert top_tags([], 3) == []


def test_top_tags_missing_tags_key_is_ignored():
    items = [{}, {"tags": ["a"]}, {"name": "x"}]
    assert top_tags(items, 5) == ["a"]
