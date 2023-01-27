** Plot distribution of immigrants in native wage distribution in IABS/SIAB data
** Jan Stuhler

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
cap mkdir "./Log/GER_IABSSIAB_InDistr_`today'"

**  Paths
**********************************************************
global SOURCE = "SOURCE PATH TO IABS HERE"   // path to IABS/SIAB data
global OUT = "./Output/" 		
global LOG = "./Log/GER_IABSSIAB_InDistr_`today'/" 	

cap log close
cap log using ${LOG}GER_IABSSIAB_full, text replace


** Prepare Stata
**********************************************************
clear all
version 11
set more off
set trace off 
set tracedepth 1
set scrollbufsize 2000000
set matsize 4000
cap log close

**  Set sampling period 
**********************************************************
global startyear 1975
global startyearplus 1976
global endyear 2001


** Load data 
**********************************************************


** Pool over years
**********************************************************

foreach y of numlist $startyear/$endyear {
	
	di "Year: `y'"
	di c(current_date)
	di c(current_time)
	use "${SOURCE}clean`y'.dta" , clear
	d, si

	*  Drop variables that are not needed
	**********************************************************
	cap drop dauer 
	cap drop gebjm 
	cap drop gebj 
	cap drop gebm 
	cap drop wz93
	cap drop ten
  
	* Clean area information
	**********************************************************
	
	* Work place
	replace ao_kreis=. if ao_kreis<0 | ao_kreis>=99999
	replace ao_kreis=11000 if ao_kreis==11100 | ao_kreis==11200  // Berlin
	label variable ao_kreis "Workplace: District/Landkreis"
	drop if ao_kreis==.

	* Place of Residence 
	codebook wo_gem 
	gen wo_kreis_abroad=(wo_gem==-9999998)   // in IAB full data the coding for living abroad is -9999998, in IABS data it is 99998 
	replace wo_gem = . if wo_gem<0
	gen wo_kreis=int(wo_gem/1000)
	label variable wo_gem 	"Place of residence: Municipality/Gemeinde"
	label variable wo_kreis "Place of residence: District/Landkreis"
	replace wo_kreis=11000 if wo_kreis==11100 | wo_kreis==11200  // Recode all parts of Berlin into one code
	replace wo_kreis=. if wo_kreis<0 | wo_kreis>=99999

	replace wo_kreis=99998 if wo_kreis_abroad==1 
	drop wo_kreis_abroad
	label define wo_kreis 99998 "Indicator if person lives abroad" 
	label values wo_kreis wo_kreis

	* Create (non-imputed) education variable
	**********************************************************
	label var ausbild "education, raw measure"
	gen edu=1 if ausbild==0 | ausbild==1 | ausbild==3
	replace edu=2 if ausbild==2 | ausbild==4
	replace edu=3 if ausbild==5 | ausbild==6
	replace edu=. if ausbild<0 | ausbild>6
	label define edu 1 "[1] None or only a school degree" 2 "[2] School and vocational" 3 "[3] Technical college / university"
	label values edu edu
	label variable edu "education (non-imputed)"

	* Merge imputed education and imputed log real wages
	**********************************************************
	
	* Merge imputed wages
	sort vsnr
	merge vsnr using "${SOURCE}imput-`y'.dta" , keep(imp_lnwcino)
	tab 	_merge		
	drop if _merge==2
	drop _merge
	label var imp_lnwcino "imputed log real wage, no heteroscedasticity"
	codebook imp_lnwcino edu

	* Label variables
	**********************************************************
	
	* Label occupation variable
	#delimit;
	label define beruford
	011 "[011]Landwirte"
	012 "[012]Weinbauern"
	021 "[021]Tierzuechter"
	022 "[022]Fischer"
	031 "[031]Verwalter, Landwirtschaft"
	032 "[032]Agraring., Landwirt. Berater"
	041 "[041]Landarbeitskraefte"
	042 "[042]Melker"
	043 "[043]Familieneigene Landarbeitskr."
	044 "[044]Tierpfleger, verw. Berufe"
	051 "[051]Gaertner, Gartenarbeiter"
	052 "[052]Gartenarchitekten, Gartenverw."
	053 "[053]Floristen"
	061 "[061]Forstverwalter, Foerster, Jaeger"
	062 "[062]Waldarbeiter, Waldnutzer"
	071 "[071]Bergleute"
	072 "[072]Maschinen-, Elektro-, Schiessh."
	081 "[081]Steinbrecher"
	082 "[082]Erden-, Kies-, Sandgewinner"
	083 "[083]Erdoel-, Erdgasgewinner"
	091 "[091]Mineralaufbereiter, -brenner"
	101 "[101]Steinbearbeiter"
	102 "[102]Edelsteinbearbeiter"
	111 "[111]Branntsteinhersteller"
	112 "[112]Formstein-, Betonhersteller"
	121 "[121]Keramiker"
	131 "[131]Glasmassehersteller"
	132 "[132]Hohlglasmacher"
	133 "[133]Flachglasmacher"
	134 "[134]Glasblaeser (vor der Lampe)"
	135 "[135]Glasbearbeiter, Glasveredler"
	141 "[141]Chemiebetriebswerker"
	142 "[142]Chemielaborwerker"
	143 "[143]Gummihersteller, -verarbeiter"
	144 "[144]Vulkaniseure"
	151 "[151]Kunststoffverarbeiter"
	161 "[161]Papier-, Zellstoffhersteller"
	162 "[162]Verpackungsmittelhersteller"
	163 "[163]Buchbinderberufe"
	164 "[164]Sonstige Papierverarbeiter"
	171 "[171]Schriftsetzer"
	172 "[172]Druckstockhersteller"
	173 "[173]Buchdrucker (Hochdruck)"
	174 "[174]Flach-, Tiefdrucker"
	175 "[175]Spezialdrucker, Siebdrucker"
	176 "[176]Vervielfaeltiger"
	177 "[177]Druckerhelfer"
	181 "[181]Holzaufbereiter"
	182 "[182]Holzverformer, zugeh. Berufe"
	183 "[183]Holzwarenmacher"
	184 "[184]Korb-, Flechtwarenmacher"
	191 "[191]Eisen-, Metallerz., Schmelzer"
	192 "[192]Walzer"
	193 "[193]Metallzieher"
	201 "[201]Former, Kernmacher"
	202 "[202]Formgiesser"
	203 "[203]Halbzeugputzer, verw. Berufe"
	211 "[211]Blechpresser, -zieher"
	212 "[212]Drahtverformer, -verarbeiter"
	213 "[213]Sonstige Metallverformer"
	221 "[221]Dreher"
	222 "[222]Fraeser"
	223 "[223]Hobler"
	224 "[224]Bohrer"
	225 "[225]Metallschleifer"
	226 "[226]Uebrige spanende Berufe"
	231 "[231]Metallpolierer"
	232 "[232]Graveure, Ziseleure"
	233 "[233]Metallvergueter"
	234 "[234]Galvaniseure, Metallfaerber"
	235 "[235]Emaillierer, Feuerverzinker"
	241 "[241]Schweisser, Brennschneider"
	242 "[242]Loeter"
	243 "[243]Nieter"
	244 "[244]Uebrige Metallverbinder"
	251 "[251]Stahlschmiede"
	252 "[252]Behaelterbauer, Kupferschmiede"
	261 "[261]Feinblechner"
	262 "[262]Rohrinstallateure"
	263 "[263]Rohrnetzbauer, Rohrschlosser"
	270 "[270]Schlosser, o.n.A."
	271 "[271]Bauschlosser"
	272 "[272]Blech-, Kunststoffschlosser"
	273 "[273]Maschinenschlosser"
	274 "[274]Betriebs-, Reparaturschlosser"
	275 "[275]Stahlbauschl., Eisenschiffb."
	281 "[281]Kraftfahrzeuginstandsetzer"
	282 "[282]Landmaschineninstandsetzer"
	283 "[283]Flugzeugmechaniker"
	284 "[284]Feinmechaniker"
	285 "[285]Sonstige Mechaniker"
	286 "[286]Uhrmacher"
	291 "[291]Werkzeugmacher"
	301 "[301]Metallfeinbauer, a.n.g."
	302 "[302]Edelmetallschmiede"
	303 "[303]Zahntechniker"
	304 "[304]Augenoptiker"
	305 "[305]Musikinstrumentenbauer"
	306 "[306]Puppenmacher, Modellbauer"
	311 "[311]Elektroinstallateure, -monteur"
	312 "[312]Fernmeldemonteure, -handwerker"
	313 "[313]E-Motoren-, Trafo-Bauer"
	314 "[314]Elektrogeraetebauer"
	315 "[315]Funk-, Tongeraetemechaniker"
	321 "[321]Elektrogeraete-, Elektroteilemo"
	322 "[322]Sonstige Montierer"
	323 "[323]Metallarbeiter, o.n.A."
	331 "[331]Spinner, Spinnvorbereiter"
	332 "[332]Spuler, Zwirner, Seiler"
	341 "[341]Webvorbereiter"
	342 "[342]Weber"
	343 "[343]Tuftingwarenmacher"
	344 "[344]Maschenwarenfertiger"
	345 "[345]Filzmacher, Hutstumpenmacher"
	346 "[346]Textilverflechter"
	351 "[351]Schneider"
	352 "[352]Oberbekleidungsnaeher"
	353 "[353]Waescheschneider, Waeschenaeher"
	354 "[354]Sticker"
	355 "[355]Hut-, Muetzenmacher"
	356 "[356]Naeher, a.n.g."
	357 "[357]Sonstige Textilverarbeiter"
	361 "[361]Textilfaerber"
	362 "[362]Textilausruester"
	371 "[371]Lederhersteller, Darmsaitenm."
	372 "[372]Schuhmacher"
	373 "[373]Schuhwarenhersteller"
	374 "[374]Groblederwarenhersteller"
	375 "[375]Feinlederwarenhersteller"
	376 "[376]Lederbekleidungshersteller und"
	377 "[377]Handschuhmacher"
	378 "[378]Fellverarbeiter"
	391 "[391]Backwarenhersteller"
	392 "[392]Konditoren"
	401 "[401]Fleischer"
	402 "[402]Fleisch-, Wurstwarenhersteller"
	403 "[403]Fischverarbeiter"
	411 "[411]Koeche"
	412 "[412]Konservierer, - Zubereiter"
	421 "[421]Weinkuefer"
	422 "[422]Brauer, Maelzer"
	423 "[423]Sonstige Getraenkehersteller"
	424 "[424]Tabakwarenmacher"
	431 "[431]Milch-, Fettverarbeiter"
	432 "[432]Mehl-, Naehrmittelhersteller"
	433 "[433]Zucker-, Suesswaren-, Speiseeis"
	441 "[441]Maurer"
	442 "[442]Betonbauer"
	451 "[451]Zimmerer"
	452 "[452]Dachdecker"
	453 "[453]Geruestbauer"
	461 "[461]Pflasterer, Steinsetzer"
	462 "[462]Strassenbauer"
	463 "[463]Gleisbauer"
	464 "[464]Sprengmeister"
	465 "[465]Kultur-, Wasserbauwerker"
	466 "[466]Sonstige Tiefbauer"
	470 "[470]Bauhilfsarbeiter"
	471 "[471]Erdbewegungsarbeiter"
	472 "[472]Sonstige Bauhilfsarbeiter"
	481 "[481]Stukkateure, Gipser, Verputzer"
	482 "[482]Isolierer, Abdichter"
	483 "[483]Fliesenleger"
	484 "[484]Ofensetzer, Luftheizungsbauer"
	485 "[485]Glaser"
	486 "[486]Estrich-, Terrazzoleger"
	491 "[491]aumausstatter"
	492 "[492]Polsterer, Matratzenhersteller"
	501 "[501]Tischler"
	502 "[502]Modelltischler, Formentischler"
	503 "[503]Stellmacher, Boettcher"
	504 "[504]Sonstige Holz-, Sportgeraeteb."
	511 "[511]Maler, Lackierer (Ausbau)"
	512 "[512]Warenmaler, -lackierer"
	513 "[513]Holzoberflaechenveredler, Furni"
	514 "[514]Kerammaler, Glasmaler"
	521 "[521]Warenpruefer, -sortierer, a.n.g"
	522 "[522]Warenaufm., Versandfertigm."
	531 "[531]Hilfsarbeiter ohne Angabe"
	541 "[541]Energiemaschinisten"
	542 "[542]Foerder-, Seilbahnmaschinisten"
	543 "[543]Sonstige Maschinisten"
	544 "[544]Kranfuehrer"
	545 "[545]Erdbewegungsmaschinenfuehrer"
	546 "[546]Baumaschinenfuehrer"
	547 "[547]Maschinenwaerter"
	548 "[548]Heizer"
	549 "[549]Maschineneinrichter, o.n.A."
	601 "[601]Ingenieure des Maschinen- und"
	602 "[602]Elektroingenieure"
	603 "[603]Architekten, Bauingenieure"
	604 "[604]Vermessungsingenieure"
	605 "[605]Bergbau-, Huetten-, Giessereiing"
	606 "[606]Uebrige Fertigungsingenieure"
	607 "[607]Sonstige Ingenieure"
	611 "[611]Chemiker, Chemieingenieure"
	612 "[612]Physiker, Physikingenieure"
	621 "[621]Maschinenbautechniker"
	622 "[622]Techniker des Elektofaches"
	623 "[623]Bautechniker"
	624 "[624]Vermessungstechniker"
	625 "[625]Bergbau-, Huettentechniker"
	626 "[626]Chemietechniker"
	627 "[627]Uebrige Fertigungstechniker"
	628 "[628]Sonstige Techniker"
	629 "[629]Industriemeister, Werkmeister"
	631 "[631]Biologisch-technische Sfk"
	632 "[632]PT und MT Sfk"
	633 "[633]Chemielaboranten"
	634 "[634]Photolaboranten"
	635 "[635]Technische Zeichner"
	681 "[681]Gross- und Einzelhandelskaufl."
	682 "[682]Verkaeufer"
	683 "[683]Verlagskaufleute, Buchhaendler"
	684 "[684]Drogisten"
	685 "[685]Apothekenhelferinnen"
	686 "[686]Tankwarte"
	687 "[687]Handelsvertreter, Reisende"
	688 "[688]Ambulante Haendler"
	691 "[691]Bankfachleute"
	692 "[692]Bausparkassenfachleute"
	693 "[693]Krankenversicherungsfachleute"
	694 "[694]Versicherungsfachleute"
	701 "[701]Speditionskaufleute"
	702 "[702]Fremdenverkehrsfachleute"
	703 "[703]Werbefachleute"
	704 "[704]Makler, Grundstuecksverwalter"
	705 "[705]Vermieter, Vermittler, Verstei"
	706 "[706]Geldeinnehmer, -auszahler, Kar"
	711 "[711]Schienenfahrzeugfuehrer"
	712 "[712]Eisenbahnbetriebsregler"
	713 "[713]Sonstige Fahrbetriebsregler"
	714 "[714]Kraftfahrzeugfuehrer"
	715 "[715]Kutscher"
	716 "[716]Strassenwarte"
	721 "[721]Nautiker"
	722 "[722]Technische Schiffsoffiziere"
	723 "[723]Decksleute (Seeschiffahrt)"
	724 "[724]Binnenschiffer"
	725 "[725]Sonstige Wasserverkehrsberufe"
	726 "[726]Luftverkehrsberufe"
	731 "[731]Posthalter"
	732 "[732]Postverteiler"
	733 "[733]Funker"
	734 "[734]Telefonisten"
	741 "[741]Lagerverwalter, Magaziner"
	742 "[742]Transportgeraetefuehrer"
	743 "[743]Stauer, Moebelpacker"
	744 "[744]Lager-, Transportarbeiter"
	751 "[751]Unternehmer, Geschaeftsfuehrer"
	752 "[752]Unternehmensberater"
	753 "[753]Wirtschaftspruefer, Steuerber."
	761 "[761]Abgeordnete, Minister"
	762 "[762]Leitende und administrativ Vfl"
	763 "[763]Verbandsleiter, Funktionaere"
	771 "[771]Kalkulatoren, Berechner"
	772 "[772]Buchhalter"
	773 "[773]Kassierer"
	774 "[774]Datenverarbeitungsfachleute"
	781 "[781]Buerofachkraefte"
	782 "[782]Stenographen, Stenotypisten"
	783 "[783]Datentypisten"
	784 "[784]Buerohilfskraefte"
	791 "[791]Werkschutzleute, Detektive"
	792 "[792]Waechter, Aufseher"
	793 "[793]Pfoertner, Hauswarte"
	794 "[794]Haus-, Gewerbediener"
	801 "[801]Soldaten, Grenzschutz, Polizei"
	802 "[802]Berufsfeuerwehrleute"
	803 "[803]Sicherheitskontrolleure"
	804 "[804]Schornsteinfeger"
	805 "[805]Gesundheitssichernde Berufe"
	811 "[811]Rechtsfinder"
	812 "[812]Rechtspfleger"
	813 "[813]Rechtsvertreter, -berater"
	814 "[814]Rechtsvollstrecker"
	821 "[821]Publizisten"
	822 "[822]Dolmetscher, UEbersetzer"
	823 "[823]Bibliothekare, Archivare"
	831 "[831]Musiker"
	832 "[832]Darstellende Kuenstler"
	833 "[833]Bildende Kuenstler, Graphiker"
	834 "[834]Dekorationen-, Schildermaler"
	835 "[835]Kuenstlerische, verw. Berufe"
	836 "[836]Raum-, Schauwerbegestalter"
	837 "[837]Photographen"
	838 "[838]Artisten, Berufssportler, kuens"
	841 "[841]Aerzte"
	842 "[842]Zahnaerzte"
	843 "[843]Tieraerzte"
	844 "[844]Apotheker"
	851 "[851]Heilpraktiker"
	852 "[852]Masseure, verw. Berufe"
	853 "[853]Krankenschwestern, -pfleger"
	854 "[854]Helfer in der Krankenpflege"
	855 "[855]Diaetassistenten"
	856 "[856]Sprechstundenhelfer"
	857 "[857]Medizinallaboranten"
	861 "[861]Sozialarbeiter, Sozialpfleger"
	862 "[862]Heimleiter, Sozialpaedagogen"
	863 "[863]Arbeits-, Berufsberater"
	864 "[864]Kindergaertnerinnen, Kinderpfle"
	871 "[871]Hochschullehrer"
	872 "[872]Gymnasiallehrer"
	873 "[873]Real-, Volks-, Sonderschull."
	874 "[874]Fachschul-, Berufsschulehrer"
	875 "[875]Lehrer fuer musische Faecher"
	876 "[876]Sportlehrer"
	877 "[877]Sonstige Lehrer"
	881 "[881]Wirtsch.- und Sozialwissensch."
	882 "[882]Geisteswissenschaftler, a.n.g."
	883 "[883]Naturwissenschaftler, a.n.g."
	888 "[888]Pflegepersonen"
	891 "[891]Seelsorger"
	892 "[892]Angehoerige geistlicher Orden"
	893 "[893]Seelsorge-, Kulthelfer"
	901 "[901]Friseure"
	902 "[902]Sonstige Koerperpfleger"
	911 "[911]Gastwirte, Hoteliers"
	912 "[912]Kellner, Stewards"
	913 "[913]Uebrige Gaestebetreuer"
	921 "[921]Hauswirtschaftsverwalter"
	922 "[922]Verbraucherberater"
	923 "[923]Hauswirtschaftliche Betreuer"
	924 "[924]Haushaltshilfe"
	931 "[931]Waescher, Plaetter"
	932 "[932]Textilreiniger, Faerber und Che"
	933 "[933]Raum-, Hausratreiniger"
	934 "[934]Glas-, Gebaeudereiniger"
	935 "[935]Strassenreiniger"
	936 "[936]Fahrzeugreiniger, -pfleger"
	937 "[937]Maschinen-, verw. Berufe"
	971 "[971]Mithelfende Familienangehoerige"
	981 "[981]Auszubildende o. Berufsang."
	982 "[982]Praktikanten, Volontaere"
	983 "[983]Arbeitskraefte (arbeitsuchend)"
	991 "[991]Arbeitskraefte ohne naehere Taeti"
	995 "[995]Vorruhestand u.ae."
	996 "[996]Altersteilzeit"
	997 "[997]Ausgleichsgeldbezieher"
	999 "[999]Ohne Angabe"
	555 "[555]Behinderte"
	;
	label values beruford beruford;
	label var beruford "occupation";

	* label job type variable
	label var pers_gr "job type (legal classification, fine)";
	label define pers_gr 101 "sozverspfl Beschäft o. bes Merkmale" 102 "Auszubildende" 103 "Beschäft in Altersteilzeit" 104 "Hausgewerbetreibende" 105 "Praktikanten" 106 "Werkstudenten" 107 "Behinderte in anerk Werkstätten" 108 "Bezieher v. Vorruhestandsgeld" 109 "Gfgg entlohnte Beschäft" 111 "Pers in Einricht d. Jugendhilfe u.ä." 112 "Mitarb Fam.Ang. in der Landwirt" 113 "Nebenerwerbslandwirte" 114 "Nebenerwerbslandwirte (saisonal)" 116 "Ausgleichsgeldempf" 118 "Unständig Beschäft" 119 "Versfreie Altersvollrentner" 120 "Pers mit vermuteter Beschäft" 140 "Seeleute" 141 "Azubis in der Seefahrt" 142 "Seeleute in Altersteilzeit" 143 "Seelotsen" 201 "KSK: verspfl Beschäft" 203 "KSK: verspfl Künstler + Publizisten" 204 "KSK: Teilnehmer an Leistungen" 205 "KSK: Unständig Beschäft" 207 "KSK: Pflegepers ohne Beihilfeberecht" 208 "KSK: Pflegepers mit Beihilfeberecht" 209 "KSK: Gfgg entlohnte Beschäft" 301 "Grundwehrdienstleistende" 302 "Wehrübungsleist" 303 "Zivis" 304 "frw soz/öko Jahr" ;
	label values pers_gr pers_gr;
	#delimit cr

	* label other variables
	label define sex 1 "men"
	label values sex sex
	label var sex "sex"
	label var bnr "ID for Establishment"
	label var vsnr "ID for Worker"
	label var estsize "establishment size (missing in data)"

	* Recode variable names and label variables
	**********************************************************
	replace pers_gr = .  if pers_gr<0
	replace beruford = . if beruford == 999
	replace berufstg = . if berufstg < 0
	label var berufstg "job type (full-time<=7, part-time>7)"

	ren alter age
	label var age "age"

	ren wz73 w73
	replace w73 = . if w73<0 | w73>=999
	label var w73  "industry classification 73"
	replace wz03 = . if wz03<0 | wz03>99003 
	label var wz03 "industry classification 2003"

	ren staat nation
	label var nation "nationality"
	replace nation = . if nation>990 | nation < 0

	* Sample selection rules
	**********************************************************
	
	* Drop individuals that we do not need in any sample 
	drop if age<18 | age>65  						// Keep individuals aged 18-65. 
	keep if pers_gr==101 		 					// Keep those normally employed, drop apprentices and marginally employed (since covered only from 1999, with code pers_gr==109)

	* Drop if citizenship information missing (only few people affected)
	drop if nation == .
	
	* Save yearly file
	**********************************************************

	gen year=`y'
	keep vsnr year ao_kreis age nation berufstg imp_lnwcino pers_gr edu sex ausbild beruford
	compress
	save "${OUT}status`y'_JEP.dta", replace	

}

