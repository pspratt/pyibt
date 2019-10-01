"""
Demonstation of how to extract and interact with data in ibt files using pyibt
"""

"""
Extracting data into and IBT object
"""
import pyibt
ibt = pyibt.IBT('ps20190510b.ibt') #that's it! If file is not in current dir file path muse be specified

"""
Generating simple plots
"""
import matplotlib.pyplot as plt

#First, write a function to remove the annoying borders around matplotlib plots
def boxoff(ax):
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    return ax

#Plot every sweep in a ibt file
fig = plt.figure()
ax = ibt.plot_all_sweeps()
ax = boxoff(ax)
plt.savefig('plot_all_sweeps result.png')
plt.show()

#Plot every command in ibt file
fig = plt.figure()
ax = ibt.plot_all_sweep_commands()
ax = boxoff(ax)
plt.savefig('plot_all_sweep_commands result.png')
plt.show()

#plot a specific set_sweep
ibt.set_sweep(15)
fig = plt.figure()
ax = ibt.plot_sweep()
ax = boxoff(ax)
plt.savefig('plot_sweep result.png')
plt.show()

#plot a specific set_sweep_command
ibt.set_sweep(15)
fig = plt.figure()
ax = ibt.plot_sweep_command()
ax = boxoff(ax)
plt.savefig('plot_sweep_command result.png')
plt.show()

#plot phase-plane
fig = plt.figure()
ax = ibt.plot_phase_plane()
ax = boxoff(ax)
plt.savefig('plot_phase_plane result.png')
plt.show()

#Get fancy
fig = plt.figure(figsize=(8,8))
ax = plt.gca()

sweeps = [9,11,13,15,17,19,21]
for i, sweep in enumerate(sweeps):
    ibt.set_sweep(sweep)

    start_idx = 0
    end_idx = int(0.5 * ibt.sweep_points_per_sec)

    x = ibt.sweep_X[start_idx:end_idx] + .025 * i
    y = ibt.sweep_Y[start_idx:end_idx] + 25 * i
    ax.plot(x,y,color='C0', alpha=.5)

ax.axis('off')
plt.savefig('fancy plot.png')
plt.show()
