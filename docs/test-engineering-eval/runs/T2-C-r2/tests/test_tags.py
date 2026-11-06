"""Tests for src/tags.py, with expectations taken from SPEC.md."""
from tags import top_tags, unique_tags


# ---- unique_tags ----------------------------------------------------------

def test_unique_tags_empty_items_returns_empty():
    assert unique_tags([]) == []


def test_unique_tags_items_without_tags_key_are_skipped():
    assert unique_tags([{"id": 1}, {}]) == []


def test_unique_tags_items_with_empty_tag_list():
    assert unique_tags([{"tags": []}]) == []


def test_unique_tags_distinct_across_items_each_once():
    items = [{"tags": ["a", "b"]}, {"tags": ["b", "c"]}, {"tags": ["a"]}]
    result = unique_tags(items)
    assert sorted(result) == ["a", "b", "c"]
    assert len(result) == 3  # no duplicates in the returned collection


def test_unique_tags_duplicates_within_one_item_collapse():
    assert unique_tags([{"tags": ["x", "x", "x"]}]) == ["x"]


def test_unique_tags_mixes_items_with_and_without_tags():
    items = [{"name": "n"}, {"tags": ["p"]}, {}, {"tags": ["q", "p"]}]
    assert sorted(unique_tags(items)) == ["p", "q"]


def test_unique_tags_is_case_sensitive():
    assert sorted(unique_tags([{"tags": ["A", "a"]}])) == ["A", "a"]


def test_unique_tags_does_not_mutate_input():
    items = [{"tags": ["b", "a", "b"]}]
    unique_tags(items)
    assert items == [{"tags": ["b", "a", "b"]}]


# ---- top_tags -------------------------------------------------------------

def test_top_tags_empty_items_returns_empty():
    assert top_tags([], 3) == []


def test_top_tags_items_without_tags_returns_empty():
    assert top_tags([{}, {"id": 2}], 3) == []


def test_top_tags_most_frequent_first():
    items = [
        {"tags": ["a", "b", "c"]},
        {"tags": ["b", "c"]},
        {"tags": ["c"]},
    ]
    # counts: c=3, b=2, a=1
    assert top_tags(items, 3) == ["c", "b", "a"]


def test_top_tags_limits_to_n():
    items = [{"tags": ["a", "b", "c"]}, {"tags": ["b", "c"]}, {"tags": ["c"]}]
    assert top_tags(items, 2) == ["c", "b"]


def test_top_tags_ties_broken_alphabetically():
    # all counts equal to 1, inserted in non-alphabetical order
    items = [{"tags": ["zebra", "apple", "mango"]}]
    assert top_tags(items, 3) == ["apple", "mango", "zebra"]


def test_top_tags_tie_break_applies_within_a_count_level_only():
    items = [
        {"tags": ["b", "a", "z"]},
        {"tags": ["z", "y"]},
        {"tags": ["z", "b"]},
    ]
    # counts: z=3, b=2, a=1, y=1
    assert top_tags(items, 4) == ["z", "b", "a", "y"]


def test_top_tags_tie_cut_at_n_keeps_alphabetically_first():
    items = [{"tags": ["d", "c", "b", "a"]}]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_counts_repeats_within_one_item():
    # "x" appears 3 times in one item, "y" once in each of two items.
    items = [{"tags": ["x", "x", "x", "y"]}, {"tags": ["y"]}]
    assert top_tags(items, 2) == ["x", "y"]


def test_top_tags_n_larger_than_distinct_returns_all():
    items = [{"tags": ["a", "b"]}, {"tags": ["a"]}]
    assert top_tags(items, 10) == ["a", "b"]


def test_top_tags_n_zero_returns_empty():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_counts_across_items_missing_tags():
    items = [{"tags": ["a"]}, {}, {"tags": ["a", "b"]}]
    assert top_tags(items, 5) == ["a", "b"]


def test_top_tags_does_not_mutate_input():
    items = [{"tags": ["b", "a", "b"]}]
    top_tags(items, 2)
    assert items == [{"tags": ["b", "a", "b"]}]