* Combine and save yearly files
**********************************************************	
use 	   "${OUT}status${startyear}_JEP.dta" , clear
cap erase  "${OUT}status${startyear}_JEP.dta"
foreach y of numlist $startyearplus/$endyear {
	des
	di c(current_date)
	di c(current_time)
	append using "${OUT}status`y'_JEP.dta"
	cap erase 	"${OUT}status`y'_JEP.dta"
}	


* National dummies
gen foreign= (nation!=0)
replace foreign=. if nation==.
label variable foreign "Indicator for foreign national"
gen native = (nation==0)
replace native=. if nation==.
label variable native "Indicator for native national"

save "${OUT}JEP_all.dta" , replace

	
**********************************************************
* Position in wage distribution	
**********************************************************
use "${OUT}JEP_all.dta" , replace

* keep only full-time employed
drop if berufstg<=0 | berufstg>7		

* keep only age 18-65
keep if age>=18 & age<=65

* Drop if we have no info on wages or education  
drop if imp_lnwcino==.
drop if edu==.

* Rename wage variable
ren imp_lnwcino lnw

* Rename occupation variable
ren beruford occ

* Once tagged as foreign -> foreign
sort vsnr year
by vsnr: egen foreignmax=max(foreign)
compare foreignmax foreign
drop foreign
ren foreignmax foreign
drop native

