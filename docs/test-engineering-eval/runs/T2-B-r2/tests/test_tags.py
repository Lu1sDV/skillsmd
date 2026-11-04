import pytest

from tags import top_tags, unique_tags


def test_unique_tags_emptyItems_returnsEmptyList():
    assert unique_tags([]) == []


def test_unique_tags_itemsWithoutTagsKey_areIgnored():
    assert unique_tags([{"name": "a"}, {"tags": ["x"]}]) == ["x"]


def test_unique_tags_itemWithEmptyTags_returnsEmptyList():
    assert unique_tags([{"tags": []}]) == []


def test_unique_tags_duplicatesAcrossAndWithinItems_appearOnce():
    result = unique_tags([{"tags": ["a", "b", "a"]}, {"tags": ["b", "c"]}])
    assert len(result) == 3
    assert set(result) == {"a", "b", "c"}


def test_unique_tags_doesNotMutateInput():
    items = [{"tags": ["a", "a"]}]
    unique_tags(items)
    assert items == [{"tags": ["a", "a"]}]


def test_top_tags_emptyItems_returnsEmptyList():
    assert top_tags([], 3) == []


def test_top_tags_orderedByFrequencyDescending():
    items = [{"tags": ["a"]}, {"tags": ["b", "a"]}, {"tags": ["c", "b", "a"]}]
    assert top_tags(items, 3) == ["a", "b", "c"]


def test_top_tags_ties_brokenAlphabetically():
    items = [{"tags": ["zeta", "alpha", "mid"]}]
    assert top_tags(items, 3) == ["alpha", "mid", "zeta"]


def test_top_tags_tiesAmongLowerRank_doNotOutrankMoreFrequent():
    items = [{"tags": ["b", "z"]}, {"tags": ["z", "a"]}]
    assert top_tags(items, 3) == ["z", "a", "b"]


def test_top_tags_limitsToN():
    items = [{"tags": ["a", "a", "b", "c"]}]
    assert top_tags(items, 2) == ["a", "b"]


def test_top_tags_nLargerThanDistinct_returnsAll():
    assert top_tags([{"tags": ["a", "b"]}], 10) == ["a", "b"]


def test_top_tags_nZero_returnsEmptyList():
    assert top_tags([{"tags": ["a"]}], 0) == []


def test_top_tags_itemsWithoutTags_areIgnored():
    assert top_tags([{}, {"tags": ["a"]}], 5) == ["a"]


def test_top_tags_repeatedWithinOneItem_countsEachOccurrence():
    items = [{"tags": ["a", "a", "a"]}, {"tags": ["b", "b"]}, {"tags": ["b"]}]
    # a:3, b:3 -> tie, alphabetical
    assert top_tags(items, 2) == ["a", "b"]
    items.append({"tags": ["b"]})
    assert top_tags(items, 2) == ["b", "a"]


@pytest.mark.xfail(strict=True, reason="SPEC silent on n<0; ranked[:n] returns all but last")
def test_top_tags_negativeN_returnsEmptyList():
    # Spec says "the n most frequent"; a negative n should not yield results.
    # Currently ranked[:n] with n=-1 returns all but the last tag.
    assert top_tags([{"tags": ["a", "b", "c"]}], -1) == []
