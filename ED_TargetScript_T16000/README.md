# ED_ENHANCED_T16000

Elite:Dangerous Enhanced TARGET script for Thrustmaster T16000 Joystick with TWCS Throttle 

### PURPOSE

The purpose of this script is to give people who have a Thrustmaster T16000 Joystick and TWCS Throttle a way to maximise the usefulness of their joystick and provide a gateway into TARGET scripting now, or maybe in the future.  

One issue this script solves is that using straight DX game binds we can run out of DX bindings (ED supports only 32).  
So my solution is to bind keyboard keys and get your joystick buttons and switches to send the game mostly keypresses!  

### FEATURES  

This script uses "layers".  
This version assigns (maps) up to 3 actions to many buttons thereby increasing your HOTAS usefulness.  

> NOTE: maximum layers per button = 5.  

I wrote this "ENHANCED" script because it's way better than the feeble attempt provided by Thrustmaster.  

It includes;  
- MapAxis statements for all critical axes  
- Curve settings for all axes  
- Mapkey statements for every button (some don't do anything, but they are defined)  
  * It uses layers to map up to 3 actions to many buttons  
- Associated BIND files  
- Game state engine which checks the game's status.json file every half second  
- Text to speech (TTS) functionality to add verbal feedback (this is NOT a Voice-to-Text alternative to VoiceAttack)  
- Sound effects functionality to allow various wav files to be played as ound effects  
- Customised and advanced PIP management
- Trip timer  
- Automated joystick curve profiles depending on which flight mode you are currently in  
  * (ie FA-Off v Normal v Supercruise etc)  
- On the fly manual joystick curve profiles selection to suit your own preferences  
- On the fly shifted trigger action  
- 3 Shifted trigger modes...
  * Discovery Scanner - Momentary trigger pull results in a 6.1 second hold function  
  * Mining Laser - Press to hold, press to release  
  * Pulse Wave Scanner - Momentary trigger pull results in repeating trigger action every 7 seconds. Press to stop  
- On the fly TTS Volume  
- and many more  

These all provide additional joystick and throttle functionality and improves the immersion within the game.  

### ACTIONS  

Each mapped button and switch produces an ACTION (not all buttons are mapped).  
These may simply produce a keystroke, however the main advantage of this script is that most call a script function which does more that sending a keystroke.  

Refer the following file in the SupportFiles\Documents subfolder for more information on ACTIONS.   
 
[Button Action Reference](/SupportFiles/Documents/ButtonActionsReference.md)  

### REQUIREMENTS

To use this script you will need a Thrustmaster T16000L or T16000M and a Thrustmaster TWCS Throttle.  
Rudder pedals are not required, but recommended.  
  
Also, you will need the latest firmware for these devices and the very latest version of TARGET software. 

Powershell v5.1 is required for the helper scripts and comes installed by default on Windows 10 and 11.  

### ZIP PACKAGE  

The zip file contains the following:  
- This README.md file  
- Changelog.txt
- ScriptFiles folder contains all supporting script files  

[Script Files Overview](./SupportFiles/Documents/ScriptFilesOverview.md)  

- A MapFiles folder which contains  
  * Quick Reference guide spreadsheet  
  * Keyboard Mapping spreadsheet  
  * Multiple image files the Throttle and Joystick
    * Image files showing the button and switch names for both the Joystick and Throttle 
    * T16000-Joystick-ENHANCED-ACTIONS.png shows the button and switch actions for the Joystick when the FULL keymap is used    
	* TWCSThrottle-ENHANCED-ACTIONS.png shoiws the button and switch actions for the throttle when the FULL keymap is used    
    * T16000-Joystick-BASIC-ACTIONS.png shows the button and switch actions for the Joystick when the BASIC keymap is used    
	* TWCSThrottle-BASIC-ACTIONS.png shoiws the button and switch actions for the throttle when the BASIC keymap is used    
- A BindFiles folder which contains the binds files matching what this script uses    
- A SupportFiles folder containing;  
  * Documents subfolder with a User Guide, Button Action Reference and UserSettings Guide  
  * Sounds subfolder containing the wav files used in the script  
  * TTS Voice Registry Scraps to assist in adding voices to Windows for use within the game via this script  
  * sounder.exe (SoundFX) and voice.exe (TTS)  
- Powershell folder containing 2x Powershell helper scripts  
  * ProcessJournal.ps1 - This helper script monitors the game journal and writes selected journal entries into SupportFiles\Output\MyJournalData.json  
    The TARGET script reads the MyJournalData.json file several times per second and updates key script string variables eg. CMDRName and StationName etc.  
  * TTSMonitor.ps1 - This helper script reads the contents of SupportFiles\Output\TTSQueue folder and is the text to speech engine for the script.
    The TARGET script composes and sends text strings to this folder to be spoken in a sequential manner  

> NOTE: The ProcessJournal.ps1 helper script uses a lookup module for ship names and exobiology data.  
>       Each time FDev release a new ship or exobiology data this lookup module will need updating.  
>       The lookup module can be found within the SupportFiles\PowerShell\Lookup folder  

### INSTALLATION

If you have just bought a Thrustmaster T16000 and TWCS Throttle, you can be up a running very quickly.  
You will, however need to spend some time becoming accustomed to what the buttons and switches all do.  

The \'MapFiles\' folder contains some images which should help with this.  
I recommend you print out the ACTIONS images for the profile you are using and have handy whilst learning which buttons do what.  

> Make sure you have already installed the Windows drivers and TARGET software before installing this script  

- Unzip the package to a local drive/folder of your choice.  
> I suggest creating c:\Thrustmaster\ED_TargetScript_T16000\ and copying the entire package into there.  
- Create a backup of your current game bind files which can be found at...  
	
	C:\Users\\<username\>\AppData\Local\Frontier Developments\Elite Dangerous\Options\Bindings  
	(change \<username\> in the above path to your Windows username)
 
- Copy the contents of my BindFiles folder into the above bindings folder.

### USER SETTINGS  

#### **!!! DO THIS FIRST BEFORE RUNNING SCRIPT !!!**  

> There are several **CRITICAL** settings which need to be set before you run the script for the first time.  

Refer to the User Setting Guide file (below) for guidance on these.  

[User Settings Guide](/SupportFiles/Documents/UserSettingsGuide.md)  

The ED_UserSettings.tmh file also allows you to select one of 2x different script profiles, FULL (default) or BASIC.  

- BASIC uses straight keypresses for the actions defined to the buttons.  
  * No TTS in game  
  * No SoundFX in game  
  * No Smarts associated with status.json flags
  * Best button response in game  
  
- FULL uses the ENHANCED script functions to perform the actions defined to the buttons  
  * Uses TTS in game to provide a richer game experience via spoken queues and updates  
  * Uses SoundFX in game  
  * Reads ststus.json to perform extended checks on many game state variables  
  * Performs more than a simple keypress in many circumstances  
  * Prints extensive information to the TARGET console which greatly aids if needing to troubleshoot  
  * ...and more  

### SCRIPT USAGE

- Open the TARGET Script Editor program.  
- Select Munu, Open, then navigate to where you copied the package and select **ED_ENHANCED_T16000.tmc** file found in the **ScriptFiles subfolder**  
- Click 'compile'  
- If you get no errors, hit 'run'  

> Errors can happen if you've made changes to the script or have not set the required file paths correctly  

You are likely to get an error or two when you run the script for the first time.   
Read the console messages carefully.  
Try to resolve the errors, then save, compile and run.  

Repeat as necessary until you see 'main returned 0'.    
If you get stuck, contact me via the E:D forum.  

Once the script is running the script editor console will show **'main returned 0'** if everything is ok.  

If the script aborts, it might mean you do not have the required controllers connected.  
Read the abort error messages carefully.  
If you get stuck, post a query in the Elite Dangerous forums.  

Navigate to the SupportFiles\Powershell folder and run the following two batch files...  
- ProcessJournal.cmd - this runs the ProcessJournal Powershell helper script  
- TTSMonitor.cmd - this runs the Text to speech monitor Powershell helper SCRIPT  

> NOTE: I recommend you create a shortcut on your desktop which points to the ED_Launcher_T16000.cmd file found in the SupportFiles folder.  
>       This batch file will start both helperscripts, the TARGET script and the Elite Dangerous Launcher app.  

- Finally, start Elite Dangerous.  

> NOTE: You need to always run the TARGET and helper scripts before starting the game  

### SCRIPT CONTROLLER CHECK 

The script will check for compatible controllers each time it is run (as described under REQUIREMENTS) and will ABORT if you don't have at least;  

- Thrustmaster T16000L or T16000M FCS flight stick...  
- Thrustmaster TWCS Throttle  

If you have either of the following compatible rudder pedals, they too will work with this script  
(the script will not abort if you don't)  

- TFRPRudder  
- TFRPHARudder  

The script will also automatically assign YAW to the most appropriate device in the following order;  
- Rudder Pedals (if one is detected)  
- Throttle Paddles  
- Joystick Twist axis  

Alternately, you can set this manually via a variable in ED_UserSettings.tmh.  
(this is covered in the User Settings section above)  

### LAUNCHER BATCH FILE  

Once you get a clean compile and run via the script editor, you can use the optional "Launcher" batch file that I've provided in the SupportFiles folder.  

This windows command file will try to run the Elite Dangerous Launcher and then this script via the TARGET GUI program.  

Before running this file, do the following;  

- Create a shortcut to ED_Launcher_T16000.cmd file on your desktop  
- Right click and select properties and select 'Advanced'  
- Tick the 'Run as Administrator' check box and click 'Ok'  
- Click 'Apply' then 'ok'  
- Right click the shortcut again but this time choose 'edit'  
- In the EDLauncher section check/change the drive letter and folder if you have installed Elite somewhere else on your PC  
- In the Target Script section, check/change the drive letter and folder to accurately reflect where you installed the TARGET software.  
- On the line which starts with 'start targetgui -r ...' make sure the full path to this script is correct.  
- If you have changed anything, do not forget to **save** before exiting the editor.  

> I have included example sections for other supporting programs you may wish to take advantage of.  
> To use these, remove the 'rem ' at the start of the lines and ensure the disk letter and folders are correct.  

Go ahead and run the Launcher shortcut!  
Assuming everything is configured correctly, the Launcher will fire up the game launcher, any additional apps you've enabled then the script.  

### SET CONTROLLER BINDS IN GAME TO 'Clicker-ENHANCED_T16000'  

Once the game is running, hit escape key and choose OPTIONS then CONTROLS.    
Set the PRESET for each of GENERAL, SHIP and SRV to 'Clicker-ENHANCED_T16000' and hit APPLY for each one then go flying!  

> NOTE: 'Clicker-ENHANCED_T16000' will only appeear as a menu option if the script is running AND you have copied the BINDS files from the package to the game folder correctly  

### PLAYING ELITE:DANGEROUS WITH THIS SCRIPT  

>RECOMMENDATION: Print the following files and have handy as reference to become familiar with the Joystick and Throttle button actions.
- Quick Reference guide spreadsheet for either BASIC or ENHANCED    
- The image files for each of the Joystick and Throttle  
  * T16000-Joystick-BUTTONS.png  
  * TWCSThrottle-BUTTONS.png  
  * T16000-Joystick-ENHANCED-ACTIONS.png and/or T16000-Joystick-BASIC-ACTIONS.png depending on which keymap profile you wish to use   
  * TWCSThrottle-ENHANCED-ACTIONS.png and/or TWCSThrottle-BASIC-ACTIONS.png depending on which keymap profile you wish to use   
  
### NOTES  

> ALWAYS Open the TARGET Script editor program and load, compile and run the script FIRST then launch Elite:Dangerous  
> Alternately, once everything is working as expected, run the Launcher shortcut you created on the desktop (as above)  

### NOTES FOR TEXT-TO-SPEECH  

> If using the Text-To-Speech function (if not, why not???)  
  * This script replaces some of the announcements made by ship's COVAS  
  * Go to the Game menu and select Options, Audio, Voice Volume, Ship Voice Volume then...  
    * Flight, Driving and Frame Shift, Turn off Flight Assist Engaged and Disengeged and Drive Assist   
	* Landing and Docking, Turn off Landing Gear Deployed and Retracted    
	* Cargo and Fuel, Turn off Landing Gear Deployed and Retracted  

### QUICK START USAGE (In Game)  

The script assigns ("maps") multiple ACTIONS to some buttons.  
(these are marked alongside 'U' and 'D' in the Quick Reference Guide)  

To use the alternate actions do the following;  
- Press and hold Throttle TBTN2 then the required button for the alternate "UP" action, or  
- Press and hold Throttle TBTN3 then the required button for the alternate "DOWN" action  

EXAMPLE - TBTN2+H1L (H1L-U)
>  To toggle the Landing gear, press and hold the TBTN2 button on the Throttle then press and release the Joystick Hat button to the left (H1L)  

NOTE: Joystick H1D Hat switch  
>  Pressing Hat 1 down on the joystick allows you to select each Wingman in sequence.  
>  First press selects Wingman 1, second press selects Wingman 2, third press selects Wingman 3  
>  Fourth press selects Wingman 1 again, and so on  

For more information refer the following files;  
[Button Action Reference](/SupportFiles/Documents/ButtonActionReference.md)  

[User Guide](/SupportFiles/Documents/UserGuide.md)  

### SUPPORT  
  
If you get stuck or just want to understand more, post a question in the forum, or PM me.  

Fly dangerously!  

o7  

Cheers  
Clicker  
