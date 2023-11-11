set matsize 5000
clear all
set more off
use data/final_data.dta

so year month 
merge 1:1 year month using data/modern_epu_data_clean
ren UP PU
gen eEPU=EPU/E
gen pEPU=EPU/P
gen uEPU=EPU/U
gen euEPU=EPU/EU
gen puEPU=EPU/PU
gen epEPU=EPU/EP
gen gE_P_U=(E*P*U)^(1/3)
gen aE_P_U=(E+P+U)/3
global unc="E P U EP EU PU EPU eEPU pEPU uEPU euEPU puEPU epEPU _EPU gE_P_U aE_P_U"
global lunc="lE lP lU lEP lEU lPU lEPU leEPU lpEPU luEPU leuEPU lpuEPU lepEPU l_EPU lgE_P_U laE_P_U"
foreach var in $unc {
gen l`var'=log(`var')
}
gen ym=year+(month-1)/12
gen yq=year+(floor((month-1)/3))/4
drop _m

so year month
merge m:1 year month using data/categories

gen quarter = 1
replace quarter = 2 if month>3
replace quarter = 3 if month>6
replace quarter =4 if month>9
lab var uncert "Combined EPU index"
lab var EPU "News only index"
collapse uncert - PCF $unc $lunc defense health fin_regulation epu yq ym, by(year quarter)
compress
save data/epu_data, replace
clear all

use data/volandcapex_quarterly.dta,clear

cap destring, replace
cap gen date = dofm(datadate)
cap gen quarter = quarter(date)
cap gen year = year(date)
cap gen month = month(date)

**These two lines below move from old to new data
cap merge 1:1 gvkey year quarter using  data/volandcapex_quarterly_updated.dta,update
cap tab _m
cap drop _m

***Note master data only has back until 1995
cap merge m:1 year quarter gvkey using data/all_firm_data_updated.dta
cap drop *uncert*
drop if _merge==2
drop _merge
merge m:1 year quarter using data/epu_data.dta
drop if _merge==2
drop _merge

********************Adding Volume Data
rename cusip cusip
merge m:1 cusip year quarter using data/quarterly_volume_data.dta
drop if _merge==2
drop _merge
cap order gvkey ticker* cusip* permno year quarter month datadate date datafdate
drop min_quarter 
sort gvkey year quarter
tsset gvkey period_code
gen luncert=log(uncert)

********Adding beta and 10k data
so sic3
merge sic3 using data/sic3_betas
drop if _m==2
drop _m

so gvkey
merge gvkey using data/steve10k_gvkey
winsor2 jp,replace cuts(2 98)
replace jp=log(jp)
drop if _m==2
drop _m

********************Updating/Fixing VIX
ren vix oldvix
so yq
merge m:1 yq using data/vix.dta,update
replace lvix=log(vix)

*Generate a bunch of uncertainty interactions with prefered intensity measure, giving them the same SD as the baseline
foreach var of varlist h_firm_sic_intens {
	foreach var2 of varlist $unc $lunc uncert vix luncert lvix fed fed_fore {
		qui	gen `var2'_X_`var' = `var2'*`var'
	}
}

*Test out with other intensity measures
egen sdXbaseline=sd(h_firm_sic_intens)
foreach var of varlist sic_intens belo_intens firm_intens firm_sic_intens beta jp {
	egen sdX`var'=sd(`var')
	replace `var'=`var'*sdXbaseline/sdX`var'
	qui	gen luncert_X_`var'_intens = luncert*`var'
	qui	gen lEPU_X_`var'_intens = lEPU*`var'
	qui	gen fed_X_`var'_intens = fed*`var'
}


gen lavg_vol_91  = log(avg_vol_91)
gen lend_vol_91  = log(end_vol_91)
gen lavg_vol_30  = log(avg_vol_30)
gen lend_vol_30  = log(end_vol_30)
gen lavg_vol_182  = log(avg_vol_182)
gen lend_vol_182  = log(end_vol_182)
gen lavg_vol_365  = log(avg_vol_365)
gen lend_vol_365  = log(end_vol_365)
cap gen lavg_volr  = log(avg_volr)
cap gen lend_volr  = log(end_volr)
tsset
gen l_luncert_X_h_firm_sic_intens=l.luncert_X_h_firm_sic_intens
gen f_luncert_X_h_firm_sic_intens=f.luncert_X_h_firm_sic_intens
cap label var l_luncert_X_h_firm_sic_intens "Lag Uncert*Firm Intens"
cap label var f_luncert_X_h_firm_sic_intens "Fwrd Uncert*Firm Intens"
cap label var luncert_X_h_firm_sic_intens "Log(Uncert)*Firm Intens"
cap label var fed_X_h_firm_sic_intens "Fed Purchases*Firm Intens"
cap label var fed_fore_X_h_firm_sic_intens "Frcst Fed Purchases*Firm Intens"

cap destring, replace
compress

*Missing lavg_volr in monthly data
cap gen lavg_volr=lavg_vol_91


