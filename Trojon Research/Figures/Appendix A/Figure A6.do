clear all

use figure_a6

twoway line italy period if period>=1997, xlabel(1997(3)2015) 

graph export figure_a6.png, replace height(600) width(900)
