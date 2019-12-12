"""
Demonstation of how to extract and interact with data in ibt files using pyibt
"""

"""
Extracting data into and IBT object
"""
from pyibt import read_ibt
ibt = read_ibt('ps20190510b.ibt')

"""
Define matplotlib defaults
"""
import matplotlib.pyplot as plt
plt.rcParams['axes.spines.right'] = False
plt.rcParams['axes.spines.top'] = False
plt.rcParams['font.sans-serif'] = "Arial"
plt.rcParams['font.family'] = "sans-serif"
plt.rcParams['pdf.fonttype'] = 42
plt.rcParams['ps.fonttype'] = 42

tick_major = 6
tick_minor = 4
plt.rcParams["xtick.major.size"] = tick_major
plt.rcParams["xtick.minor.size"] = tick_minor
plt.rcParams["ytick.major.size"] = tick_major
plt.rcParams["ytick.minor.size"] = tick_minor

font_small = 12
font_medium = 13
font_large = 14
plt.rc('font', size=font_small)          # controls default text sizes
plt.rc('axes', titlesize=font_medium)    # fontsize of the axes title
plt.rc('axes', labelsize=font_medium)    # fontsize of the x and y labels
plt.rc('xtick', labelsize=font_small)    # fontsize of the tick labels
plt.rc('ytick', labelsize=font_small)    # fontsize of the tick labels
plt.rc('legend', fontsize=font_small)    # legend fontsize
plt.rc('figure', titlesize=font_large)   # fontsize of the figure title

"""
Lets make some plots
"""
#Lets plot every sweep in the ibt file
fig=plt.figure();ax=plt.gca()
ax=ibt.plot_all_sweeps(ax=ax)

#Lets plot every command in the ibt file
fig=plt.figure();ax=plt.gca()
ax=ibt.plot_all_commands(ax=ax)

#Plot a single sweep
fig=plt.figure()
ax1=fig.add_subplot(211)
ibt.plot_sweep(16,ax=ax1)
ax1.set_ylabel('mV')

ax2=fig.add_subplot(212)
ax2.set_ylabel('pA')
ibt.plot_command(16,ax=ax2)

#plot sweep plot_phase_plane
fig=plt.figure();ax=plt.gca()
ax=ibt.plot_sweep_phase_plane(16,pipette_offset=-12,ax=ax)
