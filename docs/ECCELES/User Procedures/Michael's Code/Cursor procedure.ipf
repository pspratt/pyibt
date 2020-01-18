#pragma rtGlobals=1		// Use modern global access method.

Function Cursor_Controls (ctrlName, varNum, varStr, varName)		//SetVariable control

	String ctrlName, varStr, varName
	Variable varNum
	
	//The aim of this function is to append/remove cursors to/from the current graph
	
	Variable i=0, tempvar1, CursorOffset, Distribute_Cursors_Call
	String graphname, LastCursorPair = "", NextCursorName, PrevCursorName, tempstring1, PlottedWaveName
	
	NVAR CursorPairsNum = CursorPairsNum
	CursorPairsNum = varNum
	NVAR PrevCursorPairsNum = PrevCursorPairsNum
	
	SVAR FileNameTruncated = FileNameTruncated
	graphname = FileNameTruncated+"_Graph"
	
	//Check to see which cursor pair is the last displayed; "?" comes from ASCII code table - it has numerical value 2 units less than "A"
	If (strlen(CsrInfo(A, graphname))==0)
		LastCursorPair = "?"
		CursorOffset = 1
	Elseif (strlen(CsrInfo(C, graphname))==0)
		LastCursorPair = "A"
		CursorOffset = 3
	Elseif (strlen(CsrInfo(E, graphname))==0)
		LastCursorPair = "C"
		CursorOffset = 5
	Elseif (strlen(CsrInfo(G, graphname))==0)
		LastCursorPair = "E"
		CursorOffset = 7
	Elseif (strlen(CsrInfo(I, graphname))==0)
		LastCursorPair = "G"
		CursorOffset = 9
	Else
		LastCursorPair = "I"
	Endif
	
	//Gather a list of the names of waves plotted in the graph and assign the first wave name to PlottedWaveName
	SVAR FileNameTruncated = FileNameTruncated
	tempstring1 = FileNameTruncated+"_Graph"
	GetWindow $tempstring1, wavelist
	Wave /T W_WaveList
	PlottedWaveName = W_WaveList[0]
	KillWaves W_WaveList
	
		
	If (CursorPairsNum==PrevCursorPairsNum)
		
		print "No change in number of cursor pairs to show."
		
	Elseif (CursorPairsNum>PrevCursorPairsNum)
	
		//print "Increase in number of cursor pairs to show."
		
		tempvar1 = CursorPairsNum - PrevCursorPairsNum
		NextCursorName = num2char(char2num(LastCursorPair)+1)
		For (i=0; i<tempvar1; i+=1)
			NextCursorName = num2char(char2num(NextCursorName)+1)
			Cursor /h=2/s=1 $NextCursorName $PlottedWaveName 1
			//Cursor /F/h=2/s=1/P $NextCursorName $PlottedWaveName 0.5,0.5 
			NextCursorName = num2char(char2num(NextCursorName)+1)
			Cursor /h=2/s=1 $NextCursorName $PlottedWaveName 2 
			//Cursor /F/h=2/s=1/P $NextCursorName $PlottedWaveName 0.5,0.5
		Endfor
		Distribute_Cursors_Call = Distribute_Cursors("Cursor_Controls")
		
	Elseif (CursorPairsNum<PrevCursorPairsNum)
	
			
		tempvar1 = PrevCursorPairsNum-CursorPairsNum
		PrevCursorName = num2char(char2num(LastCursorPair)+2)
		For (i=0; i<tempvar1; i+=1)
			PrevCursorName = num2char(char2num(PrevCursorName)-1)
			Cursor /K $PrevCursorName 
			PrevCursorName = num2char(char2num(PrevCursorName)-1)
			Cursor /K $PrevCursorName
		Endfor
						
	Else
	
		print "Error in Cursor_Controls function"
	
	Endif
	
		
	PrevCursorPairsNum = CursorPairsNum
	
End		//End of Cursor_Controls

//******************************************************************************************************
//******************************************************************************************************

