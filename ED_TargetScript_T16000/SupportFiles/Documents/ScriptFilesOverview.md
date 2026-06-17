# ED_ENHANCED_T16000 - SCRIPT FILES OVERVIEW  

For the script to work, you must install the latest version of Thrustmaster's Drivers and TARGET Software.  
(https://support.thrustmaster.com/en/product/t16000mfcs-en/)  

Whilst I could have incorporated all of the below files within one single ".tmc" file it would have been a couple thousand lines long and a nightmare to maintain.  
I've separated the code into 11 separate files which does make it easier for me to maintain.  

Each file contains comments which add context and usage information.  

## Main Code File  

### ED_Enhanced_T16000.tmc  

Every TARGET script must have a ".tmc" file.  
This file's main purposes;  
- 'include' statements for each of the below files so they will be compiled at run time  
- 'exclude' statements for hardware not supported in this script in order to minimise console error messages  
- sets key runtime variables  
- calls initialisation routines for each axis on the controllers detected  
- initialises the Text To Speech and Sound Effects functions  
- loads the Training key map  
- runs the Game Start Check routine  

## Variables, Defines and Settings  

The following 4 files contain definitions for Variables, Defines, Flags and settings.  
There are many comments in each file which hopefully describe what each does or is used for.  

### ED_UserSettings.tmh  

This file's key purpose is to allow you to set critical file and folder locations required for this entire script to work properly.
There are also some options in order for you to personalise, customise and tweak the script to your own personal preference.  

### ED_GameBindings.ttm  

This file declares script label variables aligned to the game's BINDS file.  
Not all of the variables are used in this script package, however they could be.  
The extras are included in the file for completeness and makes customisation of the script much easier by not having to create a new label variable or change the BIND file in-game.  

It is recommended that if you change a definition in this file, you should also make the corresponding change to the BIND file in-game.  
Likewise, if you make a change in the BIND file in-game, you should make the corresponding definition change in this file.  

### ED_GlobalVars.tmh  

Variables, as the name suggests may be assigned different values during code execution.  
Variables can be 'Global' or 'Local'.  
- 'Local' Variables are declared inside a subroutine (function) and their values are lost when the routine exists.  
- 'Global' variables are used by 2 or more different routines or functions across multiple files and their values remain available for any routine to use or change.  

Rather than scatter required global variables throughout the code, I put them all in one place.  
Saying that, there are one or two instances where I've defined global variables just prior to the main routine (function) that initially uses them.  

This file also serves to declare initial values for certain flag variables.  

### ED_ScriptDefines.ttm  

Defines are global variables with static values which cannot be changed within the script.  

This file contains these global defines.  
It also contains Global Variables associated with some of these Defines for ease of understanding (eg. status.json flags)  

## Code Files  

Refer to each of the following code files for additional context and understanding via the included comments.  
If you'd like more context than is provided, or simply wish to better understand how a routine works, send me a PM in the Elite Dangerous forums.  

### ED_Functions.tmh  

This file contains the following general purpose routines;  

|Function | Purpose |  
|:-------:|:--------|  
|fnNotValid()						|Announce if function called is not valid|  
|fnStartupMapKeyMode()				|Sets Mapkey Mode on Script start|  
|fnGetFlightMode()					|Determine current flight mode and set Slider Curves appropriately|  
|fnTextToSpeech()					|Converts Text to Speech using voice.exe|  
|fnVoiceVolume()					|Volume Controller for 'voice' exe / fnTextToSpeech()|  
|fnTTSExport()						|Writes the text strings to an external queue file. Now processed by a powershell helper script|  
|fnSoundFX()						|Plays WAV file sound effects|  
|fnGameStarted()					|Announce Game Start, TTS and SoundFX status, Game version|  
|fnPIPMode()						|Sets PIP Mode profiles|  
|fnPIPManager()						|Determines PIP Profile, constructs and parses correct parameters to fnPIPMapper()|  
|fnPIPMapper()						|Sets Auto-PIP Mapping & then sends sequence of keystrokes to game|  
|fnAdvFireControl()					|Perform Primary and Secondary trigger actions|  
|fnAdvancedSCB()					|Fire Shield Cell Bank or two and follow up with a heatsink|  
|fnHeatsink()						|Deploy a heatsink|  
|fnChaff()							|Deploy chaff|  
|fnDeploySRV()						|Deploy/Recover SRV|  
|fnDeployFighter()					|Deploy/Recover the fighter|  
|fnDRShip()							|Dismiss/Recall Ship|   
|fnRequestDock()					|Calls Request Dock macro. Set power to shields|  
|fnHangerServices()					|Calls Enter/Exit Hanger macro|   
|fnCheckFSDCharge()					|Checks FSD starts spooling up after hitting FSD|   
|fnCheckFiregroup()					|Checks which fire group we have selected. This is used to select FG 1 and fire the discovery scanner automatically|  
|fnClearChatBox()					|Clears the chat boxes in the Comms Panel|  
|fnModeSwitch()						|Menulog to Solo, Private Group or Open|  
|fnVPOutput()						|Sends output to console and TTS|  
|fnPrintState()						|Display header banner for the status of the macro toggles & user preferences at script start|  
|fnStateDump()						|Prints state banner to console|  
|fnGetTOD()							|Return Time-of-day for console messages|  
|fnMyName()							|Gets current commander name from registry|  
|fnGreetCMDR()						|Issues customised greetings using CMDR namd and Station Name etc|  
|fnSelectFireGroup()				|Function to set which firegroup to select. Used by Auto honk functions|  
|fnGetStationName()					|Gets currently docked Station Name. used in GreetCMDR and TripTimer functions|  
|fnDockingStatus()					|Tracks docking request status from journal.|  
|fnFighterStatus()					|Tracks if a fighter bay is available and fighter is deployed|  
|fnPANIC()							|Programatically aborts the script|  
|fnInputCMD()						|Debug function to set/reset variables on the fly|  
|fnTripTime()						|Calculate and display/announce time taken to fly a circuit (Start & Finish at Origin Station|  
|fnSetOriginStation()				|Set the currently docked station as an Origin for Trip timer
|fnDEBUG()							|Empty function to be used to set and debug code whilst game is running|  
|findstr()							|Find substring within a string and return first char position or -1 if not found|  
|strcpy()							|Copy string from one variable into another|  

### ED_Initialise.tmh  

This file contains the following hardware, TTS and SoundFX initialisation routines;  

|Function | Purpose |  
|:-------:|:--------|  
|CheckControllers()					|Detect controllers we have connected|  
|initJoystickAxis()					|Initialise Joystick axes|  
|initThrottleAxis()					|Initialise Throttle axes|  
|initRudderAxis()					|Initialise Rudder axes|  
|initSliderAxis()					|Initialise Slider axis|  
|initSlewAxis()						|Initialise Slew axis|  
|initCurves()	 					|Sets Joystick, Throttle and Rudder curves for all axes|  
|initSetSliderCurve()				|Set context driven DX-SLIDER curves (Radar sensitivity)|  
|initTextToSpeech()					|Initialise TTS Engine|  
|initSoundFX()						|Initialise Sound Effects engine|  
|initUserSettings()					|Save all changeable user settings|  
|fnResetUserSettings()				|Reset changeable user settings to declared values in ED_UserSettings file|    
|fnEncodeUserSettings()				|Encodes binary user setting variable to be saved to MyStates.json|  
|fnDecodeUserSettings()				|Decodes binary user settings read from MyStates.json file|  
|fnUserSettingsDelta()				|Reports differences between declared User Settings and theencoded value read from MyStates.json|  
|fnCompareIntSettings()				|Reports differences of non-binary user settings read from MyStates.json|  


### ED_Macros.tmh   

This file contains keystroke macro chains;  

|Function | Purpose |  
|:-------:|:--------|  
|initMacroChains()					|Container within which we declare the following macros|  
|m_RequestDock						|Auto docking request|  
|m_DeploySRV						|SRV deploy macro|  
|m_BoardShip						|SRV board ship macro|  
|m_DeployNPCFighter					|Deploy the fighhter crewed by NPC|  
|m_DeployFighter					|Deploy the fighter with YOU in it|  
|m_ShowGameStats					|Display the combined On Screen Display FPS & Bandwidth meters|  
|m_FastModeSwitch0					|Menulog to Open|  
|m_FastModeSwitch1a					|Menulog to 1st Private Group in list|  
|m_FastModeSwitch1b					|Menulog to 2nd Private Group in list|  
|m_FastModeSwitch2					|Menulog to Solo|  
|m_ReportCrimesToggle				|Toggle 'Report Crimes' on/off|  
|m_NAVBeaconWing					|Toggle 'Wingman Beacon' to TEAM|  
|m_NAVBeaconOff						|Toggle 'Wingman Beacon' to OFF|  
|m_EnterHanger						|Refuel/repair/restock, enter hanger and station services|  
|m_Launch							|Launch the ship (from Launchpad screen)|  
|m_Disembark						|Refuel/repair/restock, then disembark the ship (on foot)|  
|m_ChangeColours					|Change Engine and Weapon Colours|  
|m_NextFG							|Short chain to select the next firegroup|  
|m_PrevFG							|Short chain to select the previous firegroup|  


### ED_Toggles.tmh  

Contains general purpose routines which serve to turn on/off, open/close, start/stop, deploy/retract ship systems;  

|Function | Purpose |  
|:-------:|:--------|  
|tgTxt2Speech()						|Turn Text to Speech function ON/OFF|  
|tgEnhancedFAOFF()					|Flight/Drive Assist OFF/ON|  
|tgTriggerMode()					|Cycle between 'Discovery Scanner', 'Mining Laser' and 'Pulse Wave Scanner' modes|  
|tgLights()							|Cycle Lights and Night Vision|  
|tgSilentRunning()					|Toggle Silent running ON/OFF|  
|tgCargoScoop()						|Toggle cargo scoop DEPLOYED/RETRACTED|  
|tgLandingGear()					|Toggle landing gear DEPLOYED/RETRACTED|  
|tgReverseThrust()					|Toggle Reverse in ship or SRV|  
|tgBoost()							|Fire engine boost in normal flight and SCO drive in Supercruise|  
|tgHardpoints()						|Toggle hard points DEPLOYED/RETRACTED|  
|tgHUDMode()						|Toggle HUD between Combat and Analysis modes|  
|tgFSSMode()						|ENTER/EXIT FSS Mode|   
|tgPlanetView()						|Toggle front and rear view of planet in FSS Mode|  
|tgWarpDrive()						|Engage Frameshift Drive (Supercruise/Hyperjump)|  
|tgExtCamera()						|Toggle external camera mode ON/OFF|  
|tgXAxis()							|Toggle Joystick X axis mode between ROLL/YAW|  
|tgGALMap()							|Opens/closes GAL map|  
|tgSYSMap()							|Opens/closes SYS map|  
|tgWingBeacon()						|Toggles the Wing beacon between WING and OFF|  
|tgReportCrimes()					|Toggles 'Report CRimes Against me' between on and off|  

### ED_StateTracker.tmh  

The purpose of this file is to read and process the status.json file and read/write the MyStates file;  

|Function | Purpose |  
|:-------:|:--------|  
|stfnReadMyJournalData()			|Reads the MyJournalData.json file written by the external powershell helper script|  
|stfnReadStatusJson()				|Read status.json file in journal files folder|  
|stfnWriteMaxJson()					|Tracks maximum character length of status.json so we set the buffer value correctly|  
|stfnGetKeyValue()					|Extract json key value by name from status.json|  
|stfnDecodeFlags()					|Read and process "Flags" value from status.json|  
|stfnDecodeFlags2()					|Read and process "Flags2" value from status.json|  
|stfnProcessFlags()					|Process all flags and traps any which have changed since last read|  
|stfnDecodeModules()				|Determine which optional modules have been fitted to the ship|  
|stfnProcessMyJournalData()			|Process the data read from MyJournalData.json 
|stfnProcessGuiFocus()				|Read and process 'GuiFocus' key value in status.json|  
|stfnStartCheck()					|Initial check to see if game is already running after we've restarted the script|  
|stfnMyStates()						|Save current status of non-status.json state variables when mode switching or restarting the game|  

## Button and Switch Assignment  

The following file contains 2x MapKey blocks. One for Training Mode and one for Game mode (Main).  
Each block assigns either BASIC or FULL (Enhanced) button/switch actions depending on which User Setting the user has set (FULL = Default).  

### ED_MapKeyAssignment.tmh  

|Function | Purpose |  
|:-------:|:--------|  
|MainKeyMap()						|This MapKey set is called from fnGameStarted() when we detect Game is running|  
|TrainingMap()						|This MapKey set is called at script startup and when game is stopped and 'TrainingMode' is ENABLED in ED_UserSettings.tmh|  
