/********************************************************************
Table 1: Characteristics of private vs public facility births
         by social group and region

Entries are private - public differences.
Binary outcomes are in percentage points.
Birth order and wealth quintile are in their original units.

Sample:
  Rural public/private facility births
  NFHS-4 and NFHS-5 pooled
********************************************************************/


*------------------------------------------------------------*
* 1) Load data
*------------------------------------------------------------*

do "$paths"
use "$dataset", clear

capture mkdir tables

keep if inlist(round, 4, 5)
keep if rural == 1
keep if public == 1 | private == 1

* Five social groups shown in the table
keep if inlist(group, 1, 2, 3, 4, 5)

* Prior NNM = 0 for first births
replace prior = 0 if missing(prior) & bord == 1

svyset psu [pw = v005], strata(strata) vce(linearized) singleunit(centered)


*------------------------------------------------------------*
* 2) Regions and column order
*------------------------------------------------------------*

capture drop other_eag
gen other_eag = non_upbihar_focus

local regions up_bihar other_eag nonfocus

local regionname1 "Uttar Pradesh and Bihar"
local regionname2 "Other EAG states"
local regionname3 "Non-EAG states"

local groups 1 2 3 4 5

local groupname1 "Adivasi"
local groupname2 "Dalit"
local groupname3 "OBC"
local groupname4 "Forward"
local groupname5 "Muslim"


*------------------------------------------------------------*
* 3) Variables shown in the table
*
* Binary variables are reported in percentage points.
* Continuous variables are reported in original units.
*------------------------------------------------------------*

local binaryvars ///
    momunder20 ///
    male ///
    multiples ///
    prior ///
    underweight_projected ///
    breech ///
    prolongedlabour ///
    excessivebleed ///
    any_delivery_complication ///
    any_preg_complication ///
    csection ///
    illiterate ///
    eibf ///
    skin

local continuousvars ///
    birth_order ///
    v190


*------------------------------------------------------------*
* 4) Row metadata
*------------------------------------------------------------*

tempname M
tempfile rowmeta

postfile `M' ///
    str40 statvar ///
    str120 rows ///
    str80 section ///
    double section_order ///
    double row_order ///
    double mult ///
    using `rowmeta', replace


* Maternal and birth risk
post `M' ("momunder20")            ("\hspace*{2em}Mother under 20 at birth")              ("Maternal and birth risk")                    (1) (1) (100)
post `M' ("male")                  ("\hspace*{2em}Male child")                            ("Maternal and birth risk")                    (1) (2) (100)
post `M' ("multiples")             ("\hspace*{2em}Multiple birth")                        ("Maternal and birth risk")                    (1) (3) (100)
post `M' ("prior")                 ("\hspace*{2em}Prior neonatal death to mother")         ("Maternal and birth risk")                    (1) (4) (100)
post `M' ("underweight_projected") ("\hspace*{2em}Projected maternal underweight")         ("Maternal and birth risk")                    (1) (5) (100)
post `M' ("birth_order")           ("\hspace*{2em}Birth order")                           ("Maternal and birth risk")                    (1) (6) (1)

* Pregnancy and delivery complications
post `M' ("breech")                    ("\hspace*{2em}Breech presentation")                 ("Pregnancy and delivery complications")       (2) (1) (100)
post `M' ("prolongedlabour")           ("\hspace*{2em}Prolonged labor")                    ("Pregnancy and delivery complications")       (2) (2) (100)
post `M' ("excessivebleed")            ("\hspace*{2em}Excessive bleeding")                 ("Pregnancy and delivery complications")       (2) (3) (100)
post `M' ("any_delivery_complication") ("\hspace*{2em}Any labor problem")                  ("Pregnancy and delivery complications")       (2) (4) (100)
post `M' ("any_preg_complication")     ("\hspace*{2em}Any pregnancy problem")              ("Pregnancy and delivery complications")       (2) (5) (100)
post `M' ("csection")                  ("\hspace*{2em}C-section birth")                     ("Pregnancy and delivery complications")       (2) (6) (100)

* Socioeconomic characteristics
post `M' ("illiterate")            ("\hspace*{2em}Mother illiterate")                     ("Socioeconomic characteristics")              (3) (1) (100)
post `M' ("v190")                  ("\hspace*{2em}Mean wealth quintile (1--5)")            ("Socioeconomic characteristics")              (3) (2) (1)

* Care at birth
post `M' ("eibf")                  ("\hspace*{2em}Breastfeeding initiated within 1 hour")  ("Care at birth")                              (4) (1) (100)
post `M' ("skin")                  ("\hspace*{2em}Skin-to-skin contact")                   ("Care at birth")                              (4) (2) (100)

* General
post `M' ("pct_private")           ("\hspace*{2em}Percent births in private facilities")   ("General")                                    (5) (1) (1)
post `M' ("N")                     ("\hspace*{2em}Sample size")                            ("General")                                    (5) (2) (1)

