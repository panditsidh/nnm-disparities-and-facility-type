/********************************************************************
TABLE 2:
PRIVATE FACILITY BIRTH, WEALTH, AND SOCIAL GROUP

Rural India
NFHS-4 and NFHS-5

OUTCOMES:
    (1) Neonatal mortality
        Risk controls
        No risk-control × Private interactions
        No PSU FE

    (2) Neonatal mortality
        Risk controls
        Risk-control × Private interactions
        No PSU FE

    (3) Neonatal mortality
        Risk controls
        Risk-control × Private interactions
        PSU FE

    (4) Early neonatal mortality
        Risk controls
        Risk-control × Private interactions
        PSU FE

    (5) Late neonatal mortality
        Risk controls
        Risk-control × Private interactions
        PSU FE


REFERENCE CATEGORIES:
    Public facility
    Forward Hindu
    Wealth quintile 5


RISK CONTROLS:
    Prior neonatal death
    Projected maternal prepregnancy underweight
    Child sex
    Maternal age under 20
    Multiple birth
    Birth order
    Maternal illiteracy


STANDARD ERRORS:
    Clustered by PSU
********************************************************************/


*------------------------------------------------------------*
* LOAD DATA
*------------------------------------------------------------*

do "$paths"
use "$dataset", clear


gen eag = inlist(state, ///
    104, /// Uttarakhand
    107, /// Rajasthan
    108, /// Uttar Pradesh
    109, /// Bihar
    119, /// Jharkhand
    120, /// Odisha
    121, /// Chhattisgarh
    122)   // Madhya Pradesh

label define eag_lbl ///
    0 "Non-EAG" ///
    1 "EAG"

label values eag eag_lbl
label variable eag "EAG state"


// keep if eag==1


*------------------------------------------------------------*
* SAMPLE
*------------------------------------------------------------*

keep if inlist(round,4,5)
keep if rural==1

* Public/private facility births only
keep if public==1 | private==1

* Main five social groups only
keep if inlist(group,1,2,3,4,5)

replace prior = 0 if missing(prior)

drop if missing(v005)
drop if missing(psu)
drop if missing(state)


*------------------------------------------------------------*
* SOCIAL GROUP LABELS
*------------------------------------------------------------*

label define group_lbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward Hindu" ///
    5 "Muslim" ///
    6 "Christian, Sikh, Jain", replace

label values group group_lbl


*------------------------------------------------------------*
* UNIQUE PSU ACROSS SURVEY ROUNDS
*------------------------------------------------------------*

capture drop psu_id

egen psu_id = group(round state psu)


*------------------------------------------------------------*
* COMMON COVARIATE SAMPLE
*------------------------------------------------------------*

capture drop miss_reg reg_base

egen miss_reg = rowmiss( ///
    private ///
    group ///
    v190 ///
    prior ///
    underweight_projected ///
    male ///
    momunder20 ///
    multiples ///
    birth_order ///
    illiterate ///
    round ///
    v005 ///
    psu_id ///
)

gen byte reg_base = (miss_reg==0)


*------------------------------------------------------------*
* CHECK OUTCOMES
*------------------------------------------------------------*

foreach y in nnm early_nnm late_nnm {

    capture confirm variable `y'

    if _rc {
        di as error "Variable `y' not found."
        exit 111
    }
}


*------------------------------------------------------------*
* MODEL COMPONENTS
*
* Reference groups:
*   Facility: Public
*   Wealth: Quintile 5
*   Social group: Forward Hindu
*------------------------------------------------------------*

local wealth_group_terms ///
    i.private ///
    ib5.v190 ///
    ib4.group ///
    i.private#ib5.v190 ///
    i.private#ib4.group


* Main maternal/birth risk controls
local risk_main ///
    i.prior ///
    i.underweight_projected ///
    i.male ///
    i.momunder20 ///
    i.multiples ///
    c.birth_order ///
    i.illiterate


* Maternal/birth risk controls × Private
local risk_private ///
    i.private#i.prior ///
    i.private#i.underweight_projected ///
    i.private#i.male ///
    i.private#i.momunder20 ///
    i.private#i.multiples ///
    i.private#c.birth_order ///
    i.private#i.illiterate


*------------------------------------------------------------*
* CLEAR STORED ESTIMATES
*------------------------------------------------------------*

estimates clear
eststo clear


