import matplotlib.pyplot as plt

def plot_sweep(self,sweep_num=0,color='k',ax=[]):
    if ax == []:
        ax = plt.gca()
    ax = self.sweeps[sweep_num].plot_sweep(ax=ax, color=color)
    return ax

def plot_sweep_phase_plane(self,sweep_num=0,pipette_offset=0,color='k',ax=[]):
    if ax == []:
        ax = plt.gca()
    ax = self.sweeps[sweep_num].plot_phase_plane(ax=ax, pipette_offset=pipette_offset,color=color)
    return ax

def plot_command(self,sweep_num=0,color='k',ax=[]):
    if ax == []:
        ax = plt.gca()
    ax = self.sweeps[sweep_num].plot_command(ax=ax, color=color)
    return ax

def plot_sweeps(self, sweep_nums = [],ax=[], color='k'):
    if ax == []:
        ax = plt.gca()
    for sweep_num in sweep_nums:
        ax = self.sweeps[sweep_num].plot_sweep(ax=ax, color=color)
    return ax

def plot_commands(self, sweep_nums = [],ax=[], color='k'):
    if ax == []:
        ax = plt.gca()
    for sweep_num in sweep_nums:
        ax = self.sweeps[sweep_num].plot_command(ax=ax, color=color)
    return ax

def plot_all_sweeps(self, ax=[], color='k'):
    if ax == []:
        ax = plt.gca()
    for sweep_num in range(len(self.sweeps)):
        ax = self.sweeps[sweep_num].plot_sweep(ax=ax, color=color)
    return ax

def plot_all_commands(self, ax=[], color='k'):
    if ax == []:
        ax = plt.gca()

    for sweep_num in range(len(self.sweeps)):
        sweep = self.sweeps[sweep_num]
        ax.plot(sweep.time, sweep.command, color=color)
    return ax
