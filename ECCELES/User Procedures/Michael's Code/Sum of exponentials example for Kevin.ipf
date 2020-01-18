#pragma rtGlobals=1		// Use modern global access method.


Function exponential_test ()

	Variable i, stimnum, offset, ISI, length, invtau
	String tempstring1
		
	stimnum = 10
	ISI = 0.02
	invTau = 0.001
	
	length = 500+(stimnum*ISI)+(1/invtau)*5
	
	Make /O/N=(numpnts(single)) sumwave = 0	

	DoWindow /K exp_graph
	Display /N=exp_graph sumwave

	For (i=0; i<stimnum; i+=1)
	
		tempstring1 = "componentwave"+num2str(i+1)
		Make /O/N=(numpnts(single)) $tempstring1
		Wave componentwave = $tempstring1
		componentwave = 0
		
		offset = (0.1)+(i+1)*ISI
		componentwave [0+offset,50+offset] = (p-offset)*20
		componentwave [51+offset,50000] = 1000*(e^(-((p-offset-51)*invTau)))
		
		sumwave += componentwave		
		componentwave = sumwave
		
		AppendToGraph componentwave
		ModifyGraph rgb($tempstring1) = (65280,0,0)
		ReorderTraces sumwave,{$tempstring1}		
	Endfor		
	ModifyGraph rgb(sumwave)=(0,0,0)
End

Function Exponent()

	variable i, stimnum, offset, offset2, linescan_max_time, ISI_point, onset, onset_point
	String tempstring
	Variable/G start_time, end_time, ISI

	stimnum = 10
	ISI = 0.02		// in seconds
	Onset = 0.1
	
//	CurveFit/L=2000/Q exp single[pcsr(A),pcsr(B)] /X=linescan_time /D	// explicitly calling "single", change this
	
	Make /O/N=((numpnts(fit_single_smooth)*xcsr(B))/(xcsr(B)-xcsr(A))) sumwave = 0
	Make /O/N=((numpnts(fit_single_smooth)*xcsr(B))/(xcsr(B)-xcsr(A))) fit_time = 0
	
	Wave fit_single = fit_single_smooth
	
	Wavestats/Q linescan_time		// Generate the proper timing with proper number of points for fit_time
	linescan_max_time =V_max
	For (i=0; i <numpnts(fit_time); i+=1)
		fit_time[i] = i/numpnts(fit_time)*linescan_max_time
	endfor
	

	
	// Find the appropriate point in fit_time that corresponds with ISI
	ISI_point = 0
	i =0
	Do		
		If (fit_time(i)>ISI)
			ISI_point = i-1
			break
		endif
		i+=1
	While (i<(numpnts(fit_time)))

	// Find the appropriate point in fit_time that corresponds with onset
	Onset_point = 0
	i =0
	Do		
		If (fit_time(i)>onset)
			Onset_point = i-1
			break
		endif
		i+=1
	While (i<(numpnts(fit_time)))


	For (i=0; i<stimnum; i+=1)
		tempstring = "componentwave"+num2str(i+1)
		Make /O/N=(numpnts(fit_single)) $tempstring
		Wave componentwave = $tempstring
		componentwave = 0
		
		offset = (onset_point)+(i)*ISI_point
		offset2 = (i)*ISI_point
		Insertpoints 0, (numpnts(fit_time)-numpnts(fit_single))+offset2, fit_single
		componentwave [offset,numpnts(fit_time)] = fit_single
		
		sumwave += componentwave		
		componentwave = sumwave
		
		AppendToGraph componentwave vs fit_time

	endfor

end	