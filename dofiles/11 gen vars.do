


************************************ Neonatal mortality ************************************


gen child_age_mo = v008-b3 
gen nnm = 0 if child_age_mo > 0
replace nnm = 1000 if nnm == 0 & b7 == 0
replace nnm=. if child_age_mo == 0
replace nnm =. if child_age_mo>60


drop if missing(nnm)




************************************ Facility type ************************************

gen home = inrange(m15, 10, 13)
gen public = inrange(m15, 20, 29)
gen private = inrange(m15, 30, 39)

replace home    = . if inlist(m15, 96, 99) | missing(m15)
replace public  = . if inlist(m15, 96, 99) | missing(m15)
replace private = . if inlist(m15, 96, 99) | missing(m15)

gen facility_type = 1 if private==1
replace facility_type = 2 if public==1
replace facility_type = 3 if home==1

label define facility_lbl ///
1 "Private" ///
2 "Public" ///
3 "Home"

label values facility_type facility_lbl




* indicators for inclusion in the analysis sample
gen nnm_sample = nnm if home!=1
gen public_sample = public if !missing(nnm) & home!=1
gen in_sample = !missing(nnm_sample, public_sample)



************************************ Regions ************************************

gen focus = inlist(state_nfhs5, 104, 107, 108, 109, 119, 120, 121, 122)
label var focus "EAG States"

gen up_bihar = inlist(state_nfhs5, 108, 109)
label var up_bihar "UP and Bihar"


gen non_upbihar_focus = focus==1 & up_bihar==0
label var non_upbihar_focus "EAG states besides UP and Bihar"


gen up = state_nfhs5==108
gen bihar = state_nfhs5==109

label var up    "Uttar Pradesh"
label var bihar "Bihar"


gen nonfocus = !focus
label var nonfocus "Non EAG states"


gen rest_india = !inlist(state_nfhs5, 108, 109) if !missing(state_nfhs5)
label var rest_india "Rest of India (excluding UP and Bihar)"

gen north = inlist(state_nfhs5, ///
    100, 101, 102, 103, 104, 105, 106, 107) ///
    if !missing(state_nfhs5)
label var north "North India"

gen south = inlist(state_nfhs5, ///
    126, 127, 128, 129, 130, 131, 132, 134) ///
    if !missing(state_nfhs5)
label var south "South India"

gen east = inlist(state_nfhs5, ///
    109, 118, 119, 120, 110, 133) ///
    if !missing(state_nfhs5)
label var east "East India"

gen west = inlist(state_nfhs5, ///
    123, 124, 125, 128) ///
    if !missing(state_nfhs5)
label var west "West India"

gen central = inlist(state_nfhs5, ///
    108, 121, 122) ///
    if !missing(state_nfhs5)
label var central "Central India"

gen northeast = inlist(state_nfhs5, ///
    111, 112, 113, 114, 115, 116, 117) ///
    if !missing(state_nfhs5)
label var northeast "Northeast India"


gen region = 1 if north==1
replace region = 2 if south==1
replace region = 3 if east==1
replace region = 4 if west==1
replace region = 5 if central==1
replace region = 6 if northeast==1

label var region "Region"

label define regionlbl 1 "North" 2 "South" 3 "East" 4 "West" 5 "Central" 6 "Northeast" 
label val region regionlbl






gen urban = v025==1
gen rural = v025==2

gen India = 1
gen EAG = focus



gen nonEAG = !focus


************************************ Social Groups ************************************

*------------------------------------------------------------
* Social group coding directly from round-specific variables
* NFHS-3: v000 == "IA5", caste variable = s118
* NFHS-4/5: v000 == "IA6" or "IA7", caste variable = s116
*------------------------------------------------------------

capture drop group
gen group = .

*-------------------------
* NFHS-3
* s118:
* 1 = scheduled caste
* 2 = scheduled tribe
* 3 = other backward class
*-------------------------

replace group = 1 if v000 == "IA5" & s118 == 2                              // Adivasi
replace group = 2 if v000 == "IA5" & s118 == 1                              // Dalit

replace group = 6 if v000 == "IA5" ///
    & inlist(v130, 3, 4, 6) ///
    & group == .                                                            // Christian, Sikh, Jain

replace group = 5 if v000 == "IA5" ///
    & v130 == 2 ///
    & group == .                                                            // Muslim, excluding Adivasi/Dalit

replace group = 3 if v000 == "IA5" ///
    & inlist(v130, 1, 4) ///
    & s118 == 3                                                             // OBC Hindu or Sikh

replace group = 4 if v000 == "IA5" ///
    & v130 == 1 ///
    & !inlist(s118,1,2,3)                                                         // Forward caste Hindu


*-------------------------
* NFHS-4 and NFHS-5
* s116:
* 1 = scheduled caste
* 2 = scheduled tribe
* 3 = OBC
* 4 = none of them
* 8 = don't know
*-------------------------

