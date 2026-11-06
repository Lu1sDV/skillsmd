from tags import top_tags, unique_tags


# --- unique_tags ---

def test_unique_tags_emptyItems_returnsEmpty():
    assert unique_tags([]) == []


def test_unique_tags_itemsWithoutTagsKey_ignored():
    assert unique_tags([{}, {"name": "x"}]) == []


def test_unique_tags_emptyTagLists_returnsEmpty():
    assert unique_tags([{"tags": []}, {"tags": []}]) == []


def test_unique_tags_mixedItems_returnsEachTagOnce():
    items = [{"tags": ["a", "b"]}, {}, {"tags": ["b", "c"]}, {"tags": ["a"]}]
    result = unique_tags(items)
    assert len(result) == 3
    assert set(result) == {"a", "b", "c"}


def test_unique_tags_duplicatesWithinOneItem_returnsEachOnce():
    result = unique_tags([{"tags": ["a", "a", "a"]}])
    assert result == ["a"]


def test_unique_tags_caseDiffers_treatedAsDistinct():
    assert set(unique_tags([{"tags": ["a", "A"]}])) == {"a", "A"}


def test_unique_tags_doesNotMutateInput():
    items = [{"tags": ["a", "b"]}]
    unique_tags(items)
    assert items == [{"tags": ["a", "b"]}]


# --- top_tags ---

def test_top_tags_emptyItems_returnsEmpty():
    assert top_tags([], 3) == []


def test_top_tags_itemsWithoutTags_returnsEmpty():
    assert top_tags([{}, {"tags": []}], 3) == []


def test_top_tags_distinctFrequencies_mostFrequentFirst():
    items = [
        {"tags": ["a", "b", "c"]},
        {"tags": ["b", "c"]},
        {"tags": ["c"]},
    ]
    assert top_tags(items, 3) == ["c", "b", "a"]


def test_top_tags_ties_brokenAlphabetically():
    items = [{"tags": ["z", "m", "a"]}, {"tags": ["z", "m", "a"]}]
    assert top_tags(items, 3) == ["a", "m", "z"]


def test_top_tags_tieAmongLowerRank_alphabeticalAfterHigherCount():
    items = [
        {"tags": ["z"]}, {"tags": ["z"]}, {"tags": ["z"]},
        {"tags": ["b", "a"]}, {"tags": ["b", "a"]},
        {"tags": ["y"]},
    ]
    assert top_tags(items, 4) == ["z", "a", "b", "y"]


def test_top_tags_nSmallerThanDistinct_truncates():
    items = [{"tags": ["a", "b", "c"]}, {"tags": ["b", "c"]}, {"tags": ["c"]}]
    assert top_tags(items, 2) == ["c", "b"]


def test_top_tags_truncationCutsWithinTie_keepsAlphabeticallyFirst():
    items = [{"tags": ["c", "b", "a"]}]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_nLargerThanDistinct_returnsAll():
    assert top_tags([{"tags": ["a", "b"]}], 10) == ["a", "b"]


def test_top_tags_nZero_returnsEmpty():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_countsAcrossItems():
    items = [{"tags": ["a"]}, {"tags": ["b"]}, {"tags": ["b"]}, {}]
    assert top_tags(items, 1) == ["b"]


def test_top_tags_uppercaseSortsBeforeLowercase_onTie():
    # plain string ordering: "B" < "a"
    assert top_tags([{"tags": ["a", "B"]}], 2) == ["B", "a"]
