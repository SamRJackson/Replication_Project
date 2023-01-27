%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%downgrading and the elasticity of substitution between immigrants and natives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;

%%%%%%%%%%%parameters of the production function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gamma=0.8; %corresponds to an elasticity of substitition between young and old of 1/(1-0.8)=5
beta=0.6; %corresponds to elasticity of substitution between skilled and unskilled of 1/(1-0.6)=2.5
alpha=0.3; %capital share in production
lambdagrid=[0]; %leasticity of capital. 0 means capital is fully inelastic. infinity means capital is fully elastic
phigrid=-(alpha*lambdagrid)./(1-alpha+lambdagrid); %slope of the aggregate labor demand curve

thetaUY=1; %efficiency unit parameters of the production function
thetaUO=1;
thetaSY=1;
thetaSO=1;
thetaU=1;
thetaS=1;



%%%%%%%%%%%%%%%%employment at baseline, in head counts. These numbers were
%%%%%%%%%%%%%%%%provided by Jan and come from the Census. Assume for simplicity here that existing immigrants do not downgrade.

%natives
NUY=93522; %total number of unskilled young natives at baseline (excluding existing immigrants)
NUO=870267; %total number of unskilled old natives at baseline
NSY=1578661; %total number of skilled young natives at baseline
NSO=1220918; %total number of skilled old natives at baseline
N=NUY+NUO+NSY+NSO; %total number of workers in head counts
NU=NUY+NUO; %total number of unskilled workers
NS=NSY+NSO; %total number of unskilled workers

%existing immigrants, observed
IexUYobs=145808; %observed total number of unskilled young existing immigrants at baseline (excluding existing immigrants)
IexUOobs=138928; %observed total number of unskilled old existing immigrants at baseline
IexSYobs=184969; %observed total number of skilled young existing immigrants at baseline
IexSOobs=116395; %observed total number of skilled old existing immigrants at baseline
Iextotalobs=IexSYobs+IexSOobs+IexUYobs+IexUOobs;

%%compute true number of existing immigrants for each degree of downgrading by education and by age
phisgrid=[0:0.05:0.5]';
%degree of downgrading by experience: 0
phia0=0;
IexUYtrue_phia0=IexUYobs+phisgrid*IexUOobs+phia0*IexSYobs+phisgrid*phia0*IexSOobs;
IexUOtrue_phia0=(1-phia0)*IexUOobs+(1-phia0)*phisgrid*IexSOobs;
IexSYtrue_phia0=(1-phisgrid)*IexSYobs+(1-phisgrid)*phia0*IexSOobs;
IexSOtrue_phia0=(1-phisgrid)*phia0*IexSOobs;

%degree of downgrading by experience: 0.3
phia1=0.3;
IexUYtrue_phia1=IexUYobs+phisgrid*IexUOobs+phia1*IexSYobs+phisgrid*phia1*IexSOobs;
IexUOtrue_phia1=(1-phia1)*IexUOobs+(1-phia1)*phisgrid*IexSOobs;
IexSYtrue_phia1=(1-phisgrid)*IexSYobs+(1-phisgrid)*phia1*IexSOobs;
IexSOtrue_phia1=(1-phisgrid)*phia1*IexSOobs;

%degree of downgrading by experience: 0.6
phia2=0.6;
IexUYtrue_phia2=IexUYobs+phisgrid*IexUOobs+phia2*IexSYobs+phisgrid*phia2*IexSOobs;
IexUOtrue_phia2=(1-phia2)*IexUOobs+(1-phia2)*phisgrid*IexSOobs;
IexSYtrue_phia2=(1-phisgrid)*IexSYobs+(1-phisgrid)*phia2*IexSOobs;
IexSOtrue_phia2=(1-phisgrid)*phia2*IexSOobs;


%%entering immigrants in head counts, as they are observed in the data. These numbers were provided by Jan
%%and come from the Census
IenUYobs=24277; %entering unskilled young immigrants
IenUOobs=7388; %entering unskilled old immigrants
IenSYobs=19953; %entering skilled young immigrants
IenSOobs=3411; %entering skilled old immigrants
Ientotalobs=IenSYobs+IenSOobs+IenUYobs+IenUOobs;

%%compute true number of entering immigrants for each degree of downgrading by education and by age
IenUYtrue_phia0=IenUYobs+phisgrid*IenUOobs+phia0*IenSYobs+phisgrid*phia0*IenSOobs;
IenUOtrue_phia0=(1-phia0)*IenUOobs+(1-phia0)*phisgrid*IenSOobs;
IenSYtrue_phia0=(1-phisgrid)*IenSYobs+(1-phisgrid)*phia0*IenSOobs;
IenSOtrue_phia0=(1-phisgrid)*phia0*IenSOobs;

