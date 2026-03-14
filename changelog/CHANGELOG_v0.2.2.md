# CHANGELOG v0.2.2

## Program Description

`copy_item_to_project_end.lua` is a REAPER Lua ReaScript for building a comp-audition layout at the end of a project.
It copies all comp items from the source track that overlap the selected region, explodes usable takes into sequential audition blocks, duplicates backing material from the other tracks underneath each block, and now marks the full exploded result with a project region.

The script remains non-destructive to the original recording area, trims copied material to the selected region boundaries, keeps copied backing items on their original tracks, and spaces repeated blocks by beat length instead of raw time.

## Updates In v0.2.2

- Added automatic project-region creation after a successful explode pass.
- Set the created region to span from the first exploded block start to the end of the final exploded block.
- Kept the region boundaries aligned to the same beat-based block spacing used for the repeated takes.
- Colored the created region yellow for visibility.
- Named the created region `Exploded Takes - {source track name}` using the exploded comp source track name.
