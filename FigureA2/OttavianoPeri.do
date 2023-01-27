cd U:\MATLAB\JEPimmigration

********************************************
*figure: imperfect substitutability between natives and immigrants
*************************************************


*read in ratios for SO group
clear
insheet using "ratio_SO.dat", double comma
rename v1 phisgrid
rename v2 phia0
rename v3 phia1
rename v4 phia2


label variable phia0 "no downgrading by exp."
label variable phia1 "30% downgrading by exp."
label variable phia2 "60% downgrading by exp."
label variable phisgrid "degree of downgrading by education"



#delimit;
scatter phia0 phia1 phia2 phisgrid, connect(l l l)
symbol(none none none) lp(solid dash dot) lw (medium medium thick)
title("skilled, experienced workers") ytitle(delta-1)
ylabel(-0.30(0.05)0) scheme(s2mono) saving(OP_SO.gph, replace) ;
graph export OP_SO.eps, replace;


























