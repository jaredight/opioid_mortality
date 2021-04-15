
clear all
set more off
global dir = "C:\Users\jaredmw2\OneDrive - BYU\Desktop\488_project\state_demographics"
cd "$dir"
global years = ""
local files: dir "$dir" files "*.csv"
gen label = ""
foreach file of local files {
	if strpos("`file'", "metadata") {
		preserve
		clear all
		local year = regexm("`file'","^[a-zA-Z]+[0-9]y(20[0-9][0-9])")
		local year =  regexs(1)
		di "`year'"
		global years = "$years" + " " + "`year'"
		di _newline(2) "`year'" _newline "`file'"
		
		import delimited `file', clear
		drop if strpos(v1, "M") > 0
		drop if strpos(v1, "PE") > 0
		rename (v1 v2) (var`year' label)

		recast str999 label, force
		compress
		gen l_label = lower(label)
		drop label
		rename l_label label
		quietly replace label = subinstr(label, "total population!!", "", .)
		quietly replace label = subinstr(label, "estimate!!", "", .)


		replace label = "under 5 years" if strpos(label, "under 5 years")
		replace label = "5 to 9 years" if strpos(label, "5 to 9")
		replace label = "10 to 14 years" if strpos(label, "10 to 14")
		replace label = "15 to 19 years" if strpos(label, "15 to 19")
		replace label = "20 to 24 years" if strpos(label, "20 to 24")
		replace label = "25 to 34 years" if strpos(label, "25 to 34")
		replace label = "35 to 44 years" if strpos(label, "35 to 44")
		replace label = "45 to 54 years" if strpos(label, "45 to 54")
		replace label = "55 to 59 years" if strpos(label, "55 to 59")
		replace label = "60 to 64 years" if strpos(label, "60 to 64")
		replace label = "65 to 74 years" if strpos(label, "65 to 74")
		replace label = "75 to 84 years" if strpos(label, "75 to 84")
		//replace label = "65 to 74 years" if strpos(label, "65 to 74")
		//replace label = "65 years and over" if strpos(label, "65 years and over")
		
		sort label var`year'
		save "temp", replace
		restore

		merge m:m label using temp, nogen
		sort label var`year'
}
}

save "var_name_crosswalk", replace

foreach var of varlist * {
	drop if missing(`var')
}

gen category1 = substr(label, 1, strpos(label, "!!") - 1)
replace label = subinstr(label, category1 + "!!", "", .)
gen category2 = substr(label, 1, strpos(label, "!!") - 1)
replace label = subinstr(label, category2 + "!!", "", .)
gen category3 = substr(label, 1, strpos(label, "!!") - 1)
replace label = subinstr(label, category3 + "!!", "", .)

sort label var2010
drop if label[_n] == label[_n-1]
sort var2010

drop if category2 != ""
drop category*
compress
save "var_name_crosswalk", replace

erase temp.dta

