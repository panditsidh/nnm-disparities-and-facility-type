


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



************************************ Regions ************************************

gen focus = inlist(state_nfhs5, 104, 107, 108, 109, 119, 120, 121, 122)
label var focus "EAG States"

gen up_bihar = inlist(state_nfhs5, 108, 109)
label var up_bihar "UP & Bihar"


gen non_upbihar_focus = focus==1 & up_bihar==0
label var non_upbihar_focus "EAG states besides UP & Bihar"


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


************************************ Weights ************************************


egen strata = group(v000 state_nfhs5 v025)

* cluster number, state, urban/rural
egen psu    = group(v000 v001 state_nfhs5 v025)

bysort v000: egen totalwt = total(v005)
gen wt = v005 / totalwt

svyset psu [pw=v005], strata(strata) vce(linearized) singleunit(centered)





save "$dataset", replace


