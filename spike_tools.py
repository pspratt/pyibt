import matplotlib.pyplot as plt
import pyibt
import numpy as np

def get_spike_properties(ibt,sweep,spike_start_idx):
    '''
    Returns dictionary with spike properties at the spike_start_idx
    spike_Vm
    height
    peak
    thresh
    peak_dVdt
    width
    '''
    ibt.set_sweep(sweep)

    #find zero crossings of dVdt after spike dVdt_threshold
    dVdt = ibt.dVdt[spike_start_idx:]
    spike_end_idx = find_zero_crossing(dVdt)[1]+spike_start_idx
    spike_Vm = ibt.sweep_Y[spike_start_idx:spike_end_idx]
    spike_time = ibt.sweep_X[spike_start_idx:spike_end_idx] - ibt.sweep_X[spike_start_idx]

    properties = {}
    properies['start_idx'] = spike_start_idx
    properies['start_time'] = ibt.sweep_X[spike_start_idx]
    properies['end_idx'] = spike_end_idx
    properies['end_time'] = ibt.sweep_X[spike_end_idx]
    properties['Vm'] = spike_Vm
    properties['time'] = spike_time
    properties['thresh'] = spike_Vm[0]
    properties['peak_Vm'] = np.max(spike_Vm)
    properties['height'] = np.max(spike_Vm)-spike_Vm[0]
    properties['peak_dVdt'] = np.max(dVdt[:spike_end_idx])

    half_pnts = find_zero_crossing(spike_Vm - (spike_Vm[0]+(np.max(spike_Vm)-spike_Vm[0])/2))
    properties['half_width'] = (half_pnts[1]-half_pnts[0])/ibt.sweep_points_per_sec*1000
    return properties

def get_spikes(ibt, sweep_num, dVdt_thresh = 15, min_spike_len = 0.1):
    '''
    Returns list of spikes

    ibt: ibt object
    sweep_num: sweep to detect detect_spike
    dVdt_thresh: dVdt threshold for determining spike initiation
    min_spike_len: minimum time in ms that the sweep must be above dVdt_threshold to be considered a spike
    '''
    ibt.set_sweep(sweep_num)
    #determine where dVdt exceeds dVdt_thresh
    runs = group_consecutives(np.argwhere((ibt.dVdt>dVdt_thresh)).flatten())
    spikes = []
    for run in runs:
        if len(run) > np.ceil(ibt.sweep_points_per_sec/(1000/min_spike_len)):
            spikes.append(get_spike_properties(ibt,sweep,run[0])
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
        expect = v + 1
    return result

def find_zero_crossing(x):
    '''
    returns array of indicies before a zero crossing occur
    If your input array starts and stops with zeros, it will find a zero crossing at the beginning, but not at the end
    '''
    zero_crossings = np.where(np.diff(np.signbit(x)))[0]
    return zero_crossings

def plot_spike(spike, ax=[]):
    if ax == []:
        ax = plt.gca()

    ax.plot(spike['time']-spike['time'][0],spike['Vm'])
    ax.set_xlabel('Time (seconds)')
    ax.set_ylabel('Membrane Potential (mV)')


def FI_analysis(ibt, sweep_start, num_sweeps, stim_start = .05, stim_dur = .3, dVdt_thresh = 15, 
                min_spike_len = 0.1):

    FI_data = {}
    FI_data['amp'] = []
    FI_data['spikes'] = []
    FI_data['Vm'] = []

    for sweep_num in range(sweep_start, sweep_start + num_sweeps):
        ibt.set_sweep(sweep_num)
        stim_start_idx = int(stim_start*ibt.sweep_points_per_sec)
        stim_end_idx = int(stim_start_idx + stim_dur*ibt.sweep_points_per_sec)


        FI_data['amp'].append(ibt.sweep_C[stim_start_idx])
        FI_data['Vm'].append(ibt.sweep_Y[0])

        #Find all spikes in the sweep
        all_spikes = detect_spikes(ibt, sweep_num,
                                        dVdt_thresh = dVdt_thresh,
                                        min_spike_len = min_spike_len)
        if len(all_spikes) > 0:
            valid_spikes = [spike for spike in all_spikes if spike > stim_start_idx and
                            spike <= stim_end_idx]
            FI_data['spikes'].append(len(valid_spikes))
        else:
            FI_data['spikes'].append(0)

    return FI_data
