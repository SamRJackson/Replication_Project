********************************************
* MASTER DO FILE ATTEMPT NUMBER 2              *      
* AUTHORS : SAM J., EMMA P. AND ALESSANDRO F.             *
* DATE : 30/01/2023
* CONTENT : REPLICATION EXERCISE M2-ETE RESEARCH METHODOLOGY *
********************************************

clear
set more off
macro drop _all


// SET GLOBAL PATH NAMES AND TREE STRUCTURE

	gl path  "/Users/samjackson/Desktop/M2 2022-2023/RepliProject" //YOUR PATH HERE//
	gl data "$path/data"
	gl dofile "$path/exec"
	gl tables "$path/output"
	
// OPEN DATA AND READ THE DICTIONARY FILE

*run "${dofile}/usa_00001.do"
use year age labforce wkswork2 incwage classwkr educd race marst empstat bpld yrimmig sex serial occ using "${data}/usa_00002.dta", clear

// COPY THE AUTHORS PRELIMINARY TRANSFORMATIONS

local yrlbl =  "year2000"

* Restrict analysis to those between 18 and 65 years old, in labor force
keep if age >= 18 & age <= 65 & labforce == 2
	
* Generate age categories
recode age (18/25=1) (26/35=2) (36/45=3) (46/55=4) (56/65=5), gen (agecat)   
label define agecat 1 "18/25" 2 "26/35" 3 "36/45" 4 "46/55" 5 "56/65" , replace
label val agecat agecat

recode age (18/40=1) (41/65=2) , gen (agecat2)  
label define agecat2 1 "18/40" 2 "41/65" , replace
label val agecat2 agecat2

	
* Define weekly wage (hourly wage is noisier)
gen weeks = 7 * (wkswork2 == 1) + 20 * (wkswork2 == 2) + 33 * (wkswork2 == 3) ///
+ 43.5 * (wkswork2 == 4) + 48.5 * (wkswork2 == 5) + 51 * (wkswork2 == 6)
gen log_week_wage = ln(incwage / weeks)
keep if classwkr == 2
drop if log_week_wage == .

* Rename wage variable
ren log_week_wage lnw


* Education: 6 categories
gen edu6 = 1 * (educd <= 50 | educd == 61) + 2 * (educd == 60 | (educd >= 62 & educd <= 64)) + 3 * (educd >= 65 & educd <= 90) ///
+ 4 * (educd == 100 | educd == 101) + 5 * (educd == 110 | educd == 111 | educd == 114) + 6 * (educd >= 112 & educd != 114)

* Education: 4 categories
gen edu4 = 1 * (educd <= 61) + 2 * (educd >= 62 & educd <= 64) + 3 * (educd >= 65 & educd <= 81)  + 4 * (educd >= 82 & educd != .)

* Education: 3 categories
gen edu3 = 1 * (educd <= 64) + 2 * (educd >= 65 & educd <= 90) + 3 * (educd >= 91 & educd != .)

* Education: 2 categories
gen edu2 = 1 * (educd <= 64) + 2 * (educd >= 65 & educd != .)
* 1 is low

* Education in years
gen schooling = 0
replace schooling = 2 if educd == 10
replace schooling = 2.5 if educd == 13
replace schooling = 1 if educd == 14
replace schooling = 2 if educd == 15
replace schooling = 3 if educd == 16
replace schooling = 4 if educd == 17
replace schooling = 6.5 if educd == 20
replace schooling = 5.5 if educd == 21
replace schooling = 5 if educd == 22
replace schooling = 6 if educd == 23
replace schooling = 7.5 if educd == 24
replace schooling = 7 if educd == 25
replace schooling = 8 if educd == 26
replace schooling = 9 if educd == 30
replace schooling = 10 if educd == 40
replace schooling = 11 if educd == 50 | educd == 61
replace schooling = 12 if educd == 60 | (educd >= 62 & educd <= 64)
replace schooling = 13 if educd >= 65 & educd <= 71
replace schooling = 14 if educd >= 80 & educd <= 90
replace schooling = 15 if educd == 90
replace schooling = 16 if educd >= 100 & educd <= 101
replace schooling = 17 if educd == 110
replace schooling = 18 if educd == 111 | educd == 114
replace schooling = 19 if educd == 112
replace schooling = 20 if educd == 113 | educd > 114

