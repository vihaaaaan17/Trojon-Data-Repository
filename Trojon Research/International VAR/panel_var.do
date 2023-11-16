*FILE CREATED BY NICK BLOOM ON 6 March 2016, NBLOOM@STANFORD.EDU
clear all
set matsize 4000 

************************************
************************************
*SET BASIC PARAMETERS
global lags=3
global jump=2*$lags
global plot=36
************************************
************************************

*SET UP THE BASIC DATA
u data/all_econ_epu_data_new, clear
cap rename KOR_stocks korea_stocks
cap rename KOR_ip korea_ip
cap rename KOR_unemp korea_unemp
global lags=3
global plot=36
gen ym=year+(month-1)/12

*Make long for VAR with 1 year gap between countries
replace ym=year+(month-1)/12
expand 13 if ym==1985
so ym
replace year=1984 in 1/12
replace month=_n in 1/12
replace ym=year+(month-1)/12
cap drop europe*
foreach var1 in stocks unemp ip epu {
foreach var2 in usa canada china germany france italy spain uk japan india russia korea {
cap rename `var2'_`var1' `var1'`var2'
}
}

reshape long stocks unemp ip epu,i(ym) j(country, string) 
foreach var in epu ip unemp stocks {
replace `var'=. if year==1984
}
replace country="korea" if country=="KOR"
so ym country
merge 1:1 ym country using data/overnight
foreach var in france germany italy spain {
cap egen europe_overnight=max(overnight*(country=="europe")),by(ym)
replace overnight=europe_overnight if country=="`var'"&ym>=1999
}
drop if _m==2
drop _m

merge 1:1 ym country using data/rate_usa
drop if _m==2
ren overnight rate
replace rate=fedf if country=="usa"

*Fill in missing rates and unem for India
so country ym
by country: ipolate rate ym,gen(i_rate)
replace rate=i_rate if country=="india"&rate==.
by country: ipolate unemp ym,gen(i_unemp)
replace unemp=i_unemp if country=="india"&unemp==.

*Fill in missing unem for China
by country: ipolate unem ym,gen(_unem)
replace unem=_unem if country=="china"

*Fill in missing IP for Spain
by country: ipolate ip ym,gen(i_ip)
replace ip=i_ip if country=="spain"&ip==.
order ym country
encode country,gen(code)
gen papers=10
replace papers=5 if country=="canada"
replace papers=6 if country=="korea"
replace papers=7 if country=="india"
replace papers=2 if country=="spain"|country=="germany"|country=="uk"|country=="france"|country=="italy"|country=="japan"
replace papers=1 if country=="china"|country=="russia"
egen miny=min(ym)
egen maxy=max(ym)
gen tym=ym+(code-1)*(maxy-miny+1/12)
replace epu=. if year==1984
replace ip=. if year==1984
gen period=round(tym*12)
tsset period
tab country,gen(cc)
gen lip=log(ip)
gen lstock=log(stock)
replace lstock=stock if country=="europe"
egen svol=sd(lstock),by(country year)
tssmooth ma vol=svol,w(6 1 6)
replace vol=. if svol==0|svol==.|l6.svol==0|f6.svol==0
replace vol=svol if vol==.&svol~=.&svol~=0
egen usepu=max(epu*(country=="usa")),by(ym)

*Define uncertainty variable
su epu if year==2005|year==2006
global epu_low=r(mean)
su epu if year==2011|year==2012
global epu_high=r(mean)

cap drop _m
encode country,gen(cty)
tsset cty period
qui tab year,gen(yy)
qui tab month,gen(mm)

*Define a core sample
keep if epu~=.&lstock~=.&rate~=.&unem~=.&lip~=.&year~=.&month~=.&cty~=.

*Weighting by number of papers in the index and remove country FEs
foreach var in lip epu lstock unemp {
cap egen mpapers=mean(papers)
cap gen weight=(papers/mpapers)^(1/2)
replace `var'=(weight)*`var'
}

irf set results,replace

qui var epu lstock rate unem lip, ex(cc* ) lags(1(1)$lags)
irf create baseline,step($plot) replace set(results)

qui var epu lstock rate unem lip, lags(1(1)$lags)
irf create nofes,step($plot) replace set(results)

qui var epu rate unem lip, ex(cc* ) lags(1(1)$lags)
irf create nsp,step($plot) replace set(results)

qui var epu vol lstock rate unem lip, ex(cc* ) lags(1(1)$lags)
irf create vol,step($plot) replace set(results)

qui var lstock epu rate unem lip, ex(cc* ) lags(1(1)$lags)
irf create reverse,step($plot) replace set(results)

qui var epu lstock rate unem lip, ex(cc* ) lags(1(1)$jump)
irf create lags6,step($plot) replace set(results)

qui var epu lip, ex(cc* ) lags(1(1)$lags)
irf create bi,step($plot) replace set(results)

qui var lip epu, ex(cc* ) lags(1(1)$lags)
irf create rbi,step($plot) replace set(results)

*Removing weighting 
foreach var in lip epu lstock unemp {
replace `var'=`var'/weight
}
qui var epu lstock unem lip, ex(cc* ) lags(1(1)$lags)
irf create unweight,step($plot) replace set(results)

global tests="baseline nofes lags6 bi rbi nsp vol unweight" 

******************************
******************************
*Plotting the graph
******************************
******************************
u results.irf,replace
ren step _step
drop cirf coirf sirf  fevd sf* mse*  dm cdm stddm
drop stdi* stdc* stdf* stds*

gen ir=impulse+response
drop impulse response
ren _step step

qui reshape wide oirf irf stdoirf,i(step irfname) j(ir) string

***THREE STEPS OF NORMALIZATION TO GET MAGNITUDES
****Normalizing the oirfs into the same units as irf
egen epuratio=max((step==0)*oirfepuepu),by(irfname)
replace oirfepulip   =oirfepulip/epuratio
replace oirfepuunem   =oirfepuunem/epuratio
replace stdoirfepulip =stdoirfepulip /epuratio
replace stdoirfepuunem =stdoirfepuunem /epuratio

****Normalizing the oirfs into meaningful units, vol to a 15 unit shock if actual, stock-market to 5% and interest rates to 1%
global ratio=$epu_high-$epu_low
global se=1.645
foreach var in lip unem {
replace oirfepu`var'=oirfepu`var'*$ratio
replace stdoirfepu`var'=stdoirfepu`var'*$ratio

****Normalizing the impact into % unit for both out and employment
replace oirfepu`var'=oirfepu`var'*100 if "`var'"=="lip"
replace stdoirfepu`var'=stdoirfepu`var'*100  if "`var'"=="lip"

***Generate standard error bands
gen l`var'=oirfepu`var'-stdoirfepu`var'*$se
gen h`var'=oirfepu`var'+stdoirfepu`var'*$se
}
lab var step "month"

******PLOTTING OUTPUT
*MAIN RESULTS - OUTPUT (%)
scatter oirfepulip llip hlip step if irfname=="baseline"&step<$plot,c(l l l)   lp(l _ -) s(+ p p) legend(off) lw(medthick medium medium) lc(black cranberry cranberry) mc(black cranberry cranberry)  xlab(0($jump)$plot)
graph export figure_10a.png, replace height(600) width(900)

*MAIN RESULTS - Unemployment (%)
scatter oirfepuunem lunem hunem step if irfname=="baseline"&step<$plot,c(l l l)   lp(l _ -) s(+ p p) legend(off) lw(medthick medium medium) lc(black cranberry cranberry) mc(black cranberry cranberry)  xlab(0($jump)$plot)
graph export figure_10b.png, replace height(600) width(900)

*APPENDIX ROBUSTNESS TABLE
foreach var in $tests {
egen `var'=sum(oirfepulip*(irfname=="`var'")), by(step)
}
scatter $tests step if step<$plot,c(l l l l l l l l) s(+ p p p p p p p p p) legend(off) lw(medthick medthick medium medium) lc(black cranberry black black) mc(black cranberry black black)  xlab(0($jump)$plot) 
graph export figure_c8.png, replace height(600) width(900)
