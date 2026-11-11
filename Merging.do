***Merging in Unemployment and Poverty Line:

capture cd "C:\Users\lenovo\Desktop\Akpene\Masters Work\Non-linear econometrics\Project\Data"

cls
clear

*Unemployment Data:
import excel using unemployment, firstrow cellrange(a8:k28469) clear 
sort Year Month FIPSCode
destring Year, replace
destring Month, replace
drop if FIPSCode == "037"
drop if FIPSCode == "51000"
destring FIPSCode, replace
duplicates list Year Month FIPSCode
save unemployment.dta, replace


*Merging in Unemployment Data:
use TableI1, clear
sort iyear imonth _state
**Recoding and generating new variables for consistency:
generate FIPSCode=.
replace FIPSCode=_state
drop if FIPSCode > 56
rename iyear Year //for consistency
rename imonth Month //for consistency
order _state FIPSCode fmonth Year Month 

merge m:1 Year Month FIPSCode using unemployment.dta, keepusing(Unemploymentrate) //merging in unemployment rates
*saving the new table:
drop if Year < 2010
drop if Year > 2015
save TableI1_unem.dta, replace
tab Year age
describe
summarize



*Poverty Guidelines:
import excel using PovertyGuidelines, sheet("48 Contiguous States--Nonfarm") firstrow cellrange(a4:k61) clear
tempfile states48
save `states48'

import excel using PovertyGuidelines, sheet("Alaska--Nonfarm") firstrow cellrange(a4:k61) clear
tempfile Alaska 
save `Alaska'

import excel using PovertyGuidelines, sheet("Hawaii--Nonfarm") firstrow cellrange(a4:k61) clear
tempfile Hawaii
save `Hawaii'

*Merging separate datasets into one dataset:
use `states48', clear
append using `Alaska'
append using `Hawaii'

list in 1/5

*Generating FIPSCode for identification:
generate stateid=00 if _n <=57 //48 states
replace stateid=02 if inrange(_n, 58, 114) //Alaska
replace stateid=15 if _n>114 //Hawaii
generate FIPSCode=.
replace FIPSCode=stateid
sort Year FIPSCode
order DateofPublication Year FIPSCode
list in 1/5

*reshaping the dataset:
rename Person1 Persons1
reshape long Persons, i(Year FIPSCode) j(FamilySize)
generate Persons8 = .
replace Persons8 = Persons if FamilySize == 8
generate familysizemerge = FamilySize //for merging the dataset in 
rename Persons PovertyGuideline
rename stateid PovertyState
save Povertyguidelines.dta, replace //saving the dataset
describe
summarize


**Merging in Poverty guidelines: 
use TableI1_unem, clear
describe
summarize
*recoding children
replace children=0 if children==88
replace children = . if children==99
replace hhadult = . if hhadult == 99
replace hhadult = . if hhadult == 77
*generating a variable for FamilySize
generate FamilySize=.
replace FamilySize = numadult+children if inrange(Year, 2010, 2013)
replace FamilySize=hhadult+children if inrange(Year, 2014, 2015) 
replace FamilySize = numadult if children == . & inrange(Year, 2010, 2013)
replace FamilySize = hhadult if children == . & inrange(Year, 2014, 2015)
replace FamilySize = nummen + numwomen + children if numadult == . & inrange(Year, 2010, 2013)
replace FamilySize = nummen + numwomen + children if hhadult == . & inrange(Year, 2014, 2015)
generate familysizemerge = FamilySize //for easy merging
replace familysizemerge = 8 if FamilySize >=8 & FamilySize != .

generate PovertyState=00
replace PovertyState=02 if _state==2
replace PovertyState=15 if _state==15
sort Year Month FIPSCode
merge m:1 Year familysizemerge PovertyState using Povertyguidelines, generate(__merge) keepusing(PovertyGuideline ForEachAdditionalPerson9 Persons8)
drop if Year < 2010
drop if Year > 2015


*creating variables to help calculate poverty guidelines for families larger than 8:
bysort Year PovertyState: egen Persons8_filled = max(Persons8) if FamilySize != .
bysort Year PovertyState: egen ForEachAdditional_filled = max(ForEachAdditionalPerson9) if FamilySize != .