* Potential experience
gen pe = int(age - 6 - schooling)
keep if pe >= 1 & pe <= 40

* Generate experience categories
recode pe (1/5=1) (6/10=2) (11/15=3) (16/20=4) (21/25=5) (26/30=6) (31/35=7) (36/40=8), gen (expcat)  
label def expcat 1 "(1/5=1)" 2 "(6/10=2)" 3 "(11/15=3)" 4 "(16/20=4)" 5 "(21/25=5)" 6 "(26/30=6)" 7 "(31/35=7)" 8 "(36/40=8)"
label val expcat expcat

recode pe (1/20=1) (21/40=2) , gen (expcat2)   
label define expcat2 1 "1-20 yrs" 2 "21-40 yrs" , replace
label val expcat2 expcat2
 
* Demographics: whites, blacks, others
gen race3 = 1 * (race == 1) + 2 * (race == 2) + 3 * (race > 2)
gen married = (marst <= 2)

* Labor market status
gen employed = (empstat == 1) if age >= 18 & age <= 64

* Tag foreign
gen foreign = (bpld>=15000)

* Classify immigrants by time of arrival
gen immclass = .
replace immclass = 1 if foreign==1 & year-yrimmig<=2
replace immclass = 2 if foreign==1 & year-yrimmig> 2 & year-yrimmig<=5
replace immclass = 3 if foreign==1 & year-yrimmig> 5 & year-yrimmig<=10
replace immclass = 4 if foreign==1 & year-yrimmig> 10 & year-yrimmig!=.

label var immclass "time since arrival in Census data"
label def immclass 1 "0-2 years" 2 "3-5 years" 3 "6-10 years" 4 "more than 10 years"
label val immclass immclass  

* Tag natives and immigrants
gen x=1 if foreign==0
replace x=0 if foreign==1

* Actual position of natives 
sort  lnw
gen rank=sum(x)
* rank will give the ranking in the sorted data of natives
egen totwage=sum(x)
* totwage will count the number of people with x = 1
gen natbel= rank/ totwage
* natbel then is the relative rank of individuals? your rank / total number people



// FIRST BENCHMARK

* Evidence for downgrading among recent or previous immigrants? 
reg lnw  age c.age#c.age sex i.educd i.educd#c.age foreign

reg lnw  age c.age#c.age sex i.educd i.educd#c.age foreign if foreign==0 | immclass==1   // 15.5% gap
* recent immigrants most interesting
reg lnw  age c.age#c.age sex i.educd i.educd#c.age foreign if foreign==0 | immclass==2   // 12.5% gap
reg lnw  age c.age#c.age sex i.educd i.educd#c.age foreign if foreign==0 | immclass==3   // 8.6% gap
reg lnw  age c.age#c.age sex i.educd i.educd#c.age foreign if foreign==0 | immclass==4   // -0.3% gap




* Choose education variable 3, quite disaggregated
gen edu=edu3
local eduvar = "3edu"

* Run the stuff
gen sigma_sqaux=.
gen resid=.


