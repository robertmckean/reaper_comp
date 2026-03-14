# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Goal

Convert recorded drum audio (WAV) to structured MIDI output using a trained
convolutional neural network. Input is a raw audio waveform. Output is a MIDI
heat map containing note number, relative timing (3ms resolution), and velocity.

## Project Status

Working notebook: `DrumMidi_Working_LOCAL_00_GM.ipynb` (in project root)
Original notebook/data source location: `C:\Users\windo\OneDrive\Python\drums_to_midi\00_GM\`
This project refactors that notebook into a maintainable Python codebase.

**Phase 1** (current) — Convert notebook to .py files as-is, minimal changes, verify it runs
**Phase 2** — Improve architecture, metrics, and training infrastructure
**Phase 3** — Modernize with better audio backbone if results warrant it

Do not skip to Phase 2 until Phase 1 is verified working.

## Commands

```powershell
# Environment setup (Anaconda, Python 3.10)
conda activate drum310
pip install -r requirements.txt

# Launch Claude Code session (from Windows)
claude_win.bat

# Training (once src/train.py is complete)
python src/train.py

# Inference (once src/infer.py is complete)
python src/infer.py
```

## Architecture Overview

```
WAV file (44.1kHz mono)
    └── AudioSliceDataset         # data.py - slices audio into 2.5s chunks
          └── DrumClassifier      # model.py - encoder-decoder CNN
                ├── STFT layer    # trainable, via nnAudio (n_fft=2048, hop=128)
                ├── Conv1D x3     # 1024 → 512 → 256 → 128 channels
                ├── MaxPool x3    # encoder downsampling
                └── ConvTranspose x3  # decoder upsampling → 127 output channels
    └── MIDI output (127 x 832)   # note x time_step heat map
