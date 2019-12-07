import struct
class ibt_sweep(object):
    """
    ibt_sweep Class:
    Object that allows for extracting and interacting with data stored in IBT file sweep headers created by ecceles anaylsis

    Attributes:
    ibt_File_Path
    sweep_num
    num_points
    scale_factor
    amp_gain
    sample_rate
    rec_mode
    y_label
    x_label
    command_label
    dx
    sweep_time
    commands
        flag
        value
        start
        duration
    DC_pulse_flag
    DC_pulse_value
    temperature
    sweep_data_pointer

    Properties:
    time
    data
    command
    dVdt

    Methods:
    time2index
    index2time
    get_time
    get_data
    get_command
    get_dVdt
    plot_sweep
    plot_sweep_command
    plot_phase_plane
    convert_start_and_duration
    """
    from pyibt.ibt_sweep._analysis import spike_times,\
                                        spike_properties,\
                                        spike_times_during_command,\
                                        spike_properties_during_command,\
                                        spike_properties_during_command,\
                                        Rin_from_command,\
                                        data_during_command,\
                                        calc_Rin,\
                                        detect_spike_times,\
                                        detect_spike_properties,\
                                        group_consecutives,\
                                        find_zero_crossing


    from pyibt.ibt_sweep._data_extraction import time2index,\
                                                index2time,\
                                                time,get_time,\
                                                data,\
                                                get_data,\
                                                command,\
                                                get_command,\
                                                get_dVdt,\
                                                convert_start_and_duration

    from pyibt.ibt_sweep._plot_methods import plot_sweep,\
                                            plot_response_to_command,\
                                            plot_sweep_command,\
                                            plot_phase_plane,\
                                            plot_spike

    def __init__(self, ibt_File_Path, sweep_header):
        with open(ibt_File_Path,"rb") as fb:
            #Check if the file is the correct type using the magic number
            magic_number = int.from_bytes(fb.read(2),byteorder='little',signed=1)
            if magic_number != 11: #check if the magic number matches ecceles file magic number
                raise Exception("This is not a valid igor sweep file")

            fb.seek(sweep_header) #go next sweep
            #check if we were sent to the right place
            magic_number = int.from_bytes(fb.read(2),byteorder='little')
            if magic_number != 12:
                raise Exception("Failed to find sweep")
            self.ibt_File_Path = ibt_File_Path
            self.sweep_num = int.from_bytes(fb.read(2),byteorder='little')
            self.num_points =  int(struct.unpack('<f', fb.read(4))[0]) #number of data points in the sweep
            self.scale_factor = int.from_bytes(fb.read(4),byteorder='little')
            self.amp_gain = struct.unpack('<f', fb.read(4))[0]
            self.sample_rate = struct.unpack('<f', fb.read(4))[0] * 1000 #specified in kHz. Convert to Hz for clarity

            rec_mode = struct.unpack('<f', fb.read(4))[0]
            if rec_mode == 1:
                self.rec_mode = 'current clamp'
                self.y_label = 'Membrane Potential (mV)'
                self.command_label = "Applied Current (pA)"
            elif rec_mode == 2:
                self.rec_mode = 'voltage clamp'
                self.y_label = 'Clamp Current (mV)'
                self.command_label = 'Command Voltage (mV)'
            else:
                self.rec_mode = 'OFF'
                self.y_label = 'Unknown'
                self.command_label = "Unknown"
            self.x_label = 'Time (seconds)'

            self.dx = 1/self.sample_rate
            struct.unpack('<f', fb.read(4))[0] #I think this is empty, supposed to be sample rate
            self.sweep_time = struct.unpack('<f', fb.read(4))[0]
            self.commands = []
            for num in range(5):
                command = {}
                command['number'] = num
                command['flag'] = int.from_bytes(fb.read(4),byteorder='little')
                command['value'] = struct.unpack('<d', fb.read(8))[0]
                command['start'] = struct.unpack('<d', fb.read(8))[0]/1000 #sec
                command['duration'] = struct.unpack('<d', fb.read(8))[0]/1000 #sec
                self.commands.append(command)

            self.DC_pulse_flag = struct.unpack('<d', fb.read(8))[0]
            self.DC_pulse_value  = struct.unpack('<d', fb.read(8))[0]
            self.temperature = struct.unpack('<f', fb.read(4))[0]
            fb.read(8) #unspecified Values
            self.sweep_data_pointer = int.from_bytes(fb.read(4),byteorder='little')

"""
Structure of Bender Lab IBT files

Based on code in ecceles analysis, IBTs appear to be custom binary files that have the following encoding:
File Open:
2 bytes: int IBT file magic number (should be 11)
4 bytes: int pointer to first sweep_pointer
4 bytes: float absolute time of first sweep_pointer
20 bytes: str name of y axis units
20 bytes: str name of x axis units
20 bytes: str name of experiment

Following pointer to first sweep:
2 bytes: int sweep magic numbers (should be 12)
2 bytes: int sweep number
4 bytes: int number of data points in sweep
4 bytes: int scale factor
4 bytes: float amplifier gain
4 bytes: float sampling rate
4 bytes: float recording mode – 0 = OFF;  1 = current clamp;  2 = voltage clamp
4 bytes: float dx – time interval between data points
4 bytes: float sweep time
4 bytes: int command pulse 1 flag
8 bytes: float command pulse 1 value
8 bytes: float command pulse 1 start
8 bytes: float command pulse 1 duration
4 bytes: int command pulse 2 flag
8 bytes: float command pulse 2 value
8 bytes: float command pulse 2 start
8 bytes: float command pulse 2 duration
4 bytes: int command pulse 3 flag
8 bytes: float command pulse 3 value
8 bytes: float command pulse 3 start
8 bytes: float command pulse 3 duration
4 bytes: int command pulse 4 flag
8 bytes: float command pulse 4 value
8 bytes: float command pulse 4 start
8 bytes: float command pulse 4 duration
4 bytes: int command pulse 5 flag
8 bytes: float command pulse 5 value
8 bytes: float command pulse 5 start
8 bytes: float command pulse 5 duration
8 bytes: float DC command pulse flag
8 bytes: float DC command pulse value
4 bytes: float temperature
8 bytes: empty
4 bytes: int pointer to sweep data
4 bytes: pointer to next sweep
4 bytes: pointer to previous sweep

following pointer to sweep data:
2 bytes: int sweep data magic number - should be 13
2 bytes * number points: int sweep data read 2 bytes per data point

sweep data needs to be divided by scale_factor, divided by amplifer gain, and multiplied by 1000
to be the correct value

byte order is little endian
"""
