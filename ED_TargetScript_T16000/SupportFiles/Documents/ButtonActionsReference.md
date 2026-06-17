# ED_ENHANCED_T16000 - BUTTON ACTIONS REFERENCE  

Refer to the Joystick and Throttle BUTTONS images below.

[Joystick Buttons](/Mapfiles/T16000-Joystick-BUTTONS.png)  

[Throttle Buttons](/MapFiles/TWCSThrottle-BUTTONS.png)  

For a quick reference for either the Enhanced or FULL Keymap refer to the T16000-Joystick-ENHANCED-ACTIONS and TWCSThrottle-ENHANCED-ACTIONS image files alongside the Quick Reference - ENHANCED spreadsheet.  

In the images and spreadsheets each switch/button is referenced via it's button name (eg TS1) and alongside will be a prefix of U, M or D.  
- 'U' is called the UP modified action. Press and HOLD Throttle button TBTN2, then press and release the action button  
- 'M' is the MIDDLE (unmodified) action...simply press and release the switch/button to perform the action    
- 'D' is called the DOWN modified action. Press and HOLD Throttle button TBTN3, then press and release the action button  

For this reference I will use the modifiers as a suffix, example TS1-U.  
In the descriptions I will use the following shortcuts;
For TS1 as an example...  
- TS1-U = TBTN2+TS1  (Press and hold TBTN2, press and release TS1)  
- TS1-M = TS1  (Press and release TS1)  
- TS1-D = TBTN3+TS1  (Press and HOLD TBTN3, press and release TS1)

> NOTE: "empty" actions are available should you wish to assign the button an action.
- Coded routines in the script which are not currently used are listed in the following document  
[Script Files Overview](/SupportFiles/Documents/ScriptFilesOverview.md)  
- Action labels may also be assigned using PULSE+"label" within ED_MapKeyAssignment.tmh.  
> Action labels are defined within ED_GameBindings.ttm  

I do not go into customising my code here, however if you want to know how to add an action to an empty button, first...  
- Open the ED_MapKeyAssignment.tmh file in notepad (I use notepad++) and take a look at what's already been done, or...  
- PM me in the Elite Dangerous forum.  


## T16000 JOYSTICK  

### TS1 - Primary Fire  

Standard action  
- TS1-M: TS1. Press the trigger to simply fire the weapon assigned to firegroup 1 in game (press to fire, release to stop)  

Modified actions  
- TS1-U: TBTN2+TS1. This increments the firing mode used for TS1-D  
- TS1-D: TBTN3+TS1. This uses the alternate fire mode as follows...
  *  Modes are  
     * Discovery Scanner - Press TS1-D to fire the discovery scanner, no need to hold the trigger for 6.1 seconds.  
     * Mining Laser - Press TS1-D to fire the Mining Laser. This holds the trigger down for you. Press TS1 to stop.	 
     * Pulse Wave Scanner - Press TS1-D to fire the Pulse Wave Scanner. This automatically repeats every 7 seconds. Press TS1 to stop.  
	
### TS2 - Secondary Fire  

Standard action  
- TS2-M: TS2. Press the trigger to simply fire the weapon assigned to firegroup 2 in game  (press to fire, release to stop)  

Modified actions  
- TS2-U: TBTN2+TS2. This increments the mode used for TS2-D  
- TS2-D: TBTN3+TS2. This uses the alternate fire mode as follows...
  * Modes are  
    * Discovery Scanner - Press TS2-D to fire the discovery scanner, no need to hold the trigger for 6.1 seconds.  
    * Mining Laser - Press TS2-D to fire the Mining Laser. This holds the trigger down for you. Press TS2 to stop.	 
	* Pulse Wave Scanner - Press TS2-D to fire the Pulse Wave Scanner. This automatically repeats every 7 seconds. Press TS2 to stop.  

Example: If you have a mining laser set to '1' in the currently selected firegroup and a pulse wave scanner set to '2' in the same firegroup.  
- Press TS1-U to cycle/set mode to 'Mining Laser'  
- Press TS2-U to cycle/set mode to 'Pulse Wave Scanner'  
- Use TS1-D and TS2-D to effectively use these modes  
- NOTE: TS1-M and TS2-M continue to function in the standard way  

