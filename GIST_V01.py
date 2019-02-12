# GIST2.0
import pandas as pd
import numpy as np
from sklearn.svm import SVR
import functools
import matplotlib.pyplot as plt
import seaborn as sns

#import data
path = r'C:\Users\liqian\Dropbox (UFL)\Project_QL\2018-CancerTrial-Generalizability\Data0'
TP_f = pd.read_csv(path+'\\CRC_Lab_1205.csv', sep=',', header=None)

#set variable names
TP_f.columns = [
'birth_date',
'dx_age',
'sex',
'hispanic',
'race',
'zip_code',
'source',
'dx',
'platelet',
'plt_unit',
'bilirubin',
'bb_unit',
'creatinine_serum',
'ct_unit'
]

TP = TP_f[[
'birth_date',
'dx_age',
'sex',
'hispanic',
'race',
'zip_code',
'source',
'dx',
'bilirubin',
'creatinine_serum']].dropna()

# set category variables type
for col in [
'sex',
'hispanic',
'race',
'zip_code',
'source',
'dx'
]:
    TP[col] = TP[col].astype('category')


# Eligibility class
class Elig:
    def __init__(self,
                 var_name: str = None,
                 is_range: bool = True,
                 low_bound: float = None,
                 upp_bound: float = None,
                 equal_to: float = None):
        self.var_name = var_name
        self.is_range = is_range
        self.low_bound = low_bound
        self.upp_bound = upp_bound
        self.equal_to = equal_to
    
    def get_elig(self, data):
        if self.is_range:
            if self.low_bound is None and self.upp_bound is not None:
                elig_status = (data[self.var_name] <= self.upp_bound)
            if self.low_bound is not None and self.upp_bound is None:
                elig_status = (data[self.var_name] >= self.low_bound)
            if self.low_bound is not None and self.upp_bound is not None:
                elig_status = ((data[self.var_name] >= self.low_bound) & (data[self.var_name] <= self.upp_bound))
        else:
            elig_status = (data[self.var_name] == self.equal_to)
        return elig_status
    
    def get_stringency(self, data):
        if self.is_range:
            elig_n = data.loc[(data[self.var_name] >= self.low_bound) & (data[self.var_name] <= self.upp_bound), self.var_name].shape[0]
        else:
            elig_n = data.loc[(data[self.var_name] == self.equal_to), self.var_name].shape[0]
        stringency = 1 - elig_n / data.shape[0]
        return max(stringency, 0.01)
    
    def get_gist(self, data):
        gist = sum(data.loc[self.get_elig(data), 'f_weight']) / sum(data.f_weight)
        return gist

# Set eligibility
dxage_elig = Elig(var_name = 'dx_age', low_bound = 55, upp_bound = 70)
bilirubin_elig = Elig(var_name = 'bilirubin', upp_bound = 1.5)
creatinine_elig = Elig(var_name = 'creatinine_serum', upp_bound = 2.0)

# Put the eligibility you want to use to calculate GIST into the list
cate_elig_list = []
cont_elig_list = [dxage_elig, bilirubin_elig, creatinine_elig]
elig_list = cate_elig_list + cont_elig_list

# Calculation start
# 1.normalizing all the continuous features
for col in TP._get_numeric_data().columns:
    TP[col+'_z'] = (TP[col] - np.mean(TP[col]))/np.std(TP[col])

# 2.calculate stringency for each eligibility
for elig in cont_elig_list:
    elig.get_stringency(TP)

# 3. apply stringency to normalized values
for elig in cont_elig_list:
    TP[elig.var_name+'_z_s'] = elig.get_stringency(TP) * TP[elig.var_name+'_z']

# 4. build svm regression model and calculate residual
x = TP[['bilirubin_z_s','creatinine_serum_z_s']]
y = np.array(TP.dx_age_z_s)
gist_svm = SVR()
gist_svm.fit(x, y)
y_pred = gist_svm.predict(x)
TP['f_weight'] = 1 / (1+abs(y_pred - y))

# 5. Calculate single GIST score
for elig in elig_list:
    print(elig.var_name, ': ', elig.get_gist(TP))

# 6. Calculate multi GIST score
mgist_e_list = [e.get_elig(TP) for e in elig_list]
mgist_e_subset = functools.reduce(lambda x, y: x&y, mgist_e_list)
gmulti = sum(TP.loc[mgist_e_subset, 'f_weight']) / sum(TP.f_weight)
print('mGIST: ',gmulti)

