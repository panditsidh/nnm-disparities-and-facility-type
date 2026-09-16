/********************************************************************
 Table 2: NNM regressions by region and specification

 Columns within each region:
   (1) No controls
   (2) Risk controls
   (3) Risk controls + cluster fixed effects

 Forward Hindu is the omitted social group.
 Public facility birth is the omitted facility category.

 Sample:
   Rural public/private facility births
   NFHS-4 and NFHS-5 pooled

 Standard errors clustered at PSU.
********************************************************************/


*------------------------------------------------------------
* User settings
*------------------------------------------------------------

local outcome nnm
local rounds 4,5

local outfile "tables/table2 group private interactions UP Bihar and other states NFHS4,5.tex"



*------------------------------------------------------------
* Controls
*------------------------------------------------------------

local maternalrisk ///
    i.prior ///
    i.underweight_projected ///
    i.male ///
    i.momunder20 ///
    i.multiples ///
    i.birth_order

local complications ///
    i.vaginal ///
    i.breech ///
    i.prolongedlabour ///
    i.excessivebleed

local socioeconomic ///
    i.illiterate ///
    i.v190

local controls ///
    `maternalrisk' ///
    `complications' ///
    `socioeconomic'


*------------------------------------------------------------
* Load data
*------------------------------------------------------------

do "$paths"
use "$dataset", clear

capture mkdir tables

keep if inlist(round, `rounds')
keep if rural == 1
keep if home != 1
keep if public == 1 | private == 1
keep if inlist(group, 1, 2, 3, 4, 5)

* Prior NNM is undefined for first births; code as no prior NNM
replace prior = 0 if missing(prior) & bord == 1


* focus on only last births for which these questions are asked
keep if !missing(vaginal) & !missing(breech) & !missing(prolongedlabour) & !missing(excessivebleed)


*------------------------------------------------------------
* Region definitions
*------------------------------------------------------------

capture drop other_states
gen other_states = up_bihar == 0

label var up_bihar    "Uttar Pradesh and Bihar"
label var other_states "All other states"


*------------------------------------------------------------
* Labels
*------------------------------------------------------------

label define group_lbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward Hindu" ///
    5 "Muslim" ///
    6 "Christian, Sikh, Jain", replace

label values group group_lbl

label define private_lbl 0 "Public" 1 "Private", replace
label values private private_lbl


*------------------------------------------------------------
* Regressions
*------------------------------------------------------------

eststo clear


*============================================================
* Uttar Pradesh and Bihar
*============================================================

* (1) No controls
reg `outcome' ///
    ib4.group##i.private ///
    i.round ///
    [pw = v005] ///
    if up_bihar == 1, ///
    vce(cluster psu)

eststo upb_1

estadd local maternal     ""
estadd local complications ""
estadd local socioeconomic ""
estadd local roundfe      "\checkmark"
estadd local clusterfe    ""


* (2) Risk controls
reg `outcome' ///
    ib4.group##i.private ///
    `controls' ///
    i.round ///
    [pw = v005] ///
    if up_bihar == 1, ///
    vce(cluster psu)

eststo upb_2

estadd local maternal     "\checkmark"
estadd local complications "\checkmark"
estadd local socioeconomic "\checkmark"
estadd local roundfe      "\checkmark"
estadd local clusterfe    ""


* (3) Risk controls + cluster fixed effects
reghdfe `outcome' ///
    ib4.group##i.private ///
    `controls' ///
    i.round ///
    [pw = v005] ///
    if up_bihar == 1, ///
    absorb(psu) ///
    vce(cluster psu)

eststo upb_3

estadd local maternal     "\checkmark"
estadd local complications "\checkmark"
estadd local socioeconomic "\checkmark"
estadd local roundfe      "\checkmark"
estadd local clusterfe    "\checkmark"



*============================================================
* All other states
*============================================================

* (4) No controls
reg `outcome' ///
    ib4.group##i.private ///
    i.round ///
    [pw = v005] ///
    if other_states == 1, ///
    vce(cluster psu)

eststo other_1

estadd local maternal     ""
estadd local complications ""
estadd local socioeconomic ""
estadd local roundfe      "\checkmark"
estadd local clusterfe    ""


* (5) Risk controls
reg `outcome' ///
    ib4.group##i.private ///
    `controls' ///
    i.round ///
    [pw = v005] ///
    if other_states == 1, ///
    vce(cluster psu)

eststo other_2

estadd local maternal     "\checkmark"
estadd local complications "\checkmark"
estadd local socioeconomic "\checkmark"
estadd local roundfe      "\checkmark"
estadd local clusterfe    ""


