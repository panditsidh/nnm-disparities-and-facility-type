do "$paths"


********************************************
* NFHS-3
********************************************

preserve

import delimited "data/districtcrosswalk_1245.csv", clear
keep state_nfhs5 name_nfhs5
drop if missing(state_nfhs5) | missing(name_nfhs5)
duplicates drop
gen name_key = lower(trim(itrim(name_nfhs5)))
tempfile canon
save `canon', replace


import delimited "data/state_merge_345.csv", clear

* nfhs5_statename is the target label in that file
gen name_key = lower(trim(itrim(nfhs5_statename)))


merge m:1 name_key using `canon', keep(1 3) nogen

* Now you have the correct canonical state_nfhs5 (100–134) for every row that matches.
count if missing(state_nfhs5)
list nfhs5_statename if missing(state_nfhs5)

drop if missing(statecode_nfhs3)

tempfile state_crosswalk

save `state_crosswalk'

restore

use "$nfhs3br", clear

rename v024 statecode_nfhs3
merge m:1 statecode_nfhs3 using `state_crosswalk'

gen round = 3

tempfile nfhs3br
save `nfhs3br'

********************************************
* NFHS-4
********************************************


use "$nfhs4br", clear


preserve
import excel "data/districtcrosswalk_1245.xlsx", sheet("districts") firstrow clear
drop if missing(districtcode_nfhs4)
tempfile district_crosswalk
save `district_crosswalk'
restore


rename sdistri districtcode_nfhs4

merge m:1 districtcode_nfhs4 using `district_crosswalk'
keep if _merge==3
drop _merge

gen round = 4

tempfile nfhs4br
save `nfhs4br'


********************************************
* NFHS-5
********************************************

preserve

import delimited "data/districtcrosswalk_1245.csv", clear
keep state_nfhs5 name_nfhs5
drop if missing(state_nfhs5) | missing(name_nfhs5)
duplicates drop
gen name_key = lower(trim(itrim(name_nfhs5)))
tempfile canon
save `canon', replace


import delimited "data/state_merge_345.csv", clear

* nfhs5_statename is the target label in that file
gen name_key = lower(trim(itrim(nfhs5_statename)))


merge m:1 name_key using `canon', keep(1 3) nogen

* Now you have the correct canonical state_nfhs5 (100–134) for every row that matches.
count if missing(state_nfhs5)
list nfhs5_statename if missing(state_nfhs5)
list nfhs5_statename if missing(statecode_nfhs5)

drop if missing(statecode_nfhs5)

tempfile state_crosswalk

save `state_crosswalk'

restore

use "$nfhs5br", clear

rename v024 statecode_nfhs5
merge m:1 statecode_nfhs5 using `state_crosswalk'


gen round = 5


append using `nfhs3br'
append using `nfhs4br'



*-------------------------------------------------
* Create value label for state_nfhs5
*-------------------------------------------------

label define state5_lbl ///
100 "Jammu & Kashmir" ///
101 "Himachal Pradesh" ///
102 "Punjab" ///
103 "Chandigarh" ///
104 "Uttarakhand" ///
105 "Haryana" ///
106 "NCT of Delhi" ///
107 "Rajasthan" ///
108 "Uttar Pradesh" ///
109 "Bihar" ///
110 "Sikkim" ///
111 "Arunachal Pradesh" ///
112 "Nagaland" ///
113 "Manipur" ///
114 "Mizoram" ///
115 "Tripura" ///
116 "Meghalaya" ///
117 "Assam" ///
118 "West Bengal" ///
119 "Jharkhand" ///
120 "Odisha" ///
121 "Chhattisgarh" ///
122 "Madhya Pradesh" ///
123 "Gujarat" ///
124 "Dadra & Nagar Haveli" ///
125 "Maharashtra" ///
126 "Andhra Pradesh" ///
127 "Karnataka" ///
128 "Goa" ///
129 "Lakshadweep" ///
130 "Kerala" ///
131 "Tamil Nadu" ///
132 "Puducherry" ///
133 "Andaman & Nicobar Islands" ///
134 "Telangana"

* Attach label to variable
label values state_nfhs5 state5_lbl





do "dofiles/11 gen vars"
