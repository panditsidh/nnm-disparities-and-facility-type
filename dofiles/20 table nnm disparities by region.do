

/********************************************************************
Table: NNM disparities by social group and region

Rows:
    India
    UP & Bihar
    Other EAG states
    Non-EAG India

Columns:
    Forward Hindu NNM
    Adivasi gap
    Dalit gap
    OBC gap
    Muslim gap

Table policy:
    Suppress and show "--" if:
        - Forward Hindu births < 50, OR
        - comparison group births < 50, OR
        - comparison group neonatal deaths < 5

    Flag with "!" if:
        - Forward Hindu births are 50-99, OR
        - comparison group births are 50-99, OR
        - comparison group neonatal deaths are 5-9

Notes:
    - Forward Hindu is group == 4.
    - Gaps are estimated as: group mean - Forward Hindu mean.
    - If nnm is coded 0/1, local mult = 1000 reports deaths per 1,000 births.
    - If nnm is already scaled, change local mult to 1.
********************************************************************/


*------------------------------------------------------------
* User settings
*------------------------------------------------------------

local outcome nnm
local mult 1

local regions up_bihar non_upbihar_focus nonfocus

local groups 1 2 3 5

local groupname1 "Adivasi"
local groupname2 "Dalit"
local groupname3 "OBC"
local groupname5 "Muslim"



local residence urban
local facility private
local r =  5


* Suppression / flag thresholds
local min_births_show 300
local min_deaths_show 10

local min_births_clean 500
local min_deaths_clean 20


local outfile "tables/table nnm disparities `residence' `facility' NFHS`r'.tex"




*------------------------------------------------------------
* Load data and set survey design
*------------------------------------------------------------


do "$paths"
use "$dataset", clear

gen india = 1 
label var india "All India"

gen all = 1

gen nd = nnm/1000

svyset psu [pw = v005], strata(strata) vce(linearized) singleunit(centered)

drop if group == 6 | group == .




keep if round==`r'
keep if `residence'==1
keep if `facility'==1



*------------------------------------------------------------
* Optional: make sure group labels exist
*------------------------------------------------------------

label define group_lbl ///
    1 "Adivasi" ///
    2 "Dalit" ///
    3 "OBC" ///
    4 "Forward Hindu" ///
    5 "Muslim" ///
    6 "Christian, Sikh, Jain", replace

label values group group_lbl


*------------------------------------------------------------
* Temporary postfile to store formatted table
*------------------------------------------------------------

tempfile results

capture postclose handle

postfile handle ///
    str40 region ///
    str20 forward_nnm ///
    str20 adivasi_gap ///
    str20 dalit_gap ///
    str20 obc_gap ///
    str20 muslim_gap ///
    using `results', replace


*------------------------------------------------------------
* Loop over regions
*------------------------------------------------------------