* (6) Risk controls + cluster fixed effects
reghdfe `outcome' ///
    ib4.group##i.private ///
    `controls' ///
    i.round ///
    [pw = v005] ///
    if other_states == 1, ///
    absorb(psu) ///
    vce(cluster psu)

eststo other_3

estadd local maternal     "\checkmark"
estadd local complications "\checkmark"
estadd local socioeconomic "\checkmark"
estadd local roundfe      "\checkmark"
estadd local clusterfe    "\checkmark"



*------------------------------------------------------------
* LaTeX export
*------------------------------------------------------------

esttab ///
    upb_1 upb_2 upb_3 ///
    other_1 other_2 other_3 ///
    using "`outfile'", replace ///
    b(%9.1f) se(%9.1f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    booktabs ///
    nonotes ///
    collabels(none) ///
    mgroups( ///
        "Uttar Pradesh and Bihar" ///
        "All other states", ///
        pattern(1 0 0 1 0 0) ///
        prefix(\multicolumn{@span}{c}{) suffix(}) ///
        span ///
        erepeat(\cmidrule(lr){@span}) ///
    ) ///
    mtitles( ///
        "No controls" "Risk controls" "+ Cluster FE" ///
        "No controls" "Risk controls" "+ Cluster FE" ///
    ) ///
    keep( ///
        _cons ///
        1.group ///
        2.group ///
        3.group ///
        5.group ///
        1.private ///
        1.group#1.private ///
        2.group#1.private ///
        3.group#1.private ///
        5.group#1.private ///
    ) ///
    order( ///
        _cons ///
        1.group ///
        2.group ///
        3.group ///
        5.group ///
        1.private ///
        1.group#1.private ///
        2.group#1.private ///
        3.group#1.private ///
        5.group#1.private ///
    ) ///
    coeflabels( ///
        _cons "Intercept (Forward public reference)" ///
        1.group "Adivasi" ///
        2.group "Dalit" ///
        3.group "OBC" ///
        5.group "Muslim" ///
        1.private "Private facility" ///
        1.group#1.private "Adivasi $\times$ Private" ///
        2.group#1.private "Dalit $\times$ Private" ///
        3.group#1.private "OBC $\times$ Private" ///
        5.group#1.private "Muslim $\times$ Private" ///
    ) ///
    stats( ///
        maternal ///
        complications ///
        socioeconomic ///
        roundfe ///
        clusterfe ///
        N, ///
        labels( ///
            "Maternal and birth risk controls" ///
            "Pregnancy/delivery complication controls" ///
            "Socioeconomic controls" ///
            "Survey round FE" ///
            "Cluster FE" ///
            "Observations" ///
        ) ///
        fmt(%s %s %s %s %s %9.0fc) ///
    )


*------------------------------------------------------------
* Console check
*------------------------------------------------------------

esttab ///
    upb_1 upb_2 upb_3 ///
    other_1 other_2 other_3, ///
    b(%9.1f) se(%9.1f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    nonotes ///
    collabels(none) ///
    mgroups( ///
        "Uttar Pradesh and Bihar" ///
        "All other states", ///
        pattern(1 0 0 1 0 0) ///
        span ///
    ) ///
    mtitles( ///
        "No controls" "Risk controls" "+ Cluster FE" ///
        "No controls" "Risk controls" "+ Cluster FE" ///
    ) ///
    keep( ///
        _cons ///
        1.group ///
        2.group ///
        3.group ///
        5.group ///
        1.private ///
        1.group#1.private ///
        2.group#1.private ///
        3.group#1.private ///
        5.group#1.private ///
    ) ///
    order( ///
        _cons ///
        1.group ///
        2.group ///
        3.group ///
        5.group ///
        1.private ///
        1.group#1.private ///
        2.group#1.private ///
        3.group#1.private ///
        5.group#1.private ///
    ) ///
    coeflabels( ///
        _cons "Intercept (Forward public reference)" ///
        1.group "Adivasi" ///
        2.group "Dalit" ///
        3.group "OBC" ///
        5.group "Muslim" ///
        1.private "Private facility" ///
        1.group#1.private "Adivasi x Private" ///
        2.group#1.private "Dalit x Private" ///
        3.group#1.private "OBC x Private" ///
        5.group#1.private "Muslim x Private" ///
    ) ///
    stats( ///
        maternal ///
        complications ///
        socioeconomic ///
        roundfe ///
        clusterfe ///
        N, ///
        labels( ///
            "Maternal/birth risk" ///
            "Pregnancy/delivery complications" ///
            "Socioeconomic controls" ///
            "Round FE" ///
            "Cluster FE" ///
            "Observations" ///
        ) ///
        fmt(%s %s %s %s %s %9.0fc) ///
    )