### TS3 (LHS on stick)  

Standard action  
- TS3-M: TS3. Press to turn Flight Assist OFF and ON  

Modified actions  
- TS3-U: TBTN2+TS3. Turn Silent Running ON and OFF  
- TS3-D: TBTN3+TS3. empty  


### TS4 (RHS on stick)  

Standard action  
- TS4-M: TS4.  
  * Normal Flight mode or in SRV. Press to deploy or retract hardpoints or turret  
  * Supercruise. Press to toggle the HUD between Analysis and Combat mode  

Modified actions  
- TS4-U: TBTN2+TS4. Toggles the HUD between Analysis and Combat modes  
- TS4-D: TBTN3+TS4. Toggles the Joystick X-Axis between ROLL (default) and YAW  

## H1 (Joystick Hat)  

The hat on the joystick has 8 physical positions, however we only use four; Up, Down, Left and Right.  
These are designated as H1U, H1D, H1L and H1R respectively.  
Each of these positions may also be modified via TBTN2 and TBTN3 as follows;  

### H1U  

Standard action  
- H1U-M: H1U. Select Target ahead on the radar  

Modified actions  
- H1U-U: TBTN2+H1U. Selects the highest threat ship on the radar  
- H1U-D: TBTN3+H1U. Cycles next hostile ship on the radar  

### H1D  

Standard action  
- H1D-M: H1D. Sequence. Selects Wingman 1, then Wingman 2, then Wingman 3, then Wingman 1 again and so on  

Modified actions  
- H1D-U: TBTN2+H1D. Selects currently selected Wingman's target on the radar  
- H1D-D: TBTN3+H1D. Selects currently selected Wingman's NAV Lock  

### H1L  

Standard action  
- H1L-M: H1L. Selects Next Firegroup  

Modified actions  
- H1L-U: TBTN2+H1L. Cycles the landing gear between DEPLOYED and RETRACTED  
- H1L-D: TBTN3+H1L. Cycles the cargo scoop between DEPLOYED and RETRACTED  

### H1R  

Standard action  
- H1R-M: H1R. Selects the next ship on the radar  

Modified actions  
- H1R-U: TBTN2+H1R. Cycles the ship or SRV lights (Ship=ON/OFF, SRV=Lo/Hi/Off)  
- H1R-D: TBTN3+H1R. Cycles night vision ON/OFF  

## Joystick Base Buttons  

Refer to the Joystick BUTTONS image for the layout of these buttons   

LHS Top = B5, B6, B7  
LHS Bottom = B10, B9, B8  

RHS Top = B13, B12, B11  
RHS Bottom = B14, B15, B16  

I guess Thrustmaster were trying for intuitive. Meh.  
Me, I'll list them in numerical order  

## Left Hand Buttons  

### B5  

Standard action  
- B5-M: B5. Opens and Closes the Galaxy Map  

Modified actions  
- B5-U: TBTN2+B5. empty  
- B5-D: TBTN3+B5. empty    

### B6  

Standard action  
- B6-M: B6. When on planet surface in SRV or on foot, DISMISS/RECALL the ship. Only works if the ship has not already departed due to moving beyond 600 meters  

Modified actions  
- B6-U: TBTN2+B6. Deploy/Recover the SRV. Starting point for DEPLOY = in cockpit with no panels selected. RECOVER = in SRV with the "Board" light lit  
- B6-D: TBTN3+B6. Deploy/Recover the fighter. Starting point in cockpit for both.

### B7  

Standard action  
- B7-M: B7. Turns the Ship's GUI OFF/ON 

Modified actions  
- B7-U: TBTN2+B7. empty  
- B7-D: TBTN3+B7. empty    

### B8  

Standard action  
- B8-M: B8. Once landed in a station or fleet carrier, this fires a macro to restock, enter hanger then Station Services  

Modified actions  
- B8-U: TBTN2+B8. empty  
- B8-D: TBTN3+B8. empty    

### B9  

Standard action  
- B9-M: B9. Toggles the external camera ON/OFF  

