@echo off
cls
echo.

start powershell.exe -ExecutionPolicy Bypass -File "C:\Thrustmaster\Common\PowerShell\TTSMonitor.ps1"
rem start powershell.exe -ExecutionPolicy Bypass -File "C:\Thrustmaster\Common\PowerShell\TTSMonitor-v28.ps1"

rem pause to catch startup errors
rem pause

exit 