*Nick to Update
*Cleaning of volatilty for some extreme outliers (either mistakes or stocks not normally traded)
cap gen ratio_91=avg_vol_91/avg_volr
cap replace lavg_vol_91=. if ratio_91<3|ratio_91>100
foreach var in lavg_vol_30 lavg_vol_91 lavg_vol_182 lavg_volr {
*replace `var'=. if exp(`var')>1.5|exp(`var')<0.1
su `var',de
replace `var'=r(p1) if `var'<r(p1)&`var'~=.
replace `var'=r(p99) if `var'>r(p99)&`var'~=.
}

*For weighting purposes useful
egen memp=mean(emp)
replace emp=memp if emp==.
egen mtemp=mean(emp),by(ticker_code)
*Need integer non-zero values to use reghdfe so scale by 1000 and round, and assume all firms have to have at least one employee
replace emp=round(1000*mtemp) 
replace emp=1 if emp==0
egen mrev=mean(rev),by(ticker_code)
replace mrev=round(mrev)
*Need integer non-zero values to here again replace 0 with 1 and missing with mean
replace mrev=1 if mrev==0
egen mmrev=mean(mrev)
replace mrev=round(mmrev) if mrev==.

*Drop without volume
drop if volume==0|volume==.

*Can get volume results if censor/windosrize on volume
gen lvolume=log(1+volume)
su lvolume,de
replace lvolume=. if lvolume<r(p1)
replace lvolume=r(p99) if lvolume>r(p99)&lvolume~=.

compress
cap log close
cap log using "volatility",t replace
********************************************************
*Keep core sample
qui reghdfe lavg_vol_30 lavg_volr lavg_vol_182 lEPU_X_h_firm_sic_intens lvix_X_h_firm_sic_intens defense health fin_regulation lEU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   sic3 emp, ab(ticker_code period_code) 
keep if e(sample)

*************************************
****Table 2:
*************************************
***Colum 1: No FEs
reg lavg_vol_30 lEPU fed [aw=emp], vce(cl ticker_code)

**Column 2: Add firm and time FEs and exposure measure
reghdfe lavg_vol_30 lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

so yq
su lEPU if (year==2005|year==2006)&(yq~=yq[_n-1])
global low_EPU=r(mean)
su lEPU if (year==2008|year==2009)&(yq~=yq[_n-1])
global jump=r(mean)-$low_EPU
xtsum lavg_vol_30 if e(sample)
*Note point impact for firm with 25% exposure about 20% of a SD for implied vol
di _b[lEPU_X_h_firm_sic_intens]*$jump*0.25

**Column 3 Add linear VIX
reg lavg_vol_30 lEPU fed lvix  [aw=emp],vce(cl ticker_code)

**Column 4 Add FEs and interact VIX and EPU with exposure
reghdfe lavg_vol_30 lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens lvix_X_h_firm_sic_intens    [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

**Column 5 Add linear EU
reg lavg_vol_30 lEPU fed lEU [aw=emp], vce(cl ticker_code)

**Column 6 Again add FEs and interact
reghdfe lavg_vol_30 lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens lEU_X_h_firm_sic_intens    [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

**Column 7 Categories result
replace defense=0 if sic3~=348&sic3~=372&sic3~=376&sic3~=379&sic3~=381&sic3~=871
gen ldefense=log(1+defense)
replace health=0 if (sic3<800|sic3>=810)
gen lhealth=log(1+health)
replace fin_regulation=0 if sic3<600|sic3>699
gen lfin_regulation=log(1+fin_regulation)
reghdfe lavg_vol_30 ldefense lhealth lfin_reg lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)
test ldefense lhealth lfin_regulation

*********************************************************************
***Table 3: Robustness
*********************************************************************

**Column - Realized Vol
reghdfe lavg_volr    lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

**Column  - Longer Run
reghdfe lavg_vol_182 lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

*Column  - Add in forecasts
reghdfe lavg_vol_30 lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens fed_fore_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

**Column  - Including next 12 quarters
tsset ticker_code period_code
reghdfe lavg_vol_30 lEPU_X_h_firm_sic_intens f(0/12).fed_X_h_firm_sic_intens    [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

**Robustness to different weights: Individual firm
reghdfe lavg_vol_30 lEPU_X_firm_intens fed_X_firm_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

**Robustness to different weights: Belo
reghdfe lavg_vol_30 lEPU_X_belo               fed_X_belo                 [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

*Using betas
reghdfe lavg_vol_30 lEPU_X_beta               fed_X_beta                 [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

*Using 10k risk measures
reghdfe lavg_vol_30 lEPU_X_jp               fed_X_jp                 [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)

*Firms with 500m+ sales (very similar to 10k plus employees) - basically large firms
reghdfe lavg_vol_30 lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   if mrev>=500, ab(ticker_code period_code) vce(cl ticker_code)


********************************
****Table A1
********************************
cap estimates drop *
**Baseline again
reghdfe lavg_vol_30 lEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)
global baseline=_b[lEPU_X_h_firm_sic_intens]
**Column X2 Use EPU/E
reghdfe lavg_vol_30 leEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)
test _b[leEPU_X_h_firm_sic_intens]=$baseline
**Column X3 Use EPU/P
reghdfe lavg_vol_30 lpEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)
test _b[lpEPU_X_h_firm_sic_intens]=$baseline
**Column X4 Use EPU/U
reghdfe lavg_vol_30 luEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)
test _b[luEPU_X_h_firm_sic_intens]=$baseline
**Column X5 Use EPU/EP
reghdfe lavg_vol_30 lepEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)
test _b[lepEPU_X_h_firm_sic_intens]=$baseline
**Column X6 Use EPU/EU
reghdfe lavg_vol_30 leuEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)
test _b[leuEPU_X_h_firm_sic_intens]=$baseline
**Column X7 Use EPU/PU
reghdfe lavg_vol_30 lpuEPU_X_h_firm_sic_intens fed_X_h_firm_sic_intens   [aw=emp], ab(ticker_code period_code) vce(cl ticker_code)
test _b[lpuEPU_X_h_firm_sic_intens]=$baseline

log close
