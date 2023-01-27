%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%relative wage effects with downgrading --> Borjas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

%%%%%%%%%%%parameters of the production function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gamma=0.8; %corresponds to an elasticity of substitition between young and old of 1/(1-0.8)=5
beta=0.6; %corresponds to elasticity of substitution between skilled and unskilled of 1/(1-0.6)=2.5
alpha=0.3; %capital share in production
lambdagrid=[0 500]; %leasticity of capital. 0 means capital is fully inelastic. infinity means capital is fully elastic
phigrid=-(alpha*lambdagrid)./(1-alpha+lambdagrid); %slope of the aggregate labor demand curve

thetaUY=1; %efficiency unit parameters of the production function
thetaUO=1;
thetaSY=1;
thetaSO=1;
thetaU=1;
thetaS=1;



%%%%%%%%%%%%%%%%employment at baseline, in head counts. These numbers were
%%%%%%%%%%%%%%%%provided by Jan and come from the Census. Assume for simplicity here that existing immigrants do not downgrade.


NUY=935226+145808; %total number of unskilled young natives and existing immigrants at baseline (excluding existing immigrants)
NUO=870267+138928; %total number of unskilled old natives and existing immigrants at baseline
NSY=1578661+184969; %total number of skilled young natives and existing immigrants at baseline
NSO=1220918+116395; %total number of skilled old natives and existing immigrants at baseline

%CES aggregate shares by skill and age at baseline
sUY=thetaUY*NUY^gamma/(thetaUY*NUY^gamma+thetaUO*NUO^gamma);
sUO=thetaUO*NUO^gamma/(thetaUY*NUY^gamma+thetaUO*NUO^gamma);
sSY=thetaSY*NSY^gamma/(thetaSY*NSY^gamma+thetaSO*NSO^gamma);
sSO=thetaSO*NSO^gamma/(thetaSY*NSY^gamma+thetaSO*NSO^gamma);

%%%%employment at baseline, CES aggregate
NCESU=(thetaUY*NUY^gamma+thetaUO*NUO^gamma)^(1/gamma);
NCESS=(thetaSY*NSY^gamma+thetaSO*NSO^gamma)^(1/gamma);

%CES aggregate shares by skill at baseline
sU=thetaU*NCESU^beta/(thetaU*NCESU^beta+thetaS*NCESS^beta);
sS=thetaS*NCESS^beta/(thetaU*NCESU^beta+thetaS*NCESS^beta);


%%entering immigrants in head counts, as they are observed in the data. These numbers were provided by Jan
%%and come from the Census
IUYobsdata=24277; %entering unskilled young immigrants
IUOobsdata=7388; %entering unskilled old immigrants
ISYobsdata=19953; %entering skilled young immigrants
ISOobsdata=3411; %entering skilled old immigrant

%%compute true entering immigrants for each degree of downgrading by age and education
phisgrid=[0:0.05:0.5]';
%no downgrading by age
phia0=0;
dIUYtrue_phia0=(IUYobsdata+phia0*IUOobsdata+phisgrid*ISYobsdata+phisgrid*phia0*ISOobsdata)/NUY;
dIUOtrue_phia0=((1-phia0)*IUOobsdata+(1-phia0)*phisgrid*ISOobsdata)/NUO;
dISYtrue_phia0=((1-phisgrid).*ISYobsdata+(1-phisgrid)*phia0*ISOobsdata)/NSY;
dISOtrue_phia0=((1-phia0)*(1-phisgrid)*ISOobsdata)/NSO;
%30% downgrading by age
phia1=0.3;
dIUYtrue_phia1=(IUYobsdata+phia1*IUOobsdata+phisgrid*ISYobsdata+phisgrid*phia1*ISOobsdata)/NUY;
dIUOtrue_phia1=((1-phia1)*IUOobsdata+(1-phia1)*phisgrid*ISOobsdata)/NUO;
dISYtrue_phia1=((1-phisgrid).*ISYobsdata+(1-phisgrid)*phia1*ISOobsdata)/NSY;
dISOtrue_phia1=(1-phia1)*(1-phisgrid)*ISOobsdata/NSO;
%60% downgrading by age
phia2=0.6;
dIUYtrue_phia2=(IUYobsdata+phia2*IUOobsdata+phisgrid*ISYobsdata+phisgrid*phia2*ISOobsdata)/NUY;
dIUOtrue_phia2=((1-phia2)*IUOobsdata+(1-phia2)*phisgrid*ISOobsdata)/NUO;
dISYtrue_phia2=((1-phisgrid).*ISYobsdata+(1-phisgrid)*phia2*ISOobsdata)/NSY;
dISOtrue_phia2=(1-phia2)*(1-phisgrid)*ISOobsdata/NSO;

%%compute true differences in labor supply shocks, young-old, unskilled
%%vs young-old, skilled
diffIobs=(IUYobsdata/NUY-IUOobsdata/NUO)-(ISYobsdata/NSY-ISOobsdata/NSO);
diffIobs_rep=repmat(diffIobs, length(phisgrid),1);


%%compute true differences in labor supply shocks, young-old, unskilled vs
%%young-old, skilled
%phia=0
diffItrue_phia0=(dIUYtrue_phia0-dIUOtrue_phia0)-(dISYtrue_phia0-dISOtrue_phia0);
%phia=0.3
diffItrue_phia1=(dIUYtrue_phia1-dIUOtrue_phia1)-(dISYtrue_phia1-dISOtrue_phia1);
%phia=0.6
diffItrue_phia2=(dIUYtrue_phia2-dIUOtrue_phia2)-(dISYtrue_phia2-dISOtrue_phia2);


Borjas=[phisgrid diffIobs_rep diffItrue_phia0 diffItrue_phia1 diffItrue_phia2];

dlmwrite('downgrading_Borjas.dat', Borjas);