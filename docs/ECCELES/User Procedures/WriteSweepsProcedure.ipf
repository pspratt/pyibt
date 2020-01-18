#pragma rtGlobals=1		// Use modern global access method.

Function Write_Sweeps_To_Text_File()			// For export of sweeps or sweep segments to a file in text format -- for Strontium/mini experiments

	// Set up dialog box
	NewPanel/W=(300,125,650,340) as "Write Sweeps to Text File"
	DoWindow/C Write_Sweeps_Window
	
	SetDrawLayer ProgFront
	DrawText 20, 20, "Save sweep data to text file in Default directory."
	
	SetVariable setvarFile title="File name for output", pos={20,30}, size={300,25}, fsize=9, value=SaveFileNameStr, noproc
	SetVariable setvarFirst title="First sweep", pos={20,55}, size={110,25}, limits={0,1500,1}, fsize=9, value=firstanalsweep, noproc
	SetVariable setvarLast title="Last sweep", pos={150,55}, size={110,25}, limits={0,1500,1}, fsize=9, value=lastanalsweep, noproc
	SetDrawLayer ProgFront
	DrawText 20, 95, "Time (s) in sweep to export.  Enter start=end=0 to ignore:"
	SetDrawEnv fsize=11
	DrawText 20, 115, "Range 1:"
	SetDrawEnv fsize=11
	DrawText 20, 140, "Range 2:"
	SetVariable setvarCutRange1Start title = "Start", pos = {75, 100}, size = {110, 25}, fsize = 9, value = CutRange1Start
	SetVariable setvarCutRange1End title = "End", pos = {195, 100}, size = {110, 25}, fsize = 9, value = CutRange1End
	SetVariable setvarCutRange2Start title = "Start", pos = {75, 125}, size = {110, 25}, fsize = 9, value = CutRange2Start
	SetVariable setvarCutRange2End title = "End", pos = {195, 125}, size = {110, 25}, fsize = 9, value = CutRange2End

	Button bWriteAnalysisOK pos={60,160}, size = {60,30}, title = "OK", fsize = 10, proc = bWriteSweepOKProc
	Button bCANCEL6 pos={140,160}, size = {60,30}, title= "CANCEL", fsize = 10, proc=bCANCEL6Proc

	
End

Function bCANCEL6Proc(dummy)
	String dummy
	
	DoWindow/K Write_Sweeps_Window
	
End

Function bWriteSweepOKProc(dummy)
	string dummy
	// called when user hits "OK" button to write sweep data to text file.

	SVAR SaveFileNameStr = SaveFileNameStr
	NVAR firstanalsweep = firstanalsweep
	NVAR lastanalsweep = lastanalsweep
	NVAR CutRange1Start = CutRange1Start
	NVAR CutRange1End = CutRange1End
	NVAR CutRange2Start = CutRange2Start
	NVAR CutRange2End = CutRange2End
	NVAR display_wave1 = display_wave1
	SVAR Expt = Expt
	
	variable refnum2
	variable current_sweep, first_range_valid, second_range_valid
	string SaveFileNameStrExt
	
	if (firstanalsweep > lastanalsweep)
		DoAlert 0, "Invalid sweep range specified."
		return 0
	endif
		
	if (CutRange1End != 0) %& (CutRange1End > CutRange1Start)
		// first range is valid
		first_range_valid = 1
	else
		first_range_valid = 0
	endif
	
	if (CutRange2End != 0) %& (CutRange2End > CutRange2Start)
		// first range is valid
		second_range_valid = 1
	else
		second_range_valid = 0
	endif
	
	if (first_range_valid + second_range_valid == 0)
		DoAlert 0, "Neither time range in sweep is valid."
		Return 0
	endif
	
	SaveFileNameStrExt = SaveFileNameStr + ".txt"					// add extension to text output file (.txt)
	
	// Open output file.  Give error if it exists.
	Open/Z/R/P=analpath /T="TEXT" refnum2 SaveFileNameStrExt
	if (V_flag == 0)
		DoAlert 0, "File already exists--please supply new filename."
		Return 0
	endif
	if (refnum2 > 0) 
		close refnum2
	endif
	
	Open/P=analpath /T="TEXT" refnum2 SaveFileNameStrExt
	
	//  Read sequentially through indicated sweeps in current file.
	
	current_sweep = firstanalsweep
	
	do
		Find_Sweep(current_sweep,Expt)
		Read_Sweep(Expt)
		
		if (first_range_valid)
			wfprintf refnum2, "%f\r"/R=(CutRange1Start, CutRange1End) display_wave1				// write range 1 contents of display_wave1 to file in /t delimited format
		endif
		if (second_range_valid)
			wfprintf refnum2, "%f\r"/R=(CutRange2Start, CutRange2End) display_wave1				// write range 2 contents of display_wave1 to file in /t delimited format
		endif
		if (current_sweep < lastanalsweep)
			fprintf refnum2, "0\r0\r0\r0\r0\r0\r0\r0\r0\r0\r"			// 10 zeros between sweeps.	
		endif
		current_sweep += 1
	while (current_sweep <= lastanalsweep)

	// Close the text file.
	Close refnum2	
	
	print "Finished text output to", SaveFileNameStrExt
	
End
