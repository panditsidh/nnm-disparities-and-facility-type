/********************************************************************
 Figure 2: Neonatal mortality by social group and facility type

 Layout:
   Top left:    Public, Uttar Pradesh and Bihar
   Top right:   Public, all other states
   Bottom left: Private, Uttar Pradesh and Bihar
   Bottom right:Private, all other states

 Sample:
   Rural public/private facility births
   NFHS-4 and NFHS-5 pooled
********************************************************************/


*------------------------------------------------------------*
* 1) Load data
*------------------------------------------------------------*

do "$paths"
use "$dataset", clear

keep if inlist(round, 4, 5)
keep if rural == 1
keep if public == 1 | private == 1
keep if inlist(group, 1, 2, 3, 4, 5)

svyset psu [pw=v005], strata(strata) vce(linearized) singleunit(centered)


*------------------------------------------------------------*
* 2) Define regions and collect estimates
*------------------------------------------------------------*

gen other_states = up_bihar == 0

tempname P
tempfile results

postfile `P' ///
    byte panel ///
    byte group ///
    double(mean ll ul) ///
    using `results', replace


* Top row: public
local p = 0

foreach region in up_bihar other_states {

    local ++p

    foreach g in 1 2 3 5 4 {

        quietly svy: mean nnm ///
            if `region' == 1 & group == `g' & public == 1

        matrix T = r(table)

        local m = T[1,1]
        local l = T[5,1]
        local u = T[6,1]

        post `P' (`p') (`g') (`m') (`l') (`u')
    }
}


* Bottom row: private
foreach region in up_bihar other_states {

    local ++p

    foreach g in 1 2 3 5 4 {

        quietly svy: mean nnm ///
            if `region' == 1 & group == `g' & private == 1

        matrix T = r(table)

        local m = T[1,1]
        local l = T[5,1]
        local u = T[6,1]

        post `P' (`p') (`g') (`m') (`l') (`u')
    }
}

postclose `P'
use `results', clear


*------------------------------------------------------------*
* 3) Panel and x-axis labels
*------------------------------------------------------------*

label define panel_lbl ///
    1 "Uttar Pradesh and Bihar (public facility births)" ///
    2 "All other states (public facility births)" ///
    3 "Uttar Pradesh and Bihar (private facility births)" ///
    4 "All other states (public facility births)"

label values panel panel_lbl

gen x = .
replace x = 1.0 if group == 1
replace x = 1.8 if group == 2
replace x = 2.6 if group == 3
replace x = 3.4 if group == 5
replace x = 4.2 if group == 4

gen nnm_label = string(round(mean, .1), "%4.1f")

* Truncate CIs at 90 for plotting only
gen ul_plot = min(ul, 90)


*------------------------------------------------------------*
* 4) Figure
*------------------------------------------------------------*

#delimit ;

twoway ///
    (rcap ll ul x if ul <= 90, ///
        lcolor(black) lwidth(vthin)) ///
    (rspike ll ul_plot x if ul > 90, ///
        lcolor(black) lwidth(vthin)) ///asdf
    (scatter mean x, ///
        msymbol(O) ///
        mcolor(black) ///
        msize(small) ///
        mlabel(nnm_label) ///
        mlabpos(3) ///
        mlabgap(2) ///
        mlabsize(tiny) ///
        mlabcolor(black)) ///
    , ///
    xlabel( ///
        1.0 "Adivasi" ///
        1.8 "Dalit" ///
        2.6 "OBC" ///
        3.4 "Muslim" ///
        4.2 "Forward", ///
        labsize(small) nogrid) ///
    ylabel(0(10)90, ///
        angle(horizontal) ///
        grid glcolor(gs14) glwidth(vthin) labsize(small)) ///
    yscale(range(0 90) noextend) ///
    xtitle("") ///
    ytitle("Neonatal mortality rate (per 1,000 births)") ///
    xscale(range(0.65 4.55)) ///
	subtitle(, size(medsmall)) ///
    legend(off) ///
    by(panel, ///
        cols(2) ///
        note("") ///
        legend(off) ///
        graphregion(color(white))) ///
    graphregion(color(white)) ///
    plotregion(color(white)) ///
    xsize(12) ///
    ysize(7);

#delimit cr


graph export "figures/figure2 nnm public private UP Bihar NFHS4,5.png", replace width(2800)