foreach r of local regions {

    * Use variable label as row name; fall back to variable name if unlabeled
    local reglabel : variable label `r'
    if "`reglabel'" == "" local reglabel "`r'"

    *--------------------------------------------------------
    * Get unweighted Forward Hindu sample size and deaths
    *--------------------------------------------------------

    quietly count if `r' == 1 & group == 4 & !missing(`outcome')
    local n_fwd = r(N)

    quietly summarize `outcome' if `r' == 1 & group == 4 & !missing(`outcome'), meanonly
    local deaths_fwd = r(sum)

    * Forward Hindu display policy
    local fwd_s "--"
    local fwd_ok = 0
    local fwd_flag = 0

    if `n_fwd' >= `min_births_show' & `deaths_fwd' >= `min_deaths_show' {
        local fwd_ok = 1

        if `n_fwd' < `min_births_clean' | `deaths_fwd' < `min_deaths_clean' {
            local fwd_flag = 1
        }
    }

    *--------------------------------------------------------
    * Run survey regression only if Forward Hindu exists
    * and region has usable observations
    *--------------------------------------------------------

    capture noisily svy: regress `outcome' ib4.group ///
        if `r' == 1 & inlist(group, 1, 2, 3, 4, 5) & !missing(`outcome')

    if _rc != 0 {
        local forward_nnm "--"
        local adivasi_gap "--"
        local dalit_gap "--"
        local obc_gap "--"
        local muslim_gap "--"

        post handle ///
            ("`reglabel'") ///
            ("`forward_nnm'") ///
            ("`adivasi_gap'") ///
            ("`dalit_gap'") ///
            ("`obc_gap'") ///
            ("`muslim_gap'")

        continue
    }

    *--------------------------------------------------------
    * Forward Hindu NNM
    *--------------------------------------------------------

    if `fwd_ok' == 1 {
        local fwd = _b[_cons] * `mult'
        local fwd_s : display %9.1f `fwd'
        local fwd_s = strtrim("`fwd_s'")

        if `fwd_flag' == 1 {
            local fwd_s "!" + "`fwd_s'"
        }
    }

    local forward_nnm "`fwd_s'"


    *--------------------------------------------------------
    * Gaps and significance stars
    *--------------------------------------------------------

    foreach g of local groups {

        * Default is suppressed
        local gap_s "--"

        * Check comparison group unweighted births and deaths
        quietly count if `r' == 1 & group == `g' & !missing(`outcome')
        local n_g = r(N)

        quietly summarize nd if `r' == 1 & group == `g' & !missing(`outcome'), meanonly
        local deaths_g = r(sum)

        * Apply suppression rule
        local show_gap = 0
        local flag_gap = 0

        if `n_fwd' >= `min_births_show' & ///
           `n_g'   >= `min_births_show' & ///
           `deaths_g' >= `min_deaths_show' {

            local show_gap = 1

            if `n_fwd' < `min_births_clean' | ///
               `n_g'   < `min_births_clean' | ///
               `deaths_g' < `min_deaths_clean' {

                local flag_gap = 1
            }
        }

        * Only estimate/display if cell passes policy and coefficient exists
        if `show_gap' == 1 {

            capture confirm matrix e(b)

            capture local gap = _b[`g'.group] * `mult'

            if _rc == 0 {

                quietly test `g'.group
                local p = r(p)

                local stars ""
                if `p' < 0.01 {
                    local stars "***"
                }
                else if `p' < 0.05 {
                    local stars "**"
                }
                else if `p' < 0.10 {
                    local stars "*"
                }

                local gap_s : display %9.1f `gap'
                local gap_s = strtrim("`gap_s'") + "`stars'"

                if `flag_gap' == 1 {
                    local gap_s "!" + "`gap_s'"
                }
            }
            else {
                local gap_s "--"
            }
        }

        if `g' == 1 local adivasi_gap "`gap_s'"
        if `g' == 2 local dalit_gap "`gap_s'"
        if `g' == 3 local obc_gap "`gap_s'"
        if `g' == 5 local muslim_gap "`gap_s'"
    }


    *--------------------------------------------------------
    * Post row
    *--------------------------------------------------------

    post handle ///
        ("`reglabel'") ///
        ("`forward_nnm'") ///
        ("`adivasi_gap'") ///
        ("`dalit_gap'") ///
        ("`obc_gap'") ///
        ("`muslim_gap'")
}

postclose handle


*------------------------------------------------------------
* Load and display final table
*------------------------------------------------------------

use `results', clear

list, noobs clean abbreviate(20)


*------------------------------------------------------------
* Export options
*------------------------------------------------------------




* Optional LaTeX export using listtex, if installed
capture which listtex
if _rc == 0 {
    listtex region forward_nnm adivasi_gap dalit_gap obc_gap muslim_gap ///
        using "`outfile'", replace ///
        rstyle(tabular) ///
        head("\begin{tabular}{lccccc}" ///
             "\hline" ///
             "Region & Forward Hindu NNM & Adivasi gap & Dalit gap & OBC gap & Muslim gap \\" ///
             "\hline") ///
        foot("\hline" ///
             "\end{tabular}")
}


/********************************************************************
Suggested table note:

Forward Hindu NNM reports the survey-weighted neonatal mortality rate
for Forward Hindus in deaths per 1,000 births. Gaps report the
difference between each group's NNM and Forward Hindu NNM in the same
region. Cells are suppressed with "--" if either the Forward Hindu or
comparison group has fewer than 50 unweighted births, or if the
comparison group has fewer than 5 neonatal deaths. Estimates marked
with "!" are based on 50-99 unweighted births in either group or 5-9
neonatal deaths in the comparison group. Stars denote significance of
the group gap relative to Forward Hindus: * p<0.10, ** p<0.05,
*** p<0.01.
********************************************************************/