```

## Data Pipeline (Y labels)

The MIDI ground truth goes through two stages before training:

1. **robert.py** (`src/robert.py`) — `process_midi_file()` reads raw MIDI CSV
   (exported from Reaper), slices into 2.5s indexed loops, scales note/time
   columns, inserts gap loops for alignment, truncates to 832 time steps.
   Returns `list_of_midi_arrays` (list of Nx3 arrays: note, loop_time, vel).

2. **process_list_of_midi_arrays()** (in data.py / notebook cell 11) — converts
   each Nx3 array into a (127, 832) dense heatmap where `[note, time] = velocity`.
   Returns `list_of_processed_midi`.

The X data (audio) is loaded and sliced by `AudioSliceDataset.__init__()`.
**Important**: the refactored code currently uses `soundfile.read()`.

## Key Parameters

All hyperparameters live in `config.py`. Critical values:

- Sample rate: 44100 Hz
- Slice length: 2.5 seconds (110,250 samples)
- STFT: n_fft=2048, hop_length=128, win_length=2048, trainable=True
- Output shape: (127, 832) — 127 MIDI notes x 832 time steps (3ms resolution)
- BPM: 120, ticks: 960, slice_ticks: 4800
- GPU: NVIDIA RTX 3080, <8GB VRAM target
- Batch size: 32, epochs: 300, lr: 1e-4
- Velocity threshold: 9.5 (out of 127) for inference hit detection

## Environment

- Python 3.10 (Anaconda env: `drum310`)
- PyTorch, nnAudio, soundfile, scipy, numpy, matplotlib, mido
- Prefer native Windows PowerShell commands for this repo
- Source data in `C:\Users\windo\OneDrive\Python\drums_to_midi\00_GM\` (not copied locally)

## Saved Model

- See `config.py` for the active model load path and training/output paths
- Do not assume older notebook-era model filenames are still the current default

## Core Rules

| Rule ID | Description |
|---------|-------------|
| **UPF** | **User Problem First — investigate the user's stated problem first before exploring alternatives.** |
| **RCA** | **Root Cause Analysis — NEVER accept surface explanations. Dig into actual code logic.** |
| SCR | Strict Code Rules — All code must follow formatting and documentation rules |
| NBG | No Blind Guessing — No speculation without evidence in the actual code |
| FRR | File Review Rule — Complete code inspection before responding |
| NUD | No Unverified Deletions — Confirm all references before removing code |
| RPR | Refactor Paranoia — Prefer minimal, reversible changes |
| QCC | Quality Code Critical — Production-grade quality is mandatory |

## 0. Fundamental Interaction Rule (UPF)

**CRITICAL**: Start with the problem the user named.

### When User Identifies a Problem

1. IMMEDIATELY INVESTIGATE the exact problem they describe
2. DO NOT go off on tangents before checking that path
3. If the user's diagnosis appears incomplete, verify it in code before proposing alternatives
4. Stay focused on the concrete behavior they reported

### FORBIDDEN Behaviors

- Ignoring user's specific problem identification
- "Let me first check something else..."
- Making them repeat themselves multiple times
- Pursuing your own debugging theory before checking the reported issue

### REQUIRED Response Pattern

- "You said X is the problem - investigating X now"
- "Examining exactly what you described"

## 1. Code Documentation Requirements

- Every file must begin with:
  ```python
  # filename.py
  # Purpose: General description of the file's purpose
  # Features: Key functionality provided
  # Usage: How the module is expected to be used
  ```

- Every function requires an inline comment above its definition:
- Prefer a short comment above functions when the purpose is not already obvious from the name and surrounding code:
  ```python
  # Performs X operation on Y data and returns Z
  def function_name(params):
  ```

- Add descriptive inline comments at critical points without stating the obvious

## 2. Code Structure Rules

- Keep files responsible for a single area of functionality
- Functions should perform one clear task
- Use descriptive variable and function names
- NEVER RENAME functions or classes unless explicitly instructed
- RESPECT FILE BOUNDARIES: Don't move logic between files without approval

## 3. Root Cause Analysis Protocol (RCA)

When investigating ANY anomaly, error, or unexpected behavior:

1. READ THE ACTUAL CODE - Never explain behavior without examining the implementation
2. TRACE THE EXECUTION PATH - Follow the code from trigger to error
3. EXAMINE ALL VALIDATION LOGIC - Question every condition
4. FIND THE EXACT LINE - Identify the precise code that generates the behavior

### FORBIDDEN Surface-Level Responses

- "This is normal because..."
- "This usually happens when..."
- Accepting error messages without reading the code that produces them

### REQUIRED Deep Analysis

- "Let me examine the code in [filename:line] that generates this"
- "The logic at [filename:line] checks for X, but we have Y"

## 4. Change Management

- Present code changes as minimal patches with clear context
- Always specify file, full method/class name, and whether it's insertion/deletion/replacement
- NEVER USE APPROXIMATIONS like "something like this" or "your code should contain..."
- If exact code locations are unclear, ask for clarification rather than guessing

### Code Change Description Format

MANDATORY: Before every code edit, provide a one-line description:
- **This edit [describes what the code change does in plain English].**

## 5. Quality Standards

- PRODUCTION-GRADE CODE: This is a real ML system, not a tutorial project
- All hyperparameters must live in config.py, not scattered through code
- Training must include proper checkpointing — save best model, not just last
- Validation metrics must be meaningful — F1/precision/recall on non-zero hits, not just MSE accuracy

## 6. Response Format

- Avoid large headers — keep text uniform size
- Provide succinct explanations with fixes
- Don't offer affirmations or encouragement — deliver results
- When asked to trace execution, include file, class, method, and path
- Do not summarize code in detail unless requested

## 7. Notes

- Prefer `config.py` and the current `src/` code over stale documentation
- Use backward-compatible fixes when dependencies are not pinned
- Before training, check whether `models/checkpoint_resume.pth` exists so you know whether the run will resume or start fresh
- When pushing code, add a changelog entry and increment the patch version in `v0.X.Y` form unless the user explicitly provides a different version number
