/********************************************************************
NNM BY SOCIAL GROUP
PUBLIC VS PRIVATE FACILITY BIRTHS

Survey-weighted means + 95% CIs
Uses postfile + scatter + rcap

X-axis ordered from HIGHEST private NNM to LOWEST private NNM
********************************************************************/

do "$paths"
use "$dataset", clear

keep if inlist(round,4,5)
keep if rural==1
// keep if up_bihar==1

replace v024 = state

keep if public==1 | private==1
keep if inlist(group,1,2,3,4,5)

drop if missing(nnm)
drop if missing(v005)
drop if missing(psu)

*------------------------------------------------------------*
* SURVEY SETUP
*------------------------------------------------------------*

egen psu_svy = group(round psu)
egen strata_svy = group(round v024 v025)

svyset psu_svy [pw=v005], ///
    strata(strata_svy) ///
    singleunit(centered)

*------------------------------------------------------------*
* POSTFILE FOR ESTIMATES
*------------------------------------------------------------*

tempfile results
tempname memhold

postfile `memhold' ///
    int group ///
    byte private ///
    double mean ///
    double lb ///
    double ub ///
    using `results', replace

*------------------------------------------------------------*
* ESTIMATE EACH GROUP × FACILITY CELL
*------------------------------------------------------------*

forvalues g = 1/5 {

    foreach p in 0 1 {

        quietly svy, subpop(if group==`g' & private==`p'): mean nnm

        matrix b = e(b)
        matrix V = e(V)

        scalar m  = b[1,1]
        scalar se = sqrt(V[1,1])

        scalar lo = m - invnormal(.975)*se
        scalar hi = m + invnormal(.975)*se

        post `memhold' ///
			(`g') ///
			(`p') ///
			(m) ///
			(lo) ///
			(hi)
    }
}

postclose `memhold'


*------------------------------------------------------------*
* LOAD RESULTS
*------------------------------------------------------------*

use `results', clear

* Reapply social-group labels
label define group_lbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward Hindu" ///
    5 "Muslim" ///
    6 "Christian, Sikh, Jain", replace

label values group group_lbl


*------------------------------------------------------------*
* ORDER BY PRIVATE NNM: HIGHEST TO LOWEST
*------------------------------------------------------------*

gen order = .

replace order = 1 if group==2   // Dalit
replace order = 2 if group==5   // Muslim
replace order = 3 if group==3   // OBC
replace order = 4 if group==1   // Adivasi
replace order = 5 if group==4   // Forward Hindu

label define order_lbl ///
    1 "Dalit" ///
    2 "Muslim" ///
    3 "OBC" ///
    4 "Adivasi" ///
    5 "Forward Hindu", replace

label values order order_lbl

sort order private


*------------------------------------------------------------*
* PRIVATE LEFT, PUBLIC RIGHT
*------------------------------------------------------------*

gen x = order - .10 if private==1
replace x = order + .10 if private==0


*------------------------------------------------------------*
* GRAPH
*------------------------------------------------------------*

twoway ///
    (rcap lb ub x if private==1, lcolor(blue)) ///
    (scatter mean x if private==1, ///
        mcolor(blue) msymbol(O) msize(medlarge)) ///
    (rcap lb ub x if private==0, lcolor(green)) ///
    (scatter mean x if private==0, ///
        mcolor(green) msymbol(O) msize(medlarge)), ///
    xlabel( ///
        1 "Dalit" ///
        2 "Muslim" ///
        3 "OBC" ///
        4 "Adivasi" ///
        5 "Forward Hindu", ///
        nogrid) ///
    xtitle("") ///
    ytitle("Neonatal deaths per 1,000 births") ///
    legend(order(2 "Private" 4 "Public"))
	
	
	
graph export "figures/figure 2 nnm gaps by social group.pdf", as(pdf) replace
