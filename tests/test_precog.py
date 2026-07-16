"""Precognition — query logging + suggestion ranking."""

from rewisp import db, precog


class TestLogging:
    def test_log_and_embed(self, conn):
        precog.log_query(conn, "what did I do today?", "Safari")
        row = conn.execute("SELECT text, app_context, embedding FROM queries").fetchone()
        assert row[0] == "what did I do today?" and row[1] == "Safari"
        assert row[2] is not None                 # embedded

    def test_mark_tapped(self, conn):
        precog.log_query(conn, "where's my zoom link?")
        precog.mark_tapped(conn, "where's my zoom link?")
        assert conn.execute("SELECT was_tapped FROM queries").fetchone()[0] == 1


class TestSuggest:
    def test_stacktrace_template(self, conn):
        db.insert_capture(conn, "Terminal", None, None,
                          "Traceback (most recent call last):\n  File x\nValueError: boom")
        s = precog.suggest(conn)
        assert any("error" in q.lower() for q in s)

    def test_meeting_template(self, conn):
        db.insert_capture(conn, "Calendar", None, None, "Standup — Join now via Zoom meeting")
        s = precog.suggest(conn)
        assert any("link" in q.lower() for q in s)

    def test_changed_page_template(self, conn):
        # same page captured twice -> "what changed" is offered
        for _ in range(2):
            db.insert_capture(conn, "Chrome", "Dashboard", "https://ex.com/d", "metrics content")
        s = precog.suggest(conn)
        assert any("changed" in q.lower() for q in s)

    def test_history_ranked_by_screen(self, conn):
        # log a past query about photosynthesis; current screen is about it
        precog.log_query(conn, "explain photosynthesis light reactions")
        precog.log_query(conn, "best pizza in town")
        db.insert_capture(conn, "Notes", None, None,
                          "chloroplast photosynthesis ATP light reaction notes")
        s = precog.suggest(conn, limit=3)
        assert any("photosynthesis" in q.lower() for q in s)

    def test_empty_when_nothing(self, conn):
        assert precog.suggest(conn) == []


class TestSuggestionQuality:
    def test_junk_queries_never_suggested(self):
        from rewisp.precog import _worth_suggesting
        assert not _worth_suggesting("test")
        assert not _worth_suggesting("hi")
        assert not _worth_suggesting("asdf asdf asdf")
        assert not _worth_suggesting("http://example.com/x y z")
        assert _worth_suggesting("what was due on friday")

    def test_unrelated_history_needs_similarity(self, conn, unit_vec):
        # a query orthogonal to the screen must not appear in the top slots
        # unless there's nothing else (padding tier).
        import numpy as np
        from rewisp import db, embed, precog
        v_screen = np.eye(2, embed.DIM, dtype=np.float32)[0]
        v_far = np.eye(2, embed.DIM, dtype=np.float32)[1]
        # two captures on the same page so the Delta template chip fires
        db.insert_capture(conn, "Dia", None, None, "screen text", embedding=v_screen.tobytes())
        db.insert_capture(conn, "Dia", None, None, "screen text v2", embedding=v_screen.tobytes())
        conn.execute("INSERT INTO queries (text, ts, embedding) VALUES (?, datetime('now'), ?)",
                     ("what show was i watching on netflix", v_far.tobytes()))
        conn.commit()
        # monkeypatch embed of screen -> v_screen so sim(v_far)=0 < floor
        import unittest.mock as mock
        with mock.patch.object(precog.embed, "embed_vec", return_value=v_screen):
            got = precog.suggest(conn, limit=3)
        # the far query may only appear via the padding tier (no closer options),
        # never ahead of the template chip.
        assert got[0] == "What changed on this page?" or "netflix" not in got[0]
