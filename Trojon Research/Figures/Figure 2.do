clear all

use figure_2.dta

twoway (line h_EPU_war period), scheme(s2color) xlabel(1900(10)2015) xtitle("") ytitle("")

graph export figure_2.png, replace height(600) width(900)
