** Plot distribution of immigrants in native wage distribution in UK Census data
** Jan Stuhler, 2016
** Based on do-file by Dustmann, Frattini and Preston (2013), RESTUD
** which can be downloaded at http://restud.oxfordjournals.org/content/early/2012/04/18/restud.rds019

** Prepare Stata
**********************************************************
clear all
version 13
set more off
set trace off 
set tracedepth 1
set scrollbufsize 2000000
set matsize 4000
cap log close

**  Create folder for log files
**********************************************************
local today = c(current_date)
local today =  subinstr("`today'"," ","_",.)
cd "/Users/janstuhler/Dropbox/Christian_Uta_Jan/JEP Paper/Stata/Downgrading"
cap mkdir "./Log/UK_LFS_InDistr_`today'"

**  Paths
**********************************************************
global SOURCEFILE = "/Volumes/Disk Image/Data/UK LFS/LFSsmallerPanelQ1Y92_Q4Y05.dta"  // Path to Quarterly UK LFS; download from https://discover.ukdataservice.ac.uk/series/?sn=2000026
*global SOURCEFILE = "/Volumes/Disk Image/Data/UK LFS/dataforanalysis.dta"
global OUT = "./Output/" 		
global LOG = "./Log/UK_LFS_InDistr_`today'/" 	

cap log close
cap log using ${LOG}UKLFS_full, text replace

use "${SOURCEFILE}" 

************************************
* Part I: Imported from dataadjustments_2.do and wagesimul.do by Dustmann, Frattini and Preston, 2013, RESTUD
************************************

/*Drop if region of usual residence is Northern Ireland (because we have data from 1994
 onwards only, and we don't have 1991 census data)*/
drop if uresmc==20

/*Drop industry (sic 80) and other variables we do not use*/
drop IndLastSic80 IndSic80 relh96 sngdeg variabl0 RealGrossWkPay experience MaritalStatus

/*Generate a "recent immigrant" dummy, for immigrants who arrived in the last two years*/
gen ysa= Year-CameYear if foreign==1 & CameYear>0
label variable ysa "years since arrival"
gen recent_imm=1 if ysa<2
replace recent_imm=0 if ysa>1 & ysa!=.
label var recent_imm "immigrants in UK for less than 2 years"

/*Generate a categorical variable to identify natives and earlier and recent immigrants*/
gen immstatus=1 if foreign==0
replace immstatus=2 if recent_imm==0
replace immstatus=3 if recent_imm==1
label define immstatus 1 "native" 2 "earlier immigrant" 3 "recent immigrant"
label values immstatus immstatus

/*Generate a schooling classification based on the variable `edage', age when left full time education*/
drop school
gen school=3 if edage==97 | (edage<17 & edage>0)   /*hsd: I aslo include those who never had full time education(==97)*/
replace school=2 if edage>16 & edage <21
replace school=1 if edage>20 & edage<96   /*university, I exclude those still in education (==96)*/
label define education_derived 3 "low education" 2 "intermediate education" 1 "high education"
label values school education_derived
label var school "education, based on age at which left full time education"

/*Generate a NS-Sec major category variable, for years 2001-2005 (before 2001 this variable is not available)*/
gen nsecm=floor(NSECM)

*Recode NSSECM into NSECMMJ (analytic classes of NS-SEC)
gen NSECMMJ=1 if nsecm>=1 & nsecm<=3
replace NSECMMJ=2 if nsecm>=4 & nsecm<=6
replace NSECMMJ=3 if nsecm==7
replace NSECMMJ=4 if nsecm==8 | nsecm==9
replace NSECMMJ=5 if nsecm==10 | nsecm==11
replace NSECMMJ=6 if nsecm==12
replace NSECMMJ=7 if nsecm==13
replace NSECMMJ=8 if nsecm>=14 & nsecm<=17
label define nsecmmj 1 "Higher managerial and professionals" ///
2 "Lower managerial and professionals"  ///
3 "Intermediate occupations" ///
4 "Small employers and own account workers" ///
5 "Lower supervisory and technical" ///
6 "Semi-routine occupations" ///
7 "Routine occupations" ///
8 "Never worked, unemployed, and nec"
label values NSECMMJ nsecmmj
drop nsecm


gen id=_n