* LOOPS REGRESS LOG WAGES ON SOME THINGS AND THEN SAVE THE RESULTS SEPERATELY FOR MEN AND WOMEN
forvalues k = 1/2 {
		reg lnw i.agecat i.edu i.edu#i.agecat if sex==`k' & foreign==0, robust
		* Regress log wages alternating men and women for natives
        predict pldhw_`k' if sex==`k'
		* Save the predictions
		predict sigma if e(sample), resid
		replace sigma_sqaux=sigma^2 if sex==`k'
		* Save the predicted standard deviation/variance
        drop sigma
	        }

forvalues k=1/2 {
            if `k'==1 {
				gen lnPredWage = pldhw_`k'
		    }
            else {
				replace lnPredWage= pldhw_`k' if sex==`k'
                drop pldhw_`k'
		    }
		}
		


quietly sum agecat
local agemin=r(min)
* agemin will store the minimum age
local agemax=r(max)
*agemax will store the maximum age

quietly sum edu
local edumin=r(min)
*same concept as above
local edumax=r(max)
*same concept as above

sort serial
*sort by serial number
set seed 1234


*LOOP TO ADD SOME SORT OF STOCHASTIC ERROR TO THE PREDICTED WAGES
forvalues i=`agemin'/`agemax' {
	*loop through all ages
	forvalues k=1/2 {
		*loop through both sexes seperately
		forvalues j=`edumin'/`edumax' {
			*loop through years of education
		di "edu `j' sex `k' age `i'"
		*tell stata how to print stuff
			count if agecat==`i' & sex==`k' & edu==`j'
			*count returns number of obs satisfying the conditions
			if r(N)>0 {
				*if there exists obs then 
				sum sigma_sqaux if agecat==`i' & sex==`k' & edu==`j'
				* summarise the s.d of those observations
				matrix S = sqrt(r(mean))
				* define a matrix S with entry the mean value of the s.d of those obs
				drawnorm X, means(0) sds(S)
				*draw a normal with mean 0 and s.d defined above
				replace lnPredWage=(lnPredWage + X) if agecat==`i' & sex==`k' & edu==`j'
				*add the draw to the predicted log wages for that cat
				drop X
			}
		}
	}
}

drop if lnPredWage==.

gen lnw_pred = lnPredWage




* Predicted position of natives
replace lnw_pred=lnw if foreign==0  // use actual instead of predicted wages for natives
sort lnw_pred
gen rank_pred=sum(x)
* rank_pred gives predictd rank of each native
gen natbel_pred= rank_pred/ totwage
* natbel_pred will contain the relative ranking of people based on predicted wages
drop x rank* totwage
*drop everything for some reason


/*Prepare the log odd ratio*/
gen immpos=log(natbel/(1-natbel))
* Real immigrant positin is log(natbel/1-natbel)
gen immpos_pred=log(natbel_pred/(1-natbel_pred))
* Predicted immigrant position is log(natbel_pred/1-natbel_pred)

/*Generate the values at which the density should be estimated*/
gen percentile=_n
*each percentile corresponds the row number of an obs
replace percentile=. if percentile>=100
* if above the 100th obs then set missing
gen pctile=percentile/100
gen pctiletrans=log(pctile/(1-pctile))
* transform to logit for smooth tails

compress
save "${data}/US_tmp.dta",replace

*Finally save our 'usable' dataset




************************************
******	ACTUAL WAGES	     
************************************

* NOT PREDCITED VALUES
* Foreign
kdensity immpos if foreign==1  , generate (perc_imm dens_imm) nograph at(pctiletrans) bwidth(0.2) 
* Immigrant class 1
kdensity immpos if immclass==1 , generate (perc_immclass1 dens_immclass1) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 2
kdensity immpos if immclass==2 , generate (perc_immclass2 dens_immclass2) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 2 or 3
kdensity immpos if immclass==2 | immclass==3, generate (perc_immclass23 dens_immclass23) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 3
kdensity immpos if immclass==3 , generate (perc_immclass3 dens_immclass3) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 4
kdensity immpos if immclass==4 , generate (perc_immclass4 dens_immclass4) nograph at(pctiletrans) bwidth(0.2)

