# HSC Essay Engine for Mac (v1.0.1)

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
Replace `Resources/index.html` with a newer version and run `bash build.sh --install` again. Your progress is kept.
