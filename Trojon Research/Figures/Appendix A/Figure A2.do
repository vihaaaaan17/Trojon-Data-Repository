clear all

use figure_a2

sum china_newspaper_epu if year<2012, de
replace china_newspaper_epu = china_newspaper_epu/r(mean)*100

label var china_newspaper_epu "China News-Based EPU"

gen period = year + (month-1)/12
graph twoway (line china_newspaper_epu period), xlab(1996(3)2015)  ytitle("") xtitle("") 

graph export figure_a2.png, replace height(600) width(900)
