"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
Methods for accessing data in ibt_sweep objects
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""
import numpy as np

def time2index(self,time):
    t = self.time
    if time < 0:
        raise Exception("Time must be greater than zero")
    elif time > t[-1]:
        raise Exception("Time exceeds max time in sweep")

    return np.argmin(np.abs(t-time))

def index2time(self,index):
    t = self.time
    if index < 0:
        raise Exception("Index must be greater than zero")
    elif index > len(t):
        raise Exception("Index exceeds sweep length")
    return self.t[index]

@property
def time(self):
    sigfigs = int(np.floor(np.log10(1/self.dx)))+1
    time = np.round(np.asarray(range(0,self.num_points))*self.dx,sigfigs)
    return time
    """
    Note: rounding is to avoid floating errors
    """

def get_time(self,start=0,duration=[],absolute=True):
    start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
    time = self.time[start_pnt:start_pnt+num_pnts]
    if not absolute:
        time = time-time[0]
    return time

@property
def data(self):
    return self.get_data()

def get_data(self, start=0, duration=[]):
    start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
    with open(self.ibt_File_Path,"rb") as fb:
        fb.seek(self.sweep_data_pointer) #go to sweep data
        magic_number = int.from_bytes(fb.read(2),byteorder='little')
        if magic_number != 13: #check if we went to the correct place
            print("incorrect sweep byte address")
        else:
            fb.seek(self.sweep_data_pointer+2 + start_pnt*2)
            data = []
            for i in range(num_pnts):
                data.append((int.from_bytes(fb.read(2),byteorder='little',signed=1)/
                               self.scale_factor/self.amp_gain)*1000)
            return np.asarray(data)

@property
def command(self):
    return self.get_command()

def get_command(self,start=0,duration=[]):
    start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
    comm = np.zeros(shape=(self.num_points,))
    for command in self.commands:
        if command['flag']:
            comm_start = self.time2index(command['start'])
            comm_num_pts = self.time2index(command['duration'])
            comm_end = comm_start+comm_num_pts
            comm[comm_start:comm_end] = comm[comm_start:comm_end]+command['value']
    return comm[start_pnt:start_pnt+num_pnts]

@property
def dVdt(self):
    return self.get_dVdt()

def get_dVdt(self,start=0,duration=[]):
    start_pnt, num_pnts = self.convert_start_and_duration(start,duration)
    return np.gradient(self.data,self.time)/1e3

def convert_start_and_duration(self,start,duration):
    if not duration: #if no duration specified, set for length of sweep
        num_pnts = self.num_points
    else:
        num_pnts = self.time2index(duration)
    start_pnt = self.time2index(start)

    #Ensure requested points are within the limits of the sweep
    if num_pnts < 1:
        raise Exception("duration must be greater than {}".format(self.dx))
    elif start < 0:
        raise Exception("start must be greater than 0")
    elif start_pnt + num_pnts > self.num_points:
        raise Exception("Requested range exceeds sweep length")

    return start_pnt, num_pnts
