clear all

use figure_c1

*Collapse back to yearly
collapse grader_epu computer_epu index_epu historical_epu ,by(year)
keep if grader_epu~=.&historical~=.

foreach series in grader computer index  {
su `series' 
replace `series'_epu=100*`series'_epu/r(mean)
}

lab var grader_epu "Human EPU on audit articles"

scatter grader_epu index_epu year,c(l l l) ms(+ p) xlab(1900(10)2010) legend(off)
corr grader_epu index_epu

graph export figure_c1.png, replace height(600) width(900)