Modified actions  
- B9-U: TBTN2+B9. empty  
- B9-D: TBTN3+B9. empty    

### B10     

Standard action  
- B10-M: B10. Opens and Closes the System Map  

Modified actions  
- B10-U: TBTN2+B10. empty  
- B10-D: TBTN3+B10. Print state dump banner to console    

## Right Hand Buttons  

### B11  

Standard action  
- B11-M: B11. Set current station as the "origin" for the round trip timer function.

Modified actions  
- B11-U: TBTN2+B11. Shows the framerate and connection status in lower left of the screen
- B11-D: TBTN3+B11. empty    

### B12  

Standard action  
- B12-M: B12. Clear the chatbox

Modified actions  
- B12-U: TBTN2+B12. empty  
- B12-D: TBTN3+B12. empty    

### B13   

Standard action  
- B13-M: B13. Fires a macro to cycle your ship's NAV Beacon between WING/OFF  

NOTE: This only works if your System's Panel (RHS Panel in Ship) is at the "home" position.  
Unfortunately the game does not let me determine which TABS or previous selection has been made.  
So, if not at HOME, you will get a random result.  

Modified actions  
- B13-U: TBTN2+B13. empty  
- B13-D: TBTN3+B13. empty    

### B14  

Curve settings allow me to adjust the sensitivity of the axis for the Joystick, Throttle, Rudders, Slew control and slider (RADAR).  
We use different curve settings as some situations are easier to control than others.  
Examples are, when we are in normal flight mode versus FA-Off or Supercruise, or are in FSS Mode etc.  
Likewise the Radar Zoom functions differently depending on flight mode, or if in SRV on planet etc.  

The script detects which flight mode we're in and will automatically set the curves.

There are some settings which can be adjusted for this in the ED_UserSettings.tmh file.  
I have defined 5 seperate curve profiles, 3 of which can be manually selectable via the buttons below.

Standard action  
- B14-M: B14. Set the Joystick curves to NONE (default curves). This is a neutral setting.  

Modified actions  
- B14-U: TBTN2+B14. Set curves to MEDIUM (more sensitive, faster response)  
- B14-D: TBTN3+B14. Set curves to SLOWEST (less sensitive, slower response). Best for FA-Off.  

### B15  

Standard action  
- B15-M: B15. Cycles the colours for your engines and weapons if you have purchased via the Frontier store for your ships.  

Modified actions  
- B15-U: TBTN2+B15. empty  
- B15-D: TBTN3+B15. empty   

### B16     

Menulogging is required in some situations in order to reset spawning of materials etc in places like Dav's Hope, Jameson's Crash Site and others.  
As coded, this feature cannot (should not) be used to combat log if you are attacked.  

Standard action  
- B16-M: B16. Fires a keystroke macro to exit to the menu in game then select SOLO.

Modified actions  
- B16-U: TBTN2+B16. Menulog to Private Group. This will select the top most group if you're a member of more than one. The macro can be edited via the ED_Macros.tmh file to select the second, or third etc.    
- B16-D: TBTN3+B16. Menulog to OPEN mode.  


## TWCS Throttle 

### TBTN1 (Orange button on lower RHS of Throttle body)  

Standard action  
- TBTN-M: TBTN1. Toggle Headlook ON/OFF 

Modified actions 
- TBTN1-U: TBTN2+TBTN1. Fires macro to request docking. Must have station targetted. Target Panel (LHS Panel in ship) must be at HOME position or you'll get random result.  
- TBTN1-D: TBTN2+TBTN1. empty  

### TBTN2 (Leftmost orange button on front of Throttle)  

RESERVED AS MODIFIER  

> If the SoundFX feature is ENABLED a low volume "blip" sound effect will sound whilst this button is held  

### TBTN3 (Orange button on right of TBTN2)  

RESERVED AS MODIFIER  

> If the SoundFX feature is ENABLED a low volume "blip" sound effect will sound whilst this button is held  

### TBTN4 (Up/Down switch on right of TBTN3)  

Select by pressing UP.  

Standard action  
- TBTN4-M: TBTN4. Normal flight = Fire Engine boost, Supercruise = Engage SCO Drive (if fitted)  

