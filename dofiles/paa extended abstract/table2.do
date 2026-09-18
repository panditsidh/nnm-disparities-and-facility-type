/********************************************************************
Table 2: Differences in excess private neonatal mortality
         across social groups and regions

Columns within each region:
  (1) No controls
  (2) Controls
  (3) Controls + sampling cluster fixed effects

Forward Hindu is the omitted social group.
Public facility birth is the omitted facility category.

Within each region, all three specifications use the exact same
estimation sample: the sample from specification (3).
********************************************************************/


*------------------------------------------------------------*
* 1) Load data
*------------------------------------------------------------*

do "$paths"
use "$dataset", clear

capture mkdir tables

local outfile "tables/table2 group private interactions UP Bihar and other states NFHS4,5.tex"

keep if inlist(round, 4, 5)
keep if rural == 1
keep if home != 1
keep if public == 1 | private == 1
keep if inlist(group, 1, 2, 3, 4, 5)

replace prior = 0 if missing(prior) & bord == 1

* Most recent births for which pregnancy/delivery questions are observed
keep if !missing(vaginal) ///
    & !missing(breech) ///
    & !missing(prolongedlabour) ///
    & !missing(excessivebleed)

capture drop other_states
gen other_states = up_bihar == 0


*------------------------------------------------------------*
* 2) Labels
*------------------------------------------------------------*

label define group_lbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward Hindu" ///
    5 "Muslim", replace

label values group group_lbl

label define private_lbl 0 "Public" 1 "Private", replace
label values private private_lbl


*------------------------------------------------------------*
* 3) Regressions
*------------------------------------------------------------*

eststo clear

local regions up_bihar other_states

foreach reg of local regions {

    * Name used for stored estimates and common-sample variable
    if "`reg'" == "up_bihar" {
        local prefix upb
    }
    else {
        local prefix other
    }

    * Define common sample using the most restrictive specification
    quietly reghdfe nnm ///
        ib4.group##i.private ///
        i.prior ///
        i.underweight_projected ///
        i.male ///
        i.momunder20 ///
        i.multiples ///
        i.birth_order ///
        i.vaginal ///
        i.breech ///
        i.prolongedlabour ///
        i.excessivebleed ///
        i.illiterate ///
        i.v190 ///
        i.round ///
        [pw = v005] ///
        if `reg' == 1, ///
        absorb(psu) ///
        vce(cluster psu)

    gen sample_`prefix' = e(sample)


    * (1) No controls
    reg nnm ///
        ib4.group##i.private ///
        i.round ///
        [pw = v005] ///
        if sample_`prefix' == 1, ///
        vce(cluster psu)

    eststo `prefix'_1
    estadd local controls ""
    estadd local clusterfe ""


    * (2) Controls
    reg nnm ///
        ib4.group##i.private ///
        i.prior ///
        i.underweight_projected ///
        i.male ///
        i.momunder20 ///
        i.multiples ///
        i.birth_order ///
        i.vaginal ///
        i.breech ///
        i.prolongedlabour ///
        i.excessivebleed ///
        i.illiterate ///
        i.v190 ///
        i.round ///
        [pw = v005] ///
        if sample_`prefix' == 1, ///
        vce(cluster psu)

    eststo `prefix'_2
    estadd local controls "\checkmark"
    estadd local clusterfe ""


    * (3) Controls + sampling cluster fixed effects
    reghdfe nnm ///
        ib4.group##i.private ///
        i.prior ///
        i.underweight_projected ///
        i.male ///
        i.momunder20 ///
        i.multiples ///
        i.birth_order ///
        i.vaginal ///
        i.breech ///
        i.prolongedlabour ///
        i.excessivebleed ///
        i.illiterate ///
        i.v190 ///
        i.round ///
        [pw = v005] ///
        if sample_`prefix' == 1, ///
        absorb(psu) ///
        vce(cluster psu)

    eststo `prefix'_3
    estadd local controls "\checkmark"
    estadd local clusterfe "\checkmark"
}


*------------------------------------------------------------*
* 4) Export
*------------------------------------------------------------*

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
        "No controls" "Controls" "+ Sampling cluster fixed effects" ///
        "No controls" "Controls" "+ Sampling cluster fixed effects" ///
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
        controls ///
        clusterfe ///
        N, ///
        labels( ///
            "Controls" ///
            "Sampling cluster fixed effects" ///
            "Observations" ///
        ) ///
        fmt(%s %s %9.0fc) ///
    )
