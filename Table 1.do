
***************************************************************************************************************
										*TABLE 1.DIFFERENCE IN DIFFERENCE ESTIMATES
***************************************************************************************************************
capture cd "C:\Users\lenovo\Desktop\Akpene\Masters Work\Non-linear econometrics\Project\Analysis"

use "../Data/FinalData", clear

*2010 to 2013 VS 2014 to 2015
gen period=0
replace period=1 if Year==2014 | Year==2015
tab period,m

*Variable of interest (treatment times post)
gen treatment_post=treatment*expansion
tab treatment_post,m

*Other covariates
global regvars age education female married FamilySize unemployed white ///
black americanindian asian pacific multiracial hispanic Unemploymentrate cphonesam

*State fixed effects
qui tabulate _state, gen(state)
global  state_fe state1-state50

*Quarter_year fixed effects
gen year_q= (Year*10) + quarter
qui tabulate (year_q), gen(yearq)
global quarteryear_fe yearq1-yearq21

*REGRESSIONS FOR TABLE 1:
*Health Insurance
qui eststo col_2: reg insurance treatment_post $regvars $state_fe $quarteryear_fe [pw=_llcpwt],vce(cl _state) // all adults  
qui eststo col_4: reg insurance treatment_post $regvars $state_fe $quarteryear_fe [pw=_llcpwt] if female == 1,vce(cl _state) // females only
qui eststo col_6: reg insurance treatment_post $regvars $state_fe $quarteryear_fe [pw=_llcpwt] if female == 0,vce(cl _state) // males only 
qui eststo col_8: reg insurance treatment_post $regvars $state_fe $quarteryear_fe [pw=_llcpwt] if children == 0,vce(cl _state) // childless adults
qui eststo col_10: reg insurance treatment_post $regvars $state_fe $quarteryear_fe [pw=_llcpwt] if children != 0,vce(cl _state) // adults with kids

*MEANS FOR TABLE 1 (Pre-2014 means):
*Pre_2014 mean for expansion group
eststo alladults: estpost sum insurance if period==0 & treatment==1 [w=_llcpwt]
*Pre-2014 mean for expansion group(women only):
eststo women: estpost sum insurance if period==0 & treatment==1 & female == 1 [w=_llcpwt]
*Pre-2014 mean for expansion group(men only):
eststo men: estpost sum insurance if period==0 & treatment==1 & female == 0 [w=_llcpwt] 
*Pre-2014 mean for expansion group(childless adults):
eststo childless: estpost sum insurance if period==0 & treatment==1 & children == 0 [w=_llcpwt]
*Pre-2014 mean for expansion group(adults with children under 18):
eststo childful: estpost sum insurance if period==0 & treatment==1 & children != 0 [w=_llcpwt] 

*Designing the table:
esttab alladults women men childless childful, label  title("Pre-2014 means of adults in expansion states") replace cell((mean(fmt(%15.2f))) (sd(fmt(%15.2f) par("("")")))) varwidth(24) modelwidth(17) obslast scalar("N Observations") nostar ///
mtitles("All adults" "Women only" "Men only" "Childless adults" "Parents only") ///
collabels(none) ///
coeflabels(insurance "Have Insurance")

*Latex Output: 
esttab alladults women men childless childful using "Table1means.tex", replace ///
label ///
title("Pre-2014 means of adults in expansion states") ///
varwidth(24) modelwidth(17) ///
replace cell((mean(fmt(%15.2f))) (sd(fmt(%15.2f) par("("")")))) ///
obslast scalar("N Observations") nostar ///
order(age income education sex married unemployed white black americanindian asian pacific other multiracial hispanic insurance) ///
mtitles("All adults" "Women only" "Men only" "Childless adults" "Parents only") ///
collabels(none) ///
coeflabels(insurance "Have Insurance")

*Table of DiD estimates:
esttab col_2 col_4 col_6 col_8 col_10 , label title("Table 1, DiD estimates for impact of Medicaid expansion on insurance for low-income, non-elderly adults") keep(treatment_post) varwidth(24) mtitles("All adults" "All Women" "All Men" "Childless adults" "Parents only") se(3) coeflabels(treatment_post "DiD Estimate") modelwidth(17)



***************************************************************************************************************
											*TABLE J1
***************************************************************************************************************

*Main variables for eventstudy (Add missing variables. Check paper for directions)
*Once missing variables are added, this code can automatically generate the needed 
*information for Table J1
gen year2010=0
replace year2010=1 if Year==2010

gen year2011=0
replace year2011=1 if Year==2011

gen year2012=0
replace year2012=1 if Year==2012

gen year2013=0
replace year2013=1 if Year==2013

gen year2014=0
replace year2014=1 if Year==2014

gen year2015=0
replace year2015=1 if Year==2015

gen expansion_year2010=0
replace expansion_year2010=1 if year2010==1 & treatment==1

gen expansion_year2011=0
replace expansion_year2011=1 if year2011==1 & treatment==1

gen expansion_year2012=0
replace expansion_year2012=1 if year2012==1 & treatment==1

gen expansion_year2014=0
replace expansion_year2014=1 if year2014==1 & treatment==1

gen expansion_year2015=0
replace expansion_year2015=1 if year2015==1 & treatment==1



*Eventstudy regression
eststo tableJ1: reg insurance expansion_year2015 expansion_year2014 expansion_year2012 ///
expansion_year2011 expansion_year2010 $regvars $state_fe $quarteryear_fe [pw=_llcpwt]

*Joint significance test for pre-2014 interaction coefficents are 0
testparm expansion_year2010 expansion_year2011 expansion_year2012, df(50)
estadd scalar p_value =r(p)

*Table J1
esttab tableJ1, b(3) se(3) label nodepvar nonumber ///
keep(expansion_year2015 expansion_year2014 expansion_year2012 expansion_year2011 ///
expansion_year2010) order(expansion_year2015 expansion_year2014 expansion_year2012 expansion_year2011 ///
expansion_year2010) stats(p_value N, fmt(%15.3f %15.0g) ) star(* 0.10 ** 0.05 *** 0.01) replace

esttab tableJ1 using "TableJ1.tex", replace ///
b(3) se(3) label nodepvar nonumber ///
keep(expansion_year2015 expansion_year2014 expansion_year2012 expansion_year2011 ///
expansion_year2010) order(expansion_year2015 expansion_year2014 expansion_year2012 expansion_year2011 ///
expansion_year2010) stats(p_value N, fmt(%15.3f %15.0g) ) star(* 0.10 ** 0.05 *** 0.01) replace

