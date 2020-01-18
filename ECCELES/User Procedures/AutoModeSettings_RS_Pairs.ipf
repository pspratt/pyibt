#pragma rtGlobals=1		// Use modern global access method.


// -------------------------------------------------------------------------------------------------------
//
//             AutoModeSettings.ipf
//
//
//            USER:    Dan Feldman   May 16, 2006      *** David R.C. House -- August 25th, 2006
//
//
//       This file needs to be in the Igor User Procedures folder.
//
//        Use it to define any Auto Mode procedures you want Igor to do automatically
//        during data collection.  
//
//        You can specify up to 10 Auto Mode procedures.  Each procedure has a number
//         and a short name (that can fit on the Igor menu).
//         Each Auto Mode procedure can have 1-10 component steps.  These steps are 
//         executed sequentially when the user selects this auto mode from the menu.
//         The steps can define data acquisition or current injection parameters, and then
//         start data acquisition automatically;  acquisition can continue indefinitely or for
//         a predetermined number of sweeps before starting the next step.  Alternatively,
//         a step can define various Igor parameters, but NOT start automatic data aquisition.
//         In this manner, Auto Mode can be used as a short-cut for manually entering some
//         set of Igor parameters that you usually have to enter one-by-one, by hand.
//
//         For each Auto Mode you want, please enter:
//
//         AutoMenuName[n] = "NAME" (NAME will appear in Menu)
//         AutoModeSteps[n] = n   (n is between 1 and 10).  This is the number of discrete sequential steps you want performed *within* this auto mode.
//         AutoCommandn[0] = "command1; command2; command3; command4"   etc. up to 256 characters I think.
//         AutoCommandn[1] = "command1; command2; command3; command4"
//         AutoCommandn[2] = "command1; command2; command3; command4"
//             ....
//         AutoCommandn[9] = "command1; command2; command3; command4"
//
//            Command1; command2; etc. can be any command you can type on Igor's command line.  
//             i.e., you can set any global variable to any value (isi = 5; command_pulse_value0[1] = 100).
//             You can also call any defined function.    A useful function is AutoStart(x), which starts data acquisition.
//             AutoStart(0) starts indefinite data acquisition at the isi defined in the global variable "isi".
//             AutoStart(1) acquires a single sweep.
//             AutoStart(2) acquires a finite number of sweeps set in the global variable "sweeps_remaining"
//             Thus, to collect 10 sweeps, use "sweeps_remaining = 10; AutoStart(2)"
//
//         If you only have 3 steps, you can leave AutoCommandn[3..10] undefined.
//
//
//        **** PLEASE.  Do not Use Auto Mode 0.  Your first Mode should be Auto Mode 1.  Auto Mode 0 is reserved for standard Igor User Mode.
//
//   ---------------------------------------------------------------------------------------------------------------------


//---------------------------------------------------------------------------------------------
//
//     To edit this file, close ECCLES and Igor.  Double-click on the AutoModeSettings.ipf file.
//      When it launches, hit ctrl-M to visualize the procedure window.  Make any changes you
//      want.  Then hit "Save Procedure" on the File menu  (NOT "Save Experiment").
//      Then re-launch ECCLES.  It will automatically open the newly saved version of this file.
//
// --------------------------------------------------------------------------------------------      
	
Function Set_AutoMode_Variables()
	NVAR Spike_Threshold= Spike_Threshold
	Wave/T AutoMenuName = AutoMenuName
	Wave AutoModeSteps = AutoModeSteps
	Wave/T AutoCommand1 = AutoCommand1
	Wave/T AutoCommand2 = AutoCommand2
	Wave/T AutoCommand3 = AutoCommand3
	Wave/T AutoCommand4 = AutoCommand4
	Wave/T AutoCommand5 = AutoCommand5
	Wave/T AutoCommand6 = AutoCommand6
	Wave/T AutoCommand7 = AutoCommand7
	Wave/T AutoCommand8 = AutoCommand8
	Wave/T AutoCommand9 = AutoCommand9
	Wave/T AutoCommand10 = AutoCommand10
	Wave sweepnumber = sweepnumber
	
