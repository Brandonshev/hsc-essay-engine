# Handoff: building an app in the "HSC Essay Engine" style

**Source app:** HSC Essay Engine · content v2.1.0 · Mac app v1.1.0
**Repo:** https://github.com/Brandonshev/hsc-essay-engine (public)
**Use this doc to:** build a new study app (another subject, text or skill) that teaches and looks the same way.

---

## 1. The idea in one line

Turn a fuzzy skill into **formulas**, show it being **built step by step**, then make the student **try it, get feedback, and drill it** until it's automatic.

Built for a learner with a **maths / formulaic brain**: everything is broken into barebones steps, named with letters, and colour-coded.

---

## 2. Teaching method (the most important part)

Every skill goes through the same loop:

```
LEARN (formula + "like you're 8" explanation)
  → SEE (colour-coded worked example + animated build)
  → TRY (mission box with a code, e.g. HW-Q1)
  → FEEDBACK (copy to Claude, or "Check it here" in the page)
  → DRILL (short repeatable rounds, wrong answers come back)
```

Rules that make it work:

1. **Every formula is an equation.** e.g. `THESIS = IDEA + TWIST`, `PARAGRAPH = P + (IQTVE) × 3 + L`. Letters, not paragraphs of advice.
2. **Every formula has a "Like you're 8" box**: 2–3 plain sentences.
3. **Every formula has a ✗ weak vs ✓ strong example** side by side.
4. **One colour per part, used everywhere** (formulas, exemplar, animations, drills). The student learns the colours, then sees the pattern repeat.
5. **Every concept ends with "Your turn"**: a mission with a code. Never explain without asking the student to try.
6. **Mission codes travel.** The copy button sends `[CODE] app version · subject · task · formula · my answer · marking request`, so any new Claude chat knows exactly what's being marked.
7. **Honest marking.** Score out of 5 per skill, "What works / Fix / Upgraded version". Never inflate.
8. **The student's teacher wins.** If the teacher's structure differs, the app adopts it (e.g. intro changed from TCR to the teacher's D·T·CR; QTE upgraded to the tutor's IQTVE).
9. **Verify every quote / fact against a source.** Mark anything unverified "check in your book". Never invent quotes.

### Formulas currently in the app (essay writing)

