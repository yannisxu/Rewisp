"""Promises — catch commitments you (or others) made on screen, hold them,
surface them. "I'll send it tomorrow", "please reply by Friday."

Detection is fully local and cheap: regex for commitment shapes + Apple's
NSDataDetector for the deadline. No model, no cloud call. New promises land as
Pending in the existing review flow, so precision is the human's call — the
detector can be a little liberal without polluting anything.
"""

import logging
import re

from . import db

log = logging.getLogger("rewisp")

# Action verbs that make a commitment real (filters out idle "I will" chatter).
_VERB = (r"(?:send|sends|sending|reply|replies|replying|respond|email|finish|"
         r"submit|review|call|share|deliver|sign|return|pay|get back|"
         r"follow up|circle back|send over|get you|send you|schedule|book|invite|"
         r"buy|order|remind|update|write|draft|prepare|ask|meet|ping|dm|confirm|"
         r"cancel|renew|complete|upload|fix|merge|approve|set up|reach out|text|message)")

# The tail after the verb captures the object ("the report to Dana"), but stops
# at a quote, comma, or other clause break so it doesn't swallow the rest of a
# run-on line (OCR rarely has sentence periods).
_TAIL = r"[^.?!\n,;\"“”|]{0,45}"
# You committing — broad set of openers ("I'll", "I need to", "gotta", "remember to").
_ME = re.compile(
    rf"\b(?:i'?ll|i will|i can|i'?m going to|i'?m gonna|i plan to|i'?m planning to|"
    rf"i need to|i have to|i gotta|i got to|i should|i must|i want to|i'?d like to|"
    rf"let me|remember to|need to|gotta|have to|i'?ll go ahead and)\b[^.?!\n,;]*?\b{_VERB}\b{_TAIL}", re.I)
# Owed to you: "please reply by…", "can you send…", "get back to me by…".
_THEM = re.compile(rf"\b(?:please|can you|could you|would you|will you|make sure to|don'?t forget to)\b[^.?!\n,;]*?\b{_VERB}\b{_TAIL}", re.I)
# A deadline anywhere in the clause strengthens confidence. Handles "by Friday",
# "by tomorrow", AND "by (the) end of (the) day/week/today", plus a bare
# "end of the day/week" with no "by".
_DEADLINE = re.compile(
    r"\b(?:by|before|due(?: on)?|no later than)\s+(?:the\s+)?"
    r"(?:end of\s+(?:the\s+)?(?:day|week|today|month)|eod|cob|eow|end of day|"
    r"today|tonight|tomorrow|this week|next week|this weekend|"
    r"mon|tue|wed|thu|fri|sat|sun|monday|tuesday|wednesday|thursday|friday|saturday|sunday|"
    r"jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|\d{1,2}(?:st|nd|rd|th)?)"
    r"|\bend of (?:the\s+)?(?:day|week|today|month)\b",
    re.I)

# Looser: a bare time reference with no "by" ("call Dana tomorrow", "meeting Friday",
# "invite by end of week"). Combined with a commitment verb it's a strong deadline
# signal; used to qualify me/imperative commitments (NOT the noisy 'them' bucket).
_TEMPORAL = re.compile(
    r"\b(?:today|tonight|tonite|tomorrow|tmrw|this (?:week|weekend|afternoon|evening|morning)|"
    r"next (?:week|month)|end of (?:the )?(?:day|week|today|month)|eod|eow|cob|"
    r"mon|tue|wed|thu|fri|sat|sun|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b",
    re.I)

# To-do style imperatives you write to yourself: "email manvi by EOD",
# "Send John an invite by Friday". Noisy (UI buttons say "Send"), so a match only
# counts as a promise when it ALSO carries a time reference (checked in detect()).
_IMP_VERB = (r"email|send|call|text|message|reply|respond|finish|submit|review|"
             r"schedule|book|invite|buy|order|pay|remind|update|write|draft|"
             r"prepare|share|ask|follow up|circle back|meet|ping|dm|confirm|cancel|"
             r"renew|complete|upload|fix|merge|approve|set up|reach out|get")
_IMPERATIVE = re.compile(rf"^\s*(?:{_IMP_VERB})\b[^.?!\n,;\"“”|]{{3,55}}", re.I)

_SENT_SPLIT = re.compile(r"[.?!\n]")


