*This do file replicates Table 4 with the investment and employment results
*Created by Nick Bloom on March 6th 2016, nbloom@stanford.edu

cap cd "panel_regressions"
clear all
use data/all_firm_data_updated
set more off

so gvkey year quarter
merge 1:1 gvkey year quarter using data/tobin_q_data, keepus(tobin_q)
ren tobin_q tobin
drop if _m==2
drop _m
so gvkey year quarter
merge 1:1 gvkey year quarter using data/cashflow_data, keepus(cashflow)
tab _m
drop if _m==2
drop _m

merge m:1 year quarter using data/modern_epu_quarterly

foreach var in E P U EP EU PU EPU {
	gen lm_`var'=log(m_`var')
}
drop if _merge==2
drop _merge
merge m:1 year quarter using data/categories_yq
gen yq=year+(quarter-1)/4
gen lepu=log(m_EPU)
gen leu=log(m_EU)

********************Updating/Fixing VIX
cap drop _merge
ren vix oldvix
so yq
merge m:1 yq using data/vix.dta,update
replace lvix=log(vix)
drop _m
merge m:1 yq using data/vxo_quarterly.dta,update
drop _m
*replace vix with vxo
replace vix=vxo if vix==.&vxo~=.
replace lvix=log(vix)

***************Add in Steve's intensity measure
so gvkey
merg gvkey using data/gvkey
drop if _m==2
drop _m
so cusip
*merge cusip using data/steve_data_xs
merge cusip using data/steve10k_cusip
winsor2 jp,replace 

drop if _m==2
drop _m
ren jp jp

************************************************************************************************************************
***Here we make all of the necessary interactions for each intensity measure
************************************************************************************************************************
tsset ticker_code period_code

foreach var of varlist h_firm_sic_intens  {
	foreach var2 of varlist m_* lm_* vix lepu lvix fed fed_fore leu {
		qui gen `var2'_X_`var' = `var2'*`var'
		qui gen l1`var2'_X_`var' = l1.`var2'_X_`var'
		qui gen dl1`var2'_X_`var' = d.l1`var2'_X_`var'
	}
}

foreach var of varlist firm_intens sic_intens firm_sic_intens belo_intens jp {
	foreach var2 of varlist lepu fed {
		qui gen `var2'_X_`var' = `var2'*`var'
		qui gen l1`var2'_X_`var' = l1.`var2'_X_`var'
		qui gen dl1`var2'_X_`var' = d.l1`var2'_X_`var'
	}
}
gen lagppent=l.ppent
replace defense=0 if sic3~=348&sic3~=372&sic3~=376&sic3~=379&sic3~=381&sic3~=871
gen defense_sector=(sic3==348|sic3==372|sic3==376|sic3==379|sic3==381|sic3==871)
replace health=0 if (sic3<800|sic3>=810)
replace fin_regulation=0 if sic3<600|sic3>699
foreach var in defense health fin_regulation {
gen l`var'=log(`var')
gen dl`var'=d.l`var'
gen dl`var'_miss=(dl`var'==.)
replace dl`var'=-99 if dl`var'_miss==1
}
label var iqr_fed_gov_forecast "Fed Exp. IQR"

***Compress
drop nom_fed_exp nom_gdp  vxo lvxo iqr_fed_gov_forecast ticker
egen avg_emp = mean(emp), by(ticker_code)
replace avg_emp=round(1000*avg_emp)

*Note: reghdfe can't weight with non-integer values so scale by 1000 and round, plus enforce all firms to have 1+ employee
replace avg_emp=1 if avg_emp==0
egen mavg_emp=mean(avg_emp)
replace avg_emp=round(mavg_emp) if avg_emp==.
egen min_year = min(year), by(ticker_code )
gen age = year-min_year
drop *long obligatedamount atq xrd iq lrevtq firm_cap_intens firm_rd_intens sic2 
compress
**********************************************************************************************************************************************************
****************FULL TABLES
**********************************************************************************************************************************************************
reg invest_ppe_rate dl1lepu_X_h_firm_sic_intens dl1fed_X_h_firm_sic_intens 
keep if e(sample)
save data/itemp,replace
cap log close
cap log using invemp,replace t


*Column (1) - baseline investment
reghdfe invest_ppe_rate dl1lepu_X_h_firm_sic_intens dl1fed_X_h_firm_sic_intens                                  , ab(ticker_code period_code) vce(cl ticker)
qui so yq
qui su lepu if (year==2005|year==2006)&(yq~=yq[_n-1])
qui global low_EPU=r(mean)
qui su lepu if (year==2011|year==2012)&(yq~=yq[_n-1])
qui global jump=r(mean)-$low_EPU
xtsum invest_ppe if e(sample)

*Note point impact for firm with 25% exposure about 10% of annual investment.
di _b[dl1lepu_X_h_firm_sic_intens]*$jump*0.25

