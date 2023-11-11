clear all

use figure_3.dta

gen quarter=floor((month+2)/3)
collapse defense health ,by(year quarter)
so year quarter

gen period = year + (quarter-1)/4

label var defense "Defense Uncertainty"
label var health "Health Uncertainty"

twoway (line defense health period, xlabel(1985(5)2015))

graph export figure_3.png, replace height(600) width(900)
