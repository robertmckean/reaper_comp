-- Return the first selected media item, or nil if none is selected.
local function get_selected_item()
    return reaper.GetSelectedMediaItem(0, 0)
end

-- Return the number of takes on the media item.
local function get_take_count(item)
    return reaper.CountTakes(item)
end

-- Return the number of usable takes on the media item.
-- A usable take must have a media source.
local function get_usable_take_count(item)
    local usable_take_count = 0
    local take_count = get_take_count(item)

    for take_index = 0, take_count - 1 do
        local take = reaper.GetMediaItemTake(item, take_index)

        if take and reaper.GetMediaItemTake_Source(take) ~= nil then
            usable_take_count = usable_take_count + 1
        end
    end

    return usable_take_count
end

-- Return the Nth usable take (1-based), ignoring empty take slots.
local function get_usable_take_by_number(item, usable_take_number)
    local seen_usable_takes = 0
    local take_count = get_take_count(item)

    for take_index = 0, take_count - 1 do
        local take = reaper.GetMediaItemTake(item, take_index)

        if take and reaper.GetMediaItemTake_Source(take) ~= nil then
            seen_usable_takes = seen_usable_takes + 1

            if seen_usable_takes == usable_take_number then
                return take
            end
        end
    end

    return nil
end

-- Return the item's start and end positions.
local function get_item_bounds(item)
    local start_pos = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    local length = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    return start_pos, start_pos + length
end

-- Return a one-sample time tolerance for region-edge comparisons.
local function get_sample_tolerance()
    local sample_rate = reaper.GetSetProjectInfo(0, "PROJECT_SRATE", 0, false)

    if sample_rate == nil or sample_rate <= 0 then
        sample_rate = 48000
    end

    return 1.0 / sample_rate
end

-- Duplicate an item onto its source track at the requested position.
local function duplicate_item_to_position(item, target_pos)
    local source_track = reaper.GetMediaItemTrack(item)
    local ok, chunk = reaper.GetItemStateChunk(item, "", false)

    if not ok then
        return nil
    end

    local new_item = reaper.AddMediaItemToTrack(source_track)

    if not new_item then
        return nil
    end

    if not reaper.SetItemStateChunk(new_item, chunk, false) then
        reaper.DeleteTrackMediaItem(source_track, new_item)
        return nil
    end

    reaper.SetMediaItemInfo_Value(new_item, "D_POSITION", target_pos)
    reaper.UpdateItemInProject(new_item)
    return new_item
end

-- Trim the duplicated item to the requested subrange of the original item.
local function trim_duplicated_item(item, trim_start_delta, new_length)
    local start_offset = reaper.GetMediaItemInfo_Value(item, "D_STARTOFFS")
    reaper.SetMediaItemInfo_Value(item, "D_STARTOFFS", start_offset + trim_start_delta)
    reaper.SetMediaItemInfo_Value(item, "D_LENGTH", new_length)
    reaper.UpdateItemInProject(item)
end

-- Remove fades from a duplicated comp item so contiguous takes join cleanly.
local function clear_item_fades(item)
    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN", 0.0)
    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN", 0.0)
    reaper.SetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO", 0.0)
    reaper.SetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO", 0.0)
    reaper.UpdateItemInProject(item)
end

-- Preserve the original comp item color on the duplicated item.
local function copy_item_color(source_item, target_item)
    local color = reaper.GetMediaItemInfo_Value(source_item, "I_CUSTOMCOLOR")
    reaper.SetMediaItemInfo_Value(target_item, "I_CUSTOMCOLOR", color)
    reaper.UpdateItemInProject(target_item)
end

-- Return the selected time range, or fall back to the selected item's bounds.
local function get_source_region(item)
    local time_sel_start, time_sel_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)

    if time_sel_end > time_sel_start then
        return time_sel_start, time_sel_end
    end

    return get_item_bounds(item)
end

-- Scan all media items in the project and return the latest item end position.
local function get_project_last_item_end()
    local item_count = reaper.CountMediaItems(0)
    local max_end = 0.0

    for i = 0, item_count - 1 do
        local current_item = reaper.GetMediaItem(0, i)
        local _, end_pos = get_item_bounds(current_item)

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

