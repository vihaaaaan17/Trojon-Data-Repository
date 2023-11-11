clear all

use figure_a1

sum canada_newspaper_epu if year<2011
replace canada_newspaper_epu = canada_newspaper_epu/r(mean)*100

twoway (line canada_newspaper_epu period), xlabel(1985(5)2015)

graph export figure_a1.png, replace height(600) width(900)