Modified ACTIONS  
- TBTN4-U: TBTN2+TBTN4. Increase Text-To-Speech Volume by 10% (default = 75%, max = 100%)  
- TBTN4-D: TBTN3+TBTN4. Turn the Text to speech function off and on.

> NOTE: TTS default volume can be set in ED_UserSettings.tmh

> NOTE: Volume setting will be saved to MyStates file when you exit the game or menulog  
> It will be reloaded each time you run the script or after game start is detected after a menulog   

### TBTN5 (Up/Down switch on right of TBTN3)   

Select by pressing DOWN.  

Standard action  
- TBTN5-M: TBTN5. Reverse Thrust ENGAGE/DISENGAGE

> If the SoundFX feature is ENABLED a "Reversing BEEP" sound effect will sound whilst REVERSE is active  

Modified ACTIONS  
- TBTN5-U: TBTN2+TBTN5. Decrease Text-To-Speech Volume by 10% (default = 75%, min = 5%)  
- TBTN5-D: TBTN3+TBTN5. Ship =  Set Throttle to 0. SRV = Handbrake ON/OFF  

### TLOCK (Slew Control on front of Throttle)  

Press center of slew controller  

Standard action  
- TLOCK-M: TLOCK. Recenter Headlook  

Modified actions  
- TLOCK-U: TBTN2+TLOCK. empty  
- TLOCK-D: TBTN3+TLOCK. Eject all cargo. Must Deploy Cargo Scoop first.  

## HAT controllers on throttle  

Thrustmaster, for reasons only known to themselves have positioned the HAT controllers on the throttle as follows;  
- Top = THAT2  
- Middle = THAT1  
- Bottom = THAT3  

These 3 hats have 4 positions each; up, down, left and right.  

### THAT1U  

Standard action  
- THAT1U-M: THAT1U. Supercruise ENGAGE/DISENGAGE  

Modified actions  
- THAT1U-U: TBTN2+THAT1U. Toggle FSS mode ON/OFF  
- THAT1U-D: TBTN3+THAT1U. Toggle DSS mode OFF  

### THAT1D    

Standard action  
- THAT1D-M: THAT1D. Hyperjump ENGAGE/DISENGAGE

Modified actions  
- THAT1D-U: TBTN2+THAT1D. Toggle Planet view in FSS Mode FRONT/BACK  
- THAT1D-D: TBTN3+THAT1D. empty  

### THAT1L  

Standard action  
- THAT1L-M: THAT1L. Select next system in NAV route  

Modified actions  
- THAT1L-U: TBTN2+THAT1L. FSS Mode ZOOM OUT  
- THAT1L-D: TBTN3+THAT1L. empty  

### THAT1R  

Standard action  
- THAT1R-M: THAT1R. Orbit lines OFF/ON  

Modified actions  
- THAT1R-U: TBTN2+THAT1R. FSS Mode ZOOM IN  
- THAT1R-D: TBTN3+THAT1R. empty  

### THAT2U  

This hat is dedicated predominantly to PIP Management.  
Depending on which PIP Mode is active, the code will set a different balance of PIPs between the areas.  

Selection of active PIP Mode is announced via TTS and TARGET console printout  

