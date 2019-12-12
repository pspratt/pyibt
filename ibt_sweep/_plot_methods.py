"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Methods for quickly plotting data in ibt_sweep objects
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
import numpy as np
import matplotlib.pyplot as plt
from pyibt.ibt_sweep._data_extraction import *

def plot_sweep(self, ax=[], color='k',highlight_commands=False):
    if ax == []:
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

def plot_response_to_command(self, comm_num,ax=[],color='k',lpad=0,rpad=0):
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

  if ax == []:
      ax = plt.gca()
  ax.plot(time, data, color=color)
  ax.axvspan(0,command['duration'],alpha=0.5,color='lightcoral')
  ax.set_ylabel(self.y_label)
  ax.set_xlabel(self.x_label)
  return ax

def plot_command(self, ax=[], color='k'):
    if ax == []:
      ax = plt.gca()

    ax.plot(self.time, self.command, color=color)
    ax.set_ylabel(self.y_label)
    ax.set_xlabel(self.command_label)

    return ax

def plot_phase_plane(self, start=0, duration=[], pipette_offset=0, ax=[], color='k'):
    if ax == []:
      ax = plt.gca()

    ax.plot(self.get_data(start,duration)+pipette_offset,
          self.get_dVdt(start=start, duration=duration)
          , color=color)
    ax.set_ylabel('dVdt (V/sec)')
    ax.set_xlabel(self.y_label)

    return ax

def plot_spike(spike_properties, ax=[]):
    if ax == []:
        ax = plt.gca()

    ax.plot(spike_properties['time']-spike_properties['time'][0],spike_properties['Vm'])
    ax.set_xlabel('Time (seconds)')
    ax.set_ylabel('Membrane Potential (mV)')
    return ax
