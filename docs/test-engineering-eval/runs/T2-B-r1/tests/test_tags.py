from tags import top_tags, unique_tags


# unique_tags

def test_unique_tags_empty_items_returns_empty():
    assert unique_tags([]) == []


def test_unique_tags_items_without_tags_key_returns_empty():
    assert unique_tags([{}, {"name": "x"}]) == []


def test_unique_tags_empty_tag_lists_returns_empty():
    assert unique_tags([{"tags": []}]) == []


def test_unique_tags_duplicates_within_and_across_items_each_once():
    items = [{"tags": ["a", "b", "a"]}, {"tags": ["b", "c"]}, {}]
    result = unique_tags(items)
    assert len(result) == 3
    assert sorted(result) == ["a", "b", "c"]


def test_unique_tags_does_not_mutate_input():
    items = [{"tags": ["b", "a", "b"]}]
    unique_tags(items)
    assert items == [{"tags": ["b", "a", "b"]}]


def test_unique_tags_is_case_sensitive():
    assert sorted(unique_tags([{"tags": ["A", "a"]}])) == ["A", "a"]


# top_tags

def test_top_tags_empty_items_returns_empty():
    assert top_tags([], 3) == []


def test_top_tags_items_without_tags_returns_empty():
    assert top_tags([{}, {"tags": []}], 3) == []


def test_top_tags_orders_by_frequency_descending():
    items = [{"tags": ["a", "b", "b", "c", "c", "c"]}]
    assert top_tags(items, 3) == ["c", "b", "a"]


def test_top_tags_counts_across_items():
    items = [{"tags": ["x", "y"]}, {"tags": ["y"]}, {}, {"tags": ["y", "z"]}]
    assert top_tags(items, 3) == ["y", "x", "z"]


def test_top_tags_ties_broken_alphabetically():
    items = [{"tags": ["pear", "apple", "mango"]}]
    assert top_tags(items, 3) == ["apple", "mango", "pear"]


def test_top_tags_ties_alphabetical_within_frequency_groups():
    items = [{"tags": ["b", "a", "d", "c", "c", "d"]}]
    assert top_tags(items, 4) == ["c", "d", "a", "b"]


def test_top_tags_n_limits_result_length():
    items = [{"tags": ["a", "a", "b", "c"]}]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_n_cutoff_inside_tie_keeps_alphabetically_first():
    items = [{"tags": ["z", "y", "x"]}]
    assert top_tags(items, 2) == ["x", "y"]


def test_top_tags_n_zero_returns_empty():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_n_larger_than_distinct_returns_all():
    assert top_tags([{"tags": ["a", "b", "b"]}], 10) == ["b", "a"]


def test_top_tags_n_equal_to_distinct_returns_all():
    assert top_tags([{"tags": ["a", "b", "b"]}], 2) == ["b", "a"]


def test_top_tags_does_not_mutate_input():
    items = [{"tags": ["b", "a", "b"]}]
    top_tags(items, 1)
    assert items == [{"tags": ["b", "a", "b"]}]
