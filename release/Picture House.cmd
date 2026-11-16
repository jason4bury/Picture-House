@echo off
rem Picture House - double-click to start it.
rem Each time, this makes (or refreshes) the Picture House shortcut in this folder and in the Start menu,
rem then starts Picture House from it. After the first run you can use the shortcut, the Start menu or
rem a pinned taskbar button instead: they start Picture House without a console window.
rem The execution-policy bypass applies to Picture House's own run only; no Windows settings are changed.
rem If Picture House doesn't open, run   "Picture House.cmd" debug   to start it in this window and see any errors.
setlocal
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if /i "%~1"=="debug" (
    "%PS%" -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0Picture-House.ps1"
    pause
    exit /b
)
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0New-PictureHouseShortcut.ps1" -Launch
if errorlevel 1 pause
