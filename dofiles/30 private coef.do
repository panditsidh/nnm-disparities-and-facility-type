

*------------------------------------------------------------
* User settings
*------------------------------------------------------------

local outcome nnm


local regions up_bihar non_upbihar_focus nonfocus
local groups 1 2 3 4 5

local groupname1 "Adivasi"
local groupname2 "Dalit"
local groupname3 "OBC"
local groupname4 "Forward Hindu"
local groupname5 "Muslim"

local residence rural
local r  4,5



* Regression controls
local controls i.prior i.underweight_projected i.male i.momunder20 i.multiples i.v190 i.birth_order i.illiterate i.round


* Suppression / flag thresholds
local min_births_show 300
local min_deaths_show 10

local min_births_clean 500
local min_deaths_clean 20

local outfile "tables/table private coef `residence' NFHS`r'.tex"


*------------------------------------------------------------
* Load data and prepare
*------------------------------------------------------------

use "$dataset", clear

do "$paths"



replace prior = 0 if missing(prior)



drop if home==1
keep if inlist(round, `r')
keep if `residence'==1


* Neonatal death indicator from nnm coded 0/1000
capture drop nd
gen nd = .
replace nd = 1 if `outcome' == 1000
replace nd = 0 if `outcome' == 0

drop if group == 6 | missing(group)




*------------------------------------------------------------
* Temporary postfile
*------------------------------------------------------------

tempfile results
capture postclose handle

postfile handle ///
    str40 region ///
    str80 adivasi ///
    str80 dalit ///
    str80 obc ///
    str80 forward ///
    str80 muslim ///
    using `results', replace


*------------------------------------------------------------
* Loop over regions
*------------------------------------------------------------

foreach region in `regions' {

    * Use variable label as row name; fall back to variable name
    local reglabel : variable label `region'
    if "`reglabel'" == "" local reglabel "`r'"

    * Initialize cells
    local adivasi "--"
    local dalit "--"
    local obc "--"
    local forward "--"
    local muslim "--"


        *--------------------------------------------------------
    * Loop over social groups
    *--------------------------------------------------------

        *--------------------------------------------------------
    * Loop over social groups
    *--------------------------------------------------------

    foreach g of local groups {

        * Default cell
        local cell "--"

        * Run regression
        reghdfe `outcome' i.private `controls' [aw = v005] ///
            if `region' == 1 & group == `g', cluster(psu) absorb(sdist)

        * Suppression / flag logic using actual regression sample
        quietly count if e(sample) & private == 1
        local n_private = r(N)

        quietly summarize nd if e(sample) & private == 1, meanonly
        local deaths_private = r(sum)

        quietly count if e(sample) & private == 0
        local n_nonprivate = r(N)

        quietly summarize nd if e(sample) & private == 0, meanonly
        local deaths_nonprivate = r(sum)

        local show_cell = 0
        local flag_cell = 0

        if `n_private'    >= `min_births_show' & ///
           `n_nonprivate' >= `min_births_show' & ///
           `deaths_private'    >= `min_deaths_show' & ///
           `deaths_nonprivate' >= `min_deaths_show' {

            local show_cell = 1

            if `n_private'    < `min_births_clean' | ///
               `n_nonprivate' < `min_births_clean' | ///
               `deaths_private'    < `min_deaths_clean' | ///
               `deaths_nonprivate' < `min_deaths_clean' {

                local flag_cell = 1
            }
        }

        if `show_cell' == 1 {

            local beta = _b[1.private]

            quietly test 1.private
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

            local beta_s : display %9.1f `beta'
            local beta_s = strtrim("`beta_s'") + "`stars'"

            if `flag_cell' == 1 {
                local beta_s "!" + "`beta_s'"
            }

            local cell "`beta_s'"
        }

        * Store by group
        if `g' == 1 local adivasi "`cell'"
        if `g' == 2 local dalit "`cell'"
        if `g' == 3 local obc "`cell'"
        if `g' == 4 local forward "`cell'"
        if `g' == 5 local muslim "`cell'"
    }

    *--------------------------------------------------------
    * Post region row
    *--------------------------------------------------------

    post handle ///
        ("`reglabel'") ///
        ("`adivasi'") ///
        ("`dalit'") ///
        ("`obc'") ///
        ("`forward'") ///
        ("`muslim'")
}

postclose handle


*------------------------------------------------------------
* Load and display final table
*------------------------------------------------------------

use `results', clear

list, noobs clean abbreviate(20)


*------------------------------------------------------------
* Export LaTeX
*------------------------------------------------------------

capture which listtex
if _rc == 0 {
    listtex region adivasi dalit obc forward muslim ///
        using "`outfile'", replace ///
        rstyle(tabular) ///
        head("\begin{tabular}{lccccc}" ///
             "\hline" ///
             "Region & Adivasi & Dalit & OBC & Forward Hindu & Muslim \\" ///
             "\hline") ///
        foot("\hline" ///
             "\end{tabular}")
}

