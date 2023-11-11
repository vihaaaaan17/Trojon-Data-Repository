clear all

use figure_7


qui graph twoway (bar scaled_eu_10k yq, color(red) barwidth(.2))(bar scaled_epu_10k yq, color(black) barwidth(.2))(line policy_share yq, color(blue) yaxis(2)), xlabel(1983(4)2015)

graph export figure_7.png, replace height(600) width(900)
