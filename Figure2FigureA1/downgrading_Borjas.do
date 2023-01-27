cd U:\MATLAB\JEPimmigration


clear
insheet using downgrading_Borjas.dat, double comma
rename v1 phisgrid
rename v2 diffIobs
rename v3 diffItrue_phia0
rename v4 diffItrue_phia1
rename v5 diffItrue_phia2

save downgrading_Borjas, replace


gen phia0=diffItrue_phia0/diffIobs
gen phia01=diffItrue_phia1/diffIobs
gen phia02=diffItrue_phia2/diffIobs


label variable phia0  "no downgrading by exp."
label variable phia01  "30% downgrading by exp."
label variable phia02  "60% downgrading by exp."


#delimit;
scatter phia0 phia01 phia02 phis, xtitle(degree of downgrading by education)
ytitle("bias factor")
connect(l l l) symbol(none none none) lpattern(solid dot dash)
lw(medium thick medium) scheme(s2mono)  saving(downgrading_Borjas.gph, replace);
graph export downgrading_Borjas.eps, replace;
