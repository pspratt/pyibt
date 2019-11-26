import os
import numpy as np
import matplotlib.pyplot as plt
import struct

class IBT:
    """
    IBT Class:
    Object that allows for extracting and interacting with data stored in IBT files
    created by ecceles anaylsis

    Attributes:
    sweeps: list of sweep objecst
    exp_details: dictionary containing ibt metadata
    ibt_path: path to the imported ibt files
    ibt_name: name of the ibt files
    sweep_list: list of sweep numbers in ibt files
    num_sweeps: number of sweeps in ibt files
    """
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

        #parse sweep headers to get sweep objects
        self.sweeps = []
        self.sweep_list = []
        for sweep_header in self._sweep_headers:
            self.sweeps.append(ibt_sweep(self.ibt_File_Path, sweep_header))
            self.sweep_list.append(self.sweeps[-1].sweep_num)
        self.num_sweeps = len(self.sweeps)

    def plot_all_sweeps(self, ax=[], color='k', ylim=(-150,50)):
        if ax == []:
            ax = plt.gca()

        for sweep_num in self.sweep_list:
            sweep = self.sweeps[sweep_num]
            ax.plot(sweep.time, sweep.y_data, color=color)

        ax.set_ylim(ylim)
        ax.set_ylabel(sweep.y_label)
        ax.set_xlabel(sweep.x_label)
        return ax

def get_sweep_headers(ibt_File_Path):
    '''
    Function returns sweep heads of ibt file specified by ibt_File_Path
    '''
    sweep_pointers = []

    with open(ibt_File_Path,"rb") as fb:

        magic_number = int.from_bytes(fb.read(2),byteorder='little',signed=1)
        if magic_number != 11: #check if the magic number matches ecceles file magic number
            raise Exception("This is not a valid igor sweep file")

        EOF = False
        next_sweep_pointer = int.from_bytes(fb.read(4),byteorder='little')

        while not EOF:
            fb.seek(next_sweep_pointer)
            magic_number = int.from_bytes(fb.read(2),byteorder='little')
            if magic_number != 12:
                print(magic_number)
                raise Exception("Failed to find sweep")

            sweep_pointers.append(next_sweep_pointer)

            fb.seek(next_sweep_pointer+204)
            next_sweep_pointer = int.from_bytes(fb.read(4),byteorder='little')

            if next_sweep_pointer == 0:
                EOF = True # This is the final sweep in the linked list
                return sweep_pointers

def get_experiment_details(ibt_File_Path):
    with open(ibt_File_Path,"rb") as fb:
        #Check if the file is the correct type using the magic number
        magic_number = int.from_bytes(fb.read(2),byteorder='little',signed=1)
        if magic_number != 11: #check if the magic number matches ecceles file magic number
            raise Exception("This is not a valid igor sweep file")
        next_sweep_pointer = int.from_bytes(fb.read(4),byteorder='little') # pointer to the first sweep
        fb.read(4) # Unsure if this is the time of experiment start or time of first sweep. Disregard for Now
        exp_details = {}
        exp_details["y_axis_label"] = fb.read(20).decode('utf-8')
        exp_details["x_axis_label"] = fb.read(20).decode('utf-8')
        exp_details["exp_name"] = fb.read(20).decode('utf-8')
    return exp_details