// Do not use Auto Mode 0.  Max number of steps per mode is 10.

Redimension/N=10 AutoMenuName
AutoMenuName = "Undefined"
				
// Auto Mode 1
AutoMenuName[1] = "Pairs Test 0 --> 1"	// Starts 10 sweeps of spike pairs in Ch 0; Record in Ch1; zeros display in Ch1; sets sweep window axes appropriately;  note that last collected sweep is (sweepnumber[0]-1)
AutoModeSteps[1] = 2
AutoCommand1[0] = "Setaxis/w=Sweep00_window left -100,50; Setaxis/w=Sweep00_window bottom 0,0.3; Setaxis/w=Sweep10_window left -1.5,1.5; Setaxis/w=Sweep10_window bottom 0,0.3; zero_checked(\"zero10\",1); zero_checked(\"zero00\", 0); isi = 3; command_pulse_flag0={1,0,1,0};command_pulse_flag1={0,1,0,0}; sweeps_remaining = 10; AutoStart(2)"			
AutoCommand1[1] = "Average_exists[20]=1; AvgRange[20] = num2str(sweepnumber[0]-10)+\"-\"+ num2str(sweepnumber[0]-1); RangeStr20=AvgRange[20]; AvgTitle[20]=\"PairsTest\"; RTitleStr20=AvgTitle[20]; bMake_Average_Proc(\"bAvgOK10\"); Button bStop, win=Control_Bar, title=\"Start DAQ\",rename=bStart; EnterUserMode()"
// Auto Mode 2
AutoMenuName[2] = "Pairs Test 1 --> 0"	// Starts 10 sweeps of spike pairs in Ch 0; Record in Ch1; zeros display in Ch1; sets sweep window axes appropriately;  note that last collected sweep is (sweepnumber[0]-1)
AutoModeSteps[2] = 2
AutoCommand2[0] = "Setaxis/w=Sweep00_window left -1.5,1.5; Setaxis/w=Sweep00_window bottom 0,0.3; Setaxis/w=Sweep10_window left -100,50; Setaxis/w=Sweep10_window bottom 0,0.3; zero_checked(\"zero10\",0); zero_checked(\"zero00\", 1); isi = 3; command_pulse_flag1={1,0,1,0}; command_pulse_flag0={0,1,0,0}; sweeps_remaining = 10; AutoStart(2)"
AutoCommand2[1] = "Average_exists[0]=1; AvgRange[0] = num2str(sweepnumber[0]-10)+\"-\"+ num2str(sweepnumber[0]-1); RangeStr0=AvgRange[0]; AvgTitle[0]=\"PairsTest\"; RTitleStr0=AvgTitle[0]; bMake_Average_Proc(\"bAvgOK00\"); Button bStop, win=Control_Bar, title=\"Start DAQ\",rename=bStart; EnterUserMode()"
//Auto Mode 3
AutoMenuName[3] = "PreVm Modulation Test 0 --> 1"	// Starts 60 sweeps of spike pairs in Ch 0; Record in Ch1; 2 sec isi;  purpose:  Test Analog Digital Synaptic Modulation
AutoModeSteps[3] = 1								// This assumes user has set spike parameters and window display parameters for unitary connection before running this auto mode
AutoCommand3[0] = "zero_checked(\"zero10\",1); zero_checked(\"zero00\", 0); isi = 2; sweeps_remaining = 60; AutoStart(2)"
//Auto Mode 4
AutoMenuName[4] = "PreVm Modulation Test 1 --> 0"	// Starts 60 sweeps of spike pairs in Ch 1; Record in Ch0; 2 sec isi;  purpose:  Test Analog Digital Synaptic Modulation
AutoModeSteps[4] = 1								// This assumes user has set spike parameters and window display parameters for unitary connection before running this auto mode
AutoCommand4[0] = "zero_checked(\"zero00\",1); zero_checked(\"zero10\", 0); isi = 2; sweeps_remaining = 60; AutoStart(2)"


// Add any more Auto Modes you want to add .....



End
