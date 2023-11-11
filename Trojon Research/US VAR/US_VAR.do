*Do file created by Nick Bloom on March 6 2016, nbloom@stanford.edu
clear all
set more off

************************************
************************************
global lags=3/$months
global lags2=2*$lags
global jump=6
global plot=36/$months
************************************
************************************

*Basic data set-up
use data/modern_epu_data
keep year month total*
ren total_index_UP total_index_PU
foreach var in E P U EP EU PU EPU {
ren total_index_`var' `var'
}
save data/modern_epu_data_clean,replace

*Historical data
use data/all_hist_data
order year month quarter
cap drop _m
so year month quarter
merge 1:1 year month using data/modern_epu_data_clean,update
drop _m
so year month quarter
merge m:1 year quarter using data/abcq,update
drop if _m==2
drop _m
keep year - rgnp72

*Michigan consumer sentiment data - some robustness test data
merge 1:1 year month using data/consumer_sentiment_data
ren Month mich
drop if _m==2
drop _m

***Merge in govt data
merge m:1 year using data/yearly_fed_measurements
drop if _merge==2
drop _merge

***Merge in NIPA data
merge 1:1 year month using data/nipa
drop if _merge==2
drop _merge

*Extrapolate back using old GDP data
gen lgdp=log(gdp)
gen lrgnp=log(rgnp)
reg lgdp lrgnp
predict hlgdp
replace lgdp=hlgdp if lgdp==.

***Merge in Stock data
merge m:1 year month using data/sp_500_data
drop if _merge==2
drop _merge

***Merge in Macro data 
merge m:1 year month using data/macro_data
drop if _merge==2
drop _merge
replace vix=. if year<1990

***Merge historic IP
merge m:1 year month using data/ip
drop _merge
replace indus=ip
drop ip

***Merge historic FFR
merge m:1 year month using data/nyrate
drop if _merge==2
drop _merge
replace fedf=nyrate if fedf==.&year<1960
drop nyrate

**Merge in historical employment data
cap drop _m
so year month
merge 1:1 year month using data/historical_emp
drop _m
merge m:1 year month using data/sp_500_vol_data
drop if _merge==2
drop _merge
drop sp_index
gen ym=year+(month-1)/12
replace quarter=floor((month+2)/3) if quarter==.
gen yq=year+(quarter-1)/4
gen time=ym*12
tsset time
gen lemp=log(employment)
gen lip=log(indus)
ren sp sp

*These two obs were missing so hand punch in
replace sp=1380 if year==2012&month==11
replace sp=1420 if year==2012&month==12
gen lsp=log(sp)
gen ldurable=log(durable)
gen lnondurable=log(nondurable)
gen lpce=log(pce)
gen lgross=log(gross)
gen lfixed=log(fixed)
gen lnonres=log(nonres)
gen lstruct=log(structures)
gen lequip=log(equip)
gen lresident=log(resident)
ren fedfundsrate ffr

lab var h_EPU "Historical Policy uncertainty index"
lab var sp "Closing value of S&P500 index"
lab var gdp "Real Gross Domestic Product (GDP)"
lab var vix "VIX index of implied equity volatility on the S&P500"
lab var EPU "Post 1985 EPU"
lab var ym "Year in fraction (i.e. 2010.5 is July 2010)"
lab var year "Year"
lab var month "Calendar Month"
lab var time "Indicator for Stata to tsset, definied as ym*12"
lab var employment "Aggregate non-farm employment"
lab var lemp "Log employment"
lab var lgdp "Log real gdp"
lab var lip "Log industrial production"
lab var lsp "Log stock index"
lab var ldurable "Log durable consumption"
lab var lnondurable "Log nondurable consumption"
lab var lpce "Log personal consumption expenditure"
lab var lgross "Log gross investment"
lab var lfixed "Log fixed investment"
lab var lnonres "Log non-residential investment"

*Uncertainty measures
gen epu=EPU
gen eu=EU

*For Quarterly Collapse the Data
if $months==3 {
collapse epu EPU h_EPU_war lsp ffr lemp ldurable lnondurable lgdp lgross lfixed lnonres lstruct lequip lpce lip vix eu lresident year mich quarter,by(yq)
gen time=4*yq
tsset time
gen ym=yq 
}
gen linvest=lgross
gen lconsumption=lpce

