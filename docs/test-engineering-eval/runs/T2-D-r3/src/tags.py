"""Tag helpers."""
from collections import Counter


def unique_tags(items):
    """Distinct tags across all items, each once. Order is not specified."""
    seen = set()
    for item in items:
        seen.update(item.get("tags", []))
    return list(seen)


def top_tags(items, n):
    """The n most frequent tags, most frequent first; ties broken alphabetically."""
    counts = Counter(tag for item in items for tag in item.get("tags", []))
    ranked = sorted(counts, key=lambda tag: (-counts[tag], tag))
    return ranked[:n]
