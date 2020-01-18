// ----------------------------------------------------------------------------------------------
//
//             AmplifierSettings.ipf
//
//             This procedure file contains declarations for waves containing amplifier scaling factors.
//             These are different for each amplifier, and should be set on each rig to reflect which amplifiers
//              are being used.
//
//         	  Updated Dec 2007 DF. 
//             (correcting earlier bugs, including failure to differentiate 700A from 700B settings)
//		   This file now defines the variable UsingAxoclamp2B = "Y" or "N".
//
// ------------------------------------------------------------------------------------------------

//---------------------------------------------------------------------------------------------
//
//     To edit this file, close ECCLES and Igor.  Double-click on the AmplifierSettings.ipf file.
//      When it launches, hit ctrl-M to visualize the procedure window.  Make any changes you
//      want.  Then hit "Save Procedure" on the File menu  (NOT "Save Experiment").
//      Then re-launch ECCLES.  It will automatically open the newly saved version of this file.
//
// --------------------------------------------------------------------------------------------      


Function Read_Amplifier_Settings()

	SVAR UsingAxoclamp2B = UsingAxoclamp2B
	Make/N=2 command_Iclamp_scale_factor
	Make/N=2 command_Vclamp_scale_factor
	Make/N=2 input_Iclamp_scale_factor
	Make/N=2 input_Vclamp_scale_factor
	Make/N=2 unscaled_Iclamp_gain
	Make/N=2 unscaled_Vclamp_gain


	// For Axopatch 200B
	//  input_Iclamp_scale_factor = 1			// units:  mV of output signal per mV of Vm
	//  input_Vclamp_scale_factor = 1			// units:  V of output signal per nA of Im
	//  unscaled_Iclamp_gain = 0				// NOT USED
	//  unscaled_Vclamp_gain = 0				// NOT USED
	//  command_Iclamp_scale_factor = 2000	// units:  pA output per V of command
	//  command_Vclamp_scale_factor = 20		// units:  mV output per V of command

	// For Axopatch 2B   --- validated 07/2007 DF
	//  input_Iclamp_scale_factor = 10			// units: mV of output signal per mV of Vm
	//  input_Vclamp_scale_factor = 0.1			// units:  V of output signal per nA of Im (Axo2B: 100 mV per nA)
	//  unscaled_Iclamp_gain = 10				// NOT USED
	//  unscaled_Vclamp_gain = 0.1			// NOT USED
	//  command_Iclamp_scale_factor = 1000	// units:  pA output per V of command
	//  command_Vclamp_scale_factor = 20		// units:  mV output per V of command
      //  UsingAxoclamp2B = "Y"				// must set this variable if you are using a 2B.  This tells Igor to set up the seal test window for the 2B.

	// For Axoclamp 700A
	//  input_Iclamp_scale_factor = 1			// units:  mV of output signal per mV of Vm  
	//  input_Vclamp_scale_factor = 0.5			// units:  V of output signal per nA of Im
	//  unscaled_Iclamp_gain = 0				// NOT USED
	//  unscaled_Vclamp_gain = 0				// NOT USED
	//  command_Iclamp_scale_factor = 400		// units:  pA output per V of command
	//  command_Vclamp_scale_factor = 20		// units:  mV output per V of command
	
	// For Axoclamp 700B  
	// input_Iclamp_scale_factor = 10			// units:  mV of output signal per mV of Vm
	// input_Vclamp_scale_factor = 0.5			// units:  V of output signal per nA of Im
	// unscaled_Iclamp_gain = 0				// NOT USED
	// unscaled_Vclamp_gain = 0				// NOT USED
	// command_Iclamp_scale_factor = 400		// units:  pA output per V of command
	// command_Vclamp_scale_factor = 20		// units:  mV output per V of command

	// Copy the relevant lines above to reflect the amplifiers actually used on this rig, for channel 0 and channel 1 separately.
	// Channel 0 is Axoclamp 700B
	input_Iclamp_scale_factor[0] = 10			// units:  mV of output signal per mV of Vm
	input_Vclamp_scale_factor[0] = 0.5			// units:  V of output signal per nA of Im
	unscaled_Iclamp_gain[0] = 0				// NOT USED
	unscaled_Vclamp_gain[0] = 0				// NOT USED
	command_Iclamp_scale_factor[0] = 400		// units:  pA output per V of command
	command_Vclamp_scale_factor[0] = 20		// units:  mV output per V of command

	// Channel 1 is Axoclamp 700B
	input_Iclamp_scale_factor[1] = 10			// units:  mV of output signal per mV of Vm
	input_Vclamp_scale_factor[1] = 0.5			// units:  V of output signal per nA of Im
	unscaled_Iclamp_gain[1] = 0				// NOT USED
	unscaled_Vclamp_gain[1] = 0				// NOT USED
	command_Iclamp_scale_factor[1] = 400		// units:  pA output per V of command
	command_Vclamp_scale_factor[1] = 20		// units:  mV output per V of command
	
End

