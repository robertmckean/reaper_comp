@echo off
setlocal
:: Create timestamp
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set timestamp=%%i
:: Create placeholder log file
set log_file=C:\Users\windo\drums\codex_logs\codex_session_%timestamp%.txt
:: Ensure log directory exists
if not exist "C:\Users\windo\drums\codex_logs\" mkdir "C:\Users\windo\drums\codex_logs\"
:: Create placeholder file with header
echo Codex Code Session - %date% %time% > "%log_file%"
echo ================================================ >> "%log_file%"
echo Session started at: %time% on %date% >> "%log_file%"
echo ================================================ >> "%log_file%"
echo. >> "%log_file%"
echo [Paste your Codex Code conversation here] >> "%log_file%"
echo. >> "%log_file%"
echo. >> "%log_file%"
echo ================================================ >> "%log_file%"
echo End of session >> "%log_file%"
echo ================================================ >> "%log_file%"
echo Created placeholder log file: %log_file%
echo.
:: Open Notepad with the log file
start notepad "%log_file%"
:: Launch Codex Code in a separate PowerShell window with the drum310 env active
echo Launching Codex Code (native Windows)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -WorkingDirectory 'C:\Users\windo\drums' -ArgumentList '-NoExit','-ExecutionPolicy','Bypass','-File','C:\Users\windo\drums\codex_launch.ps1'"
echo.
echo Codex Code launched in new window. Notepad is open for session notes.
endlocal