-- Return the region length in quarter notes so repeated blocks stay on the grid.
local function get_region_length_qn(region_start, region_end)
    local region_start_qn = reaper.TimeMap2_timeToQN(0, region_start)
    local region_end_qn = reaper.TimeMap2_timeToQN(0, region_end)
    return region_end_qn - region_start_qn
end

-- Set the pasted item's active take to the requested usable 1-based take number.
local function set_item_to_take_number(item, take_number)
    local take = get_usable_take_by_number(item, take_number)

    if not take then
        return false
    end

    reaper.SetActiveTake(take)
    return true
end

-- Return true when the item overlaps the requested region.
local function item_overlaps_region(item, region_start, region_end)
    local item_start, item_end = get_item_bounds(item)
    local tolerance = get_sample_tolerance()
    return item_start < (region_end - tolerance) and item_end > (region_start + tolerance)
end

-- Collect comp items on the source track that overlap the source region.
local function collect_comp_items(source_item, region_start, region_end)
    local comp_items = {}
    local source_track = reaper.GetMediaItemTrack(source_item)
    local track_item_count = reaper.CountTrackMediaItems(source_track)

    for item_index = 0, track_item_count - 1 do
        local item = reaper.GetTrackMediaItem(source_track, item_index)

        if item_overlaps_region(item, region_start, region_end) then
            local item_start, item_end = get_item_bounds(item)
            local overlap_start = math.max(item_start, region_start)
            local overlap_end = math.min(item_end, region_end)
            comp_items[#comp_items + 1] = {
                item = item,
                offset = overlap_start - region_start,
                trim_start_delta = overlap_start - item_start,
                length = overlap_end - overlap_start,
                take_count = get_take_count(item),
                usable_take_count = get_usable_take_count(item)
            }
        end
    end

    table.sort(comp_items, function(a, b)
        if a.offset == b.offset then
            return a.trim_start_delta < b.trim_start_delta
        end
        return a.offset < b.offset
    end)

    return comp_items
end

-- Return the shared usable take count when all comp items match.
local function get_shared_usable_take_count(comp_items)
    local shared_usable_take_count = nil

    for _, comp in ipairs(comp_items) do
        if shared_usable_take_count == nil then
            shared_usable_take_count = comp.usable_take_count
        elseif comp.usable_take_count ~= shared_usable_take_count then
            return nil
        end
    end

    return shared_usable_take_count
end

-- Collect items on non-source tracks that overlap the source region.
local function collect_backing_items(source_item, region_start, region_end)
    local backing_items = {}
    local source_track = reaper.GetMediaItemTrack(source_item)
    local track_count = reaper.CountTracks(0)

    for track_index = 0, track_count - 1 do
        local track = reaper.GetTrack(0, track_index)

        if track ~= source_track then
            local track_item_count = reaper.CountTrackMediaItems(track)

            for item_index = 0, track_item_count - 1 do
                local item = reaper.GetTrackMediaItem(track, item_index)

                if item_overlaps_region(item, region_start, region_end) then
                    local item_start, item_end = get_item_bounds(item)
                    local overlap_start = math.max(item_start, region_start)
                    local overlap_end = math.min(item_end, region_end)
                    backing_items[#backing_items + 1] = {
                        item = item,
                        offset = overlap_start - region_start,
                        trim_start_delta = overlap_start - item_start,
                        length = overlap_end - overlap_start
                    }
                end
            end
        end
    end

    return backing_items
end

-- Copy all collected backing items to the requested take location.
local function copy_backing_items_to_position(backing_items, take_start_pos)
    for _, backing in ipairs(backing_items) do
        local backing_target_pos = take_start_pos + backing.offset
        local pasted_item = duplicate_item_to_position(backing.item, backing_target_pos)

        if not pasted_item then
            reaper.ShowMessageBox("Failed to paste a backing item.", "Error", 0)
            return false
        end

        trim_duplicated_item(pasted_item, backing.trim_start_delta, backing.length)
    end

    return true
