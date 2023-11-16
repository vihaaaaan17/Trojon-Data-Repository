clear all
use figure_c2

****Data normalizations
foreach var of varlist vix financial_uncert {
	sum `var'
	gen sc_`var' = `var'/r(mean)*100
}

gen period = year + (month-1)/12

label var sc_vix "VIX"
label var sc_financial_uncert "Equity Market Uncertainty"

twoway (line sc_vix period, lcolor(red))(line sc_financial_uncert period, lcolor(blue)) if period>=1990, xlab(1990(2)2012, angle(45))  ytitle("") xtitle("") legend(off)

graph export figure_c2.png, replace height(600) width(900)