postclose `M'


*------------------------------------------------------------*
* 5) Estimate private - public differences
*------------------------------------------------------------*

tempname P
tempfile results

postfile `P' ///
    str40 statvar ///
    double col ///
    str30 value ///
    using `results', replace

local col = 0
local rnum = 0

foreach reg of local regions {

    local ++rnum

    foreach g of local groups {

        local ++col

        *----------------------------------------------------*
        * Difference in means: private - public
        *----------------------------------------------------*

        foreach var of local binaryvars {

            local out = "--"

            capture quietly svy: regress `var' private ///
                if `reg' == 1 & group == `g' & !missing(`var')

            if !_rc {
                local b = 100 * _b[private]

                quietly test private
                local p = r(p)

                local stars ""
                if `p' < .10 local stars "*"
                if `p' < .05 local stars "**"
                if `p' < .01 local stars "***"

                local b_s : display %6.1f `b'
                local b_s = strtrim("`b_s'")
                local out "`b_s'`stars'"
            }

            post `P' ("`var'") (`col') ("`out'")
        }


        foreach var of local continuousvars {

            local out = "--"

            capture quietly svy: regress `var' private ///
                if `reg' == 1 & group == `g' & !missing(`var')

            if !_rc {
                local b = _b[private]

                quietly test private
                local p = r(p)

                local stars ""
                if `p' < .10 local stars "*"
                if `p' < .05 local stars "**"
                if `p' < .01 local stars "***"

                local b_s : display %6.2f `b'
                local b_s = strtrim("`b_s'")
                local out "`b_s'`stars'"
            }

            post `P' ("`var'") (`col') ("`out'")
        }


        *----------------------------------------------------*
        * Percent of facility births occurring in private
        *----------------------------------------------------*

        local out "--"

        capture quietly svy: mean private ///
            if `reg' == 1 & group == `g'

        if !_rc {
            matrix T = r(table)
            local m = 100 * T[1,1]

            local m_s : display %6.1f `m'
            local m_s = strtrim("`m_s'")
            local out "`m_s'"
        }

        post `P' ("pct_private") (`col') ("`out'")


        *----------------------------------------------------*
        * Unweighted sample size
        *----------------------------------------------------*

        quietly count if `reg' == 1 & group == `g'
        local n = r(N)

        local n_s : display %12.0fc `n'
        local n_s = strtrim("`n_s'")

        post `P' ("N") (`col') ("`n_s'")
    }
}

postclose `P'


*------------------------------------------------------------*
* 6) Reshape into table columns
*------------------------------------------------------------*

use `results', clear

reshape wide value, i(statvar) j(col)

merge 1:1 statvar using `rowmeta', nogen keep(match)

gen final_order = section_order * 100 + row_order
sort final_order


*------------------------------------------------------------*
* 7) Add section headers and blank rows
*------------------------------------------------------------*

tempfile body headers blanks

save `body', replace

preserve

    keep section section_order
    duplicates drop

    gen statvar = ""
    gen rows = "\textbf{" + section + "}"
    gen row_order = 0
    gen mult = .
    gen final_order = section_order * 100

    foreach i of numlist 1/15 {
        gen value`i' = ""
    }

    save `headers', replace

restore


use `headers', clear

replace rows = ""
replace final_order = final_order - .5

save `blanks', replace


use `body', clear
append using `headers'
append using `blanks'

sort final_order


*------------------------------------------------------------*
* 8) Add blank spacer columns between regions
*------------------------------------------------------------*

gen gap1 = ""
gen gap2 = ""

keep rows ///
    value1 value2 value3 value4 value5 ///
    gap1 ///
    value6 value7 value8 value9 value10 ///
    gap2 ///
    value11 value12 value13 value14 value15


*------------------------------------------------------------*
* 9) Export with listtex
*------------------------------------------------------------*

local outfile "tables/table1 private public differences by social group and region NFHS4,5.tex"

#delimit ;

listtex rows ///
    value1 value2 value3 value4 value5 ///
    gap1 ///
    value6 value7 value8 value9 value10 ///
    gap2 ///
    value11 value12 value13 value14 value15 ///
    using "`outfile'", replace ///
    rstyle(tabular) ///
    head(
        "\begin{tabular}{l*{5}{c}@{\hspace{1.4em}}c@{\hspace{1.4em}}*{5}{c}@{\hspace{1.4em}}c@{\hspace{1.4em}}*{5}{c}}"
        "\toprule"
        "& \multicolumn{5}{c}{Uttar Pradesh and Bihar} & & \multicolumn{5}{c}{Other EAG states} & & \multicolumn{5}{c}{Non-EAG states} \\"
        "\cmidrule(lr){2-6} \cmidrule(lr){8-12} \cmidrule(lr){14-18}"
        "\addlinespace[0.25em]"
        "& \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim & & \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim & & \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim \\"
        "\midrule"
    )
    foot(
        "\bottomrule"
        "\end{tabular}"
    );

#delimit cr


*------------------------------------------------------------*
* 10) Quick manual check
*------------------------------------------------------------*

display "BROWSE DATA EDITOR TO SEE RESULTS IN STATA DIRECTLY"
browse
