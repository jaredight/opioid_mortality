/*
Jared Wright, Jess Rees, Marissa Mcrae
jaredwright217@gmail.com
6 April 2021
*/

clear all
set more off
global dir = "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\controls_usa_ipums_acs"
cd "$dir"
do "usa_00001.do"

replace sex = sex - 1
rename sex cz_sex
tab marst, gen(cz_mar)
tab race, gen(cz_race)
tab educ, gen(cz_educ)
rename ftotinc cz_ftotinc
gen cz_lninc = ln(cz_ftotinc)

global controls
di "$controls"
foreach v of varlist cz_* {
	global controls $controls (mean) `v'
}
di "$controls"


preserve
collapse (mean) cz_* pweights=perwt, by(year statefip)
cd "$dir"
save "usa_collapsed", replace
restore

cd "$dir"
use "usa_collapsed", clear
