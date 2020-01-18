import os
import numpy as np
import matplotlib.pyplot as plt
from pyibt.sweep import Sweep

class Read_IBT(object):
    """
    ibt class:
    Object that allows for extracting and interacting with data stored in IBT files
    """
    def __init__(self, ibt_File_Path):

        if os.path.exists(ibt_File_Path):  # Check if file paths and filenames exists
            self.ibt_File_Path = ibt_File_Path
        elif os.path.exists(ibt_File_Path + '.ibt'):  # see if .ibt extension was left off
            self.ibt_File_Path = ibt_File_Path + '.ibt'
        else:
            raise ValueError("IBT file does not exist: %s" % ibt_File_Path)

        self.name = os.path.splitext(os.path.basename(self.ibt_File_Path))[0]

        self.sweeps = []
        self._sweep_pointers = self._get_sweep_pointers()
        for sweep_pointer in self._sweep_pointers:
            self.sweeps.append(Sweep(self.ibt_File_Path, sweep_pointer))

    def _get_sweep_pointers(self):
        '''
        Function returns sweep headers of ibt file specified by ibt_File_Path
        '''
        sweep_pointers = []

        with open(self.ibt_File_Path,"rb") as fb:

            magic_number = int.from_bytes(fb.read(2),byteorder='little',signed=1)
            if magic_number != 11: #check if the magic number matches ecceles file magic number
                raise Exception("This is not a valid igor sweep file")

            EOF = False
            next_sweep_pointer = int.from_bytes(fb.read(4),byteorder='little')
            while not EOF:
                fb.seek(next_sweep_pointer)

                magic_number = int.from_bytes(fb.read(2),byteorder='little')
                if magic_number != 12:
                    raise Exception("Failed to find sweep")

                sweep_pointers.append(next_sweep_pointer)
                fb.seek(next_sweep_pointer+204)
                next_sweep_pointer = int.from_bytes(fb.read(4),byteorder='little')

                if next_sweep_pointer == 0:
                    EOF = True # This is the final sweep in the linked list
                    return sweep_pointers

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    Analysis Methods """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    def find_sweeps_with_command(self,
                                 value=None, duration=None, start=None,
                                 value_operator='=',duration_operator='=',start_operator ='='):
        indices=[]
        valid_commands=[]
        for sweep in self.sweeps:
            valid_commands.append(check_sweep_commands(sweep,
                                                     value=value, duration=duration, start=start,
                                                     value_operator=value_operator,
                                                     duration_operator=duration_operator,
                                                     start_operator =start_operator))
            if valid_commands[-1].any():
                indices.append(sweep.sweep_num)

    def check_sweep_commands(sweep, value=None, duration=None, start=None,
                             value_operator='=', duration_operator='=', start_operator = '='):
        value_criteria=0
        duration_criteria=0
        start_criteria=0
        valid_commands=[]
        for command in sweep.commands:
            if not command['flag']: #check if command is active, break if not
                break
            if value is not None:
                value_criteria = __variable_comparison(value,command['value'],value_operator)
            else:#if not specified, criteria is met
                value_criteria=1
            if duration is not None:
                duration_criteria = __variable_comparison(a,b,duration_operator)
            else:#if not specified, criteria is met
                duration_criteria=1
            if start is not None:
                start_criteria = __variable_comparison(a,b,start_operator)
            else: #if not specified, criteria is met
                start_criteria=1
            valid_commands.append(np.asarray([value_criteria,duration_criteria,start_criteria]).any())
        return np.asarray(valid_commands)

    def average_sweeps_during_command(self, sweep_list, command, lpad=0, rpad=0, zero=False):
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

    def p_n_subtraction(self, sweep_list, p_comm=1, n_comm=2, baseline=0.01, rpad=.01):
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

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    Plotting Methods """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    def plot_sweep(self, sweep_num=0, color='k', ax=None):
        if ax is None:
            ax = plt.gca()
        ax = self.sweeps[sweep_num].plot_sweep(ax=ax, color=color)
        return ax

    def plot_sweep_phase_plane(self, sweep_num=0, pipette_offset=0, color='k', ax=None):
        if ax is None:
            ax = plt.gca()
        ax = self.sweeps[sweep_num].plot_phase_plane(ax=ax, pipette_offset=pipette_offset,color=color)
        return ax

    def plot_command(self, sweep_num=0, color='k', ax=None):
        if ax is None:
            ax = plt.gca()
        ax = self.sweeps[sweep_num].plot_command(ax=ax, color=color)
        return ax

    def plot_sweeps(self, sweep_nums, ax=None, color='k'):
        if ax is None:
            ax = plt.gca()
        for sweep_num in sweep_nums:
            ax = self.sweeps[sweep_num].plot_sweep(ax=ax, color=color)
        return ax

    def plot_commands(self, sweep_nums, ax=None, color='k'):
        if ax is None:
            ax = plt.gca()
        for sweep_num in sweep_nums:
            ax = self.sweeps[sweep_num].plot_command(ax=ax, color=color)
        return ax

    def plot_all_sweeps(self, ax=None, color='k'):
        if ax is None:
            ax = plt.gca()

        for sweep in self.sweeps:
            ax = sweep.plot_sweep(ax=ax, color=color)
        return ax

    def plot_all_commands(self, ax=None, color='k'):
        if ax is None:
            ax = plt.gca()

        for sweep in self.sweeps:
            ax.plot(sweep.time, sweep.command, color=color)
        return ax

def __variable_comparison(var1, var2, operator):
    #checks is a and b with the start_operator
    if operator == "=":
        return var1 == var2
    elif operator == ">":
        return var1 > var2
    elif operator == "<":
        return var1 < var2
    elif operator == "<=":
        return var1 <= var2
    elif operator == ">=":
        return var1 >= var2
    elif operator == "!=":
        return var1 != var2
