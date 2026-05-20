/*


Social group differences in neonatal mortality



Overvar - the categories on the x-axis
Outcome - the y axis
Byvar - the stratifying variable, at each level of the overvar 



Example - overvar is social group, outcome is neonatal mortality, byvar is facility type (public private or home)





*/



use "$dataset", clear


*******************************************************
* Do your sample restrictions and stuff here
*******************************************************

drop if group==6 | missing(group)


local round = 5
local residence_type rural
local states nonfocus


keep if round==`round'

keep if `residence_type'==1


keep if `states'==1


*******************************************************
* Change this based on the variables you want
*******************************************************



local overlabel group_lbl
local bylabel facility_lbl


local outcome nnm
local overvar group
local byvar facility_type


local ytitle "Neonatal mortality"


local sample "(`residence_type' `states', NFHS-`round')"

local title "Neonatal mortality by social group `sample'"


local outfile "/Users/sidhpandit/Documents/GitHub/bookUP/figures/NNM by group and facility `sample'.png"

*******************************************************
* Gets the results postfile
*******************************************************


levelsof(`overvar'), local(overlevels)
levelsof(`byvar'), local(bylevels)


tempfile out
tempname post

postfile `post' ///
    int overlevel int bylevel ///
    str40 overlabel str40 bylabel ///
    double mean se ll ul ///
    using `out', replace

foreach overlevel in `overlevels' {
	
	
    * -----------------------------
    * Overall mean within overlevel
    * -----------------------------
    di "`overvar' level `overlevel' and total"

    svy: mean `outcome' if `overvar' == `overlevel'

    matrix estimate = r(table)

    local mean = estimate[1,1]
    local se   = estimate[2,1]
    local ll   = estimate[5,1]
    local ul   = estimate[6,1]

    local overlab : label `overlabel' `overlevel'

    post `post' ///
        (`overlevel') (0) ///
        ("`overlab'") ("total") ///
        (`mean') (`se') (`ll') (`ul')


    * -----------------------------
    * Means by bylevel within overlevel
    * -----------------------------
	
	foreach bylevel in `bylevels' {
		
		
		di "`overvar' level `overlevel' and `byvar' level `bylevel'"
		
		svy: mean `outcome' if `overvar'==`overlevel' & `byvar'==`bylevel'
		
		
		
		matrix estimate = r(table)
		
		local mean = estimate[1,1]
		local ll = estimate[5,1]
		local ul = estimate[6,1]
		local se = estimate[2,1]
		
		local overlab : label `overlabel' `overlevel'
        local bylab   : label `bylabel' `bylevel'
		
		post `post' ///
            (`overlevel') (`bylevel') ///
            ("`overlab'") ("`bylab'") ///
            (`mean') (`se') (`ll') (`ul')
		
	}
	
	
}


postclose `post'
use `out', clear


*******************************************************
* Dynamic stagger the x positions
*******************************************************

distinct bylevel
local n_bylevels = r(ndistinct)

distinct overlevel
local n_overlevels = r(ndistinct)

* Create plotting position for bylevel
* This makes total/private/public/home into 1/2/3/4, regardless of raw codes
capture drop bypos
egen bypos = group(bylevel)

* Tighter radius so points stay visually grouped within overlevel
local radius = min(0.18, 0.05 + 0.035 * `n_bylevels')

* Stagger x positions
capture drop offset
gen double offset = .

if `n_bylevels' == 1 {
    replace offset = 0
}
else {
    replace offset = -`radius' + ///
        (bypos - 1) * (2 * `radius' / (`n_bylevels' - 1))
}

capture drop xpos
gen double xpos = overlevel + offset


*******************************************************
* Get xlabels
*******************************************************


levelsof(overlabel), local(overlabels)

foreach lab in `overlabels' {
    
    quietly summarize overlevel if overlabel == "`lab'", meanonly
    local x = r(mean)
    
    local xlabels `xlabels' `x' `"`lab'"'
}

di `"`xlabels'"'


*******************************************************
* Dynamic twoway graph by bylevel
*******************************************************

* Marker/line colors: no yellow
local colors navy maroon forest_green dkorange purple teal cranberry brown black gs8

* Open marker symbols
local symbols Oh Th Sh Dh O T S X

* Get bylevels from results data
levelsof bylevel, local(bylevels_graph)

local plots
local legend
local k = 0

foreach b of local bylevels_graph {

    local ++k

    * Pick color and marker symbol
    local color  : word `k' of `colors'
    local symbol : word `k' of `symbols'

    * Get bylabel from stored string variable
    preserve
        keep if bylevel == `b'
        keep bylevel bylabel
        duplicates drop
        local this_bylabel = bylabel[1]
    restore

    * Add rcap layer and scatter layer
    local plots `plots' ///
        (rcap ll ul xpos if bylevel == `b', ///
            lcolor(`color')) ///
        (scatter mean xpos if bylevel == `b', ///
            msymbol(`symbol') ///
            mcolor(`color') ///
            mlab(mean) ///
            mlabposition(12) ///
            mlabsize(vsmall) ///
            mlabformat(%4.1f) ///
            mlabcolor(`color'))

    * Legend should show only scatter layers.
    * Since each bylevel adds 2 layers:
    *   rcap    = 2*k - 1
    *   scatter = 2*k
    local scatter_layer = 2 * `k'

    local legend `legend' `scatter_layer' `"`this_bylabel'"'
}


twoway `plots', ///
    xtitle("") ///
    xlabel(`xlabels', angle(45)) ///
    ytitle("`ytitle'") ///
	title("`title'") ///
    legend(order(`legend') rows(1) pos(6)) ///
    graphregion(color(white)) ///
    plotregion(color(white))



	
graph export "`outfile'", replace as(png) name("Graph")	
	
/*

stagger overlevel based on how many bylevels there are?




*/

