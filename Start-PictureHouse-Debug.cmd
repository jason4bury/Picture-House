@echo off
rem Picture House - debug launcher: runs with a console and saves everything it prints to Data\console.log
echo Starting Picture House in debug mode - output goes to Data\console.log
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0Picture-House.ps1" > "%~dp0Data\console.log" 2>&1
echo Picture House closed (exit code %errorlevel%). You can close this window.
pause
