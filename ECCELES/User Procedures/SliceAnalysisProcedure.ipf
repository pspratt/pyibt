#pragma rtGlobals=1		// Use modern global access method.
#include "CollectFileDefaults"		// This file defines a procedure, SetDefaultPaths, that defines the following variables:
								// DefaultDataPath	--  for reading saved data files
								// AnalysisFilePath	--  for analysis descriptor files
								// CrunchFilePath		--  for crunch descriptor files

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
//                  Data Analysis From Disk Files           Rev 4.4
//
//                      for IGOR 3.13b with NIDAQ Tools
//
//                      Dan Feldman 
// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 


// Global variable definitions
String/G DefaultDataPath				// default path for reading saved data files
String/G AnalysisFilePath				// default path for reading analysis descriptor files
String/G CrunchFilePath				// default path for reading/writing crunch descriptor files

Variable/G no_samples				// number of DAQ samples per sweep
Variable/G kHz 						// DAQ sample rate in kHz
Make/N=2000 display_wave1				// Copy of wave for display
Make/N=1 sweeptimes					// Wave to record time of all sweeps in expt.
Variable/G gZERO=0 					// Flag for zeroing sweeps during acquisition
Variable/G sweepnumber				// current sweep number.
String/G Expt						// name of current experiment or cell
Variable/G refnum=0					// reference number for access open disk sweep file.
String/G Pathname					// name of path for saving data to disk
Variable/G DCoffset					// for turning on & off trace zeroing

// Globals for setting time axis on analysis plots
Variable/G left_value
Variable/G right_value

// Globals for file reading & writing
String/G separator = "|"					// Single char for coding of x, y, expt names
Variable/G fheader_magicnumber = 1	// Codes for writing & reading to binary files
Variable/G wheader_magicnumber = 2
Variable/G sweep_magicnumber = 3
Variable/G disk_sweep_time
Variable/G first_sweep_time
Variable/G disk_sweep_no
Variable/G current_wheader_ptr		// this pointer contains the byte address of the current waveheader
String/G ydataname
String/G xdataname
String/G exptname

String/G extension = ".ibt"

// Globals for calculating average sweeps
Make/N=8 avgstart					// beginning sweep of range for average
Make/N=8 avgend					// end sweep of range for average
Make/N=8 average_exists
Make/N=8 avgDCoffset
Make/T/N=8 avgtitle
Variable/G max_averages
String/G RangeStr0="ST-END"				// string ranges for averages
String/G RangeStr1="ST-END"
String/G RangeStr2="ST-END"
String/G RangeStr3="ST-END"
String/G RangeStr4="ST-END"
String/G RangeStr5="ST-END"
String/G RangeStr6="ST-END"
String/G RangeStr7="ST-END"
String/G RTitleStr0="Average0"				// title strings for averages
String/G RTitleStr1="Average1"
String/G RTitleStr2="Average2"
String/G RTitleStr3="Average3"
String/G RTitleStr4="Average4"
String/G RTitleStr5="Average5"
String/G RTitleStr6="Average6"
String/G RTitleStr7="Average7"


// Globals for keeping track of analyses
Variable/G number_of_analyses
String/G analysismenulist				// for making popupmenu
Make/N=10 analmenureference				// index for making analysis popupmenu
Variable/G show_anal_cursors			// toggle for showing anal cursors or not
Variable/G firstanalsweep				// start sweep for doing analyses
Variable/G lastanalsweep				// end sweep for doing analyses
Variable/G current_analysis_number	// for controlling analysis window cursors

Make/N=10 analysis_on				// 0 or 1 for is analysis being used?
Make/N=10 analysis_display			// should analysis window be created?
Make/T/N=10 analysis_name			// title
Make/T/N=10 analysis_type			// type of analysis:  AMPL, PKTOPK, IHOLD, etc.
Make/N=10 analysis_path				// path--not used here, but included for compatibility with analysis descriptor files used during collection
Make/N=10 analysis_cursor0			// 1st coord of analysis window
Make/N=10 analysis_cursor1			// 2nd coord of analysis window
Make/N=10 analysis_y0				// lower y axis bound for graph setup
Make/N=10 analysis_y1				// upper y axis bound for graph setup
Make/N=0 analysis0					// results of analysis 0
Make/N=0 analysis1					// results of analysis 1
Make/N=0 analysis2					// results of analysis 2
Make/N=0 analysis3					// results of analysis 3
Make/N=0 analysis4					// results of analysis 4
Make/N=0 analysis5					// results of analysis 5
Make/N=0 analysis6					// results of analysis 6
Make/N=0 analysis7					// results of analysis 7
Make/N=0 analysis8					// results of analysis 8
Make/N=0 analysis9					// results of analysis 9
Make/N=2 path_mode					// 0 or 1 indicating whether path is a current or voltage recording.

// ANALYSIS TYPES CURRENTLY SUPPORTED:
//		AMPL: absolute amplitude
//		IHOLD: also absolute amplitude
//		RSERIES:  calculated from transient and step size
//		RINPUT:  calculated from step size and whether it is a current or voltage recording
//		PKTOPK:  peak-to-peak amplitude within a specified window
//		SUB:  calculated ANAL0-ANAL1, where ANAL0=analysis number in analysis_cursor0
//				and ANAL1=the analysis number in analysis_cursor1
//		SLOPE:  slope between two x-values (in seconds) using IGOR curve-fit routine
//		TIMEOFAPPK:  calculates time of occurrence of peak of AP (where AP=largest depolarization within anal. window)
//		EPSPPK: calculates mean amplitude of 5 pts around max positive potential within the anal window (assumes positive going pk)
//           FIELDPK:  calculates mean amplitude of 5 pts around max negative field within the anal. window. (assumes negative going pk)
//		TIMEOFNEGPK:  calculates time (in s) of negative-going peak within the anal. window.
//		LATENCY:  calculates time of positive- or negative going latency, defined as 2 consecutive points > 2 s.d. away from mean of
//				initial 2 ms of analysis window.


Variable/G stepsize = -5				// For calculating Rin and Rseries  	(in mV or pA)			

// Globals for keeping track of marks on analysis graphs
Make/N=5 mark_exists				// does a given mark exist?
Make/N=5 MarkSweep				// sweep number at which to place each mark
Variable/G Mark0Sweep
Variable/G Mark1Sweep
Variable/G Mark2Sweep
Variable/G Mark3Sweep
Variable/G Mark4Sweep

// Globals for crunching across experiments
Variable/G crunch_type = 0						// 0 = slope;  1 = netamp;  2= absamp
Variable/G crunch_no_files=0
String/G crunchfilenamestr=" "
Make/T/N=0 crunch_file
Make/N=0 crunch_sweep0
Make/N=0 crunch_sweep1
Make/N=0 crunch_bline0
Make/N=0 crunch_bline1
Make/N=0 crunch_anal0
Make/N=0 crunch_anal1
Make/N=0 crunch_align
Make/N=0 crunch_binsize
Make/N=0 crunch_included			// on-off 1-0 for including a cell in the crunch.  Not saved to disk.
Make/D/N=0 crunch_mean
Make/D/N=0 crunch_stdev
Make/N=0 crunch_n
Variable/G max_crunch_bins
Variable/G crunch_zero_bin			// this is the bin where all the aligned sweeps are.
Variable/G crunch_normalize=1
Make/N=0 crunch_align_offset			// for aligning cells in a crunch
Make/N=0 crunch_align_firstn

// Globals for epoch analysis
String/G epoch_analysis_list			// analysis numbers to calculate values for
String/G epoch_range0="ST-END"		// sweep range for epoch 0
String/G epoch_range1="ST-END"		// sweep range for epoch 1
String/G epoch_range2="ST-END"		// sweep range for epoch 2
String/G epoch_range3="ST-END"		// sweep range for epoch 3
String/G epoch_range4="ST-END"		// sweep range for epoch 4
String/G epoch_range5="ST-END"		// sweep range for epoch 5
String/G epoch_range6="ST-END"		// sweep range for epoch 6
String/G epoch_range7="ST-END"		// sweep range for epoch 7
String/G epoch_temprange
Variable/G epoch_normalize			// flag to indicate whether to normalize epoch results to first epoch


// Start the experiment
	
	Initialize_General_Variables( )
	
	// set up sweep window
	Make_Sweep_Window()

	// set up main control panel	
	NewPanel/W=(0,0,1020,75) as "Control Bar"
	DoWindow/C Control_Bar						// Name it Control_Bar

	// define all controls on Control Panel
	Button bQuit, pos={15,5}, size = {50,50}, proc=bQuitProc, title="Quit"
	SetVariable setvar_path pos={85,8}, size={200,25}, title="Path", value=pathname, fsize=10, proc=newpathproc
	SetVariable setvar_expt pos={85,30}, size={200,25}, noproc, title="File name", proc=NewFileProc, value=Expt, fsize=10
	Button bReadWave, pos={360,10}, size={80,50}, proc=bReadWaveProc, title="Read Sweep"
	Button bNextWave, pos={460,10}, size={100,20}, proc=bNextWaveProc, title="Next Sweep"
	Button bPrevWave, pos={460,40}, size={100,20}, proc=bPrevWaveProc, title="Prev Sweep"
	SetVariable setvar_sweep_no pos={85, 55}, size={200,25}, title="Sweep no.", value=disk_sweep_no, fsize=10, proc=GetSweep	
	Button bLayout pos={720,5}, size={80,30}, proc=bLayoutProc,title="Print Layout"
	Button bSHOW, pos={720,40},size={80,30},proc=bShowAnalCursors,title="SHOW cursors"
	SetVariable setvar_stepsize size={105,20}, noproc, pos={855,10}, title="Step (mV)", value=stepsize, fsize = 9


// -------- Everything should now run on its own.
		
//--------------------------------------------------------Macros----------------------------------------------------------//

Macro Set_Control_Panel_Color()

	ModifyPanel cbRGB=(500,500,65535)
End

Macro Arrange_Crunch_Table()
	
	ModifyTable size=9,width(Point)=30
	ModifyTable size(crunch_included)=8,width(crunch_included)=36,title(crunch_included)="Include?";DelayUpdate
	ModifyTable size(crunch_file)=8, width(crunch_file)=90,title(crunch_file)="Filename (no path/ext.)";DelayUpdate
	ModifyTable size(crunch_sweep0)=8,width(crunch_sweep0)=40,title(crunch_sweep0)="StSweep";DelayUpdate
	ModifyTable size(crunch_sweep1)=8,width(crunch_sweep1)=40,title(crunch_sweep1)="EndSweep";DelayUpdate
	ModifyTable size(crunch_bline0)=8,width(crunch_bline0)=40,title(crunch_bline0)="StBline";DelayUpdate
	ModifyTable size(crunch_bline1)=8,width(crunch_bline1)=40,title(crunch_bline1)="EndBline";DelayUpdate
	ModifyTable size(crunch_anal0)=8,width(crunch_anal0)=40,title(crunch_anal0)="AnalWin0";DelayUpdate
	ModifyTable size(crunch_anal1)=8,width(crunch_anal1)=40,title(crunch_anal1)="AnalWin1";DelayUpdate
	ModifyTable size(crunch_align)=8,width(crunch_align)=40,title(crunch_align)="AlignSweep";DelayUpdate
	ModifyTable size(crunch_binsize)=8,width(crunch_binsize)=40,title(crunch_binsize)="BinSize"

EndMacro
		
		
Macro Arrange_Analysis_Table()
	
	ModifyTable size=9,width(Point)=30
	ModifyTable size(analysis_on)=8,width(analysis_on)=36,title(analysis_on)="On?";DelayUpdate
	ModifyTable size(analysis_display)=8,width(analysis_display)=36,title(analysis_display)="Show?";DelayUpdate
	ModifyTable size(analysis_name)=8, width(analysis_name)=90,title(analysis_name)="Name";DelayUpdate
	ModifyTable size(analysis_type)=8,width(analysis_type)=40,title(analysis_type)="TYPE";DelayUpdate
	ModifyTable size(analysis_path)=8,width(analysis_path)=40,title(analysis_path)="Path";DelayUpdate
	ModifyTable size(analysis_cursor0)=8,width(analysis_cursor0)=50,title(analysis_cursor0)="St.Window";DelayUpdate
	ModifyTable size(analysis_cursor1)=8,width(analysis_cursor1)=40,title(analysis_cursor1)="EndWindow";DelayUpdate

EndMacro

Macro ReversalPotentialCalculator(Current_at_0mV, Current_at_10mV)
	Variable Current_at_0mV
	Variable Current_at_10mV
	
	Print 10* (  Current_at_0mV / (Current_at_0mV - Current_at_10mV)  )
EndMacro

// --------------------------------------------------------- Menus ---------------------------------------------------------- //

Menu "--Average--"
	"Make Average...", Select_Avg_Proc()
	"Delete Average...",Delete_Avg_Proc()
	"Save Average...",Save_Avg_Proc()
End

Menu "--Analyses--"
	"Load New Analysis File", Reload_Analysis()
	"Select Analysis...", Select_Analysis()
	"Run...", Run_Analysis()
	"Reset All", Reset_Analyses()
	"Time Axis...", Adjust_Time_Axis()
	"Write Results", Write_Analysis_Results()
	"Crunch Expts", Make_Crunch_Dialog()
	"Epoch Calculator", Make_Epoch_Dialog()
	"Identify Analysis Sweep", SetUpCursorProc()
End

Menu "--Mark--"
	"New Mark", Make_Mark()
	"Edit Mark", Edit_Mark()
	"Delete...", Delete_Marks()
End

Function DummyProc()

	print "Not a valid menu choice"
End

Menu "--Display--"
	"Make Stim Protocol Graph",Make_Stim_Protocol_Graph()
End


//----------------------------------------------------------Initialization Routine -----------------------------------------//

Function Initialize_General_Variables()

	SVAR Pathname = Pathname
	SVAR Expt = Expt
	Wave display_wave1 = display_wave1
	NVAR disk_sweep_no = disk_sweep_no
	SVAR Exptname = Exptname
	SVAR ydataname = ydataname
	SVAR xdataname = xdataname
	Wave average_exists = average_exists
	Wave avgDCoffset = avgDCoffset
	Wave/T avgtitle=avgtitle
	NVAR current_average_number = current_average_number
	NVAR max_averages = max_averages
	NVAR left_value = left_value
	NVAR right_value = right_value
 	NVAR show_anal_cursors = show_anal_cursors
 	SVAR DefaultDataPath = DefaultDataPath		
 	Wave average_exists = average_exists
 	Wave path_mode = path_mode
 	
 	SetDefaultPaths()					// procedure defined in "CollectFileDefaults.ipf"
 									//  Sets DefaultDataPath, AnalysisFilePath, CrunchFilePath
	Pathname = DefaultDataPath
	disk_sweep_no =1
	display_wave1 = 0

	Expt = "Untitled"
	ydataname = ""
	xdataname = ""
	Exptname = "--no experiment--"
	
	path_mode = 0						// ASSUME current recording.  I need to have this stored with data in disk file!
	
	left_value = 0							// initial values for time axis of analysis graphs
	right_value = 20						// ditto
	
	NewPathProc("",0,"","")							// set the savepath symbolic path from pathname
	
	average_exists = 0
	current_average_number = 0
	avgDCoffset = 0		
	max_averages = 8
	avgtitle[0]="Average0"
	avgtitle[1]="Average1"
	avgtitle[2]="Average2"
	avgtitle[3]="Average3"
	avgtitle[4]="Average4"
	avgtitle[5]="Average5"
	avgtitle[6]="Average6"
	avgtitle[7]="Average7"
	
	show_anal_cursors = 1		
End

Function ReInitialize()
 
	Delete_All_Averages("")
	Delete_All_Marks("")
	DoWindow/K Mark_Window
	Reset_Analyses()

	Initialize_General_Variables()
End


Function Initialize_Analyses()

	Wave/T analysis_name = analysis_name
 	Wave analysis_cursor0 = analysis_cursor0
 	Wave analysis_cursor1 = analysis_cursor1
 	Wave analysis_path = analysis_path
 	Wave/T analysis_type = analysis_type
 	Wave analysis_on = analysis_on
 	Wave analysis_display = analysis_display
 	Wave analysis_y0 = analysis_y0
 	Wave analysis_y1 = analysis_y1
 	NVAR number_of_analyses = number_of_analyses
 	SVAR AnalysisFilePath = AnalysisFilePath				// Set by SetDefaultPaths(), above
 	
 	Make/N=10 inp0				// temporary input waves.  Max 10 analyses
 	Make/N=10 inp1
	Make/T/N=10 inp2
	Make/T/N=10 inp3
	Make/N=10 inp4
	Make/N=10 inp5
	Make/N=10 inp6
	Make/N=10 inp7
	Make/N=10 inp8
	Make/N=10 inp9
 	
 	String cmdstr
 	
 	cmdstr ="NewPath/O/Q analysissetup \""+AnalysisFilePath+"\""			//  Set global from default directory file
 	Execute cmdstr
 	print "Preparing to load waves from setup file"
 	LoadWave/J/P=analysissetup/K=0/N=inp 
 	print "Loading complete"
 	
	// set number_of_analyses
	variable end_detected=0
	number_of_analyses = 0
	do
		if (inp0[number_of_analyses] == -1)		// analysis_on
			end_detected = 1
		endif
		if (number_of_analyses > 10)
			end_detected =1
			DoAlert 0, "There may have been a problem loading the analysis setup file."
		endif
		number_of_analyses += 1
	while (!end_detected)
	number_of_analyses -= 1

	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_on"
	Execute cmdstr
	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_display"
	Execute cmdstr
	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_name"
	Execute cmdstr
	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_type"
	Execute cmdstr
	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_path"
	Execute cmdstr
	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_cursor0"
	Execute cmdstr
	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_cursor1"
	Execute cmdstr
	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_y0"
	Execute cmdstr
	cmdstr="Redimension/N="+num2str(number_of_analyses)+" analysis_y1"
	Execute cmdstr
	
 	Analysis_on = inp0
 	Analysis_display = inp1
 	Analysis_name = inp2
 	Analysis_type = inp3
 	Analysis_path = inp4				//Note: i'm skipping analysis channel=inp5
 	analysis_cursor0=inp6
 	analysis_cursor1=inp7
 	analysis_y0 = inp8
 	analysis_y1 = inp9
 	 
 	Killwaves inp0, inp1, inp2, inp3, inp4, inp5, inp6, inp7, inp8, inp9
 	
 End
 				