*PREDICTED VALUES
* Foreign
kdensity immpos_pred if foreign==1 , generate (perc_imm_pred dens_imm_pred) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 1
kdensity immpos_pred if immclass==1 , generate (perc_immclass1_pred dens_immclass1_pred) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 1
kdensity immpos_pred if immclass==2 , generate (perc_immclass2_pred dens_immclass2_pred) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 2 or 3
kdensity immpos_pred if immclass==2 | immclass==3 , generate (perc_immclass23_pred dens_immclass23_pred) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 3
kdensity immpos_pred if immclass==3 , generate (perc_immclass3_pred dens_immclass3_pred) nograph at(pctiletrans) bwidth(0.2)
* Immigrant class 4
kdensity immpos_pred if immclass==4 , generate (perc_immclass4_pred dens_immclass4_pred) nograph at(pctiletrans) bwidth(0.2)


/*Apply the transformation to the estimates to reverse the logit stuff*/
gen density_imm=dens_imm/(pctile*(1-pctile))
gen density_immclass1=dens_immclass1/(pctile*(1-pctile))
gen density_immclass2=dens_immclass2/(pctile*(1-pctile))
gen density_immclass23=dens_immclass23/(pctile*(1-pctile))
gen density_immclass3=dens_immclass3/(pctile*(1-pctile))
gen density_immclass4=dens_immclass4/(pctile*(1-pctile))

gen density_imm_pred=dens_imm_pred/(pctile*(1-pctile))
gen density_immclass1_pred=dens_immclass1_pred/(pctile*(1-pctile))
gen density_immclass2_pred=dens_immclass2_pred/(pctile*(1-pctile))
gen density_immclass23_pred=dens_immclass23_pred/(pctile*(1-pctile))
gen density_immclass3_pred=dens_immclass3_pred/(pctile*(1-pctile))
gen density_immclass4_pred=dens_immclass4_pred/(pctile*(1-pctile))

/*Difference between actual and predicted*/
gen density_immclass1_diff=(density_immclass1-density_immclass1_pred)
gen density_immclass2_diff=(density_immclass2-density_immclass2_pred)
gen density_immclass23_diff=(density_immclass23-density_immclass23_pred)
gen density_immclass3_diff=(density_immclass3-density_immclass3_pred)
gen density_immclass4_diff=(density_immclass4-density_immclass4_pred)


*******************************
******	GRAPHS	        
*******************************
/*Plot*/
* Label all variables for the graphs to look passable
gen one=1
gen zero=0
label var percentile "Percentile of non-immigrant wage distribution"
label var density_imm "Foreign workers"
label var density_immclass1 "Foreign <=2 years"
label var density_immclass2 "Foreign 3-5 years"
label var density_immclass23 "Foreign 3-10 years"
label var density_immclass4 "Foreign >10 years"
label var density_imm_pred "Foreign predicted"
label var density_immclass1_pred "Foreign <=2 years predicted"
label var density_immclass2_pred "Foreign 3-5 years predicted"
label var density_immclass3_pred "Foreign 6-10 years predicted"
label var density_immclass4_pred "Foreign >10 years predicted"
label var density_immclass1_diff "Arrival <=2 years"
label var density_immclass2_diff "Arrival 3-5 years"
label var density_immclass23_diff "Arrival 3-10 years"
label var density_immclass3_diff "Arrival 6-10 years"
label var density_immclass4_diff "Arrival >10 years"
label var one "Non-immigrant"



