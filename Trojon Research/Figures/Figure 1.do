clear all

use figure_1.dta

twoway (line usa_newspaper_epu period), xlabel(1985(5)2015)

graph export figure_1.png, replace height(600) width(900)