* Tag time of arrival (in data)
sort vsnr year
by vsnr: gen  firstyear_=year if _n==1
by vsnr: egen firstyear=max(firstyear)
drop firstyear_

* Classify immigrants by time of arrival
gen immclass = .
replace immclass = 1 if foreign==1 & year-firstyear<=2
replace immclass = 2 if foreign==1 & year-firstyear> 2 & year-firstyear<=5
replace immclass = 3 if foreign==1 & year-firstyear> 5 & year-firstyear<=10
replace immclass = 4 if foreign==1 & year-firstyear> 10 & year-firstyear!=.

label var immclass "time since arrival in data"
label def immclass 1 "0-2 years" 2 "3-5 years" 3 "6-10 years" 4 "more than 10 years"
label val immclass immclass  

* Tag natives and immigrants
gen x=1 if foreign==0
replace x=0 if foreign==1

* Keep year 2000
keep if year==2000
local yrlbl =  "year2000"

* actual position of migrants and low/highly educated natives
sort year lnw
by year: gen rank=sum(x)
by year: egen totwage=sum(x)
gen natbel= rank/ totwage

* evidence for downgrading in stock of immigrants? 
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign  // 5.7% gap

* evidence for downgrading among recent or previous immigrants? 
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign if foreign==0 | immclass==1   // 17.9% gap
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign if foreign==0 | immclass==2   // 8.3% gap
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign if foreign==0 | immclass==3   // 6.1% gap
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign if foreign==0 | immclass==4   // 0.0% gap

