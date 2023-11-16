clear all

use figure_a3

twoway line france_index period if period>=1987, xlabel(1987(3)2015) 

graph export figure_a3.png, replace height(600) width(900)
