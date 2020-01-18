"""
TODO:
Add additional test cells, include cells for voltage clamp
Add matplotlib tests
add code for verifying that a command is active, add tests for this
"""

import unittest
import os
from pyibt.read_ibt import read_ibt

class test_sweep(unittest.TestCase):

    def setUp(self):
        path = os.path.dirname(os.path.abspath(__file__))
        ibt = read_ibt(path + '/test_cell.ibt')
        self.sweeps = ibt.sweeps

    def tearDown(self):
        pass

    def test_sweep(self):
        self.assertEqual(len(self.sweeps[25].data), self.sweeps[25].num_points)
        self.assertEqual(len(self.sweeps[25].command), self.sweeps[25].num_points)
        self.assertEqual(len(self.sweeps[25].time), self.sweeps[25].num_points)
        self.assertEqual(self.sweeps[25].rec_mode, 'current clamp')

    def test_time2index(self):
        with self.assertRaises(Exception):
            self.sweeps[25].time2index(time=-1)
        with self.assertRaises(Exception):
            self.sweeps[25].time2index(time=2)
        self.assertEqual(self.sweeps[25].time2index(self.sweeps[25].time[-1]),49999)
        self.assertEqual(self.sweeps[25].time2index(self.sweeps[25].time[0]),0)

    def test_index2time(self):
        with self.assertRaises(Exception):
            self.sweeps[25].index2time(time=-1)
        with self.assertRaises(Exception):
            self.sweeps[25].index2time(time=50001)
        self.assertEqual(self.sweeps[25].index2time(len(self.sweeps[25].time)-1),0.99998)
        self.assertEqual(self.sweeps[25].index2time(0),0)

    def test_spike_times(self):
        spike_times = self.sweeps[25].spike_times()
        self.assertEqual(len(spike_times),14)
        self.assertEqual(spike_times[0],0.06)
        self.assertEqual(spike_times[-1],0.33062)

    def test_spike_times_during_command(self):
        spike_times = self.sweeps[25].spike_times_during_command(4)
        self.assertEqual(len(spike_times),14)
        self.assertEqual(spike_times[0],0.009999999999999995)
        self.assertEqual(spike_times[-1],0.28062000000000004)

    def test_spike_properties(self):
        spikes = self.sweeps[25].spike_properties()
        self.assertEqual(len(spikes),14)
        self.assertEqual(len(spikes[0]['Vm']),105)
        self.assertEqual(spikes[0]['start_time'],0.06)
        self.assertEqual(spikes[0]['peak_dVdt'],647.0000000000264)

    def test_spike_properties_during_command(self):
        spikes = self.sweeps[25].spike_properties_during_command(4)
        self.assertEqual(len(spikes),14)
        self.assertEqual(len(spikes[0]['Vm']),105)
        self.assertEqual(spikes[0]['start_time'],0.06)
        self.assertEqual(spikes[0]['peak_dVdt'],647.0000000000264)

    def test_Rin_from_command(self):
        self.assertEqual(self.sweeps[9].Rin_from_command(4),102.95866666666682)

    def test_data_during_command(self):
        self.assertEqual(len(self.sweeps[9].data_during_command(4)[0]),15000)
        self.assertEqual(len(self.sweeps[9].data_during_command(4)[1]),15000)


if __name__ == '__main__':
    print(os.path.abspath((os.getcwd())))
    unittest.main()