Function Distribute_Cursors (ctrlName)	//Button Control

	String ctrlName
	
	String LastCursorPair, graphname, NextCursorName, tempstring1, PlottedWaveName
	Variable CursorOffset, tempvar1, i, inc
	
	SVAR FileNameTruncated = FileNameTruncated
	graphname = FileNameTruncated+"_Graph"
	
	//Check to see which cursor pair is the last displayed; "?" comes from ASCII code table - it has numerical value 2 units less than "A"
	If (strlen(CsrInfo(A, graphname))==0)
		LastCursorPair = "?"
		CursorOffset = 1
		DoAlert 0, "No cursors present."
		Return 0
	Elseif (strlen(CsrInfo(C, graphname))==0)
		LastCursorPair = "A"
	Elseif (strlen(CsrInfo(E, graphname))==0)
		LastCursorPair = "C"
	Elseif (strlen(CsrInfo(G, graphname))==0)
		LastCursorPair = "E"
	Elseif (strlen(CsrInfo(I, graphname))==0)
		LastCursorPair = "G"
	Else
		LastCursorPair = "I"
	Endif
	
	//Gather a list of the names of waves plotted in the graph and assign the first wave name to PlottedWaveName
	SVAR FileNameTruncated = FileNameTruncated
	tempstring1 = FileNameTruncated+"_Graph"
	GetWindow $tempstring1, wavelist
	Wave /T W_WaveList
	PlottedWaveName = W_WaveList[0]
	KillWaves W_WaveList
	
	//Distribute cursors
	GetAxis /W=$graphname/Q bottom	//returns x-axis range as V_min and V_max
	If (cmpstr(ctrlName,"button4")==0)	//If function called by Distribute Cursors button, distribute all existing cursors evenly across graph 
		tempvar1 = (char2num(LastCursorPair)-63)/2
		inc = (V_max-V_min)/(char2num(LastCursorPair)-62)
		For (i=0; i<tempvar1; i+=1)
			NextCursorName = num2char(65+i*2)
			Cursor $NextCursorName $PlottedWaveName (V_min+inc+2*i*inc)
			Cursor /M /A=0 $NextCursorName
			NextCursorName =  num2char(65+1+i*2)
			Cursor $NextCursorName $PlottedWaveName (V_min+2*inc+2*i*inc)
			Cursor /M /A=0 $NextCursorName
		Endfor
	Else	//If function called by Cursor_Controls, then only the last two cursors are placed
		inc = (V_max-V_min)/11
		tempvar1 = (char2num(LastCursorPair)-64)*(1/11)*(V_max-V_min)
		Cursor $LastCursorPair $PlottedWaveName (tempvar1+V_min)
		Cursor /M /A=0 $LastCursorPair
		NextCursorName =  num2char(char2num(LastCursorPair)+1)
		Cursor $NextCursorName $PlottedWaveName (inc+tempvar1+V_min)
		Cursor /M /A=0 $NextCursorName
	Endif
	
	Return 1
		
End		//End of Distribute_Cursors

//******************************************************************************************************
//******************************************************************************************************

Function Distribute_Cursors2 ()		//Function runs when F5 pressed

	Distribute_Cursors("button4")

End		//End of Distribute_Cursors2

//******************************************************************************************************
//******************************************************************************************************

Function Add_Cursor_Pair ()	//Function runs when F8 pressed

	//print "Add_Cursor_Pair function called."
	
	Variable tempvar1
	
	//get info on how many cursor pairs are currently displayed
	ControlInfo /W=Data_Analysis_Controls setvar1
	If (V_value<5)
		tempvar1 = V_Value+1
		Cursor_Controls ("Add_Cursor_Pair", tempvar1, num2str(tempvar1), "")
	Endif
	

End		//End of Add_Cursor_Pair

//******************************************************************************************************
//******************************************************************************************************

Function Remove_Cursor_Pair ()	//Function runs when F7 pressed

	//print "Remove_Cursor_Pair function called."
	
	Variable tempvar1
	
	//get info on how many cursor pairs are currently displayed
	ControlInfo /W=Data_Analysis_Controls setvar1
	If (V_value>0)
		tempvar1 = V_Value-1
		Cursor_Controls ("Remove_Cursor_Pair", tempvar1, num2str(tempvar1), "")
	Endif
	
End		//End of Remove_Cursor_Pair


//******************************************************************************************************
//******************************************************************************************************

Menu "Macros"		//This procedure defines short-cut keys

	"Distribute_Cursors2/F5"
	"Remove_Cursor_Pair/F7"
	"Add_Cursor_Pair/F8"

End		//End of "Macros"