/********************************************************************
MODEL 1
NNM
Risk controls
No risk × Private interactions
No PSU FE
********************************************************************/

regress nnm ///
    `wealth_group_terms' ///
    `risk_main' ///
    i.round ///
    [aw=v005] ///
    if reg_base==1 & !missing(nnm), ///
    vce(cluster psu_id)

estadd local risk_controls "Yes"
estadd local risk_interactions "No"
estadd local psu_fe "No"

estimates store m1



/********************************************************************
MODEL 2
NNM
Risk controls
Risk × Private interactions
No PSU FE
********************************************************************/

regress nnm ///
    `wealth_group_terms' ///
    `risk_main' ///
    `risk_private' ///
    i.round ///
    [aw=v005] ///
    if reg_base==1 & !missing(nnm), ///
    vce(cluster psu_id)

estadd local risk_controls "Yes"
estadd local risk_interactions "Yes"
estadd local psu_fe "No"

estimates store m2



/********************************************************************
MODEL 3
NNM
Risk controls
Risk × Private interactions
PSU FE
********************************************************************/

reghdfe nnm ///
    `wealth_group_terms' ///
    `risk_main' ///
    `risk_private' ///
    i.round ///
    [aw=v005] ///
    if reg_base==1 & !missing(nnm), ///
    absorb(psu_id) ///
    vce(cluster psu_id)

estadd local risk_controls "Yes"
estadd local risk_interactions "Yes"
estadd local psu_fe "Yes"

estimates store m3



/********************************************************************
MODEL 4
EARLY NEONATAL MORTALITY
Risk controls
Risk × Private interactions
PSU FE
********************************************************************/

reghdfe early_nnm ///
    `wealth_group_terms' ///
    `risk_main' ///
    `risk_private' ///
    i.round ///
    [aw=v005] ///
    if reg_base==1 & !missing(early_nnm), ///
    absorb(psu_id) ///
    vce(cluster psu_id)

estadd local risk_controls "Yes"
estadd local risk_interactions "Yes"
estadd local psu_fe "Yes"

estimates store m4



/********************************************************************
MODEL 5
LATE NEONATAL MORTALITY
Risk controls
Risk × Private interactions
PSU FE
********************************************************************/

reghdfe late_nnm ///
    `wealth_group_terms' ///
    `risk_main' ///
    `risk_private' ///
    i.round ///
    [aw=v005] ///
    if reg_base==1 & !missing(late_nnm), ///
    absorb(psu_id) ///
    vce(cluster psu_id)

estadd local risk_controls "Yes"
estadd local risk_interactions "Yes"
estadd local psu_fe "Yes"

estimates store m5



* MODEL 1
estadd local wealth_main "\checkmark"
estadd local group_main "\checkmark"
estadd local controls "\checkmark"
estadd local psu_fe ""

* MODEL 2
estadd local wealth_main "\checkmark"
estadd local group_main "\checkmark"
estadd local controls "\checkmark"
estadd local psu_fe ""

* MODEL 3
estadd local wealth_main "\checkmark"
estadd local group_main "\checkmark"
estadd local controls "\checkmark"
estadd local psu_fe "\checkmark"

* MODEL 4
estadd local wealth_main "\checkmark"
estadd local group_main "\checkmark"
estadd local controls "\checkmark"
estadd local psu_fe "\checkmark"

* MODEL 5
estadd local wealth_main "\checkmark"
estadd local group_main "\checkmark"
estadd local controls "\checkmark"
estadd local psu_fe "\checkmark"


/********************************************************************
DISPLAY TABLE IN STATA
********************************************************************/