/*generate log wages*/
gen lnw=log(RealPay)
drop RealPay

/*Drop observations for those still in education and without observations on edage. Also, recode those who have never had ful time education as 0*/
replace edage=0 if edage==97
drop if edage==96 | edage<0
 
/*generate quarter dummies*/
tab Quarter, gen (Q_)

/*Generate London dummy*/
gen London=(uresmc==8)

/*Generate age categories*/
recode age (16/25=1) (26/35=2) (36/45=3) (46/55=4) (56/65=5), gen (agecat)
tab agecat, gen (age_)

/*Generate education categories, based on edage (age at which left full time education*/
recode edage (0/15=1) (16/18=2) (19/20=3) (nonmissing=4), gen (educat)
tab educat, gen (educ_)

/*generate education and age categories interaction*/
gen agecat10=agecat*10
gen educage=agecat10+educat

tab educage, gen (ageeduc_) 

gen sigma_sqaux=.
gen resid=.

quietly sum Year
local ymin=r(min)
local ymax=r(max)
forvalues i=`ymin'(1)`ymax' {
	forvalues k = 1/2 {
        regress lnw  Q_2-Q_4 London age_* educ_* ageeduc_* if sex==`k'& Year==`i' & foreign==0, robust
        predict pldhw_`k'_`i' if Year==`i' & sex==`k'
		predict sigma if e(sample), resid
		replace sigma_sqaux=sigma^2 if Year==`i' & sex==`k'
        drop sigma
	        }
	}

forvalues i=`ymin'(1)`ymax' {
	forvalues k=1/2 {
                if `i'==`ymin' &`k'==1 {
		    gen lnPredWage = pldhw_`k'_`i'
		    }
                else {
		    replace lnPredWage= pldhw_`k'_`i' if Year==`i' & sex==`k'
                drop pldhw_`k'_`i' 
		    }
		}
        }

quietly sum agecat
local agemin=r(min)
local agemax=r(max)

quietly sum educat
local edumin=r(min)
local edumax=r(max)

sort id
set seed 19811978
forvalues i=`agemin'/`agemax' {
	forvalues k=1/2 {
		forvalues j=`edumin'/`edumax' {
			sum sigma_sqaux if agecat==`i' & sex==`k' & educat==`j'
		      matrix S = sqrt(r(mean))
      		drawnorm X, means(0) sds(S)
      		replace lnPredWage=(lnPredWage + X) if agecat==`i' & sex==`k' & educat==`j'
			drop X
			}
		}
	}

drop if lnPredWage==.

************************************
* Part II: 
************************************

keep uresmc Year CameYear foreign lnw lnPredWage sigma_sq school soc2km age edage sex country 
keep if lnw!=. 

* Rename variables
ren soc2km occ
ren Year year

* Generate years since arrival
gen ysm=year-CameYear

* Keep 1995=2005
keep if year>=1995 & year<=2005

* Restrict analysis to those between 18 and 65 years old, with education observed
keep if age >= 18 & age <= 65 
drop if edage==.
	
* Generate age categories
recode age (18/25=1) (26/35=2) (36/45=3) (46/55=4) (56/65=5), gen (agecat)   
label define agecat 1 "18/25" 2 "26/35" 3 "36/45" 4 "46/55" 5 "56/65" , replace
label val agecat agecat

recode age (18/40=1) (41/65=2) , gen (agecat2)  
label define agecat2 1 "18/40" 2 "41/65" , replace
label val agecat2 agecat2

* Education: 4 categories
recode edage (0/15=1) (16/18=2) (19/20=3) (nonmissing=4), gen (edu4)

* Education: 2 categories
recode edage (0/15=1) (16/18=1) (19/20=2) (nonmissing=2), gen (edu2)
tab edu2 , missing

* Potential experience
gen pe = int(age - edage)
tab pe , miss
keep if pe >= 1 & pe <= 40

* Generate experience categories
recode pe (1/5=1) (6/10=2) (11/15=3) (16/20=4) (21/25=5) (26/30=6) (31/35=7) (36/40=8), gen (expcat)  
label def expcat 1 "(1/5=1)" 2 "(6/10=2)" 3 "(11/15=3)" 4 "(16/20=4)" 5 "(21/25=5)" 6 "(26/30=6)" 7 "(31/35=7)" 8 "(36/40=8)"
label val expcat expcat