| Part | Formula |
|---|---|
| Whole essay | `D·T·CR · P(IQTVE)×3L ×3 · RS` |
| Intro | **D**efinition + **T**hesis + **C**ontextual **R**oadmap (+ extent if "to what extent") |
| Thesis | IDEA + TWIST ("Harwood shows ___, yet ___") |
| Analysis unit | **I**dea → **Q**uote → **T**echnique → **V**erb → **E**ffect |
| Body paragraph | P + IQTVE × 3 + L (order: loss → struggle → growth, or small → big) |
| Conclusion | **R**estate + **S**ummarise + **W**ider significance |
| Plan (5 min) | keyword → idea + twist → pick texts → 3 quotes each |
| Zoom method | underline 2–3 words → technique + meaning each → pick the one that proves I → build IQTVE |
| Thesis algorithm | keyword → plain-words answer → find the catch (the text that doesn't fit) → template → 3-check test |

> Note: the live app (v2.1.0) still says QTE in places; IQTVE (the tutor's formula) should replace it in the next content update.

---

## 3. App sections (tabs)

| # | Tab | What it does |
|---|---|---|
| 01 | Start here | Where the topic sits in the exam, the whole formula in one line (`bigcode` banner), how to use the app, what markers want |
| 02 | The formula | One card per formula: equation → "like you're 8" → ✗/✓ example → mission box |
| 03 | Analysis ladder | One quote analysed at 6 levels (L0 retell → L5 judgement), tap to switch |
| 04 | Content cards | One card per text/poem: story in one line, idea tags, form, starter quotes, a personal quote-bank textarea (saved) + an SVG mind map + context hooks |
| 05 | Watch it built | "Videos" = animated step players (play/pause/next, speed), each frame adds one coloured piece |
| 06 | Exemplar | Full model essay, every sentence wrapped in `data-part` spans, colour toggle, word count, a weak vs strong comparison |
| 07 | Missions | All missions listed with done/to-do, tap to jump |
| 08 | Drills | Multiple-choice, tap-the-keywords and tap-in-order drills; streak + best scores |
| 09 | Timed writing | Timer (5/12/40 min), live word/quote counts, rule-based self-audit, copy-for-Claude, in-page AI marking |
| 10 | Plan | Day-by-day plan to the assessment date |
| 11 | Coming later | Placeholders for the next texts/modules |

Header stats: reps today, day streak, missions done, accuracy.

---

## 4. Architecture

### Web app (`web/index.html`)
- **One self-contained HTML file.** Vanilla JS, no framework, no build step. Inline CSS + JS. Only external load: Google Fonts.
- **Routing:** `location.hash` (`#start`, `#formula`…), one `<section class="view" id="v-NAME">` per tab; `route()` toggles `.active`.
- **State:** one object `S` in `localStorage` under key `hsc-essay-engine-v1`, wrapped in try/catch. Holds `days` (reps per date → streak), `total`, `right`, `best` (per drill), `m` (missions: text + done), `qb` (quote banks), `q`/`draft` (timed writing).
- **Version:** `var VERSION = "x.y.z";`. The Mac updater reads this exact pattern, so keep the format.
- **Content lives in JS data arrays**, so a new subject = new data, same engine:

| Array | Shape | Used by |
|---|---|---|
| `MISSIONS` | `{code, title, where, formula, task, hint}` | mission boxes (`<div class="mission" data-mission="CODE">`) |
| `POEMS` (rename per subject) | `{id, t, yr, story, ideas[], form, q:[[quote, note]], link}` | content cards |
| `RUNGS` | `{lv, name, band, txt, why}` | analysis ladder |
| `EPISODES` | `{title, frames:[{cap, parts:[[colourClass, text]], note}]}` | animated player |
| `TECH` | `[quote, answer, [distractors], why]` | "Name the technique" |
| `WHICH` | `[quote, sourceText]` | "Which poem?" |
| `WS` | `[strong, weak, why]` | "Weak or strong?" |
| `VERBS` | `[sentence with ____, answer, [distractors], why]` | "Upgrade the verb" |
| `DECODE` | `{q, keys[], why}` | "Decode the question" (tap keywords) |
| `ORDER` | `{title, parts[] in correct order}` | "Build in order" |
| `QUESTIONS` | `string[]` | timed-writing random question |
| `BANK` | `{t, items[]}` | word bank chips |

- **Drill engine:** three runners: `runMC` (8 items/round, wrong answers re-queued, first-try accuracy scored), `runDecode`, `runOrder`. Each calls `rep(ok)` (streak/accuracy) and `finish(id, pct)` (best score).
- **"Spot the part" drill is generated from the exemplar's `data-part` spans**, so editing the essay automatically updates the drill.
- **Copy to clipboard:** `navigator.clipboard.writeText` with an `execCommand('copy')` fallback (needed in sandboxed views).
- **In-page AI marking (claude.ai only):** `await claude.use("sample")` returns null elsewhere, so the buttons stay hidden. The artifact must declare `capabilities: {sample: {}}`. Prompts ask for a fixed format (Score / What works / Fix / Upgraded) and to flag inaccurate quotes.
- **Self-audit:** pure regex heuristics (word count vs target, quote count, texts named, "shows" count, plot-sequence words, generic openers, twist word in the first sentence, question keywords used). Clearly labelled "pattern checks only".

### Mac app (`mac/`)
- `Sources/main.swift`: AppKit + `WKWebView` loading `index.html`. No Xcode project; built with `swiftc`.
- **Progress survives updates:** a user script wraps `Storage.prototype.setItem` and posts the state key to native, which saves it in `UserDefaults` and restores it at document start.
- **Auto-update:** on launch and via Cmd U, it fetches `raw.githubusercontent.com/<user>/<repo>/main/web/index.html`, compares `VERSION`, and saves newer content to `~/Library/Application Support/<App>/index.html`, which it then loads. **The repo must be public** for this.
- Menus: Edit (needed for copy/paste in text boxes), View (reload, zoom), Window.
- `build.sh`: compiles, copies `index.html` + `Info.plist`, builds `AppIcon.icns` from `icon-1024.png` with `sips` + `iconutil`, ad-hoc codesigns. `--install` copies to /Applications **and removes the local copy** (avoids duplicate apps).
- Icon: generated with Python PIL: blueprint-blue rounded square, faint grid, white page with coloured bars (the part colours).

### Hosting
- **claude.ai artifact**: phone + in-page AI marking.
- **GitHub repo**: source of truth; the Mac app updates from it.
- Content-only changes: bump `VERSION` → push → Mac app updates itself. Swift changes need a rebuild (`bash build.sh --install`).

---

## 5. Design system

```css
/* light */
--paper:#f3f5f9; --card:#ffffff; --ink:#14213a; --muted:#5a6680; --line:#d9dfea; --accent:#2350d8;
/* part colours (text / background) */
--c-thesis:#7b3fd0 / #efe6fb   (violet)   thesis, restate
--c-topic:#1f63d6  / #e3edfd   (blue)     point, roadmap
--c-evidence:#b26a00 / #fdf0d9 (amber)    quote + technique
--c-analysis:#178a4c / #dff4e8 (green)    effect
--c-context:#c43a64 / #fbe3ea  (rose)     context, definition
--c-link:#4b5d78   / #e7ebf2   (slate)    link, so what
--f-display:"Bricolage Grotesque"; --f-body:"IBM Plex Sans"; --f-mono:"IBM Plex Mono";
```

- **Look:** a maths-notebook "engine manual": faint 22px grid paper background, formulas in dashed mono `.eq` boxes, coloured `.var` pills for each variable.
- Full dark theme via `prefers-color-scheme` and `[data-theme="dark"]`.
- Mobile-first: sticky horizontally scrolling tab bar, cards stack to one column, 16px gutters.
- Key components: `.card`, `.eq`, `.var.v-*`, `.kid` ("like you're 8"), `.why.ok / .why.no` (✓/✗ examples), `.mission` (dashed accent border + `.code` badge), `.bigcode` (dark banner with the whole formula), `.rung` (ladder), `.dcard` (drill picker), `.opt` (answers), `.tok` (tap tokens).
- Respect `prefers-reduced-motion`; visible focus rings; no emoji as section markers.

---

## 6. How to adapt it to a new subject

1. **Find the official criteria** (syllabus, marking guidelines, marker feedback) and translate the band words into plain behaviour.
2. **Invent or adopt formulas.** Ask the student what their teacher/tutor uses first and adopt it.
3. **Pick the colour mapping**: one colour per formula part (keep 6 max).
4. **Write a verified exemplar** and wrap each sentence in `data-part`.
5. **Fill the data arrays** (section 4). Verify every quote/fact; mark unverified ones.
6. **Write missions** with a new code prefix (e.g. `OT-` for Othello, `MD-` for Mrs Dalloway/The Hours, `MA-` for maths).
7. **Write the study plan** backwards from the assessment date.
8. **Bump `VERSION`**, push, republish the artifact.

---

## 7. Lessons learned (avoid these)

- macOS ships **bash 3.2**: a non-ASCII character like `…` straight after `$VAR` breaks the script ("unbound variable"). Keep shell scripts ASCII and use `${VAR}`.
- `build.sh --install` must delete its local `.app`, or Launchpad shows duplicates.
- The updater can't read a **private** repo without embedding a token (don't do that). Make the repo public, or update by hand.
- **Don't put a personal email in public commits.** Use `<user>@users.noreply.github.com`.
- Harwood (and most modern texts) are under **copyright**: only short quotes for analysis; never paste whole poems into the app.
- Students often need the same correction repeatedly (e.g. apostrophes, "juxtapose *with*"). Feedback should flag repeats as patterns.

---

## 8. Starter prompt for a new chat

> I'm building a study app in the same style as my "HSC Essay Engine" (repo: Brandonshev/hsc-essay-engine, read HANDOFF.md). New subject: **[SUBJECT / TEXT]**. Assessment: **[TYPE, DATE, MARKS, TIME]**. My teacher's formula/structure: **[IF ANY]**.
>
> Use the same teaching loop (formula → "like you're 8" → ✗/✓ example → colour-coded exemplar → animated build → mission with a code → drills), the same single-file HTML architecture and data arrays, the same design system, and the same Mac wrapper + GitHub auto-updater. Verify every quote and fact, and mark anything unverified. After each concept, give me a mission to try with a code I can send back. Add a version number for debugging.
