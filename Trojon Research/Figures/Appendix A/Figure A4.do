clear all

use figure_a4

twoway line germany_index period if period>=1997, xlabel(1997(3)2015) 

graph export figure_a4.png, replace height(600) width(900)