recode pe (1/20=1) (21/40=2) , gen (expcat2)   
label define expcat2 1 "1-20 yrs" 2 "21-40 yrs" , replace
label val expcat2 expcat2

* Classify immigrants by time of arrival
gen immclass = .
replace immclass = 1 if foreign==1 & ysm<=2
replace immclass = 2 if foreign==1 & ysm> 2 & ysm<=5
replace immclass = 3 if foreign==1 & ysm> 5 & ysm<=10
replace immclass = 4 if foreign==1 & ysm> 10 & ysm!=.

label var immclass "time since arrival in Census data"
label def immclass 1 "0-2 years" 2 "3-5 years" 3 "6-10 years" 4 "more than 10 years"
label val immclass immclass  

/*Recreate wage variable*/
gen RealPay=exp(lnw)

/*Calculate average native and recent immigrants wage*/
sum RealPay  if foreign==0 
gen natwage=r(mean)
sum RealPay  if foreign==1 & ysm>=0 & ysm<2
gen immwage=r(mean)
gen imm_nat=immwage/natwage
label var imm_nat "ratio of recent immigrant to native wages"
drop natwage immwage


* evidence for downgrading among recent or previous immigrants? 
reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex age c.age#c.age sex i.edu4 i.edu4#c.age foreign if foreign==0 | immclass==1   // 12.9%. gap
reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex  age c.age#c.age sex i.edu4 i.edu4#c.age foreign if foreign==0 | immclass==2   // 9.4% gap
reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex  age c.age#c.age sex i.edu4 i.edu4#c.age foreign if foreign==0 | immclass==3   // 11.1 gap
reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex  age c.age#c.age sex i.edu4 i.edu4#c.age foreign if foreign==0 | immclass==4   // 4.5% gap

* evidence that degree of downgrading or recent immigrants changes over years? 
reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex age c.age#c.age sex i.edu4 i.edu4#c.age foreign#i.year if foreign==0 | immclass==1
reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex age c.age#c.age sex i.edu4 i.edu4#c.age foreign#i.year if foreign==0 | foreign==1

reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex age c.age#c.age sex i.edu4 i.edu4#c.age foreign if foreign==0 | immclass==1 & year>=2003 & year<=2005   // 21.8%. gap
reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex age c.age#c.age sex i.edu4 i.edu4#c.age foreign if foreign==0 | immclass==1 & year>=2000 & year<=2002   // 8.1%. gap
reg lnw  i.year i.year#i.edu4 i.year#c.age i.year#i.sex age c.age#c.age sex i.edu4 i.edu4#c.age foreign if foreign==0 | immclass==1 & year>=1997 & year<=1999   // 7.9%. gap

	
tab country if year<=1998 & immclass==1 
tab country if year>=2003 & immclass==1 

*Net out year effects 
reg lnw i.year
predict lnw2 , res

/*Calculate for each immigrant the proportion of natives working at a lower wage than their ACTUAL wage*/
sort year lnw2
gen x=1 if foreign==0
replace x=0 if foreign==1
by year: gen rank=sum(x)
by year: egen totwage=sum(x)
gen natbel= rank/ totwage
drop x rank totwage

/*Calculate for each immigrant the proportion of natives working at a lower wage than their PREDICTED wage*/
replace lnPredWage=lnw if foreign==0
sort year lnPredWage
gen x=1 if foreign==0
replace x=0 if foreign==1
by year: gen rank=sum(x)
by year: egen totwage=sum(x)
gen natbel_pred= rank/ totwage
drop rank totwage

/*Prepare the log odd ratio*/
gen immpos=log(natbel/(1-natbel))
gen immpos_pred=log(natbel_pred/(1-natbel_pred))

/*Generate the values at which the density should be estimated*/
gen percentile=_n
replace percentile=. if percentile>=100
gen pctile=percentile/100
gen pctiletrans=log(pctile/(1-pctile))

save "${OUT}UK_tmp.dta" , replace

************************************
******	ACTUAL WAGES	
************************************

