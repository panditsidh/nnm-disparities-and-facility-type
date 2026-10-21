/********************************************************************
NATIONAL HEALTH PROFILE 2019
STATE-LEVEL HEALTH SYSTEM DATA

Tables:
    5.1
    5.6
    6.2.1
    6.2.2
********************************************************************/

clear all
set more off


/********************************************************************
TABLE 5.1
REGISTERED ALLOPATHIC DOCTORS
********************************************************************/

clear

input str30 state registered_doctors_2018 registered_doctors_total2018

"Andhra Pradesh"       3756 100587
"Arunachal Pradesh"      94    973
"Assam"                 654  23804
"Bihar"                   .  40649
"Chhattisgarh"          774   8771
"Delhi"                2801  21394
"Goa"                   193   3840
"Gujarat"              3608  66944
"Haryana"                 .   5717
"Himachal Pradesh"        .   3054
"Jammu & Kashmir"       623  15038
"Jharkhand"             402   5764
"Karnataka"            5301 120261
"Madhya Pradesh"       1556  38180
"Maharashtra"          3360 173384
"Mizoram"                16     74
"Nagaland"               25    116
"Odisha"                  .  22521
"Punjab"                695  48351
"Rajasthan"            2525  43388
"Sikkim"                128   1405
"Tamil Nadu"           7167 133918
"Kerala"               1503  59353
"Uttar Pradesh"        2718  77549
"Uttarakhand"           928   8309
"West Bengal"          2544  72016
"Tripura"                 .   1718
"Telangana"               .   4942
end

tempfile doctors
save `doctors'


/********************************************************************
TABLE 5.6
RURAL GOVERNMENT HEALTH HUMAN RESOURCES
AS OF 31.03.2018
********************************************************************/

clear

input str30 state ///
    doctors_phc ///
    specialists_chc ///
    healthassist_male ///
    healthassist_female ///
    healthworker_male ///
    healthworker_anm

"Andhra Pradesh"       2045 384    0 1172 2959 13698
"Arunachal Pradesh"     125   4   81    6   92   481
"Assam"                1376 158  106  308 2665 10230
"Bihar"                1786  82  212   95 1244 23390
"Chhattisgarh"          359  57  406  713 3933  6799
"Goa"                    56  10    0    9   86   273
"Gujarat"              1321 118  826  851 7755  8340
"Haryana"               491  17  107  268 1291  4374
"Himachal Pradesh"      622   4   38    0  799  1846
"Jammu & Kashmir"       694 256   44   94  657  4582
"Jharkhand"             340  92   33   19 1684  6632
"Karnataka"            2136 498 3645 1089 3645  7156
"Kerala"               1169  40 2197   13 3401  7950
"Madhya Pradesh"       1112 248  543 1314 3248 12353
"Maharashtra"          2929 485 1620 1628 4570 14605
"Manipur"               194   3   65   59  374   923
"Meghalaya"             130   9   85  106  209  1080
"Mizoram"                59   0   22   19  337   629
"Nagaland"              118   8    0    0    .   913
"Odisha"                917 253    0  528 3344  8108
"Punjab"                480 105  289  444 1318  4525
"Rajasthan"            2396 565   36 1344 1486 18257
"Sikkim"                 24   0    7   14   77   227
"Tamil Nadu"           2780 210  721 1058 2288  7854
"Telangana"            1066 112    0  944 1363  7679
"Tripura"               119   2   14    0  674   601
"Uttar Pradesh"        1344 192  131 3129 1543 25751
"Uttarakhand"           241  29   18  127   65  1760
"West Bengal"          1016 125  113  277 2848 17583
"Andaman & Nicobar"      34   0   11   20   45   274
"Chandigarh"              0   0    0    0    5    33
"Dadra & Nagar Haveli"    8   0    0    0   63    90
"Daman & Diu"             4   3    2    1    6    34
"Delhi"                  22   0    0   11   11    33
"Lakshadweep"             8   0    0    1   14    51
"Puducherry"             46   5   34   12    0   212
end

tempfile rural_hr
save `rural_hr'


/********************************************************************
TABLE 6.2.1
SUBCENTRES, PHCs, AND CHCs
AS OF 31.03.2018
********************************************************************/

clear

input str30 state subcentres phcs chcs