esttab m1 m2 m3 m4 m5, ///
    b(1) se(1) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep( ///
        _cons ///
        1.private ///
        1.private#1.v190 ///
        1.private#2.v190 ///
        1.private#3.v190 ///
        1.private#4.v190 ///
        1.private#2.group ///
        1.private#5.group ///
        1.private#3.group ///
        1.private#1.group ///
    ) ///
    order( ///
        _cons ///
        1.private ///
        1.private#1.v190 ///
        1.private#2.v190 ///
        1.private#3.v190 ///
        1.private#4.v190 ///
        1.private#2.group ///
        1.private#5.group ///
        1.private#3.group ///
        1.private#1.group ///
    ) ///
    coeflabels( ///
        _cons "Intercept: Public, Q5, Forward Hindu" ///
        1.private "Private" ///
        1.private#1.v190 "Private x quintile 1" ///
        1.private#2.v190 "Private x quintile 2" ///
        1.private#3.v190 "Private x quintile 3" ///
        1.private#4.v190 "Private x quintile 4" ///
        1.private#2.group "Private x Dalit" ///
        1.private#5.group "Private x Muslim" ///
        1.private#3.group "Private x OBC" ///
        1.private#1.group "Private x Adivasi" ///
    ) ///
    refcat( ///
        _cons "BASELINE" ///
        1.private#1.v190 "WEALTH" ///
        1.private#2.group "SOCIAL GROUP", ///
        nolabel ///
    ) ///
    mtitles( ///
        "NNM" ///
        "NNM" ///
        "NNM" ///
        "Early NNM" ///
        "Late NNM" ///
    ) ///
    stats( ///
        wealth_main ///
        group_main ///
        controls ///
        psu_fe ///
        N, ///
        labels( ///
            "Wealth main effects" ///
            "Social-group main effects" ///
            "Maternal and birth controls" ///
            "PSU fixed effects" ///
            "Observations" ///
        ) ///
        fmt(0 0 0 0 0) ///
    )



/********************************************************************
EXPORT LATEX TABLE
********************************************************************/

esttab m1 m2 m3 m4 m5 using ///
    "tables/table 2 main regression.tex", ///
    replace ///
    booktabs ///
    b(1) se(1) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    keep( ///
        _cons ///
        1.private ///
        1.private#1.v190 ///
        1.private#2.v190 ///
        1.private#3.v190 ///
        1.private#4.v190 ///
        1.private#2.group ///
        1.private#5.group ///
        1.private#3.group ///
        1.private#1.group ///
    ) ///
    order( ///
        _cons ///
        1.private ///
        1.private#1.v190 ///
        1.private#2.v190 ///
        1.private#3.v190 ///
        1.private#4.v190 ///
        1.private#2.group ///
        1.private#5.group ///
        1.private#3.group ///
        1.private#1.group ///
    ) ///
    coeflabels( ///
        _cons "Intercept: Public, Q5, Forward Hindu" ///
        1.private "Private" ///
        1.private#1.v190 "Private $\times$ quintile 1" ///
        1.private#2.v190 "Private $\times$ quintile 2" ///
        1.private#3.v190 "Private $\times$ quintile 3" ///
        1.private#4.v190 "Private $\times$ quintile 4" ///
        1.private#2.group "Private $\times$ Dalit" ///
        1.private#5.group "Private $\times$ Muslim" ///
        1.private#3.group "Private $\times$ OBC" ///
        1.private#1.group "Private $\times$ Adivasi" ///
    ) ///
    refcat( ///
        _cons "\textit{Baseline}" ///
        1.private#1.v190 "\textit{Wealth}" ///
        1.private#2.group "\textit{Social group}", ///
        nolabel ///
    ) ///
    mtitles( ///
        "(1)" ///
        "(2)" ///
        "(3)" ///
        "(4)" ///
        "(5)" ///
    ) ///
    mgroups( ///
        "Neonatal mortality" ///
        "Early neonatal mortality" ///
        "Late neonatal mortality", ///
        pattern(1 0 0 1 1) ///
        span ///
        prefix(\multicolumn{@span}{c}{) ///
        suffix(}) ///
        erepeat(\cmidrule(lr){@span}) ///
    ) ///
    stats( ///
        wealth_main ///
        group_main ///
        controls ///
        psu_fe ///
        N, ///
        labels( ///
            "Wealth main effects" ///
            "Social-group main effects" ///
            "Maternal and birth controls" ///
            "PSU fixed effects" ///
            "Observations" ///
        ) ///
        fmt(0 0 0 0 0) ///
    ) ///
    nonotes ///
    addnotes( ///
        "Standard errors clustered by PSU appear in parentheses." ///
        "Public facility birth, wealth quintile 5, and Forward Hindu are the omitted categories." ///
        "Wealth-quintile and social-group main effects are included in all specifications but not reported." ///
        "Maternal and birth controls include prior neonatal death, projected maternal prepregnancy underweight, child sex, maternal age under 20, multiple birth, birth order, and maternal illiteracy." ///
        "Columns 2--5 also include interactions of maternal and birth controls with Private." ///
        "All models include NFHS round fixed effects." ///
        "$^{*}p<0.10$, $^{**}p<0.05$, $^{***}p<0.01$." ///
    )