/*Estimation*/
kdensity immpos if foreign==1  , generate (perc_imm dens_imm) nograph at(pctiletrans)
kdensity immpos if immclass==1 , generate (perc_immclass1 dens_immclass1) nograph at(pctiletrans)
kdensity immpos if immclass==2 , generate (perc_immclass2 dens_immclass2) nograph at(pctiletrans)
kdensity immpos if immclass==3 , generate (perc_immclass3 dens_immclass3) nograph at(pctiletrans)
kdensity immpos if immclass==4 , generate (perc_immclass4 dens_immclass4) nograph at(pctiletrans)

kdensity immpos if immclass==1 & year>=2003 & year<=2005 , generate (perc_immclass1_y1 dens_immclass1_y1) nograph at(pctiletrans)   // by year
kdensity immpos if immclass==1 & year>=2000 & year<=2002 , generate (perc_immclass1_y2 dens_immclass1_y2) nograph at(pctiletrans)
kdensity immpos if immclass==1 & year>=1997 & year<=1999 , generate (perc_immclass1_y3 dens_immclass1_y3) nograph at(pctiletrans)

kdensity immpos_pred if foreign==1 , generate (perc_imm_pred dens_imm_pred) nograph at(pctiletrans)
kdensity immpos_pred if immclass==1 , generate (perc_immclass1_pred dens_immclass1_pred) nograph at(pctiletrans)
kdensity immpos_pred if immclass==2 , generate (perc_immclass2_pred dens_immclass2_pred) nograph at(pctiletrans)
kdensity immpos_pred if immclass==3 , generate (perc_immclass3_pred dens_immclass3_pred) nograph at(pctiletrans)
kdensity immpos_pred if immclass==4 , generate (perc_immclass4_pred dens_immclass4_pred) nograph at(pctiletrans)

kdensity immpos_pred if immclass==1 & year>=2003 & year<=2005 , generate (perc_immclass1_pred_y1 dens_immclass1_pred_y1) nograph at(pctiletrans)  // by year
kdensity immpos_pred if immclass==1 & year>=2000 & year<=2002 , generate (perc_immclass1_pred_y2 dens_immclass1_pred_y2) nograph at(pctiletrans)
kdensity immpos_pred if immclass==1 & year>=1997 & year<=1999 , generate (perc_immclass1_pred_y3 dens_immclass1_pred_y3) nograph at(pctiletrans)

/*Apply the transformation to the estimates*/
gen density_imm=dens_imm/(pctile*(1-pctile))
gen density_immclass1=dens_immclass1/(pctile*(1-pctile))
gen density_immclass2=dens_immclass2/(pctile*(1-pctile))
gen density_immclass3=dens_immclass3/(pctile*(1-pctile))
gen density_immclass4=dens_immclass4/(pctile*(1-pctile))

gen density_immclass1_y1=dens_immclass1_y1/(pctile*(1-pctile))   // by year
gen density_immclass1_y2=dens_immclass1_y2/(pctile*(1-pctile))
gen density_immclass1_y3=dens_immclass1_y3/(pctile*(1-pctile))

gen density_imm_pred=dens_imm_pred/(pctile*(1-pctile))
gen density_immclass1_pred=dens_immclass1_pred/(pctile*(1-pctile))
gen density_immclass2_pred=dens_immclass2_pred/(pctile*(1-pctile))
gen density_immclass3_pred=dens_immclass3_pred/(pctile*(1-pctile))
gen density_immclass4_pred=dens_immclass4_pred/(pctile*(1-pctile))

gen density_immclass1_pred_y1=dens_immclass1_pred_y1/(pctile*(1-pctile))   // by year
gen density_immclass1_pred_y2=dens_immclass1_pred_y2/(pctile*(1-pctile))
gen density_immclass1_pred_y3=dens_immclass1_pred_y3/(pctile*(1-pctile))

	
*******************************
******	GRAPHS	
*******************************
/*Plot*/
gen one=1
label var percentile "Percentile of non-immigrant wage distribution"
label var density_imm "Foreign workers"
label var density_immclass1 "Foreign <=2 years"
label var density_immclass2 "Foreign 3-5 years"
label var density_immclass3 "Foreign 6-10 years"
label var density_immclass4 "Foreign >10 years"

label var density_immclass1_y1 "Recent, 2003-2005"
label var density_immclass1_y2 "Recent, 2000-2002"
label var density_immclass1_y3 "Recent, 1997-1999"

