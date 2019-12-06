
import numpy as np

def spike_times(self,dVdt_thresh=15,min_spike_len=.2):

    if self.rec_mode != "current clamp":
        raise Exception("rec_mode must be in current clamp")
    return detect_spike_times(self.data, self.time,
                          dVdt_thresh=dVdt_thresh, min_spike_len=min_spike_len)

def spike_properties(self,dVdt_thresh=15,min_spike_len=.2):
    if self.rec_mode != "current clamp":
        raise Exception("rec_mode must be in current clamp")
    return detect_spike_properties(self.data, self.time,
                          dVdt_thresh=dVdt_thresh, min_spike_len=min_spike_len)

def spike_times_during_command(self,comm_num,dVdt_thresh=15,min_spike_len=.2):
    if self.rec_mode != "current clamp":
        raise Exception("rec_mode must be in current clamp")

    command = self.commands[comm_num]
    if not command['flag']:
        raise Exception('Command {} not activated'.format(comm_num))

    Vm = self.get_data(command['start'],command['duration'])
    time = self.get_time(command['start'],command['duration'],absolute=False)

    return detect_spike_times(Vm, time,
                                           dVdt_thresh = dVdt_thresh,
                                           min_spike_len = min_spike_len)

def spike_properties_during_command(self,comm_num,dVdt_thresh=15,min_spike_len=.2):
    if self.rec_mode != "current clamp":
        raise Exception("rec_mode must be in current clamp")

    command = self.commands[comm_num]
    if not command['flag']:
        raise Exception('Command {} not activated'.format(comm_num))

    all_spikes = self.get_spike_properties(dVdt_thresh=dVdt_thresh,min_spike_len=min_spike_len)

    command_spikes = []
    for spike in all_spikes:
        if spike['start_time'] >= command['start']\
                and spike['start_time'] <= command['start'] + command['duration']:
            command_spikes.append(spike)
    return command_spikes

def Rin_from_command(self,comm_num,window_size=0.01):
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

def data_during_command(self, comm_num,lpad=0,rpad=0):
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

"""""""""""""""""""""""""""
Non-object methods
"""""""""""""""""""""""""""
def calc_Rin(mV_pre,mV_post,pA_pre,pA_post):
    #Return value is in Mohm
    return np.abs((mV_pre-mV_post)/(pA_pre-pA_post)) * (1e-3/1e-12)/1e6

def detect_spikes(Vm, time, dVdt_thresh = 15, min_spike_len = 0.0001, properties=True):
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

def detect_spike_times(Vm, time, dVdt_thresh = 15, min_spike_len = 0.0001):
    """
    detects spike times in Vm
    """







    #check if consecutive points above thresh are long enough to qualify as a spike



    #for each run, ensure that it exceeds the spike time
    #If so append the time of the first index of the run to spike_times
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