"Andhra Pradesh"        7458 1147 193
"Arunachal Pradesh"      312  143  63
"Assam"                 4644  946 172
"Bihar"                 9949 1899 150
"Chhattisgarh"          5200  793 169
"Goa"                    214   25   4
"Gujarat"               9153 1474 363
"Haryana"               2589  368 113
"Himachal Pradesh"      2084  576  91
"Jammu & Kashmir"       2967  637  84
"Jharkhand"             3848  298 171
"Karnataka"             9443 2359 206
"Kerala"                5380  849 227
"Madhya Pradesh"       11192 1171 309
"Maharashtra"          10638 1823 361
"Manipur"                429   91  23
"Meghalaya"              443  108  28
"Mizoram"                370   57   9
"Nagaland"               396  126  21
"Odisha"                6688 1288 377
"Punjab"                2950  432 151
"Rajasthan"            14405 2078 588
"Sikkim"                 147   24   2
"Tamil Nadu"            8712 1421 385
"Telangana"             4744  643  91
"Tripura"               1020  108  22
"Uttarakhand"           1847  257  67
"Uttar Pradesh"        20521 3621 822
"West Bengal"          10357  913 348
"Andaman & Nicobar"      123   22   4
"Chandigarh"              17    0   0
"Dadra & Nagar Haveli"    71    9   2
"Daman & Diu"             26    4   2
"Delhi"                   12    5   0
"Lakshadweep"             14    4   3
"Puducherry"              54   24   3
end

tempfile facilities
save `facilities'


/********************************************************************
TABLE 6.2.2
GOVERNMENT HOSPITALS AND BEDS
********************************************************************/

clear

input str30 state ///
    rural_gov_hospitals ///
    rural_gov_beds ///
    urban_gov_hospitals ///
    urban_gov_beds ///
    total_gov_hospitals ///
    total_gov_beds ///
    reference_year

"Andhra Pradesh"        193  6480  65 16658  258 23138 2017
"Arunachal Pradesh"     208  2136  10   268  218  2404 2018
"Assam"                1176 10944  50  6198 1226 17142 2017
"Bihar"                1032  5510 115  6154 1147 11664 2018
"Chhattisgarh"          169  5070  45  4342  214  9412 2016
"Goa"                    18  1397  25  1615   43  3012 2018
"Gujarat"               363 11688  75  8484  438 20172 2018
"Haryana"               609  6690  59  4550  668 11240 2016
"Himachal Pradesh"      705  5665  96  6734  801 12399 2017
"Jammu & Kashmir"        35  1221 108  6070  143  7291 2018
"Jharkhand"             519  5842  36  4942  555 10784 2015
"Karnataka"            2467 21176 375 48545 2842 69721 2018
"Kerala"                981 16865 299 21139 1280 38004 2017
"Madhya Pradesh"        330  9900 135 21206  465 31106 2018
"Maharashtra"           273 12398 438 39048  711 51446 2015
"Manipur"                23   730   7   697   30  1427 2014
"Meghalaya"             143  1970  14  2487  157  4457 2017
"Mizoram"                56   604  34  1393   90  1997 2017
"Nagaland"               21   630  15  1250   36  1880 2015
"Odisha"               1655  6339 151 12180 1806 18519 2018
"Punjab"                510  5805 172 12128  682 17933 2017
"Rajasthan"            2090 12540 760 34514 2850 47054 2018
"Sikkim"                 24   260   9  1300   33  1560 2017
"Tamil Nadu"            692 40179 525 37353 1217 77532 2017
"Telangana"             802  7668  61 13315  863 20983 2017
"Tripura"               130  1982  26  2447  156  4429 2018
"Uttar Pradesh"        4442 39104 193 37156 4635 76260 2017
"Uttarakhand"           410  3284  50  5228  460  8512 2015
"West Bengal"          1272 19684 294 58882 1566 78566 2015
"Andaman & Nicobar"      27   575   3   500   30  1075 2016
"Chandigarh"              0     0   9  3756    9  3756 2018
"Dadra & Nagar Haveli"   11   303   1   316   12   619 2018
"Daman & Diu"             5   240   0     0    5   240 2015
"Delhi"                   0     0 109 24383  109 24383 2015
"Lakshadweep"             9   300   0     0    9   300 2016
"Puducherry"              3    96  11  3473   14  3569 2016
end

tempfile beds
save `beds'


/********************************************************************
MERGE TABLES
********************************************************************/

use `rural_hr', clear

merge 1:1 state using `facilities'
drop _merge

merge 1:1 state using `beds'
drop _merge

merge 1:1 state using `doctors'
drop _merge

sort state


/********************************************************************
SAVE
********************************************************************/

save "results/health_system_capacity_states.dta", replace
