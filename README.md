# reaper_comp

REAPER Lua script project for comp-audition automation.

## Purpose

This repo is the source-of-truth workspace for developing REAPER ReaScripts that help audition multiple recorded takes in context. The current prototype copies a selected media item to the end of the project on the next measure boundary.

Longer term, the tool is intended to support region-based take explosion, marker creation, and backing-track preparation for faster comp review.

## Project Layout

- `copy_item_to_project_end.lua` - current working prototype script
- `deploy.ps1` - copies the script into REAPER's Lua directory
- `.vscode/settings.json` - Lua language support configuration for REAPER scripting

## Development Workflow

1. Edit the Lua script in this repo.
2. Run `deploy.ps1` to copy the current script into REAPER.
3. Run the script from REAPER and test behavior there.
4. Commit and push changes from this repo.

## Deploy Target

`deploy.ps1` currently deploys to:

`C:\Users\windo\AppData\Roaming\REAPER\lua\rjm\copy_item_to_project_end.lua`

## Git

This folder is the git repo and should remain the canonical source.

Do not use REAPER's `AppData\Roaming\REAPER\lua` directory as the primary development location.
