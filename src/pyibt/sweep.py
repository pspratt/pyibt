import struct
import numpy as np
import matplotlib.pyplot as plt

class Sweep(object):

    """
    ibt_sweep Class:
    Object that allows for extracting and interacting with data stored in IBT file sweep headers created by ecceles anaylsis
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
            if rec_mode == 1:
                self.rec_mode = 'current clamp'
                self.y_label = 'Membrane Potential (mV)'
                self.command_label = "Applied Current (pA)"
            elif rec_mode == 2:
                self.rec_mode = 'voltage clamp'
                self.y_label = 'Clamp Current (mV)'
                self.command_label = 'Command Voltage (mV)'
            else:
                self.rec_mode = 'OFF'
                self.y_label = 'Unknown'
                self.command_label = "Unknown"
            self.x_label = 'Time (seconds)'

            self.dx = 1/self.sample_rate
            struct.unpack('<f', fb.read(4))[0] #I think this is empty, supposed to be sample rate
            self.sweep_time = struct.unpack('<f', fb.read(4))[0]
            self.commands = []
            for num in range(5):
                command = {}
                command['number'] = num
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

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    Data Extraction Methods """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    def time2index(self, time):
        t = self.time
        if time < 0:
            raise Exception("Time must be greater than zero")
        elif time > t[-1]:
            raise Exception("Time exceeds max time in sweep")

        return np.argmin(np.abs(t-time))

    def index2time(self, index):
        t = self.time
        if index < 0:
            raise Exception("Index must be greater than zero")
        elif index > len(t):
            raise Exception("Index exceeds sweep length")
        return t[index]

    @property
    def time(self):
        sigfigs = int(np.floor(np.log10(1/self.dx)))+1
        time = np.round(np.asarray(range(0,self.num_points))*self.dx,sigfigs)
        return time
        """
        Note: rounding is to avoid floating errors
        """

    def get_time(self, start=0, duration=None, absolute=True):
        if duration is None:
            duration = []
        start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
        time = self.time[start_pnt:start_pnt+num_pnts]
        if not absolute:
            time = time-time[0]
        return time

    @property
    def data(self):
        return self.get_data()

    def get_data(self, start=0, duration=None):
        if duration is None:
            duration = []
        start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
        with open(self.ibt_File_Path,"rb") as fb:
            fb.seek(self.sweep_data_pointer) #go to sweep data
            magic_number = int.from_bytes(fb.read(2),byteorder='little')
            if magic_number != 13: #check if we went to the correct place
                print("incorrect sweep byte address")
            else:
                fb.seek(self.sweep_data_pointer+2 + start_pnt*2)
                data = []
                for i in range(num_pnts):
                    data.append((int.from_bytes(fb.read(2),byteorder='little',signed=1)/
                                   self.scale_factor/self.amp_gain)*1000)
                return np.asarray(data)

    @property
    def command(self):
        return self.get_command()

    def get_command(self, start=0, duration=None):
        if duration is None:
            duration = []
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
    def dVdt(self):
        return self.get_dVdt()

    def get_dVdt(self, start=0, duration=None):
        if duration is None:
            duration = []
        start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
        return np.gradient(self.data,self.time)/1e3

    def convert_start_and_duration(self, start, duration):
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

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    Analysis methods
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    def spike_times(self, dVdt_thresh=15, min_spike_len=.0002):

        if self.rec_mode != "current clamp":
            raise Exception("rec_mode must be in current clamp")
        return detect_spike_times(self.data,
                                  self.time,
                                  dVdt_thresh=dVdt_thresh,
                                  min_spike_len=min_spike_len)

    def spike_properties(self, dVdt_thresh=15, min_spike_len=.0002):
        if self.rec_mode != "current clamp":
            raise Exception("rec_mode must be in current clamp")
        return detect_spike_properties(self.data, self.time,
                              dVdt_thresh=dVdt_thresh, min_spike_len=min_spike_len)

    def spike_times_during_command(self, comm_num, dVdt_thresh=15, min_spike_len=.0002):
        if self.rec_mode != "current clamp":
            raise Exception("rec_mode must be in current clamp")

        command = self.commands[comm_num]
        if not command['flag']:
            raise Exception('Command {} not activated'.format(comm_num))

        Vm = self.get_data(command['start'],command['duration'])
        time = self.get_time(command['start'],command['duration'],absolute=False)

        return detect_spike_times(Vm, time, dVdt_thresh = dVdt_thresh, min_spike_len = min_spike_len)

    def spike_properties_during_command(self, comm_num, dVdt_thresh=15, min_spike_len=.0002):
        if self.rec_mode != "current clamp":
            raise Exception("rec_mode must be in current clamp")

        command = self.commands[comm_num]
        if not command['flag']:
            raise Exception('Command {} not activated'.format(comm_num))

        all_spikes = self.spike_properties(dVdt_thresh=dVdt_thresh,min_spike_len=min_spike_len)

        command_spikes = []
        for spike in all_spikes:
            if spike['start_time'] >= command['start']\
                    and spike['start_time'] <= command['start'] + command['duration']:
                command_spikes.append(spike)
        return command_spikes

    def Rin_from_command(self, comm_num, window_size=0.01):
        command = self.commands[comm_num]
        if not command['flag']:
            raise Exception('Command {} not activated'.format(comm_num))

        comm_value = command['value']
        comm_start = command['start']
        comm_duration = command['duration']

        pre = np.mean(self.get_data(comm_start-window_size,window_size))
        post = np.mean(self.get_data(comm_start+comm_duration-window_size,window_size))

        if self.rec_mode == 'current clamp':
            return calc_Rin(mV_pre=pre,mV_post=post,
                            pA_pre=0,pA_post=comm_value)
        if self.rec_mode == 'voltage clamp':
            return calc_Rin(mV_pre=0,mV_post=comm_value,
                            pA_pre=pre,pA_post=post)
        return -1

    def data_during_command(self, comm_num, lpad=0, rpad=0):
        command = self.commands[comm_num]
        if not command['flag']:
            raise Exception('Command {} not activated'.format(comm_num))

        if rpad < 0 or lpad < 0:
            raise Exception('Padding must be greater than 0')
        if command['start'] - lpad < 0:
            raise Exception('lpad exceeds sweep range')
        if command['start']+command['duration']+rpad > self.num_points/self.dx:
            raise Exception('rpad exceeds sweep range')

        data = self.get_data(command['start']-lpad,command['duration']+lpad+rpad)
        time = self.get_time(command['start']-lpad,command['duration']+lpad+rpad,absolute=False)
        time = time-time[self.time2index(lpad)]

        return data, time

    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    Plotting Methods
    """""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    def plot_sweep(self, ax=None, color='k', highlight_commands=False):
        if ax is None:
            ax = plt.gca()

        ax.plot(self.time, self.data, color=color)
        ax.set_ylabel(self.y_label)
        ax.set_xlabel(self.x_label)
        if highlight_commands:
            for command in self.commands:
                if command['flag']:
                    ax.axvspan(command['start'],
                             command['start']+command['duration'],
                             color='lightcoral',
                             alpha=0.3)
        return ax

    def plot_response_to_command(self, comm_num, ax=None, color='k', lpad=0, rpad=0):

        command = self.commands[comm_num]
        if not command['flag']:
            raise Exception('Command {} not activated'.format(comm_num))

        if rpad < 0 or lpad < 0:
          raise Exception('Padding must be greater than 0')
        if command['start'] - lpad < 0:
          raise Exception('lpad exceeds sweep range')
        if command['start']+command['duration']+rpad > self.num_points/self.dx:
          raise Exception('rpad exceeds sweep range')

        data = self.get_data(command['start']-lpad,command['duration']+lpad+rpad)
        time = self.get_time(command['start']-lpad,command['duration']+lpad+rpad,absolute=False)
        time = time-time[self.time2index(lpad)]

        if ax is None:
            ax = plt.gca()
        ax.plot(time, data, color=color)
        ax.axvspan(0,command['duration'],alpha=0.5,color='lightcoral')
        ax.set_ylabel(self.y_label)
        ax.set_xlabel(self.x_label)
        return ax

    def plot_command(self, ax=None, color='k'):
        if ax == None:
          ax = plt.gca()

        ax.plot(self.time, self.command, color=color)
        ax.set_ylabel(self.command_label)
        ax.set_xlabel(self.x_label)

        return ax

    def plot_phase_plane(self, start=0, duration=[], pipette_offset=0, ax=[], color='k'):
        if ax == None:
          ax = plt.gca()

        ax.plot(self.get_data(start,duration)+pipette_offset,
              self.get_dVdt(start=start, duration=duration)
              , color=color)
        ax.set_ylabel('dVdt (V/sec)')
        ax.set_xlabel(self.y_label)

        return ax

    def plot_spike(spike_properties, ax=None):
        if ax == None:
            ax = plt.gca()

        ax.plot(spike_properties['time']-spike_properties['time'][0],spike_properties['Vm'])
        ax.set_xlabel('Time (seconds)')
        ax.set_ylabel('Membrane Potential (mV)')
        return ax

def calc_Rin(mV_pre, mV_post, pA_pre, pA_post):
    #Return value is in Mohm
    return np.abs((mV_pre-mV_post)/(pA_pre-pA_post)) * (1e-3/1e-12)/1e6

def detect_spikes(Vm, time, dVdt_thresh = 15, min_spike_len = 0.0002, properties=True):
    '''
    Method for idenifying spikes based on rates of change in the membrane potential
    INPUTS:
    Vm: array-like - membrane potential (mV)
    time: array-like - time corresponding to Vm (sec)
    dVdt_thresh: float - Threshold for determining spike initiation (V/s)
    min_spike_len: float - Minimum length of time dVdt must be above dVdt_thresh to be considered a spike (sec)
    properties: Bool - If true, returns spike_times and spike_properties. Otherwise returns only spike_properties

    Output:
    array of spike times

    Identification of spike start times:
    dVdt is first quanitified from Vm and time
    Continuous tretches (runs) of dVdt above dVdt_thresh are identified, and then esured to last longer than min_spike_len

    Spike Property measurement:
    spike_end is determined by finding the second zero crossing of dVdt after spike dVdt_threshold
    First zero crossing is AP peak, second should be end of repolarization phase
    Persistent zero crossing (must stay above zero for 3 continous points) is used to make sure that noise in slowly repolarizing spikes doesn't trigger spike end
    '''
    if len(Vm) != len(time):
        raise Exception("Vm and time must be the same length")

    #determine stretches where dVdt exceeds dVdt_thresh
    dVdt = np.gradient(Vm,time)/1e3
    runs = group_consecutives(np.argwhere((dVdt>=dVdt_thresh)).flatten())

    #If runs are longer than min_spike_len count as a spike
    dt = time[1]-time[0] #sample rate
    min_run_len = np.ceil(min_spike_len/dt)
    spike_times = []
    for run in runs:
        if len(run) > min_run_len:
            spike_times.append(time[run[0]])
    spike_times = np.asarray(spike_times)

    if not properties: #just return spike_times
        return spike_times

    #get spike properties
    spike_properties=[]
    for spike_time in spike_times:
        #find index of spike_time in time
        spike_start_idx = np.argwhere(spike_time == time)[0][0]

        #find zero crossings of dVdt after spike dVdt_threshold
        zero_crosses = find_zero_crossing(dVdt[spike_start_idx:-1])
        #make sure zero cross is persistent to account for noise
        if len(zero_crosses) > 1:
            spike_end_idx = spike_start_idx\
                            + zero_crosses[np.argwhere(np.diff(zero_crosses)>3)[0] + 1][0]
        else: #Vm ends before spike can repolarize, therefore assigned Vm[-1] as spike end
            spike_end_idx = len(Vm)-1

        spike_Vm = Vm[spike_start_idx:spike_end_idx]
        spike_time = time[spike_start_idx:spike_end_idx] - time[spike_start_idx]
        spike_dVdt = dVdt[spike_start_idx:spike_end_idx]
        spike = {}
        spike['start_idx'] = spike_start_idx
        spike['start_time'] = time[spike_start_idx]
        spike['end_idx'] = spike_end_idx
        spike['end_time'] = time[spike_end_idx]
        spike['Vm'] = spike_Vm
        spike['time'] = spike_time
        spike['thresh'] = spike_Vm[0]
        spike['peak_Vm'] = spike_Vm.max()
        spike['height'] = np.max(spike_Vm)-spike_Vm[0]
        spike['AHP'] = spike_Vm[0]-spike_Vm[-1]
        spike['peak_dVdt'] = spike_dVdt.max()
        spike['min_dVdt'] = spike_dVdt.min()
        try:
            half_pnts = find_zero_crossing(spike_Vm - (spike_Vm[0]+(np.max(spike_Vm)-spike_Vm[0])/2))
            spike['half_width'] = (half_pnts[1]-half_pnts[0])*dt*1000
        except: #For slowly repolarizing spikes this can sometimes fail
            spike['half_width'] = np.nan

        spike_properties.append(spike)
    return spike_times,spike_properties

def detect_spike_times(Vm, time, dVdt_thresh = 15, min_spike_len = 0.0002):
    '''
    Wrapper of detect_spikes to only get spike times
    '''
    return detect_spikes(Vm, time,
                          dVdt_thresh = dVdt_thresh,
                          min_spike_len = min_spike_len,
                          properties=False)

def detect_spike_properties(Vm, time, dVdt_thresh = 15, min_spike_len = 0.0001):
    '''
    Wrapper of detect_spikes to only get spike properties
    '''
    return detect_spikes(Vm, time,
                          dVdt_thresh = dVdt_thresh,
                          min_spike_len = min_spike_len,
                          properties=True)[1]

def group_consecutives(vals, step=1):
    """Return list of consecutive lists of numbers from vals (number list)."""
    run = []
    result = [run]
    expect = None
    for v in vals:
        if (v == expect) or (expect is None):
            run.append(v)
        else:
            run = [v]
            result.append(run)
        expect = v + step
    return result

def find_zero_crossing(x):
    '''
    returns array of indicies before a zero crossing occur
    If your input array starts and stops with zeros, it will find a zero crossing at the beginning, but not at the end
    '''
    zero_crossings = np.where(np.diff(np.signbit(x)))[0]
    return zero_crossings
