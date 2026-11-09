@echo off
rem Picture House - debug launcher: runs with a console and saves everything it prints to
rem console-debug.log in %APPDATA%\Picture House.
set "PHDATA=%APPDATA%\Picture House"
if not exist "%PHDATA%" mkdir "%PHDATA%"
echo Starting Picture House in debug mode - output goes to "%PHDATA%\console-debug.log"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0src\Picture-House.ps1" > "%PHDATA%\console-debug.log" 2>&1
echo Picture House closed (exit code %errorlevel%). You can close this window.
pause
