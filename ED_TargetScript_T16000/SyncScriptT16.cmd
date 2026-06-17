@echo off

set local

cls

echo.
echo Sync Script files with development folder
echo.

pause

echo Deleting TTS files...
echo.

del C:\Thrustmaster\common\Output\TTSQueue\*.*
del C:\Thrustmaster\common\Output\TTSQueue\Archive\*.*

set "SRC=C:\thrustmaster\ed_targetscript_t16000"
set "DST=D:\Users\Den\OneDrive\Personal\Thrustmaster\TARGET\Clicker\Development\ED_Enhanced_T16000"

set "ROBO_OPTS=/S"

:: Exclude one specific file
set "EXCLUDE_FILES=/XF C:\thrustmaster\ed_targetscript_t16000\scriptfiles\ED_UserSettings.tmh"
set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\ed_targetscript_t16000\scriptfiles\TARGET_Session"

:: Exclude tidy up scripts...
set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\ed_targetscript_T16000\Build-Index.ps1"
set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\ed_targetscript_T16000\SyncScriptT16.cmd"
set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\ed_targetscript_T16000\TARGET_Script_Analyzer_v9.3.ps1"

:: Exclude Launcher files inside \supportfiles
set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\ed_targetscript_t16000\SupportFiles\ED_Launcher.cmd"
set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\ed_targetscript_t16000\SupportFiles\ED_Launcher_2.cmd"

:: Exclude JSON only inside supportfiles\output
set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\common\output\MyJournalData.json"
rem set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\ed_targetscript_t16000\SupportFiles\output\MyStatusFile.json"
set "EXCLUDE_FILES=%EXCLUDE_FILES% /XF C:\thrustmaster\common\output\Tracking.json"

:: Exclude the EDMC folder
rem set "EXCLUDE_DIRS=/XD supportfiles\edmc"

robocopy "%SRC%" "%DST%" %ROBO_OPTS% %EXCLUDE_FILES% %EXCLUDE_DIRS% /L 

rem robocopy C:\thrustmaster\ed_targetscript_t16000\ D:\Users\Den\OneDrive\Personal\Thrustmaster\TARGET\Clicker\Development\ED_Enhanced_t16000\ /s /xf C:\thrustmaster\ed_targetscript_t16000\scriptfiles\ED_Usersettings.tmh /xf C:\thrustmaster\ed_targetscript_t16000\supportfiles\output\*.json /xd C:\thrustmaster\ed_targetscript_t16000\supportfiles\edmc /L 

rem robocopy C:\thrustmaster\ed_targetscript_t16000\scriptfiles\ D:\Users\Den\OneDrive\Personal\Thrustmaster\TARGET\Clicker\Development\ED_Enhanced_t16000\ScriptFiles /xf C:\thrustmaster\ed_targetscript_t16000\scriptfiles\ED_Usersettings.tmh /L 
rem robocopy C:\thrustmaster\ed_targetscript_t16000\SupportFiles\ D:\Users\Den\OneDrive\Personal\Thrustmaster\TARGET\Clicker\Development\ED_Enhanced_t16000\SupportFiles\ /s /xd C:\thrustmaster\ed_targetscript_t16000\supportfiles\edmc\edmc_plugins\edmc-ClickersFolly\__pycache__ /L  

rem robocopy C:\thrustmaster\ed_targetscript_t16000\scriptfiles\ D:\Users\Den\OneDrive\Personal\Thrustmaster\TARGET\Clicker\Development\ED_Enhanced_t16000\ScriptFiles /L 
rem robocopy C:\thrustmaster\ed_targetscript_t16000\SupportFiles\ D:\Users\Den\OneDrive\Personal\Thrustmaster\TARGET\Clicker\Development\ED_Enhanced_t16000\SupportFiles\ /s /L  

echo.
echo if output above is expected, press any key, otherwise press ctrl+c to quit
echo.

pause 

robocopy "%SRC%" "%DST%" %ROBO_OPTS% %EXCLUDE_FILES% %EXCLUDE_DIRS%

rem robocopy C:\thrustmaster\ed_targetscript_t16000\ D:\Users\Den\OneDrive\Personal\Thrustmaster\TARGET\Clicker\Development\ED_Enhanced_t16000\ /s /xf C:\thrustmaster\ed_targetscript_t16000\scriptfiles\ED_Usersettings.tmh /xd C:\thrustmaster\ed_targetscript_t16000\supportfiles\edmc

pause

exit
