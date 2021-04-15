/*
Jared Wright, Jess Rees, Marissa Mcrae
jaredwright217@gmail.com
24 March 2021
*/

clear all
set more off

global dir = "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project"
cd "$dir"

import delimited "Multiple Cause of Death, 1999-2019 drug_alcohol_induced.txt", delimiters(tab) clear
drop notes yearcode
drop if missing(year)
drop cruderate
gen cruderate_dai = deaths/population
labmask statecode, values(state) //note: if stata does not recognize "labmask", type "search labutil" in the command line and download the user generated package. This command labels statecode with the state strings
drop state mcddrugalcoholinduced population deaths
reshape wide cruderate_dai, i(year statecode) j(mcddrugalcoholinducedcode) string
save temp, replace

import delimited "Underlying Cause of Death, 1999-2019 suicide.txt", delimiters(tab) clear
drop notes yearcode
labmask statecode, values(state)
drop if missing(year)
drop cruderate
gen cruderate_suicide = deaths/population
drop state deaths population
merge 1:1 year statecode using temp, nogenerate
save temp, replace

import delimited "Bridged-Race Population Estimates 1990-2019.txt", delimiters(tab) clear
drop notes yearlyjuly1stestimatescode
rename yearlyjuly1stestimates year
rename population popgroup
drop if missing(year)
save temp2, replace
import delimited "Bridged-Race Population Estimates 1990-2019 total.txt", delimiters(tab) clear
drop notes yearlyjuly1stestimatescode
rename yearlyjuly1stestimates year
drop if year < 1999
drop if missing(year)
merge 1:m year state using temp2, nogenerate
labmask statecode, values(state)
drop state
gen prc_age_ = popgroup / population
drop population popgroup agegroup
replace agegroupcode = subinstr(agegroupcode, "-", "_", .)
replace agegroupcode = subinstr(agegroupcode, "+", "", .)
reshape wide prc_age_, i(year statecode) j(agegroupcode) string
merge 1:1 year statecode using temp, nogenerate
save temp, replace

import delimited "Multiple Cause of Death, 1999-2019 opioid breakdown.txt", delimiters(tab) clear
drop notes yearcode
drop if missing(year)
drop cruderate
gen cruderate_op = deaths/population
labmask statecode, values(state) //note: if stata does not recognize "labmask", type "search labutil" in the command line and download the user generated package. This command labels statecode with the state strings
replace multiplecauseofdeath = "othr_opioid" if multiplecauseofdeath=="Other opioids"
replace multiplecauseofdeath = "othr_synth_narc" if multiplecauseofdeath=="Other synthetic narcotics"
replace multiplecauseofdeath = "othr_uspec_narc" if multiplecauseofdeath=="Other and unspecified narcotics"
replace multiplecauseofdeath = "weed" if multiplecauseofdeath=="Cannabis (derivatives)"
replace multiplecauseofdeath = lower(multiplecauseofdeath)
//replace multiplecauseofdeath = multiplecauseofdeath + "_" + multiplecauseofdeathcode
replace multiplecauseofdeath = subinstr(multiplecauseofdeath, " ", "", .)
drop state multiplecauseofdeathcode population deaths
reshape wide cruderate_op, i(year statecode) j(multiplecauseofdeath) string
merge 1:1 year statecode using temp, nogenerate
decode statecode, gen(state)
save temp, replace

// import dellimited jess' file
import delimited "488 controls.csv", varnames(1) clear
drop v5
rename ïyear year
merge 1:1 year state using temp, nogenerate
save temp, replace

import delimited "Multiple Cause of Death, 1999-2019.txt", delimiters(tab) clear
drop notes yearcode
drop if missing(year)
labmask statecode, values(state)
drop cruderate ageadjustedrate
gen cruderate_od = deaths/population
rename deaths deaths_od
merge 1:1 year statecode using temp, nogen keep(1 3)

rename statecode statefip
cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\controls_usa_ipums_acs"
merge 1:1 year statefip using "usa_collapsed", nogen keep(1 3)
rename statefip statecode


cd "${dir}\state_demographics"
merge m:1 statecode year using "demographics", nogenerate

drop if strpos(state, "District of Columbia") > 0 //D.C. is not a state
drop if strpos(state, "Washington") > 0 //law took effect 2014
drop if strpos(state, "Alaska") > 0 //law took effect 2015
drop if strpos(state, "Oregon") > 0 //law took effect 2015
drop if strpos(state, "Massachusetts") > 0 //law took effect 2016
drop if strpos(state, "Nevada") > 0 //law took effect 2017
//drop if strpos(state, "California") > 0 //law took effect 2018. Vermont as well.
//drop if strpos(state, "Illinois") > 0 //law took effect 2019. So did Michigan
// Maybe drop 2018 and 2019??

* Drop states with missing values (generally small states). What are the potential issues with this?
gen count1 = 1
bys statecode: egen nyears = sum(count1)
drop if nyears < 21
drop count1 nyears

sort statecode year

* k but now we're going to standardize populations and create percentages
tsset statecode year
foreach var of varlist cr_* {
	di "`var'"
	if "`var'" != "cr_total_population" & "`var'" != "cr_median_age__years_" {
		local tmpname = subinstr("`var'", "cr_", "", 1)
		local tmpname = "pr_" + "`tmpname'"
		gen `tmpname' = `var' / cr_total_population
	}
}
drop pr_male pr_female cr_*
cd "$dir"
save full_data, replace

