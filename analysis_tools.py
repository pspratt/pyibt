import numpy as np
import matplotlib.pyplot as plt
import pyibt

"""
Functions for batch analyzing ibt files

All features are in beta

"""

def get_rin(ibt, comm_value = -50, comm_durr = 120, sweep_list = []):
    # [0.5,0.55,0.635,0.645] ← time points used in ecceles for calculating Rin
    if len(sweep_list) == 0:
        sweep_list = ibt.sweep_list

    Rin = []
    for sweep_num in sweep_list:
        sweep = ibt.sweeps[sweep_num]
        valid_commands = check_for_command(sweep, comm_value=comm_value,
                                           comm_durr=comm_durr, exclusive = True)
        if np.sum(valid_commands) == 0:
            continue
        ibt.set_sweep(sweep_num)
        comm_idx = valid_commands.index(True)
        start = int(ibt.sweeps[sweep_num]['command_pulse_start'][comm_idx]*ibt.sweep_points_per_sec/1000)
        end = int(start + ibt.sweeps[sweep_num]['command_pulse_duration'][comm_idx]*ibt.sweep_points_per_sec/1000)

        Rin.append(abs((ibt.sweep_Y[start]-ibt.sweep_Y[end])/comm_value) * (1e-3/1e-12)/1e6)
        print(str(sweep_num) + ': ' + str(Rin[-1]))
    if Rin == []:
        return np.nan
    else:
        return np.mean(Rin)

def get_sag_and_rebound(ibt, comm_value = -400, com_durr = 120, sweep_list = []):

    if len(sweep_list) == 0:
        sweep_list = ibt.sweep_list

    sag = []
    rebound = []
    for sweep_num in sweep_list:
        sweep = ibt.sweeps[sweep_num]

        valid_commands = check_for_command(sweep, comm_value=comm_value,
                                           comm_durr=comm_durr, exclusive = True)
        if np.sum(valid_commands) == 0:
            continue

        comm_idx = valid_commands.index(True)
        ibt.set_sweep(sweep_num)
        start = int(ibt.sweeps[sweep_num]['command_pulse_start'][comm_idx]*ibt.sweep_points_per_sec/1000)
        end = int(start + ibt.sweeps[sweep_num]['command_pulse_duration'][comm_idx]*ibt.sweep_points_per_sec/1000)

        sag.append(ibt.sweep_Y[end]-np.min(ibt.sweep_Y[start:end]))
        rebound.append(np.max(ibt.sweep_Y[end:-1])-ibt.sweep_Y[-1])

    if sag == []:
        return np.nan, np.nan
    else:
        return np.mean(sag), np.mean(rebound)

def check_for_command(sweep, comm_value=[], comm_durr=[], comm_start=[], exclusive = False):

    valid_commands = [bool(comm) for comm in sweep['command_pulse_flag']]

    if exclusive:
        values = [bool(value) for value in sweep['command_pulse_value']]
        num_commands = [value and comm for value, comm in zip(values, valid_commands)]
        if np.sum(num_commands) > 1:
            return [False,False,False,False,False]

    if comm_value:
        values = [value == comm_value for value in sweep['command_pulse_value']]
        valid_commands = [value and comm for value, comm in zip(values,valid_commands)]
    if comm_durr:
        durrs = [durr == comm_durr for durr in sweep['command_pulse_duration']]
        valid_commands = [durr and comm for durr, comm in zip(durrs, valid_commands)]
    if comm_start:
        starts = [start == comm_durr for start in sweep['command_pulse_start']]
        valid_commands = [start and comm for start, comm in zip(starts, valid_commands)]
    return valid_commands

def find_sweeps_with_command(ibt, comm_value=[], comm_durr=[], comm_start=[], exclusive = False):
    sweeps = []
    commands = []
    for sweep_num in ibt.sweep_list:
        sweep_command = check_for_command(ibt.sweeps[sweep_num],
                                 comm_value=comm_value, comm_durr=comm_durr,
                                 comm_start=comm_start,
                                 exclusive = exclusive)

        if any(sweep_command):
            sweeps.append(sweep_num)
            commands.append(sweep_command)

    return sweeps, commands
# def FI_analysis(ibt, stim_amps, stim_durr = 300, stim_start = 50,
#                 dVdt_thresh = 15, min_spike_len = 0.1):
#     for sweep_num in ibt.sweep_list:
#         for stim_amp in stim_amps:
#
#     FI_data = {}
#     FI_data['amp'] = []
#     FI_data['spikes'] = []
#     FI_data['Vm'] = []
#
#     for sweep_num in range(sweep_start, sweep_start + num_sweeps):
#         ibt.set_sweep(sweep_num)
#         stim_start_idx = int(stim_start*ibt.sweep_points_per_sec)
#         stim_end_idx = int(stim_start_idx + stim_dur*ibt.sweep_points_per_sec)
#
#
#         FI_data['amp'].append(ibt.sweep_C[stim_start_idx])
#         FI_data['Vm'].append(ibt.sweep_Y[0])
#
#         #Find all spikes in the sweep
#         all_spikes = get_spikes(ibt, sweep_num,
#                                         dVdt_thresh = dVdt_thresh,
#                                         min_spike_len = min_spike_len)
#         if len(all_spikes) > 0:
#             valid_spikes = [spike for spike in all_spikes if spike > stim_start_idx and
#                             spike <= stim_end_idx]
#             FI_data['spikes'].append(len(valid_spikes))
#         else:
#             FI_data['spikes'].append(0)
#
#     return FI_data