"""
Based on code in ecceles analysis, IBTs appear to be custom binary files that have the following encoding:
File Open:
2 bytes: int IBT file magic number (should be 11)
4 bytes: int pointer to first sweep_pointer
4 bytes: float absolute time of first sweep_pointer
20 bytes: str name of y axis units
20 bytes: str name of x axis units
20 bytes: str name of experiment

Following pointer to first sweep:
2 bytes: int sweep magic numbers (should be 12)
2 bytes: int sweep number
4 bytes: int number of data points in sweep
4 bytes: int scale factor
4 bytes: float amplifier gain
4 bytes: float sampling rate
4 bytes: float recording mode – 0 = OFF;  1 = current clamp;  2 = voltage clamp
4 bytes: float dx – time interval between data points
4 bytes: float sweep time
4 bytes: int command pulse 1 flag
8 bytes: float command pulse 1 value
8 bytes: float command pulse 1 start
8 bytes: float command pulse 1 duration
4 bytes: int command pulse 2 flag
8 bytes: float command pulse 2 value
8 bytes: float command pulse 2 start
8 bytes: float command pulse 2 duration
4 bytes: int command pulse 3 flag
8 bytes: float command pulse 3 value
8 bytes: float command pulse 3 start
8 bytes: float command pulse 3 duration
4 bytes: int command pulse 4 flag
8 bytes: float command pulse 4 value
8 bytes: float command pulse 4 start
8 bytes: float command pulse 4 duration
4 bytes: int command pulse 5 flag
8 bytes: float command pulse 5 value
8 bytes: float command pulse 5 start
8 bytes: float command pulse 5 duration
8 bytes: float DC command pulse flag
8 bytes: float DC command pulse value
4 bytes: float temperature
8 bytes: empty
4 bytes: int pointer to sweep data
4 bytes: pointer to next sweep
4 bytes: pointer to previous sweep

following pointer to sweep data:
2 bytes: int sweep data magic number - should be 13
2 bytes * number points: int sweep data read 2 bytes per data point

sweep data needs to be divided by scale_factor, divided by amplifer gain, and multiplied by 1000
to be the correct value

byte order is little endian
"""

