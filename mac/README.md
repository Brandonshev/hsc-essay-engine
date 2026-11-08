# HSC Essay Engine for Mac (v1.1.0)

A native Mac app version of the essay training page. It works offline and keeps your progress between launches.

## Install (about 1 minute)

1. Clone or download this repo.
2. Open **Terminal** and run:

```
cd hsc-essay-engine/mac
bash build.sh --install
```

3. The app opens and is now in Applications. Drag it to your Dock.

If it says the Swift compiler isn't found, run `xcode-select --install`, wait for it to finish, then repeat step 2.

## Notes
- Everything works offline. Fonts look slightly different without internet.
- Claude marking only works in the claude.ai version. The self-audit works here.
- Progress (reps, streak, best scores, your draft) is saved in the app.
- Cmd + / Cmd − to zoom. Cmd R to reload.

## Updating
The app updates its own content: on launch, or with Cmd U, it checks GitHub for a newer `web/index.html` and installs it. The repo must be public for this. You only need to rebuild when the app itself (the Swift code) changes. Your progress is kept either way.
