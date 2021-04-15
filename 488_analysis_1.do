/*
Jared Wright, Jess Rees, Marissa Mcrae
jaredwright217@gmail.com
12 April 2021
The file merge_data.do merges all our control data and makes the file "full_data.dta".
This file uses the "full_data file and creates the synthetic controls"
*/


ssc install synth, replace all
clear all
set more off

global dir = "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project"
cd "$dir"
use full_data, clear
tsset statecode year

* state democraphics (populations) from the American Community Survey
global cr_controls cr_total_population cr_under_5_years cr_5_to_9_years cr_10_to_14_years cr_15_to_19_years cr_20_to_24_years cr_25_to_34_years cr_35_to_44_years cr_45_to_54_years cr_55_to_59_years cr_60_to_64_years cr_65_to_74_years cr_75_to_84_years cr_85_years_and_over cr_median_age__years_ cr_18_years_and_over cr_21_years_and_over cr_62_years_and_over cr_65_years_and_over cr_one_race cr_two_or_more_races cr_one_white cr_one_black_or_african_american cr_one_american_indian_and_alask cr_one_asian cr_one_native_hawaiian_and_other cr_one_some_other_race cr_hispanic_or_latino__of_any_ra cr_not_hispanic_or_latino cr_total_housing_units

* rates from the American community survey
global pr_controls pr_under_5_years pr_5_to_9_years pr_10_to_14_years pr_15_to_19_years pr_20_to_24_years pr_25_to_34_years pr_35_to_44_years pr_45_to_54_years pr_55_to_59_years pr_60_to_64_years pr_65_to_74_years pr_75_to_84_years pr_85_years_and_over pr_18_years_and_over pr_21_years_and_over pr_62_years_and_over pr_65_years_and_over pr_one_race pr_two_or_more_races pr_one_white pr_one_black_or_african_american pr_one_american_indian_and_alask pr_one_asian pr_one_native_hawaiian_and_other pr_one_some_other_race pr_hispanic_or_latino__of_any_ra pr_not_hispanic_or_latino pr_total_housing_units

* rates from IPUMS. American Community Survey
global cz_controls cz_sex cz_mar1 cz_mar2 cz_mar3 cz_mar4 cz_mar5 cz_mar6 cz_race1 cz_race2 cz_race3 cz_race4 cz_race5 cz_race6 cz_race7 cz_race8 cz_race9 cz_educ1 cz_educ2 cz_educ3 cz_educ4 cz_educ5 cz_educ6 cz_educ7 cz_educ8 cz_educ9 cz_educ10 cz_educ11 cz_lninc cz_ftotinc

*death rates from CDC WONDER database
global cruderate_controls cruderate_opcocaine cruderate_opheroin cruderate_opmethadone cruderate_opothr_opioid cruderate_opothr_synth_narc cruderate_opothr_uspec_narc cruderate_opweed

* age groups from CDC WONDER Bridged-Race Resident Population Estimates United States, State and County for the years 1990 - 2019
global age_controls prc_age_1 prc_age_10_14 prc_age_15_19 prc_age_1_4 prc_age_20_24 prc_age_25_29 prc_age_30_34 prc_age_35_39 prc_age_40_44 prc_age_45_49 prc_age_50_54 prc_age_55_59 prc_age_5_9 prc_age_60_64 prc_age_65_69 prc_age_70_74 prc_age_75_79 prc_age_80_84 prc_age_85

gen prc_age_20_34 = prc_age_20_24 + prc_age_25_29 + prc_age_30_34


* SPEC 1: includes democraphic controls for sex, marital status, race, education, average total household income, ln average total household income, age buckets, housing units per capita
global treatyear1 2008 
global treatyear2 2013
log using "synth_log", replace
synth cruderate_od $cz_controls $age_controls pr_total_housing_units cruderate_od, trunit(8) trperiod(2013) xperiod(${treatyear1} ${treatyear2}) mspeperiod(1999/2013) fig keep(synth_colorado, replace)
log close

use synth_colorado, clear
rename _time year
gen tr_effect = (_Y_synthetic - _Y_treated) / _Y_synthetic

cd "$dir"
use full_data, clear
tsset statecode year

