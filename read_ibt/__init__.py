import os
import struct
from datetime import datetime
from dateutil.relativedelta import relativedelta
import pytz
from pyibt.ibt_sweep import ibt_sweep

def read_ibt(ibt_File_Path):
    '''
    Wrapper for the ibt object class
    '''
    return ibt(ibt_File_Path)

class ibt(object):
    """
    ibt class:
    Object that allows for extracting and interacting with data stored in IBT files
    created by ecceles anaylsis

    Attributes:
    sweeps: list of sweep objecst
    exp_details: dictionary containing ibt metadata
    ibt_path: path to the imported ibt files
    ibt_name: name of the ibt files
    sweep_list: list of sweep numbers in ibt files
    num_sweeps: number of sweeps in ibt files
    """
    from pyibt.read_ibt._plot_methods import plot_all_sweeps, plot_all_commands
    from pyibt.read_ibt._analysis import find_sweeps_with_command,check_sweep_commands

    def __init__(self, ibt_File_Path):

        #Check if file paths and filenames exists
        if os.path.exists(ibt_File_Path):
            self.ibt_File_Path = ibt_File_Path
        elif os.path.exists(ibt_File_Path + '.ibt'): #see if .ibt extension was left off
            self.ibt_File_Path = ibt_File_Path + '.ibt'
        else:
            raise ValueError("IBT file does not exist: %s" % ibt_File_Path)

        self.ibt_name = os.path.splitext(os.path.basename(self.ibt_File_Path))[0]

        #Get experiment details and sweep headers
        self.exp_details = get_experiment_details(self.ibt_File_Path)
        self._sweep_headers = get_sweep_headers(self.ibt_File_Path)

        #parse sweep headers to get sweep objects
        self.sweeps = []
        for sweep_header in self._sweep_headers:
            self.sweeps.append(ibt_sweep(self.ibt_File_Path, sweep_header))

def get_sweep_headers(ibt_File_Path):
    '''
    Function returns sweep heads of ibt file specified by ibt_File_Path
    '''
    sweep_pointers = []

    with open(ibt_File_Path,"rb") as fb:
        magic_number = int.from_bytes(fb.read(2),byteorder='little',signed=1)
        if magic_number != 11: #check if the magic number matches ecceles file magic number
            raise Exception("This is not a valid igor sweep file")

        EOF = False
        next_sweep_pointer = int.from_bytes(fb.read(4),byteorder='little')
        while not EOF:
            fb.seek(next_sweep_pointer)
            magic_number = int.from_bytes(fb.read(2),byteorder='little')
            if magic_number != 12:
                raise Exception("Failed to find sweep")

            sweep_pointers.append(next_sweep_pointer)

            fb.seek(next_sweep_pointer+204)
            next_sweep_pointer = int.from_bytes(fb.read(4),byteorder='little')

            if next_sweep_pointer == 0:
                EOF = True # This is the final sweep in the linked list
                return sweep_pointers

def get_experiment_details(ibt_File_Path):
    with open(ibt_File_Path,"rb") as fb:
        #Check if the file is the correct type using the magic number
        magic_number = int.from_bytes(fb.read(2),byteorder='little',signed=1)
        if magic_number != 11: #check if the magic number matches ecceles file magic number
            raise Exception("This is not a valid igor sweep file")
        next_sweep_pointer = int.from_bytes(fb.read(4),byteorder='little') # pointer to the first sweep
        exp_details = {}
        unix_timestamp = struct.unpack('<f', fb.read(4))[0]
        date_obj = datetime.fromtimestamp(unix_timestamp)
        #ibt files seem to be consistently 66 years off
        date_obj = date_obj-relativedelta(years=66)
        # date_obj = pytz.utc.localize(date_obj)
        # date_obj = date_obj.astimezone(pytz.timezone("America/Los_Angeles"))

        exp_details["exp_date"] = date_obj.strftime('%Y/%m/%d')
        exp_details["exp_time"] = date_obj.strftime('%H:%M:%S')
        exp_details["y_axis_label"] = fb.read(20).decode('utf-8')
        exp_details["x_axis_label"] = fb.read(20).decode('utf-8')
        exp_details["exp_name"] = fb.read(20).decode('utf-8')
    return exp_details
