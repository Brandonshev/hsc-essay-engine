<p align="center"><img src="icon.png" width="128" alt="HSC Essay Engine icon"></p>

# HSC Essay Engine

**v1.0.1** · A training tool for NSW HSC English Advanced essays, built for the new English Advanced 11–12 Syllabus (2024), first examined in 2027.

It breaks essay writing down into formulas, then drills them until they're automatic.

## What's inside

| Section | What it does |
|---|---|
| The exam | Paper 1 and Paper 2 layout, timing, word targets, essay skeleton diagram |
| What markers want | NESA band criteria translated into plain behaviour, plus 8 laws from HSC marker feedback |
| Formulas | F0–F8: whole essay, thesis, intro, topic sentence, analysis atom, body paragraph, conclusion, planning, self-check mark model |
| Analysis ladder | One quote analysed at six levels, from retelling to Band 6 judgement |
| Watch it built | Animated step-by-step builds of a thesis, a paragraph and a 40-minute exam run |
| Model essay | Full colour-coded Common Module essay on Lawson's "The Drover's Wife" |
| Per module | How the formula changes for Common Module, Module A, B and C |
| Drills | 7 drill types with explanations; missed questions repeat; streaks and best scores |
| Write + get marked | Timed sprints, live word count, automatic self-audit |
| Training plan | Daily routine and phases from now to the 2027 HSC |
| 2027 texts | Full prescribed text list |

## Two versions

- **`web/index.html`**: open in any browser. Works offline. Progress is saved in that browser.
- **`mac/`**: native Mac app wrapper. Build with:
  ```
  cd mac
  bash build.sh --install
  ```
  Needs the Xcode command line tools (`xcode-select --install`).

AI marking against the NESA criteria is only available in the claude.ai-hosted version of the page.

## Notes

- The model essay is original, written to the published 17–20 marking criteria. NESA does not publish real 20/20 scripts. Check quotes against your own edition of the prescribed text.
- Sources: NESA English Advanced 11–12 Syllabus (2024) exam specifications and course structure, and NESA's 2024 and 2025 HSC English Advanced marking guidelines and marking feedback.