end

-- Copy all collected comp items to the requested take location.
local function copy_comp_items_to_position(comp_items, take_number, take_start_pos)
    for _, comp in ipairs(comp_items) do
        local comp_target_pos = take_start_pos + comp.offset
        local pasted_item = duplicate_item_to_position(comp.item, comp_target_pos)

        if not pasted_item then
            reaper.ShowMessageBox("Failed to paste copied comp item.", "Error", 0)
            return false
        end

        trim_duplicated_item(pasted_item, comp.trim_start_delta, comp.length)
        clear_item_fades(pasted_item)

        if not set_item_to_take_number(pasted_item, take_number) then
            reaper.ShowMessageBox("Failed to activate pasted take " .. take_number .. ".", "Error", 0)
            return false
        end

        copy_item_color(comp.item, pasted_item)
    end

    return true
end

-- Paste one region-length block per usable take, ensuring take numbering starts at 1.
local function explode_takes_to_project_end(comp_items, target_pos, region_start, region_end, backing_items)
    local take_count = get_shared_usable_take_count(comp_items)
    local region_length_qn = get_region_length_qn(region_start, region_end)
    local target_qn = reaper.TimeMap2_timeToQN(0, target_pos)

    if take_count == nil then
        reaper.ShowMessageBox("Take numbers must be the same.", "Error", 0)
        return false
    end

    for take_number = 1, take_count do
        local paste_qn = target_qn + ((take_number - 1) * region_length_qn)
        local paste_pos = reaper.TimeMap2_QNToTime(0, paste_qn)

        if not copy_comp_items_to_position(comp_items, take_number, paste_pos) then
            return false
        end

        if not copy_backing_items_to_position(backing_items, paste_pos) then
            return false
        end
    end

    return true
end

-- Create a region covering the full exploded take area.
local function create_exploded_takes_region(comp_items, target_pos, region_start, region_end)
    local take_count = get_shared_usable_take_count(comp_items)
    local region_length_qn = get_region_length_qn(region_start, region_end)
    local target_qn = reaper.TimeMap2_timeToQN(0, target_pos)
    local exploded_end_qn = target_qn + (take_count * region_length_qn)
    local exploded_end_pos = reaper.TimeMap2_QNToTime(0, exploded_end_qn)
    local yellow = reaper.ColorToNative(255, 255, 0) | 0x1000000
    local source_track = reaper.GetMediaItemTrack(comp_items[1].item)
    local _, track_name = reaper.GetTrackName(source_track)
    local region_name = "Exploded Takes - " .. track_name

    reaper.AddProjectMarker2(0, true, target_pos, exploded_end_pos, region_name, -1, yellow)
end

-- Main entry point for the script.
local function main()
    local item = get_selected_item()

    if not item then
        reaper.ShowMessageBox("No media item selected.", "Error", 0)
        return
    end

    local region_start, region_end = get_source_region(item)
    local comp_items = collect_comp_items(item, region_start, region_end)
    local backing_items = collect_backing_items(item, region_start, region_end)

    if #comp_items == 0 then
        reaper.ShowMessageBox("No comp items found on the source track inside the region.", "Error", 0)
        return
    end

    if get_shared_usable_take_count(comp_items) == nil then
        reaper.ShowMessageBox("Take numbers must be the same.", "Error", 0)
        return
    end

    local last_item_end = get_project_last_item_end()
    local target_pos = get_target_paste_position(last_item_end)

    reaper.Undo_BeginBlock()
    reaper.PreventUIRefresh(1)

    local ok = explode_takes_to_project_end(comp_items, target_pos, region_start, region_end, backing_items)

    if ok then
        create_exploded_takes_region(comp_items, target_pos, region_start, region_end)
    end

    reaper.PreventUIRefresh(-1)
    reaper.UpdateArrange()
    if ok then
        reaper.Undo_EndBlock("Copy selected item to project end and explode takes", -1)
    else
        reaper.Undo_EndBlock("Copy selected item to project end and explode takes (failed)", -1)
    end
end

main()
