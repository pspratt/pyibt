'''
Functions to support the analysis of action potentials
All functions are in beta
'''



import matplotlib.pyplot as plt
import pyibt
import numpy as np

def spike_properties(ibt,spike_time):
    '''
    Returns dictionary with spike properties of the spike that starts
    spike_Vm
    height
    peak
    thresh
    peak_dVdt
    width
    '''
    spike_start_idx = spike_time * ibt.sweep_points_per_sec

    #find zero crossings of dVdt after spike dVdt_threshold
    dVdt = ibt.dVdt[spike_start_idx:]
    zero_crosses = find_zero_crossing(dVdt)

    #make sure zero cross is persistent to account for noise
    spike_end_idx = spike_start_idx + zero_crosses[np.argwhere(np.diff(zero_crosses)>2)[0] + 1][0]

    spike_Vm = ibt.sweep_Y[spike_start_idx:spike_end_idx]
    spike_time = ibt.sweep_X[spike_start_idx:spike_end_idx] - ibt.sweep_X[spike_start_idx]

    properties = {}
    properties['start_idx'] = spike_start_idx
    properties['start_time'] = ibt.sweep_X[spike_start_idx]
    properties['end_idx'] = spike_end_idx
    properties['end_time'] = ibt.sweep_X[spike_end_idx]
    properties['Vm'] = spike_Vm
    properties['time'] = spike_time
    properties['thresh'] = spike_Vm[0]
    properties['peak_Vm'] = np.max(spike_Vm)
    properties['height'] = np.max(spike_Vm)-spike_Vm[0]
    properties['peak_dVdt'] = np.max(dVdt[:spike_end_idx])
    properties['min_dVdt'] = np.min(dVdt[:spike_end_idx])

    half_pnts = find_zero_crossing(spike_Vm - (spike_Vm[0]+(np.max(spike_Vm)-spike_Vm[0])/2))
    properties['half_width'] = (half_pnts[1]-half_pnts[0])/ibt.sweep_points_per_sec*1000
    return properties


def get_spikes(ibt):
    spike_times = get_spike_times(ibt)
    spikes = []
    if not empty(spike_times):
        for spike_time in spike_times:
            spike.append(spike_properties(ibt,spike_time))
    return spikes

def get_spike_times(ibt, dVdt_thresh = 15, min_spike_len = 0.1):
    '''
    Returns list of spike start times
    '''
    #determine where dVdt exceeds dVdt_thresh
    runs = group_consecutives(np.argwhere((ibt.dVdt>dVdt_thresh)).flatten())
    spike_times = []
    for run in runs:
        if len(run) > np.ceil(ibt.sweep_points_per_sec/(1000/min_spike_len)):
            spike_times.append(run[0]/ibt.sweep_points_per_sec)
    return spike_times

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

def plot_spike(spike_properties, ax=[]):
    if ax == []:
        ax = plt.gca()

    ax.plot(spike_properties['time']-spike_properties['time'][0],spike_properties['Vm'])
    ax.set_xlabel('Time (seconds)')
    ax.set_ylabel('Membrane Potential (mV)')
    return ax