/*Actual vs Predicted*/
twoway ///
	(line density_imm percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///	
	(line density_imm_pred percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in native wage distribution) scheme(s1mono) note("Source: U.S. Census 2000.") 
*qui graph export "${LOG}US_immwagedis_actual_pred_`eduvar'.eps", replace
qui graph save   "${tables}/US_immwagedis_actual_pred_`eduvar'.gph", replace

/*Figure 1a: Actual vs Predicted: recent*/
twoway ///
	(line density_immclass1 percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///	
	(line density_immclass1_pred percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in native wage distribution) scheme(s1mono) note("Source: U.S. Census 2000.") 
*qui graph export "${LOG}US_immwagedis_actual_pred_recent_`eduvar'.eps", replace
qui graph save   "${tables}/US_immwagedis_actual_pred_recent_`eduvar'.gph", replace

/*Figure 1d: Actual Minus Predicted: Multiple Classes*/
twoway ///
	(line density_immclass1_diff percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///
	(line density_immclass23_diff percentile if percentile>4.5 & percentile<95.5, sort lpattern(dash) lcolor(orange)) ///	
	(line density_immclass4_diff percentile if percentile>4.5 & percentile<95.5, sort lpattern(shortdash) lcolor(purple)) ///	
	(line zero percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Actual vs. Predicted Position of Foreign workers)  scheme(s1mono) legend(order(1 2 3) cols(3) symxsize(*0.75))
*qui graph export "${LOG}US_immwagedis_actual_diff_classes_`eduvar'.eps", replace
qui graph save   "${tables}/US_immwagedis_actual_diff_classes_`eduvar'.gph", replace




************************************
******	IMPUTATION PROCEDURE 
************************************

************************************
* Effective skill imputation: unconstrained version for Table 2 and Table A.2
************************************

use "${data}/US_tmp.dta" , replace

* Select immigrant subgroup
global subgroup = "recentimm"
keep if foreign==0 | immclass==1
* Keep only recent immigrants 

*Check frequences of the skill groups and education groups by foreign or not
tab edu2 expcat2 if foreign==0 , nofreq cell
tab edu2 expcat2 if foreign==1 , nofreq cell

* Preparation
gen n=1
gen native=(foreign==0)

* Wage centiles by year
gen lnw_centile=.
replace lnw_centile=1
centile lnw if foreign==0, c(10(10)90)	
forval i=1/9 {
	replace lnw_centile=`i'+1 if lnw>=r(c_`i') & lnw!=.
}

* Occupation cells
gen occ2digit = floor(occ/10)
* Round down occupation to the closest lowest multiple of 10.

* Cell occupation x wage	
egen cell=group(lnw_centile occ2digit)
* Create groups based on belonging to a centile and an occupation family


* Sum # of workers on occ-lnw-edu-exp level, separately for immigrants and natives
collapse (sum) native foreign , by(cell edu2 expcat2)  
 

* Reshape over education
ren native native_ed
ren foreign foreign_ed
reshape wide native_ed foreign_ed , i(cell expcat2) j(edu2)

* Reshape over experience
ren native_ed1 native_ed1_exp
ren native_ed2 native_ed2_exp
ren foreign_ed1 foreign_ed1_exp
ren foreign_ed2 foreign_ed2_exp
reshape wide native_ed* foreign_ed* , i(cell) j(expcat2)

* Generate shares in each occupation-wage cell
unab vlist : native_* foreign_*
*create a varlist with all the 8 categories possible
foreach var in `vlist' {
	replace `var'=0 if `var'==.
	egen `var'_total = total(`var') 
	* var_total counts how many people in each category I think
	gen sh_`var' = `var'/`var'_total
	* For each class and category entry make it a relative representation I think
	replace sh_`var'=0 if sh_`var'==.
	drop `var'_total
}


**************************************
* NOW WE TRY AND ESTIMATE DOWNGRADING IDK HOW****
*************************************



* Estimate downgrading, separately for each education and experience group
forval edu=1/2 {
	forval exp=1/2 {
	gen foreign_ed`edu'_exp`exp'_weight_ed1_exp1=.
	gen foreign_ed`edu'_exp`exp'_weight_ed1_exp2=.
	gen foreign_ed`edu'_exp`exp'_weight_ed2_exp1=.
	gen foreign_ed`edu'_exp`exp'_weight_ed2_exp2=.
	*Generate a set of 4 empty weights for foreign ed/exp groups

	
	* Explain group occ-wage density as a mixture of all native distributions
	scalar sqdiffmin=1000
		
		forval i=0(0.01)1 {
			local rest=1-`i'
			forval j=0(0.01)`rest' {
				local rest2=1-`i'-`j'
				forval k=0(0.01)`rest2' {
					*di "with weight `i' `j' `k' sqdiff ..."
					
					gen mixture=`i'*sh_native_ed1_exp1 + `j'*sh_native_ed1_exp2 + `k'*sh_native_ed2_exp1 + (1-`i'-`j'-`k')*sh_native_ed2_exp2
					gen sqdiff = (sh_foreign_ed`edu'_exp`exp' - mixture)^2
					qui su sqdiff
					if r(mean)<sqdiffmin {

						qui replace foreign_ed`edu'_exp`exp'_weight_ed1_exp1=`i'
						qui replace foreign_ed`edu'_exp`exp'_weight_ed1_exp2=`j'
						qui replace foreign_ed`edu'_exp`exp'_weight_ed2_exp1=`k'
						qui replace foreign_ed`edu'_exp`exp'_weight_ed2_exp2=1-(`i'+`j'+`k')
 
 						scalar sqdiffmin=r(mean) 
					}
					drop mixture sqdiff	
				}
			}	
		}
	
	* Impute shares
	gen foreign_ed`edu'_exp`exp'_imp_ed1_exp1=foreign_ed`edu'_exp`exp'_weight_ed1_exp1 * foreign_ed`edu'_exp`exp'
	gen foreign_ed`edu'_exp`exp'_imp_ed1_exp2=foreign_ed`edu'_exp`exp'_weight_ed1_exp2 * foreign_ed`edu'_exp`exp'
	gen foreign_ed`edu'_exp`exp'_imp_ed2_exp1=foreign_ed`edu'_exp`exp'_weight_ed2_exp1 * foreign_ed`edu'_exp`exp'
	gen foreign_ed`edu'_exp`exp'_imp_ed2_exp2=foreign_ed`edu'_exp`exp'_weight_ed2_exp2 * foreign_ed`edu'_exp`exp'
	
	}	
}

