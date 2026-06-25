/********************************************************************
 Summary statistics table
 NFHS-5 only, UP and Bihar only

 Columns:
   Social group headers
   Public / Private within each social group

 Rows:
   Existing risk variables from gen vars + v190 wealth quintile dummies
   + mean delivery OOP expenditure

 Output:
   tables/summary_stats_up_bihar_nfhs5.tex
********************************************************************/

do "$paths"
use "$dataset", clear

capture mkdir tables

local outfile "tables/summary_stats_up_bihar_nfhs5.tex"

*------------------------------------------------------------
* Sample
*------------------------------------------------------------

keep if round == 5
keep if rural==1
keep if up_bihar == 1
keep if inlist(group, 1, 2, 3, 4, 5)
keep if public == 1 | private == 1

gen facility_pubpriv = .
replace facility_pubpriv = 1 if public == 1
replace facility_pubpriv = 2 if private == 1

label define facility_pubpriv_lbl 1 "Public" 2 "Private", replace
label values facility_pubpriv facility_pubpriv_lbl


*------------------------------------------------------------
* Clean delivery out-of-pocket expenditure
*
* NFHS-5: s454
* 99998 = Don't know
* Values above 60,000 excluded as top 1%
*------------------------------------------------------------

cap drop deliv_oop_cost_raw
cap drop deliv_oop_cost

gen deliv_oop_cost_raw = .
replace deliv_oop_cost_raw = s454 if round == 5 & inrange(s454, 0, 99994)

gen deliv_oop_cost = deliv_oop_cost_raw
replace deliv_oop_cost = . if deliv_oop_cost > 60000

label var deliv_oop_cost "Mean OOP delivery cost, Rs"


*------------------------------------------------------------
* Wealth quintile dummies from v190
*------------------------------------------------------------

capture drop wealth_*
tab v190, gen(wealth_)

label var wealth_1 "Poorest"
label var wealth_2 "Poorer"
label var wealth_3 "Middle"
label var wealth_4 "Richer"
label var wealth_5 "Richest"


*------------------------------------------------------------
* Row labels
*------------------------------------------------------------

label var momunder20              "Mother under 20 at birth"
label var male                    "Male child"
label var multiples               "Birth was a multiple"
label var prior                   "Prior neonatal death to mother"
label var underweight_projected   "Mother BMI $<$ 18.5 (projected)"
label var vaginal                 "Vaginal birth"
label var breech                  "Breech"
label var prolongedlabour         "Prolonged labor"
label var excessivebleed          "Excessive bleeding"
label var any_delivery_complication "Any labor problem"
label var illiterate              "Mother is illiterate"

* If your pregnancy-problem variable has a different name, change this local only.
local pregvar any_preg_complication
label var `pregvar' "Any pregnancy problem"


*------------------------------------------------------------
* Variables to report
*
* pctvars: binary variables reported as percentages
* meanvars: continuous variables reported as means
*------------------------------------------------------------

local pctvars ///
    momunder20 ///
    male ///
    multiples ///
    prior ///
    underweight_projected ///
    vaginal ///
    breech ///
    prolongedlabour ///
    excessivebleed ///
    any_delivery_complication ///
    `pregvar' ///
    illiterate ///
    wealth_1 ///
    wealth_2 ///
    wealth_3 ///
    wealth_4 ///
    wealth_5

local meanvars ///
    deliv_oop_cost


*------------------------------------------------------------
* Stack variables into long format
*------------------------------------------------------------

tempfile stacked
local i = 0

foreach v of local pctvars {

    local ++i

    preserve

        keep group facility_pubpriv v005 `v'
        keep if !missing(group, facility_pubpriv, `v')

        gen roworder = `i'
        gen row = "`: variable label `v''"
        gen value = `v'
        gen byte is_pct = 1

        keep roworder row group facility_pubpriv value is_pct v005

        if `i' == 1 {
            save `stacked', replace
        }
        else {
            append using `stacked'
            save `stacked', replace
        }

    restore
}

foreach v of local meanvars {

    local ++i

    preserve

        keep group facility_pubpriv v005 `v'
        keep if !missing(group, facility_pubpriv, `v')

        gen roworder = `i'
        gen row = "`: variable label `v''"
        gen value = `v'
        gen byte is_pct = 0

        keep roworder row group facility_pubpriv value is_pct v005

        append using `stacked'
        save `stacked', replace

    restore
}


use `stacked', clear


*------------------------------------------------------------
* Weighted means
* Percent variables multiplied by 100
* OOP expenditure left in rupees
*------------------------------------------------------------

collapse (mean) value [pw = v005], by(roworder row is_pct group facility_pubpriv)

replace value = 100 * value if is_pct == 1

gen cell = ""
replace cell = string(value, "%9.1f") if is_pct == 1
replace cell = string(value, "%9.0fc") if is_pct == 0

replace cell = "--" if missing(value)


*------------------------------------------------------------
* Reshape to table columns
*------------------------------------------------------------

gen col = ""

replace col = "adivasi_public"  if group == 1 & facility_pubpriv == 1
replace col = "adivasi_private" if group == 1 & facility_pubpriv == 2

replace col = "dalit_public"    if group == 2 & facility_pubpriv == 1
replace col = "dalit_private"   if group == 2 & facility_pubpriv == 2

replace col = "obc_public"      if group == 3 & facility_pubpriv == 1
replace col = "obc_private"     if group == 3 & facility_pubpriv == 2

replace col = "fh_public"       if group == 4 & facility_pubpriv == 1
replace col = "fh_private"      if group == 4 & facility_pubpriv == 2

replace col = "muslim_public"   if group == 5 & facility_pubpriv == 1
replace col = "muslim_private"  if group == 5 & facility_pubpriv == 2

keep roworder row col cell
reshape wide cell, i(roworder row) j(col) string

foreach c in ///
    adivasi_public adivasi_private ///
    dalit_public dalit_private ///
    obc_public obc_private ///
    fh_public fh_private ///
    muslim_public muslim_private {

    capture confirm variable cell`c'
    if _rc {
        gen cell`c' = "--"
    }

    replace cell`c' = "--" if missing(cell`c')
}

sort roworder


*------------------------------------------------------------
* Console check
*------------------------------------------------------------

list row ///
    celladivasi_public celladivasi_private ///
    celldalit_public celldalit_private ///
    cellobc_public cellobc_private ///
    cellfh_public cellfh_private ///
    cellmuslim_public cellmuslim_private, ///
    noobs clean abbreviate(30)


*------------------------------------------------------------
* LaTeX export
*------------------------------------------------------------

capture which listtex

if _rc == 0 {
    listtex row ///
        celladivasi_public celladivasi_private ///
        celldalit_public celldalit_private ///
        cellobc_public cellobc_private ///
        cellfh_public cellfh_private ///
        cellmuslim_public cellmuslim_private ///
        using "`outfile'", replace ///
        rstyle(tabular) ///
        head("\begin{tabular}{lcccccccccc}" ///
             "\hline" ///
             " & \multicolumn{2}{c}{Adivasi} & \multicolumn{2}{c}{Dalit} & \multicolumn{2}{c}{OBC} & \multicolumn{2}{c}{Forward Hindu} & \multicolumn{2}{c}{Muslim} \\" ///
             " & Public & Private & Public & Private & Public & Private & Public & Private & Public & Private \\" ///
             "\hline") ///
        foot("\hline" ///
             "\end{tabular}")
}
else {
    di as error "listtex is not installed. Install it with: ssc install listtex"
}
