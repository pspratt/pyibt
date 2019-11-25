"""
IBT Class:
Object that allows for extracting and interacting with data stored in IBT files
created by ecceles anaylsis

Attributes:
sweeps: list of sweep dictionary containing raw sweep data from ibt files
exp_details: dictionary containing ibt metadata
ibt_path: path to the imported ibt files
ibt_name: name of the ibt files
time: list of sweep times in seconds from the start of the experiment
sweep_list: list of sweep numbers in ibt files
temp: list of sweep temperatures
count: number of sweeps in ibt files

sweep_Y: numpy array of Vm or pA data for sweep specified by set_sweep
sweep_X: numpy array of time points for sweep specified by set_sweep
sweep_C: numpy array of Vm or pA commands for sweep specified by set_sweep
sweep_temp: temperature of sweep specified by set_sweep
sweep_num: sweep currently set by set_sweep
sweep_Y_label: y_axis label for sweep set by set_sweep
sweep_Y_label: x_axis label for sweep set by set_sweep
sweep_C_label: y_axis label sweep command for sweep set by set_sweep

Properties:
dVdt: time derivated of sweep_Y specified by set_sweep

Functions:
set_sweep: intitalizes sweep values
Various plotting functions

To do:
Write functions to:
convert time to sweep indicies
return subsweeps values without loading full sweep to quickly measure Vm, Rin for each sweep
"""
import os
import numpy as np
import matplotlib.pyplot as plt

from pyibt.parse_IBT import *