* evidence for downgrading among recent or previous immigrants? condition on entry year also for natives 
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign if (foreign==0 & year-firstyear<=2) | immclass==1   // -3.9% gap
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign if (foreign==0 & year-firstyear> 2 & year-firstyear<=5) | immclass==2   // -5.8% gap
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign if (foreign==0 & year-firstyear> 5 & year-firstyear<=10) | immclass==3   // -5.3% gap
reg lnw age c.age#c.age sex i.edu i.edu#c.age foreign if (foreign==0 & year-firstyear> 10 & year-firstyear!=.) | immclass==4   // -3.7% gap

* Generate age categories 
recode age (18/25=1) (26/35=2) (36/45=3) (46/55=4) (56/65=5), gen (agecat)   
label define agecat 1 "18/25" 2 "26/35" 3 "36/45" 4 "46/55" 5 "56/65" , replace
label val agecat agecat

recode age (18/40=1) (41/65=2) , gen (agecat2)  
label define agecat2 1 "18/40" 2 "41/65" , replace
label val agecat2 agecat2

* Education: 2 categories
gen edu2 = edu
replace edu2 = 2 if edu==3

* Education in years
gen schooling = 0
replace schooling = 10   if ausbild==0
replace schooling = 13   if ausbild==1 | ausbild==3
replace schooling = 12.5 if ausbild==2
replace schooling = 15   if ausbild==4
replace schooling = 16   if ausbild==5
replace schooling = 18   if ausbild==6

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


