# Rewisp — Research: where the real edge is

*Written 2026-07-19. Goal: Rewisp works as a standalone product, but "another ambient
memory app" is a crowded, dying category. This doc finds the differentiators — features
that are **hard to build, barely researched, and un-copied** — by reading across memory
science, the competitive frontier, HCI/lifelogging research, and the on-device ML edge.
It ends with the main directions to pick from.*

---

## Part 1 — The field, and the actual gap

Every shipping tool is the **same product**: capture the screen → OCR/index → let you
search it. Rewind (dead — Meta bought it, capture killed Dec 2025), Limitless (fled to a
$99 hardware pendant), [Microsoft Recall](https://screenpipe.com/blog/best-ai-screen-recorder-2026)
(Copilot+ PC only, periodic snapshots, closed), [Screenpipe](https://screenpi.pe/blog/rewind-ai-alternative-2026)
(open-source, dev-only). They compete on *capture* — resolution, privacy, platform.

The most important sentence I found, from Screenpipe's own blog:

> **"The real problem isn't capture, it's synthesis. Getting information in is the easy
> part. Finding it later, and connecting it to what you're working on now, that's where
> most systems fall apart."**

Nobody has won synthesis. **Everyone builds a better filing cabinet; nobody builds a
mind.** That's the whole opening — and it's exactly the axis Rewisp already turned onto
(delta, promises, forgetting model). The differentiators below all push *further* down the
synthesis axis, into territory the science says is real but no product has touched.

---

## Part 2 — Rewisp's structural moat (why *we* can do these and they can't)

1. **Text over time, not video.** Diffing, tracking numbers, entity graphs, and
   consolidation are trivial on text and near-impossible on video (compute-prohibitive to
   re-watch weeks of frames per query). This is a permanent architectural advantage.
2. **Local + private.** We can hold the user's *whole* behavioral stream — every failed
   search, every re-read, every dwell — without a cloud-privacy problem. Cloud tools
   can't ethically model the user this deeply.
3. **We already model the human, not just the screen.** The forgetting model + reinforcement
   already treat the *user* as the object. No competitor does this. It's the beachhead for
   everything below.
4. **Context in real time.** Frontmost app, domain, time, what's on screen right now — we
   can act *in the moment*, which a search box can't.

The moat is not "we capture better." It's **"we're the only one modeling how this specific
person's memory works, locally, over their real text."**

---

## Part 3 — The science that software has barely touched (the goldmine)

Memory research is deep and replicated, but almost none of it has been applied to an
ambient-memory *product*. Each principle below is a lever competitors don't even know exists.

- **Retrieval is reconstructive and *labile*.** [Reconsolidation research](https://pmc.ncbi.nlm.nih.gov/articles/PMC5605913/):
  every time you recall something, the memory becomes editable and can be *changed* — and
  your brain silently rewrites it. Implication: your memory of your own past is provably
  unreliable, and Rewisp holds the un-rewritten copy. (This is the basis of the "decision
  provenance" idea in FABLE5-THOUGHTS.)
- **Context-dependent memory / encoding specificity.** [Recall is dramatically better when
  the cues at encoding are present at retrieval](https://en.wikipedia.org/wiki/Context-dependent_memory)
  (the scuba-diver studies). Revisiting an environment surfaces memories you thought were
  gone. Rewisp can *reinstate your context* — show the exact screen-state you were in — to
  trigger recall no keyword search ever could.
- **We remember the *source*, not the content.** The [Google effect / Sparrow-Wegner 2011](https://en.wikipedia.org/wiki/Google_effect):
  when we expect to look something up, we remember *where* it is, not *what* it is. Humans
  already treat machines as [transactive memory](https://pmc.ncbi.nlm.nih.gov/articles/PMC4419599/)
  partners. Rewisp's job is to be the *reliable, contextual* half of that partnership —
  better than Google because it knows your context.
- **The testing effect** — [retrieval practice beats passive review by 30–50%](https://recallify.ai/evidence-for-active-recall-and-spaced-repetition/)
  — **but a crucial caveat**: it [does *not* persist for autobiographical memory](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5976790/).
  So "quiz me on my life" fails; "quiz me on the article/doc I read" works. Sharp line.
- **Metamemory: tip-of-the-tongue and feeling-of-knowing.** [People can sense they know
  something they can't retrieve](https://pmc.ncbi.nlm.nih.gov/articles/PMC12047626/), and
  these states predict retrieval success. If Rewisp could *detect* a TOT/FOK state from
  behavior (hesitation, partial search, re-typing), it could rescue the word at the exact
  moment of the gap.
- **Involuntary autobiographical memory.** [Cue-triggered, spontaneous, most frequent
  during diffuse-attention / idle moments, mostly positive+mundane recent events](https://pmc.ncbi.nlm.nih.gov/articles/PMC4552601/).
  Rewisp's nudge is *artificial involuntary memory* — and the science says *when* to fire
  it (idle) and *what* to surface (present-cue-relevant, recent, positive).
- **Targeted memory reactivation.** [Re-presenting a learning cue strengthens that specific
  memory](https://pmc.ncbi.nlm.nih.gov/articles/PMC9649863/) (studied during sleep, but the
  cueing principle is general). Rewisp deciding *what to re-surface* is a waking analogue.
- **Memory's real purpose is future simulation.** [Episodic memory and imagining the future
  share one neural system](https://pmc.ncbi.nlm.nih.gov/articles/PMC2666704/); memory exists
  to **simulate scenarios and make better decisions**, not to recall accurately. This is the
  deepest lever: a memory tool that helps you *decide*, not just *retrieve*.
- **Lifelogging is clinically validated.** [SenseCam passively-captured cues measurably
  restore autobiographical recall in memory-impaired patients](https://pmc.ncbi.nlm.nih.gov/articles/PMC51669983/) —
  but only when review *reinstates the original thoughts/feelings*, not just shows a log.
  There's a real accessibility/health story here almost nobody in consumer software owns.

---

## Part 4 — Differentiating directions (hard, novel, un-copied)

Ranked by moat strength. Each: the idea, the science under it, why it's a moat, and the
honest reason it's hard.

### A. Context Reinstatement — "put me back where I was"
**Idea:** don't just answer "what was that API rate limit?" — *reconstruct the moment*.
Rebuild the screen-state (the surrounding text, the tab, the adjacent code, the time, what
you did right before/after) as a navigable "you were here" card, so recall is cued the way
the brain actually retrieves.
**Science:** [encoding specificity / context-dependent memory](https://en.wikipedia.org/wiki/Context-dependent_memory)
— reinstating context is the single strongest known recall enhancer, and it's why
[SenseCam works](https://pmc.ncbi.nlm.nih.gov/articles/PMC51669983/).
**Moat:** requires reconstructing *scene context* from stored text over time — trivial for
us, impossible for a video tool (and a search box has no concept of "the moment"). No
competitor frames retrieval as reinstatement.
**Hard because:** you must reconstruct a coherent "scene" from noisy OCR fragments across
adjacent captures, model before/after, and present it so it *feels* like being back there.
Almost no product research exists on this; it's a genuine HCI design problem.

### B. Tip-of-the-Tongue Rescue — catch the gap in real time
**Idea:** detect the *behavioral signature* of a retrieval failure as it happens — you
start typing a name and delete it, you re-search the same thing three ways, you pause and
switch to Google — and surface the answer at that exact instant, unprompted.
**Science:** [TOT/FOK are detectable metamemory states that predict recoverable knowledge](https://pmc.ncbi.nlm.nih.gov/articles/PMC12047626/);
firing during [diffuse-attention gaps](https://pmc.ncbi.nlm.nih.gov/articles/PMC4552601/) is
exactly when involuntary memory naturally helps.
**Moat:** needs the full local behavioral stream (keystroke hesitation, search reformulation,
app-switch-to-search) — a cloud tool can't watch this, and a search box is reactive by
definition. This is proactive at the millisecond of need.
**Hard because:** modeling "this person is stuck right now" from raw interaction signals is
unresearched in consumer software, high false-positive risk, and must never interrupt when
you're fine. It's a signal-detection problem on top of an interruption-UX problem.

### C. Decision Provenance — the un-rewritten record of *why*
**Idea:** "why did I choose X?" → the frozen evidence trail (what you compared, prices *as
they were*, the review that tipped you), and it can *contradict your rewritten memory*.
**Science:** [reconsolidation](https://pmc.ncbi.nlm.nih.gov/articles/PMC5605913/) +
[choice-supportive misremembering](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2017.02062/full)
— your memory of your decisions is *systematically falsified*, and Rewisp holds the truth.
**Moat:** backward evidence-chaining over text + numbers + embeddings — a few queries for us,
weeks of video review for them. (Full plan already in FABLE5-THOUGHTS §4.1.)
**Hard because:** detecting decision moments and reliably chaining the *causal* evidence
(vs. merely co-occurring) is genuinely open research.

### D. Memory as Future-Simulator — decide, don't just recall
**Idea:** the endgame. "Should I take this?" → Rewisp simulates from your own history:
"last two times you took on a Fri-deadline project mid-quarter, you missed it; here's what
that week looked like." A memory that runs *what-ifs* on your past to inform the future.
**Science:** [episodic memory and future simulation are one system; memory exists to
simulate and decide](https://pmc.ncbi.nlm.nih.gov/articles/PMC2666704/), not to recall.
**Moat:** this is the *purpose* of memory, and literally no memory product attempts it. It's
the deepest possible differentiator — "Rewisp doesn't remember your past, it uses it."
**Hard because:** requires pattern-mining outcomes over long horizons and generating
faithful, non-hallucinated simulations — the hardest thing in this doc, and mostly
un-attempted anywhere. High bar; high payoff.

### E. Self-generating Retrieval Practice (the *right* slice)
**Idea:** for **factual content you read** (docs, articles, specs) — not your life — Rewisp
quietly builds spaced retrieval prompts so it *sticks*, no flashcard authoring. Turns
passive reading into durable knowledge automatically.
**Science:** [testing effect +30–50%](https://recallify.ai/evidence-for-active-recall-and-spaced-repetition/),
scheduled by your *own* [personal forgetting curve](https://pmc.ncbi.nlm.nih.gov/articles/PMC7334729/)
(which we already fit). **Critically bounded** by the finding that [it doesn't work on
autobiographical memory](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5976790/) — so this
must target read-content only.
**Moat:** every spaced-repetition tool needs manual card creation; Rewisp already has the
content *and* your personal curve, so it's zero-effort. Anki-class tools can't follow (no
ambient content); ambient tools can't follow (no learning model).
**Hard because:** deciding *what's worth remembering* (vs. noise) and generating good
prompts on-device without being annoying is a real quality problem.

### F. Serendipity Engine — the connection you'd never search for
**Idea:** surface non-obvious links across your own history — "the pricing model in this
doc is the same one from that podcast 3 weeks ago" — connections you'd never think to query.
**Science:** [personal knowledge graphs make implicit relationships explicit and foster
serendipitous discovery](https://www.webmap.network/blog/personal-knowledge-graphs-ai-that-maps-human-thinking/);
[just-in-time insight recall](https://arxiv.org/pdf/2506.20156) is an active research frontier.
**Moat:** needs an entity/relationship graph over *all* your text with semantic linking —
we have the embeddings + episodes already. Search-box tools can't surface what you don't ask.
**Hard because:** precision. Most "connections" are noise; surfacing the 1 that matters
without burying it in 100 junk links is unsolved (it's why graph views in PKM tools go unused).

---

## Part 5 — The one big bet, and what to research next

If I had to name **the** differentiator: **Rewisp models *you*, not your screen** — and the
sharpest expression of that is the pairing of **Context Reinstatement (A)** as the near-term,
demoable, science-backed win, building toward **Memory-as-Future-Simulator (D)** as the
category-defining endgame. Both are things the science says are real and no product has done.

Un-obvious cross-cutting finding worth its own track: **behavioral signals are a goldmine we
already sit on.** Failed searches, reformulations, dwell, re-reads, hesitation — the raw
material for TOT-rescue (B), the forgetting model (shipped), and even a private "cognitive
state" read. Cloud tools can't touch this data ethically; we can, locally.

**Main questions to move on (pick a direction and I'll go deep + prototype):**

1. **Context Reinstatement (A)** — can we reconstruct a coherent, cue-rich "you were here"
   scene from adjacent OCR captures well enough that it *feels* like being back? (Design +
   feasibility spike.) *My pick for near-term.*
2. **TOT-Rescue (B)** — what behavioral signature reliably = "stuck retrieving," and can we
   detect it locally with an acceptable false-positive rate? (Signal study on your own data.)
3. **Future-Simulator (D)** — can we mine outcome patterns from history and generate
   faithful what-ifs without hallucinating? (The moonshot; needs careful scoping.)
4. **Retrieval Practice on read-content (E)** — narrowest, safest, shippable; bounded by the
   autobiographical caveat. Good "prove the loop" candidate.
5. **Behavioral-signal track** — formalize the interaction stream (keystroke/dwell/search
   telemetry, all local) as the substrate B, D, and the forgetting model all draw on.

**What I would NOT chase:** anything that's just "capture better," anything requiring cloud
to model the user (kills the moat), and retrieval practice on autobiographical memory (the
science says it won't work).

---

## Sources (representative — the reasoning draws on the full result sets behind each)

- Reconsolidation: [PMC5605913](https://pmc.ncbi.nlm.nih.gov/articles/PMC5605913/)
- Context-dependent memory / encoding specificity: [Wikipedia](https://en.wikipedia.org/wiki/Context-dependent_memory), [VR reinstatement study PMC9732332](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9732332/)
- Lifelogging / SenseCam clinical: [PMC51669983](https://pmc.ncbi.nlm.nih.gov/articles/PMC51669983/), [CMU Lee et al.](http://www.cs.cmu.edu/~mllee/docs/UbiComp229-lee.pdf)
- Competitive landscape + "synthesis not capture": [Screenpipe 2026](https://screenpipe.com/blog/best-ai-screen-recorder-2026)
- Testing effect (and autobiographical caveat): [Recallify evidence](https://recallify.ai/evidence-for-active-recall-and-spaced-repetition/), [PMC5976790](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5976790/)
- Personalized forgetting curves: [PMC7334729](https://pmc.ncbi.nlm.nih.gov/articles/PMC7334729/)
- Metamemory / TOT / FOK: [PMC12047626](https://pmc.ncbi.nlm.nih.gov/articles/PMC12047626/)
- Google effect / transactive memory: [Google effect (Wikipedia)](https://en.wikipedia.org/wiki/Google_effect), [TMS scale PMC4419599](https://pmc.ncbi.nlm.nih.gov/articles/PMC4419599/)
- Targeted memory reactivation: [PMC9649863](https://pmc.ncbi.nlm.nih.gov/articles/PMC9649863/)
- On-device screen understanding: [Apple Screen Recognition](https://machinelearning.apple.com/research/creating-accessibility-metadata), [Screen2AX arXiv 2507.16704](https://arxiv.org/pdf/2507.16704)
- Involuntary autobiographical memory: [PMC4552601](https://pmc.ncbi.nlm.nih.gov/articles/PMC4552601/)
- Personal knowledge graphs / serendipity / just-in-time insight: [webmap.network](https://www.webmap.network/blog/personal-knowledge-graphs-ai-that-maps-human-thinking/), [Irec arXiv 2506.20156](https://arxiv.org/pdf/2506.20156)
- Episodic future thinking / memory-as-simulation: [PMC2666704](https://pmc.ncbi.nlm.nih.gov/articles/PMC2666704/)
- Choice-supportive misremembering: [Frontiers 2017](https://www.frontiersin.org/journals/psychology/articles/10.3389/fpsyg.2017.02062/full)