def _extract_due(text: str) -> str | None:
    """Resolve a natural-language deadline to an ISO date via NSDataDetector."""
    try:
        import Foundation
        det, _ = Foundation.NSDataDetector.dataDetectorWithTypes_error_(
            Foundation.NSTextCheckingTypeDate, None)
        if det is None:
            return None
        rng = Foundation.NSMakeRange(0, len(text))
        for m in det.matchesInString_options_range_(text, 0, rng):
            d = m.date()
            if d is not None:
                return d.descriptionWithCalendarFormat_timeZone_locale_(
                    "%Y-%m-%d", None, None) if hasattr(d, "descriptionWithCalendarFormat_timeZone_locale_") \
                    else str(d)[:10]
    except Exception:  # noqa: BLE001 — date detection is best-effort
        pass
    return None


def _clean(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()[:140]


def _norm(s: str) -> str:
    return re.sub(r"[^a-z0-9 ]", "", s.lower()).strip()[:60]


def detect(text: str) -> list[dict]:
    """Find commitments in a block of text. Returns
    [{who:'me'|'them', what, due, confidence}], deduped within the block."""
    out: list[dict] = []
    seen: list[str] = []
    for sent in _SENT_SPLIT.split(text):
        sent = sent.strip()
        if len(sent) < 8 or len(sent) > 200:
            continue
        if len(re.findall(r"[a-zA-Z]{2,}", sent)) < 3:
            continue                              # OCR garbage / not a real sentence
        strict_dl = bool(_DEADLINE.search(sent))            # "by Friday", "by EOD"
        any_time = strict_dl or bool(_TEMPORAL.search(sent))  # + bare "tomorrow", "Friday"
        due = _extract_due(sent) if any_time else None
        matched = False
        for who, pat in (("me", _ME), ("them", _THEM)):
            m = pat.search(sent)
            if not m:
                continue
            what = _clean(m.group(0))
            key = _norm(what)
            if len(key) < 6 or any(key in s or s in key for s in seen):
                matched = True
                break
            seen.append(key)
            # First-person commitments ("I'll send…") are low-noise, so they count
            # even without a time reference. Requests owed to you ("please email me
            # at…") are boilerplate-prone, so those need a real deadline.
            if who == "me":
                conf = 0.9 if any_time else 0.75
                out.append({"who": "me", "what": what, "due": due, "confidence": conf})
            else:
                conf = 0.85 if strict_dl else 0.5
                out.append({"who": "them", "what": what,
                            "due": due if strict_dl else None, "confidence": conf})
            matched = True
            break  # one promise per sentence
        # To-do imperative ("email manvi by EOD", "call Dana tomorrow") — only when
        # it carries a time reference, since a bare "Send"/"Reply" is a button.
        if not matched and any_time:
            im = _IMPERATIVE.match(sent)
            if im:
                what = _clean(im.group(0))
                key = _norm(what)
                if len(key) >= 6 and not any(key in s or s in key for s in seen):
                    seen.append(key)
                    out.append({"who": "me", "what": what, "due": due, "confidence": 0.8})
    return out


def scan_and_store(conn, wisp_id: int, text: str, min_conf: float = 0.7,
                   max_per_capture: int = 3) -> int:
    """Detect promises in a capture and store new ones as Pending. Stores your own
    commitments even without a deadline ('I'll send mavi a doc pic'), but drops
    deadline-less requests owed to you (boilerplate like 'please email me at…').
    Dedups against recent promises. Returns how many were added."""
    found = [p for p in detect(text) if p["confidence"] >= min_conf][:max_per_capture]
    if not found:
        return 0
    # Dedup against recent promises by normalized substring (handles apostrophes
    # and rewordings that a raw SQL LIKE would miss).
    recent = conn.execute(
        "SELECT what FROM promises WHERE status IN ('pending','confirmed') "
        "AND created_at >= datetime('now','-7 days')").fetchall()
    known = [_norm(r[0]) for r in recent]
    added = 0
    for p in found:
        norm = _norm(p["what"])
        if any(norm in k or k in norm for k in known):
            continue
        db.add_promise(conn, wisp_id, p["who"], p["what"], p["due"], p["confidence"])
        known.append(norm)
        added += 1
    if added:
        log.info("promises: stored %d from wisp #%s", added, wisp_id)
    return added
