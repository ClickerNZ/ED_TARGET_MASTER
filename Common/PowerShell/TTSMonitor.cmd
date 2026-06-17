@echo off
cls
echo.

rem start powershell.exe -ExecutionPolicy Bypass -File "C:\Thrustmaster\Common\PowerShell\TTSMonitor.ps1"
start powershell.exe -ExecutionPolicy Bypass -File "C:\Thrustmaster\Common\PowerShell\TTSMonitor-v28.ps1"

rem pause to catch startup errors
rem pause

exit 