* Wage regression and prediction

gen sigma_sqaux=.
gen resid=.

quietly sum year
local ymin=r(min)
local ymax=r(max)
forvalues i=`ymin'(1)`ymax' {
	forvalues k = 1/2 {
        regress lnw i.agecat i.edu i.edu#i.agecat if sex==`k'& year==`i' & foreign==0, robust		
        predict pldhw_`k'_`i' if year==`i' & sex==`k'
		predict sigma if e(sample), resid
		replace sigma_sqaux=sigma^2 if year==`i' & sex==`k'
        drop sigma
	        }
	}

forvalues i=`ymin'(1)`ymax' {
	forvalues k=1/2 {
            if `i'==`ymin' &`k'==1 {
				gen lnPredWage = pldhw_`k'_`i'
		    }
            else {
				replace lnPredWage= pldhw_`k'_`i' if year==`i' & sex==`k'
                drop pldhw_`k'_`i' 
		    }
	}
}

quietly sum agecat
local agemin=r(min)
local agemax=r(max)

quietly sum edu
local edumin=r(min)
local edumax=r(max)

sort vsnr
gen lnPredWageX=.
set seed 1234
forvalues i=`agemin'/`agemax' {
	forvalues k=1/2 {
		forvalues j=`edumin'/`edumax' {
			sum sigma_sqaux if agecat==`i' & sex==`k' & edu==`j'
		      matrix S = sqrt(r(mean))
      		drawnorm X, means(0) sds(S)
      		replace lnPredWageX=(lnPredWage + X) if agecat==`i' & sex==`k' & edu==`j'
			drop X
			}
		}
	}

	
