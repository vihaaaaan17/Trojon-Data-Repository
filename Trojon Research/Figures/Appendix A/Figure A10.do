clear all

use figure_a10

twoway line uk_index period if period>=1997, xlabel(1997(3)2015) 

graph export figure_a10.png, replace height(600) width(900)