label var density_imm_pred "Foreign predicted"
label var density_immclass1_pred "Foreign <=2 years predicted"
label var density_immclass2_pred "Foreign 3-5 years predicted"
label var density_immclass3_pred "Foreign 6-10 years predicted"
label var density_immclass4_pred "Foreign >10 years predicted"

label var density_immclass1_pred_y1 "Recent pred, 2003-2005"
label var density_immclass1_pred_y2 "Recent pred, 2000-2002"
label var density_immclass1_pred_y3 "Recent pred, 1997-1999"

label var one "Non-immigrant"

/*Actual vs Predicted*/
twoway ///
	(line density_imm percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///	
	(line density_imm_pred percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in native wage distribution) scheme(s1mono) note("Source: LFS, 1995-2005") 
qui graph export "${LOG}UK_immwagedis_actual_pred_`eduvar'.eps", replace
qui graph save   "${LOG}UK_immwagedis_actual_pred_`eduvar'.gph", replace

/*Figure 1b: Actual vs Predicted: recent*/
twoway ///
	(line density_immclass1 percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///	
	(line density_immclass1_pred percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in native wage distribution) scheme(s1mono) note("Source: LFS, 1995-2005") 
qui graph export "${LOG}UK_immwagedis_actual_pred_recent_`eduvar'.eps", replace
qui graph save   "${LOG}UK_immwagedis_actual_pred_recent_`eduvar'.gph", replace


************************************
******	IMPUTATION PROCEDURE 
************************************

************************************
* Effective skill imputation: unconstrained version for Table 2 and Table A.1/A.2
************************************
use "${OUT}UK_tmp.dta" , clear

* Select immigrant subgroup
keep if foreign==0 | immclass==1
*global subgroup = "recentimm"
keep if year>=2003 
global subgroup = "recentimm_2003_05"

tab edu2 expcat2 if foreign==0 , nofreq cell
tab edu2 expcat2 if foreign==1 , nofreq cell

* Preparation
gen n=1
gen native=(foreign==0)

* Wage centiles by year
gen lnw_centile=.

sum year
local ymax=r(max)
local ymin=r(min) 
forval y=`ymin'/`ymax' {
	replace lnw_centile=1 if year==`y'
	centile lnw if foreign==0 & year==`y', c(10(10)90)	
	forval i=1/9 {
		replace lnw_centile=`i'+1 if lnw>=r(c_`i') & lnw!=. & year==`y'
	}
}

* Occupation cells
gen occ2digit = floor(occ/100)

* Cell occupation x wage	
egen cell=group(lnw_centile occ2digit)

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
foreach var in `vlist' {
	replace `var'=0 if `var'==.
	egen `var'_total = total(`var')
	gen sh_`var' = `var'/`var'_total
	replace sh_`var'=0 if sh_`var'==.
	drop `var'_total
}

* Unconstrained case
forval edu=1/2 {
	forval exp=1/2 {

	gen foreign_ed`edu'_exp`exp'_weight_ed1_exp1=.
	gen foreign_ed`edu'_exp`exp'_weight_ed1_exp2=.
	gen foreign_ed`edu'_exp`exp'_weight_ed2_exp1=.
	gen foreign_ed`edu'_exp`exp'_weight_ed2_exp2=.

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
	export excel `var'* using "${LOG}impedu2_impexp2_${subgroup}_`var'_unconstrained.csv" , replace first(variables)
}	



************************************
* Effective skill imputation: constrained version for Table A.4
************************************
use "${OUT}UK_tmp.dta" , clear

* Select immigrant subgroup
keep if foreign==0 | immclass==1
*global subgroup = "recentimm"
keep if year>=2003 
global subgroup = "recentimm_2003_05"

tab edu2 expcat2 if foreign==0 , nofreq cell
tab edu2 expcat2 if foreign==1 , nofreq cell

* Preparation
gen n=1
gen native=(foreign==0)

* Wage centiles by year
gen lnw_centile=.

sum year
local ymax=r(max)
local ymin=r(min) 
forval y=`ymin'/`ymax' {
	replace lnw_centile=1 if year==`y'
	centile lnw if foreign==0 & year==`y', c(10(10)90)	
	forval i=1/9 {
		replace lnw_centile=`i'+1 if lnw>=r(c_`i') & lnw!=. & year==`y'
	}
}

