
import unittest
import pandas as pd
import numpy as np
import os
import sys
file_dir = os.getcwd()
sys.path.append(file_dir)

from reporting import clean

class TestReporting(unittest.TestCase):

    def setUp(self):
        pass

    #checks that the column in the clean dataframe has more zeros. this will fail if the cutoff is made too small in the clean function
    def testClean_moreZeros(self):
        df = pd.DataFrame(data=np.arange(10 ** 7) / 10 ** 6, columns=['r'])
        df_clean = clean(df,'r')
        self.assertTrue(df.loc[df['r']==0]['r'].count() < df_clean.loc[df_clean['r']==0]['r'].count() )

    # check that the function does not change the input dataframe
    def testClean_originalUnchanged(self):
        df = pd.DataFrame(data=np.arange(10**7) / 10**6, columns=['r'])
        df_copy = df.copy()
        df_copy_clean = clean(df_copy,'r')
        self.assertTrue(df.equals(df_copy))


if __name__ == '__main__':
    unittest.main()


