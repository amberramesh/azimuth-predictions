import pandas as pd
import sys

data = pd.read_csv(sys.argv[1],sep='\t')

data = data.drop(0,axis=0)

data = data.drop('donor.hubmap_id',axis=1)

data.to_csv('datasets.csv',header=False,index=False,columns=['hubmap_id','uuid'])