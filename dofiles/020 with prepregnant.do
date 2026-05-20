/*
Table 1: Descriptive statistics by social group and pregnancy status

Dynamic version

How to edit:
- Put 0/1 variables in `binaryvars`
    - row labels come from variable labels
- Put categorical variables in `catvars`
    - section headers come from variable labels
    - indented row labels come from value labels

Example:
    local catvars agebin parity_bs wealth_q5

As long as wealth_q5 has a variable label and value labels, the table updates automatically.
*/

do "$paths"
use "$dataset", clear

drop if group == . | group == 6

*------------------------------------------------------------*
* 0) Create prepregnancy reweighting function
*------------------------------------------------------------*

global binvars agebin rural less_edu noboy group
qui do "dofiles/00 resubmission/040 reweighting.do"


*------------------------------------------------------------*
* 1) Define variables shown in Table 1
*------------------------------------------------------------*

local binaryvars less_edu rural noboy 
local catvars agebin 

local outfile "tables/table1 sumstats NEW.tex"


*------------------------------------------------------------*
* 2) Build dynamic variable list and row metadata
*------------------------------------------------------------*

tempname rowpost
tempfile rowmeta

postfile `rowpost' ///
    str32 statvar ///
    str200 rows ///
    str200 section ///
    double section_order ///
    double row_order ///
    using `rowmeta', replace

local meanvars
local section_order = 1


*-----------------------------*
* Binary predictors
*-----------------------------*

local binary_section "Binary Predictors"
local row_order = 1

foreach var of local binaryvars {

    local meanvars `meanvars' `var'

    local vlabel : variable label `var'
    if `"`vlabel'"' == "" local vlabel "`var'"

    post `rowpost' ///
        ("`var'") ///
        (`"\hspace*{2em}`vlabel'"') ///
        (`"`binary_section'"') ///
        (`section_order') ///
        (`row_order')

    local ++row_order
}

local ++section_order


*-----------------------------*
* Categorical predictors
*-----------------------------*

local catnum = 1

foreach cat of local catvars {

    local section_label : variable label `cat'
    if `"`section_label'"' == "" local section_label "`cat'"

    local vallab : value label `cat'

    levelsof `cat' if !missing(`cat'), local(levels)

    local row_order = 1

    foreach lev of local levels {

        local dvar __cat`catnum'_`row_order'

        gen `dvar' = (`cat' == `lev') if !missing(`cat')

        local meanvars `meanvars' `dvar'

        if "`vallab'" != "" {
            local levlabel : label `vallab' `lev'
        }
        else {
            local levlabel "`lev'"
        }

        if `"`levlabel'"' == "" local levlabel "`lev'"

        post `rowpost' ///
            ("`dvar'") ///
            (`"\hspace*{2em}`levlabel'"') ///
            (`"`section_label'"') ///
            (`section_order') ///
            (`row_order')

        local ++row_order
    }

    local ++catnum
    local ++section_order
}


*-----------------------------*
* N row
*-----------------------------*

post `rowpost' ///
    ("N") ///
    (`"\textbf{N}"') ///
    ("") ///
    (999) ///
    (1)

postclose `rowpost'


*------------------------------------------------------------*
* 3) Keep only what is needed
*------------------------------------------------------------*

keep preg group v005 reweightingfxn `meanvars'
gen ones = 1


*------------------------------------------------------------*
* 4) Compute true unweighted N by pregnancy status and group
*    Include pooled "All five groups" N dynamically
*    Also add prepregnant pooled N
*------------------------------------------------------------*

preserve

    keep if !missing(preg)

    tempfile N_by_group N_pooled N_prepreg Ntrue

    collapse (count) N = ones, by(preg group)
    save `N_by_group', replace

restore

preserve

    keep if !missing(preg)
    collapse (count) N = ones, by(preg)
    gen group = 0
    save `N_pooled', replace

restore

preserve

    keep if preg == 0 & !missing(reweightingfxn)
    collapse (count) N = ones
    gen preg = 2
    gen group = 0
    save `N_prepreg', replace

restore

preserve

    use `N_by_group', clear
    append using `N_pooled'
    append using `N_prepreg'
    save `Ntrue', replace

restore


*------------------------------------------------------------*
* 5) Compute prepregnant pooled means separately
*------------------------------------------------------------*

preserve

    keep if preg == 0 & !missing(reweightingfxn)

    collapse (mean) `meanvars' [aw = reweightingfxn]

    gen preg = 2
    gen group = 0

    tempfile prepreg_means
    save `prepreg_means', replace

restore


*------------------------------------------------------------*
* 6) Add "All five groups" columns by duplicating observations
*------------------------------------------------------------*

expand 2, gen(dup)
replace group = 0 if dup == 1
drop dup


*------------------------------------------------------------*
* 7) Collapse to weighted means
*------------------------------------------------------------*

collapse (mean) `meanvars' [pw = v005], by(preg group)

drop if preg == .

append using `prepreg_means'

merge 1:1 preg group using `Ntrue', nogen


*------------------------------------------------------------*
* 8) Fix group codes and ordering
*------------------------------------------------------------*

drop if group == 6
replace group = 6 if group == 0

