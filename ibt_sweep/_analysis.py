
import numpy as np

def get_spike_times(self,dVdt_thresh=15,min_spike_len=.2):

    if self.rec_mode != "current clamp":
        raise Exception("rec_mode must be in current clamp")
    return detect_spike_times(self.data, self.time,
                          dVdt_thresh=dVdt_thresh, min_spike_len=min_spike_len)

def get_spike_properties(self,dVdt_thresh=15,min_spike_len=.2):
    if self.rec_mode != "current clamp":
        raise Exception("rec_mode must be in current clamp")
    return detect_spike_properties(self.data, self.time,
                          dVdt_thresh=dVdt_thresh, min_spike_len=min_spike_len)

def get_spike_times_during_command(self,comm_num,dVdt_thresh=15,min_spike_len=.2):
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

def get_spike_properties_during_command(self,comm_num,dVdt_thresh=15,min_spike_len=.2):
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

def get_Rin_from_command(self,comm_num,window_size=0.01):
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

def get_data_during_command(self, comm_num,lpad=0,rpad=0):
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

def detect_spike_times(Vm, time, dVdt_thresh = 15, min_spike_len = 0.1):
    """
    detects spike times in Vm
    """
    if len(Vm) != len(time):
        raise Exception("Vm and time must be the same length")

    dVdt = np.gradient(Vm,time)/1e3

    #determine where dVdt exceeds dVdt_thresh
    runs = group_consecutives(np.argwhere((dVdt>=dVdt_thresh)).flatten())

    #check if consecutive points above thresh are long enough to qualify as a spike
    min_run_len = np.ceil(min_spike_len/(time[1]-time[0])/1000)
    spike_times = []

    #for each run, ensure that it exceeds the spike time
    #If so append the time of the first index of the run to spike_times
    for run in runs:
        if len(run) > min_run_len:
            spike_times.append(time[run[0]])
    return np.asarray(spike_times)

def detect_spike_properties(Vm, time, dVdt_thresh = 15, min_spike_len = 0.1):
    '''
    Returns spike properties of all spikes in Vm/time given the criteria specified by dVdt thresh and min_spike_len
    '''
    #get all the spike start times
    spike_times = detect_spike_times(Vm, time, dVdt_thresh = dVdt_thresh,
                                min_spike_len = min_spike_len)

    spikes = []
    if len(spike_times) == 0:
        return spikes

    dt = time[1]-time[0]
    dVdt = np.gradient(Vm,time)/1e3
    # kink = np.gradient(dVdt,(Vm-Vm.min())+1) #Offset to avoid divide by zero errors

    for spike_time in spike_times:
        #find index of spike_time in time
        spike_start_idx = np.argwhere(spike_time == time)[0][0]

        #ensure spike_start meets inclusion criteria
        if dVdt[spike_start_idx-1] >= dVdt_thresh or dVdt[spike_start_idx] < dVdt_thresh:
            raise Exception('Spike_time is not a valid spike start')

        #find zero crossings of dVdt after spike dVdt_threshold
        #This is cumbersome and leads to errors. Probably better to work with Vm
        #look for local min after spike onset of Vm
        zero_crosses = find_zero_crossing(dVdt[spike_start_idx:-1])
        #make sure zero cross is persistent to account for noise
        if len(zero_crosses) > 1:
            spike_end_idx = spike_start_idx\
                            + zero_crosses[np.argwhere(np.diff(zero_crosses)>2)[0] + 1][0]
        else: #Vm ends before spike can repolarize, therefore assigned Vm[-1] as spike end
            spike_end_idx = len(Vm)-1

        spike_Vm = Vm[spike_start_idx:spike_end_idx]
        spike_time = time[spike_start_idx:spike_end_idx] - time[spike_start_idx]

        spike = {}
        spike['start_idx'] = spike_start_idx
        spike['start_time'] = time[spike_start_idx]
        spike['end_idx'] = spike_end_idx
        spike['end_time'] = time[spike_end_idx]
        spike['Vm'] = spike_Vm
        spike['time'] = spike_time
        spike['thresh'] = spike_Vm[0]
        spike['peak_Vm'] = np.max(spike_Vm)
        spike['height'] = np.max(spike_Vm)-spike_Vm[0]
        spike['peak_dVdt'] = np.max(dVdt[spike_start_idx:spike_end_idx])
        spike['min_dVdt'] = np.min(dVdt[spike_start_idx:spike_end_idx])
        spike['kink_slope'] = np.nan
        #kink[spike_start_idx:spike_start_idx+4].mean()

        try:
            half_pnts = find_zero_crossing(spike_Vm - (spike_Vm[0]+(np.max(spike_Vm)-spike_Vm[0])/2))
            spike['half_width'] = (half_pnts[1]-half_pnts[0])*dt*1000
        except:
            spike['half_width'] = np.nan
            # continue #This likely means that an artifact was detected instead of a spike. Ignore

        spikes.append(spike)
    return spikes

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