replace group = 1 if inlist(v000, "IA6", "IA7") & s116 == 2                 // Adivasi
replace group = 2 if inlist(v000, "IA6", "IA7") & s116 == 1                 // Dalit

replace group = 6 if inlist(v000, "IA6", "IA7") ///
    & inlist(v130, 3, 4, 6) ///
    & group == .                                                            // Christian, Sikh, Jain

replace group = 5 if inlist(v000, "IA6", "IA7") ///
    & v130 == 2 ///
    & group == .                                                            // Muslim, excluding Adivasi/Dalit

replace group = 3 if inlist(v000, "IA6", "IA7") ///
    & inlist(v130, 1, 4) ///
    & s116 == 3                                                             // OBC Hindu or Sikh

replace group = 4 if inlist(v000, "IA6", "IA7") ///
    & v130 == 1 ///
    & (s116 == 4 | s116 == 8 | missing(s116))                               // Forward caste Hindu


label define group_lbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward Hindu" ///
    5 "Muslim" ///
    6 "Christian, Sikh, Jain", replace

label values group group_lbl
label var group "Social group"


************************************ NNM risk variables ************************************


* sex of child
gen male = (b4==1)

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


rename state_nfhs5
levelsof state_nfhs5
foreach i of numlist `r(levels)' {
reg bmi momagesurvey [aweight = v005] if state== `i'& v025==1 & v213==0
replace bmi_projected = bmi + (momageb4birth-momagesurvey)*_b[momagesurvey] if state==`i' & v025==1
reg bmi momagesurvey [aweight = v005] if state== `i' & v025==2 & v213==0
replace bmi_projected = bmi + (momageb4birth-momagesurvey)*_b[momagesurvey] if state==`i' & v025==2

reg bmi mopreg [aweight = v005] if v025==1 & v213==1 & mopreg>=3
replace bmi_projected = bmi_projected - weightgainmo*_b[mopreg] if state==`i'& v025==1 & v213==1 & mopreg>=3
reg bmi mopreg [aweight = v005] if v025==2 & v213==1 & mopreg>=3
replace bmi_projected = bmi_projected - weightgainmo*_b[mopreg] if state==`i'& v025==2 & v213==1 & mopreg>=3
}


* mother's projected underweight status at conception 
gen underweight_projected = bmi_projected < 18.5 if !missing(bmi_projected)



gen csection = (m17==1) if !missing(m17)
gen vaginal = (csection==0) if !missing(csection)






gen birth_order = bord 
replace birth_order = 5 if bord>=5



gen multiples = b0!=0


************************************ Wealth variables ************************************



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


* mother's illiteracy
gen illiterate = (v155 == 0)


************************************ Care at birth variables ************************************

cap drop prelac
    gen prelac = .

capture confirm variable m55a
if !_rc {
	foreach v in m55a m55b m55c m55d m55e m55f m55g m55h m55i m55j m55x {
		capture replace `v' = . if `v' >= 8
	}

	egen prelac_any = rowmax(m55a m55b m55c m55d m55e m55f m55g m55h m55i m55j m55x)
	replace prelac = 1 if prelac_any==1
	replace prelac = 0 if prelac_any==0
	drop prelac_any
	
	

}


cap drop skin
gen skin = .
replace skin = 1 if m77==1
replace skin = 0 if inlist(m77,0,2)
label var skin "Skin-to-skin contact after birth"








* total OOP delivery cost


*------------------------------------------------------------
* Harmonize out-of-pocket delivery cost
*
* NFHS-5: s454
*   0       Did not pay
*   1-99995 Cost in Rs
*   99998   Don't know
*
* NFHS-4: s449
*   0       Did not pay
*   1-99990 Cost in Rs
*   99998   Don't know
*
* Harmonized variable:
*   deliv_oop_cost = total out-of-pocket delivery cost in Rs
*------------------------------------------------------------

cap drop deliv_oop_cost_raw
cap drop deliv_oop_cost
* Raw harmonized delivery OOP cost
gen deliv_oop_cost_raw = .

replace deliv_oop_cost_raw = s449 if round == 4 & inrange(s449, 0, 99989)
replace deliv_oop_cost_raw = s454 if round == 5 & inrange(s454, 0, 99994)

label var deliv_oop_cost_raw "Total out-of-pocket delivery cost, Rs, raw"


* Cleaned analytic version: drop values above round-specific p99
gen deliv_oop_cost = deliv_oop_cost_raw

replace deliv_oop_cost = . if round == 4 & deliv_oop_cost > 50000
replace deliv_oop_cost = . if round == 5 & deliv_oop_cost > 60000

label var deliv_oop_cost "Total out-of-pocket delivery cost, Rs, top 1% excluded"

************************************ Weights ************************************


egen strata = group(v000 state_nfhs5 v025)

* cluster number, state, urban/rural
egen psu    = group(v000 v001 state_nfhs5 v025)

bysort v000: egen totalwt = total(v005)
gen wt = v005 / totalwt

svyset psu [pw=v005], strata(strata) vce(linearized) singleunit(centered)








save "$dataset", replace


