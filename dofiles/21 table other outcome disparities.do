*------------------------------------------------------------
* User settings
*------------------------------------------------------------

local outcome deliv_oop_cost
local mult 100

local regions up_bihar non_upbihar_focus nonfocus

local groups 1 2 3 5

local groupname1 "Adivasi"
local groupname2 "Dalit"
local groupname3 "OBC"
local groupname5 "Muslim"

local residence all
local facility private
local r 4,5


* Suppression / flag thresholds
* For breastfeeding, use sample-size thresholds only.
local min_births_show 300
local min_births_clean 500


local outfile "tables/table bf24hr disparities `residence' `facility' NFHS`r'.tex"


*------------------------------------------------------------
* Load data and set survey design
*------------------------------------------------------------

do "$paths"
use "$dataset", clear

gen india = 1
label var india "All India"

gen all = 1

svyset psu [pw = v005], strata(strata) vce(linearized) singleunit(centered)

drop if group == 6 | group == .

keep if inlist(round, `r')
keep if `residence' == 1
keep if `facility' == 1


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
    str20 forward_mean ///
    str20 adivasi_gap ///
    str20 dalit_gap ///
    str20 obc_gap ///
    str20 muslim_gap ///
    using `results', replace


*------------------------------------------------------------
* Loop over regions
*------------------------------------------------------------

foreach reg of local regions {

    * Use variable label as row name; fall back to variable name if unlabeled
    local reglabel : variable label `reg'
    if "`reglabel'" == "" local reglabel "`reg'"

    *--------------------------------------------------------
    * Get Forward Hindu sample size
    *--------------------------------------------------------

    quietly count if `reg' == 1 & group == 4 & !missing(`outcome')
    local n_fwd = r(N)

    * display policy
    local fwd_s "--"
    local fwd_ok = 0
    local fwd_flag = 0

    if `n_fwd' >= `min_births_show' {
        local fwd_ok = 1

        if `n_fwd' < `min_births_clean' {
            local fwd_flag = 1
        }
    }


    *--------------------------------------------------------
    * Run survey regression only if Forward Hindu has usable observations
    *--------------------------------------------------------

    capture noisily svy: regress `outcome' ib4.group ///
        if `reg' == 1 & inlist(group, 1, 2, 3, 4, 5) & !missing(`outcome')

    if _rc != 0 {
        local forward_mean "--"
        local adivasi_gap "--"
        local dalit_gap "--"
        local obc_gap "--"
        local muslim_gap "--"

        post handle ///
            ("`reglabel'") ///
            ("`forward_mean'") ///
            ("`adivasi_gap'") ///
            ("`dalit_gap'") ///
            ("`obc_gap'") ///
            ("`muslim_gap'")

        continue
    }


    *--------------------------------------------------------
    * Forward Hindu mean
    *--------------------------------------------------------

    if `fwd_ok' == 1 {
        local fwd = _b[_cons] * `mult'
        local fwd_s : display %9.1f `fwd'
        local fwd_s = strtrim("`fwd_s'")

        if `fwd_flag' == 1 {
            local fwd_s "!" + "`fwd_s'"
        }
    }

    local forward_mean "`fwd_s'"


    *--------------------------------------------------------
    * Gaps and significance stars
    *--------------------------------------------------------

    foreach g of local groups {

        * Default is suppressed
        local gap_s "--"

        * Check comparison group unweighted births
        quietly count if `reg' == 1 & group == `g' & !missing(`outcome')
        local n_g = r(N)

        * Apply suppression rule
        local show_gap = 0
        local flag_gap = 0

        if `n_fwd' >= `min_births_show' & ///
           `n_g'   >= `min_births_show' {

            local show_gap = 1

            if `n_fwd' < `min_births_clean' | ///
               `n_g'   < `min_births_clean' {

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
        ("`forward_mean'") ///
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
* Optional LaTeX export
*------------------------------------------------------------

capture which listtex

if _rc == 0 {
    listtex region forward_mean adivasi_gap dalit_gap obc_gap muslim_gap ///
        using "`outfile'", replace ///
        rstyle(tabular) ///
        head("\begin{tabular}{lccccc}" ///
             "\hline" ///
             "Region & Forward Hindu mean & Adivasi gap & Dalit gap & OBC gap & Muslim gap \\" ///
             "\hline") ///
        foot("\hline" ///
             "\end{tabular}")
}
