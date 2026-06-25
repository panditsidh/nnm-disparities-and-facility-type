do "$paths"
use "$dataset", clear

/********************************************************************
 Oaxaca table: NNM disparities vs Forward Hindu

 Rows within each panel:
   Total gap, deaths per 1,000, with significance stars
   % explained by risk variables
   % explained by wealth
   % explained by facility type
   % explained overall

 Columns:
   Adivasi-Forward, Dalit-Forward, OBC-Forward, Muslim-Forward

 Notes:
   - No district fixed effects.
   - This decomposes the overall group NNM gap.
********************************************************************/


*------------------------------------------------------------
* User settings
*------------------------------------------------------------

local outcome nnm
local round 5

local outfile "tables/oaxaca_nnm_decomposition_nfhs`round'.tex"

* Panels
local npanels 3

local panellabel1 "Panel A. All India"
local panelif1    "india == 1"

local panellabel2 "Panel B. Rural EAG"
local panelif2    "rural == 1 & EAG == 1"

local panellabel3 "Panel C. Rural non-EAG"
local panelif3    "rural == 1 & nonEAG == 1"

* Comparison groups
local groups 1 2 3 5

local groupname1 "Adivasi"
local groupname2 "Dalit"
local groupname3 "OBC"
local groupname5 "Muslim"


*------------------------------------------------------------
* Load data
*------------------------------------------------------------

do "$paths"
use "$dataset", clear

capture mkdir tables

keep if round == `round'
keep if inlist(group, 1, 2, 3, 4, 5)

capture gen india = 1
capture gen EAG = focus
capture gen nonEAG = !focus

* prior is usually missing for first births; don't let Oaxaca drop them
replace prior = 0 if missing(prior) & bord == 1


*------------------------------------------------------------
* Dummies for categorical variables
*------------------------------------------------------------

drop if missing(`outcome', group, prior, underweight_projected, ///
    male, momunder20, birth_order, multiples, illiterate, v190, facility_type)

capture drop bo_* w_* fac_*

tab birth_order, gen(bo_)
tab v190, gen(w_)
tab facility_type, gen(fac_)

capture drop bo_1
capture drop w_1
capture drop fac_1

local risk     prior underweight_projected male momunder20 bo_* multiples illiterate
local wealth   w_*
local facility fac_*

unab riskvars     : `risk'
unab wealthvars   : `wealth'
unab facilityvars : `facility'

local xvars `riskvars' `wealthvars' `facilityvars'


*------------------------------------------------------------
* Postfile
*------------------------------------------------------------

tempfile results
capture postclose handle

postfile handle ///
    str60 row ///
    str25 adivasi ///
    str25 dalit ///
    str25 obc ///
    str25 muslim ///
    using `results', replace


*------------------------------------------------------------
* Main loop
*------------------------------------------------------------

forvalues p = 1/`npanels' {

    local panellabel "`panellabel`p''"
    local panelif    "`panelif`p''"

    * Panel header row
    post handle ///
        ("\textbf{`panellabel'}") ///
        ("") ("") ("") ("")

    * Initialize cells
    foreach rowtype in gap risk wealth facility overall {
        foreach g of local groups {
            local `rowtype'_`g' "--"
        }
    }

    foreach g of local groups {

        preserve

            keep if `panelif'
            keep if inlist(group, `g', 4)

            gen minority = group == `g'

            quietly count
            if r(N) == 0 {
                restore
                continue
            }

            *------------------------------------------------
            * Oaxaca without district FE
            *------------------------------------------------

            capture quietly oaxaca `outcome' ///
                `xvars' ///
                [pw = v005], ///
                by(minority) pooled relax ///
                detail( ///
                    risk: `riskvars', ///
                    wealth: `wealthvars', ///
                    facility: `facilityvars' ///
                )

            if _rc == 0 {

                * oaxaca reports group_1 - group_2.
                * With minority = 0/1, group_1 is usually Forward Hindu
                * and group_2 is usually minority.
                * Flip so table reports minority - Forward Hindu.
                local flip = 1
                if "`e(group_1)'" == "0" & "`e(group_2)'" == "1" {
                    local flip = -1
                }

                * Total gap
                local gap = `flip' * _b[overall:difference]
                local se  = _se[overall:difference]

                local pval = 2 * normal(-abs(`gap' / `se'))

                local stars ""
                if `pval' < .01 local stars "***"
                else if `pval' < .05 local stars "**"
                else if `pval' < .10 local stars "*"

                local gap_s : display %6.1f `gap'
                local gap_s = strtrim("`gap_s'") + "`stars'"

                * Explained contributions
                local risk_c     = `flip' * _b[explained:risk]
                local wealth_c   = `flip' * _b[explained:wealth]
                local facility_c = `flip' * _b[explained:facility]
                local overall_c  = `flip' * _b[overall:explained]

                local risk_pct     = 100 * `risk_c'     / `gap'
                local wealth_pct   = 100 * `wealth_c'   / `gap'
                local facility_pct = 100 * `facility_c' / `gap'
                local overall_pct  = 100 * `overall_c'  / `gap'

                local risk_s     : display %6.1f `risk_pct'
                local wealth_s   : display %6.1f `wealth_pct'
                local facility_s : display %6.1f `facility_pct'
                local overall_s  : display %6.1f `overall_pct'

                local risk_s     = strtrim("`risk_s'")     + "\%"
                local wealth_s   = strtrim("`wealth_s'")   + "\%"
                local facility_s = strtrim("`facility_s'") + "\%"
                local overall_s  = strtrim("`overall_s'")  + "\%"

                local gap_`g'      "`gap_s'"
                local risk_`g'     "`risk_s'"
                local wealth_`g'   "`wealth_s'"
                local facility_`g' "`facility_s'"
                local overall_`g'  "`overall_s'"
            }

        restore
    }

    *--------------------------------------------------------
    * Post rows
    *--------------------------------------------------------

    post handle ///
        ("Total gap") ///
        ("`gap_1'") ///
        ("`gap_2'") ///
        ("`gap_3'") ///
        ("`gap_5'")

    post handle ///
        ("\% explained: risk variables") ///
        ("`risk_1'") ///
        ("`risk_2'") ///
        ("`risk_3'") ///
        ("`risk_5'")

    post handle ///
        ("\% explained: wealth") ///
        ("`wealth_1'") ///
        ("`wealth_2'") ///
        ("`wealth_3'") ///
        ("`wealth_5'")

    post handle ///
        ("\% explained: facility type") ///
        ("`facility_1'") ///
        ("`facility_2'") ///
        ("`facility_3'") ///
        ("`facility_5'")

    post handle ///
        ("\% explained: overall") ///
        ("`overall_1'") ///
        ("`overall_2'") ///
        ("`overall_3'") ///
        ("`overall_5'")

    post handle ("") ("") ("") ("") ("")
}

postclose handle


*------------------------------------------------------------
* Console output
*------------------------------------------------------------

use `results', clear

list, noobs clean abbreviate(30)




*------------------------------------------------------------
* LaTeX export
*------------------------------------------------------------

capture which listtex
if _rc == 0 {
    listtex row adivasi dalit obc muslim ///
        using "`outfile'", replace ///
        rstyle(tabular) ///
        head("\begin{tabular}{lcccc}" ///
             "\hline" ///
             " & Adivasi--Forward & Dalit--Forward & OBC--Forward & Muslim--Forward \\" ///
             "\hline") ///
        foot("\hline" ///
             "\end{tabular}")
}
