@echo off
rem Builds "Picture House.exe" (with its icon) from Picture-House.ps1. Checks this PC has what it needs first.
rem Run it again after each Picture House update.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0Build-PictureHouseExe.ps1"