%degree of downgrading by experience: 0.3
IenUYtrue_phia1=IenUYobs+phisgrid*IenUOobs+phia1*IenSYobs+phisgrid*phia1*IenSOobs;
IenUOtrue_phia1=(1-phia1)*IenUOobs+(1-phia1)*phisgrid*IenSOobs;
IenSYtrue_phia1=(1-phisgrid)*IenSYobs+(1-phisgrid)*phia1*IenSOobs;
IenSOtrue_phia1=(1-phisgrid)*phia1*IenSOobs;

%degree of downgrading by experience: 0.6
IenUYtrue_phia2=IenUYobs+phisgrid*IenUOobs+phia2*IenSYobs+phisgrid*phia2*IenSOobs;
IenUOtrue_phia2=(1-phia2)*IenUOobs+(1-phia2)*phisgrid*IenSOobs;
IenSYtrue_phia2=(1-phisgrid)*IenSYobs+(1-phisgrid)*phia2*IenSOobs;
IenSOtrue_phia2=(1-phisgrid)*phia2*IenSOobs;

%CES aggregate shares by skill and age at baseline
%phia0

sUY_phia0=thetaUY*(NUY+IexUYtrue_phia0).^gamma./(thetaUY*(NUY+IexUYtrue_phia0).^gamma+thetaUO*(NUO+IexUOtrue_phia0).^gamma);
sUO_phia0=thetaUO*(NUO+IexUOtrue_phia0).^gamma./(thetaUY*(NUY+IexUYtrue_phia0).^gamma+thetaUO*(NUO+IexUOtrue_phia0).^gamma);
sSY_phia0=thetaSY*(NSY+IexSYtrue_phia0).^gamma./(thetaSY*(NSY+IexSYtrue_phia0).^gamma+thetaSO*(NSO+IexSOtrue_phia0).^gamma);
sSO_phia0=thetaSO*(NSO+IexSOtrue_phia0).^gamma./(thetaSY*(NSY+IexSYtrue_phia0).^gamma+thetaSO*(NSO+IexSOtrue_phia0).^gamma);

%phia1
sUY_phia1=thetaUY*(NUY+IexUYtrue_phia1).^gamma./(thetaUY*(NUY+IexUYtrue_phia1).^gamma+thetaUO*(NUO+IexUOtrue_phia1).^gamma);
sUO_phia1=thetaUO*(NUO+IexUOtrue_phia1).^gamma./(thetaUY*(NUY+IexUYtrue_phia1).^gamma+thetaUO*(NUO+IexUOtrue_phia1).^gamma);
sSY_phia1=thetaSY*(NSY+IexSYtrue_phia1).^gamma./(thetaSY*(NSY+IexSYtrue_phia1).^gamma+thetaSO*(NSO+IexSOtrue_phia1).^gamma);
sSO_phia1=thetaSO*(NSO+IexSOtrue_phia1).^gamma./(thetaSY*(NSY+IexSYtrue_phia1).^gamma+thetaSO*(NSO+IexSOtrue_phia1).^gamma);

%phia2
sUY_phia2=thetaUY*(NUY+IexUYtrue_phia2).^gamma./(thetaUY*(NUY+IexUYtrue_phia2).^gamma+thetaUO*(NUO+IexUOtrue_phia2).^gamma);
sUO_phia2=thetaUO*(NUO+IexUOtrue_phia2).^gamma./(thetaUY*(NUY+IexUYtrue_phia2).^gamma+thetaUO*(NUO+IexUOtrue_phia2).^gamma);
sSY_phia2=thetaSY*(NSY+IexSYtrue_phia2).^gamma./(thetaSY*(NSY+IexSYtrue_phia2).^gamma+thetaSO*(NSO+IexSOtrue_phia2).^gamma);
sSO_phia2=thetaSO*(NSO+IexSOtrue_phia2).^gamma./(thetaSY*(NSY+IexSYtrue_phia2).^gamma+thetaSO*(NSO+IexSOtrue_phia2).^gamma);

%%%%employment at baseline, CES aggregate
NCESU_phia0=(thetaUY*(NUY+IexUYtrue_phia0).^gamma+thetaUO*(NUO+IexUOtrue_phia0).^gamma).^(1/gamma);
NCESS_phia0=(thetaSY*(NSY+IexSYtrue_phia0).^gamma+thetaSO*(NSO+IexSOtrue_phia0).^gamma).^(1/gamma);

