#pragma rtGlobals=1		// Use modern global access method.


Function FileSortWindow()

	NewPanel/W=(10, 550, 430, 610)
	DoWindow/C File_Sort_Window
	String/G folder_path
	
	SetVariable folder_path pos={10,8}, size={400,30}, title="Path", value=folder_path, fsize=10
	Button Sort_files pos = {100, 32}, title = "Sort Linescans into subfolders", size = {170, 25}, proc = FileSort
	Button Close_sort pos = {350, 32}, title = "Close", size = {50, 25}, proc = Close_FileSort

end

Function FileSort(ctrlname)
	String ctrlname
	//The aim of this procedure is to identify a windows folder and then sort files within that folder
	//into separate folders based on the presence of "Ch1" or "Ch2" in the file names
	
	Variable fileindex, Ch1check, Ch2check
	String FolderPath, Ch1FolderPath, Ch2FolderPath, CurrentFile, CurrentFilePath
	
	String FileListString, varlocate
	
	//Prompt user to select folder
	ControlInfo/W=File_Sort_Window folder_path
	Varlocate = "folder_path"
	SVAR folder_path = $varlocate
		
	GetFileFolderInfo /D/Q folder_path
	If (V_flag!=0)
		DoAlert 0, "Folder not selected.  Function canceled."
		Return -1
	Endif
	FolderPath = S_path
	
	//Make Ch1 and Ch2 folders in the selected file folder
	Ch1FolderPath = FolderPath+"Alexa"		// Name in quotes will be new folder name.
	Ch2FolderPath = FolderPath+"Fluo"
	NewPath /Q/O SelectedFolder, FolderPath
	NewPath /C/Q/O Ch1Folder, Ch1FolderPath
	NewPath /C/Q/O Ch2Folder, Ch2FolderPath
		
	//Sort files into folders
	FileListString = IndexedFile (SelectedFolder, -1, ".tif")

	fileindex=0
	Do
		CurrentFile = StringFromList(fileindex, FileListString)
		If (Strlen(CurrentFile) == 0)
			break
		Endif
		CurrentFilePath = FolderPath+CurrentFile
		Ch1Check = strsearch (CurrentFile, "Ch1_Image", 0, 2)		// String in quotes should be unique and repeatable to all Ch1 images
		Ch2Check = strsearch (CurrentFile, "Ch2_Image", 0, 2)
		If (Ch1Check != -1)
			MoveFile /D CurrentFilePath as Ch1FolderPath
			//print CurrentFilePath+" Ch1"
		Elseif (Ch2check != -1)
			MoveFile /D CurrentFilePath as Ch2FolderPath
			//print CurrentFilePath+" Ch2"
		Endif
	
		fileindex += 1
				
	While (1)
		
End		//end of FileSort

Function Close_FileSort(ctrlname)
	string ctrlname
	
	DoWindow/K File_Sort_Window
end