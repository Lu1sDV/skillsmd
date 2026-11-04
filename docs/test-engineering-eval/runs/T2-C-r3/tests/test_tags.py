from tags import top_tags, unique_tags


# unique_tags: order unspecified, so compare as sorted lists (also checks "each once").
def test_unique_tags_distinct_across_items():
    items = [{"tags": ["a", "b"]}, {"tags": ["b", "c"]}, {"tags": ["a"]}]
    assert sorted(unique_tags(items)) == ["a", "b", "c"]


def test_unique_tags_item_without_tags_key_is_skipped():
    items = [{"name": "x"}, {"tags": ["a"]}, {}]
    assert sorted(unique_tags(items)) == ["a"]


def test_unique_tags_empty_inputs():
    assert unique_tags([]) == []
    assert unique_tags([{"tags": []}, {}]) == []


def test_unique_tags_repeated_within_one_item_listed_once():
    assert unique_tags([{"tags": ["a", "a", "a"]}]) == ["a"]


# top_tags
def test_top_tags_most_frequent_first():
    items = [{"tags": ["a", "b"]}, {"tags": ["b", "c"]}, {"tags": ["b", "c"]}]
    # counts: b=3, c=2, a=1
    assert top_tags(items, 3) == ["b", "c", "a"]


def test_top_tags_limits_to_n():
    items = [{"tags": ["a", "b"]}, {"tags": ["b", "c"]}, {"tags": ["b", "c"]}]
    assert top_tags(items, 2) == ["b", "c"]
    assert top_tags(items, 1) == ["b"]


def test_top_tags_ties_broken_alphabetically():
    # all counts equal to 1, given in non-alphabetical order
    items = [{"tags": ["c", "a"]}, {"tags": ["b"]}]
    assert top_tags(items, 3) == ["a", "b", "c"]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_tie_break_applies_within_a_frequency_level_only():
    # z=2, then a/m tie at 1
    items = [{"tags": ["z", "m"]}, {"tags": ["z", "a"]}]
    assert top_tags(items, 3) == ["z", "a", "m"]


def test_top_tags_n_larger_than_distinct_returns_all():
    assert top_tags([{"tags": ["a", "b"]}], 10) == ["a", "b"]


def test_top_tags_n_zero_returns_empty():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_empty_and_tagless_items():
    assert top_tags([], 3) == []
    assert top_tags([{}, {"tags": []}], 3) == []
    assert top_tags([{}, {"tags": ["a"]}], 3) == ["a"]