NCESU_phia1=(thetaUY*(NUY+IexUYtrue_phia1).^gamma+thetaUO*(NUO+IexUOtrue_phia1).^gamma).^(1/gamma);
NCESS_phia1=(thetaSY*(NSY+IexSYtrue_phia1).^gamma+thetaSO*(NSO+IexSOtrue_phia1).^gamma).^(1/gamma);

NCESU_phia2=(thetaUY*(NUY+IexUYtrue_phia2).^gamma+thetaUO*(NUO+IexUOtrue_phia2).^gamma).^(1/gamma);
NCESS_phia2=(thetaSY*(NSY+IexSYtrue_phia2).^gamma+thetaSO*(NSO+IexSOtrue_phia2).^gamma).^(1/gamma);


%CES aggregate shares by skill at baseline
sU_phia0=thetaU*NCESU_phia0.^beta./(thetaU*NCESU_phia0.^beta+thetaS*NCESS_phia0.^beta);
sS_phia0=thetaS*NCESS_phia0.^beta./(thetaU*NCESU_phia0.^beta+thetaS*NCESS_phia0.^beta);
sU_phia1=thetaU*NCESU_phia0.^beta./(thetaU*NCESU_phia1.^beta+thetaS*NCESS_phia1.^beta);
sS_phia1=thetaS*NCESS_phia0.^beta./(thetaU*NCESU_phia1.^beta+thetaS*NCESS_phia1.^beta);
sU_phia2=thetaU*NCESU_phia0.^beta./(thetaU*NCESU_phia2.^beta+thetaS*NCESS_phia2.^beta);
sS_phia2=thetaS*NCESS_phia0.^beta./(thetaU*NCESU_phia2.^beta+thetaS*NCESS_phia2.^beta);

%%%%%%%%%%%compute the shocks
dIUYtrue_phia0=IenUYtrue_phia0./(NUY+IexUYtrue_phia0);
dIUOtrue_phia0=IenUOtrue_phia0./(NUO+IexUOtrue_phia0);
dISYtrue_phia0=IenSYtrue_phia0./(NSY+IexSYtrue_phia0);
dISOtrue_phia0=IenSOtrue_phia0./(NSO+IexSOtrue_phia0);

dIUYtrue_phia1=IenUYtrue_phia1./(NUY+IexUYtrue_phia1);
dIUOtrue_phia1=IenUOtrue_phia1./(NUO+IexUOtrue_phia1);
dISYtrue_phia1=IenSYtrue_phia1./(NSY+IexSYtrue_phia1);
dISOtrue_phia1=IenSOtrue_phia1./(NSO+IexSOtrue_phia1);

dIUYtrue_phia2=IenUYtrue_phia2./(NUY+IexUYtrue_phia2);
dIUOtrue_phia2=IenUOtrue_phia2./(NUO+IexUOtrue_phia2);
dISYtrue_phia2=IenSYtrue_phia2./(NSY+IexSYtrue_phia2);
dISOtrue_phia2=IenSOtrue_phia2./(NSO+IexSOtrue_phia2);

dItildeUtrue_phia0=sUY_phia0.*dIUYtrue_phia0+sUO_phia0.*dIUOtrue_phia0;
dItildeStrue_phia0=sSY_phia0.*dISYtrue_phia0+sSO_phia0.*dISOtrue_phia0;

dItildeUtrue_phia1=sUY_phia1.*dIUYtrue_phia1+sUO_phia1.*dIUOtrue_phia1;
dItildeStrue_phia1=sSY_phia1.*dISYtrue_phia1+sSO_phia1.*dISOtrue_phia1;

dItildeUtrue_phia2=sUY_phia2.*dIUYtrue_phia2+sUO_phia2.*dIUOtrue_phia2;
dItildeStrue_phia2=sSY_phia2.*dISYtrue_phia2+sSO_phia2.*dISOtrue_phia2;

dItildetrue_phia0=sU_phia0.*dItildeUtrue_phia0+sS_phia0.*dItildeStrue_phia0;
dItildetrue_phia1=sU_phia1.*dItildeUtrue_phia1+sS_phia1.*dItildeStrue_phia1;
dItildetrue_phia2=sU_phia2.*dItildeUtrue_phia2+sS_phia2.*dItildeStrue_phia2;


