$source = "C:\Users\windo\VS_Code\reaper_comp\copy_item_to_project_end.lua"
$dest   = "C:\Users\windo\AppData\Roaming\REAPER\Scripts\rjm\copy_item_to_project_end.lua"

Copy-Item $source $dest -Force
Write-Host "Script deployed to REAPER."