*Column (2) - add forecast
reghdfe invest_ppe_rate dl1lepu_X_h_firm_sic_intens dl1fed_X_h_firm_sic_intens dl1fed_fore_X_h_firm_sic_intens  , ab(ticker_code period_code) vce(cl ticker)

*Referee footnote - add cashflow and tobin Q, and also check interactions with uncertainty
u data/itemp,replace
gen c_k=cashflow/lagppent
replace tobin=20 if tobin>20&tobin~=.
replace tobin=0.1 if tobin<0.1&tobin~=.
winsor2 c_k,cuts(2.5 97.5) replace
tsset
replace revt=0 if revt<=0
gen dsales=2*(revt-l.revt)/(revt+l.revt)
winsor2 dsales,replace
foreach var in tobin c_k dsales{
gen l`var'=l.`var'
gen l`var'_miss=(l`var'==.)
replace l`var'=-99 if l`var'==.
gen xl`var'=l`var'*dl1lepu_X_h_firm_sic_intens
gen xl`var'_miss=l`var'_miss*dl1lepu_X_h_firm_sic_intens
}

*Column (3) - add up to 3 years of future realizations
tsset
reghdfe invest_ppe_rate dl1lepu_X_h_firm_sic_intens f(0/12).dl1fed_X_h_firm_sic_intens   , ab(ticker_code period_code) vce(cl ticker)

*Column (4)  - categories (Table 2 breakdowns by different types of EPU)
reghdfe invest_ppe_rate dldefense* dlhealth* dlfin_reg* dl1lepu_X_h_firm_sic_intens dl1fed_X_h_firm_sic_intens,  ab(ticker_code period_code) vce(cl ticker)
test dldefense dlhealth dlfin_regulation



******************************************
***************EMPLOYMENT
***Collapse to yearly data
clear all
use data/annual_firm_data
gen period_code=year
tsset ticker_code period_code
gen one=1

foreach var of varlist one firm_intens sic_intens firm_sic_intens health_sic_intens health_firm_intens belo_intens h_firm_sic_intens {
	foreach var2 of varlist lepu leu lvix fed  fed_fore {
		qui gen `var2'_X_`var' = `var2'*`var'
		qui gen d`var2'_X_`var' = d.`var2'_X_`var'
	}
}

tsset 
gen demp = (emp - l.emp)/(0.5*emp+0.5*l.emp)
gen drev = (revtq - l.revtq)/(0.5*revtq+0.5*l.revtq)
replace drev = . if drev>=2 |drev<=-2
replace defense=0 if sic3~=348&sic3~=372&sic3~=376&sic3~=379&sic3~=381&sic3~=871
replace health=0 if (sic3<800|sic3>=810)
replace fin_regulation=0 if sic3<600|sic3>699
foreach var in defense health fin_regulation {
gen l`var'=log(`var')
gen dl`var'=d.l`var'
gen dl`var'_miss=(dl`var'==.)
replace dl`var'=-99 if dl`var'_miss==1
}

reg demp dlepu_X_h_firm_sic_intens dfed_X_h_firm_sic_intens                               
keep if e(sample)
egen noj=count(demp),by(ticker_code)
keep if noj>1

*Keep a core sample with all explanatory variables in main table
qui reghdfe dlepu_X_h_firm_sic_intens dfed_X_h_firm_sic_intens  dfed_fore_X_h_firm_sic_intens                         dldefense dlhealth dlfin_regulation      , ab(ticker_code period_code) 
keep if e(sample)
save data/etemp,replace

*Column (5) - baseline employment
reghdfe demp dlepu_X_h_firm_sic_intens dfed_X_h_firm_sic_intens                                 , ab(ticker_code period_code) vce(cl ticker)
qui so year
qui su lepu if (year==2005|year==2006)&(year~=year[_n-1])
qui global low_EPU=r(mean)
qui su lepu if (year==2011|year==2012)&(year~=year[_n-1])
qui global jump=r(mean)-$low_EPU
xtsum demp if e(sample)
*Note point impact for firm with 25% exposure about equal to annual employment growth
di _b[dlepu_X_h_firm_sic_intens]*$jump*0.25

*Column (6) - add forecasts
reghdfe demp dlepu_X_h_firm_sic_intens dfed_X_h_firm_sic_intens dfed_fore_X_h_firm_sic_intens   , ab(ticker_code period_code) vce(cl ticker)

*Column (7) - add three years future forecasts
tsset 
reghdfe demp dlepu_X_h_firm_sic_intens f(0/3).dfed_X_h_firm_sic_intens                                 , ab(ticker_code period_code) vce(cl ticker)

*Column (8) - Categories result
reghdfe demp dldefense* dlhealth* dlfin_reg* dlepu_X_h_firm_sic_intens dfed_X_h_firm_sic_intens                                 , ab(ticker_code period_code) vce(cl ticker)
test dldefense dlhealth dlfin_regulation

*Column (9) - revenue placebo 
reghdfe drev dlepu_X_h_firm_sic_intens dfed_X_h_firm_sic_intens                                 , ab(ticker_code period_code) vce(cl ticker)

log close
