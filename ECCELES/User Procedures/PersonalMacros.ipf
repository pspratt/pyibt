#pragma rtGlobals=1		// Use modern global access method.

// ----------------------------------------------------------------------------------------------
//
//             PersonalMacros.ipf
//
//             This procedure file should contain Macro and Function 
//             definitions for any personalized routines you
//   		    want in your Collect procedures.
//
//         	  Please DO NOT add macros or functions within the main 
//             ECCLES_Collect code.
//             This will allow us to all share a common ECCLES engine.
//
//              Thanks,    Dan
//
// ------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------
//
//     To edit this file, close ECCLES and Igor.  Double-click on the PersonalMacros.ipf file.
//      When it launches, hit ctrl-M to visualize the procedure window.  Make any changes you
//      want.  Then hit "Save Procedure" on the File menu  (NOT "Save Experiment").
//      Then re-launch ECCLES.  It will automatically open the newly saved version of this file.
//
// --------------------------------------------------------------------------------------------      

//---------------------------------- Screen Layout Functions -----------------------------
//
//     These functions are called from the --Screen Layout-- menu.
//     Modify these or add any new functions you like.
//
//------------------------------------------------------------------------------------------------------

Menu "Screen Layout"									// builds a new menu
	"1 channel layout",  one_channel_layout()
	"2 channel layout", two_channel_layout()
End

Function One_channel_layout()  				

	// Default version from DRCH Fall 2007

	DoWindow/F sweep00_window
	MoveWindow/W=sweep00_window 360,125,950,550
	SetAxis/E=1 left -100,50 
	SetAxis bottom 0,0.6 
	DoWindow/F CommandOut0	
	MoveWindow/W=CommandOut0 360,577,760,708 
	DoWindow/F CommandPulseTable0
	MoveWindow/W=CommandPulseTable0 765,600,950,700
	DoWindow/F CurrentInjectionControlPanel
	MoveWindow/W=CurrentInjectionControlPanel 765, 577, 935, 708	
	DoWindow/F Cell0Analysis
	MoveWindow/W=Cell0Analysis 0, 125, 355, 708	
End

Function Two_channel_layout()				

	// Default version from DRCH Fall 2007

	DoWindow/F sweep00_window
	MoveWindow/W=sweep00_window 360,125,950,550
	SetAxis/E=1 left -100,50 
	SetAxis bottom 0,0.6 
	DoWindow/F CommandOut0	
	MoveWindow/W=CommandOut0 360,577,760,708 
	DoWindow/F CommandPulseTable0
	MoveWindow/W=CommandPulseTable0 765,600,950,700
	DoWindow/F CurrentInjectionControlPanel
	
	DoWindow/F Cell0Analysis
	MoveWindow/W=Cell0Analysis 0, 125, 355, 708	
	DoWindow/F Cell1Analysis
	MoveWindow/W=Cell1Analysis 1555, 0, 1903, 580
	DoWindow/F sweep10_window
	MoveWindow/W=sweep10_window 960,0,1550,425
	SetAxis/E=1 left -100,50 
	SetAxis bottom 0,0.6 
	DoWindow/F CommandPulseTable1
	MoveWindow/W=CommandPulseTable1 1140,620,1355,720
	DoWindow/F CommandOut1
	MoveWindow/W=CommandOut1 1130,492,1550,623
	MoveWindow/W=CurrentInjectionControlPanel 970, 492, 1120, 720
End

//-----------------------------Other Functions & Menus   --------------------------------
//
//       Add any other functions you like, and menus to call these functions,
//       here.
//
//-------------------------------------------------------------------------------------------------------
