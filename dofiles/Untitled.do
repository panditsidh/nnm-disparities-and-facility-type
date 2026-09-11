use "3_clean/processmonitoringdata cleaned.dta", clear

summ intake, format
di "Most recent intake date: " %tdDD_Month_CCYY r(max)

tab intake_month
tab intakeperiod, missing
