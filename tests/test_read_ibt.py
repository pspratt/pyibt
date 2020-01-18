
# TODO(pspratt): Register github with travis-ci.org for integration testing

"""
TODO:
Add tests for
command check functions
average sweeps
p_n_subtraction
plotting
"""
import unittest
import os
from pyibt import read_ibt

class test_read_ibt(unittest.TestCase):

    def setUp(self):
        path = os.path.dirname(os.path.abspath(__file__))
        self.ibt = read_ibt(path + '/test_cell.ibt')

    def test_read_ibt(self):
        self.assertEqual(self.ibt.name,'test_cell')
        self.assertEqual(len(self.ibt.sweeps),28)

if __name__ == '__main__':
    print(os.path.abspath((os.getcwd())))
    unittest.main()
