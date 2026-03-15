# Script Flow Overview

This project currently has one main Lua script:

- [copy_item_to_project_end.lua](/C:/Users/windo/VS_Code/reaper_comp/copy_item_to_project_end.lua)

## How Lua Runs Here

Lua does not require a special `main` file the way some other languages do. A script runs from top to bottom when REAPER executes it.

In this file, most functions are defined first with:

```lua
local function some_helper()
```

That only defines the function. It does not run it yet.

At the very bottom of the file, this line is what actually starts the script:

```lua
main()
```

So the execution model is:

1. REAPER runs the file.
2. Lua reads the file from top to bottom and creates all the helper functions.
3. Lua reaches `main()`.
4. `main()` starts calling the helper functions it needs.

## What `main()` Does

`main()` is the real entry point for the script.

Its job is:

1. Get the selected media item.
2. Decide what source region to use.
3. Gather the comp items from the selected track.
4. Gather overlapping backing items from other tracks.
5. Validate that the comp items all have matching usable take counts.
6. Find a target position near the end of the project.
7. Copy and explode the takes there.
8. Create a project region covering the new exploded section.

If anything important is missing, `main()` shows an error message and exits early.

## High-Level Call Flow

This is the practical call chain:

```text
main()
  -> get_selected_item()
  -> get_source_region()
     -> get_item_bounds()   [if no time selection exists]
  -> collect_comp_items()
     -> item_overlaps_region()
        -> get_item_bounds()
        -> get_sample_tolerance()
     -> get_take_count()
     -> get_usable_take_count()
        -> get_take_count()
  -> collect_backing_items()
     -> item_overlaps_region()
        -> get_item_bounds()
        -> get_sample_tolerance()
  -> get_shared_usable_take_count()
  -> get_project_last_item_end()
     -> get_item_bounds()
  -> get_target_paste_position()
     -> get_next_measure_start_after_time()
  -> explode_takes_to_project_end()
     -> get_shared_usable_take_count()
     -> get_region_length_qn()
     -> copy_comp_items_to_position()
        -> duplicate_item_to_position()
        -> trim_duplicated_item()
        -> clear_item_fades()
        -> set_item_to_take_number()
           -> get_usable_take_by_number()
              -> get_take_count()
        -> copy_item_color()
     -> copy_backing_items_to_position()
        -> duplicate_item_to_position()
        -> trim_duplicated_item()
  -> create_exploded_takes_region()
     -> get_shared_usable_take_count()
     -> get_region_length_qn()
```

## Why So Many Functions Appear "Unused"

They are not meant to be called directly from outside the file.

Most of them are:

- `local`, so they only exist inside this script file
- helper functions called by other helper functions
- organized so that `main()` stays readable

So even if a function is not called directly by `main()`, it may still be part of the real execution path through another function.

Example:

- `main()` calls `explode_takes_to_project_end()`
- that calls `copy_comp_items_to_position()`
- that calls `set_item_to_take_number()`
- that calls `get_usable_take_by_number()`

That means `get_usable_take_by_number()` is still part of the runtime path even though `main()` never names it directly.

## Simple Mental Model

You can think of the file in three layers:

1. Small utility helpers
   Functions like item bounds, take counts, trimming, colors, and overlap checks.
2. Mid-level operations
   Functions that collect items, copy items, and explode takes.
3. Entry point
   `main()`, which coordinates the whole workflow and is the only function called at file end.

If you want to understand behavior, start at `main()`, then follow only the functions it calls.