Function Reload_Analysis()			// called when user wants to load in a new analysis parameter file.

	// get rid of old analysis windows
	
	DoWindow/K analysis_window0
	DoWindow/K analysis_window1
	DoWindow/K analysis_window2
	DoWindow/K analysis_window3
	DoWindow/K analysis_window4
	DoWindow/K analysis_window5
	DoWindow/K analysis_window6
	DoWindow/K analysis_window7
	DoWindow/K analysis_window8
	DoWindow/K analysis_window9
	
	// allow user to load in a new analysis parameter file.
	
	Initialize_Analyses()
		
	SetUpAnalysisWindows()
	
End

Function bZEROProc(ctrlName2) : buttoncontrol
	string ctrlName2		// ctrlName2 is "bZERO" when called for DC -> zero switch
						// ctrlName2 is "bDC" when called for zero -> DC switch
	
	NVAR gZERO = gZERO
	NVAR DCoffset = DCoffset
	Wave display_wave1 = display_wave1
	variable i1
	string avgwave, cmdstr
	NVAR max_averages = max_averages
	wave avgDCoffset = avgDCoffset
	wave average_exists = average_exists
	
	if ( cmpstr(ctrlName2, "bZERO") == 0)
		gZERO = 1										// turn zeroing on
		Button $ctrlName2, title="DC",rename=bDC						// rechristen the button DC
		DCoffset = mean (display_wave1,0,pnt2x(display_wave1,9))		// zero the current wave
		display_wave1 -= DCoffset
		i1 = 0
		do
			if (average_exists[i1] == 1)								// zero all the average sweeps
				avgwave = "Average_"+num2str(i1)
				avgDCoffset[i1] = mean($avgwave,0,pnt2x($avgwave,9))
				cmdstr = avgwave + "-=avgDCoffset["+num2str(i1)+"]"
				Execute cmdstr
			endif
			i1 += 1
		while (i1 < max_averages)
	else
		gZERO = 0										// turn zeroing off
		Button $ctrlName2, title="Zero B'line", rename=bZERO			// rechristen ZERO
		display_wave1 += DCoffset									// remove DC offset from current wave
		i1 = 0
		do														// unzero all the average sweeps
			if (average_exists[i1] == 1)
				avgwave = "Average_"+num2str(i1)
				cmdstr = avgwave + "+=avgDCoffset["+num2str(i1)+"]"
				Execute cmdstr
			endif
			i1 += 1
		while (i1 < max_averages)
		DCoffset = 0	
	endif
End

Function bHideSweepProc(ctrlname) : buttoncontrol
	string ctrlname
	
	if ( cmpstr(ctrlName, "bHideSweep") == 0)			// if user wants to hide the sweep
		RemoveFromGraph/Z display_wave1
		Button $ctrlName, title="Show Swp",rename=bShowSweep						// rechristen the button bShowSweep
	endif
	
	if (cmpstr(ctrlName, "bShowSweep") == 0)			// if user wants to display sweep
		AppendToGraph/C=(52224,0,0) display_wave1
		Button $ctrlName, title="Hide Swp", rename = bHideSweep
	endif
End

	
Function bShowAnalCursors(ctrlname) : buttoncontrol
	string ctrlname
	NVAR show_anal_cursors = show_anal_cursors
	
	DoWindow/F Control_Bar
	if ( cmpstr(ctrlname,"bSHOW") == 0)		// if user wants to show cursors
		show_anal_cursors = 1
		Button $ctrlname, title= "HIDE cursors", rename = bHIDE
		Draw_Analysis_Cursors(1)
	else										// user wants to hide cursors
		show_anal_cursors = 0
		Button $ctrlname, title="SHOW cursors", rename = bSHOW
		Draw_Analysis_Cursors(0)
	endif
End

Function NewPathProc(dum1, dum2, dum3, dum4)	
	string dum1
	variable dum2
	string dum3
	string dum4							// this function is called if the user changes the pathname for saving data

	SVAR pathname = pathname
	
	NewPath/O savepath pathname		// overwrites the path if it exists.
	
End

Function bQuitProc(dummy) : buttoncontrol
	string dummy
	Button bQuit, rename=bReally, title = "Really?"
	Button bYesQuit, pos = {70,10}, size = {25, 15}, title="Yes", proc=bYesQuitProc
	Button bNoQuit, pos= {70, 30}, size= {25,15}, title="No", proc=bNoQuitProc
End

Function bYesQuitProc(dummy) : buttoncontrol
	string dummy
	bNoQuitProc("")
	CleanUp()
	Execute "quit/N"			// quit without saving -- when programming, you must save changes manually--
							// run CleanUp() first, then save changes, then type "Quit" on command line
							// and answer "yes" to save changes.
End

Function bNoQuitProc(dummy) : buttoncontrol
	string dummy
	Button bReally, title = "Quit", rename=bQuit
	KillControl bYesQuit
	KillControl bNoQuit
End

//---------------------------------------------------- Sweep Window ----------------------------------------------------------//

Function Make_Sweep_Window() : Graph
	NVAR sweepnumber = sweepnumber
	NVAR sweep0time = sweep0time
	Wave sweeptimes = sweeptimes
	SVAR ydataname = ydataname
	SVAR xdataname = xdataname
	SVAR exptname = exptname
	NVAR show_anal_cursors = show_anal_cursors
	
	string commandstr
	
	PauseUpdate; Silent 1		// building window...
	Display /W=(365,115,763,315) display_wave1 as "Sweep"
	DoWindow/C Sweep_window					// name it Sweep_window
	ModifyGraph wbRGB=(65280,65280,65280),gbRGB=(65280,65280,65280)
	Label left "mV"
	Label bottom "Time (sec)"
	SetAxis/E=1 left -40,20
	SetAxis bottom 0,0.1
	SetDrawLayer UserFront
	ModifyGraph axoffset(left)=-1, zero(left)=1
	
	textbox /A=MT/F=0/E "Sweep \{disk_sweep_no} -- \{secs2time(disk_sweep_time,3)}"
	Button bZERO, pos={440,8}, size={60,20},title="Zero B'line",proc=bZEROProc		// Trace zeroing control
	Button bShowSweepCursors, pos ={440,32}, size={60,20}, title="Cursors", proc=bAdjust_Anal_Cursors_FrontEnd
	Button bHideSweep, pos={370,8}, size={60,20}, title = "Hide swp", proc=bHideSweepProc	     // allow user to remove sweep from graph
	
	commandstr = "Label left \""+ydataname+"\""
	execute commandstr
	commandstr = "Label bottom \""+xdataname+"\""
	execute commandstr
		
	// Make_Step_Window()
		
	if (show_anal_cursors == 1)
		Draw_Analysis_Cursors(1)											
	endif
End


Function Make_Step_Window()

	Wave display_wave1 = display_wave1
	
	PauseUpdate; Silent 1		// building window...
	Display/W=(500,340,760.5,500) display_wave1 as "Step"
	DoWindow/C Step_window				// name it
	ModifyGraph wbRGB=(64000,64000,0),gbRGB=(65535,65535,65535)  					// yellow!
	Label left "pA"
	Label bottom "time (msec)"
	SetAxis/E=1 left -100,200
	SetAxis bottom 0.29,0.4
	SetDrawLayer UserFront
	ModifyGraph axoffset(left)=-1, zero(left)=1
	ModifyGraph tick=2, btlen=2, lblMargin =1							// various things to conserve space
	ModifyGraph margin(bottom)=25, margin(top)=10, margin(right)=10		// more things to conserve space
	ModifyGraph margin(left)=25, tloffset(left) = 2							// ditto
End



//----------------------------------------- Functions Controlling Analysis Cursors ----------------------------------------------------//

Function Draw_Analysis_Cursors(flag1)
	variable flag1								// 1 to draw cursors, 0 to erase them
	
	NVAR number_of_analyses = number_of_analyses
	Wave analysis_cursor0=analysis_cursor0
	Wave analysis_cursor1=analysis_cursor1
	Wave analysis_on=analysis_on
	Wave/T analysis_type = analysis_type
	Wave/T analysis_name = analysis_name
	
	Variable i1=0
	
	DoWindow/F Step_window					// erase step window
	SetDrawLayer/K Userback
	
	DoWindow/F Sweep_window				// erase sweep window	
	SetDrawLayer/K Userback

	if (flag1 == 1)
		do
			if ((analysis_on[i1]==1) %& (cmpstr(analysis_type[i1],"SUB") != 0) )		// if analysis is active
																				// and it's not type SUB
				DoWindow/F sweep_window
				SetDrawLayer UserBack			
				SetDrawEnv xcoord = bottom, ycoord = prel, linethick=2,save
				DrawLine analysis_cursor0[i1],0.75+(.02*i1),analysis_cursor1[i1],0.75+(0.02*i1)
				SetDrawEnv textxjust=0, textyjust=2,fsize=10
				DrawText analysis_cursor0[i1], 0.77+(.02*i1),analysis_name[i1]
			endif
			i1 += 1
		while (i1 < number_of_analyses)
	endif
	
End

Function bShow_Anal_Cursors(ctrlstring)				// called from control bar button or Menu
	string ctrlstring
	
	NVAR show_anal_cursors = show_anal_cursors
	
	if (show_anal_cursors == 0)
		show_anal_cursors = 1
	else
		show_anal_cursors = 0
	endif
	Draw_Analysis_Cursors(show_anal_cursors)
	
End


// (These are called from the Menu)

Function Select_Analysis()
	NewPanel/W=(375,15,535,85) as "Add Analysis"
	DoWindow/C Add_Analysis_Window
	
	Button bAddNewAnalysis, pos={10,15}, size={40,40}, title = "NEW", proc = AddNewAnalProc
	Button bCloseSelectAnalWindow, pos={110,15}, size={40,40}, title="Close", proc=CloseSelectAnalWindowProc
	Button bUpdateAnalyses, pos={60,15},size={40,40},title="Update",proc=UpdateAnalysesProc
	
	// put up a table so user can edit analysis parameters.
	Edit/w=(105,115,520,285) analysis_on, analysis_display, analysis_name, analysis_type, analysis_path, analysis_cursor0, analysis_cursor1 as "Analysis List"
	DoWindow/C Analysis_Table
	Execute "Arrange_Analysis_Table()"
	
End

Function UpdateAnalysesProc(dummy)
	string dummy
	
	// User has altered the analysis list.  Update display of analysis cursors to reflect this.  Also add/remove appropriate
	// analysis windows.  ADD THIS FUNCTION IN THE FUTURE.
	
	NVAR show_anal_cursors = show_anal_cursors
	
	if (show_anal_cursors == 1)
		Draw_Analysis_Cursors(1)
	endif
	
	DoAlert 0, "Use Make_Analysis_Window(number) to add new analysis window."
	
End

Function AddNewAnalProc(dummy) : buttoncontrol
	string dummy
	
	NVAR number_of_analyses = number_of_analyses
	string cmdstr
	
	number_of_analyses += 1
	
	cmdstr = "Redimension/N="+num2str(number_of_analyses)+" analysis_on"
 	Execute cmdstr
 	cmdstr = "Redimension/N="+num2str(number_of_analyses)+" analysis_name"
 	Execute cmdstr
	cmdstr = "Redimension/N="+num2str(number_of_analyses)+" analysis_type"
 	Execute cmdstr
 	cmdstr = "Redimension/N="+num2str(number_of_analyses)+" analysis_path"
 	Execute cmdstr
 	cmdstr = "Redimension/N="+num2str(number_of_analyses)+" analysis_cursor0"
 	Execute cmdstr
 	cmdstr = "Redimension/N="+num2str(number_of_analyses)+" analysis_cursor1"
 	Execute cmdstr
 	
End

Function CloseSelectAnalWindowProc(dummy) : buttoncontrol
	string dummy
	
	DoWindow/K Add_Analysis_Window
	DoWindow/K Analysis_Table
End

Function bAdjust_Anal_Cursors_FrontEnd(ctrlName)	
	string ctrlName
	
	// This procedure is called when user clicks Cursors button on Sweep or Step windows.
	//  If called by bShowSweepCursors, this procedure will call Adjust_Anal_Cursors(0)
	//  If called by bShowStepCursors, this procedure will call Adjust_Anal_Cursors(2)
	//  This is for compatibility with the collect program, which uses path0=sweep, path2=step
	
	If (cmpstr(ctrlName,"bShowSweepCursors")==0)
		Adjust_Anal_Cursors(0)
	endif
	if (cmpstr(ctrlName,"bShowStepCursors")==0)
		Adjust_Anal_Cursors(2)
	endif
End

Function Adjust_Anal_Cursors(path) 	// allows user to graphically change analysis windows using cursors
	variable path						// path = 0 means path0;  path = 1 means path1; path=2 means STEP window (path0)
									// in the analysis program, treat 0 and 1 as identical and referring to sweep window.  
									// treat path 2 as unique, referring to step window.
	Wave/T analysis_name = analysis_name
	Wave/T analysis_type = analysis_type
	NVAR number_of_analyses= number_of_analyses
	Wave analysis_path = analysis_path
	Wave analysis_on = analysis_on
	Wave analmenureference=analmenureference
	SVAR analysismenulist=analysismenulist
	
	// create popupmenu listing relevant analyses
	
	variable i1 = 0
	variable j1 = 0
	analysismenulist = ""
	analmenureference=0
	do
		if ((analysis_on[i1] == 1) %& (analysis_path[i1]==path) %& (cmpstr(analysis_type[i1],"SUB") != 0))
			analysismenulist += analysis_name[i1]				// no cursors to adjust if type is SUB
			analmenureference[j1]=i1							// create LUT for popupmenu
			j1 += 1
			if (i1 < (number_of_analyses-1))
				analysismenulist += ";"
			endif
		endif
		i1 += 1
	while (i1<number_of_analyses)
	
	if (path==0)
		Popupmenu Analchoices, mode=1, win=Sweep_window, pos = {290,50}, proc=AnalChoicesProc, title="Analysis:",value=#"analysismenulist"
	endif
	if (path==2)
		Popupmenu Analchoices, mode=1, win=Step_window, pos = {220,50}, proc=AnalChoicesProc, title="Analysis:",value=#"analysismenulist"
	endif
End


Function AnalChoicesProc(ctrlName, popNum, popStr) : PopUpMenuControl			// for adjusting analysis cursors
	string ctrlName
	Variable popNum
	String popStr
	
	Wave/T analysis_name = analysis_name
	Wave analysis_path = analysis_path
	Wave analysis_cursor0=analysis_cursor0
	Wave analysis_cursor1=analysis_cursor1
	String commandstr, wavestr
	Wave analmenureference = analmenureference
	
	Variable analysis_number
	
	// Erase the popupmenu
	KillControl Analchoices
	
	popNum -= 1		
	analysis_number = analmenureference[popNum]			// Look up the chosen analysis from the LUT	
	
	// On the appropriate window.... //
	if ((analysis_path[analysis_number] == 0) %| (analysis_path[analysis_number] == 1) )			// ** UNIQUE FOR ANALYSIS PROG ** //
		DoWindow/F sweep_window
		Button bACCEPT, pos={460,64}, size={40,20}, title="Accept", proc=bACCEPTProc
		Button bREVERT, pos ={460,88}, size={40,20}, title="Revert", proc=bREVERTProc
		wavestr = wavename("sweep_window",0,3)				// put cursor on first wave displayed in the window
	endif

	print "analysis_number", analysis_number, "path: ", analysis_path[analysis_number]
	
	if (analysis_path[analysis_number] == 2)				// assumes STEP is associated with path 0
		DoWindow/F step_window
		Button bACCEPT, pos={260,64}, size={40,20}, title="Accept", proc=bACCEPTProc
		Button bREVERT, pos ={260,88}, size={40,20}, title="Revert", proc=bREVERTProc
		wavestr=wavename("step_window",0,3)
	endif
	
	// ... draw the current analysis window.  //
	SetDrawLayer UserFront
	SetDrawEnv fsize=10, linethick=1, xcoord=bottom, save
	DrawLine analysis_cursor0[analysis_number],0.1,analysis_cursor0[analysis_number],0.9				// draw in cursor0 position
	DrawLine analysis_cursor1[analysis_number],0.1,analysis_cursor1[analysis_number],0.9				// draw in cursor1 position
	commandstr = "TextBox/F=0/N=label/A=LT \"" + analysis_name[analysis_number] +"\""
	Execute commandstr

	// put up user cursors for changing //	
	commandstr = "Cursor A, "+wavestr+", analysis_cursor0["+num2str(analysis_number)+"]"
	Execute commandstr
	commandstr = "Cursor B, "+wavestr+", analysis_cursor1["+num2str(analysis_number)+"]"
	Execute commandstr
	
	NVAR current_analysis_number = current_analysis_number			// save the analysis number as global
	current_analysis_number = analysis_number
	
End


Function bACCEPTProc(dummy) : buttoncontrol				// user wants to accept cursor positions for new analysis window //
	string dummy
	
	NVAR current_analysis_number = current_analysis_number	
	Wave analysis_cursor0 = analysis_cursor0			
	Wave analysis_cursor1 = analysis_cursor1
	
	analysis_cursor0[current_analysis_number]=xcsr(A)
	analysis_cursor1[current_analysis_number]=xcsr(B)
	
	Cursor/K A
	Cursor/K B
	
	KillControl bACCEPT
	KillControl bREVERT
	
	// remove old cursor position and label //
	TextBox/K/N=label
	SetDrawLayer/K UserFront
	Draw_Analysis_Cursors(1)
	
End

Function bREVERTProc (dummy): buttoncontrol					// user wants to ignore cursors and leave analysis window intact
	string dummy
	
	Cursor/K A
	Cursor/K B
					
	KillControl bACCEPT
	KillControl bREVERT
	
	TextBox/K/N=label
	SetDrawLayer/K UserFront
	