sort Year Month _state
*generating poverty guidelines for families larger than 8:
replace PovertyGuideline = Persons8_filled + (FamilySize - 8) * ForEachAdditional_filled if FamilySize > 8 & FamilySize != .
generate income = .
replace income = 10000 if income2 == 1
replace income = 15000 if income2 == 2
replace income = 20000 if income2 == 3
replace income = 25000 if income2 == 4
replace income = 35000 if income2 == 5
replace income = 50000 if income2 == 6
replace income = 75000 if income2 == 7
replace income = 100000 if income2 == 8

*generating the federal poverty line:
generate FPL = .
replace FPL = (income/PovertyGuideline)*100

*generating an indicator for expansion states:
generate expansion = .
*Replacing with 0 for non-expansion states:
replace expansion = 0 if inlist(FIPSCode, 01, 12, 13, 16, 20, 22, 23, 28, 29, 30)
replace expansion = 0 if inlist(FIPSCode, 32, 37, 40, 45, 46, 47, 48, 49, 51, 56) 
*Replacing with 1 for states with late expansion:
replace expansion = 1 if FIPSCode == 02 & Year == 2015 & Month >= 09 //Alaska
replace expansion = 1 if FIPSCode == 02 & Year > 2015
replace expansion = 1 if FIPSCode == 18 & Year == 2015 & Month >= 02 //Indiana
replace expansion = 1 if FIPSCode == 18 & Year > 2015
replace expansion = 1 if FIPSCode == 26 & Year == 2014 & Month >= 04 //Michigan
replace expansion = 1 if FIPSCode == 26 & Year > 2014
replace expansion = 1 if FIPSCode == 33 & Year == 2014 & Month >= 04 //New Hampshire
replace expansion = 1 if FIPSCode == 33 & Year > 2014
replace expansion = 1 if FIPSCode == 42 & Year == 2015 & Month >= 01 //Pennsylvania
replace expansion = 1 if FIPSCode == 42 & Year > 2015
*Replacing with 0 for states with late expansion:
replace expansion = 0 if FIPSCode == 02 & Year == 2015 & Month < 09 //Alaska
replace expansion = 0 if FIPSCode == 02 & Year < 2015
replace expansion = 0 if FIPSCode == 18 & Year == 2015 & Month < 02 //Indiana
replace expansion = 0 if FIPSCode == 18 & Year < 2015
replace expansion = 0 if FIPSCode == 26 & Year == 2014 & Month < 04 //Michigan
replace expansion = 0 if FIPSCode == 26 & Year < 2014
replace expansion = 0 if FIPSCode == 33 & Year == 2014 & Month < 04 //New Hampshire
replace expansion = 0 if FIPSCode == 33 & Year < 2014
replace expansion = 0 if FIPSCode == 42 & Year < 2015 //Pennsylvania
replace expansion = 1 if inrange(FIPSCode, 4, 10)
replace expansion = 1 if inlist(FIPSCode, 11, 15, 17, 19, 21, 24, 25, 27)
replace expansion = 1 if inlist(FIPSCode, 31, 34, 35, 36, 38, 39)
replace expansion = 1 if inlist(FIPSCode, 41, 44, 45, 50, 53, 54, 55)


*Generating an indicator for quarter:
generate quarter = .
replace quarter = 1 if inrange(Month, 1, 3)
replace quarter = 2 if inrange(Month, 4, 6)
replace quarter = 3 if inrange(Month, 7, 9)
replace quarter = 4 if inrange(Month, 10, 12)

*Generating variables for race:
generate white = 1 if race2 ==1 | _race == 1
replace white = 0 if white == .
generate black = 1 if race2 == 2 | _race == 2
replace black = 0 if black == .
generate americanindian = 1 if race2 == 3 | _race == 3
replace americanindian = 0 if americanindian == .
generate asian = 1 if race2 == 4 | _race == 4
replace asian = 0 if asian == .
generate pacific = 1 if race2 == 5 | _race == 5
replace pacific = 0 if pacific == .
generate other = 1 if race2 == 6 | _race == 6
replace other = 0 if other == .
generate multiracial = 1 if race2 == 7 | _race == 7
replace multiracial = 0 if multiracial == .
generate hispanic = 1 if race2 == 8 | _race == 8
replace hispanic = 0 if hispanic == .

*Generating variables for education:
generate education = .
replace education = 1 if educa == 1
replace education = 4.5 if educa == 2
replace education = 10 if educa == 3
replace education = 12 if educa == 4
replace education = 14 if educa == 5
replace education = 16 if educa == 6
drop if educa == 9