class ibt_sweep:
    """
    ibt_sweep Class:
    Object that allows for extracting and interacting with data stored in IBT file sweep headers created by ecceles anaylsis

    Attributes:
    ibt_File_Path
    sweep_num
    num_points
    scale_factor
    amp_gain
    sample_rate
    rec_mode
    y_label
    x_label
    command_label
    dx
    sweep_time
    commands
        flag
        value
        start
        duration
    DC_pulse_flag
    DC_pulse_value
    temperature
    sweep_data_pointer

    Properties:
    time
    y_data
    command
    dVdt

    Methods:
    time2index
    index2time
    get_time
    get_y_data
    get_command
    get_dVdt
    plot_sweep
    plot_sweep_command
    plot_phase_plane
    convert_start_and_duration
    """
    def __init__(self, ibt_File_Path, sweep_header):
        with open(ibt_File_Path,"rb") as fb:
            #Check if the file is the correct type using the magic number
            magic_number = int.from_bytes(fb.read(2),byteorder='little',signed=1)
            if magic_number != 11: #check if the magic number matches ecceles file magic number
                raise Exception("This is not a valid igor sweep file")

            fb.seek(sweep_header) #go next sweep
            #check if we were sent to the right place
            magic_number = int.from_bytes(fb.read(2),byteorder='little')
            if magic_number != 12:
                raise Exception("Failed to find sweep")
            self.ibt_File_Path = ibt_File_Path
            self.sweep_num = int.from_bytes(fb.read(2),byteorder='little')
            self.num_points =  int(struct.unpack('<f', fb.read(4))[0]) #number of data points in the sweep
            self.scale_factor = int.from_bytes(fb.read(4),byteorder='little')
            self.amp_gain = struct.unpack('<f', fb.read(4))[0]
            self.sample_rate = struct.unpack('<f', fb.read(4))[0] * 1000 #specified in kHz. Convert to Hz for clarity

            rec_mode = struct.unpack('<f', fb.read(4))[0]
            if rec_mode == 0:
                self.rec_mode = 'OFF'
                self.y_label = 'Unknown'
                self.command_label = "Unknown"
            elif rec_mode == 1:
                self.rec_mode = 'current clamp'
                self.y_label = 'Membrane Potential (mV)'
                self.command_label = "Applied Current (pA)"
            elif rec_mode == 2:
                self.rec_mode = 'voltage clamp'
                self.y_label = 'Clamp Current (mV)'
                self.command_label = 'Command Voltage (mV)'
            self.x_label = 'Time (seconds)'

            self.dx = 1/self.sample_rate
            struct.unpack('<f', fb.read(4))[0] #I think this is empty, supposed to be sample rate
            self.sweep_time = struct.unpack('<f', fb.read(4))[0]
            self.commands = []
            for num in range(5):
                command = {}
                command['flag'] = int.from_bytes(fb.read(4),byteorder='little')
                command['value'] = struct.unpack('<d', fb.read(8))[0]
                command['start'] = struct.unpack('<d', fb.read(8))[0]/1000 #sec
                command['duration'] = struct.unpack('<d', fb.read(8))[0]/1000 #sec
                self.commands.append(command)

            self.DC_pulse_flag = struct.unpack('<d', fb.read(8))[0]
            self.DC_pulse_value  = struct.unpack('<d', fb.read(8))[0]
            self.temperature = struct.unpack('<f', fb.read(4))[0]
            fb.read(8) #unspecified Values
            self.sweep_data_pointer = int.from_bytes(fb.read(4),byteorder='little')

    @property
    def time(self):
        sigfigs = int(np.floor(np.log10(1/self.dx)))+1
        time = np.round(np.asarray(range(0,self.num_points))*self.dx,sigfigs)
        return time
        """
        Note: rounding is to avoid floating errors
        """

    def get_time(self,start=0,duration=[],absolute=True):
        start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
        time = self.time[start_pnt:start_pnt+num_pnts]
        if not absolute:
            time = time-time[0]
        return time

    def time2index(self,time):
        t = self.time
        if time < 0:
            raise Exception("Time must be greater than zero")
        elif time > t[-1]:
            raise Exception("Time exceeds max time in sweep")

        return np.argmin(np.abs(t-time))

    def index2time(self,index):
        t = self.time
        if index < 0:
            raise Exception("Index must be greater than zero")
        elif index > len(t):
            raise Exception("Index exceeds sweep length")
        return self.t[index]

    def get_y_data(self, start=0, duration=[]):
        start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
        with open(self.ibt_File_Path,"rb") as fb:
            fb.seek(self.sweep_data_pointer) #go to sweep data
            magic_number = int.from_bytes(fb.read(2),byteorder='little')
            if magic_number != 13: #check if we went to the correct place
                print("incorrect sweep byte address")
            else:
                fb.seek(self.sweep_data_pointer+2 + start_pnt*2)
                Y_data = []
                for i in range(num_pnts):
                    Y_data.append((int.from_bytes(fb.read(2),byteorder='little',signed=1)/
                                   self.scale_factor/self.amp_gain)*1000)
                return np.asarray(Y_data)

    @property
    def y_data(self):
        return self.get_y_data()

    def get_command(self,start=0,duration=[]):
        start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
        comm = np.zeros(shape=(self.num_points,))
        for command in self.commands:
            if command['flag']:
                comm_start = self.time2index(command['start'])
                comm_num_pts = self.time2index(command['duration'])
                comm_end = comm_start+comm_num_pts
                comm[comm_start:comm_end] = comm[comm_start:comm_end]+command['value']
        return comm[start_pnt:start_pnt+num_pnts]

    @property
    def command(self):
        return self.get_command()

    def get_dVdt(self,start=0,duration=[]):
        start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
        return np.gradient(self.y_data,self.time)/1e3

    @property
    def dVdt(self):
        return self.get_dVdt()

    def convert_start_and_duration(self,start,duration):
        if not duration: #if no duration specified, set for length of sweep
            num_pnts = self.num_points
        else:
            num_pnts = self.time2index(duration)
        start_pnt = self.time2index(start)

        #Ensure requested points are within the limits of the sweep
        if num_pnts < 1:
            raise Exception("duration must be greater than {}".format(self.dx))
        elif start < 0:
            raise Exception("start must be greater than 0")
        elif start_pnt + num_pnts > self.num_points:
            raise Exception("Requested range exceeds sweep length")

        return start_pnt, num_pnts

    def plot_sweep(self, ax=[], color='k'):
        if ax == []:
            ax = plt.gca()

        ax.plot(self.time, self.y_data, color=color)
        ax.set_ylabel(self.y_label)
        ax.set_xlabel(self.x_label)

        return ax

    def plot_sweep_command(self, ax=[], color='k'):
        if ax == []:
            ax = plt.gca()

        ax.plot(self.time, self.command, color=color)
        ax.set_ylabel(self.y_label)
        ax.set_xlabel(self.x_label)

        return ax

    def plot_phase_plane(self, start=0, duration=[], pipette_offset=0, ax=[], color='k'):
        if ax == []:
            ax = plt.gca()

        ax.plot(self.get_y_data(start,duration)+pipette_offset,
                self.get_dVdt(start=start, duration=duration)
                , color=color)
        ax.set_ylabel('dVdt (V/sec)')
        ax.set_xlabel(self.y_label)

        return ax