drop if lnPredWageX==.

* predicted + X position of migrants
replace lnPredWageX=lnw if foreign==0  // use actual instead of predicted wages for natives
sort year lnPredWageX
by year: gen rank_pred=sum(x)
gen natbel_pred= rank_pred/ totwage

* predicted position of migrants
sort year lnPredWage 
by year: gen rank_predNoX=sum(x)
gen natbel_predNoX= rank_predNoX/ totwage
drop rank* totwage	

/*Prepare the log odd ratio (see footnote 17 in DFP 2013) */
gen immpos=log(natbel/(1-natbel))
gen immpos_pred=log(natbel_pred/(1-natbel_pred))
gen immpos_predNoX=log(natbel_predNoX/(1-natbel_predNoX))

/*Generate the values at which the density should be estimated*/
gen percentile=_n
replace percentile=. if percentile>=100
gen pctile=percentile/100
gen pctiletrans=log(pctile/(1-pctile))

save "${OUT}GER_tmp.dta" , replace

	
************************************
******	ACTUAL WAGES	******
************************************

/*Estimation*/
kdensity immpos if foreign==1  , generate (perc_imm dens_imm) nograph at(pctiletrans)
kdensity immpos if immclass==1 , generate (perc_immclass1 dens_immclass1) nograph at(pctiletrans)
kdensity immpos if immclass==2 , generate (perc_immclass2 dens_immclass2) nograph at(pctiletrans)
kdensity immpos if immclass==3 , generate (perc_immclass3 dens_immclass3) nograph at(pctiletrans)
kdensity immpos if immclass==4 , generate (perc_immclass4 dens_immclass4) nograph at(pctiletrans)

