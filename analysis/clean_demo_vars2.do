/*
Jared Wright
jaredwright217@gmail.com
25 March 2021
*/

clear all
set more off
global dir = "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\state_demographics"
cd "$directory"
quietly do "create_var_crosswalk.do"
clear all
global years = ""
local files: dir "$directory" files "*.csv"
foreach file of local files {
	if strpos("`file'", "data_with_overlays") {
		preserve
		clear all
		local year = regexm("`file'","^[a-zA-Z]+[0-9]y(20[0-9][0-9])")
		local year =  regexs(1)
		global years = "$years" + " " + "`year'"
		di _newline(2) "`year'" _newline "`file'"
		quietly {
		import delimited `file', clear varnames(1)

		drop in 1
		gen statecode = regexs(1) if regexm(geo_id,"US([0-9][0-9])$")
		foreach var of varlist * {
			quietly destring `var', replace
		}
		
		
		labmask statecode, values(name) //note: if stata does not recognize "labmask", type "search labutil" in the command line and download the user generated package.
		gen year = `year'
		order statecode year

		//drop all string variables (variables with missing values were kept as strings)
		//if you DONT want to drop vars with missing data, add the 'force' option in the destring line above, and then comment out the following two lines
		ds, has(type string)
		drop `r(varlist)'
		save "`year'_demographics", replace	

		* this section merges in variable name crosswalks and renames variables properly
		use "var_name_crosswalk", clear
		keep label var`year'
		gen n = 1
		reshape wide label, i(n) j(var`year') string
		drop n
		rename label* *
		foreach var of varlist * {
			quietly label variable `var' "`=`var'[1]'"
			quietly replace `var'="1" if _n==1
			quietly destring `var', replace
		}
		drop GEO_ID
		rename *, lower

		append using "`year'_demographics"

		foreach var of varlist * {
			if missing(`=`var'[1]') & "`var'"!="statecode" & "`var'"!="year"{
				drop `var'
			}
		}
		drop in 1
		order statecode year

		label variable statecode "statecode"
		label variable year "year"

		foreach v of var * {
			local lbl : var label `v'
			if "`v'"!="statecode" & "`v'"!="year" {
				local lbl = "cr_" + "`lbl'"
			}
			local lbl = strtoname("`lbl'")
			rename `v' `lbl'
		}
		
		save "`year'_demographics_clean", replace	
		restore
		append using "`year'_demographics_clean"
		}
	}
}
save "demographics", replace