levelsof statecode, local(states)
global states `states'
cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\synthetic_controls"
foreach state in $states {
	di "`state'"
	synth cruderate_od $cz_controls $age_controls cruderate_od, trunit(`state') trperiod(2013) xperiod(${treatyears}) mspeperiod(${treatyears}) keep(synth_`state', replace)
}
foreach state in $states {
	di "`state'"
	use synth_`state', clear
	rename _time years
	gen tr_effect_`state' = _Y_treated - _Y_synthetic
	keep years tr_effect_`state'
	drop if missing(years)
	save synth_`state', replace
}

cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\synthetic_controls"
clear all
gen years = 0
foreach state in $states {
	quietly merge 1:1 years using synth_`state', nogenerate
}
drop if year == ${treatyear1} | year == ${treatyear2}
gen pretreat = (year < 2013)
local lp
foreach state in $states {
    local lp `lp' line tr_effect_`state' years, lwidth(vthin) lcolor(gs12) ||
	gen tmp = (tr_effect_`state')^2
	bys pretreat: egen mspe_`state' = mean(tmp)
	drop tmp
}
di "`lp'"
* create plot
cd "$dir"
sort year
twoway `lp' || line tr_effect_8 years, lcolor(red) lwidth(medthick) ytitle("Difference between Control and Synthetic") xtitle(year) xline(2013, lpattern(dash)) saving("placebo_tests", replace) legend(order(39 "Control States" 42 "Colorado")) title("Figure 3. Opioid Overdose Death Rates Placebo Test")
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Opioid Overdose Death Rates Placebo Test -spec 1.png", replace


preserve
keep if year==2001
local low_mspe
foreach state in $states {
    if mspe_`state' > 5 * mspe_8 {
		drop tr_effect_`state'
	}
	else {
		local low_mspe `low_mspe' `state'
	}
}
restore
local lp
foreach state in `low_mspe' {
    local lp `lp' line tr_effect_`state' years, lwidth(vthin) lcolor(gs12) ||
}
di "`lp'"
* create plot
cd "$dir"
sort year
twoway `lp' || line tr_effect_8 years, lcolor(red) lwidth(medthick) ytitle("Difference between Control and Synthetic") xtitle("Year") xline(2013, lpattern(dash)) saving("placebo_tests", replace) legend(order(3 "Control States" 17 "Colorado")) title("Figure 4. Placebo Test for 16 Control States")
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Opioid Overdose Death Rates Placebo Test -spec 2.png", replace

keep mspe* year
keep if year==2001 | year==2019
tostring year, force replace
replace year = "pre" if year=="2001"
replace year = "post" if year=="2019"
reshape long mspe_ , i(year) j(statecode)
preserve
drop if year=="post"
rename year pre
rename mspe_ pre_mspe
save temp, replace
restore
drop if year=="pre"
rename year post
rename mspe_ post_mspe
merge 1:1 statecode using temp, nogen keep(1 2 3)
gen post_pre_mspe = post_mspe / pre_mspe

twoway (histogram post_pre_mspe, width(1) frequency title("Figure 5. Frequencies of Post/Pre- Legalization MSPE") ytitle("Frequency") xtitle("Post/Pre MSPE") color(gs12) legend(off)) (pcarrowi 3 60 1.2 65 (9) "Colorado" legend(off))
gr_edit .plotregion1.plot1.EditCustomStyle , j(19) style(area(shadestyle(color(red))))
cd "$dir"
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Frequencies of PostPre Legalization MSPE.png", replace

use full_data, clear
tsset statecode year



* ROBUSTNESS CHECK: DROP STATES WITHOUT MEDICAL MARIJUANA ****************************************

keep if med_legal
gen tokeep = 0
replace tokeep = 1 if year == ${treatyear1} | year == ${treatyear2}
by statecode, sort: egen tokeep2 = sum(tokeep)
keep if tokeep2 > 1
synth cruderate_od $cz_controls $age_controls pr_total_housing_units cruderate_od, trunit(8) trperiod(2013) xperiod(${treatyear1} ${treatyear2}) mspeperiod(${treatyear1} ${treatyear2}) fig resultsperiod(${treatyear1}/2019)

levelsof statecode, local(states)
global states `states'
cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\synthetic_controls"
foreach state in $states {
	di "`state'"
	synth cruderate_od $cz_controls $age_controls cruderate_od, trunit(`state') trperiod(2013) xperiod(${treatyears}) mspeperiod(${treatyears}) keep(synth_`state', replace) resultsperiod(${treatyear1}/2019)
}
foreach state in $states {
	di "`state'"
	use synth_`state', clear
	rename _time years
	gen tr_effect_`state' = _Y_treated - _Y_synthetic
	keep years tr_effect_`state'
	drop if missing(years)
	save synth_`state', replace
}

cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\synthetic_controls"
clear all
gen years = 0
foreach state in $states {
	quietly merge 1:1 years using synth_`state', nogenerate
}
drop if year == ${treatyear1} | year == ${treatyear2}
gen pretreat = (year < 2013)
local lp
foreach state in $states {
    local lp `lp' line tr_effect_`state' years, lwidth(vthin) lcolor(gs12) ||
	gen tmp = (tr_effect_`state')^2
	bys pretreat: egen mspe_`state' = mean(tmp)
	drop tmp
}
di "`lp'"
* create plot
cd "$dir"
sort year
twoway `lp' || line tr_effect_8 years, lcolor(red) lwidth(medthick) ytitle("Difference between Control and Synthetic") xtitle("Year") xline(2013, lpattern(dash)) saving("placebo_tests", replace) legend(order(8 "Control States" 9 "Colorado")) title("Figure 7. Placebo Test for 7 Control States") subtitle("Medical Marijuana Only")
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Opioid Overdose Death Rates Placebo Test -med robust.png", replace











cd "$dir"
use full_data, clear
global sumstats prc_age_20_24 prc_age_25_29 cz_sex cz_ftotinc cz_mar1 cz_mar2 cz_race1 cz_educ6 cz_educ7 cz_educ8 cz_educ9 cz_educ10 cz_educ11 cz_lninc
foreach v of global sumstats {
	gen s_`v' = 1
	replace s_`v' = 0 if missing(`v')
}
drop if year > 2013
keep if year==2008 | year==2013
collapse (mean) $sumstats



* SPEC 2: includes democraphic controls for average total family income, percent of population that is married/divorced/single, race, ethnicity, education, mean natural log of income. 
cd "$dir"
use full_data, clear
tsset statecode year
synth cruderate_od $cz_controls cruderate_od, trunit(8) trperiod(2013) xperiod(2003 2008) mspeperiod(2003 2008) fig

levelsof statecode, local(states)
global states `states'
cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\synthetic_controls"
foreach state in $states {
	di "`state'"
	synth cruderate_od $cz_controls cruderate_od, trunit(`state') trperiod(2013) xperiod(2003 2008) mspeperiod(2003 2008) keep(synth_`state', replace)
}
foreach state in $states {
	di "`state'"
	use synth_`state', clear
	rename _time years
	gen tr_effect_`state' = _Y_treated - _Y_synthetic
	keep years tr_effect_`state'
	drop if missing(years)
	save synth_`state', replace
}
clear all
gen years = 0
foreach state in $states {
	quietly merge 1:1 years using synth_`state', nogenerate
}
local lp
foreach state in $states {
   local lp `lp' line tr_effect_`state' years, lwidth(vthin) lcolor(gs12) ||
}
di "`lp'"
* create plot
cd "$dir"
twoway `lp' || line tr_effect_8 years, lcolor(red) lwidth(medthick) ytitle("Difference between Control and Synthetic") xtitle(year) xline(2013, lpattern(dash)) saving("placebo_tests", replace) legend(order(39 "Control States" 42 "Colorado")) title("Figure 3. Opioid Overdose Death Rates Placebo Test")
gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\Opioid Overdose Death Rates Placebo Test -spec 2.png", replace




synth cruderate_od $cz_controls cruderate_od, trunit(8) trperiod(2013) xperiod(2008 2012) mspeperiod(2008 2012) fig










* i like these. is it overfitting?
synth cruderate_od $pr_controls $cz_controls cruderate_od, trunit(8) trperiod(2013) xperiod(2010 2013) mspeperiod(2008 2013) fig

synth cruderate_od $pr_controls $cz_controls cruderate_od, trunit(8) trperiod(2013) xperiod(2010 2013) fig

synth cruderate_od population $pr_controls $cz_controls cruderate_od, trunit(8) trperiod(2013) xperiod(2010 2013) mspeperiod(2010 2013) fig



// spec 1: all controls, 2010 and 2013
quietly synth cruderate_od $controls cruderate_od, trunit(8) trperiod(2013) xperiod(2010/2013)  fig

// spec 2: less demographics and age ranges 15-44
synth cruderate_od cr_total_population cr_15_to_19_years cr_20_to_24_years cr_25_to_34_years cr_35_to_44_years cr_18_years_and_over cr_65_years_and_over cr_one_white cr_one_black_or_african_american cr_one_asian cr_hispanic_or_latino__of_any_ra cr_total_housing_units cruderate_od(2010) cruderate_od(2013), trunit(8) trperiod(2013) xperiod(2010/2013) fig


// spec 2 placebo tests
// see https://www.statalist.org/forums/forum/general-stata-discussion/general/1303878-placebo-tests-for-synthetic-control-method for details on this next part 
cd "$dir"
use full_data, clear
tsset statecode year
cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\synthetic_controls"

levelsof statecode, local(states)
global states `states'
foreach state in $states {
	di "`state'"
	synth cruderate_od $pr_controls $cz_controls cruderate_od, trunit(`state') trperiod(2013) xperiod(2010 2013) keep(synth_`state', replace)

	//synth cruderate_od cr_total_population cr_15_to_19_years cr_20_to_24_years cr_25_to_34_years cr_35_to_44_years cr_18_years_and_over cr_65_years_and_over cr_one_white cr_one_black_or_african_american cr_one_asian cr_hispanic_or_latino__of_any_ra cr_total_housing_units cruderate_od(2010) cruderate_od(2013), trunit(8) trperiod(2013) xperiod(2010/2013) keep(synth_`state', replace)

}

foreach state in $states {
	di "`state'"
	use synth_`state', clear
	rename _time years
	gen tr_effect_`state' = _Y_treated - _Y_synthetic
	keep years tr_effect_`state'
	drop if missing(years)
	save synth_`state', replace
}

clear all
gen years = 0
foreach state in $states {
	quietly merge 1:1 years using synth_`state', nogenerate
}

local lp
foreach state in $states {
   local lp `lp' line tr_effect_`state' years, lcolor(gs12) ||
}
di "`lp'"
* create plot
twoway `lp' || line tr_effect_8 years, lcolor(orange) ytitle("overdose death rate") xline(2013, lpattern(dash)) saving("placebo_tests", replace) legend(order(39 "control states" 42 "Colorado")) title("Opioid Overdose Death Rates Placebo Test")


label list statecode






// spec 4: all controls, 2010 and 2013
synth cruderate_od $pr_controls cruderate_od(2010) cruderate_od(2013), trunit(8) trperiod(2013) xperiod(2010/2013)  fig

// spec 5: fewer controls
synth cruderate_suicide cr_total_population pr_15_to_19_years pr_20_to_24_years pr_25_to_34_years pr_35_to_44_years  pr_18_years_and_over pr_65_years_and_over pr_one_white pr_one_black_or_african_american pr_one_asian pr_hispanic_or_latino__of_any_ra pr_total_housing_units cruderate_od(2010) cruderate_od(2013), trunit(8) trperiod(2013) xperiod(2010/2013) fig

synth cruderate_suicide cr_total_population pr_18_years_and_over pr_one_white cruderate_od cruderate_suicide, trunit(8) trperiod(2013) xperiod(2010/2013) fig


synth cruderate cr_total_population(2010) pr_15_to_19_years(2010) pr_20_to_24_years(2010) pr_25_to_34_years(2010) pr_35_to_44_years(2010)  pr_18_years_and_over(2010) pr_65_years_and_over(2010) pr_one_white(2010) pr_one_black_or_african_american(2010) pr_one_asian(2010) pr_hispanic_or_latino__of_any_ra(2010) pr_total_housing_units(2010) cruderate(2010) cruderate(2013), trunit(8) trperiod(2013) xperiod(2010/2013) fig

synth cruderate cr_total_population(2010) pr_15_to_19_years(2010) pr_20_to_24_years(2010) pr_25_to_34_years(2010) pr_35_to_44_years(2010)  pr_18_years_and_over(2010) pr_65_years_and_over(2010) pr_one_white(2010) pr_one_black_or_african_american(2010) pr_one_asian(2010) pr_hispanic_or_latino__of_any_ra(2010) pr_total_housing_units(2010) cruderate(2010) cr_total_population(2013) pr_15_to_19_years(2013) pr_20_to_24_years(2013) pr_25_to_34_years(2013) pr_35_to_44_years(2013) pr_18_years_and_over(2013) pr_65_years_and_over(2013) pr_one_white(2013) pr_one_black_or_african_american(2013) pr_one_asian(2013) pr_hispanic_or_latino__of_any_ra(2013) pr_total_housing_units(2013) cruderate(2013), trunit(8) trperiod(2013) xperiod(2010/2013) fig


synth cruderate cr_total_population cr_15_to_19_years cr_20_to_24_years cr_25_to_34_years cr_35_to_44_years cr_18_years_and_over cr_65_years_and_over cr_one_white cr_one_black_or_african_american cr_one_asian cr_hispanic_or_latino__of_any_ra cr_total_housing_units cruderate(2010) cruderate(2013), trunit(8) trperiod(2013) xperiod(2010/2013) fig



synth cruderate_od cruderate_suicide pr_15_to_19_years pr_20_to_24_years pr_25_to_34_years pr_one_white pr_hispanic_or_latino__of_any_ra cruderate_od cruderate_suicide, trunit(8) trperiod(2013) xperiod(2010 2013)  fig

synth cruderate_od cruderate_suicide $pr_controls cruderate_od cruderate_suicide, trunit(8) trperiod(2013) xperiod(2010 2013) fig



// see https://www.statalist.org/forums/forum/general-stata-discussion/general/1303878-placebo-tests-for-synthetic-control-method for details on this next part 
cd "$dir"
//use full_data, clear
tsset statecode year
cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\synthetic_controls"

levelsof statecode, local(states)
global states `states'
foreach state in $states {
	di "`state'"
	synth cruderate_od $pr_controls $cz_controls cruderate_od, trunit(`state') trperiod(2013) xperiod(2010 2013) keep(synth_`state', replace)

}

foreach state in $states {
	di "`state'"
	use synth_`state', clear
	rename _time years
	gen tr_effect_`state' = _Y_treated - _Y_synthetic
	keep years tr_effect_`state'
	drop if missing(years)
	save synth_`state', replace
}

clear all
gen years = 0
foreach state in $states {
	quietly merge 1:1 years using synth_`state', nogenerate
}

local lp
foreach state in $states {
	//di "`lp'"
   local lp `lp' line tr_effect_`state' years, lcolor(gs12) ||
}
* create plot
twoway `lp' || line tr_effect_8 years, ///
lcolor(orange) legend(off) xline(2013, lpattern(dash))


//
use nameyoulike.dta, clear
gen effect= _Y_treated - _Y_synthetic
gen e2= effect^2
sum e2 if _time==8 | _time==9





cd "$dir"
use full_data, clear
tsset statecode year
cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\synthetic_controls"

levelsof statecode, local(states)
global states `states'
foreach state in $states {
	di "`state'"
	synth cruderate_od $pr_controls $cz_controls cruderate_od, trunit(`state') trperiod(2013) xperiod(2010 2013) keep(synth_`state', replace)

}

clear all
gen state = 0
foreach state in $states {
	di "`state'"
	append using synth_`state'
	replace state = `state' if missing(state)
}
rename _time years
gen tr_effect = _Y_treated - _Y_synthetic
keep years tr_effect state
drop if missing(years)

cd "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\4public"
do "group_lines.ado"

group_lines y x group lcolor lpattern lwdith globalname subsetvar subsetvar_value
gen num = 1

group_lines tr_effect years state navy%40 solid vthin myplot num 1
group_lines tr_effect years state green solid medthick myplot_8 state 8

tw $myplot $myplot_8 , xtitle("years") ytitle("difference in overdose rates") title("Placebo Tests for Synthetic Control") xline(2013, lpattern(dash)) graphregion(color(white)) legend(order(39 "control states" 46 "Colorado"))

gr export "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\placebo_test.png", replace	


