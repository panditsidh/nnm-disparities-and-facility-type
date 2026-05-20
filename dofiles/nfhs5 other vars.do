
// use "$dataset", clear

keep if round==5

* sex of child
gen male = (b4==1)

* indicators for inclusion in the analysis sample
gen nnm_sample = nnm if home!=1
gen public_sample = public if !missing(nnm) & home!=1
gen in_sample = !missing(nnm_sample, public_sample)


* create other SES variables
gen water = v113 if v113<51
replace water = 10 if inrange(water, 10,19)
replace water = 20 if inrange(water, 20,29)
replace water = 30 if inrange(water, 30,39)
replace water = 40 if inrange(water, 40,49)
label val water V113

gen floor = v127 if v127 < 96
replace floor = 10 if inrange(floor, 10, 19)
replace floor = 20 if inrange(floor, 20, 29)
replace floor = 30 if inrange(floor, 30, 39)
label define floor 10 "unfinished" 20 "part finished" 30 "finished" 
label val floor floor

gen wall = v128 if v128 < 96
replace wall = 10 if inrange(wall, 10, 19)
replace wall = 20 if inrange(wall, 20, 29)
replace wall = 30 if inrange(wall, 30, 39)
label define wall 10 "unfinished" 20 "part finished" 30 "finished" 
label val wall wall

gen roof = v129 if v129 < 96
replace roof = 10 if inrange(roof, 10, 19)
replace roof = 20 if inrange(roof, 20, 29)
replace roof = 30 if inrange(roof, 30, 39)
label define roof 10 "unfinished" 20 "part finished" 30 "finished" 
label val roof roof



* create natal risk variables --------------------------------------------------

* unique mother identifier, input for sibling variables
egen momid = group(v000 v001 v002 v003 v011 state_nfhs5)

* the following block creates indicators for whether a baby's mother had any 
*    prior NNM and an immediately prior NNM
forvalues i = 1(1)9{
gen nnm_`i' = nnm if bord == `i'
egen nnm_mom_`i' = mean(nnm_`i'), by(momid)
}
gen prior = .
gen immediatelyprior = .
forvalues i = 2(1)10{
local prior = `i'-1
replace prior = 1 if nnm_mom_`prior' == 1000 & bord >= `i' & bord <=10
replace prior = 0 if prior == . & bord == `i'
replace immediatelyprior = nnm_mom_`prior' / 1000 if bord == `i'
}


* mother's age at the time of the birth in completed years
gen moagebirth= b3 - v011
replace moagebirth = floor(moagebirth/12)
tab moagebirth
replace moagebirth = . if moagebirth < 10
replace moagebirth = 48 if moagebirth == 49

* mother's age at the time of the birth in fractional years
gen momagebirth = (b3-v011)/12
gen momagebirth_sq = momagebirth^2

* indicators for whether the mother was under or over 20 at birth
gen momunder20 = momagebirth < 20 if momagebirth < .
gen mom20plus = momagebirth >= 20 if momagebirth < .

* early initiation of breastfeeding (within 1 hour)
gen eibf = (v426==0) if !missing(v426)

* breastfeeding initiation within 24 hr
gen bf24hr = v426 < 125 if !missing(v426) 






* create variable for mother's projected BMI -----------------------------------

* mother's age at the time of the survey in fractional years
gen momagesurvey = (v008-v011)/12
tab v213 if in_sample==1 

* mother's age at the time of conception in fractional years
gen momageb4birth = momagebirth-0.83

* gestational age, among pregnant women
gen moperiod = .
replace moperiod = 1 if v215>=101 & v215<=128 & v213==1
replace moperiod = 2 if v215>=129 & v215<=156 & v213==1
replace moperiod = 3 if v215>=157 & v215<=184 & v213==1
replace moperiod = 4 if v215>=185 & v215<=198 & v213==1
replace moperiod = 1 if v215>=201 & v215<=204 & v213==1
replace moperiod = 2 if v215>=205 & v215<=208 & v213==1
replace moperiod = 3 if v215>=209 & v215<=213 & v213==1
replace moperiod = 1 if v215==301 & v213==1
replace moperiod = 2 if v215==302 & v213==1
replace moperiod = 3 if v215==303 & v213==1
replace moperiod = 4 if v215==304 & v213==1
replace moperiod = 5 if v215==305 & v213==1
replace moperiod = 6 if v215==306 & v213==1
replace moperiod = 7 if v215==307 & v213==1
replace moperiod = 8 if v215==308 & v213==1
replace moperiod = 9 if v215==309 & v213==1
replace moperiod = 10 if v215==310 & v213==1
replace moperiod = 11 if v215==311 & v213==1
gen mopreg = moperiod
tab mopreg, m
replace mopreg = v214 if missing(mopreg)
replace mopreg = 9 if inlist(mopreg, 10, 11)
gen weightgainmo = mopreg - 3

* mother's BMI at survey
gen bmi = v445/100 if v445 < 7000

* This code projects what a mother's BMI was before she got pregnant. It assumes
* that her BMI has increased linearly with age at the same rate as the average
* woman for the rural/urban part of her state. For pregnant women, it
* additionally subtracts 0.42 BMI points for each month of pregnancy 4-9. This
* effectively assumes there is not weight gain in the first trimester. 
gen bmi_projected = .


rename state_nfhs5 state
levelsof state
foreach i of numlist `r(levels)' {
reg bmi momagesurvey [aweight = wt] if state== `i'& v025==1 & v213==0
replace bmi_projected = bmi + (momageb4birth-momagesurvey)*_b[momagesurvey] if state==`i' & v025==1
reg bmi momagesurvey [aweight = wt] if state== `i' & v025==2 & v213==0
replace bmi_projected = bmi + (momageb4birth-momagesurvey)*_b[momagesurvey] if state==`i' & v025==2

reg bmi mopreg [aweight = wt] if v025==1 & v213==1 & mopreg>=3
replace bmi_projected = bmi_projected - weightgainmo*_b[mopreg] if state==`i'& v025==1 & v213==1 & mopreg>=3
reg bmi mopreg [aweight = wt] if v025==2 & v213==1 & mopreg>=3
replace bmi_projected = bmi_projected - weightgainmo*_b[mopreg] if state==`i'& v025==2 & v213==1 & mopreg>=3
}


* mother's projected underweight status at conception 
gen underweight_projected = bmi_projected < 18.5 if !missing(bmi_projected)




gen csection = (m17==1) if !missing(m17)
gen vaginal = (csection==0) if !missing(csection)


* mother's illiteracy
gen illiterate = (v155 == 0)
