# CHANGELOG v0.2.3

## Program Description

`copy_item_to_project_end.lua` is a REAPER Lua ReaScript for building a comp-audition layout at the end of a project.
It copies all comp items from the source track that overlap the selected region, explodes usable takes into sequential audition blocks, duplicates backing material from the other tracks underneath each block, and marks the full exploded result with a project region.

The repo also includes workspace and deployment support files used to edit, launch, and understand the script from VS Code.

## Updates In v0.2.3

- Added `SCRIPT_FLOW.md` to explain how the Lua script executes, where `main()` is called, and how helper functions participate in the runtime call chain.
- Updated the VS Code workspace file so new integrated terminals start in the workspace folder.
- Kept the workspace rooted at the project directory through the local `.code-workspace` file.
