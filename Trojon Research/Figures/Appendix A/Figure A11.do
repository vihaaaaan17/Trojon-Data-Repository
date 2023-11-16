clear all

use figure_a11

twoway (line uk_guard_times_hist_news_epu period) if year>1899, xlabel(1900(10)2005)

graph export figure_a11.png, replace height(600) width(900)
