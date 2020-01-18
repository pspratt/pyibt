#pragma rtGlobals=1		// Use modern global access method.

// ---------------------------------------------------------------------------------------
//
//          AnalysisSettings.ipf
//
//
//          USER NAME:    Dave House
//          Date:      May 16, 2006
//
//          This file defines a function called User_Initialization() that will be executed at startup of the ECCLES Analysis program.
//
//          It lets the user define any global variables that he wants set to standard default values.
//          For example, set default titles for your averages, default sweep ranges for your averages, turn zeroing on or off, etc.
//          
//          The goal is to save you the keystrokes and mouseclicks you use over and over each time you start the analysis program.
//
//           If you DON"T want any predefined values here, you must still define the User_Initialization function, but it can be empty:
//                                  Function User_Initialization()
//					   End
//
// -------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------
//
//     To edit this file, close ECCLES and Igor.  Double-click on the AnalysisSettings.ipf file.
//      When it launches, hit ctrl-M to visualize the procedure window.  Make any changes you
//      want.  Then hit "Save Procedure" on the File menu  (NOT "Save Experiment").
//      Then re-launch ECCLES.  It will automatically open the newly saved version of this file.
//
// --------------------------------------------------------------------------------------------      

Function User_Initialization()			// This is the procedure where you change the variables YOU want to set at startup.
	Wave/T avgtitle = avgtitle
	string cmdstr
	variable avgno
	
	// Kevin
	
	avgtitle[0]="Baseline"
	avgtitle[1]="Post"
	avgtitle[2]="-40a"
	avgtitle[3]="0a"
	avgtitle[4]="+30a"
	avgtitle[5]="-90b"
	avgtitle[6]="-68b"
	avgtitle[7]="-40b"
	avgtitle[8]="0b"
	avgtitle[9]="+30b"
	avgtitle[10]="-68c"
	
	avgno = 0					// copy these titles into RTitleStr0..10, which the user sees in the Average dialog box.
	do
		cmdstr = "RTitleStr"+num2str(avgno)+ " = avgtitle["+num2str(avgno)+"]"
		execute cmdstr
		avgno += 1
	while (avgno < 11)

End
