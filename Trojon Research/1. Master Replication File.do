****************************************************************************************************************************************
*Master Replication File for Measuring Economic Policy Uncertainty (2016) by Scott R. Baker, Nicholas A. Bloom, and Steve J. Davis
*This file last updated 3/16/2016
*For questions, contact s-baker@kellogg.northwestern.edu
*EPU index data available at www.policyuncertainty.com
****************************************************************************************************************************************

clear all
set more off

********************************************************************
****Set working directory to this .do file's location, if necessary:
********************************************************************
*cd "this .do file's location"

********************************************************************
***Install necessary Stata commands
********************************************************************
cap ssc install winsor2
cap ssc install reghdfe


***************************************************************************************************
***************************************************************************************************
****Create all Tables below
***************************************************************************************************
***************************************************************************************************

********************************************************************
****Categorical EPU Table
********************************************************************

***Table 1
*See Categorical_EPU_Data.xlsx


********************************************************************
****Create Results Tables
********************************************************************
cd "Firm Panel"

***Table 2, Table 3, and Table A1
do "volatility"

***Table A1
*See Table A1 Data and Calculations

***Table 4
do "invemp"


***************************************************************************************************
***************************************************************************************************
****Create all Figures below
***************************************************************************************************
***************************************************************************************************


********************************************************************
****Main EPU Newspaper and Beige Book Figures
********************************************************************
cd ..
cd "Figures"

**Figure 1
do "Figure 1"

**Figure 2
do "Figure 2"

**Figure 3
do "Figure 3"

**Figure 4
do "Figure 4"

**Figure 5
do "Figure 5"

**Figure 6
do "Figure 6"

**Figure 7
do "Figure 7"


********************************************************************
****US VAR: Figure 8 and Figure 9; Figure C6 and Figure C7
********************************************************************
cd ..
cd "US VAR"

**Figure 8 and Figure 9 and Figure C7
global months=1
do "US_VAR"

**Figure C6
global months=3
do "US_VAR"


********************************************************************
****International Panel VAR: Figure 10; Figure C8
********************************************************************
cd ..
cd "International VAR"

do "panel_var"


********************************************************************
****Create all other Appendix Figures
********************************************************************

********************************************************************
****Appendix A: Country level EPU Figures
cd ..
cd "Figures"
cd "Appendix A"

**Figure A1
do "Figure A1"

**Figure A2
do "Figure A2"

**Figure A3
do "Figure A3"

**Figure A4
do "Figure A4"

**Figure A5
do "Figure A5"

**Figure A6
do "Figure A6"

**Figure A7
do "Figure A7"

**Figure A8
do "Figure A8"

**Figure A9
do "Figure A9"

**Figure A10
do "Figure A10"

**Figure A11
do "Figure A11"

********************************************************************
****Appendix B: Single-word EPU Index Removal Figures
cd ..
cd "Appendix B"

**All Appendix B Figures
do "Appendix B Figures"

********************************************************************
****Appendix C: Misc Figures
cd ..
cd "Appendix C"

**Figure C1
do "Figure C1"

**Figure C2
do "Figure C2"

**Figure C3
do "Figure C3"

**Figure C4
do "Figure C4"

**Figure C5
do "Figure C5"
