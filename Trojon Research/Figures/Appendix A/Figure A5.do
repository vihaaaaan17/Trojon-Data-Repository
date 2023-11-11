clear all
use figure_a5

gen period = year + (month-1)/12

twoway (line india_newspaper_epu period), xlabel(2003(2)2015)

graph export figure_a5.png, replace height(600) width(900)
