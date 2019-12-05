import matplotlib.pyplot as plt

def plot_all_sweeps(self, ax=[], color='k', ylim=(-150,50)):
    if ax == []:
        ax = plt.gca()

    for sweep_num in range(len(self.sweeps)):
        sweep = self.sweeps[sweep_num]
        ax.plot(sweep.time, sweep.data, color=color)

    ax.set_ylim(ylim)
    ax.set_ylabel(sweep.y_label)
    ax.set_xlabel(sweep.x_label)
    return ax

def plot_all_commands(self, ax=[], color='k', ylim=(-150,50)):
    if ax == []:
        ax = plt.gca()

    for sweep_num in range(len(self.sweeps)):
        sweep = self.sweeps[sweep_num]
        ax.plot(sweep.time, sweep.command, color=color)

    ax.set_ylim(ylim)
    ax.set_ylabel(sweep.command_label)
    ax.set_xlabel(sweep.x_label)
    return ax