# TODO(ken): Factor out interfaces for sweeps, analysis and plotting.
# E.G. "cell" class that stores a list of identically formatted sweep objects. Sweeps
# contain methods for analyzing / plotting that only need to know about single sweeps,
# cells contain analysis/plotting methods that go across-sweep.
class IBT:

    def __init__(self, ibt_File_Path, sweeps = []):

        #check if it is the right kind of file
        if not ibt_File_Path.lower().endswith(".ibt"):
            raise Exception("File must have the file extension 'ibt'")

        #Check if file paths and filenames exists
        self.ibt_File_Path = ibt_File_Path
        if not os.path.exists(self.ibt_File_Path):
            raise ValueError("IBT file does not exist: %s" % self.ibt_File_Path)
        self.ibt_path = ibt_File_Path
        self.ibt_name = os.path.splitext(os.path.basename(self.ibt_File_Path))[0]

        #Get experiment details and sweep headers
        self.exp_details = get_experiment_details(ibt_File_Path)
        self._sweep_headers = get_sweep_headers(ibt_File_Path)

        #parse sweep headers to get sweep metadata
        self.sweeps = parse_sweep_headers(ibt_File_Path, self._sweep_headers)

        self.time = []
        self.sweep_list = []
        self.temp = []
        self.count = len(self.sweeps)
        for i, sweep in enumerate(self.sweeps):
            self.time.append(sweep['sweep_time'])
            self.sweep_list.append(sweep['sweep_num'])
            self.temp.append(sweep['temperature'])

        self.set_sweep(self.sweep_list[0])

    def set_sweep(self,sweep_num):
        #update sweep values


        if sweep_num < 0:
            raise Exception("sweep index must be greater or equal to 0")
        elif sweep_num > self.sweep_list[-1]:
            raise Exception("sweep index is out of bounds")

        self.sweep_Y, self.sweep_X, self.sweep_C = get_sweep_data(self.ibt_File_Path,
                                                                  self.sweeps[sweep_num])
        self.sweep_temp = self.sweeps[sweep_num]['temperature']
        self.sweep_num = sweep_num
        self.sweep_points_per_sec = self.sweeps[sweep_num]["sample_rate"]

        #set axes labels
        self.sweep_X_label = "Time (seconds)"
        if self.sweeps[sweep_num]["rec_mode"] == 1: #voltage clamp
            self.sweep_Y_label = "Membrane Potential (mV)"
            self.sweep_C_label = "Applied Current (pA)"
        elif self.sweeps[sweep_num]["rec_mode"] == 2: #voltage clamp
            self.sweep_Y_label = "Clamp Current (pA)"
            self.sweep_C_label = "Command Voltage (mV)"
        else:
            self.sweep_Y_label = "unknown"
            self.sweep_C_label = "unknown"

    def get_sub_sweep_Vm(self, sweep_num, start_point, num_points):
        """
        get Vm data for sweep num from start_point to start_point+num_points
        """
        sweep = self.sweeps[sweep_num]
        with open(self.ibt_File_Path,"rb") as fb:
            fb.seek(sweep['sweep_data_pointer']) #go to sweep data
            magic_number = int.from_bytes(fb.read(2),byteorder='little')
            if magic_number != 13: #check if we went to the correct place
                print("incorrect sweep byte address")

            #Ensure requested points are within the limits of the sweep
            if num_points < 1:
                raise Exception("num_points must be greater than 1")
            elif start_point + num_points > sweep["num_points"]:
                raise Exception("Requested range exceeds sweep length")
            elif start_point < 0:
                raise Exception("start_point must be greater than 0")

            if num_points == 1:
                fb.seek(sweep['sweep_data_pointer']+2 + start_point*2)
                return int.from_bytes(fb.read(2),byteorder='little',signed=1)/sweep["scale_factor"]/sweep["amp_gain"]*1000
            else:
                fb.seek(sweep['sweep_data_pointer']+2 + start_point*2)
                Vm = []
                for i in range(num_points):
                    Vm.append((int.from_bytes(fb.read(2),byteorder='little',signed=1)/sweep["scale_factor"]/sweep["amp_gain"])*1000)

            return Vm


    @property
    def dVdt(self):
        return np.gradient(self.sweep_Y,self.sweep_X)/1e3

    """
    Ploting Functions
    """

    def plot_sweep(self, ax=[], color='k', ylim=(-150,50)):
        if ax == []:
            ax = plt.gca()

        ax.plot(self.sweep_X, self.sweep_Y, color=color)

        ax.set_ylim(ylim)

        ax.set_ylabel(self.sweep_Y_label, fontsize=14)
        ax.set_xlabel(self.sweep_X_label, fontsize=14)

        return ax

    def plot_sweep_command(self, ax=[], color='k'):
        if ax == []:
            ax = plt.gca()

        ax.plot(self.sweep_X, self.sweep_C, color=color)

        ax.set_ylabel(self.sweep_C_label, fontsize=14)
        ax.set_xlabel(self.sweep_X_label, fontsize=14)

        return ax

    def plot_all_sweeps(self, ax=[], color='k', ylim=(-150,50)):
        if ax == []:
            ax = plt.gca()

        original_sweep_num = self.sweep_num

        for sweep_num in self.sweep_list:
            self.set_sweep(sweep_num)
            ax.plot(self.sweep_X, self.sweep_Y, color=color)

        ax.set_ylim(ylim)

        ax.set_ylabel(self.sweep_Y_label, fontsize=14)
        ax.set_xlabel(self.sweep_X_label, fontsize=14)

        self.set_sweep(original_sweep_num)

        return ax

    def plot_all_sweep_commands(self, ax=[], color='k'):
        if ax == []:
            ax = plt.gca()

        for sweep_num in self.sweep_list:
            self.set_sweep(sweep_num)
            ax.plot(self.sweep_X, self.sweep_C, color=color)

        ax.set_ylabel(self.sweep_C_label, fontsize=14)
        ax.set_xlabel(self.sweep_X_label, fontsize=14)

        return ax

    def plot_phase_plane(self, ax=[], color='k',t_lim=[], pipette_offset = 0):
        if ax == []:
            ax = plt.gca()


        if t_lim == []:
            vm = self.sweep_Y
            dVdt = self.dVdt

        else:
            start = int(t_lim[0]*self.sweep_points_per_sec)
            end = int(t_lim[1]*self.sweep_points_per_sec)
            vm = self.sweep_Y[start:end]
            dVdt = self.dVdt[start:end]

        if pipette_offset != 0:
            vm = vm+pipette_offset

        ax.plot(vm, dVdt, color=color)
        ax.set_ylabel('dVdt (V/sec)', fontsize=14)
        ax.set_xlabel(self.sweep_Y_label, fontsize=14)

        return ax