* Collape each group
collapse (mean) *weight* (sum) foreign_ed*imp* 

* Reshape 
gen id=1
reshape long foreign_ed1_exp1_imp_ foreign_ed1_exp2_imp_ foreign_ed2_exp1_imp_ foreign_ed2_exp2_imp_ /// 
	foreign_ed1_exp1_weight_ foreign_ed1_exp2_weight_ foreign_ed2_exp1_weight_ foreign_ed2_exp2_weight_  , i(id) j(edexp) string

gen impedu=.
gen impexp=.
replace impedu=1 if edexp=="ed1_exp1" | edexp=="ed1_exp2"
replace impedu=2 if edexp=="ed2_exp1" | edexp=="ed2_exp2"
replace impexp=1 if edexp=="ed1_exp1" | edexp=="ed2_exp1"
replace impexp=2 if edexp=="ed1_exp2" | edexp=="ed2_exp2"
drop id 
ren edexp impedexp
order impedexp impedu impexp

gen total = foreign_ed1_exp1_imp_+foreign_ed1_exp2_imp_+foreign_ed2_exp1_imp_+foreign_ed2_exp2_imp_ 
egen tot_total=total(total)
gen sh_total = total/tot_total
drop tot_total

drop impedexp
reshape wide total sh_total foreign_ed1_exp1_weight_ - foreign_ed2_exp2_imp_ , i(impedu) j(impexp)

* Export results: imputed weights	
foreach var in foreign_ed1_exp1_weight foreign_ed1_exp2_weight foreign_ed2_exp1_weight foreign_ed2_exp2_weight total sh_total { 
	export delimited `var'* using "${tables}/impedu2_impexp2_${subgroup}_`var'_unconstrained.csv" , replace
}





