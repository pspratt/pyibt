## Structure of ECCELES IBT files

### File Open:
- 2 bytes (int):    IBT file magic number – should be 11
- 4 bytes (int):    pointer to first sweep
- 4 bytes (float):  absolute time of first sweep
- 20 bytes (str):   name of y axis units
- 20 bytes (str):   name of x axis units
- 20 bytes (str):   name of experiment

### Following pointer to first sweep:
- 2 bytes (int):    sweep magic numbers – should be 12
- 2 bytes (int):    sweep number
- 4 bytes (int):    number of data points in sweep
- 4 bytes (int):    scale factor
- 4 bytes (float):  amplifier gain
- 4 bytes (float):  sampling rate
- 4 bytes (float):  recording mode – 0 = OFF;  1 = current clamp;  2 = voltage clamp
- 4 bytes (float):  dx – time interval between data points
- 4 bytes (float):  sweep time
- 4 bytes (int):    command pulse 1 flag
- 8 bytes (float):  command pulse 1 value
- 8 bytes (float):  command pulse 1 start
- 8 bytes (float):  command pulse 1 duration
- 4 bytes (int):    command pulse 2 flag
- 8 bytes (float):  command pulse 2 value
- 8 bytes (float):  command pulse 2 start
- 8 bytes (float):  command pulse 2 duration
- 4 bytes (int):    command pulse 3 flag
- 8 bytes (float):  command pulse 3 value
- 8 bytes (float):  command pulse 3 start
- 8 bytes (float):  command pulse 3 duration
- 4 bytes (int):    command pulse 4 flag
- 8 bytes (float):  command pulse 4 value
- 8 bytes (float):  command pulse 4 start
- 8 bytes (float):  command pulse 4 duration
- 4 bytes (int):    command pulse 5 flag
- 8 bytes (float):  command pulse 5 value
- 8 bytes (float):  command pulse 5 start
- 8 bytes (float):  command pulse 5 duration
- 8 bytes (float):  DC command pulse flag
- 8 bytes (float):  DC command pulse value
- 4 bytes (float):  temperature
- 8 bytes: empty
- 4 bytes (int):    pointer to sweep data
- 4 bytes (int):    pointer to next sweep
- 4 bytes (int):    pointer to previous sweep

### Following pointer to sweep data:
- 2 bytes (int):    sweep data magic number - should be 13
- 2 bytes * number points (int): sweep data read 2 bytes per data point

sweep data needs to be divided by scale_factor, divided by amplifer gain, and multiplied by 1000
to be the correct value

byte order is little endian