*Generating a variable to indicate for unemployment:
replace employ = . if employ == 9 & inrange(Year, 2010, 2012)
replace employ1 = . if employ1 == 9 & inrange(Year, 2013, 2015)
generate unemployed = .
replace unemployed = 1 if inrange(employ, 3, 4) & inrange(Year, 2010, 2012)
replace unemployed = 1 if inrange(employ1, 3, 4) & inrange(Year, 2013, 2015)
replace unemployed = 0 if inrange(employ, 1, 2) & inrange(Year, 2010, 2012)
replace unemployed = 0 if inrange(employ1, 1, 2) & inrange(Year, 2013, 2015)
replace unemployed = 0 if inrange(employ, 5, 8) & inrange(Year, 2010, 2012)
replace unemployed = 0 if inrange(employ1, 5, 8) & inrange(Year, 2013, 2015)

 
*Dropping Quarter 3 & 4 of 2011
drop if (quarter == 3 | quarter == 4) & Year == 2011


svyset [pweight = final_weight]
svy: mean age income education sex marital unemployed white black americanindian asian pacific other multiracial hispanic hlthpln1 if expansion==1 & inrange(Year, 2010, 2013) & FPL < 100 
estadd scalar sd = r(sd) // Manually adding the SD from r() to e()
eststo model1




*Generating TableI1:
*Expansion (2010-2013)
mean age income education sex marital unemployed white black americanindian asian pacific other multiracial hispanic hlthpln1 [pweight = final_weight] if expansion==1 & inrange(Year, 2010, 2013) & FPL < 100 
eststo Expansion2013

*Expansion (2014-2015)
mean age income education sex marital unemployed white black americanindian asian pacific other multiracial hispanic hlthpln1 [pweight = final_weight] if expansion==1 & inrange(Year, 2014, 2015) & FPL < 100 
eststo Expansion2015

*NonExpansion (2010-2013)
mean age income education sex marital unemployed white black americanindian asian pacific other multiracial hispanic hlthpln1 [pweight = final_weight] if expansion==0 & inrange(Year, 2010, 2013) & FPL < 100 
eststo Nonexpansion2013

*NonExpansion (2014-2015)
mean age income education sex marital unemployed white black americanindian asian pacific other multiracial hispanic hlthpln1 [pweight = final_weight] if expansion==0 & inrange(Year, 2014, 2015) & FPL < 100
eststo Nonexpansion2015

*Table Output
esttab Expansion2013 Expansion2015 Nonexpansion2013 Nonexpansion2015, ///
title("Table I1, Descriptive statistics of low-income, non-elderly adults sample") ///
varwidth(24) cells(b) noobs nostar ///
mtitles("2010 - 2013" "2014 - 2015" "2010 - 2013" "2014 - 2015") ///
collabels(none) ///
refcat(age "Panel 1: Demographics" white "Race" insure "Panel 2: Insurance", nolabel) ///
mgroups("Expansion States" "Non-Expansion States", pattern(1 0 1 0) span) ///
coeflabels(age "Age" income "Household Income" education "Years schooling" sex "Female" marital "Married" unemployed "Unemployed" white "White" blacl "Black" americanindian "Native American" asian "Asian" pacific "Pacific Islander" other "Other" multiracial "Multiracial" hispanic "Hispanic" hlthpln1 "Have Insurance") 

*Latex Output
esttab Expansion2013 Expansion2015 Nonexpansion2013 Nonexpansion2015 using "FinalTableI1.tex", replace ///
title("Table I1, Descriptive statistics of low-income, non-elderly adults sample") ///
varwidth(24) cells("b(fmt(3))") noobs nostar alignment(D{.}{.}{-1}) ///
mtitles("2010 - 2013" "2014 - 2015" "2010 - 2013" "2014 - 2015") ///
collabels(none) ///
refcat(age \textbf{"Panel 1: Demographics"} white "Race" insure \textbf{"Panel 2: Insurance"}, nolabel) ///
mgroups("Expansion States" "Non-Expansion States", pattern(1 0 1 0) span) ///
coeflabels(age "Age" income "Household Income" education "Years schooling" sex "Female" marital "Married" unemployed "Unemployed" white "White" black "Black" americanindian "Native American" asian "Asian" pacific "Pacific Islander" other "Other" multiracial "Multiracial" hispanic "Hispanic" hlthpln1 "Have Insurance") 



