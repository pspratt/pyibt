## pyibt
![](https://travis-ci.org/pspratt/pyibt.svg?branch=master)

pyibt is a Python module that extends the functionality of the [ECCELES Electrophysiology Suite](https://github.com/pspratt/pyibt/tree/master/docs/ECCELES) with a simple and intuitive API for the analysis and visualization of electrophysiology data in Python.

ECCELES is an online electrophysiology acquisition program developed for the IGOR Pro data analysis platform ([WaveMetrics](https://www.wavemetrics.com/)) that allows for conducting and and analyzing highly customizable and flexible electrophysiological experiments. ELLECES however requires a very specific computing environment to run correctly, requires proprietary software (Igor Pro), and has a limited ability to implement automated and repetitive analyses.

pyibt was developed to read the custom binary files generated by ECCELES (ibt files) and provide a simple API to interact with the data stored with them. At its core, pyibt provides an easy access to ibt data to facilitate custom analysis in Python. However, pyibt also includes a set of native methods to quickly and easily plot and analyze ephys data. Please see the examples below to learn how to get started with pyibt.

### Loading data
```python
from pyibt.read_ibt import Read_IBT
ibt = Read_IBT('demo.ibt')
```

### Accessing file information
```python
print('ibt file name:', ibt.name)
print('Number of sweeps:', len(ibt.sweeps))
```
```
ibt file name: demo
Number of sweeps: 28
```

### Accessing sweep data
```python
sweep = ibt.sweeps[0]
print('Recording mode:', sweep.rec_mode)
print('Sweep data:', sweep.data)
print('Recording mode:', sweep.y_label)
print('Sweep time:', sweep.time)
print('Recording mode:', sweep.x_label)
print('Sweep command:', sweep.command)
```
```
Recording mode: current clamp
Sweep data: [-63.18666667 -62.98666667 -62.89333333 ... -62.98666667 -62.98666667 -63.18666667]
Recording mode: Membrane Potential (mV)
Sweep time: [0.0000e+00 2.0000e-05 4.0000e-05 ... 9.9994e-01 9.9996e-01 9.9998e-01]
Recording mode: Time (seconds)
Sweep command: [0. 0. 0. ... 0. 0. 0.]
```

### Quick plot functions
```python
fig = plt.figure(figsize=(8, 7))
ax1 = fig.add_subplot(211)
ax1 = ibt.plot_sweep(sweep_num=16, ax=ax1)

ax2 = fig.add_subplot(212)
ax2 = ibt.plot_command(sweep_num=16, ax=ax2)
```
![docs/example_plots/single_sweep.png](docs/example_plots/single_sweep.png)
```python
fig = plt.figure(figsize=(5, 5))
ax=ibt.plot_sweep_phase_plane(sweep_num=16)
ax.set_xlim(-50, 60)
```
![docs/examples/example_plots/phase_plane.png](docs/example_plots/phase_plane.png)
```python
fig=plt.figure(figsize=(8,5))
ax=ibt.plot_all_sweeps()
```
![docs/examples/example_plots/all_sweeps.png](docs/example_plots/all_sweeps.png)
### Get Creative
```python
sweeps = ibt.sweeps[9:25]
cm = plt.get_cmap("winter")
colors = [cm(i/len(sweeps)) for i, x in enumerate(sweeps)]

plt.figure(figsize=(12, 8))
for i, sweep in enumerate(sweeps):
    num_pnts = int(0.5/sweep.dx)
    x = sweep.time[:num_pnts] + 0.02 * i
    y = sweep.data[:num_pnts] + 10 * i
    plt.plot(x, y, color=colors[i], alpha=0.5)
plt.gca().axis('off')
```
![docs/examples/example_plots/fancy_FI_curve.png](docs/example_plots/fancy_FI_plot.png)

### Automatic detection of action potentials
```Python
command = 4
sweeps = ibt.sweeps[9:25]

num_APs = []
current = []
for sweep  in sweeps:
    num_APs.append(len(sweep.spike_times_during_command(command)))
    current.append(sweep.commands[4]['value'])

fig=plt.figure(figsize=(8, 5))
plt.plot(current, num_APs, '-o', markersize=10)
plt.ylabel('Number of Action potentials')
plt.xlabel('Applied current (pA)')
plt.savefig('example_plots/FI_curve.png')
```
![docs/examples/example_plots/FI_curve.png](docs/example_plots/FI_curve.png)

```Python
import numpy as np

sweep = ibt.sweeps[25]
spikes = sweep.spike_properties()

spike_num = [x for x in range(len(spikes))]
spike_height = [spike['height'] for spike in spikes]
spike_width = [spike['half_width'] for spike in spikes]
spike_thresh = [spike['thresh'] for spike in spikes]
spike_dVdt = [spike['peak_dVdt'] for spike in spikes]

fig = plt.figure(figsize=(12, 8))

ax1 = fig.add_subplot(231)
ax1.set_ylabel('Membrane Potential (mV)')
ax1.set_xlabel('Time (ms)')

ax4 = fig.add_subplot(234)
ax4.set_ylabel('dVdt (V/s')
ax4.set_xlabel('Membrane Potential (mV)')

cm=plt.cm.magma
colors = [cm(i/len(sweeps)) for i, x in enumerate(sweeps)]
for i, spike in enumerate(spikes):
    ax1.plot(spike['time'] * 1000, spike['Vm'], color=colors[i])

    dVdt = np.gradient(spike['Vm'], spike['time'])/1000
    ax4.plot(spike['Vm'], dVdt, color=colors[i])

ax2 = fig.add_subplot(232)
ax2.set_ylabel('AP half width (ms)')
ax2.set_xlabel('AP number')
ax2.set_xticks(spike_num)
ax2.plot(spike_num,spike_width, '-o', markersize=8, color='tab:blue')

ax3 = fig.add_subplot(233, sharex=ax2)
ax3.set_ylabel('AP Height (mV)')
ax3.set_xlabel('AP number')
ax3.plot(spike_num,spike_height, '-o', markersize=8, color='tab:orange')

ax2 = fig.add_subplot(235, sharex=ax2)
ax2.set_ylabel('Threshold (mV)')
ax2.set_xlabel('AP number')
ax2.plot(spike_num,spike_thresh, '-o', markersize=8, color='tab:green')

ax3 = fig.add_subplot(236, sharex=ax2)
ax3.set_ylabel('dVdt (V/s)')
ax3.set_xlabel('AP number')
ax3.plot(spike_num,spike_dVdt, '-o', markersize=8, color='tab:red')
```
![docs/examples/example_plots/AP_char.png](docs/example_plots/AP_char.png)

**Details of the ibt file structure can be found** [here](docs/ibt_structure.md)

pyibt was inspired by the [pyABF module written by Scott Harden](https://github.com/swharden/pyABF) for Axon Binary Format (ABF) files.

## Author 

**Perry Spratt**\
PhD Candidate, [Bender Lab](https://benderlab.ucsf.edu/lab-members)\
University of California, San Francisco\
perrywespratt@gmail.com