* Occupation cells
gen occ2digit = floor(occ/100)

* Cell occupation x wage	
egen cell=group(lnw_centile occ2digit)

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
foreach var in `vlist' {
	replace `var'=0 if `var'==.
	egen `var'_total = total(`var')
	gen sh_`var' = `var'/`var'_total
	replace sh_`var'=0 if sh_`var'==.
	drop `var'_total
}

* Constrained case with only two parameters 
forval edu=1/2 {
	forval exp=1/2 {

	gen foreign_ed`edu'_exp`exp'_weight_ed1_exp1=.
	gen foreign_ed`edu'_exp`exp'_weight_ed1_exp2=.
	gen foreign_ed`edu'_exp`exp'_weight_ed2_exp1=.
	gen foreign_ed`edu'_exp`exp'_weight_ed2_exp2=.
	
	}
}

	* Explain group occ-wage density as a mixture of all native distributions
	scalar sqdiffmin=1000
		
		forval phiE=0(0.01)1 {
			forval phiS=0(0.01)1 {
				
				*di "with weight phiS `phiS' and phiE `phiE' sqdiff ..."
				
				gen mixture_ed1_exp1 = 1*sh_native_ed1_exp1 
				gen mixture_ed1_exp2 = `phiE'*sh_native_ed1_exp1 + (1-`phiE')*sh_native_ed1_exp2  // experience downgrading
				gen mixture_ed2_exp1 = `phiS'*sh_native_ed1_exp1 + (1-`phiS')*sh_native_ed2_exp1  // schooling downgrading
				gen mixture_ed2_exp2 = `phiE'*`phiS'*sh_native_ed1_exp1 + `phiS'*(1-`phiE')*sh_native_ed1_exp2 + `phiE'*(1-`phiS')*sh_native_ed2_exp1 + (1-`phiE'-`phiS'+`phiE'*`phiS')*sh_native_ed2_exp2 // experience and schooling downgrading
				
				gen sqdiff = (sh_foreign_ed1_exp1 - mixture_ed1_exp1)^2 + (sh_foreign_ed1_exp2 - mixture_ed1_exp2)^2  /// 
								+ (sh_foreign_ed2_exp1 - mixture_ed2_exp1)^2 + (sh_foreign_ed2_exp2 - mixture_ed2_exp2)^2 

				qui su sqdiff
				if r(mean)<sqdiffmin {

					qui replace foreign_ed1_exp1_weight_ed1_exp1=1
					qui replace foreign_ed1_exp1_weight_ed1_exp2=0
					qui replace foreign_ed1_exp1_weight_ed2_exp1=0
					qui replace foreign_ed1_exp1_weight_ed2_exp2=0

					qui replace foreign_ed1_exp2_weight_ed1_exp1=`phiE'
					qui replace foreign_ed1_exp2_weight_ed1_exp2=1-`phiE'
					qui replace foreign_ed1_exp2_weight_ed2_exp1=0
					qui replace foreign_ed1_exp2_weight_ed2_exp2=0

					qui replace foreign_ed2_exp1_weight_ed1_exp1=`phiS'
					qui replace foreign_ed2_exp1_weight_ed1_exp2=0
					qui replace foreign_ed2_exp1_weight_ed2_exp1=1-`phiS'
					qui replace foreign_ed2_exp1_weight_ed2_exp2=0

					qui replace foreign_ed2_exp2_weight_ed1_exp1=`phiS'*`phiE'
					qui replace foreign_ed2_exp2_weight_ed1_exp2=`phiS'*(1-`phiE')
					qui replace foreign_ed2_exp2_weight_ed2_exp1=`phiE'*(1-`phiS')
					qui replace foreign_ed2_exp2_weight_ed2_exp2=1-`phiE'-`phiS'+`phiE'*`phiS'
										
					scalar sqdiffmin=r(mean) 
				}
				drop mixture* sqdiff	
				
			}	
		}
	
* Impute shares
forval edu=1/2 {
	forval exp=1/2 {
	
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
	export excel `var'* using "${LOG}impedu2_impexp2_${subgroup}_`var'_constrained.csv" , replace first(variables)
}	
	
	
rm "${OUT}UK_tmp.dta"
	