End
	

// ---------------------------------------------------- Functions to average sweeps and display them -----------------------------------------------//

Function Select_Avg_Proc()
	
	Wave average_exists = average_exists
	SVAR RangeStr0 = RangeStr0					// this is not a text wave because I can't figure out how to
	SVAR RangeStr1 = RangeStr1					// pass one element of the text wave to the setvariable control
	SVAR RangeStr2 = RangeStr2					// ? maybe an IGOR bug ??
	SVAR RangeStr3 = RangeStr3
	SVAR RangeStr4 = RangeStr4
	SVAR RangeStr5 = RangeStr5
	SVAR RangeStr6 = RangeStr6
	SVAR RangeStr7 = RangeStr7
	SVAR RTitleStr0 = RTitleStr0
	SVAR RTitleStr1 = RTitleStr1
	SVAR RTitleStr2 = RTitleStr2
	SVAR RTitleStr3 = RTitleStr3
	SVAR RTitleStr4 = RTitleStr4
	SVAR RTitleStr5 = RTitleStr5
	SVAR RTitleStr6 = RTitleStr6
	SVAR RTitleStr7 = RTitleStr7
	
	NewPanel/W=(350,90,590,298) as "Make Average"
	DoWindow/C Make_Avg_Window
		
	Checkbox Avg0, pos={20,15}, size={30,15}, title = "0", value = average_exists[0], proc = Avg_checked
	Checkbox Avg1, pos={20,35}, size={30,15}, title = "1", value = average_exists[1], proc = Avg_checked
	Checkbox Avg2, pos={20,55}, size={30,15}, title = "2", value = average_exists[2], proc = Avg_checked
	Checkbox Avg3, pos={20,75}, size={30,15}, title = "3", value = average_exists[3], proc = Avg_checked
	Checkbox Avg4, pos={20,95}, size={30,15}, title = "4", value = average_exists[4], proc = Avg_checked
	Checkbox Avg5, pos={20,115}, size={30,15}, title = "5", value = average_exists[5], proc = Avg_checked
	Checkbox Avg6, pos={20,135}, size={30,15}, title = "6", value = average_exists[6], proc = Avg_checked
	Checkbox Avg7, pos={20,155}, size={30,15}, title = "7", value = average_exists[7], proc = Avg_checked
	
	if (average_exists[0])
		Setvariable Range0, pos ={55,14}, size = {80,10}, fsize = 9, value=RangeStr0, proc=SetRange, title=" "
		Setvariable RTitle0, pos = {145, 14}, size = {80,10}, fsize = 9, value = RTitleStr0, proc = SetRTitle, title = " "
	endif
	if (average_exists[1])
		Setvariable Range1, pos ={55,34}, size = {80,10}, fsize = 9, value=RangeStr1, proc=SetRange, title = " "
		Setvariable RTitle1, pos = {145, 34}, size = {80,10}, fsize = 9, value = RTitleStr1, proc = SetRTitle, title = " "
	endif
	if (average_exists[2])
		Setvariable Range2, pos ={55,54}, size = {80,10}, fsize = 9, value=RangeStr2, proc=SetRange, title = " "
		Setvariable RTitle2, pos = {145, 54}, size = {80,10}, fsize = 9, value = RTitleStr2, proc = SetRTitle, title = " "
	endif
	if (average_exists[3])
		Setvariable Range3, pos ={55,74}, size = {80,10}, fsize = 9, value=RangeStr3, proc=SetRange, title = " "
		Setvariable RTitle3, pos = {145, 74}, size = {80,10}, fsize = 9, value = RTitleStr3, proc = SetRTitle, title = " "
	endif
	if (average_exists[4])
		Setvariable Range4, pos ={55,94}, size = {80,10}, fsize = 9, value=RangeStr4, proc=SetRange, title = " "
		Setvariable RTitle4, pos = {145, 94}, size = {80,10}, fsize = 9, value = RTitleStr4, proc = SetRTitle, title = " "
	endif
	if (average_exists[5])
		Setvariable Range5, pos ={55,114}, size = {80,10}, fsize = 9, value=RangeStr5, proc=SetRange, title = " "
		Setvariable RTitle5, pos = {145, 114}, size = {80,10}, fsize = 9, value = RTitleStr5, proc = SetRTitle, title = " "
	endif
	if (average_exists[6])
		Setvariable Range6, pos ={55,134}, size = {80,10}, fsize = 9, value=RangeStr6, proc=SetRange, title = " "
		Setvariable RTitle6, pos = {145, 134}, size = {80,10}, fsize = 9, value = RTitleStr6, proc = SetRTitle, title = " "
	endif
	if (average_exists[7])
		Setvariable Range7, pos ={55,154}, size = {80,10}, fsize = 9, value=RangeStr7, proc=SetRange, title = " "
		Setvariable RTitle7, pos = {145, 154}, size = {80,10}, fsize = 9, value = RTitleStr7, proc = SetRTitle, title = " "
	endif

	Button bAvgOK, pos={15,180},size={60,20},title="OK", proc=bMake_Average_Proc
End

