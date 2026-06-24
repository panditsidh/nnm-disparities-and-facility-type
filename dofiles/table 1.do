*------------------------------------------------------------
* User settings
*------------------------------------------------------------

local outcome nnm
local mult 1              // use 1 if nnm is already 0/1000; use 1000 if outcome is 0/1

local r 5
local outfile "tables/table_nnm_levels_by_group_nfhs`r'.tex"

local nrows 7

local rowlabel1 "All India"
local rowcond1  "india == 1"

local rowlabel2 "Rural India"
local rowcond2  "rural == 1"

local rowlabel3 "Urban India"
local rowcond3  "urban == 1"

local rowlabel4 "Rural EAG"
local rowcond4  "rural == 1 & EAG == 1"

local rowlabel5 "Urban EAG"
local rowcond5  "urban == 1 & EAG == 1"

local rowlabel6 "Rural non-EAG"
local rowcond6  "rural == 1 & nonEAG == 1"

local rowlabel7 "Urban non-EAG"
local rowcond7  "urban == 1 & nonEAG == 1"

local groups 4 1 2 3 5


*------------------------------------------------------------
* Load data and set survey design
*------------------------------------------------------------

do "$paths"
use "$dataset", clear

keep if round == `r'
drop if missing(`outcome', group)
drop if group == 6

capture gen india = 1
capture gen EAG = focus
capture gen nonEAG = !focus

gen y = `outcome' * `mult'

svyset psu [pw = v005], strata(strata) vce(linearized) singleunit(centered)


*------------------------------------------------------------
* Store results
*------------------------------------------------------------

tempfile results
capture postclose handle

postfile handle ///
    str30 region ///
    str30 forward ///
    str30 adivasi ///
    str30 dalit ///
    str30 obc ///
    str30 muslim ///
    using `results', replace


*------------------------------------------------------------
* Loop over rows and social groups
*------------------------------------------------------------

forvalues i = 1/`nrows' {

    local rowlabel "`rowlabel`i''"
    local rowcond  "`rowcond`i''"

    foreach g of local groups {

        local cell`g' "--"

        quietly count if `rowcond' & group == `g' & !missing(y)

        if r(N) > 0 {

            capture quietly svy: mean y if `rowcond' & group == `g' & !missing(y)

            if _rc == 0 {
                matrix T = r(table)

                local mean = T[1,1]
                local ll   = T[5,1]
                local ul   = T[6,1]

                local mean_s : display %5.1f `mean'
                local ll_s   : display %5.1f `ll'
                local ul_s   : display %5.1f `ul'

                local mean_s = strtrim("`mean_s'")
                local ll_s   = strtrim("`ll_s'")
                local ul_s   = strtrim("`ul_s'")

                local cell`g' "`mean_s' [`ll_s', `ul_s']"
            }
        }
    }

    post handle ///
        ("`rowlabel'") ///
        ("`cell4'") ///
        ("`cell1'") ///
        ("`cell2'") ///
        ("`cell3'") ///
        ("`cell5'")
}

postclose handle


*------------------------------------------------------------
* Display table in console
*------------------------------------------------------------

use `results', clear

list, noobs clean abbreviate(30)


*------------------------------------------------------------
* Export with listtex
*------------------------------------------------------------

capture which listtex
if _rc == 0 {
    listtex region forward adivasi dalit obc muslim ///
        using "`outfile'", replace ///
        rstyle(tabular) ///
        head("\begin{tabular}{lccccc}" ///
             "\hline" ///
             "Region & Forward Hindu & Adivasi & Dalit & OBC & Muslim \\" ///
             "\hline") ///
        foot("\hline" ///
             "\end{tabular}")
}
