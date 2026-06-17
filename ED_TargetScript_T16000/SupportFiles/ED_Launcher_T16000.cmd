@echo off

echo.
echo VERSION T16000
echo.

rem pause


echo.
echo Copy correct T16000 bindfiles...

rem		Change destination username and ensure destination bindings folder is correct...
copy c:\thrustmaster\ed_targetscript_t16000\bindfiles\*.* "c:\users\<USERNAME>\appdata\local\frontier developments\elite dangerous\options\bindings\" /y
echo.

echo Start EDLauncher...
c:
cd "\Program Files (x86)\Frontier\EDLaunch"
start EDLaunch.exe

rem timeout /t 5

echo Starting supporting apps...
echo.
rem echo Start EDMC...
rem c:
rem cd "\Program Files (x86)\EDMarketConnector\"
rem start EDMarketConnector.exe
rem echo.

rem timeout /t 5

rem echo Start Opentrack...
rem c:
rem cd "\Program Files (x86)\opentrack\"
rem start opentrack.exe
rem echo.

rem timeout /t 5

rem echo Start Voice Attack...
rem cd "\Program Files (x86)\VoiceAttack\"
rem start VoiceAttack.exe -shortcutson

rem timeout /t 5

rem echo Start TeamSpeak...
rem cd "\Users\<username>\AppData\Local\TeamSpeak 3 Client"
rem start ts3client_win64.exe

echo.
echo. Start the T16000 TARGET script...
echo. 

c:
cd "\program files (x86)\thrustmaster\target\x64\"
start targetgui.exe -r "c:\Thrustmaster\ED_TargetScript_T16000\ScriptFiles\ed_enhanced_t16000.tmc"

timeout /t 5 /nobreak >nul
echo. 
echo Start TTSMonitor powershell script...
start powershell -NoProfile -ExecutionPolicy Bypass -NonInteractive -File "C:\Thrustmaster\ED_TargetScript_T16000\SupportFiles\PowerShell\TTSMonitor.ps1"
echo.

timeout /t 20 /nobreak >nul

rem DO THIS LAST

echo Start ProcessJournal powershell script...
start powershell -NoProfile -ExecutionPolicy Bypass -NonInteractive -File "C:\Thrustmaster\ED_TargetScript_T16000\SupportFiles\PowerShell\ProcessJournal.ps1"
echo.

rem pause

exit
