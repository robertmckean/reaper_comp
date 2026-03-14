-- Return the first selected media item, or nil if none is selected.
local function get_selected_item()
    return reaper.GetSelectedMediaItem(0, 0)
end

-- Scan all media items in the project and return the latest item end position.
local function get_project_last_item_end()
    local item_count = reaper.CountMediaItems(0)
    local max_end = 0.0

    for i = 0, item_count - 1 do
        local item = reaper.GetMediaItem(0, i)
        local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        local end_pos = start_pos + length

        if end_pos > max_end then
            max_end = end_pos
        end
    end

    return max_end
end

-- Return the first bar start after the supplied time position.
-- This version assumes 4/4 and snaps to beat 1 of the next measure.
local function get_next_measure_start_after_time(time_pos)
    local qn_at_time = reaper.TimeMap2_timeToQN(0, time_pos)

    -- In 4/4, each measure is 4 quarter notes.
    local next_measure_qn = math.floor(qn_at_time / 4 + 1) * 4
    local next_measure_time = reaper.TimeMap2_QNToTime(0, next_measure_qn)

    return next_measure_time
end

-- Return the target paste position:
-- first beat of the first measure occurring after a point that is at least 3 beats
-- beyond the last item end.
local function get_target_paste_position(last_item_end)
    local bpm = reaper.TimeMap2_GetDividedBpmAtTime(0, last_item_end)
    local seconds_per_beat = 60.0 / bpm
    local minimum_time = last_item_end + (3.0 * seconds_per_beat)

    return get_next_measure_start_after_time(minimum_time)
end

-- Copy the selected item and paste it at the requested position.
local function copy_and_paste_item_to_position(item, target_pos)
    reaper.SelectAllMediaItems(0, false)
    reaper.SetMediaItemSelected(item, true)
    reaper.UpdateArrange()

    reaper.Main_OnCommand(40057, 0) -- Item: Copy items
    reaper.SetEditCurPos(target_pos, true, false)
    reaper.Main_OnCommand(42398, 0) -- Item: Paste items/tracks
end

-- Main entry point for the script.
local function main()
    local item = get_selected_item()

    if not item then
        reaper.ShowMessageBox("No media item selected.", "Error", 0)
        return
    end

    local last_item_end = get_project_last_item_end()
    local target_pos = get_target_paste_position(last_item_end)

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    copy_and_paste_item_to_position(item, target_pos)

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    reaper.Undo_EndBlock("Copy selected item to project end on next measure", -1)
end

main()