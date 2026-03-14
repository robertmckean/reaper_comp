# CHANGELOG v0.2.1

## Program Description

`copy_item_to_project_end.lua` is a REAPER Lua ReaScript for building a comp-audition layout at the end of a project.
It copies all comp items from the source track that overlap the selected region, explodes usable takes into sequential audition blocks, and duplicates backing material from the other tracks underneath each block.

The script preserves the original recording area, trims copied material to the selected region boundaries, and keeps copied backing items on their original tracks.

## Updates In v0.2.1

- Counted usable takes instead of raw take slots, ignoring empty takes with no media source.
- Added early abort when comp items in the region do not share the same number of usable takes.
- Updated take selection so the script uses the Nth usable take instead of the raw Nth take slot.
- Cleared fades on copied comp items so contiguous loops do not inherit unwanted fades.
- Changed repeated block spacing from raw time offsets to quarter-note-based spacing to keep loops aligned to the beat grid.
- Added one-sample region-edge tolerance so items touching the region boundary are not incorrectly treated as overlapping.
- Confirmed that visible color changes across loops come from take colors rather than item colors.
