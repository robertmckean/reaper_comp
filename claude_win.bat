@echo off
setlocal
:: Create timestamp
for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set timestamp=%%i
:: Create placeholder log file
set log_file=C:\Users\windo\drums\claude_logs\claude_session_%timestamp%.txt
:: Ensure log directory exists
if not exist "C:\Users\windo\drums\claude_logs\" mkdir "C:\Users\windo\drums\claude_logs\"
:: Create placeholder file with header
echo Claude Code Session - %date% %time% > "%log_file%"
echo ================================================ >> "%log_file%"
echo Session started at: %time% on %date% >> "%log_file%"
echo ================================================ >> "%log_file%"
echo. >> "%log_file%"
echo [Paste your Claude Code conversation here] >> "%log_file%"
echo. >> "%log_file%"
echo. >> "%log_file%"
echo ================================================ >> "%log_file%"
echo End of session >> "%log_file%"
echo ================================================ >> "%log_file%"
echo Created placeholder log file: %log_file%
echo.
:: Open Notepad with the log file
start notepad "%log_file%"
:: Launch Claude Code in a new Windows Terminal PowerShell tab
echo Launching Claude Code (native Windows)...
wt.exe cmd /k "cd /d C:\Users\windo\drums && conda activate drum310 && claude"
echo.
echo Claude Code launched in new window. Notepad is open for session notes.
endlocal
