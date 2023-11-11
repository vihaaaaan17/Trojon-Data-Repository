clear all

use figure_c5


global start_year = 1885
global increment = 10


qui graph twoway (bar decreasing year, lcolor(blue) color(bluishgray) barwidth(.5))(bar increasing year, lcolor(red) color(sand) barwidth(.5))(bar policydec year, color(blue) barwidth(.5))(bar policyinc year, color(red) barwidth(.5)), xlabel($start_year($increment)2012, angle(45))

graph export figure_c5.png, replace height(600) width(900)