kdensity immpos_pred if foreign==1  , generate (perc_imm_pred dens_imm_pred) nograph at(pctiletrans)
kdensity immpos_pred if immclass==1 , generate (perc_immclass1_pred dens_immclass1_pred) nograph at(pctiletrans)
kdensity immpos_pred if immclass==2 , generate (perc_immclass2_pred dens_immclass2_pred) nograph at(pctiletrans)
kdensity immpos_pred if immclass==3 , generate (perc_immclass3_pred dens_immclass3_pred) nograph at(pctiletrans)
kdensity immpos_pred if immclass==4 , generate (perc_immclass4_pred dens_immclass4_pred) nograph at(pctiletrans)

kdensity immpos_predNoX if foreign==1  , generate (perc_imm_predNoX dens_imm_predNoX) nograph at(pctiletrans)
kdensity immpos_predNoX if immclass==1 , generate (perc_immclass1_predNoX dens_immclass1_predNoX) nograph at(pctiletrans)


/*Apply the transformation to the estimates (scale densities by derivative of log(pctile/(1-pctile))*/
gen density_imm=dens_imm/(pctile*(1-pctile))
gen density_immclass1=dens_immclass1/(pctile*(1-pctile))
gen density_immclass2=dens_immclass2/(pctile*(1-pctile))
gen density_immclass3=dens_immclass3/(pctile*(1-pctile))
gen density_immclass4=dens_immclass4/(pctile*(1-pctile))

gen density_imm_pred=dens_imm_pred/(pctile*(1-pctile))
gen density_immclass1_pred=dens_immclass1_pred/(pctile*(1-pctile))
gen density_immclass2_pred=dens_immclass2_pred/(pctile*(1-pctile))
gen density_immclass3_pred=dens_immclass3_pred/(pctile*(1-pctile))
gen density_immclass4_pred=dens_immclass4_pred/(pctile*(1-pctile))