gen colorder = .

* Pregnant women first: Adivasi, Dalit, OBC, Forward, Muslim, All five
replace colorder = group if preg == 1

* Prepregnant women pooled column immediately after pregnant pooled column
replace colorder = 7 if preg == 2 & group == 6

* Nonpregnant women last: Adivasi, Dalit, OBC, Forward, Muslim, All five
replace colorder = 7 + group if preg == 0

sort colorder


*------------------------------------------------------------*
* 9) Reshape: variables become rows, columns become group/preg cells
*------------------------------------------------------------*

keep preg group colorder `meanvars' N
sort colorder

drop preg group colorder

xpose, clear varname
rename _varname statvar


*------------------------------------------------------------*
* 10) Merge row labels and section metadata
*------------------------------------------------------------*

merge 1:1 statvar using `rowmeta', nogen keep(match)

gen final_order = section_order * 100 + row_order

sort final_order


*------------------------------------------------------------*
* 11) Create display strings
*------------------------------------------------------------*

foreach i of numlist 1/13 {

    gen disp_v`i' = ""

    replace disp_v`i' = subinstr(string(v`i', "%6.2f"), "0.", ".", 1) ///
        if statvar != "N"

    replace disp_v`i' = string(v`i', "%15.0fc") ///
        if statvar == "N"

}

keep statvar rows section section_order row_order final_order disp_v*


*------------------------------------------------------------*
* 12) Create dynamic section header rows
*------------------------------------------------------------*

tempfile body headers blanks

save `body', replace

preserve

    keep if section != ""
    keep section section_order
    duplicates drop

    gen statvar = ""
    gen rows = "\textbf{" + section + "}"
    gen row_order = 0
    gen final_order = section_order * 100

    foreach i of numlist 1/13 {
        gen disp_v`i' = ""
    }

    save `headers', replace

restore

*------------------------------------------------------------*
* 13) Create blank row before each section header
*     and before N
*------------------------------------------------------------*

use `headers', clear

replace rows = ""
replace final_order = final_order - .5

save `blanks', replace


* Blank row before N
use `body', clear
keep if statvar == "N"

replace rows = ""
replace final_order = final_order - .5

foreach i of numlist 1/13 {
    replace disp_v`i' = ""
}

tempfile blankN
save `blankN', replace


*------------------------------------------------------------*
* 14) Combine body, blank rows, headers, and N blank row
*------------------------------------------------------------*

use `body', clear
append using `headers'
append using `blanks'
append using `blankN'

sort final_order

keep rows disp_v1 disp_v2 disp_v3 disp_v4 disp_v5 disp_v6 ///
          disp_v7 disp_v8 disp_v9 disp_v10 disp_v11 disp_v12 disp_v13


		  
gen blank_pre = ""		  
gen blank_post = ""

// replace disp_v7 = "\multicolumn{1}{>{\centering\arraybackslash}m{1.55cm}}{" + disp_v7 + "}" if disp_v7 != ""

replace disp_v7 = "\multicolumn{1}{>{\centering\arraybackslash}m{1.55cm}}{" + disp_v7 + "}" if disp_v7 != ""
		  
*------------------------------------------------------------*
* 15) Export to LaTeX with listtex
*------------------------------------------------------------*
#delimit ;

listtex rows ///
    disp_v1 disp_v2 disp_v3 disp_v4 disp_v5 disp_v6 ///
    disp_v7 ///
    disp_v8 disp_v9 disp_v10 disp_v11 disp_v12 disp_v13 ///
    using "`outfile'", replace ///
    rstyle(tabular) ///
    head(
        "\begin{tabular}{l*{6}{>{\centering\arraybackslash}p{1.2cm}}@{\hspace{2em}}>{\centering\arraybackslash}m{1.55cm}@{\hspace{2em}}*{6}{>{\centering\arraybackslash}p{1.2cm}}}"
        "\toprule"
        "\addlinespace[0.25em]"
        "& \multicolumn{6}{c}{Pregnant women (3+ months)} & \multicolumn{1}{>{\centering\arraybackslash}m{1.55cm}}{\shortstack[c]{Prepregnant \\ women}} & \multicolumn{6}{c}{Nonpregnant women} \\"
        "\cmidrule[0.01em](lr){2-7} \cmidrule[0.01em](l{-0.4em}r{-0.4em}){8-8} \cmidrule[0.01em](lr){9-14}"
        "\addlinespace[0.35em]"
        "Social Group & \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim & \tiny \shortstack{All five \\ social groups} & \multicolumn{1}{>{\centering\arraybackslash}m{1.55cm}}{\tiny \shortstack[c]{All five \\ social groups}} & \tiny Adivasi & \tiny Dalit & \tiny OBC & \tiny Forward & \tiny Muslim & \tiny \shortstack{All five \\ social groups} \\"
        "\midrule"
    )
    foot(
        "\bottomrule"
        "\end{tabular}"
    );

#delimit cr

*------------------------------------------------------------*
* 16) Quick manual check
*------------------------------------------------------------*

display "BROWSE DATA EDITOR TO SEE RESULTS IN STATA DIRECTLY"
browse
