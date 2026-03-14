# AGENTS.md

This file provides guidance to Codex and other coding agents when working in this repository.

## Project Goal

Convert recorded drum audio (WAV) to structured MIDI output using a trained
convolutional neural network. Input is a raw audio waveform. Output is a MIDI
heat map containing note number, relative timing, and velocity.

## Project Status

- Working notebook: `DrumMidi_Working_LOCAL_00_GM.ipynb`
- This repository is the Python refactor of that notebook
- Current priority: keep the refactor working end-to-end before broad architectural changes

## Environment

- Use the `drum310` Conda environment for all Python commands in this repo
- Prefer commands that work in Windows PowerShell
- Assume Codex is commonly launched from `codex_start.bat`
- Treat `config.py` and the current `src/` code as the source of truth when documentation is stale

## Commands

```powershell
conda activate drum310
python src\train.py
python src\infer.py
```

## Working Style

- Investigate the user's stated issue first before exploring alternatives
- Do not guess about behavior without reading the code that produces it
- Prefer minimal, reversible changes over broad rewrites
- Do not rename functions, classes, files, or move logic across files unless necessary
- Respect existing file boundaries unless the task requires a structural change

## Training And Model Safety

- Never intentionally overwrite an existing saved model `.pth` file
- New training runs should save best models to timestamped filenames
- Before running training, check whether `models/checkpoint_resume.pth` exists and state whether the run will resume or start fresh
- Warn when a command will overwrite generated artifacts such as `files/training_loss.png`, `files/training_f1.png`, or inference images

## Validation

- After changes to `src/model.py`, `src/data.py`, `src/train.py`, `src/infer.py`, or `config.py`, run the smallest useful sanity check in `drum310`
- Prefer targeted validation first: import path, model load, dataset build, one inference slice, then full CLI path if needed
- If a command is environment-sensitive, verify it is running in `drum310`

## Dependencies

- Because `requirements.txt` is unpinned, prefer backward-compatible fixes unless the task explicitly includes dependency upgrades
- If a change depends on a newer package API, add a compatibility fallback or pin the dependency intentionally
- Avoid replacing core dependencies unless there is a clear user request or a concrete technical reason

## Documentation And Comments

- Keep the existing top-of-file header comment pattern in Python files
- Add comments only where they clarify non-obvious logic
- Do not force comment-heavy rewrites of otherwise clear code
- If repo guidance is stale, update it rather than silently following outdated instructions
- When pushing code, add a changelog entry and increment the patch version in `v0.X.Y` form unless the user explicitly provides a different version number

## Review Priorities

- Prioritize regressions, stale guidance, environment mismatches, unsafe training behavior, and model save-path risks
- When reviewing changes, prefer concrete findings with file and line references over broad summaries
