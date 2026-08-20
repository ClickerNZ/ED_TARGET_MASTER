@echo off
cls
echo.

rem powershell -NoProfile -ExecutionPolicy Bypass -NonInteractive -File "C:\Thrustmaster\Common\PowerShell\ProcessJournal.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -NonInteractive -File "C:\Thrustmaster\Common\PowerShell\ProcessJournal-v38.ps1"

rem pause to catch startup errors
pause

exit 

