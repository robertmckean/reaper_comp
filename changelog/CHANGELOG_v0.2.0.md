# CHANGELOG v0.2.0

## Program Description

`copy_item_to_project_end.lua` is a REAPER Lua ReaScript for comp-audition layout building.
It copies a comp source from the selected source track into a new audition area at the end of the project, snaps the destination to the next measure boundary, explodes usable takes into sequential blocks, and duplicates the backing material from other tracks underneath each take block.

The script is non-destructive to the original recording area. It works from the selected media item and the current source region or time selection, trims copied material to the region boundaries, and keeps copied backing items on their original tracks.

## Recent Updates

- Added support for multiple comp media items within the selected region on the source track.
- Preserved the relative spacing and gaps between comp items inside each repeated take block.
- Added early validation based on usable takes only, ignoring empty take slots with no media source.
- Aborted before copy when comp items in the region do not have matching usable take counts.
- Updated take selection to use the Nth usable take instead of the raw Nth take slot.
- Kept backing copies on the same tracks as their original source items.
- Trimmed copied comp and backing items to the selected region boundaries.
- Cleared fades on copied comp items so contiguous take blocks do not inherit unwanted crossfade behavior.
- Changed repeated block placement from raw time offsets to quarter-note-based offsets to prevent drift from the beat grid across multiple loops.
