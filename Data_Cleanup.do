***Importing and inspecting data for project

cls

capture cd "~/Desktop/Akpene/Masters Work/Non-linear econometrics/Project/Data"
log using ../Analysis/Cleanup, replace

**Creating datasets for each year:

*2010
import sasxport5 CDBRFS10.XPT, clear
describe
summarize 
keep _state cellfon fmonth imonth iyear dispcode numadult hlthplan age hispanc2 mrace _prace _mrace race2 orace2 marital children educa employ income2 sex _raw _wt2 _poststr _finalwt _rawhh _wt2hh _posthh _housewt _ststr _psu nummen numwomen //keeping relevant variables
tempfile Edited_2010
save `Edited_2010'

*2011
import sasxport5 LLCP2011.XPT, clear
describe
keep _state cellfon fmonth imonth iyear dispcode numadult hlthpln1 age hispanc2 mrace _prace _mrace race2 orace2 marital children educa employ income2 sex _raw _wt2 _llcpwt _ststr _psu nummen numwomen 
*recoding BRFSS final weight for consistency:
replace _llcpwt = _llcpwt/sum(_llcpwt)
tempfile Edited_2011
save `Edited_2011'


*2012
import sasxport5 LLCP2012.XPT, clear
describe
keep _state cellfon fmonth imonth iyear dispcode numadult hlthpln1 age hispanc2 mrace _prace _mrace race2 orace2 marital children educa employ income2 sex _raw _wt2 _llcpwt _ststr _psu nummen numwomen 
tempfile Edited_2012
save `Edited_2012'


*2013
import sasxport5 LLCP2013.XPT, clear
describe
keep _state cellfon3 fmonth imonth iyear dispcode numadult hlthpln1 _age80 _hispanc _prace1 _mrace1 _race _imprace marital children educa employ income2 sex _raw _wt2 _llcpwt _ststr _psu nummen numwomen 
rename cellfon3 cellfon //for consistency with other years
tempfile Edited_2013
save `Edited_2013'


*2014
import sasxport5 LLCP2014.XPT, clear
describe
keep _state cellfon2 fmonth imonth iyear dispcode numadult hhadult hlthpln1 _age80 _hispanc _prace1 _mrace1 _race _imprace marital children educa employ income2 sex _raw _wt2 _llcpwt _ststr _psu nummen numwomen 
tempfile Edited_2014
save `Edited_2014'


*2015
import sasxport5 LLCP2015.XPT, clear
describe
keep _state cellfon3 fmonth imonth iyear dispcode numadult hhadult hlthpln1 _age80 _hispanc _prace1 _mrace1 _race _racegr3 marital children educa employ income2 sex _raw _wt2 _llcpwt _ststr _psu nummen numwomen
rename cellfon3 cellfon //for consistency with previous years
tempfile Edited_2015
save `Edited_2015'


clear
cls

***Appending data files:
use `Edited_2010', clear
describe
rename hlthplan hlthpln1 //renaming for consistency
drop _poststr _rawhh _wt2hh _posthh _housewt //removing variables that are not relevant to our analysis

append using `Edited_2011' //adding 2011
append using `Edited_2012' //adding 2012
append using `Edited_2013' //adding 2013
append using `Edited_2014' //adding 2014
append using `Edited_2015' //adding 2015

describe
*Grouping variables together under a common name
generate final_weight =. //BRFSS final weight
replace final_weight=_finalwt
replace final_weight=_llcpwt if final_weight==.


generate prace=. //Preferred Race
replace prace = _prace //Preferred Race
replace prace = _prace1 if prace==.

*dropping regrouped variables:
drop _finalwt _llcpwt _prace _prace1 

*changing the data format:
destring iyear, replace
destring imonth, replace

*dropping ages less than 65:
summarize age _age80
drop if age >= 65 & inrange(iyear, 2010, 2012)
drop if _age80 >= 65 & inrange(iyear, 2013, 2015)
summarize age _age80
drop if age <= 18 & inrange(iyear, 2010, 2012)
drop if _age80 <= 18 & inrange(iyear, 2013, 2015)


*grouping age under one common variable:
generate agee = .
replace agee = age if inrange(iyear, 2010, 2012)
replace agee = _age80 if inrange(iyear, 2013, 2015)

summarize agee

drop age _age80
rename agee age

*recoding variables:
drop if marital == 9 //marital status
drop if marital == .
replace marital = 0 if marital != 1 
drop if hlthpln1 > 2 //health insurance
replace hlthpln1 = 0 if hlthpln1 == 2
replace sex = 0 if sex == 1 // female
replace sex = 1 if sex == 2

*dropping income:
drop if income2 > 8
drop if income2 == .
*Ordering variables to replicate Table I1:
order _state fmonth imonth iyear dispcode cellfon numadult age income2 educa sex marital employ employ1 mrace _mrace _mrace1 prace hispanc2 _hispanc hlthpln1 final_weight children  


save ../Data/TableI1, replace
describe
summarize




list in -5/l 
log close



