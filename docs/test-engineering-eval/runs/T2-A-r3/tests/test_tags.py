from tags import top_tags, unique_tags


# unique_tags

def test_unique_tags_emptyItems_returnsEmpty():
    assert unique_tags([]) == []


def test_unique_tags_itemsWithoutTagsKey_ignoredAndReturnsEmpty():
    assert unique_tags([{}, {"name": "x"}]) == []


def test_unique_tags_emptyTagsList_returnsEmpty():
    assert unique_tags([{"tags": []}]) == []


def test_unique_tags_repeatedAcrossItems_eachReturnedOnce():
    result = unique_tags([{"tags": ["a", "b"]}, {"tags": ["b", "c"]}, {"tags": ["a"]}])
    assert len(result) == 3
    assert set(result) == {"a", "b", "c"}


def test_unique_tags_duplicateWithinOneItem_returnedOnce():
    result = unique_tags([{"tags": ["a", "a", "a"]}])
    assert result == ["a"]


def test_unique_tags_mixedItemsWithAndWithoutTags_collectsOnlyPresent():
    assert set(unique_tags([{"tags": ["x"]}, {}, {"tags": ["y"]}])) == {"x", "y"}


def test_unique_tags_caseDiffers_treatedAsDistinct():
    assert set(unique_tags([{"tags": ["A", "a"]}])) == {"A", "a"}


def test_unique_tags_doesNotMutateInput():
    items = [{"tags": ["b", "a"]}, {"tags": ["a"]}]
    unique_tags(items)
    assert items == [{"tags": ["b", "a"]}, {"tags": ["a"]}]


def test_unique_tags_generatorInput_isConsumed():
    assert set(unique_tags(i for i in [{"tags": ["a"]}, {"tags": ["b"]}])) == {"a", "b"}


# top_tags

def test_top_tags_emptyItems_returnsEmpty():
    assert top_tags([], 3) == []


def test_top_tags_itemsWithoutTags_returnsEmpty():
    assert top_tags([{}, {"tags": []}], 3) == []


def test_top_tags_differentFrequencies_mostFrequentFirst():
    items = [{"tags": ["a", "b", "c"]}, {"tags": ["b", "c"]}, {"tags": ["c"]}]
    assert top_tags(items, 3) == ["c", "b", "a"]


def test_top_tags_tiedCounts_brokenAlphabetically():
    items = [{"tags": ["zeta", "alpha", "mid"]}]
    assert top_tags(items, 3) == ["alpha", "mid", "zeta"]


def test_top_tags_tieOutranksedByCount_countBeatsAlphabet():
    items = [{"tags": ["z"]}, {"tags": ["z"]}, {"tags": ["a"]}]
    assert top_tags(items, 2) == ["z", "a"]


def test_top_tags_nSmallerThanDistinct_truncates():
    items = [{"tags": ["a", "b", "c"]}, {"tags": ["c", "b"]}, {"tags": ["c"]}]
    assert top_tags(items, 2) == ["c", "b"]


def test_top_tags_truncationAtTie_keepsAlphabeticallyFirst():
    items = [{"tags": ["b", "a", "c"]}]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_nLargerThanDistinct_returnsAll():
    assert top_tags([{"tags": ["b", "a"]}], 10) == ["a", "b"]


def test_top_tags_nZero_returnsEmpty():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_nOne_returnsSingleTop():
    assert top_tags([{"tags": ["a", "b"]}, {"tags": ["b"]}], 1) == ["b"]


def test_top_tags_mixedItemsWithAndWithoutTags_countsOnlyPresent():
    assert top_tags([{"tags": ["a"]}, {}, {"tags": ["a", "b"]}], 2) == ["a", "b"]


def test_top_tags_returnsList():
    assert isinstance(top_tags([{"tags": ["a"]}], 1), list)
