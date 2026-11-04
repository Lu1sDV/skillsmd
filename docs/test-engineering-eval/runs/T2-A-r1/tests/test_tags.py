from tags import top_tags, unique_tags


# --- unique_tags ---

def test_unique_tags_emptyItems_returnsEmpty():
    assert unique_tags([]) == []


def test_unique_tags_itemsWithoutTagsKey_ignored():
    assert unique_tags([{"id": 1}, {}]) == []


def test_unique_tags_emptyTagLists_returnsEmpty():
    assert unique_tags([{"tags": []}]) == []


def test_unique_tags_duplicatesAcrossAndWithinItems_eachOnce():
    items = [{"tags": ["a", "b", "a"]}, {"tags": ["b", "c"]}, {"tags": ["a"]}]
    result = unique_tags(items)
    assert isinstance(result, list)
    assert len(result) == 3
    assert set(result) == {"a", "b", "c"}


def test_unique_tags_mixedItemsWithAndWithoutTags_collectsOnlyPresent():
    assert set(unique_tags([{"tags": ["x"]}, {"name": "n"}, {"tags": ["y"]}])) == {"x", "y"}


def test_unique_tags_caseDifferentTags_keptDistinct():
    assert set(unique_tags([{"tags": ["A", "a"]}])) == {"A", "a"}


def test_unique_tags_doesNotMutateInput():
    items = [{"tags": ["a", "b"]}]
    unique_tags(items)
    assert items == [{"tags": ["a", "b"]}]


# --- top_tags ---

def test_top_tags_emptyItems_returnsEmpty():
    assert top_tags([], 3) == []


def test_top_tags_itemsWithoutTags_returnsEmpty():
    assert top_tags([{}, {"id": 1}], 3) == []


def test_top_tags_differentFrequencies_mostFrequentFirst():
    items = [{"tags": ["a", "b", "c"]}, {"tags": ["b", "c"]}, {"tags": ["c"]}]
    assert top_tags(items, 3) == ["c", "b", "a"]


def test_top_tags_ties_brokenAlphabetically():
    items = [{"tags": ["zeta", "alpha", "mid"]}]
    assert top_tags(items, 3) == ["alpha", "mid", "zeta"]


def test_top_tags_tieBelowHigherCount_alphabeticalWithinTierOnly():
    items = [{"tags": ["z", "b", "a"]}, {"tags": ["z", "b", "a"]}, {"tags": ["z"]}]
    # z:3, a:2, b:2
    assert top_tags(items, 3) == ["z", "a", "b"]


def test_top_tags_nSmallerThanDistinct_truncates():
    items = [{"tags": ["a"]}, {"tags": ["a"]}, {"tags": ["b"]}, {"tags": ["c"]}]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_tieAtCutoff_alphabeticalWinsSlot():
    items = [{"tags": ["c", "b", "a"]}]
    assert top_tags(items, 1) == ["a"]


def test_top_tags_nLargerThanDistinct_returnsAll():
    assert top_tags([{"tags": ["a", "b"]}], 10) == ["a", "b"]


def test_top_tags_nZero_returnsEmpty():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_countsAcrossItems():
    items = [{"tags": ["a"]}, {"tags": ["b"]}, {"tags": ["b"]}]
    assert top_tags(items, 1) == ["b"]

