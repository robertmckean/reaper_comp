# CHANGELOG v0.2.4

## Program Description

`copy_item_to_project_end.lua` is a REAPER Lua ReaScript for building a comp-audition layout at the end of a project.
It copies all comp items from the source track that overlap the selected region, explodes usable takes into sequential audition blocks, duplicates backing material from the other tracks underneath each block, and marks the full exploded result with a project region.

The repo also includes workspace and deployment support files used to edit, launch, and understand the script from VS Code.

## Updates In v0.2.4

- Added a ReaScript metadata header to `copy_item_to_project_end.lua` for release metadata.
- Set the script `@version` to `0.2.4` so it matches the repository release version.
- Updated `README.md` so the current script behavior, `SCRIPT_FLOW.md`, and deploy target path are described accurately.