| PIP Mode | Balance | Selection | SYS | ENG | WEP |  
|:--------:|:-------:|:---------:|:---:|:---:|:---:|    
| 0 | Single. Assigns 1 PIP to selected system each press | SYS | +1 | | |  
| 0 | Single. Assigns 1 PIP to selected system each press | ENG | | +1 | |  
| 0 | Single. Assigns 1 PIP to selected system each press | WEP | | | +1 |  
| 1 | Double. Assigns 2 PIPs to selected system each press | SYS | +2 | | |  
| 1 | Double. Assigns 2 PIPs to selected system each press | ENG | | +2 | |  
| 1 | Double. Assigns 2 PIPs to selected system each press | WEP | | | +2 |  
| 2 | Attack. Assign 4+2, 4 to selection + 2 to Weapons or Engine | SYS | 4 | 0 | 2 |   
| 2 | Attack. Assign 4+2, 4 to selection + 2 to Weapons or Engine | ENG | 0 | 4 | 2 |   
| 2 | Attack. Assign 4+2, 4 to selection + 2 to Weapons or Engine | WEP | 0 | 2 | 4 |   
| 3 | Defend. Assign 4+2, 4 to selection + 2 to Systems or Engine | SYS | 4 | 2 | 0 |   
| 3 | Defend. Assign 4+2, 4 to selection + 2 to Systems or Engine | ENG | 2 | 4 | 0 |   
| 3 | Defend. Assign 4+2, 4 to selection + 2 to Systems or Engine | WEP | 2 | 0 | 4 |   
| 4 | Recharge. 4+1+1, 4 to selection and 1 each to the other systems | SYS | 4 | 1 | 1 |   
| 4 | Recharge. 4+1+1, 4 to selection and 1 each to the other systems | ENG | 1 | 4 | 1 |   
| 4 | Recharge. 4+1+1, 4 to selection and 1 each to the other systems | WEP | 1 | 1 | 4 |   
| 5 | General Purpose or 3+3, 3 to selection + 3 elsewhere | SYS | 3 | 3 | 0 |    
| 5 | General Purpose or 3+3, 3 to selection + 3 elsewhere | ENG | 0 | 3 | 3 |    
| 5 | General Purpose or 3+3, 3 to selection + 3 elsewhere | WEP | 3 | 0 | 3 |    

Standard action  
- THAT2U-M: THAT2U. Fire Engine focussed PIP sequence  

Modified actions  
- THAT2U-U: TBTN2+THAT2U. Increment PIP Mode (0-5). After 5, mode wraps back to 0  
- THAT2U-D: TBTN3+THAT2U. empty  

### THAT2D  

Standard action  
- THAT2D-M: THAT2D. Balance PIPS (2 PIPS each)  

Modified actions  
- THAT2D-U: TBTN2+THAT2D. Decrement PIP Mode (5-0). After 0, mode wraps back to 5  
- THAT2D-D: TBTN3+THAT2D. empty  

### THAT2L  

Standard action  
- THAT2L-M: THAT2L. Fire System focussed PIP sequence  

Modified actions  
- THAT2L-U: TBTN2+THAT2L. Focus weapons on next subsystem of targetted ship  
- THAT2L-D: TBTN3+THAT2L. empty  

### THAT2R  

Standard action  
- THAT2R-M: THAT2R. Fire Weapons focussed PIP sequence  

Modified actions  
- THAT2R-U: TBTN2+THAT2R. Focus weapons on previous subsystem of targetted ship  
- THAT2R-D: TBTN3+THAT2R. empty  

### THAT3U  

This HAT is predominantly used for countermeasures  

Standard action  
- THAT3U-M: THAT3U. Fire a shield cell bank (SCB)  

Modified actions  
- THAT3U-U: TBTN2+THAT3U. Double-bank. Fires an SCB, then 2 heat sinks seperated by several seconds  
- THAT3U-D: TBTN3+THAT3U. Fires an SCB then 1 heat sink  

### THAT3D  

Standard action  
- THAT3D-M: THAT3D. Fire a heat sink. 

> NOTE: The script checks the status.json "Overheating" flag twice per second.  
> If overheating is detected and "AutoHeatsink" in ED_UserSettings.tmh is ENABLED, a heatsink will automatically be fired.  

Modified actions  
- THAT3D-U: TBTN2+THAT3D. empty  
- THAT3D-D: TBTN3+THAT3D. empty  

### THAT3L  

Standard action  
- THAT3L-M: THAT3L. Electronic Counter Measure (ECM). Press to start charging, Release to fire.  

> NOTE: The longer you charge the ECM the greater the effective range  

Modified actions  
- THAT3L-U: TBTN2+THAT3L. empty  
- THAT3L-D: TBTN3+THAT3L. empty  

### THAT3R  

Standard action  
- THAT3R-M: THAT3R. Fire a chaff canister  

Modified actions  
- THAT3R-U: TBTN2+THAT3R. empty  
- THAT3R-D: TBTN3+THAT3R. empty  

END


  
