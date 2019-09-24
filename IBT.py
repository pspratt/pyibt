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
Vm_epoch: list of two numbers specifying start and stop times for calculating  Vm (see below)
amp_epoch: list of four numbers [baseline_start,base_end,amp_start,amp_end] specifying times for calculating amp (see below)
slope_epoch: list of two numbers specifiying start and stop times for calculating  slope (see below)
Rin_epoch: list of four numbers [baseline_start,base_end,Rin_start,Rin_end] specifying times for calculating Rin (see below)
sweep_Y: numpy array of Vm or pA data for sweep specified by set_sweep
sweep_X: numpy array of time points for sweep specified by set_sweep
sweep_C: numpy array of Vm or pA commands for sweep specified by set_sweep
sweep_temp: temperature of sweep specified by set_sweep
sweep_num: sweep currently set by set_sweep
sweep_Y_label: y_axis label for sweep set by set_sweep
sweep_Y_label: x_axis label for sweep set by set_sweep
sweep_C_label: y_axis label sweep command for sweep set by set_sweep

Properties:
Vm: list of Vm values for each sweep calcuated as the mean between Vm_epoch
amp: list of values for each sweep calcuated as the difference between baseline and amp specified by amp_epoch
slope: list of slope values for each sweep calculated as the rise/run between points specified by slope_epoch
Rin_epoch: list of Rin values for each sweep calculated from the baseline and rin points specified by Rin_epoch
dVdt: time derivated of sweep_Y specified by set_sweep

