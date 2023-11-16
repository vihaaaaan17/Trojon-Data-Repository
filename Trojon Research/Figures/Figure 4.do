clear all

use figure_4.dta

label var russia_newspaper_epu "News-Based Policy Uncertainty Index"

twoway (line russia_newspaper_epu period), xlabel(1992(2)2014)

graph export figure_4.png, replace height(600) width(900)
