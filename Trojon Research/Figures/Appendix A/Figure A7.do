clear all

use figure_a7

gen period = year + (month-1)/12

graph twoway (line japan_epu period), xlab(1987(3)2015)  ytitle("") xtitle("") 

graph export figure_a7.png, replace height(600) width(900)