Functions:
set_sweep: intitalizes sweep values
Various plotting functions
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

        #Check if specific sweeps were specified, parse headers of only those sweeps
        if not sweeps:
            self.sweeps = parse_sweep_headers(ibt_File_Path, self._sweep_headers)
        else:
            sweep_headers = [self._sweep_headers[sweep] for sweep in sweeps]
            self.sweeps = parse_sweep_headers(ibt_File_Path, sweep_headers)

        self.time = []
        self.sweep_list = []
        self.temp = []
        self.count = len(self.sweeps)
        for i, sweep in enumerate(self.sweeps):
            self.time.append(sweep['sweep_time'])
            self.sweep_list.append(sweep['sweep_num'])
            self.temp.append(sweep['temperature'])
        # self.Vm_epoch = [0,0.001] #[start,stop]
        # self.amp_epoch = [0.048,0.05,0.0558,0.0658]#[baseline_start,baseline_stop,amp_start,amp_end]
        # self.slope_epoch = [0.0524,0.0544] #[start,stop]
        # self.Rin_epoch = [0.5,0.55,0.635,0.645]#[baseline_start,baseline_stop,amp_start,amp_end]
        self.set_sweep(self.sweep_list[0])

    def set_sweep(self,sweep_num):
        #update sweep values
        sweep_idx = self.sweep_list.index(sweep_num)

        self.sweep_Y, self.sweep_X, self.sweep_C = get_sweep_data(self.ibt_File_Path,
                                                                  self.sweeps[sweep_idx])
        self.sweep_temp = self.sweeps[sweep_idx]['temperature']
        self.sweep_num = sweep_num
        self.sweep_points_per_sec = self.sweeps[sweep_idx]["sample_rate"]

        #set axes labels
        self.sweep_X_label = "Time (seconds)"
        if self.sweeps[sweep_idx]["rec_mode"] == 1: #voltage clamp
            self.sweep_Y_label = "Membrane Potential (mV)"
            self.sweep_C_label = "Applied Current (pA)"
        elif self.sweeps[sweep_idx]["rec_mode"] == 2: #voltage clamp
            self.sweep_Y_label = "Clamp Current (pA)"
            self.sweep_C_label = "Command Voltage (mV)"
        else:
            self.sweep_Y_label = "unknown"
            self.sweep_C_label = "unknown"

    # @property
    # def Vm(self):
    #     if len(self.Vm_epoch) != 2:
    #         raise Exception("Vm_epoch must be a list with two numbers")
    #     elif self.Vm_epoch[0] < 0:
    #         raise Exception("Vm_epoch[0] must be greater than zero")
    #     self._Vm = []
    #     for sweep in self.sweeps:
    #         if self.Vm_epoch[1] > sweep["dataX"][-1]:
    #             raise Exception("Vm_epoch[1] must be less than the length of the sweep")
    #         start_idx = int(self.Vm_epoch[0]*sweep["sample_rate"])
    #         end_idx = int(self.Vm_epoch[1]*sweep["sample_rate"])
    #         self._Vm.append(np.mean(sweep["dataY"][start_idx:end_idx]))
    #     return self._Vm
    #
    # @property
    # def Rin(self): #Output values seem incorrect
    #     if len(self.Rin_epoch) != 4:
    #         raise Exception("Vm_epoch must be a list with four numbers")
    #     elif self.Rin_epoch[0] < 0 or self.Rin_epoch[2] < 0:
    #         raise Exception("Rin_epoch[0] and Rin_epoch[2] must be greater than zero")
    #     self._Rin = []
    #     for sweep in self.sweeps:
    #         if self.Rin_epoch[1] > sweep["dataX"][-1] or self.Rin_epoch[3] > sweep["dataX"][-1]:
    #             raise Exception("Rin_epoch[1] and Rin_epoch[3] must be less than the length of the sweep")
    #
    #         baseline_start_idx = int(self.Rin_epoch[0]*sweep["sample_rate"])
    #         baseline_end_idx = int(self.Rin_epoch[1]*sweep["sample_rate"])
    #         baseline_Y = np.mean(sweep["dataY"][baseline_start_idx:baseline_end_idx])
    #         baseline_C = np.mean(sweep["dataC"][baseline_start_idx:baseline_end_idx])
    #
    #         amp_start_idx = int(self.Rin_epoch[2]*sweep["sample_rate"])
    #         amp_end_idx = int(self.Rin_epoch[3]*sweep["sample_rate"])
    #         amp_Y = np.mean(sweep["dataY"][amp_start_idx:amp_end_idx])
    #         amp_C = np.mean(sweep["dataC"][amp_start_idx:amp_end_idx])
    #
    #         #Use ohms law: V=IR R=V/I
    #         if amp_C-baseline_C == 0: #no command
    #             self._Rin.append(np.nan)
    #         else:
    #             if sweep["rec_mode"] == 1: #current clamp R=Y/C
    #                 self._Rin.append(np.abs((amp_Y-baseline_Y)/(amp_C-baseline_C))*(1e-3/1e-12)/1e6)
    #             elif sweep["rec_mode"] == 2: #voltage clamp R=C/Y
    #                 self._Rin.append(np.abs(((amp_C-baseline_C)/amp_Y-baseline_Y))*(1e-3/1e-12)/1e6)
    #     return self._Rin
    #
    # @property
    # def amp(self):
    #     if len(self.amp_epoch) != 4:
    #         raise Exception("Vm_epoch must be a list with four numbers")
    #     elif self.amp_epoch[0] < 0 or self.amp_epoch[2] < 0:
    #         raise Exception("Rin_epoch[0] and Rin_epoch[2] must be greater than zero")
    #     self._amp = []
    #     for sweep in self.sweeps:
    #         if self.amp_epoch[1] > sweep["dataX"][-1] or self.Rin_epoch[3] > sweep["dataX"][-1]:
    #             raise Exception("Rin_epoch[1] and Rin_epoch[3] must be less than the length of the sweep")
    #
    #         baseline_start_idx = int(self.amp_epoch[0]*sweep["sample_rate"])
    #         baseline_end_idx = int(self.amp_epoch[1]*sweep["sample_rate"])
    #         baseline_Y = np.mean(sweep["dataY"][baseline_start_idx:baseline_end_idx])
    #
    #         amp_start_idx = int(self.amp_epoch[2]*sweep["sample_rate"])
    #         amp_end_idx = int(self.amp_epoch[3]*sweep["sample_rate"])
    #         amp_Y = np.mean(sweep["dataY"][amp_start_idx:amp_end_idx])
    #
    #         self._amp.append(amp_Y-baseline_Y)
    #
    #     return self._amp
    #
    # @property
    # def slope(self):
    #     if len(self.slope_epoch) != 2:
    #         raise Exception("slope_epoch must be a list with two numbers")
    #     elif self.slope_epoch[0] < 0:
    #         raise Exception("slope_epoch[0] must be greater than zero")
    #     self._slope = []
    #     for sweep in self.sweeps:
    #         if self.slope_epoch[1] > sweep["dataX"][-1]:
    #             raise Exception("Vm_epoch[1] must be less than the length of the sweep")
    #         start_idx = int(self.slope_epoch[0]*sweep["sample_rate"])
    #         end_idx = int(self.slope_epoch[1]*sweep["sample_rate"])
    #
    #         rise = sweep["dataY"][end_idx] - sweep["dataY"][start_idx]
    #         run = sweep["dataX"][end_idx] - sweep["dataX"][start_idx]
    #
    #         self._slope.append(rise/run)
    #     return self._slope

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

    def plot_phase_plane(self, ax=[], color='k',t_lim=[]):
        if ax == []:
            ax = plt.gca()
        if t_lim == []:
            ax.plot(self.sweep_Y, self.dVdt, color=color)
        else:
            ax.plot(self.sweep_X[t_lim[0]:t_lim[1]], self.sweep_C[t_lim[0]:t_lim[1]], color=color)
        ax.set_ylabel('dVdt (V/sec)', fontsize=14)
        ax.set_xlabel(self.sweep_Y_label, fontsize=14)

        return ax
