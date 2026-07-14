"""Regression tests for audit-sweep fixes: OCR-chrome snippet cleanup and
precog fuzzy de-duplication."""

from difflib import SequenceMatcher

from rewisp import dejavu


class TestCleanSnippet:
    def test_strips_menu_bar_and_clock(self):
        raw = ("Dia File Edit View Tabs Bookmarks History Extensions Window Help "
               "43% ( 43% 8 Tue Jul 14 8 Netflix - The Witcher episode 3 recap")
        assert dejavu.clean_snippet(raw) == "Netflix - The Witcher episode 3 recap"

    def test_strips_notes_chrome(self):
        raw = "Notes File Edit Format View Window Help 100% Mon Jul 13 5:28 PM Meeting notes: ship it"
        assert dejavu.clean_snippet(raw).startswith("Meeting notes: ship it")

    def test_plain_text_untouched(self):
        assert dejavu.clean_snippet("just a normal sentence here") == "just a normal sentence here"

    def test_empty(self):
        assert dejavu.clean_snippet("") == ""


def _dedup(out):
    """Mirror of precog's final fuzzy de-dupe."""
    final = []
    for q in out:
        qn = q.rstrip("?. ").lower()
        if any(qn == kn or qn.startswith(kn) or kn.startswith(qn)
               or SequenceMatcher(None, qn, kn).ratio() > 0.8
               for kn in (k.rstrip("?. ").lower() for k in final)):
            continue
        final.append(q)
    return final


class TestPrecogDedup:
    def test_prefix_duplicate_dropped(self):
        out = ["what show was i watching just now?",
               "what show was i watching just now on netflix?"]
        assert _dedup(out) == ["what show was i watching just now?"]

    def test_distinct_kept(self):
        out = ["What changed on this page?", "what did i do today?", "have i seen this error?"]
        assert len(_dedup(out)) == 3
