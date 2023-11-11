clear all

use appendix_b_figures

gen period = year + (month-1)/12

twoway (line m_regulation period), xlabel(1985(5)2012)
graph export figure_b1.png, replace height(600) width(900)

twoway (line m_deficit period), xlabel(1985(5)2012)
graph export figure_b2.png, replace height(600) width(900)

twoway (line m_whitehouse period), xlabel(1985(5)2012)
graph export figure_b3.png, replace height(600) width(900)

twoway (line m_congress period), xlabel(1985(5)2012)
graph export figure_b4.png, replace height(600) width(900)

twoway (line m_legislation period), xlabel(1985(5)2012)
graph export figure_b5.png, replace height(600) width(900)

twoway (line m_federalreserve period), xlabel(1985(5)2012)
graph export figure_b6.png, replace height(600) width(900)

corr m_*
