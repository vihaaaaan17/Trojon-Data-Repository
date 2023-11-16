clear all

use figure_a9

twoway line spain_index period if period>=2001, xlabel(2001(3)2015) 

graph export figure_a9.png, replace height(600) width(900)
