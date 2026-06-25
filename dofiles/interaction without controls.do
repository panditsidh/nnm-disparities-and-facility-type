/********************************************************************
 Table: Uncontrolled NNM regressions by region

 Diane request:
   Start with an uncontrolled regression of NNM on private and the
   interaction of private and social groups. Show all coefficients so
   someone can recover the rates. Stratify by:
      1. UP/Bihar
      2. Other EAG states
      3. Non-EAG states

 Regression:
   NNM_i = alpha
         + beta_g Group_i
         + beta_p Private_i
         + beta_gp Group_i x Private_i
         + error_i

 Forward Hindu is the omitted social group.
 Public facility birth is the omitted facility category.

 Coefficient interpretation:
   _cons                  = Forward Hindu public NNM rate
   group coef             = group public minus Forward Hindu public
   private coef           = Forward Hindu private minus Forward Hindu public
   group#private coef     = additional private-public gap for group,
                            relative to Forward Hindu

 Output:
   tables/table uncontrolled private interaction all coefs NFHS5.tex
********************************************************************/


*------------------------------------------------------------
* User settings
*------------------------------------------------------------

local outcome nnm
local round 5

local outfile "tables/table uncontrolled private interaction all coefs NFHS`round'.tex"


*------------------------------------------------------------
* Load data
*------------------------------------------------------------

do "$paths"
use "$dataset", clear

capture mkdir tables

keep if round == `round'

* Public and private facility births only
keep if home != 1
keep if public == 1 | private == 1

* Keep social groups used in the main comparison
keep if inlist(group, 1, 2, 3, 4, 5)

* Make sure labels are stable
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
* Region definitions
*------------------------------------------------------------

capture drop other_eag
gen other_eag = non_upbihar_focus

label var up_bihar  "UP/Bihar"
label var other_eag "Other EAG states"
label var nonEAG    "Non-EAG states"


*------------------------------------------------------------
* Regressions
*------------------------------------------------------------

eststo clear

reg `outcome' ib4.group##i.private [pw = v005] ///
    if up_bihar == 1, ///
    vce(cluster psu)

eststo up_bihar


reg `outcome' ib4.group##i.private [pw = v005] ///
    if other_eag == 1, ///
    vce(cluster psu)

eststo other_eag


reg `outcome' ib4.group##i.private [pw = v005] ///
    if nonEAG == 1, ///
    vce(cluster psu)

eststo nonEAG


*------------------------------------------------------------
* LaTeX export
*------------------------------------------------------------

esttab up_bihar other_eag nonEAG ///
    using "`outfile'", replace ///
    b(%9.1f) se(%9.1f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    booktabs ///
    nonotes ///
    collabels(none) ///
    mtitles("UP/Bihar" "Other EAG states" "Non-EAG states") ///
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
        _cons "Forward Hindu public" ///
        1.group "Adivasi" ///
        2.group "Dalit" ///
        3.group "OBC" ///
        5.group "Muslim" ///
        1.private "Private" ///
        1.group#1.private "Adivasi $\times$ Private" ///
        2.group#1.private "Dalit $\times$ Private" ///
        3.group#1.private "OBC $\times$ Private" ///
        5.group#1.private "Muslim $\times$ Private" ///
    ) ///
    stats(N, labels("Observations") fmt(%9.0fc))


*------------------------------------------------------------
* Console check
*------------------------------------------------------------

esttab up_bihar other_eag nonEAG, ///
    b(%9.1f) se(%9.1f) ///
    star(* 0.10 ** 0.05 *** 0.01) ///
    label ///
    mtitles("UP/Bihar" "Other EAG states" "Non-EAG states") ///
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
        _cons "Forward Hindu public" ///
        1.group "Adivasi" ///
        2.group "Dalit" ///
        3.group "OBC" ///
        5.group "Muslim" ///
        1.private "Private" ///
        1.group#1.private "Adivasi x Private" ///
        2.group#1.private "Dalit x Private" ///
        3.group#1.private "OBC x Private" ///
        5.group#1.private "Muslim x Private" ///
    ) ///
    stats(N, labels("Observations") fmt(%9.0fc))