Function Avg_Checked(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if checked, 0 if not
	
	// This procedure is called whenever the user checks or unchecks a box to select an average.
	
	Variable average_number

	if (cmpstr(ctrlName,"Avg0") == 0)			// determine which checkbox was checked
		average_number = 0
	endif
	if (cmpstr(ctrlName,"Avg1") == 0)
		average_number = 1
	endif
	if (cmpstr(ctrlName,"Avg2") == 0)
		average_number = 2
	endif
	if (cmpstr(ctrlName,"Avg3") == 0)
		average_number = 3
	endif
	if (cmpstr(ctrlName,"Avg4") == 0)
		average_number = 4
	endif
	if (cmpstr(ctrlName,"Avg5") == 0)
		average_number = 5
	endif
	if (cmpstr(ctrlName,"Avg6") == 0)
		average_number = 6
	endif
	if (cmpstr(ctrlName,"Avg7") == 0)
		average_number = 7
	endif
	
	// update the average_exists variable 
	Wave average_exists = average_exists
	
	average_exists[average_number] = checked
	
	if (checked == 0) 									// if the user just unchecked the box, delete the average
		Delete_Average(average_number)
	endif
	
	// now redraw the Make_Avg_Window so that the range box will be added or deleted according to the checkbox.
	DoWindow/K Make_Avg_Window
	Select_Avg_Proc()
End

	
Function SetRange(ctrlName, varNum, varStr, varName)			// this is called whenever user sets a sweep range
	String ctrlName											// for creating an average.
	Variable varNum
	String varStr
	String varName
	
	Wave avgstart = avgstart
	Wave avgend = avgend
	Variable average_number
	
	// determine which average number was adjusted
	
	if (cmpstr(ctrlName,"Range0") == 0)
		average_number = 0
	endif
	if (cmpstr(ctrlName,"Range1") == 0)
		average_number = 1
	endif
	if (cmpstr(ctrlName,"Range2") == 0)
		average_number = 2
	endif
	if (cmpstr(ctrlName,"Range3") == 0)
		average_number = 3
	endif
	if (cmpstr(ctrlName,"Range4") == 0)
		average_number = 4
	endif
	if (cmpstr(ctrlName,"Range5") == 0)
		average_number = 5
	endif
	if (cmpstr(ctrlName,"Range6") == 0)
		average_number = 6
	endif
	if (cmpstr(ctrlName,"Range7") == 0)
		average_number = 7
	endif
	
	// parse the Range string to determine avgstart sweep and avgend sweep
	
	variable hyphen, posn
	string buildstr
		
	hyphen = strsearch(varStr,"-",0)
	if (hyphen == -1)
		DoAlert 0, "Improper sweep range.  Use format 'start-end'."
		Return 0
	endif

	posn = 0 				// extract start sweep number
	buildstr = ""
	do
		buildstr+=varStr[posn]
		posn += 1
	while (posn < hyphen)
	avgstart[average_number] = str2num(buildstr)
	
	posn = hyphen + 1			// extract end sweep number
	buildstr = ""
	do
		buildstr += varStr[posn]
		posn += 1
	while (posn < strlen(varStr))
	avgend[average_number] = str2num(buildstr)
	
	print "Avg #", average_number, "Start: ", avgstart[average_number], "  End: ", avgend[average_number]   	// TEST
	
End

Function SetRTitle(ctrlName, varNum, varStr, varName)			// this is called whenever user sets a title
	String ctrlName											// for an average.
	Variable varNum
	String varStr
	String varName
	
	Wave/T avgtitle = avgtitle
	Variable average_number
	
	// determine which average number was adjusted
	
	if (cmpstr(ctrlName,"RTitle0") == 0)
		average_number = 0
	endif
	if (cmpstr(ctrlName,"RTitle1") == 0)
		average_number = 1
	endif
	if (cmpstr(ctrlName,"RTitle2") == 0)
		average_number = 2
	endif
	if (cmpstr(ctrlName,"RTitle3") == 0)
		average_number = 3
	endif
	if (cmpstr(ctrlName,"RTitle4") == 0)
		average_number = 4
	endif
	if (cmpstr(ctrlName,"RTitle5") == 0)
		average_number = 5
	endif
	if (cmpstr(ctrlName,"RTitle6") == 0)
		average_number = 6
	endif
	if (cmpstr(ctrlName,"RTitle7") == 0)
		average_number = 7
	endif
	
	// copy the Range Title into the avgtitle wave
	
	avgtitle[average_number] = Varstr
	
	print "Avg #", average_number, "Title: ", avgtitle[average_number]   	// TEST
	
End

Function Delete_Avg_Proc()
	
	Select_Avg_Proc()
	// add an additional button, "Delete All"
	
	DoWindow/F Make_Avg_Window
	Button bDeleteAll, pos={85,180},size={70,20},title="Delete All", proc=Delete_All_Averages
End

Function Save_Avg_Proc()

	DoAlert 0,"Not yet implemented."

End

Function bMake_Average_Proc(dummy) : buttoncontrol				// Average limits have been set, user hit OK,
	string dummy												// so now make & display the averages.
	
	Wave avgstart = avgstart				// beginning sweep of average range
	Wave avgend = avgend				// last sweep of average range
	variable current_average_number
	string avgname, sourcename
	string cmdstr
	Variable i1
	Wave average_exists = average_exists				// list of existing averages
	Wave avgDCoffset = avgDCoffset
	Wave/T avgtitle = avgtitle
	NVAR max_averages = max_averages
	SVAR Expt = Expt
	NVAR gZERO = gZERO
	variable returnval
	
	DoWindow/K Make_Avg_Window
	
	current_average_number = 0
	do
		if (average_exists[current_average_number]==1)
			if (avgstart[current_average_number] > avgend[current_average_number])
				cmdstr = "Invalid sweep range for Average_"+num2str(current_average_number)
				DoAlert 0, cmdstr
				Return 0
			endif
	
			avgname = "Average_"+num2str(current_average_number)
	
			// Calculate sweep average
			i1 = avgstart[current_average_number]
			Find_Sweep(i1,Expt)
			Read_Sweep(Expt)
			Duplicate/O display_wave1, $avgname
	
			if (avgend[current_average_number] > avgstart[current_average_number])
				do
					i1 += 1
					returnval = Find_Next_Sweep(Expt)
					if (returnval > 0)
						Read_Sweep(Expt)
						cmdstr = avgname+" += display_wave1"
						Execute cmdstr
					endif
				while ( (i1 < avgend[current_average_number]) %& (returnval >0) )
			endif
	
			cmdstr = avgname + "/= "+num2str((avgend[current_average_number]-avgstart[current_average_number]+1))
			Execute cmdstr
	
			if (gZERO == 1)											// if DC zeroing is on, zero the average wave //
				cmdstr = "avgDCoffset["+num2str(current_average_number)+"]= mean("+avgname+",0,pnt2x("+avgname+",9))"
				Execute cmdstr
				cmdstr = avgname + "-=avgDCoffset["+num2str(current_average_number)+"]"
				Execute cmdstr
			endif
	
			// Delete old avg trace if currently displayed, and then display new trace with label.
			DoWindow/F Sweep_window
			RemoveFromGraph/Z $avgname
			AppendToGraph/B/L/C=(0,0,0) $avgname
			cmdstr ="Tag/F=0/P=1/X=10/Y=-10 "+avgname+", "+num2str(.02+(.004*current_average_number))+", "
			cmdstr += "\"" + avgtitle[current_average_number]+" "+num2str(avgstart[current_average_number])+"-"+num2str(avgend[current_average_number]) + "\""
			print cmdstr
			execute cmdstr
		
		endif  		// if average_exists
	
		current_average_number += 1
	while (current_average_number < max_averages)
End


Function Delete_Average(avg_number)
	Variable avg_number
	
	Wave average_exists = average_exists
	string cmdstr
	string avgwave
	wave avgDCoffset = avgDCoffset
	
	avgwave = "Average_"+num2str(avg_number)
	
	DoWindow/F Sweep_window
	RemoveFromGraph/Z $avgwave
	average_exists[avg_number] = 0
	avgDCoffset[avg_number] = 0
	KillWaves/Z $avgwave
	
End

Function Delete_All_Averages(dummy)
	string dummy

	Variable i1=0
	NVAR max_averages = max_averages
	
	DoWindow/K Make_Avg_Window
	do
		Delete_Average(i1)
		i1 += 1
	while (i1 <= max_averages)

End


//-------------------------------------------------------- Functions to Create Analysis Windows -----------------------------------------------------------//
	
Function Make_Analysis_Window(analysis_number) : Graph
	Variable analysis_number
	
	Wave/T analysis_name = analysis_name
	Wave path_mode = path_mode
	Wave/T analysis_type = analysis_type
	Wave analysis_path = analysis_path
	Wave analysis_y0 = analysis_y0
	Wave analysis_y1 = analysis_y1
	String windowname
	String cmdstr, cmdstr2, labelstr
	variable real_path
	variable topposition
	
	Windowname=UniqueName("Analysis_Window",6,analysis_number)			// 6 denotes a graph
	
	if (analysis_path[analysis_number] == 2)			// for any analyses derived from STEP window
		real_path = 0
	else
		real_path = analysis_path[analysis_number]
	endif
	if ((cmpstr(analysis_type[analysis_number],"IHOLD")==0) %| (cmpstr(analysis_type[analysis_number],"RSERIES")==0) %| (cmpstr(analysis_type[analysis_number],"RINPUT")==0) )

		topposition = 250+(15*analysis_number)
		labelstr = num2str(65+topposition)				// bottom yval 
		cmdstr2 = "ModifyGraph margin(bottom)=15"
	else
		topposition = 100+(15* analysis_number)
		labelstr = num2str(100+topposition)				// bottom yval
		cmdstr2 = "ModifyGraph margin(bottom)=25"
	endif
	cmdstr="Display/W=(4,"+num2str(topposition)+",354,"+labelstr+") analysis"+num2str(analysis_number)+" vs sweeptimes"				//** UNIQUE TO ANAL **//
	Execute cmdstr
	cmdstr = "DoWindow/C "+Windowname
	Execute cmdstr
	cmdstr = "SetAxis/E=0 left, "+num2str(analysis_y0[analysis_number])+", "+num2str(analysis_y1[analysis_number])
	Execute cmdstr
	
	SetAxis/E=0 bottom, 0, 30
	ModifyGraph mode[0]=3, marker[0]=16, rgb[0]=(0,0,0), msize[0]=1		// set display prop
	ModifyGraph zero=1, zeroThick=0.2
	ModifyGraph tick=2, btlen=2, lblMargin =1, fsize=8							// various things to conserve space
	Execute cmdstr2													// use appropriate bottom margin 
	ModifyGraph margin(top)=10, margin(right)=10						// more things to conserve space
	ModifyGraph margin(left)=30, tloffset(left) = 2							// ditto
	ModifyGraph grid(left)=1											// add y axis grid
	Label bottom "Time (min)"
	labelstr = yaxislabel(analysis_type[analysis_number],path_mode[real_path])					// figure out correct y axis label
	cmdstr="Label left \""+labelstr+"\""
	Execute cmdstr
	cmdstr="Textbox/F=0/A=LT \""+analysis_name[analysis_number]+"\""
	Execute cmdstr
	Textbox/C/N=text0/X=2.00/Y=-3.00
End
	
Function/S yaxislabel(analtype, analmode)
	string analtype
	variable analmode				// 0 = voltage, 1 = current
	
		
	if (cmpstr(analtype,"AMPL")==0)		// note:  modify for v-clamp/i-clamp expt mv/pA
		if (analmode == 0)
			return "mV"
		endif
		if (analmode == 1)
			return "pA"
		endif			
	endif
	if (cmpstr(analtype,"SUB")==0)			// ditto
		if (analmode == 0)
			return "mV"
		endif
		if (analmode == 1)
			return "pA"
		endif			
	endif
	if (cmpstr(analtype,"SLOPE")==0)
		if (analmode == 0)
			return "mV/msec"
		endif
		if (analmode == 1)
			return "pA/msec"
		endif				
	endif
	if (cmpstr(analtype,"RSERIES")==0)
		return "Mohm"			
	endif
	if (cmpstr(analtype,"RINPUT")==0)
		return "Mohm"			
	endif	
	if (cmpstr(analtype,"IHOLD")==0)	
		if (analmode == 0)
			return "mV"
		else
			return "pA"	
		endif		
	endif
	if (cmpstr(analtype,"TIMEOFAPPK")==0)
		return "AP latency (ms)"
	endif
	if (cmpstr(analtype,"FIELDPK")==0)
	  	return "mV"
	endif
	if (cmpstr(analtype,"TIMEOFNEGPK")==0)
		return ("sec")
	endif
	if (cmpstr(analtype,"LATENCY")==0)
		return ("sec")
	endif
	if (cmpstr(analtype,"EPSPPK")==0)	
		if (analmode == 0)
			return "mV"
		else
			return "pA"	
		endif		
	endif
End

Function SetUpAnalysisWindows()			// set up windows for each active analysis
	Wave analysis_display = analysis_display
	NVAR number_of_analyses = number_of_analyses
	
	variable i1
	
	i1 = 0
	do
		if (analysis_display[i1]>=1)					// note:  no access window, just analysis windows
			Make_Analysis_Window(i1)
		endif
		i1 += 1
	while (i1 < number_of_analyses)
End

		
Function Bring_Analysis_To_Front(analnumber)
	variable analnumber
	
	Wave analysis_display = analysis_display
	
	string cmdstr

	if (analysis_display[analnumber]==1)	
		cmdstr = "DoWindow/F analysis_window"+num2str(analnumber)
		execute cmdstr
	endif

End

Function Adjust_Time_Axis()				// This allows user to set the time range for all analysis windows
										// at once, so it doesn't have to be done by hand for each window.
	
	NewPanel/W=(510,90,640,243) as "Analysis Time Axis"
	DoWindow/C Time_Window
	
	DrawText 16,21,"Time axis bounds"	
	SetVariable setvar_left size={85,20}, noproc, pos={20,30}, title="Left", value=left_value, fsize =10
	SetVariable setvar_right size={85,20}, noproc, pos={20,60}, title="Right", value=right_value, fsize =10
	Button bCalc_Time, pos = {20,90}, size ={88,20}, proc=bCalc_Time_Axis, title = "Set Full Scale"
	Button bOK_TIME, pos={35,120},size={60,20},proc=bSet_Time_Axis,title="OK"
	
End

Function bCalc_Time_Axis(dummy)		// This procedure calculates left and right values of time axis to equal full scale for the anal. sweep range.
	string dummy
	
	Wave sweeptimes = sweeptimes
	NVAR firstanalsweep = firstanalsweep
	NVAR lastanalsweep = lastanalsweep
	NVAR left_value = left_value
	NVAR right_value = right_value
	
	// calculate time in minutes associated with first and last analysis sweep.
	left_value = floor(sweeptimes[0])
	right_value = floor(sweeptimes[lastanalsweep-firstanalsweep]+1)
	
	// now hit OK button so user doesn't have to.
	bSet_Time_Axis("")
	
End

Function bSet_Time_Axis(dummy)			// This procedure called when user hits OK button on Time_Window
	string dummy
	
	String cmdstr1, cmdstr2
	Wave analysis_on = analysis_on
	Wave analysis_display = analysis_display
	NVAR number_of_analyses = number_of_analyses
	NVAR right_value = right_value
	NVAR left_value = left_value
	
	variable i1=0
	
	DoWindow/K Time_Window

	cmdstr1 = "SetAxis/E=0 bottom, "+num2str(left_value)+", "+num2str(right_value)
	
	do
		if ((analysis_on[i1]==1) %& (analysis_display[i1]>=1))
			cmdstr2="DoWindow/F analysis_window"+num2str(i1)
			execute cmdstr2
			execute cmdstr1
		endif
		i1 += 1
	while (i1 < number_of_analyses)
									
End

Function Make_Stim_Protocol_Graph()
	// This function takes displays average_0, average_1, and average_2, and displays them in a 
	// stereotyped format.  It is useful for summarizing the stimulus protocol (baseline, pairing, test)
	// used in a particular experiment.  The resulting window is named "Stim_Protocol_Window"
	
	if (WinType("Stim_Protocol_Window")==0)
		// graph doesn't exist
		Execute "duplicate/o average_0 bline"
		Execute "bline += 60"
		Execute "duplicate/o average_1 pairing"
		Execute "duplicate/o average_2 post"
		Execute "post -= 60"
		Display/W=(3,100,170,300) bline, pairing, post
		DoWindow/C Stim_Protocol_Window
		ModifyGraph fSize=7
		ModifyGraph tick=2, btlen=2, lblMargin =1, fsize=8																			
		ModifyGraph margin(top)=10, margin(right)=10						
		ModifyGraph margin(left)=20, tloffset(left) = 2	
		SetAxis/E=0 bottom, 0, 0.6
		SetAxis/E=0 left -80,160
		ModifyGraph rgb=(0,0,0)
		Textbox/N=text0/F=0/A=MT "\\Z08 Stimulation Protocol"
		Textbox/N=text1/F=0/A=MC "\\Z07 Baseline"
		Textbox/N=text2/F=0/A=RC "\\Z07 Pairing"
		Textbox/N=text3/F=0/A=MB "\\Z07 Post"
	else
		Execute "bline = average_0 + 60"
		Execute "pairing = average_1"
		Execute "post = average_2 - 60"
	endif
	
End

//----------------------------------------------- Routines to Place Marks on Analysis Windows --------------------------------------//


Function Make_Mark()
	// This is a first-pass attempt.
	
	Wave Mark_exists = mark_exists				// 0/1 denoting if a mark exists already
	Wave MarkSweep = MarkSweep				// sweep numbers associated with the marks
	NVAR Mark0Sweep = Mark0Sweep
	NVAR Mark1Sweep = Mark1Sweep
	NVAR Mark2Sweep = Mark2Sweep
	NVAR Mark3Sweep = Mark3Sweep
	NVAR Mark4Sweep = Mark4Sweep
	
	NewPanel/W=(510,90,680,238) as "Marks"
	DoWindow/C Mark_Window
	
	Checkbox Mark0, pos={20,15}, size={30,15}, title = "0", value = mark_exists[0], proc = Mark_checked
	Checkbox Mark1, pos={20,35}, size={30,15}, title = "1", value = mark_exists[1], proc = Mark_checked
	Checkbox Mark2, pos={20,55}, size={30,15}, title = "2", value = mark_exists[2], proc = Mark_checked
	Checkbox Mark3, pos={20,75}, size={30,15}, title = "3", value = mark_exists[3], proc = Mark_checked
	Checkbox Mark4, pos={20,95}, size={30,15}, title = "4", value = mark_exists[4], proc = Mark_checked
	
	Mark0Sweep = MarkSweep[0]				// again, setvar won't accept object that is subscripted, so I am
	Mark1Sweep = MarkSweep[1]				// forced to use a kludge.
	Mark2Sweep = MarkSweep[2]
	Mark3Sweep = MarkSweep[3]
	Mark4Sweep = MarkSweep[4]
	
	if (mark_exists[0])
		Setvariable MarkSweep0, pos ={55,14}, size = {80,10}, fsize = 9, value=Mark0Sweep, proc=SetMarkSweep, title=" "
	endif
	if (mark_exists[1])
		Setvariable MarkSweep1, pos ={55,34}, size = {80,10}, fsize = 9, value=Mark1Sweep, proc=SetMarkSweep, title=" "
	endif
	if (mark_exists[2])
		Setvariable MarkSweep2, pos ={55,54}, size = {80,10}, fsize = 9, value=Mark2Sweep, proc=SetMarkSweep, title = " "
	endif
	if (mark_exists[3])
		Setvariable MarkSweep3, pos ={55,74}, size = {80,10}, fsize = 9, value=Mark3Sweep, proc=SetMarkSweep, title = " "
	endif
	if (mark_exists[4])
		Setvariable MarkSweep4, pos ={55,94}, size = {80,10}, fsize = 9, value=Mark4Sweep, proc=SetMarkSweep, title = " "
	endif

	Button bMarkOK, pos={15,120},size={60,20},title="OK", proc=bMarkOKProc
End

Function Mark_Checked(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if checked, 0 if not
	
	// This procedure is called whenever the user checks or unchecks a box to select a mark.
	
	Variable mark_number

	if (cmpstr(ctrlName,"Mark0") == 0)			// determine which checkbox was checked
		mark_number = 0
	endif
	if (cmpstr(ctrlName,"Mark1") == 0)
		mark_number = 1
	endif
	if (cmpstr(ctrlName,"Mark2") == 0)
		mark_number = 2
	endif
	if (cmpstr(ctrlName,"Mark3") == 0)
		mark_number = 3
	endif
	if (cmpstr(ctrlName,"Mark4") == 0)
		mark_number = 4
	endif
	
	// update the average_exists variable 
	Wave mark_exists = mark_exists
	
	mark_exists[mark_number] = checked
	
	Redraw_All_Marks()
	
	// now redraw the Make_Avg_Window so that the range box will be added or deleted according to the checkbox.
	DoWindow/K Mark_Window
	Make_Mark()
	
End		// mark_checked()

Function SetMarkSweep(ctrlName, varNum, varStr, varName)			// this is called whenever user sets a sweep number
	String ctrlName												// for a mark
	Variable varNum
	String varStr
	String varName									// in future, allow alternative entry of either times or sweep numbers
	
	Variable mark_number
	Wave MarkSweep = MarkSweep
	
	// determine which average number was adjusted
	
	if (cmpstr(ctrlName,"MarkSweep0") == 0)
		mark_number = 0
	endif
	if (cmpstr(ctrlName,"MarkSweep1") == 0)
		mark_number = 1
	endif
	if (cmpstr(ctrlName,"MarkSweep2") == 0)
		mark_number = 2
	endif
	if (cmpstr(ctrlName,"MarkSweep3") == 0)
		mark_number = 3
	endif
	if (cmpstr(ctrlName,"MarkSweep4") == 0)
		mark_number = 4
	endif
	
	MarkSweep[mark_number] = varNum				// set the result into the correct wave
	
	print "Mark #", mark_number, " Sweep ", MarkSweep[mark_number]
		
	// Draw or redraw the mark at this sweep number on all current analysis windows.  In the future, allow user
	// to have set a toggle saying whether this should be done in all analysis windows
	// or in a particular window.
	
	Redraw_All_Marks()
	
End

Function Redraw_All_Marks()

	Wave analysis_on = analysis_on
	Wave analysis_display = analysis_display
	Wave sweeptimes = sweeptimes
	Wave MarkSweep = MarkSweep
	NVAR firstanalsweep = firstanalsweep
	Wave mark_exists = mark_exists
	NVAR number_of_analyses = number_of_analyses
	
	Variable w1, mark
	
	// erase and redraw all marks
	
		w1 = 0
		do
		if ((analysis_on[w1]==1) %& (analysis_display[w1]==1))
			Bring_Analysis_To_Front(w1)
			SetDrawLayer/K ProgFront				// erase old marks
			SetDrawLayer ProgFront	
	
			mark = 0							// draw in each mark that exists
			do
				if (mark_exists[mark]==1)
					SetDrawEnv xcoord = bottom, ycoord = prel
					DrawLine sweeptimes[MarkSweep[mark]-firstanalsweep], 1, sweeptimes[MarkSweep[mark]-firstanalsweep], 0
				endif
				mark += 1
			while (mark < 5)
		endif
		w1 += 1
		while (w1 < number_of_analyses)
	
End

Function bMarkOKProc(dummy)
	string dummy
	
	// This procedure called when user is done creating/modifying marks
	
	DoWindow/K Mark_Window
	
End

Function Edit_Mark()

	Make_Mark()					// This should accomplish the same purpose.
End

Function Delete_Marks()				// called from Menu

	Make_Mark()
	// add an additional button, "Delete All"
	
	DoWindow/F Mark_Window
	Button bDeleteAll, pos={85,120},size={70,20},title="Delete All", proc=Delete_All_Marks
End

Function Delete_All_Marks(dummy)
	string dummy
	
	Delete_Mark(-1)
	DoWindow/K Mark_Window
	Make_Mark()
	
End

	
Function Delete_Mark(number)
	variable number								// delete the specified mark.  If mark_number = -1, delete them all.

	Wave mark_exists = mark_exists
	Variable i1
	
	if (number > -1)
		mark_exists[number] = 0
	else
		i1 = 0
		do
			mark_exists[i1]=0
			i1 += 1
		while (i1 < 5)
	endif
	
	Redraw_All_Marks()
	
End


//----------------------------------------------------------- Data Analysis Routines -------------------------------------------------------------//


Function Run_Analysis()

	// Get rid of any old analyses
	Reset_Analyses()
	
	// Prompt user for beginning and end sweeps
	NewPanel/W=(300,125,455,250) as "Sweep Range"
	DoWindow/C Sweep_Range_Window
	
	// Allow user to change the sweep range //
	SetVariable setvarFirst title="First sweep", pos={20,10}, size={110,30}, limits={0,1000,1}, fsize=9, value=firstanalsweep, noproc
	SetVariable setvarLast title="Last sweep", pos={20,45}, size={110,30}, limits={0,1000,1}, fsize=9, value=lastanalsweep, noproc
	Button bRunAnalysisOK pos={10,80}, size = {60,30}, title = "OK", fsize = 10, proc = bRunAnalysisOKProc
	Button bCANCEL5 pos={80, 80}, size = {60,30}, title= "CANCEL", fsize = 10, proc=bCANCEL5Proc
	
End

Function Reset_Analyses()
	NVAR sweepnumber = sweepnumber
	NVAR number_of_analyses = number_of_analyses
	string cmdstr
	variable i1=0
	
	do
		cmdstr="Redimension/N=0 analysis"+num2str(i1)
		execute cmdstr
		i1 += 1
	while (i1 < number_of_analyses)

	sweepnumber = 0
	
End

Function bRunAnalysisOKProc(dummy)
	string dummy
	
	NVAR firstanalsweep = firstanalsweep
	NVAR lastanalsweep = lastanalsweep
	Variable i1
	SVAR Expt = Expt
	NVAR sweepnumber = sweepnumber
	NVAR disk_sweep_time = disk_sweep_time
	
	// Erase sweep range window
	DoWindow/K Sweep_Range_Window
	
	if (firstanalsweep > lastanalsweep)
		DoAlert 0, "Invalid sweep range."
		Return 0
	endif
	
	// Read through the sweeps, calling analysis_master with each one
	
	sweepnumber = 0
	
	i1 = firstanalsweep
	Find_Sweep(i1,Expt)
	Read_Sweep(Expt)
	
	Analysis_Master()
	
	sweepnumber += 1
	
	if (lastanalsweep > firstanalsweep)
		do
			i1 += 1
			Find_Next_Sweep(Expt)
			Read_Sweep(Expt)
			Analysis_Master()
			sweepnumber += 1
		while (i1 < lastanalsweep)
	endif
	
	// set time axis on analysis graphs to full scale
	bCalc_Time_Axis("")
	
End

Function bCANCEL5Proc(dummy) : buttoncontrol				// user wants to cancel average changes
	string dummy

	// Erase avg_window
	DoWindow/K Sweep_Range_Window
	
End


Function Analysis_Master()			// This function should be called after reading a sweep, to perform all required analyses
						 			// on that sweep and update the analysis windows.
	
	Wave analysis_on = analysis_on
	Variable a1=0
	NVAR number_of_analyses=number_of_analyses

	// call the appropriate analysis routines.  Do this more intelligently in the future //
	do
		if (analysis_on[a1] == 1)
			Perform_Analysis(a1)
		endif
		a1 += 1
	while (a1 < number_of_analyses)
	
End

Function Perform_Analysis (analysisnumber)			
	Variable analysisnumber
	NVAR sweepnumber = sweepnumber
	Wave sweeptimes = sweeptimes
	Wave display_wave1 = display_wave1
	Wave/T analysis_type = analysis_type
	SVAR Expt = Expt
	Wave analysis_cursor0 = analysis_cursor0
	Wave analysis_cursor1 = analysis_cursor1
	NVAR Stepsize = stepsize					
	NVAR disk_sweep_time = disk_sweep_time
		
	string cmdstr
	variable min1, max1, sample, endpt, minposn, maxposn, maxrange, minrange
	variable cpnt, direction, finished					// for latency calc.
	
	Insertpoints (sweepnumber +1), 1, sweeptimes
	sweeptimes[sweepnumber] = (disk_sweep_time)/60			// cast into absolute experiment minutes

	string sourcewave = "display_wave1"			// UNIQUE FOR ANAL -- ONLY PATH0, NO PATH1
	string resultswave = "analysis"+num2str(analysisnumber)
	
	// ABSOLUTE AMPLITUDE OR HOLDING CURRENT (same calculation)
	if ((cmpstr(analysis_type[analysisnumber],"AMPL") == 0)	%| (cmpstr(analysis_type[analysisnumber],"IHOLD")==0) )			
		NVAR DCoffset = DCoffset
		NVAR gZERO=gZERO
		InsertPoints (sweepnumber + 1), 1, $resultswave
		cmdstr=resultswave+"["+num2str(sweepnumber)+"]=mean("+sourcewave+",analysis_cursor0["+num2str(analysisnumber)+"], analysis_cursor1["+num2str(analysisnumber)+"])"
		if (gZERO==1)
			cmdstr+="+ DCoffset"
		endif
			Execute cmdstr
		// Save $resultswave if desired
	endif


	//  INPUT RESISTANCE  Compute as net amplitude of late window re msec 0-2 of trace.  Calculate for step size used.
	// again, assume path 0!!!!   Special note:  For voltage clamp experiments, Rin=Vcommand/(Iwindow-Ihold).  
	//  For current clamp experiments, Rin=1 / (Vwindow-Vhold) / Icommand
	
	if (cmpstr(analysis_type[analysisnumber],"RINPUT") == 0)		 		
		Wave path_mode = path_mode			// voltage or current clamp
		variable temp1, temp2
			
		InsertPoints (sweepnumber+ 1), 1, $resultswave
		
		temp1 = mean(display_wave1,analysis_cursor0[analysisnumber], analysis_cursor1[analysisnumber])
		temp2 = mean(display_wave1,0,.002)		// ie, the baseline I or V
		temp1 -= temp2							// subtract off baseline
		if (path_mode[0]==0)		// this is a current clamp recording
			cmdstr=resultswave+"["+num2str(sweepnumber)+"] = 1000 * "+num2str(temp1) +"/"+ num2str(Stepsize)
		else						// this is a voltage clamp recording
			cmdstr=resultswave+"["+num2str(sweepnumber)+"] = 1000 * "+num2str(Stepsize)+"/"+num2str(temp1)
		endif
		execute cmdstr
		// Save if desired
	endif
	
	// PK to PK amplitude or RSERIES (similar calculations)
	if ((cmpstr(analysis_type[analysisnumber],"PKTOPK") == 0)	%| (cmpstr(analysis_type[analysisnumber],"RSERIES") == 0)	)
		
		Duplicate $sourcewave, tempwave
		Sample = x2pnt(tempwave,analysis_cursor0[analysisnumber])
		min1 = tempwave[sample]
		max1 = min1
		endpt = x2pnt(tempwave, analysis_cursor1[analysisnumber])
		Do
			if (tempwave[sample] < min1)
				min1 = tempwave[sample]
			endif
			if (tempwave[sample] > max1)
				max1 = tempwave[sample]
			endif
			sample += 1
		while (sample <= endpt)

		InsertPoints (sweepnumber + 1), 1, $resultswave
		if (cmpstr(analysis_type[analysisnumber],"PKTOPK")==0)				// for peak to peak 
			cmdstr=resultswave+"["+num2str(sweepnumber)+"]="+num2str((min1-max1))
		else																// for Rseries calc based on stepsize
			cmdstr = resultswave+"["+num2str(sweepnumber)+"] = abs("+num2str(Stepsize)+") / ("+num2str(max1)+"-"+num2str(min1)+") * 1000"
		endif
		Execute cmdstr
		
		Killwaves tempwave
		
		// Save $resultswave if desired
	endif
	
	// SUBTRACT TWO CHANNELS //
	if (cmpstr(analysis_type[analysisnumber],"SUB") == 0)		// subtract two analyses.  NOTE these anals MUST BE
															// LOWER in the analysis list!!!!
		// the convention is, result = ANAL0 - ANAL1, where
		// ANAL0 = analysisnumber in analysis_cursor0 entry
		// ANAL1 = analysisnumber in analysis_cursor1 entry
	
		InsertPoints (sweepnumber+1), 1, $resultswave
		cmdstr=resultswave+"["+num2str(sweepnumber)+"]=analysis"+num2str(analysis_cursor0[analysisnumber])+"["+num2str(sweepnumber)+"] - analysis"+num2str(analysis_cursor1[analysisnumber])+"["+num2str(sweepnumber)+"]"
		execute cmdstr
	
	endif
	
	// SLOPE //
	if (cmpstr(analysis_type[analysisnumber],"SLOPE") == 0)		
		
		InsertPoints (sweepnumber+1), 1, $resultswave
		// do the calc here.
		cmdstr = "Curvefit/Q line, "+sourcewave+"("+num2str(analysis_cursor0[analysisnumber])+","+num2str(analysis_cursor1[analysisnumber])+")"
		execute cmdstr
		cmdstr = resultswave+"["+num2str(sweepnumber)+"] = W_Coef[1]/1000"			// convert sec to msec
		execute cmdstr
	endif
	
	// TIME OF ACTION POTENTIAL PEAK //
	// This routine calculates the time of occurrance of the peak of the AP, within the analysis window specified.
	// The returned value is ms from the start of the sweep.
	// Note that the max voltage value is detected without checking that it was actually an AP!!!!!  (could solve this with
	// a user-supplied minimum threshold for AP detection in a future version).
	
	if (cmpstr(analysis_type[analysisnumber],"TIMEOFAPPK")==0)
		InsertPoints (sweepnumber+1), 1, $resultswave
		WaveStats/Q/R=(analysis_cursor0[analysisnumber],analysis_cursor1[analysisnumber]) $sourcewave	// find max between the cursors
		cmdstr = resultswave+"["+num2str(sweepnumber)+"] = "+num2str(V_maxloc)+" * 1000"							// location of ymax --convert to msec
		execute cmdstr
	endif
	
	// FIELD POTENTIAL PEAK //
	//  This routine calculates maximal (negative) field amplitude, within the analysis window specified.  It can be used 
	//  when peak latency may shift slightly--a condition in which a fixed amplitude window would confound latency and amplitude.
	//  The mean value of 5 consecutive sample points centered on the maximal amplitude is returned.
	//  Note that this routine does not subtract baseline amplitude;  therefore it assumes fields are recorded AC coupled.
	
	if (cmpstr(analysis_type[analysisnumber],"FIELDPK")==0)
		InsertPoints (sweepnumber+1), 1, $resultswave
		WaveStats/Q/R=(analysis_cursor0[analysisnumber],analysis_cursor1[analysisnumber]) $sourcewave	// find min between the cursors
		minposn = x2pnt($sourcewave,V_minloc)
		WaveStats/Q/R=[minposn-2,minposn+2] $sourcewave							// Calculate mean of 5 pts around minimum
		cmdstr = resultswave+"["+num2str(sweepnumber)+"] = "+num2str(V_avg)							
		execute cmdstr
	endif
	
	// PEAK OF A POSITIVE-GOING EPSP //
	//  This routine calculates maximal (positive) potential amplitude occurring anywhere within the defined analysis window.
	
	if (cmpstr(analysis_type[analysisnumber],"EPSPPK")==0)
		InsertPoints (sweepnumber +1), 1, $resultswave
		WaveStats/Q/R=(analysis_cursor0[analysisnumber],analysis_cursor1[analysisnumber]) $sourcewave	// find max between the cursors
		maxposn = x2pnt($sourcewave,V_maxloc)
		WaveStats/Q/R=[maxposn-2,maxposn+2] $sourcewave							// Calculate mean of 5 pts around minimum
		cmdstr = resultswave+"["+num2str(sweepnumber)+"] = "+num2str(V_avg)
		execute cmdstr
	endif
	
	// TIME OF NEGATIVE-GOING FIELD PK
	//  This routine calculates time of field peak within the defined analysis window
	if (cmpstr(analysis_type[analysisnumber],"TIMEOFNEGPK")==0)
		InsertPoints (sweepnumber +1), 1, $resultswave
		WaveStats/Q/R=(analysis_cursor0[analysisnumber],analysis_cursor1[analysisnumber]) $sourcewave	// find min between the cursors
		cmdstr = resultswave+"["+num2str(sweepnumber)+"] = "+num2str(V_minloc)
		execute cmdstr
	endif
	
	// LATENCY
	// This routine calculates latency of either a positive-going or a negative-going waveform.  ** The analysis window must be
	// broad, so that there is at least 4 ms of baseline within the window, before the suspected latency.
	//  The routine will calculate mean +/- s.d. of "noise" within the first 2 ms of the window.  it will then report the time (x-position)
	//  of the first of two consecutive points that are greater than (mean+ 2 * s.d) or are less than (mean - 2*s.d.)
	if (cmpstr(analysis_type[analysisnumber],"LATENCY")==0)
		InsertPoints (sweepnumber +1), 1, $resultswave
		WaveStats/Q/R=(analysis_cursor0[analysisnumber],analysis_cursor0[analysisnumber]+.002) $sourcewave	// find stats of bline epoch
		maxrange = V_avg + 2* V_sdev
		minrange = V_avg - 2* V_sdev
		cpnt = x2pnt($sourcewave, analysis_cursor0[analysisnumber])
		direction = 0
		finished = 0
			do
				if (display_wave1[cpnt] > maxrange)
					if (direction == 1)
						finished = 1
					else
						direction = 1				// this potential is positive-going
					endif
				endif
				if (display_wave1[cpnt] < minrange)
					if (direction == -1)
						finished = 1
					else
						direction = -1				// this potential is negative-going
					endif
				endif
				if ((display_wave1[cpnt] >= minrange) %& (display_wave1[cpnt] <= maxrange))
					direction = 0
				endif
				print "cpnt = ", cpnt, "val: ", display_wave1[cpnt], "maxrange = ", maxrange, "minrange = ", minrange, "direction = ", direction
				cpnt += 1
			while ((finished == 0) %| (cpnt < analysis_cursor1[analysisnumber]))
			print "exited loop.  finished = ", finished, "direction = ", direction, " cpnt = ", cpnt 
		if (finished == 0)
			cmdstr = resultswave+"["+num2str(sweepnumber)+"] = 0.0"			// Use 0.0 to signal no latency detected.
		 	execute cmdstr
		else
			cmdstr = resultswave+"["+num2str(sweepnumber)+"] = "+num2str(pnt2x($sourcewave, cpnt-2))			// Use 0.0 to signal no latency detected.
		 	execute cmdstr
		 	print "latency = ", pnt2x($sourcewave, cpnt-2)
		 endif
	endif
	// save sweeptimes if desired
	// Save/o/p=savepath sweeptimes as Expt+"times.ibw"
	
End

Function Write_Analysis_Results()			// UNDER CONSTRUCTION

	// Set up dialog box
	NewPanel/W=(300,125,555,350) as "Write Analysis Results"
	DoWindow/C Write_Results_Window
	
	SetVariable setvarSavePath title="Save Path", pos={20,10}, size={200,25}, fsize=9, value=SavePathStr, noproc
	SetVariable setvarFile title="File name", pos={20,30}, size={200,25}, fsize=9, value=FileNameStr, noproc
	SetVariable setvarFirst title="First sweep", pos={20,45}, size={110,25}, limits={0,1000,1}, fsize=9, value=firstanalsweep, noproc
	SetVariable setvarLast title="Last sweep", pos={20,80}, size={110,25}, limits={0,1000,1}, fsize=9, value=lastanalsweep, noproc
	Button bWriteAnalysisOK pos={20,120}, size = {50,40}, title = "OK", fsize = 10, proc = bWriteAnalysisOKProc
	Button bCANCEL6 pos={80,120}, size = {50,40}, title= "CANCEL", fsize = 10, proc=bCANCEL6Proc

	// controls in here to allow user to select analyses to save.
	
	// on ok, write the data to disk file in ascii format
	
End

//-----------------------------------------------------  Crunch Routines  ----------------------------------------------------------//
Function Make_Crunch_Dialog()

	NVAR crunch_type = crunch_type				// 0 = slope;  1 = netamp;  2= absamp
	NVAR crunch_no_files = crunch_no_files
	SVAR crunchfilenamestr = crunchfilenamestr
	NVAR crunch_normalize = crunch_normalize
	
	NewPanel/W=(200,125,500,295) as "Crunch Multiple Experiments"
	DoWindow/C Crunch_Dialog
		
	DrawText 90,30, "Default folder: D:\DATA\CRUNCH"
	Button bLoadCrunch pos={10,10}, size={50,25}, fsize=10, title="Load..", proc=bLoadSaveCrunchProc
	Button bSaveCrunch pos={10,40}, size={50,25}, fsize=10, title="Save..", proc=bLoadSaveCrunchProc
	Button bNewCrunch pos={70,40}, size={50,25}, fsize=10, title="New", proc=bNewCrunchProc
	Button bRunCrunch pos={150,135}, size={60,25}, fsize=10, title="Run Crunch", proc=bRunCrunchProc
	Button bCloseCrunch pos={220,135}, size={60,25}, fsize=10, title="Exit", proc=bCloseCrunchProc
	Button bAddCell pos={10,135}, size={60,25}, fsize=10, title="Add Cell", proc=bAddCellProc
	Button bCleanUpCrunch pos={80, 135}, size={60,25}, fsize=10, title="CleanUp", proc=bCleanUpCrunchProc
	
	Make_Crunch_Checkboxes()
	
	// in here count up number of cells in loaded crunch file and display prominently somewhere
	
End

Function Make_Crunch_Checkboxes()
	NVAR crunch_type = crunch_type
	NVAR crunch_normalize = crunch_normalize
	
	Checkbox slopebox, pos={50,75}, size={70,25}, title="Slope", value=(crunch_type == 0),proc=Crunchmarkchecked
	Checkbox netbox, pos={120, 75}, size={70,25}, title="Net Ampl.", value=(crunch_type == 1), proc=Crunchmarkchecked
	Checkbox absbox, pos={190,75},size={70,25},  title="Abs Ampl.", value=(crunch_type == 2), proc=Crunchmarkchecked
	Checkbox normalizebox, pos={20,105},size={150,25}, title="Normalize to Baseline", value=crunch_normalize,proc=Crunchmarkchecked
End


Function bNewCrunchProc(dummy)				// this routine sets up a new crunch
	string dummy
	
	NVAR crunch_no_files=crunch_no_files 
	Wave/T crunch_file=crunch_file
	Wave crunch_sweep0=crunch_sweep0			// sweep range start for crunch
	Wave crunch_sweep1=crunch_sweep1			// sweep range end for crunch
	Wave crunch_bline0=crunch_bline0				// sweep range start for baseline normalization
	Wave crunch_bline1=crunch_bline1				// sweep range end for baseline normalization
	Wave crunch_anal0=crunch_anal0				// sample number start for analysis window
	Wave crunch_anal1=crunch_anal1				// sample number end for analysis window
	Wave crunch_align=crunch_align				// sweep number to align sweeps between cells
	Wave crunch_binsize = crunch_binsize			// number of sweeps per crunch bin
	Wave crunch_included=crunch_included			// on-off 1-0 for including a cell in the crunch.  Not saved to disk.

	
	// Redimension all crunch variables to N=1 so user can enter first experiment.
	crunch_no_files = 1
	Redimension/N=1 crunch_file; crunch_file = ""
	Redimension/N=1 crunch_sweep0; crunch_sweep0 = 0
	Redimension/N=1 crunch_sweep1; crunch_sweep1 = 0
	Redimension/N=1 crunch_bline0; crunch_bline0 = 0
	Redimension/N=1 crunch_bline1; crunch_bline1 = 0
	Redimension/N=1 crunch_anal0; crunch_anal0 = 0
	Redimension/N=1 crunch_anal1; crunch_anal1 = 0
	Redimension/N=1 crunch_align; crunch_align = 0
	Redimension/N=1 crunch_binsize; crunch_binsize=10
	Redimension/N=1 crunch_included; crunch_included = 1
	
	// Put up a new Edit table so user can enter data
	if (WinType("Crunch_Table")==0)		// if Table does not already exist, create it
		Edit/W=(5,250, 500, 400) crunch_included, crunch_file, crunch_sweep0, crunch_sweep1, crunch_bline0, crunch_bline1, crunch_anal0, crunch_anal1, crunch_align, crunch_binsize as "Crunch Parameters"
		DoWindow/C Crunch_Table
		Execute "Arrange_Crunch_Table()"
	endif
End
	
Function bLoadSaveCrunchProc(ctrlname)			// this routine does both reading and writing of crunch files
	string ctrlname
	
	SVAR CrunchFilePath = CrunchFilePath		// from #include "CollectFileDefaults"
	SVAR CrunchFileNameStr = CrunchFileNameStr
	NVAR crunch_no_files=crunch_no_files
	
	Wave/T crunch_file=crunch_file
	Wave crunch_sweep0=crunch_sweep0			// sweep range start for crunch
	Wave crunch_sweep1=crunch_sweep1			// sweep range end for crunch
	Wave crunch_bline0=crunch_bline0				// sweep range start for baseline normalization
	Wave crunch_bline1=crunch_bline1				// sweep range end for baseline normalization
	Wave crunch_anal0=crunch_anal0				// sample number start for analysis window
	Wave crunch_anal1=crunch_anal1				// sample number end for analysis window
	Wave crunch_align=crunch_align				// sweep number to align sweeps between cells
	Wave crunch_binsize = crunch_binsize			// number of sweeps in each crunch time bin
	Wave crunch_included=crunch_included			// on-off 1-0 for including a cell in the crunch.  Not saved to disk.
	string cmdstr
	
	if (cmpstr(ctrlname, "bLoadCrunch")==0) 
		// Load in file of name CrunchFileNameStr and fill relavent variables.  Display in edit table.  Redimension waves properly (initial length 0)
		// Declare temporary input waves
		
		Make/T/N=25 inp0
		Make/N=25 inp1
		Make/N=25 inp2
		Make/N=25 inp3
		Make/N=25 inp4
		Make/N=25 inp5
		Make/N=25 inp6
		Make/N=25 inp7
		Make/N=25 inp8
		
		cmdstr = "NewPath/O/Q crunch \"" + CrunchFilePath + "\""		// Default file location specified in CollectFileDefaults.ipf
		Execute cmdstr
		Print "Preparing to load crunch file data."
		LoadWave/J/P=crunch/K=0/N=inp
		Print "Loading complete."
		
		// determine number of files
		crunch_no_files = 0;  variable end_detected = 0
		
		do
			if (cmpstr(inp0[crunch_no_files],"end")==0)
				end_detected = 1
			endif
			if (crunch_no_files > 25)
				end_detected = 1
				DoAlert 0, "There may have been a problem loading the crunch parameter file."
			endif
			crunch_no_files += 1
		while (!end_detected)
		
		crunch_no_files -= 1
		
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_file"
		Execute cmdstr
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_sweep0"
		Execute cmdstr
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_sweep1"
		Execute cmdstr
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_bline0"
		Execute cmdstr
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_bline1"
		Execute cmdstr
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_anal0"
		Execute cmdstr
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_anal1"
		Execute cmdstr
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_align"
		Execute cmdstr
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_binsize"
		Execute cmdstr
		
		crunch_file = inp0;  crunch_sweep0=inp1;  crunch_sweep1=inp2; crunch_bline0=inp3; crunch_bline1=inp4
		crunch_anal0 = inp5; crunch_anal1 = inp6; crunch_align = inp7; crunch_binsize=inp8
		
		// assume everything that was saved was included.
		cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_included"
		Execute cmdstr
		crunch_included = 1	
		
		Killwaves inp0, inp1, inp2, inp3, inp4, inp5, inp6, inp7, inp8
		
		// Set up Edit Table to allow user to view what's been loaded
		if (WinType("Crunch_Table")==0)		// if Table does not already exist, create it
			Edit/W=(5,250, 500, 400) crunch_included, crunch_file, crunch_sweep0, crunch_sweep1, crunch_bline0, crunch_bline1, crunch_anal0, crunch_anal1, crunch_align, crunch_binsize as "Crunch Parameters"
			DoWindow/C Crunch_Table	
			Execute "Arrange_Crunch_Table()"		
		endif
	endif
	
	if (cmpstr(ctrlname, "bSaveCrunch")==0)
		// Save relavent variables as a file as CrunchFileNameStr
		
		cmdstr = "Make/T/N="+num2str(crunch_no_files+1)+" temp"
		Execute cmdstr
		cmdstr = "temp = crunch_file"
		Execute cmdstr
		cmdstr = "temp[crunch_no_files]=\"end\""
		Execute cmdstr
		Save/J/I/P=crunch temp, crunch_sweep0, crunch_sweep1, crunch_bline0, crunch_bline1, crunch_anal0, crunch_anal1, crunch_align, crunch_binsize as CrunchFileNameStr
		Print "Wrote crunch parameters to file", crunchfilenamestr
		
		cmdstr ="Killwaves temp"; Execute cmdstr
	endif
End

Function bAddCellProc(dummy)			// This function adds a new empty cell to a crunch list.  User fills it in on edit table.
	string dummy
	
	NVAR crunch_no_files = crunch_no_files
	string basestr, cmdstr
	
	crunch_no_files += 1
	
	basestr = "Redimension/N="+num2str(crunch_no_files)+" "
	cmdstr = basestr+"crunch_file"
	execute cmdstr
	cmdstr=basestr+"crunch_sweep0, crunch_sweep1, crunch_bline0, crunch_bline1, crunch_anal0, crunch_anal1, crunch_align, crunch_binsize, crunch_included"
	execute cmdstr
End

Function bRunCrunchProc(dummy)
	string dummy
	
	// This will actually calculate the crunch and display the results.  All crunch parameters should be in memory already.
	
	NVAR crunch_no_files=crunch_no_files
	
	Wave/T crunch_file=crunch_file
	Wave crunch_sweep0=crunch_sweep0			// sweep range start for crunch
	Wave crunch_sweep1=crunch_sweep1			// sweep range end for crunch
	Wave crunch_bline0=crunch_bline0				// sweep range start for baseline normalization
	Wave crunch_bline1=crunch_bline1				// sweep range end for baseline normalization
	Wave crunch_anal0=crunch_anal0				// sample number start for analysis window
	Wave crunch_anal1=crunch_anal1				// sample number end for analysis window
	Wave crunch_align=crunch_align				// sweep number to align sweeps between cells
	Wave crunch_binsize = crunch_binsize			// number of sweeps in each crunch time bin
	Wave crunch_included=crunch_included			// on-off 1-0 for including a cell in the crunch.  Not saved to disk.
	Wave crunch_align_offset = crunch_align_offset	// whole bin offset for aligning cells
	Wave crunch_align_firstn = crunch_align_firstn	// number of sweeps in first bin for alignment.
	Wave/D crunch_mean=crunch_mean
	Wave/D crunch_stdev=crunch_stdev
	Wave crunch_n=crunch_n
	NVAR max_crunch_bins = max_crunch_bins
	NVAR crunch_normalize = crunch_normalize
	NVAR crunch_zero_bin = crunch_zero_bin
	
	SVAR Expt = Expt							// for displaying which cell is being analyzed during crunch
	variable cell, sweep, bin, sweep_in_bin, val
	variable sumbaseline, nbaseline
	variable max_bins, bin1, b1
	string cmdstr
	Make/D/N=0 sum1, n1								// tallies for each bin within a cell
	Make/D/N=0 crunch_sum, crunch_ss					// sum & sum-squares for tallies across cells
	
	// delete any previous crunch results saved for debugging purposes
	cmdstr = "Killwaves/Z Crunchcell0, crunchn0, crunchcell1, crunchn1, crunchcell2, crunchn2, crunchcell3, crunchn3"
	execute cmdstr
	cmdstr = "Killwaves/Z Crunchcell4, crunchn4, crunchcell5, crunchn5, crunchcell6, crunchn6, crunchcell7, crunchn7"
	execute cmdstr
	cmdstr = "Killwaves/Z Crunchcell8, crunchn8, crunchcell9, crunchn9, crunchcell10, crunchn10, crunchcell11, crunchn11"
	execute cmdstr
	cmdstr = "Killwaves/Z Crunchcell12, crunchn12, crunchcell13, crunchn13, crunchcell14, crunchn14, crunchcell15, crunchn15"
	execute cmdstr	
	
	
	//  Calculate offset and firstn for each cell so that cells are aligned at appropriate sweep.
	//  The convention will be that the sweepnumber in crunch_align is the first sweep in bin crunch_zero_bin
	
	cell = 0
	variable bins_before_align, temp, max_offset=0
	cmdstr = "Redimension/N="+num2str(crunch_no_files)+" crunch_align_offset, crunch_align_firstn"
	execute cmdstr
	do
		if (crunch_binsize[cell] <= 1)
			DoAlert 0, "Improper bin size for cell "+num2str(cell)
		endif
		bins_before_align = ((crunch_align[cell]-crunch_sweep0[cell])/crunch_binsize[cell])				// this includes fractional bins.
		crunch_align_firstn[cell] = mod((crunch_align[cell]-crunch_sweep0[cell]),crunch_binsize[cell])		// remainder = sweeps in first bin
		crunch_align_offset[cell] = floor(bins_before_align) + (crunch_align_firstn[cell]!=0)					// rounded up to whole bins
		
		if (crunch_align_firstn[cell]==0)														// if no remainder, fill the first bin completely.
			crunch_align_firstn[cell] = crunch_binsize[cell]
		endif
		
		if (crunch_align_offset[cell] > max_offset)						// keep track of largest offset
			max_offset = crunch_align_offset[cell]
		endif
		cell += 1
	while (cell < crunch_no_files)
	
	 
	crunch_zero_bin = max_offset									// this will be the bin where the aligned sweeps are.
	
	 // Now loop through cells calculating within-cell averages
	 
	Crunch_sum = 0; crunch_n = 0; crunch_ss = 0
	cell =0;
	max_crunch_bins = 0
	
	do				// loop through all cells
		if (crunch_included[cell])
			
			// figure out which bin number to start with, according to crunch_align_offset of cell
			bin1 = max_offset - crunch_align_offset[cell]
			bin = bin1
			// Redimension the within-cell tally waves to the right size
			temp = ((crunch_sweep1[cell]-crunch_sweep0[cell]+1-crunch_align_firstn[cell])/crunch_binsize[cell])+1+bin1
			if (floor(temp)!=temp)
				temp = floor(temp)+1
			endif
			cmdstr = "Redimension/D/N="+num2str(temp)+" sum1, n1"
			Execute cmdstr
			sum1=0			
			n1=0
			sumbaseline=0; nbaseline=0									

			// first sweep 
			print "Starting Cell: ",crunch_file[cell] 
			Expt = crunch_file[cell]		// user display of which cell is being analyzed	
			sweep=crunch_sweep0[cell]
			if (Find_Sweep(sweep,crunch_file[cell])==0)	// load crunch_sweep0 into display_wave1	
				DoAlert 0, "Path should be specified on Control Bar.  Use no path or extension in crunch file names."
				return 0
			endif
			Read_Sweep(crunch_file[cell])								
			sum1[bin] = Calculate_Value(cell)			// calculate the appropriate value from display_wave1
			n1[bin] = 1
			sweep += 1

													// tally baseline values for later normalization
			if ((crunch_sweep0[cell] >= crunch_bline0[cell]) %& (crunch_sweep0[cell] <= crunch_bline1[cell]))
				sumbaseline += sum1[bin]
				nbaseline += 1
			endif
		
			if ((crunch_binsize[cell] == 1) %| (crunch_align_firstn[cell]==1))				// special case for 1 sweep per bin
				bin += 1
			endif
			
			// remaining sweeps
			do
				if (Find_Next_Sweep(crunch_file[cell])==0)
					return 0
				endif
				Read_Sweep(crunch_file[cell])
				val = Calculate_Value(cell)
				sum1[bin] += val
				n1[bin] += 1
													// tally baseline values for later normalization
				if ((sweep >= crunch_bline0[cell]) %& (sweep <= crunch_bline1[cell]))
					sumbaseline += val
					nbaseline += 1
				endif
			
				if (( bin == bin1) %& (n1[bin] == crunch_align_firstn[cell]) )			// if first bin, check that we're not exceeding firstn
					bin += 1
				endif
				
				if (n1[bin] == crunch_binsize[cell])				// for other bins, check that we're not exceeding binsize[cell]
					bin += 1
				endif
			
				sweep += 1
				
			while (sweep <= crunch_sweep1[cell])
			
			if (n1[bin]==0)			// if there are no sweeps in the last bin, remove that bin from crunch waves.
				bin -= 1
			endif
		
			if (bin>max_crunch_bins)					// keep track of max number of bins
				max_crunch_bins = bin
			endif
		
			// now normalize to baseline and for number of sweeps per bin
			b1 = 0
			do
				if (n1[b1]!=0)
					sum1[b1] /= n1[b1]
				endif
				b1 += 1
			while (b1 <= bin)
		
			if (crunch_normalize == 1)
				sum1 /= (sumbaseline/nbaseline)
			endif
		
			// debugging
			cmdstr = "Make/N="+num2str(bin+1)+" Crunchcell"+num2str(cell)
			execute cmdstr
			cmdstr = "Make/N="+num2str(bin+1)+ " Crunchn"+num2str(cell)
			Execute cmdstr
			cmdstr = "Crunchcell"+num2str(cell)+"= sum1"
			execute cmdstr
			cmdstr = "Crunchn"+num2str(cell)+"= n1"
			Execute cmdstr
		
			// add this single-cell result to the tally across cells. 
			cmdstr = "Redimension/D/N="+num2str(max_crunch_bins+1)+" crunch_sum, crunch_ss, sum1 "
			Execute cmdstr
			cmdstr = "Redimension/N="+num2str(max_crunch_bins+1)+" crunch_n, n1"
			Execute cmdstr
			crunch_sum += sum1
			crunch_ss += (sum1 * sum1)
			crunch_n += (n1 != 0)
		endif		// if cell was crunch_included	
		
		cell += 1
		
	while (cell < crunch_no_files)
	
	// Prepare to average across individual cells
	Duplicate/O/D crunch_sum, crunch_stdev, crunch_mean		// Make mean & stdev waves the appropriate size
	
	// calculate means etc. across cells.
	bin = 0
	do
		crunch_stdev[bin] = stdev(crunch_sum[bin], crunch_ss[bin], crunch_n[bin])
		bin += 1
	while (bin <= max_crunch_bins)
	
	crunch_mean = crunch_sum/crunch_n
	
	Killwaves sum1, n1, crunch_sum, crunch_ss
	
	// NOTE:  results are left in globals: crunch_mean, crunch_stdev[], and crunch_n[].  0->max_crunch_bins (global)
	// NOTE:  the specified alignment sweeps are the first sweeps in the bin crunch_zero_bin
	CheckDisplayed/A crunch_mean
	if (V_flag == 0)
		Display_Crunch_Results()
	endif
	
End

Function Display_Crunch_Results()
	Wave crunch_mean = crunch_mean
	Wave crunch_stdev = crunch_stdev
	Wave crunch_n = crunch_n
	NVAR max_crunch_bins = max_crunch_bins
	NVAR crunch_zero_bin = crunch_zero_bin
	String labelstr
	
	Display crunch_mean
	ModifyGraph mode=3,marker=8, rgb=(0,0,0), opaque=1, axisEnab(left)={0,0.7}, grid(left)=1
	ErrorBars crunch_mean Y,wave=(crunch_stdev,crunch_stdev)
	AppendToGraph/L=n crunch_n
	ModifyGraph grid(n)=1,axisEnab(n)={0.85,1}, freePos(n)=0, rgb=(0,0,0), mode(crunch_n)=6, grid(n)=1
	ModifyGraph manTick(n)={1,1,0,0},manMinor(n)={0,50}
	SetAxis/A/N=1 n
	Label n, "Cells"; ModifyGraph lblPos(n)=40
	Label left, "Crunch Units"; ModifyGraph lblPos(left)=40
	Label bottom, "Bins"
	
	// mark the point at crunch_zero_bin:  this is the bin containing all the aligned sweeps.
	textbox /A=MT/F=0/E "Crunch Results.  Aligned at bin: \{crunch_zero_bin}"
	
End

Function stdev(sum, ss, n1)
	variable sum, ss, n1
	
	variable num
	
	num = ss - ((sum*sum) / n1)
	if (n1>1)
		num /= (n1-1)
	endif
	if (n1==1)
		num = 0
	endif
	return sqrt(num)
end

Function Calculate_Value(cellnumber)
	variable cellnumber
	// This function returns the desired value for the sweep in display_wave1.  It returns slope, absolute amplitude,
	// or net amplitude depending on the value of the global variable crunch_type.
	
	// NOTE:  netamp is defined as absolute amplitude at specified window MINUS absolute amplitude of msec0-4 of
	// the sweep.
	
	NVAR crunch_type = crunch_type				// 0 = slope, 1 = netamp, 2 = absamp
	Wave crunch_anal0 = crunch_anal0
	Wave crunch_anal1 = crunch_anal1
	
	variable temp1
	
	if (crunch_type ==0)			// if slope analysis is desired
		Wave W_Coef = W_Coef
		Curvefit/Q line, display_wave1(crunch_anal0[cellnumber],crunch_anal1[cellnumber])
		temp1 = W_Coef[1]/1000			// convert sec to msec
	endif
	
	if ((crunch_type==1) %| (crunch_type==2))
		temp1= mean(display_wave1,crunch_anal0[cellnumber], crunch_anal1[cellnumber])
		if (crunch_type==1)
			temp1 -= mean(display_wave1, 0.000,0.004)			// DEFAULT BASELINE is 0-4 msec
		endif
	endif
	
	Return temp1
End

Function bCloseCrunchProc(dummy)
	string dummy
	string cmdstr
	
	DoWindow/K Crunch_Dialog
	DoWindow/K Crunch_Table
	
	cmdstr = "Killwaves/Z Crunchcell0, crunchn0, crunchcell1, crunchn1, crunchcell2, crunchn2, crunchcell3, crunchn3"
	execute cmdstr
	cmdstr = "Killwaves/Z Crunchcell4, crunchn4, crunchcell5, crunchn5, crunchcell6, crunchn6, crunchcell7, crunchn7"
	execute cmdstr
	cmdstr = "Killwaves/Z Crunchcell8, crunchn8, crunchcell9, crunchn9, crunchcell10, crunchn10, crunchcell11, crunchn11"
	execute cmdstr
	cmdstr = "Killwaves/Z Crunchcell12, crunchn12, crunchcell13, crunchn13, crunchcell14, crunchn14, crunchcell15, crunchn15"
	execute cmdstr	

End

Function bCleanUpCrunchProc(dummy)
	string dummy
	
	NVAR crunch_no_files = crunch_no_files
	Wave/T crunch_file=crunch_file
	Wave crunch_sweep0=crunch_sweep0			// sweep range start for crunch
	Wave crunch_sweep1=crunch_sweep1			// sweep range end for crunch
	Wave crunch_bline0=crunch_bline0				// sweep range start for baseline normalization
	Wave crunch_bline1=crunch_bline1				// sweep range end for baseline normalization
	Wave crunch_anal0=crunch_anal0				// sample number start for analysis window
	Wave crunch_anal1=crunch_anal1				// sample number end for analysis window
	Wave crunch_align=crunch_align				// sweep number to align sweeps between cells
	Wave crunch_binsize = crunch_binsize			// number of sweeps in each crunch time bin
	Wave crunch_included=crunch_included			// on-off 1-0 for including a cell in the crunch.  Not saved to disk.
	
	Variable cell = 0, i1=0
	
	Make/T/N=25 temp0
	Make/N=25 temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8
	
	do
		if (crunch_included[cell]!=0)		// if cell is currently included, add it to new cell list
			temp0[i1]=crunch_file[cell]
			temp1[i1]=crunch_sweep0[cell]
			temp2[i1]=crunch_sweep1[cell]
			temp3[i1]=crunch_bline0[cell]
			temp4[i1]=crunch_bline1[cell]
			temp5[i1]=crunch_anal0[cell]
			temp6[i1]=crunch_anal1[cell]
			temp7[i1]=crunch_align[cell]
			temp8[i1]=crunch_binsize[cell]
			i1 += 1
		endif
		cell +=1
	while (cell < crunch_no_files)
	crunch_no_files = i1
 	
 	string cmdstr="Redimension/N="+num2str(crunch_no_files)+" crunch_file, crunch_sweep0, crunch_sweep1, crunch_bline0, crunch_bline1,"
 	cmdstr += " crunch_anal0, crunch_anal1, crunch_align, crunch_binsize, crunch_included"
 	Execute cmdstr
 	crunch_file = temp0; crunch_sweep0=temp1; crunch_sweep1=temp2; crunch_bline0=temp3; crunch_bline1=temp4
 	crunch_anal0=temp5; crunch_anal1=temp6; crunch_align=temp7; crunch_binsize=temp8; crunch_included =1
 	
	Killwaves temp0, temp1, temp2, temp3, temp4, temp5, temp6, temp7, temp8
End

Function CrunchMarkChecked(ctrlName,checked) : CheckBoxControl
	String ctrlName
	Variable checked			// 1 if checked, 0 if not
	
	// I just need to make sure that only one of the slope/netamp/absamp boxes is checked at once
	NVAR crunch_type = crunch_type
	NVAR crunch_normalize = crunch_normalize
	
	if (cmpstr(ctrlName, "slopebox")==0)		// user selects slope
		crunch_type = 0
	endif
	if (cmpstr(ctrlName, "netbox")==0)			// user selects net amplitude
		crunch_type = 1
	endif
	if (cmpstr(ctrlName, "absbox")==0)			// user selects absolute amplitude
		crunch_type = 2
	endif
	if (cmpstr(ctrlName, "normalizebox")==0)	// user checked normalize box
		crunch_normalize = (!crunch_normalize)
	endif
	
	// Redraw the checkboxes
	DoWindow/F Crunch_Dialog
	Killcontrol slopebox
	Killcontrol netbox
	Killcontrol absbox
	Killcontrol normalizebox	
	Make_Crunch_Checkboxes()
End


//------------------------------------------ Epoch Calculation Routines ------------------------------------------------------//

// These routines allow a user to specify epochs within an experiment, and then have the program
// calculate mean & S.D. values for specified analyses during those epochs.  The idea is to calculate
// baseline and post-treatment values for a slope or amplitude window, for example.  Or for an I-V curve.

// First a dialog box is set up where the user enters which analysis they want calculated, the sweep
// ranges for the epochs to use, and whether they want the results normalized to a control epoch.

Function Make_Epoch_Dialog()
	
	SVAR epoch_analysis_list	= epoch_analysis_list		// analysis numbers to calculate values for
	NVAR epoch_normalize=epoch_normalize			// flag to indicate whether to normalize epoch results to first epoch
	SVAR epoch_range0 = epoch_range0
	SVAR epoch_range1 = epoch_range1
	SVAR epoch_range2 = epoch_range2
	SVAR epoch_range4 = epoch_range3
	SVAR epoch_range5 = epoch_range5
	SVAR epoch_range6 = epoch_range6
	SVAR epoch_range7 = epoch_range7
	
	NewPanel/W=(200,125,479,330) as "Epoch Analyzer"
	DoWindow/C Epoch_Dialog
		
	Setvariable setvar_epoch_list pos = {10,10}, size = {250,30}, fsize =10, title = "Analysis Numbers", value=epoch_analysis_list, noproc
	Setvariable set_epoch0 pos = {10,40}, size = {120,30}, fsize = 10, title = "Epoch 0", value = epoch_range0, proc=epoch_range_proc
	Setvariable set_epoch1 pos = {10,65}, size = {120,30}, fsize = 10, title = "Epoch 1", value = epoch_range1, proc=epoch_range_proc
	Setvariable set_epoch2 pos = {10,90}, size = {120,30}, fsize = 10, title = "Epoch 2", value = epoch_range2, proc=epoch_range_proc
	Setvariable set_epoch3 pos = {10,115}, size = {120,30}, fsize = 10, title = "Epoch 3", value = epoch_range3, proc=epoch_range_proc
	Setvariable set_epoch4 pos = {140,40}, size = {120,30}, fsize = 10, title = "Epoch 4", value = epoch_range4, proc=epoch_range_proc
	Setvariable set_epoch5 pos = {140,65}, size = {120,30}, fsize = 10, title = "Epoch 5", value = epoch_range5, proc=epoch_range_proc
	Setvariable set_epoch6 pos = {140,90}, size = {120,30}, fsize = 10, title = "Epoch 6", value = epoch_range6, proc=epoch_range_proc
	Setvariable set_epoch7 pos = {140,115}, size = {120,30}, fsize = 10, title = "Epoch 7", value = epoch_range7, proc=epoch_range_proc
	SetDrawEnv fsize=9
	// DrawText 58,153,"---Use sweep range, \"avg\", or \"avgn\"---"
	Checkbox normalizebox, pos={10,172}, size={150,25}, title="Normalize to first epoch?", value=epoch_normalize,proc=normalizecheckedproc
	Button bUseAvgforEpoch pos = {70,140}, size={140,20}, title = "Use Average Ranges", fsize = 10, proc = bUseAvgforEpochProc
	Button bRunEpoch pos = {164,170}, size = {40,30}, fsize=10, title = "Run", proc = bRunEpochProc
	Button bCloseEpoch pos = {219, 170}, size = {40,30}, fsize = 10, title = "Exit", proc = bCloseEpochProc
End

Function Epoch_Range_Proc(ctrlName, varNum, varStr, varName)
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	// This function allows user to enter a code for the epoch sweep range and have the
	// program figure out and enter the appropriate sweep numbers.
	// Codes supported:  avg		-- use correspondingly numbered average sweep (must already have been entered in average routines)
	//				     avgn		-- use average_n  (must have already been entered in average routine)
	
	variable epoch
	string outstr

	if ((strsearch(varStr,"avg",0) > -1) %| (strsearch(varStr,"AVG",0) > -1) )		// if the range variable contains "avg" or "AVG"
		epoch = str2num(ctrlName[9])		// get index number for appropriate epoch
		
		if (str2num(varStr[3])>=0)			// if the 4th character is a number, then user has entered avgn code
			if (str2num(varStr[3])<8)		// only supports average_0 to average_7
				outstr = "epoch_range"+num2str(epoch)+"=RangeStr"+varStr[3]			// set range to range string for average_n
			else					// desired average doesn't exist
				outstr = "epoch_range"+num2str(epoch)+"=\"! avg>7 !\""
			endif
		else								// user entered avg code
			if (epoch < 8)			// only supports average_0 to average_7
				outstr = "epoch_range"+num2str(epoch)+"=RangeStr"+num2str(epoch)		// set range to corresponding average range string												
			else					// desired average doesn't exist
				outstr = "epoch_range"+num2str(epoch)+"=\"! avg>7 !\""
			endif
		endif
		print outstr
		execute outstr	
	endif
	
End

Function bUseAvgforEpochProc(dummy)
	string dummy
	
	// This procedure is called when user wants to set all epoch ranges to match sweep ranges
	//  previously entered in the average dialog box. 
	
	Wave average_exists = average_exists
	Wave avgstart = avgstart
	Wave avgend = avgend
	
	variable epoch_number
	string outstr
	
	epoch_number = 0
	do
		if ( average_exists[epoch_number] )
			outstr = "epoch_range"+num2str(epoch_number)+"= "
			outstr +=  "\""+num2str(avgstart(epoch_number))+"-"+num2str(avgend(epoch_number))+"\""
		else
			outstr = "epoch_range"+num2str(epoch_number)+"= \"\""
		endif
		execute outstr
		epoch_number += 1
	while (epoch_number < 8)		// current supports 8 averages & 8 epochs
	
End

	
Function Normalizecheckedproc(ctrlName, checked)
	string ctrlName
	variable checked
	
	NVAR epoch_normalize = epoch_normalize
	epoch_normalize = checked
	
End


Function bCloseEpochProc(dummy)
	string dummy
	
	DoWindow/K Epoch_Dialog
End

Function bRunEpochProc(dummy)
	string dummy
	
	SVAR epoch_range0 = epoch_range0
	SVAR epoch_range1 = epoch_range1
	SVAR epoch_range2 = epoch_range2
	SVAR epoch_range3 = epoch_range3
	SVAR epoch_range4 = epoch_range4
	SVAR epoch_range5 = epoch_range5
	SVAR epoch_range6 = epoch_range6
	SVAR epoch_range7 = epoch_range7
	NVAR epoch_normalize = epoch_normalize
	SVAR epoch_analysis_list = epoch_analysis_list
	SVAR Expt = Expt
	SVAR epoch_temprange = epoch_temprange
	NVAR sweepnumber = sweepnumber
	Wave/T analysis_name = analysis_name
	
	variable epoch_number
	string cmdstr, sourcewave
	variable start_sweep, end_sweep, returnval
	variable analnumber, space, posn, last_epoch_flag

	 if (strlen(epoch_analysis_list)==0)
	 	DoAlert 0, "Please enter analysis numbers separated by spaces."
	 	Return 0
	 endif
	 
	 // print header for output to history area
	 printf "Epoch"
	 posn = 0; last_epoch_flag = 0
	 if (strlen(epoch_analysis_list)==0)
		DoAlert 0, "Epoch analysis list was empty."
		Return 0
  	 endif
	 do
		space = strsearch(epoch_analysis_list," ",posn)
		if (space == -1)							// if not found, this was the last entry
			last_epoch_flag = 1
			space = strlen(epoch_analysis_list)
		endif
		analnumber = str2num(epoch_analysis_list[posn,space-1])
		posn = space+1
		printf "\t%s\tS.D.",analysis_name[analnumber]
		execute cmdstr
	 while (last_epoch_flag == 0)	
	 printf "\r"
	 // that was all the header!!	
	 
	 epoch_number = 0
	 do
	 	cmdstr = "epoch_temprange = epoch_range"+num2str(epoch_number)
	 	execute cmdstr
	 	start_sweep = extract_sweep(epoch_temprange,0)
	 	end_sweep = extract_sweep(epoch_temprange,1)
	 
		if ((start_sweep >= 0)	%& (end_sweep>start_sweep))			// legitimate range was entered
		 	cmdstr = "printf \"#%s\t\", epoch_range"+num2str(epoch_number)
		 	execute cmdstr
		 	Reset_Analyses()
		 	// first sweep
		 	sweepnumber = start_sweep
		 	Find_Sweep(sweepnumber,Expt)
			Read_Sweep(Expt)
			Analysis_Master()
				
			//subsequent sweeps in epoch
			do
				sweepnumber += 1
				returnval = Find_Next_Sweep(Expt)
				if (returnval > 0)
					Read_Sweep(Expt)
					Analysis_Master()
				endif
			while ( (sweepnumber < end_sweep) %& (returnval >0))

			// now calculate mean value for all analyses in epoch_analysis_list
			
			posn = 0; last_epoch_flag = 0
			do
				space = strsearch(epoch_analysis_list," ",posn)
				if (space == -1)							// if not found, this was the last entry
					last_epoch_flag = 1
					space = strlen(epoch_analysis_list)
				endif
				analnumber = str2num(epoch_analysis_list[posn,space-1])
				posn = space+1
				sourcewave = "analysis"+num2str(analnumber)
				WaveStats/Q/R=(0,end_sweep-start_sweep) $sourcewave
				
				printf " %.4f\t %.4f\t",V_avg, V_sdev
				
				// suppress output for I-V plot construction -- print "Current[", epoch_number,"]=",V_avg
				
			while (last_epoch_flag == 0)
			printf "\r"		
		endif		// if legitimate sweep range
		epoch_number += 1
	while (epoch_number < 8)			// only allow epoch numbers 0-7 right now
	printf "\r"
	
End

Function extract_sweep(sweeprange,firstorlast)
	string sweeprange				// returns the first or last sweep of the range, or -1 if invalid range.
	variable firstorlast					// 0 = return first sweep;  1 = return last sweep
	
	variable hyphen, posn
	string buildstr
		
	if ((strlen(sweeprange)==0)	%| (cmpstr(sweeprange,"ST-END")==0) )		
		return -1
	endif
	
	if (cmpstr(sweeprange,"! avg>4 !")==0)			// this is the error code for improper auto average range entry
		return -1
	endif
	
	hyphen = strsearch(sweeprange,"-",0)
	if (hyphen == -1)
		DoAlert 0, "Improper sweep range.  Use format 'start-end'."
		Return -1
	endif

	posn = 0 				// extract start sweep number
	buildstr = ""
	do
		buildstr+=sweeprange[posn]
		posn += 1
	while (posn < hyphen)
	
	if (firstorlast==0)				// return first sweep if requested.
		return str2num(buildstr)
	endif
	
	posn = hyphen + 1			// extract end sweep number
	buildstr = ""
	do
		buildstr += sweeprange[posn]
		posn += 1
	while (posn < strlen(sweeprange))
	if (firstorlast==1)
		return str2num(buildstr)
	endif
	
End


//------------------------------------------ Functions to Read Sweep Files --------------------------------------------------//

Function NewFileProc(ctrlName, varNum, varStr,varName)
	String ctrlName
	Variable varNum
	String varStr
	String varName
	
	// This procedure is called when the user enters a new data file name to read.
	//  It will prompt user to supply whether the file is of a voltage recording or a current
	//  recording, and set path_mode accordingly.   Ultimately this information should
	//  be stored in the data file itself, but now it is not.
	
	// Make the dialog box.
	NewPanel/W=(200,125,380,255) as "Recording Type"
	DoWindow/C Recording_Type_Dialog
	
	SetDrawEnv textxjust=1
	DrawText 90,25, "Please specify whether"
	SetDrawEnv textxjust=1
	DrawText 90, 40, varStr
	SetDrawEnv textxjust=1
	DrawText 90,55, "is a current or voltage recording."
	
	DrawTheBoxes()
	
End

Function DrawTheBoxes()
	Wave path_mode = path_mode
	
	Checkbox currentbox, pos={30,60}, size={70,25}, title="Current", value=(path_mode[0] %& 1),proc=RecTypechecked
	Checkbox voltagebox, pos={110, 60}, size={70,25}, title="Voltage", value=!(path_mode[0] %& 1), proc=RecTypechecked
	Button bOK7 pos={70, 100}, size={40,25}, fsize=10, title="OK", proc=bOKNewFileProc
End

Function RecTypeChecked(ctrlName, checked)
	string ctrlname
	variable checked
	
	// called when user selects voltage or current recording type boxes on Recording_Type_Dialog
	
	Wave path_mode = path_mode
	
	if (cmpstr(ctrlName, "currentbox")==0)		// user selects current
		path_mode[0]=1
		path_mode[1]=1
	endif
	if (cmpstr(ctrlName, "voltagebox")==0)		// user selects voltage
		path_mode[0]=0
		path_mode[1]=0
	endif

	// Redraw the checkboxes
	Killcontrol currentbox
	Killcontrol voltagebox
	Killcontrol bOK7
	DrawTheBoxes()
	
End

Function bOKNewFileProc(dummy)
	string dummy
	
	// Relabel existing analysis windows to reflect new path_mode entered by user.
	// Also relabel Stepsize setvariable control on control bar.
	
	NVAR number_of_analyses = number_of_analyses
	Wave analysis_display = analysis_display
	Wave analysis_on = analysis_on
	Wave/T analysis_type = analysis_type
	Wave path_mode = path_mode
	NVAR disk_sweep_no = disk_sweep_no
		
	variable i1
	string cmdstr, labelstr

	
	DoWindow/K Recording_Type_Dialog
	
	i1 = 0
	do
		if ((analysis_display[i1]>=1) %& (analysis_on[i1]==1))
			cmdstr = "DoWindow/F analysis_window"+num2str(i1)
			execute cmdstr
			labelstr = yaxislabel(analysis_type[i1],path_mode[0])					// figure out correct y axis label
			cmdstr="Label left \""+labelstr+"\""
			Execute cmdstr
		endif
		i1 += 1
	while (i1 < number_of_analyses)
	
	DoWindow/F Control_Bar
	if (path_mode[0]==0)
		SetVariable setvar_stepsize, title="Step (pA)"
	else
		SetVariable setvar_stepsize, title="Step (mV)"
	endif
		
	// Read first sweep
	disk_sweep_no = 0
	GetSweep("",0,"","")
	
End

Function Find_Sweep (sweep_number, filename)
	Variable sweep_number
	String filename
	
	//    This procedure will open the requested file for Reading, using the global symbolic path,
	//     and use the linked list of waveheaders to locate the waveheader corresponding to the 
	//     requested sweep number.  It will return the byte location of desired waveheader.
	//     If the desired sweep number does not exist, it will return 0.
	// 	Note:  the opened file is left open so that future Find_Next_Sweep or Read_Sweep routines don't have to re-open it.
	//	Therefore, when opening each new file, Find_Sweep must be called before any other read routine.
	
	NVAR current_wheader_ptr = current_wheader_ptr				// byte address of current waveheader (global)
	SVAR ydataname = ydataname
	SVAR xdataname = xdataname
	SVAR exptname = exptname 
	NVAR refnum=refnum
	variable magic_number
	variable wheaderptr
	variable sweepptr, tempptr
	variable sweep
	variable exitcode = 0
	variable garbage
	variable scale_factor
	string inputstr
	
	variable i, c
	
	xdataname=""
	ydataname=""
	exptname=""
	
	SVAR separator = separator					// global for field separator for saved strings
	NVAR fheader_magicnumber = fheader_magicnumber
	NVAR wheader_magicnumber = wheader_magicnumber
	SVAR extension = extension
	
	filename += extension
	
	if (refnum != 0)
		Close refnum			// close the previous file if one existed.
	endif
	
	// test to see if filename exists in path savepath //
	Open/Z/R/P=savepath /T="IGT-" refnum filename
	if (V_flag != 0)
		DoAlert 0, "No such filename found."
		Return 0
	endif
	Close refnum
	
	// open the file //
	Open/R /P=savepath /T="IGT-" refnum filename
	
	// Read Fileheader //
	FSetPos refnum, 0				
	FBinRead/F=2 refnum, magic_number		// For valid files, magicnumber = 1
	if (magic_number != fheader_magicnumber)
		DoAlert 0, "This file is not an Igor sweep file."
		return 0
	endif
	
	FBinRead/U/F=3 refnum, wheaderptr		// byte address of first waveheader
	FBinRead/F=4 refnum, garbage				// skip:  absolute time of first sweep	
	inputstr  = "                    "					// this must be set to 20 spaces //
	FBinRead refnum, inputstr	
	i=0; c=strsearch(inputstr, separator, 0)			
	do										// ydataname = inputstr up to separator
		ydataname += inputstr[i]
		i += 1
	while (i<c)
	FBinRead refnum, inputstr	
	i=0; c=strsearch(inputstr, separator, 0)			
	do										// xdataname = inputstr up to separator
		xdataname += inputstr[i]
		i += 1
	while (i<c)
	FBinRead refnum, inputstr	
	i=0; c=strsearch(inputstr, separator, 0)			
	do										// exptname = inputstr up to separator
		exptname += inputstr[i]
		i += 1
	while (i<c)
	
	// Now follow the linked list of waveheaders to find the desired sweep. //
	do
		FSetPos refnum, wheaderptr					// Go to next waveheader
	
		FBinRead/F=2 refnum, magic_number			// check magicnumber	
		if (magic_number != wheader_magicnumber)
			DoAlert 0, "Failed to find wheader"
			return 0
		endif
		FBinRead/F=2 refnum, sweep						// read sweep
		if  (sweep == sweep_number)	
			exitcode = 1									// is this the one?
		endif
		
		FBinRead/F=2 refnum, garbage						// number of pts in sweep (SKIP)
		FBinRead/U/F=3 refnum, garbage					// scale factor (SKIP)
		FBinRead/F=4 refnum, garbage						// amplifier gain (SKIP)
		FBinRead/F=4 refnum, garbage						// sample rate, kHz (SKIP)
		FBinRead/F=4 refnum, garbage						// Vm (SKIP)
		FBinRead/F=4 refnum, garbage						// dx for calculating x-axis (SKIP)
		FBinRead/F=4 refnum, garbage						// time of sweep			(SKIP)					
		FBinRead/U/F=3 refnum, garbage					// ptr to wavedata for this sweep (SKIP)
		FBinRead/U/F=3 refnum, tempptr					// ptr to next waveheader
		if (exitcode == 0)
			wheaderptr = tempptr
		endif
		FBinRead/U/F=3 refnum, garbage					// ptr to previous waveheader (SKIP)
		
		if (wheaderptr == 0)		// if no next sweep //
			inputstr = "Final sweep in file was "+num2str(sweep)
			DoAlert 0, inputstr
			return 0
		endif
		
	while (exitcode == 0) 
	
	//  Note:  I'm not closing refnum here!
	//  Close refnum
	current_wheader_ptr = wheaderptr						// set global current_wheader_ptr to this waveheader
	
End


Function Find_Next_Sweep(filename)
	string filename
	
	// This function starts at the current waveheader in file filename
	// and looks forward to find the next sweep.  It returns the byte
	// address of the next waveheader.
	
	// Note:  I have modified this procedure so it just reads from the open file specified by refnum.  It will not reopen or close it.
	
	NVAR refnum=refnum
	variable garbage, sweep
	variable nextwheaderptr
	string outstr
	variable magic_number
	NVAR wheader_magicnumber = wheader_magicnumber
	NVAR current_wheader_ptr = current_wheader_ptr
	SVAR extension = extension
	
	// File is assumed to be already open..
	
	FSetPos refnum, current_wheader_ptr
	FBinRead/F=2 refnum, magic_number			// check magicnumber	
	
		if (magic_number != wheader_magicnumber)
			DoAlert 0, "Improper waveheader byte address in Find_Next_Sweep"
			return 0
		endif
		FBinRead/F=2 refnum, sweep						// read sweep (SKIP)
		FBinRead/F=2 refnum, garbage						// number of pts in sweep (SKIP)
		FBinRead/U/F=3 refnum, garbage					// scale factor (SKIP)
		FBinRead/F=4 refnum, garbage						// amplifier gain (SKIP)
		FBinRead/F=4 refnum, garbage						// sample rate, kHz (SKIP)
		FBinRead/F=4 refnum, garbage						// Vm (SKIP)
		FBinRead/F=4 refnum, garbage						// dx for calculating x-axis (SKIP)
		FBinRead/F=4 refnum, garbage						// time of sweep			(SKIP)					
		FBinRead/U/F=3 refnum, garbage					// ptr to wavedata for this sweep (SKIP)
		FBinRead/U/F=3 refnum, nextwheaderptr					// ptr to next waveheader
		if (nextwheaderptr == 0)
			outstr = "Sweep "+num2str(sweep)+" is the final sweep."
			DoAlert 0, outstr
			return 0
		endif
		
		current_wheader_ptr = nextwheaderptr				// update the current sweep pointer.
		Return 1
		
End
		
Function Find_Previous_Sweep (filename)
	string filename
	
	// This function starts at the current waveheader in file filename
	// and looks backwared to find the previous sweep.  It returns the byte
	// address of the previous waveheader.
	
	// As for Find_Next_Sweep, this assumes a file is already open and specified by refnum.
	
	NVAR refnum=refnum
	variable garbage, sweep
	variable prevwheaderptr
	string outstr
	variable magic_number
	NVAR wheader_magicnumber = wheader_magicnumber
	NVAR current_wheader_ptr = current_wheader_ptr
	SVAR extension = extension
	
	// Note I'm assuming the file is already open here.
	
	FSetPos refnum, current_wheader_ptr
	FBinRead/F=2 refnum, magic_number			// check magicnumber	
		if (magic_number != wheader_magicnumber)
			DoAlert 0, "Improper waveheader byte address in Find_Previous_Sweep"
			return 0
		endif
		FBinRead/F=2 refnum, sweep						// read sweep (SKIP)
		FBinRead/F=2 refnum, garbage						// number of pts in sweep (SKIP)
		FBinRead/U/F=3 refnum, garbage					// scale factor (SKIP)
		FBinRead/F=4 refnum, garbage						// amplifier gain (SKIP)
		FBinRead/F=4 refnum, garbage						// sample rate, kHz (SKIP)
		FBinRead/F=4 refnum, garbage						// Vm (SKIP)
		FBinRead/F=4 refnum, garbage						// dx for calculating x-axis (SKIP)
		FBinRead/F=4 refnum, garbage						// time of sweep			(SKIP)					
		FBinRead/U/F=3 refnum, garbage					// ptr to wavedata for this sweep (SKIP)
		FBinRead/U/F=3 refnum, garbage					// ptr to next waveheader
		FBinRead/U/F=3 refnum, prevwheaderptr			// ptr to previous waveheader
		
		if (prevwheaderptr == 0)
			outstr = "Sweep "+num2str(sweep)+" is the first sweep."
			DoAlert 0, outstr
			return 0
		endif
		current_wheader_ptr = prevwheaderptr				// update the current sweep pointer
		
End

Function Read_Sweep(filename)
	String filename				// file to read from disk

	// This function reads the current sweep from filename and loads that data into
	// the global wave disk_wave1
	
	// Note:  this routine assumes the file is already open and specified by the global refnum.
	
	NVAR refnum=refnum

	variable sweep, npts, Vm, dx, sweep_time, sweepptr
	string outstr
	variable magicnumber
	NVAR wheader_magicnumber = wheader_magicnumber
	NVAR sweep_magicnumber = sweep_magicnumber
	Wave display_wave1 = display_wave1				// referencing global wave for displaying data 
	NVAR disk_sweep_no = disk_sweep_no
	NVAR disk_sweep_time = disk_sweep_time
	NVAR no_samples = no_samples
	NVAR rate = kHz
	NVAR current_wheader_ptr = current_wheader_ptr
	SVAR extension = extension
	NVAR gZERO = gZERO
	variable scale_factor, amplifier_gain
	NVAR DCoffset = DCoffset							// to enable zero on/off in other procedures
	
	Make/W sw1										// local wave: 16-bit sweep for reading data from file
	
	// Note:  I'm assuming here the file is already open and specified by refnum
	
	
	FSetPos refnum, current_wheader_ptr				// Read the waveheader
	FBinRead/F=2 refnum, magicnumber				// check magicnumber	
		if (magicnumber != wheader_magicnumber)
			DoAlert 0, "Improper waveheader byte address in Read_Sweep"
			return 0
		endif
	FBinRead/F=2 refnum, disk_sweep_no				// sweep number
	FBinRead/F=2 refnum, no_samples					// number of pts in sweep
	FBinRead/U/F=3 refnum, scale_factor				// scale factor 
	FBinRead/F=4 refnum, amplifier_gain				// amplifier gain 
	FBinRead/F=4 refnum, rate						// kHz sample rate for this sweep
	FBinRead/F=4 refnum, Vm							// Vm for recalculating DC sweep if saved using autozero function. 
	FBinRead/F=4 refnum, dx							// dx for calculating x-axis
	FBinRead/F=4 refnum, disk_sweep_time			// time of sweep						
	FBinRead/U/F=3 refnum, sweepptr					// ptr to wavedata for this sweep
	
	// Dimension data and display waves appropriately for the data in the file //
	outstr = "Redimension/N="+num2str(no_samples)+" sw1"
	execute outstr
	outstr = "Redimension/N="+num2str(no_samples)+" display_wave1"
	execute outstr
	
	FSetPos refnum, sweepptr							// read sweep data
	FBinRead/F=2 refnum, magicnumber				// magicnumber
	if (magicnumber != sweep_magicnumber)
		DoAlert 0, "Improper sweep byte address in Read_Sweep"
		return 0
	endif
	FBinRead/F=2 refnum, sw1								// the sweep itself (2 bytes per sample)
	
	display_wave1 = (sw1/scale_factor/amplifier_gain*1000)+Vm	// scale sw1 back to real data values
															// Note that Vm needs to be added back to saved sweep.
															// This is because sweeps collected in autozero mode are
															// saved to disk zeroed (to preserve dynamic range).
															// If autozero wasn't used, Vm=0, so no harm done.
															// In earlier data files, this file position contained 0 anyway.
	
	setscale /p x, 0, 0.001/rate, "sec", display_wave1
	
	if (gZERO ==1)					// if user wants baseline zero //
		DCoffset = mean (display_wave1,0,pnt2x(display_wave1,9))
		display_wave1 -= DCoffset
	endif
	
	// Don't close the file--leave it open!
	killwaves sw1
	
End
	
Function GetSweep(ctrlName, varNum, varStr,varName)
	string ctrlName
	variable varNum
	string varStr
	string varName
	
	// called when user enters a number on the sweep number control.
	// this will read & display the specified sweep.
	
	bReadWaveProc("")
End

Function bReadWaveProc(dummy) : buttoncontrol
	string dummy
	
	SVAR Expt = Expt
	NVAR disk_sweep_no = disk_sweep_no
	
	Find_Sweep(disk_sweep_no, Expt)
	Read_Sweep(Expt)
	
End


Function bNextWaveProc(dummy) : buttoncontrol
	string dummy
	
	SVAR Expt = Expt
	
	Find_Next_Sweep(Expt)
	Read_Sweep(Expt)
	
End


Function bPrevWaveProc(dummy) : buttoncontrol
	string dummy

	SVAR Expt = Expt
	Find_Previous_Sweep(Expt)
	Read_Sweep(Expt)
	
End

Function SetupCursorProc()				// This procedure called from the Analysis Menu to identify single sweep nums from anal windows.
	string ctrlname
	NVAR CursorAposn = CursorAposn
	
	// if control window already exists, don't remake it
	if (WinType("Read_Sweep_Number_Panel") == 0)
		NewPanel/W=(520,140,770,257) as "Read Sweep Number"
		DoWindow/C Read_Sweep_Number_Panel
		SetDrawEnv textxjust=1
		DrawText 125,25, "Read Sweep Number from Anal. Window"

		PopupMenu bPickAnalysis, pos={2,40}, mode=1, value=WinList("Analysis*",";","WIN:1"), proc=bPickAnalysisProc, title = "Use Analysis Window"
		Button bClose_Read_Sweep_Number_Panel, pos = {160,75}, size = {50,30}, title = "Close", proc=bCloseReadSweepNoProc
		Button bReadThisSweepNo, pos = {30,75}, size = {100,30}, title = "Read Sweep No.", proc=bReadThisSweepNoProc
	endif
	
End

Function bReadThisSweepNoProc(ctrlName)
	string ctrlName
	
	NVAR disk_sweep_no = disk_sweep_no
	NVAR firstanalsweep = firstanalsweep
						
	ControlInfo bPickAnalysis
	DoWindow /F $S_value
	disk_sweep_no = pcsr(A) + firstanalsweep	
	
	bReadWaveProc("")
End

Function bCloseReadSweepNoProc(ctrlName)
	string ctrlname
	
	DoWindow/K Read_Sweep_Number_Panel
	// This will also delete the controls bUseCursor, bNoUseCursor, and bPickAnalysis.
	DeleteCursorsOnAnalWindows()
	
End


Function bPickAnalysisProc(ctrlName, popNum, popStr) : PopupMenuControl
	String ctrlName
	Variable popNum
	String popStr
	NVAR disk_sweep_no = disk_sweep_no
	NVAR firstanalsweep=firstanalsweep
	
	DeleteCursorsOnAnalWindows()
				
	ControlInfo/W=Read_Sweep_Number_Panel bPickAnalysis			// check which analysis window the user has selected.
	DoWindow /F $S_value
	string mytracename = TraceNameList(S_value,";",0)
	Cursor/P A, $mytracename,  disk_sweep_no - firstanalsweep		// put the cursor on at the position specified by disk_sweep_no.

	// note the cursor value is not read until user clicks the Read Sweep No. button.

End
 
 Function DeleteCursorsOnAnalWindows()			// This proc deletes any CursorA that may exist on an analysis window.
 	string window_name
 	NVAR number_of_analyses = number_of_analyses
 	
 	variable num = 0
 	
 	do
 		window_name = "Analysis_Window"+num2str(num)
 		if (WinType(window_name) == 1)			// if this graph exists, delete the cursor on it
 			DoWindow/F $window_name
 			Cursor/K A
 		endif
 		num += 1
 	while (num < number_of_analyses)
 End
 

// ------------------------------------------------------------ Printing Functions ---------------------------------------------------------------------//

Function bLayoutProc(dummy)
	string dummy
	
	Execute "Make_Layout()"
End


Window Make_Layout(): Layout
	// don't need global declarations--this is a macro.
	
	variable left1=50
	variable top1=120
	variable right1=570
	variable bottom1
	variable spacing = 1
	string cmdstr
	variable i1
	
	PauseUpdate; Silent 1		// building window...
	Layout /C=1 /W=(85.5,41,586.5,479.75)
	if (WinType("Stim_Protocol_Window") == 1)
		cmdstr="Stim_Protocol_Window("
		cmdstr += num2str(380)+","+num2str(45)+","+num2str(560)+","+num2str(225)+")/O=1/F=0"
		AppendToLayout $cmdstr
		top1 += (100+spacing)
	endif
	
	i1 = 0
	do
		if ((analysis_on[i1]==1) %& (analysis_display[i1]>=1) )
			if (( cmpstr(analysis_type[i1],"IHOLD")==0) %| (cmpstr(analysis_type[i1],"RSERIES")==0) %| (cmpstr(analysis_type[i1],"RINPUT")==0) )
				bottom1 = top1 + 60			// set appropriate graph height
			else
				bottom1 = top1 + 120			// graph height for major graphs 
			endif
			cmdstr="analysis_window"+num2str(i1)+"("
			cmdstr += num2str(left1)+","+num2str(top1)+","+num2str(right1)+","+num2str(bottom1)+")/O=1/F=0"
			AppendToLayout $cmdstr
			top1 = bottom1 + spacing
		endif
		i1 += 1
	while (i1 < number_of_analyses)
	
	// print whatever is in the sweep window
	bottom1 = top1 + 180
	right1 = left1 + 530			// make this one narrower
	cmdstr = "Sweep_window("
	cmdstr += num2str(left1)+","+num2str(top1)+","+num2str(right1)+","+num2str(bottom1)+")/O=1/F=0"
	AppendToLayout $cmdstr
	
	// Print a label
	Textbox/F=0/A=MT/E=1/X=0/Y=0 "\\Z14"+Expt
	Textbox/F=0/A=RT/E=1/X=5/Y=0 "\\Z12"+date()+"     "+time()	
	
	ModifyLayout mag=.5, units=1

EndMacro




Function CleanUp()

	Close/A							// close any open files
	
	KillVariables/A/Z
	DoWindow/K Control_Bar
	DoWindow/K Sweep_Window
	DoWindow/K Step_window			// Close step window
	
	// all the sweep average stuff //
	Killwaves avgstart
	Killwaves avgend
	Killwaves average_exists
	Killwaves avgDCoffset
	Killwaves avgtitle
	
	KillWaves/Z Average_0			// sloppy but effective. 
	KillWaves/Z Average_1
	KillWaves/Z Average_2
	KillWaves/Z Average_3
	KillWaves/Z Average_4
	KillWaves/Z Average_5
	KillWaves/Z Average_6
	KillWaves/Z Average_7
	KillWaves/Z Average_8

	// all the mark stuff //
	KillWaves mark_exists
	KillWaves marksweep 
	
	// all the crunch stuff //
	Killwaves crunch_file
	Killwaves crunch_sweep0
	Killwaves crunch_sweep1
	Killwaves crunch_bline0
	Killwaves crunch_bline1
	Killwaves crunch_anal0
	Killwaves crunch_anal1
	Killwaves crunch_align
	Killwaves crunch_binsize
	Killwaves crunch_included
	Killwaves crunch_mean
	Killwaves crunch_stdev
	Killwaves crunch_n
	Killwaves crunch_align_offset, crunch_align_firstn
	
	DoWindow/K analysis_window0
	DoWindow/K analysis_window1
	DoWindow/K analysis_window2
	DoWindow/K analysis_window3
	DoWindow/K analysis_window4
	DoWindow/K analysis_window5
	DoWindow/K analysis_window6
	DoWindow/K analysis_window7
	DoWindow/K analysis_window8
	DoWindow/K analysis_window9
	DoWindow/K Stim_Protocol_Window
	
	Killwaves analysis0, analysis1, analysis2, analysis3, analysis4, analysis5, analysis6, analysis7, analysis8, analysis9
	
	Killwaves analysis_name, analysis_type, analysis_path, analysis_on, analysis_display, analysis_y0, analysis_y1
	Killwaves analysis_cursor0, analysis_cursor1, path_mode
	Killwaves bline, pairing, post
	
	Killwaves analmenureference
	
	Killwaves sweeptimes
	Killwaves display_wave1
End

	




Window ChangeDelayWindow() : Graph
	PauseUpdate; Silent 1		// building window...
	Display /W=(5.25,233.75,197.25,445.25) bline,pairing,post
	ModifyGraph margin(left)=32,margin(bottom)=27,margin(top)=10,margin(right)=10
	ModifyGraph marker=8
	ModifyGraph rgb=(0,0,0)
	ModifyGraph msize=2.5
	ModifyGraph opaque=1
	ModifyGraph tick=2
	ModifyGraph zero(bottom)=1
	ModifyGraph fSize=8
	ModifyGraph lblMargin(bottom)=1
	ModifyGraph btLen=2
	ModifyGraph tlOffset(left)=2
	ModifyGraph manTick(left)={100,25,0,0},manMinor(left)={0,0}
	SetAxis left -60,150
	SetAxis bottom 0,0.6
	Textbox/N=text0/F=0/A=MC/X=0.00/Y=41.20 "\\Z08Change Delay Protocol"
	Textbox/N=text1/F=0/A=MC/X=-16.92/Y=4.72 "\\Z08 Bline"
	Textbox/N=text1_1/F=0/A=MC/X=-15.92/Y=-34.76 "\\Z08 Post"
	Textbox/N=text1_2/F=0/A=MC/X=-14.93/Y=-15.02 "\\Z08 Pairing"
EndMacro
