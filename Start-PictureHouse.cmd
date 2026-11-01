@echo off
rem Picture House launcher - runs the GUI without a console window.
rem Each start is noted in Data\launch.log, and anything PowerShell prints (errors included)
rem goes to Data\console-NNNN.log so a start that never appears can be diagnosed.
if not exist "%~dp0Data" mkdir "%~dp0Data"
set "PHRUN=%RANDOM%%RANDOM%"
echo %DATE% %TIME%  launcher run %PHRUN%>>"%~dp0Data\launch.log"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "& { & '%~dp0Picture-House.ps1' *> '%~dp0Data\console-%PHRUN%.log' }"
