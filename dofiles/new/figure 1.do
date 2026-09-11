/********************************************************************
 Figure: Neonatal mortality by social group and facility type

 Sample:
   Rural public/private facility births
   NFHS-4 and NFHS-5 pooled

 Panels:
   1. UP/Bihar
   2. Other EAG states
   3. Non-EAG states
   4. All India
********************************************************************/


*--------------------------------------------------*
* Load data
*--------------------------------------------------*

do "$paths"
use "$dataset", clear

keep if inlist(round, 4, 5)
keep if rural == 1
keep if public == 1 | private == 1
keep if inlist(group, 1, 2, 3, 4, 5)

svyset psu [pw=v005], strata(strata) vce(linearized) singleunit(centered)


*--------------------------------------------------*
* Region indicators
*--------------------------------------------------*

capture drop other_eag india

gen other_eag = non_upbihar_focus
gen india = 1


*--------------------------------------------------*
* Post results: region x social group x facility
*--------------------------------------------------*

tempfile results
tempname P

postfile `P' ///
    byte panel ///
    byte group ///
    str10 facility ///
    double(mean ll ul) ///
    using `results', replace


local regions up_bihar other_eag nonfocus india
local p = 0

foreach region of local regions {

    local ++p

    foreach g in 1 2 3 5 4 {

        foreach facility in public private {

            quietly svy: mean nnm if `region' == 1 & group == `g' & `facility' == 1
            matrix T = r(table)

            local m = T[1,1]
            local l = T[5,1]
            local u = T[6,1]

            post `P' (`p') (`g') ("`facility'") (`m') (`l') (`u')
        }
    }
}

postclose `P'
use `results', clear


*--------------------------------------------------*
* Labels and x-axis positions
*--------------------------------------------------*

label define panel_lbl ///
    1 "Uttar Pradesh and Bihar" ///
    2 "Other EAG states" ///
    3 "Non-EAG states" ///
    4 "All India"
label values panel panel_lbl


gen x = .
replace x = 1.0  if group == 1
replace x = 6.0  if group == 2
replace x = 10.0  if group == 3
replace x = 14.0 if group == 5
replace x = 18.0 if group == 4

* Stagger public/private within each social group
gen x_off = x
replace x_off = x - 0.37 if facility == "public"
replace x_off = x + 0.37 if facility == "private"


* Point labels
gen nnm_label = string(round(mean, .1), "%4.1f")

* Put labels just above the top of each confidence interval
gen label_y = ul + 2.5


*--------------------------------------------------*
* Plot
*--------------------------------------------------*

#delimit ;

twoway ///
    (rcap ll ul x_off if facility == "public", ///
        lcolor(black) lwidth(vthin)) ///
    (scatter mean x_off if facility == "public", ///
        msymbol(O) mcolor(black) msize(medsmall)) ///
    (scatter label_y x_off if facility == "public", ///
        msymbol(none) ///
        mlabel(nnm_label) mlabsize(tiny) mlabpos(12) mlabcolor(black)) ///
    (rcap ll ul x_off if facility == "private", ///
        lcolor(black) lwidth(vthin)) ///
    (scatter mean x_off if facility == "private", ///
        msymbol(Th) mcolor(black) msize(medsmall)) ///
    (scatter label_y x_off if facility == "private", ///
        msymbol(none) ///
        mlabel(nnm_label) mlabsize(tiny) mlabpos(12) mlabcolor(black)) ///
    , ///
    xlabel(1 "Adivasi" 5 "Dalit" 9 "OBC" 13 "Muslim" 17 "Forward", ///
        labsize(small) nogrid) ///
    ylabel(0(25)150, grid glcolor(gs14) glwidth(vthin)) ///
    yscale(range(0 150)) ///
    xtitle("") ///
    ytitle("Neonatal mortality rate (per 1,000 births)") ///
    xscale(range(0.0 18.0)) ///
    legend(order(2 "Public" 5 "Private") ///
        ring(1) pos(6) region(lcolor(none))) ///
    by(panel, cols(2) ixaxes note("") graphregion(color(white))) ///
    graphregion(color(white));

#delimit cr


* Optional export
graph export "figures/figure nnm public private by social group NFHS4,5.png", replace width(2400)

