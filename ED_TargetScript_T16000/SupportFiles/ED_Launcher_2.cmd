@echo off

echo.
echo VERSION 5.1.0 - 2Dogs + T16000
echo.

rem pause

echo.
rem		Change destination username and destination folder is correct...
echo Copy correct T16000 bindfiles...
xcopy c:\thrustmaster\ed_targetscript_t16000\bindfiles\*.binds "c:\users\den\appdata\local\frontier developments\elite dangerous\options\bindings\" /d /y /i 
xcopy c:\thrustmaster\ed_targetscript_t16000\bindfiles\*.start "c:\users\den\appdata\local\frontier developments\elite dangerous\options\bindings\" /y /i
echo.

echo Start 2Dogs' EDLauncher...
d:
cd "\Program Files (x86)\Frontier\EDLaunch"
start EDLaunch-2Dogs.exe

rem timeout /t 5

echo Starting supporting apps...
echo.
echo Start EDMC...
c:
cd "\Program Files (x86)\EDMarketConnector\"
start EDMarketConnector.exe
echo.

rem timeout /t 5

rem echo Start Opentrack...
rem c:
rem cd "\Program Files (x86)\opentrack\"
rem start opentrack.exe
rem echo.

rem timeout /t 5

echo.
echo Start T16000 TARGET script...
c:
cd "\program files (x86)\thrustmaster\target\x64\"
rem start targetgui.exe -r "c:\Thrustmaster\ED_TargetScript\script\ed_main.tmc"
start targetgui.exe -r "C:\Thrustmaster\ED_TargetScript_T16000\ScriptFiles\ed_enhanced_T16000.tmc"
echo.

timeout /t 5 /nobreak >nul
rem pause
echo. 
echo Start TTSMonitor powershell script...
start powershell -NoProfile -ExecutionPolicy Bypass -NonInteractive -File "C:\Thrustmaster\ED_TargetScript_T16000\SupportFiles\PowerShell\TTSMonitor.ps1"
echo.

timeout /t 20 /nobreak >nul

rem DO THIS LAST

echo Start ProcessJournal powershell script...
start powershell -NoProfile -ExecutionPolicy Bypass -NonInteractive -File "C:\Thrustmaster\ED_TargetScript_T16000\SupportFiles\PowerShell\ProcessJournal.ps1"
echo.

exit
