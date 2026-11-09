@echo off
rem Picture House launcher - runs the GUI without a console window.
rem Each start is noted in launch.log, and anything PowerShell prints (errors included) goes to
rem console-NNNN.log, both in %APPDATA%\Picture House, so a start that never appears can be diagnosed.
set "PHDATA=%APPDATA%\Picture House"
if not exist "%PHDATA%" mkdir "%PHDATA%"
set "PHRUN=%RANDOM%%RANDOM%"
echo %DATE% %TIME%  launcher run %PHRUN%>>"%PHDATA%\launch.log"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -Command "& { & '%~dp0src\Picture-House.ps1' *> '%PHDATA%\console-%PHRUN%.log' }"
