@echo off
rem Builds "..\Builds\Picture House v<version>.exe" (e.g. Picture House v1.00.exe) from src\Picture-House.ps1.
rem Checks this PC has what it needs first. Add -RedrawIcon to remake assets\Picture-House.ico.
rem Interim: E:\Created\_shared\Build-Tool.ps1 (which reads build.json) replaces this once it exists.
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0Build-Exe.ps1" %*
