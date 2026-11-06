from tags import top_tags, unique_tags


def test_unique_tags_distinct_across_items():
    items = [{"tags": ["a", "b"]}, {"tags": ["b", "c"]}]
    result = unique_tags(items)
    assert sorted(result) == ["a", "b", "c"]
    assert len(result) == 3


def test_unique_tags_missing_tags_key():
    assert sorted(unique_tags([{"x": 1}, {"tags": ["a"]}])) == ["a"]


def test_unique_tags_empty():
    assert unique_tags([]) == []
    assert unique_tags([{"tags": []}]) == []


def test_unique_tags_duplicates_within_item():
    assert unique_tags([{"tags": ["a", "a"]}]) == ["a"]


def test_top_tags_most_frequent_first():
    items = [{"tags": ["a", "b"]}, {"tags": ["b"]}, {"tags": ["b", "c", "c"]}]
    assert top_tags(items, 3) == ["b", "c", "a"]


def test_top_tags_ties_alphabetical():
    items = [{"tags": ["z", "m"]}, {"tags": ["a"]}]
    assert top_tags(items, 3) == ["a", "m", "z"]


def test_top_tags_limits_to_n():
    items = [{"tags": ["a", "a", "b", "c"]}]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_n_larger_than_distinct():
    assert top_tags([{"tags": ["a"]}], 10) == ["a"]


def test_top_tags_n_zero_and_empty():
    assert top_tags([{"tags": ["a"]}], 0) == []
    assert top_tags([], 5) == []


def test_top_tags_missing_tags_key():
    assert top_tags([{}, {"tags": ["a"]}], 5) == ["a"]
