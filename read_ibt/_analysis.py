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
