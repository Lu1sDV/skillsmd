from tags import top_tags, unique_tags


# unique_tags (order unspecified -> compare as sorted lists)

def test_unique_tags_emptyItems_returnsEmptyList():
    assert unique_tags([]) == []


def test_unique_tags_itemsWithoutTagsKey_areIgnored():
    assert unique_tags([{}, {"name": "x"}]) == []


def test_unique_tags_emptyTagLists_returnsEmptyList():
    assert unique_tags([{"tags": []}, {"tags": []}]) == []


def test_unique_tags_mixedItems_returnsDistinctTags():
    items = [{"tags": ["a", "b"]}, {}, {"tags": ["b", "c"]}]
    assert sorted(unique_tags(items)) == ["a", "b", "c"]


def test_unique_tags_repeatedTagsWithinAndAcrossItems_eachReturnedOnce():
    items = [{"tags": ["a", "a", "b"]}, {"tags": ["a"]}]
    result = unique_tags(items)
    assert len(result) == len(set(result))
    assert sorted(result) == ["a", "b"]


def test_unique_tags_isCaseSensitive():
    assert sorted(unique_tags([{"tags": ["A", "a"]}])) == ["A", "a"]


def test_unique_tags_doesNotMutateInput():
    items = [{"tags": ["b", "a"]}]
    unique_tags(items)
    assert items == [{"tags": ["b", "a"]}]


# top_tags

def test_top_tags_emptyItems_returnsEmptyList():
    assert top_tags([], 3) == []


def test_top_tags_itemsWithoutTags_returnsEmptyList():
    assert top_tags([{}, {"x": 1}], 3) == []


def test_top_tags_mostFrequentFirst():
    items = [{"tags": ["a", "b", "c"]}, {"tags": ["b", "c"]}, {"tags": ["c"]}]
    assert top_tags(items, 3) == ["c", "b", "a"]


def test_top_tags_ties_brokenAlphabetically():
    items = [{"tags": ["z", "m", "a"]}]
    assert top_tags(items, 3) == ["a", "m", "z"]


def test_top_tags_tiesAmongSameCountOnly_higherCountStillFirst():
    items = [{"tags": ["z"]}, {"tags": ["z"]}, {"tags": ["b", "a"]}]
    assert top_tags(items, 3) == ["z", "a", "b"]


def test_top_tags_limitsToN():
    items = [{"tags": ["a", "b", "c", "d"]}, {"tags": ["d", "c"]}, {"tags": ["d"]}]
    assert top_tags(items, 2) == ["d", "c"]


def test_top_tags_tieAtCutoff_alphabeticalWinsSlot():
    items = [{"tags": ["x", "b", "a"]}, {"tags": ["x"]}]
    assert top_tags(items, 2) == ["x", "a"]


def test_top_tags_nLargerThanDistinctTags_returnsAll():
    assert top_tags([{"tags": ["b", "a"]}], 10) == ["a", "b"]


def test_top_tags_nZero_returnsEmptyList():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_countsRepeatsWithinSingleItem():
    items = [{"tags": ["a", "a", "a"]}, {"tags": ["b", "b"]}, {"tags": ["c"]}]
    assert top_tags(items, 3) == ["a", "b", "c"]


def test_top_tags_countsAcrossItems():
    items = [{"tags": ["b"]}, {"tags": ["a"]}, {"tags": ["b"]}]
    assert top_tags(items, 1) == ["b"]


def test_top_tags_isCaseSensitive_uppercaseSortsBeforeLowercase():
    items = [{"tags": ["a", "B"]}]
    assert top_tags(items, 2) == ["B", "a"]
