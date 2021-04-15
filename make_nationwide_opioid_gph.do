/*
Jared Wright, Jess Rees, Marissa Mcrae
jaredwright217@gmail.com
24 March 2021
*/

* DEATH RATES BY STATE FOR OPIOIDS
clear all
set more off

global dir = "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project"
cd "$dir"

import delimited "Multiple Cause of Death, 1999-2019.txt", delimiters(tab) clear
drop notes yearcode
drop if missing(year)
drop cruderate ageadjustedrate
gen cruderate = deaths/population


drop state
reshape wide cruderate deaths population, i(year) j(statecode)


global lp
foreach state of var cruderate* {
	if "`state'" != "cruderate8" {
		di "`state'"
		//twoway line cruderate year, legend(off) ytitle("opioid od death rate") xline(2013, lpattern(dash))
		global lp $lp line `state' year, lcolor(gs12) lwidth(vthin) ||
	}
}

//twoway line `state' year, legend(off) ytitle("opioid od death rate") xline(2013, lpattern(dash))
global lp $lp line cruderate8 year, lcolor(red) lwidth(medthick) ||


cd "$dir"

preserve
import delimited "Multiple Cause of Death, 1999-2019 opioid nationwide.txt", delimiters(tab) clear
drop notes yearcode
drop if missing(year)
drop cruderate
gen cruderate = deaths/population
save temp, replace
restore
merge 1:1 year using temp, nogen

global lp $lp line cruderate year, lcolor(orange) lwidth(medthick) legend(on) ||

twoway $lp, ytitle("Death Rate") xtitle("Year") xline(2013, lpattern(dash)) saving("cruderate_by_state", replace) legend(order(50 "Control states" 51 "Colorado" 52 "Nationwide Average")) title("Figure 1. Opioid Overdose Death Rates by State")
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Opioid Overdose Death Rates by State.png", replace	




* DEATH RATES BY STATE FOR ALCOHOL, DRUG, AND OTHER DEATHS
clear all
set more off

global dir = "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project"
cd "$dir"

import delimited "Multiple Cause of Death, 1999-2019 drug_alcohol_induced.txt", delimiters(tab) clear
drop notes yearcode
drop if missing(year)
drop cruderate mcddrugalcoholinduced
gen cruderate = deaths/population


drop state
tostring statecode, replace
reshape wide cruderate deaths population, i(year statecode) j(mcddrugalcoholinducedcode) string


global lp
foreach state of var cruderate* {
	if "`state'" != "cruderate8" {
		di "`state'"
		//twoway line cruderate year, legend(off) ytitle("opioid od death rate") xline(2013, lpattern(dash))
		global lp $lp line `state' year, lcolor(gs12) ||
	}
}

//twoway line `state' year, legend(off) ytitle("opioid od death rate") xline(2013, lpattern(dash))
global lp $lp line cruderate8 year, lcolor(red) ||


cd "$dir"

preserve
import delimited "Multiple Cause of Death, 1999-2019 drug_alcohol_induced_nationwide.txt", delimiters(tab) clear
drop notes yearcode
drop if missing(year)
drop cruderate mcddrugalcoholinduced
gen cruderate = deaths/population
reshape wide cruderate deaths population, i(year) j(mcddrugalcoholinducedcode) string
gen statecode = "0"
save temp, replace
restore
merge 1:1 year statecode using temp, nogen

global lp $lp line cruderate year, lcolor(orange) legend(on) ||


cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\4public"
quietly do "group_lines.ado"
cd "$dir"

gen num = 1
destring statecode, force replace

group_lines cruderateA year statecode gs12 solid vthin myplot num 1
group_lines cruderateA year statecode red solid medthick myplot_8 state 8
group_lines cruderateA year statecode orange solid medthick myplot_0 state 0
tw $myplot $myplot_8 $myplot_0, xtitle("Year") ytitle("Death Rate") title("Alcohol Induced Death Rates by State") xline(2013, lpattern(dash)) legend(order(39 "Control States" 59 "Colorado" 105 "Nationwide Average"))
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Alcohol Induced Death Rates by State.png", replace	

group_lines cruderateD year statecode gs12 solid vthin myplot num 1
group_lines cruderateD year statecode red solid medthick myplot_8 state 8
group_lines cruderateD year statecode orange solid medthick myplot_0 state 0
tw $myplot $myplot_8 $myplot_0, xtitle("Year") ytitle("Death Rate") title("Drug Induced Death Rates by State") xline(2013, lpattern(dash)) legend(order(39 "Control States" 59 "Colorado" 105 "Nationwide Average"))
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Drug Induced Death Rates by State.png", replace	

group_lines cruderateO year statecode gs12 solid vthin myplot num 1
group_lines cruderateO year statecode red solid medthick myplot_8 state 8
group_lines cruderateO year statecode orange solid medthick myplot_0 state 0
tw $myplot $myplot_8 $myplot_0, xtitle("Year") ytitle("Death Rate") title("Non-Drug/Alcohol Induced Death Rates by State") xline(2013, lpattern(dash)) legend(order(39 "Control States" 59 "Colorado" 105 "Nationwide Average"))
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Non-Drug Alcohol Induced Death Rates by State.png", replace	


