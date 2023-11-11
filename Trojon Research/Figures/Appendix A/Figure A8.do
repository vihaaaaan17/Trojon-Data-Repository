clear all

use figure_a8

twoway (line korea_newspaper_epu period), xlabel(1990(5)2015)

graph export figure_a8.png, replace height(600) width(900)
