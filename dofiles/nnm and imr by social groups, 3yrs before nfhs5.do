*******************************************************
* NFHS-5 neonatal and infant mortality by social group
*
* Birth cohort:
*   NNM: births 1–35 months before the survey
*   IMR: births 12–35 months before the survey
*
* Outcomes are deaths per 1,000 live births.
* Confidence intervals come directly from svy: mean.
*******************************************************

use "$dataset", clear

*******************************************************
* 1. Restrict to NFHS-5 and relevant social groups
*******************************************************

keep if round == 5
keep if inlist(group, 1, 2, 3, 4, 5)

* Completed months between birth and interview
capture drop child_age_mo
gen int child_age_mo = v008 - b3

label variable child_age_mo ///
    "Completed months between birth and interview"

*******************************************************
* 2. Construct mortality outcomes
*******************************************************

*------------------------------------------------------
* Neonatal mortality:
* death before completing one month of life
*------------------------------------------------------

capture drop nnm_fig
gen double nnm_fig = 0 if !missing(b5)

replace nnm_fig = 1000 if ///
    b5 == 0 & b7 == 0

label variable nnm_fig ///
    "Neonatal deaths per 1,000 live births"

*------------------------------------------------------
* Infant mortality:
* death before completing 12 months of life
*------------------------------------------------------

capture drop imr
gen double imr = 0 if !missing(b5)

replace imr = 1000 if ///
    b5 == 0 & b7 < 12 & !missing(b7)

label variable imr ///
    "Infant deaths per 1,000 live births"

*******************************************************
* 3. Define exposure-appropriate analytical samples
*******************************************************

* NNM:
* births during the 3 years before the survey,
* excluding births in the interview month
capture drop nnm_fig_sample
gen byte nnm_fig_sample = ///
    inrange(child_age_mo, 1, 35) & ///
    !missing(nnm_fig, group)

* IMR:
* births during the 3 years before the survey that
* had at least 12 completed months of exposure
capture drop imr_fig_sample
gen byte imr_fig_sample = ///
    inrange(child_age_mo, 12, 35) & ///
    !missing(imr, group)

label variable nnm_fig_sample ///
    "NNM sample: births 1–35 months before survey"

label variable imr_fig_sample ///
    "IMR sample: births 12–35 months before survey"

*******************************************************
* 4. Confirm survey design
*******************************************************

svyset

*******************************************************
* 5. Estimate mortality and confidence intervals
*******************************************************

tempfile mortality_estimates

tempname results

postfile `results' ///
    byte group ///
    str3 outcome ///
    double estimate se lb ub ///
    long n ///
    using `mortality_estimates', replace

foreach g of numlist 1/5 {

    ***************************************************
    * Neonatal mortality
    ***************************************************

    quietly count if ///
        group == `g' & ///
        nnm_fig_sample == 1

    local n_nnm = r(N)

    quietly svy, subpop(if ///
        group == `g' & ///
        nnm_fig_sample == 1): ///
        mean nnm_fig

    matrix T = r(table)

    local est = T[1,1]
    local se  = T[2,1]
    local lb  = T[5,1]
    local ub  = T[6,1]

    post `results' ///
        (`g') ///
        ("NNM") ///
        (`est') ///
        (`se') ///
        (`lb') ///
        (`ub') ///
        (`n_nnm')

    ***************************************************
    * Infant mortality
    ***************************************************

    quietly count if ///
        group == `g' & ///
        imr_fig_sample == 1

    local n_imr = r(N)

    quietly svy, subpop(if ///
        group == `g' & ///
        imr_fig_sample == 1): ///
        mean imr

    matrix T = r(table)

    local est = T[1,1]
    local se  = T[2,1]
    local lb  = T[5,1]
    local ub  = T[6,1]

    post `results' ///
        (`g') ///
        ("IMR") ///
        (`est') ///
        (`se') ///
        (`lb') ///
        (`ub') ///
        (`n_imr')
}

postclose `results'

*******************************************************
* 6. Prepare estimates for graphing
*******************************************************

use `mortality_estimates', clear

* Requested display order:
* Adivasi, Dalit, OBC, Forward Hindu, Muslim
gen byte plot_group = .

replace plot_group = 1 if group == 1
replace plot_group = 2 if group == 2
replace plot_group = 3 if group == 3
replace plot_group = 4 if group == 4
replace plot_group = 5 if group == 5

label define plot_group_lbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward Hindu" ///
    5 "Muslim", replace

label values plot_group plot_group_lbl

* Offset NNM and IMR slightly within each group
gen double x = plot_group

replace x = plot_group - 0.10 if outcome == "NNM"
replace x = plot_group + 0.10 if outcome == "IMR"

format estimate se lb ub %6.1f
format n %12.0fc

sort plot_group outcome

*******************************************************
* 7. Print estimates to the Stata console
*******************************************************

display as text _newline ///
    "NFHS-5 mortality by social group"

display as text ///
    "NNM sample: births 1–35 months before survey"

display as text ///
    "IMR sample: births 12–35 months before survey"

list plot_group outcome estimate se lb ub n, ///
    noobs separator(0) abbreviate(20)

*******************************************************
* 8. Graph NNM and IMR with 95% confidence intervals
*    and point-estimate labels
*******************************************************

twoway ///
    (rcap lb ub x if outcome == "NNM", ///
        lcolor(navy) ///
        lwidth(medium)) ///
    (scatter estimate x if outcome == "NNM", ///
        mcolor(navy) ///
        msymbol(circle) ///
        msize(medium) ///
        mlabel(estimate) ///
        mlabposition(3) ///
        mlabgap(2) ///
        mlabcolor(navy) ///
        mlabformat(%4.1f)) ///
    (rcap lb ub x if outcome == "IMR", ///
        lcolor(cranberry) ///
        lwidth(medium)) ///
    (scatter estimate x if outcome == "IMR", ///
        mcolor(cranberry) ///
        msymbol(diamond) ///
        msize(medium) ///
        mlabel(estimate) ///
        mlabposition(3) ///
        mlabgap(2) ///
        mlabcolor(cranberry) ///
        mlabformat(%4.1f)), ///
    title("Neonatal and infant mortality by social group") ///
    xtitle("") ///
    ytitle("Deaths per 1,000 live births") ///
    xlabel( ///
        1 "Adivasi" ///
        2 "Dalit" ///
        3 "OBC" ///
        4 "Forward Hindu" ///
        5 "Muslim", ///
        angle(0)) ///
    xscale(range(0.5 5.7)) ///
    ylabel(0(10)80, angle(horizontal)) ///
    legend( ///
        order(2 "Neonatal mortality" ///
              4 "Infant mortality") ///
        rows(1) ///
        position(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    name(nfhs5_nnm_imr_by_group, replace)

*******************************************************
* Optional export
*******************************************************

* graph export ///
*     "outputs/nfhs5_nnm_imr_by_group.png", ///
*     width(2400) replace
