"""
Tests to ensure that read_ibt can load ibt files

TODO:
command check functions
average sweeps
p_n_subtraction
plotting
"""

import unittest
import os
import sys
try:
    #  ensure pyIBT is imported from this specific path
    sys.path.insert(0, "src")
    from pyibt.read_ibt import Read_IBT
except:
    raise ImportError("could not import local pyABF")

class test_read_ibt(unittest.TestCase):

    def setUp(self):
        path = os.path.dirname(os.path.abspath(__file__))
        self.ibt = Read_IBT(path + '/data/test_cell.ibt')

    def test_read_ibt(self):
        self.assertEqual(self.ibt.name,'test_cell')
        self.assertEqual(len(self.ibt.sweeps),28)

if __name__ == '__main__':
    print(os.path.abspath((os.getcwd())))
    unittest.main()
