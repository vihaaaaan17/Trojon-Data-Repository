clear all

use figure_c3.dta

gen a = 1985
gen b = 1993
gen c = 2001
gen d = 2009
gen e = 2013

gen y_val =0
replace y_val = 420 in 1

gen alt_y_val = -205
replace alt_y_val = 115 in 1

twoway (rarea a b y_val , horiz lcolor(gs14) fcolor(gs14))(rarea c d y_val, horiz lcolor(gs14) fcolor(gs14))(line right_newspaper_epu period, lcolor(red) lwidth(medthick) clpattern(dash))(line left_newspaper_epu period, lstyle(solid)  lwidth(medthick) lcolor(blue)), legend(off) xlabel(1985(5)2015)
 
graph export figure_c3.png, replace height(600) width(900)