gen density_imm_predNoX=dens_imm_predNoX/(pctile*(1-pctile))
gen density_immclass1_predNoX=dens_immclass1_predNoX/(pctile*(1-pctile))

*******************************
******	GRAPHS	*******
*******************************
/*Plot*/
gen one=1
label var percentile "Percentile of non-immigrant wage distribution"
label var density_imm "Foreign workers"
label var density_immclass1 "Foreign <=2 years"
label var density_immclass2 "Foreign 3-5 years"
label var density_immclass3 "Foreign 6-10 years"
label var density_immclass4 "Foreign >10 years"
label var density_imm_pred "Foreign predicted"
label var density_immclass1_pred "Foreign <=2 years predicted"
label var density_immclass2_pred "Foreign 3-5 years predicted"
label var density_immclass3_pred "Foreign 6-10 years predicted"
label var density_immclass4_pred "Foreign >10 years predicted"
label var one "Non-immigrant"
label var density_imm_predNoX "Foreign predicted no X"
label var density_immclass1_predNoX "Foreign <=2 years predicted no X"

/*Actual vs Predicted*/
twoway ///
	(line density_imm percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///	
	(line density_imm_pred percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in native wage distribution) scheme(s1mono) note("Source: IABS 2% sample, year 2000.") 
qui graph export ${LOG}immwagedis_actual_pred.eps, replace
qui graph save   ${LOG}immwagedis_actual_pred.gph, replace

/*Figure 1c: Actual vs Predicted: recent*/
twoway ///
	(line density_immclass1 percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///	
	(line density_immclass1_pred percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in native wage distribution) scheme(s1mono) note("Source: IABS 2% sample, year 2000.") 
qui graph export ${LOG}immwagedis_actual_pred_recent.eps, replace
qui graph save   ${LOG}immwagedis_actual_pred_recent.gph, replace

/*Actual vs Predicted: nonrecent*/
/*
twoway ///
	(line density_immclass4 percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///	
	(line density_immclass4_pred percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in native wage distribution) scheme(s1mono) note("Source: IABS 2% sample, year 2000.") 
qui graph export ${LOG}immwagedis_actual_pred_nonrecent.eps, replace
qui graph save   ${LOG}immwagedis_actual_pred_nonrecent.gph, replace


/*Actual Classes*/
twoway ///
	(line density_immclass1 percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///
	(line density_immclass2 percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(yellow)) ///
	(line density_immclass3 percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(orange)) ///	
	(line density_immclass4 percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(red)) ///	
	(line density_imm_pred percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in native wage distribution) scheme(s1mono) note("Source: IABS 2% sample, year 2000.") 
qui graph export ${LOG}immwagedis_actual_pred_classes.eps, replace
qui graph save   ${LOG}immwagedis_actual_pred_classes.gph, replace

/*Predicted	w/o X positions */
twoway ///
	(line density_imm_predNoX percentile if percentile>4.5 & percentile<95.5, sort lpattern(longdash) lcolor(green)) ///	
	(line density_immclass1_predNoX percentile if percentile>4.5 & percentile<95.5, sort lpattern(line) lcolor(black)) ///						
	(line one percentile if percentile>4.5 & percentile<95.5, sort) ///
	, title(Position of Foreign workers in predicted wage distribution) scheme(s1mono) note("Source: IABS 2% sample, year 2000.") 
qui graph export ${LOG}immwagedis_pred_NoX.eps, replace
qui graph save   ${LOG}immwagedis_pred_NoX.gph, replace */


************************************
******	IMPUTATION PROCEDURE 
************************************

************************************
* Effective skill imputation: unconstrained version for Table 2 and Table A.1/A.2
************************************
use "${OUT}GER_tmp.dta" , replace

* Select immigrant subgroup
global subgroup = "recentimm"
keep if foreign==0 | immclass==1

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


* Estimate downgrading separately for each education and experience group

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
					gen mixture=`i'*sh_native_ed1_exp1 + `j'*sh_native_ed1_exp2 + `k'*sh_native_ed2_exp1 + (1-`i'-`j'-`k')*sh_native_ed2_exp2
					gen sqdiff = (sh_foreign_ed`edu'_exp`exp' - mixture)^2
					qui su sqdiff
					if r(mean)<sqdiffmin {
						di "with weight `i' `j' `k' sqdiff ..."

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
use "${OUT}GER_tmp.dta" , replace

* Select immigrant subgroup
global subgroup = "recentimm"
keep if foreign==0 | immclass==1

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

* Alternative: Constrained case with only two parameters 
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
				* di "with weight phiS `phiS' and phiE `phiE' sqdiff ..."
				
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
	
	
rm "${OUT}JEP_all.dta" 
rm "${OUT}GER_tmp.dta" 
