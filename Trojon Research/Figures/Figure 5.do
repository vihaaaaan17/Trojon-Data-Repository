clear all

use figure_5

lab var grader_epu "Human EPU on audit articles"
lab var index_epu "Overall news index"

*Figure 2
gen period=year+(quarter-1)/4
so year quarter
corr grader_epu computer_epu

scatter grader_epu computer_epu period if period<2013,c(l l l) ms(+ p) xlab(1985(5)2012) legend(off)

graph export figure_5.png, replace height(600) width(900)