%%%compute true wage changes for natives
dlogwUYtrue_phia0=(phigrid*dItildetrue_phia0+(beta-1).*(dItildeUtrue_phia0-dItildetrue_phia0)+(gamma-1).*(dIUYtrue_phia0-dItildeUtrue_phia0));
dlogwUOtrue_phia0=(phigrid*dItildetrue_phia0+(beta-1).*(dItildeUtrue_phia0-dItildetrue_phia0)+(gamma-1).*(dIUOtrue_phia0-dItildeUtrue_phia0));
dlogwSYtrue_phia0=(phigrid*dItildetrue_phia0+(beta-1).*(dItildeStrue_phia0-dItildetrue_phia0)+(gamma-1).*(dISYtrue_phia0-dItildeStrue_phia0));
dlogwSOtrue_phia0=(phigrid*dItildetrue_phia0+(beta-1).*(dItildeStrue_phia0-dItildetrue_phia0)+(gamma-1).*(dISOtrue_phia0-dItildeStrue_phia0));

dlogwUYtrue_phia1=(phigrid*dItildetrue_phia1+(beta-1).*(dItildeUtrue_phia1-dItildetrue_phia1)+(gamma-1).*(dIUYtrue_phia1-dItildeUtrue_phia1));
dlogwUOtrue_phia1=(phigrid*dItildetrue_phia1+(beta-1).*(dItildeUtrue_phia1-dItildetrue_phia1)+(gamma-1).*(dIUOtrue_phia1-dItildeUtrue_phia1));
dlogwSYtrue_phia1=(phigrid*dItildetrue_phia1+(beta-1).*(dItildeStrue_phia1-dItildetrue_phia1)+(gamma-1).*(dISYtrue_phia1-dItildeStrue_phia1));
dlogwSOtrue_phia1=(phigrid*dItildetrue_phia1+(beta-1).*(dItildeStrue_phia1-dItildetrue_phia1)+(gamma-1).*(dISOtrue_phia1-dItildeStrue_phia1));

dlogwUYtrue_phia2=(phigrid*dItildetrue_phia2+(beta-1).*(dItildeUtrue_phia2-dItildetrue_phia2)+(gamma-1).*(dIUYtrue_phia2-dItildeUtrue_phia2));
dlogwUOtrue_phia2=(phigrid*dItildetrue_phia2+(beta-1).*(dItildeUtrue_phia2-dItildetrue_phia2)+(gamma-1).*(dIUOtrue_phia2-dItildeUtrue_phia2));
dlogwSYtrue_phia2=(phigrid*dItildetrue_phia2+(beta-1).*(dItildeStrue_phia2-dItildetrue_phia2)+(gamma-1).*(dISYtrue_phia2-dItildeStrue_phia2));
dlogwSOtrue_phia2=(phigrid*dItildetrue_phia2+(beta-1).*(dItildeStrue_phia2-dItildetrue_phia2)+(gamma-1).*(dISOtrue_phia2-dItildeStrue_phia2));



%%compute wage change for immigrants observed to be experienced and skilled
dlogwSOIobs_phia0=phisgrid.*phia0.*dlogwUYtrue_phia0+phisgrid.*(1-phia0).*dlogwUOtrue_phia0+(1-phisgrid).*phia0.*dlogwSYtrue_phia0+(1-phisgrid).*(1-phia0).*dlogwSOtrue_phia0;
%%degree of downgrading by experience:0.3
dlogwSOIobs_phia1=phisgrid.*phia1.*dlogwUYtrue_phia1+phisgrid.*(1-phia1).*dlogwUOtrue_phia1+(1-phisgrid).*phia1.*dlogwSYtrue_phia1+(1-phisgrid).*(1-phia1).*dlogwSOtrue_phia1;
%%degree of downgrading by experience:0.3
dlogwSOIobs_phia2=phisgrid.*phia2.*dlogwUYtrue_phia2+phisgrid.*(1-phia2).*dlogwUOtrue_phia2+(1-phisgrid).*phia2.*dlogwSYtrue_phia2+(1-phisgrid).*(1-phia2).*dlogwSOtrue_phia2;



%%%compute the observed shock to skilled old existing immigrants. 
dISOIex=IenSOobs/IexSOobs;

%%%compute the ratio between the difference between )wage changes for existing immigrants observed to be
%skilled-old and skilled-old native wage changes) and the shock for skilled-old immigrants ad=nd write in one matrix

ratio_SO=[phisgrid (dlogwSOIobs_phia0-dlogwSOtrue_phia0)./dISOIex (dlogwSOIobs_phia1-dlogwSOtrue_phia1)./dISOIex (dlogwSOIobs_phia2-dlogwSOtrue_phia2)./dISOIex]


dlmwrite('ratio_SO.dat', ratio_SO);