if $months==1 {
*Note to save changing variable names too much call industrial production GDP for monthly runs on IP
replace lgdp=lip
}

tsset time
gen dlgdp=lgdp-l.lgdp
forval i=1(1)3 {
gen l`i'=l`i'.dlgdp
gen f`i'=f`i'.dlgdp
}

su epu if year==2005|year==2006
global epu_low=r(mean)
su epu if year==2011
global epu_high=r(mean)

gen recession=0
replace recession=1 if (yq>=1945)&(yq<=1945.76)
replace recession=1 if (yq>=1948.74)&(yq<=1949.76)
replace recession=1 if (yq>=1953.24)&(yq<=1954.26)
replace recession=1 if (yq>=1957.49)&(yq<=1958.26)
replace recession=1 if (yq>=1960.24)&(yq<=1961)
replace recession=1 if (yq>=1969.74)&(yq<=1970.76)
replace recession=1 if (yq>=1973.74)&(yq<=1975)
replace recession=1 if (yq>=1980)&(yq<=1980.51)
replace recession=1 if (yq>=1981.49)&(yq<=1982.76)
replace recession=1 if (yq>=1990.49)&(yq<=1991)
replace recession=1 if (yq>=2001)&(yq<=2001.76)
replace recession=1 if (yq>=2008)&(yq<=2009.26)

*For magnitudes note investment falls by 8.4% on average in post-WWII recessions 
reg lgross recession yq
reg lemp recession yq
sa var,replace

*Baseline regressions
u var,replace
irf set results,replace
gen ym2=ym^2
qui var epu lsp ffr lemp lgdp if year>=1985,lags(1(1)$lags)
irf create baseline,step($plot) replace set(results)

*Quarterly regressions including investment
cap qui var epu lsp ffr lgross lgdp if year>=1985,lags(1(1)$lags)
cap irf create quarterly,step($plot) replace set(results)

replace epu=h_EPU_war
qui var epu lsp    lgdp ym if year<1985,lags(1(1)$lags)
irf create history,step($plot) replace set(results)
replace epu=EPU

cap qui var epu lsp ffr lemp lgdp ym if year>=1985,lags(1(1)$lags)
cap irf create timetrend,step($plot) replace set(results)

qui var epu lgdp,lags(1(1)$lags)
irf create bi,step($plot) replace set(results)

qui var lgdp epu,lags(1(1)$lags)
irf create rbi,step($plot) replace set(results)

qui var epu ffr lemp lgdp,lags(1(1)$lags)
irf create nsp,step($plot) replace set(results)

qui var lgdp lemp ffr lsp epu,lags(1(1)$lags)
irf create reverse,step($plot) replace set(results)

qui var epu vix lsp ffr lemp lgdp,lags(1(1)$lags)
irf create vix,step($plot) replace set(results)

qui var epu eu lsp ffr lemp lgdp,lags(1(1)$lags)
irf create eu,step($plot) replace set(results)

qui var epu lsp ffr lemp lgdp,lags(1(1)$lags2)
irf create lags6,step($plot) replace set(results)

qui var epu mich lsp ffr lemp lgdp,lags(1(1)$lags)
irf create mich_second,step($plot) replace set(results)

qui var mich epu lsp ffr lemp lgdp,lags(1(1)$lags)
irf create mich_first,step($plot) replace set(results)

global tests="baseline timetrend vix eu lags6 bi rbi nsp history mich_first mich_second"


******************************
******************************
*Plotting the graph
******************************
******************************
u results.irf,replace
ren step _step
drop cirf coirf sirf  fevd sf* mse* dm cdm stddm
drop stdi* stdc* stdf* stds*

gen ir=impulse+response
drop impulse response
ren _step step


qui reshape wide oirf irf stdoirf,i(step irfname) j(ir) string


