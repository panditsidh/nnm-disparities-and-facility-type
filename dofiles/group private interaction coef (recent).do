/********************************************************************
Table: Difference in private-public NNM gap relative to Forward Hindus

Rows:
    UP & Bihar
    Other EAG states
    Non-EAG India

Columns:
    Adivasi
    Dalit
    OBC
    Muslim

Each cell reports the coefficient on:

    group x private

from a regression restricted to:
    Forward Hindu + Adivasi + Dalit + OBC + Muslim
    public + private facility births
    rural births
    selected NFHS rounds

Regression:

    NNM_i = alpha
          + beta_g Group_i
          + beta_p Private_i
          + beta_gp Group_i x Private_i
          + X_i gamma
          + district FE
          + error_i

with Forward Hindu as the omitted/base social group.

The reported coefficient for each group is:

    (Group private - Group public)
    -
    (Forward private - Forward public)

Controls are common across groups; they are NOT interacted with group.

Suppression / flag policy:
    Suppress and show "--" if any of the four cells has:
        - fewer than 300 births, OR
        - fewer than 10 neonatal deaths

    Flag with "!" if any of the four cells has:
        - 300-500 births, OR
        - 10-20 neonatal deaths

Four cells:
    Forward Hindu public
    Forward Hindu private
    Comparison group public
    Comparison group private
********************************************************************/


*------------------------------------------------------------
* User settings
*------------------------------------------------------------

local outcome nnm

local regions up_bihar non_upbihar_focus nonfocus

local groups 1 2 3 5

local groupname1 "Adivasi"
local groupname2 "Dalit"
local groupname3 "OBC"
local groupname5 "Muslim"

local residence rural
local r 4,5


* Regression controls
* Controls are common across groups, not interacted with group.
local controls i.prior i.underweight_projected i.male i.momunder20 i.multiples i.v190 i.birth_order i.illiterate i.round


* Suppression / flag thresholds
local min_births_show 300
local min_deaths_show 10

local min_births_clean 500
local min_deaths_clean 20


local outfile "tables/table private interaction relative to forward `residence' NFHS`r'.tex"


*------------------------------------------------------------
* Load data and prepare
*------------------------------------------------------------

do "$paths"
use "$dataset", clear


replace prior = 0 if missing(prior)

* Restrict to public and private facility births only
drop if home == 1

keep if inlist(round, `r')
keep if `residence' == 1

drop if group == 6 | missing(group)

* Keep only groups used in table:
* 1 Adivasi, 2 Dalit, 3 OBC, 4 Forward Hindu, 5 Muslim
keep if inlist(group, 1, 2, 3, 4, 5)


* Neonatal death indicator from nnm coded 0/1000
capture drop nd
gen nd = .
replace nd = 1 if `outcome' == 1000
replace nd = 0 if `outcome' == 0


*------------------------------------------------------------
* Group labels
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
* Temporary postfile
*------------------------------------------------------------

tempfile results
capture postclose handle

postfile handle ///
    str40 region ///
    str80 adivasi ///
    str80 dalit ///
    str80 obc ///
    str80 muslim ///
    using `results', replace


*------------------------------------------------------------
* Loop over regions
*------------------------------------------------------------

foreach region of local regions {

    * Use variable label as row name; fall back to variable name
    local reglabel : variable label `region'
    if "`reglabel'" == "" local reglabel "`region'"

    * Initialize cells
    local adivasi "--"
    local dalit "--"
    local obc "--"
    local muslim "--"


    *--------------------------------------------------------
    * Run one interaction regression per region
    *
    * ib4.group makes Forward Hindu the omitted/base category.
    * Coefficients on:
    *   1.group#1.private
    *   2.group#1.private
    *   3.group#1.private
    *   5.group#1.private
    *
    * are the private-public NNM gaps relative to Forward Hindus.
    *--------------------------------------------------------

    capture noisily reghdfe `outcome' ///
        ib4.group##i.private ///
        `controls' ///
        [aw = v005] ///
        if `region' == 1, ///
        cluster(psu) absorb(sdist)

    if _rc != 0 {
        post handle ///
            ("`reglabel'") ///
            ("`adivasi'") ///
            ("`dalit'") ///
            ("`obc'") ///
            ("`muslim'")
        continue
    }


    *--------------------------------------------------------
    * Loop over social groups and extract interaction terms
    *--------------------------------------------------------

    foreach g of local groups {

        local cell "--"

        *----------------------------------------------------
        * Suppression / flag logic using actual regression sample
        *
        * Need enough observations in all four cells:
        *   Forward public
        *   Forward private
        *   Comparison public
        *   Comparison private
        *----------------------------------------------------

        quietly count if e(sample) & group == 4 & private == 0
        local n_fwd_public = r(N)

        quietly summarize nd if e(sample) & group == 4 & private == 0, meanonly
        local deaths_fwd_public = r(sum)

        quietly count if e(sample) & group == 4 & private == 1
        local n_fwd_private = r(N)

        quietly summarize nd if e(sample) & group == 4 & private == 1, meanonly
        local deaths_fwd_private = r(sum)

        quietly count if e(sample) & group == `g' & private == 0
        local n_comp_public = r(N)

        quietly summarize nd if e(sample) & group == `g' & private == 0, meanonly
        local deaths_comp_public = r(sum)

        quietly count if e(sample) & group == `g' & private == 1
        local n_comp_private = r(N)

        quietly summarize nd if e(sample) & group == `g' & private == 1, meanonly
        local deaths_comp_private = r(sum)


        local show_cell = 0
        local flag_cell = 0

        if `n_fwd_public'        >= `min_births_show' & ///
           `n_fwd_private'       >= `min_births_show' & ///
           `n_comp_public'       >= `min_births_show' & ///
           `n_comp_private'      >= `min_births_show' & ///
           `deaths_fwd_public'   >= `min_deaths_show' & ///
           `deaths_fwd_private'  >= `min_deaths_show' & ///
           `deaths_comp_public'  >= `min_deaths_show' & ///
           `deaths_comp_private' >= `min_deaths_show' {

            local show_cell = 1

            if `n_fwd_public'        < `min_births_clean' | ///
               `n_fwd_private'       < `min_births_clean' | ///
               `n_comp_public'       < `min_births_clean' | ///
               `n_comp_private'      < `min_births_clean' | ///
               `deaths_fwd_public'   < `min_deaths_clean' | ///
               `deaths_fwd_private'  < `min_deaths_clean' | ///
               `deaths_comp_public'  < `min_deaths_clean' | ///
               `deaths_comp_private' < `min_deaths_clean' {

                local flag_cell = 1
            }
        }


        *----------------------------------------------------
        * Extract interaction coefficient and stars
        *----------------------------------------------------

        if `show_cell' == 1 {

            * Confirm coefficient exists before extracting
            capture confirm matrix e(b)
            if _rc == 0 {

                capture local beta = _b[`g'.group#1.private]

                if _rc == 0 {

                    quietly test `g'.group#1.private
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
            }
        }


        *----------------------------------------------------
        * Store by group
        *----------------------------------------------------

        if `g' == 1 local adivasi "`cell'"
        if `g' == 2 local dalit "`cell'"
        if `g' == 3 local obc "`cell'"
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
    listtex region adivasi dalit obc muslim ///
        using "`outfile'", replace ///
        rstyle(tabular) ///
        head("\begin{tabular}{lcccc}" ///
             "\hline" ///
             "Region & Adivasi & Dalit & OBC & Muslim \\" ///
             "\hline") ///
        foot("\hline" ///
             "\end{tabular}")
}
