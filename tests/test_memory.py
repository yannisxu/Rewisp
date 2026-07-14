"""Memory fuzzy de-dupe — stop the digest re-proposing facts it already learned."""
from rewisp import memory


class TestSimilar:
    def test_reworded_same_fact(self):
        assert memory._similar(
            "Data Science student at UC San Diego, open to Summer 2027 internships",
            "Data Science student at UC San Diego; portfolio states open to Summer 2027 internships")

    def test_plural_and_punctuation_variants(self):
        assert memory._similar("Scouting volunteer (Troop 511/2511)",
                               "He volunteers with Scouting Troop 511/2511")

    def test_distinct_facts_not_merged(self):
        assert not memory._similar("Prefers short answers", "Prioritizing robotics internships")
        assert not memory._similar("Uses Claude Pro", "Uses Gemini as fallback")
        assert not memory._similar("Studies late at night", "Prefers dark mode")


class TestForget:
    def test_forget_removes_confirmed(self, tmp_path, monkeypatch):
        f = tmp_path / "memory.md"
        f.write_text("# Rewisp memory\n\n## Confirmed\n- keep this\n- remove this\n\n## Pending (approve or delete)\n- pending one\n")
        monkeypatch.setattr(memory.config, "MEMORY_PATH", f)
        assert memory.forget("remove this") is True
        confirmed, pending = memory.read_sections()
        assert "remove this" not in confirmed and "keep this" in confirmed
        assert "pending one" in pending

    def test_forget_missing_line(self, tmp_path, monkeypatch):
        f = tmp_path / "memory.md"
        f.write_text("# Rewisp memory\n\n## Confirmed\n- a\n\n## Pending (approve or delete)\n")
        monkeypatch.setattr(memory.config, "MEMORY_PATH", f)
        assert memory.forget("nope") is False