***THREE STEPS OF NORMALIZATION TO GET MAGNITUDES
****Normalizing the oirfs into the same units as irf
egen epuratio=max((step==0)*oirfepuepu),by(irfname)
replace oirfepulgdp   =oirfepulgdp/epuratio
replace oirfepulemp   =oirfepulemp/epuratio
cap replace oirfepulgross   =oirfepulgross/epuratio
replace stdoirfepulgdp =stdoirfepulgdp /epuratio
replace stdoirfepulemp =stdoirfepulemp /epuratio
cap replace stdoirfepulgross =stdoirfepulgross /epuratio

****Normalizing the oirfs into meaningful units, vol to a 15 unit shock if actual, stock-market to 5% and interest rates to 1%
global ratio=$epu_high-$epu_low
global se=1.645
foreach var in lgdp lemp lgross {
cap replace oirfepu`var'=oirfepu`var'*$ratio
cap replace stdoirfepu`var'=stdoirfepu`var'*$ratio
****Normalizing the impact into % unit for both out and employment
cap replace oirfepu`var'=oirfepu`var'*100
cap replace stdoirfepu`var'=stdoirfepu`var'*100
***Generate standard error bands
cap gen l`var'=oirfepu`var'-stdoirfepu`var'*$se
cap gen h`var'=oirfepu`var'+stdoirfepu`var'*$se
}
lab var step "year"
sa irf,replace

******PLOTTING OUTPUT
lab var step "Months"

if $months==1 {
***MAIN PAPER FIGURES
*MAIN RESULTS - OUTPUT (%)
scatter oirfepulgdp llgdp hlgdp step if irfname=="baseline"&step<=$plot,c(l l l)   lp(l _ -) s(+ p p) legend(off) lw(medthick medium medium) lc(black cranberry cranberry) mc(black cranberry cranberry)  xlab(0($jump)$plot) graphregion(color(white))
graph export figure_8a.png, replace height(600) width(900)
*MAIN RESULTS - Employment (%)
scatter oirfepulemp llemp hlemp step if irfname=="baseline"&step<=$plot,c(l l l)   lp(l _ -) s(+ p p) legend(off) lw(medthick medium medium) lc(black cranberry cranberry) mc(black cranberry cranberry)  xlab(0($jump)$plot)  graphregion(color(white))
graph export figure_8b.png, replace height(600) width(900)
*ROBUSTNESS VAR
foreach var in $tests {
egen `var'=sum(oirfepulgdp*(irfname=="`var'")), by(step)
}
scatter baseline timetrend vix eu lags6 bi rbi nsp history step if step<=$plot,c(l l l l l l l l l l) s(+ p p p p p p p p p p p) legend(off) lw(medthick medthick medium medium) lc(black cranberry black black) mc(black cranberry black black)  xlab(0($jump)$plot)   graphregion(color(white))
graph export figure_9.png, replace height(600) width(900)

***APPENDIX FIGURES
*MICHIGAN CONSUMER SURVEY CONTROL RESULTS
scatter baseline mich_first mich_second step if step<=$plot,c(l l l l l l l l l l) s(+ p p p p p p p p p p p) legend(off) lw(medthick medthick medium medium) lc(black cranberry black black) mc(black cranberry black black)  xlab(0($jump)$plot)    graphregion(color(white))
graph export figure_c7.png, replace height(600) width(900)
}

else {
*QUARTERLY MAIN RESULTS - GDP (%). THIS ONLY PRODUCES SENSIBLE RESULTS WHEN MONTHS=3 IS SET AT THE BEGINNING
lab var step "Quarters"

scatter oirfepulgdp llgdp hlgdp step if irfname=="quarterly"&step<=$plot,c(l l l)   lp(l _ -) s(+ p p) legend(off) lw(medthick medium medium) lc(black cranberry cranberry) mc(black cranberry cranberry)  xlab(0($jump)$plot)    graphregion(color(white))
graph export figure_c6a.png, replace height(600) width(900)
scatter oirfepulgross llgross hlgross step if irfname=="quarterly"&step<=$plot,c(l l l)   lp(l _ -) s(+ p p) legend(off) lw(medthick medium medium) lc(black cranberry cranberry) mc(black cranberry cranberry)  xlab(0($jump)$plot)    graphregion(color(white))
graph export figure_c6b.png, replace height(600) width(900)

}
