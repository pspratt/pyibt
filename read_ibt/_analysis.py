import numpy as np

def find_sweeps_with_command(self,
                             value=[],duration=[],start=[],
                             value_operator='=',duration_operator='=',start_operator ='='):
    indices=[]
    valid_commands=[]
    for sweep in range(len(self.sweeps)):
        valid_commands.append(check_sweep_commands(sweep,value=value,duration=duration,start=start,
                                                 value_operator=value_operator,
                                                 duration_operator=duration_operator,
                                                 start_operator =start_operator))
        if valid_commands[-1].any():
            indices.append(sweep.sweep_num)

def check_sweep_commands(sweep,value=[],duration=[],start=[],
                         value_operator='=',duration_operator='=',start_operator = '='):
    value_criteria=0
    duration_criteria=0
    start_criteria=0
    valid_commands=[]
    for command in sweep.commands:
        if not command['flag']: #check if command is active, break if not
            break
        if value:
            value_criteria = __variable_comparison(value,command['value'],value_operator)
        else:#if not specified, criteria is met
            value_criteria=1
        if duration:
            duration_criteria = __variable_comparison(a,b,duration_operator)
        else:#if not specified, criteria is met
            duration_criteria=1
        if start:
            start_criteria = __variable_comparison(a,b,start_operator)
        else: #if not specified, criteria is met
            start_criteria=1
        valid_commands.append(np.asarray([value_criteria,duration_criteria,start_criteria]).any())
    return np.asarray(valid_commands)

def __variable_comparison(a,b,operator):
    #checks is a and b with the start_operator
    if operator == "=":
        return a == b
    elif operator == ">":
        return a > b
    elif operator == "<":
        return a < b
    elif operator == "<=":
        return a <= b
    elif operator == ">=":
        return a >= b
    elif operator == "!=":
        return a != b

def average_sweeps_during_command(self,sweep_list,command,lpad=0,rpad=0,zero=False):
    data=[]
    comm = self.sweeps[sweep_list[0]].commands[command]
    for sweep_num in sweep_list:
        sweep=self.sweeps[sweep_num]

        if sweep.commands[command] != comm:
            raise Exception('Commands must be consistent between sweeps')
        d,time = sweep.data_during_command(comm_num=command,lpad=lpad,rpad=rpad)
        if zero:
            d=d-d[0:sweep.time2index(lpad)].mean()
        data.append(d)
    data=np.asarray(data)
    return data.mean(axis=0),data,time

def average_sweeps(self,sweep_list,zero=False, baseline=(0,0)):
    '''
    TODO: Account for sweeps of different lengths and differing sample rates
    '''
    data=[]
    dx = ibt.sweeps[sweep_list[0]].dx
    num_points = ibt.sweeps[sweep_list[0]].num_points
    for sweep_num in sweep_list:
        sweep=self.sweeps[sweep_num]

        if sweep.dx != dx:
            raise Exception('Sweeps must have the same sampling rate')
        if sweep.num_points != num_points:
            raise Exception('Sweeps must be the same length')

        d = sweep.data
        time = sweep.time
        if zero:
            d=d-d[0:sweep.time2index(lpad)]
        data.append(d)
    data=np.asarray(data)
    return data.mean(axes=0),data,time

def p_n_subtraction(self,sweep_list,p_comm=1,n_comm=2,baseline=0.01,rpad=.01):
    '''
    Performs P by N subtraction of two voltage step commands to identify active currents from a mixture of active and passive responses to current steps

    INPUTS:
    start - start sweep for anaylsis
    num_sweeps - number of sweeps from start sweep to include
    p_comm - primary test pulse
    n_comm - secondary test pulse that is some factor smaller than p_comm

    RETURNS:
    result - dict with the following keywords:
    time - array of time values relative to command start
    currents - P/N subtracted current for each sweep
    mean_current - mean of the P/N subtract currents
    P_amp - value of the P command
    N_amp - value of the N command
    '''
    commands = self.sweeps[sweep_list[0]].commands
    if commands[p_comm]['duration'] != commands[n_comm]['duration']:
        raise Exception('P and N commands must be same duration')

    p_sweeps, time = self.average_sweeps_during_command(sweep_list,command=p_comm,
                                                              lpad=baseline,
                                                              rpad=rpad,
                                                              zero=True)[1:3]
    n_sweeps = self.average_sweeps_during_command(sweep_list,command=n_comm,
                                                              lpad=baseline,
                                                              rpad=rpad,
                                                              zero=True)[1]
    scale_factor = commands[p_comm]['value']/commands[n_comm]['value']

    I_subbed=[]
    for p,n in zip(p_sweeps,n_sweeps):
        I_subbed.append(p-(n*scale_factor))

    I_subbed=np.asarray(I_subbed)
    result={}
    result['time'] = time
    result['currents'] = I_subbed
    result['mean_current'] = I_subbed.mean(axis=0)
    result['P_amp']= commands[p_comm]['value']
    result['N_amp']= commands[n_comm]['value']
    return result
