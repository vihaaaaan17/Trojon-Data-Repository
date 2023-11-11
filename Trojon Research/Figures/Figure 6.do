clear all

use figure_6

corr mean_vix usa_newspaper_epu
gen period = year + (month-1)/12
sort period

label var mean_vix "VIX (Red)"
label var usa_newspaper_epu "Economic Policy Uncertainty (Blue)"
twoway (line usa_newspaper_epu period, lcolor(blue))(line mean_vix period, yaxis(2) lcolor(red)) if year>=1990, xlab(1990(2)2016, angle(45)) legend(off) xtitle("")

graph export figure_6.png, replace height(600) width(900)
