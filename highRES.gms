$ontext
option profile=1
$offtext
option limrow=0, limcol=0, solprint=OFF
$offlisting

* Switches:
* uktm_scen = which UKTM scenario
* area_scen = which VRE area scenario (disabled)
* storage = ON/OFF
* gdx2sql = ON/OFF
* year = year of weather data and demand
* outname = output gdx name if write is turned ON

$setglobal uktm_scen "NOCCS_renew30pc"
$setglobal RPS_scen "30"
$setglobal area_scen "norestriction"
$setglobal nuc_restrict "norestriction"
$setglobal water_restrict "norestriction"
$setglobal year "2006"
$setglobal outname "hR_%uktm_scen%_water_1.5_nuc%nuc_restrict%_area_%area_scen%_RPS_%RPS_scen%_%year%_bio2coal"
* $setglobal outname "hR_%uktm_scen%_water_%water_restrict%_nuc%nuc_restrict%_area_%area_scen%_RPS_%RPS_scen%_%year%"

$setglobal log ""

$setglobal water "OFF"
$setglobal storage "ON"
$setglobal gdx2sql "ON"

$onempty

$BATINCLUDE highres_data_input.gms

$IF "%storage%" == OFF   $GOTO nostorage
$BATINCLUDE highres_storage_setup.gms
$LABEL nostorage


scalar
RPS
/%RPS_scen%/
;
RPS=RPS/100.

scalar
emis_price
/0/
;

* UKTM capacities from GW to MW

uktm_gen_cap(g)=uktm_gen_cap(g)*1000.;

* Limit which regions a given VRE tech can be built in
* based on buildable area in that region. Stops offshore solar
* and onshore offshore wind.

set vre_lim(vre,z,r);
vre_lim(vre,z,r)=(area(vre,z,r)>0.);

* Non VRE cap lim to dynamic set, stops Nuclear being built in London

set non_vre_lim(z,non_vre);
non_vre_lim(z,non_vre)=(non_vre_cap_lim(z,non_vre)>0.);


* Buildable area per cell from km2 to MW capacity

area(vre,z,r)=area(vre,z,r)$(vre_lim(vre,z,r))*cap2area(vre);

* Fuel, varom and emission costs for non VRE generators;

generator_varom(non_vre)=fuelC(non_vre)+emis_fac(non_vre)*emis_price+generator_varom(non_vre);

* Penalty generation setup

generator_capex("pgen")=round(smax(g,generator_capex(g))*3.,1);
generator_varom("pgen")=round(smax(g,generator_varom(g))*10.,1);

* Solar marginal

generator_varom("Solar")=0.001;

Variables
costs total electricty system dispatch costs

Positive variables
var_vre_cap(vre)
var_vre_cap_z(z,vre) VRE capacity by zone and technology
var_vre_cap_r(z,vre,r) VRE capacity by region and technology
var_vre_gen(z,h,vre,r) VRE generation by region hour and technology

var_non_vre_cap(non_vre) Non_VRE capacity by technology
var_non_vre_cap_z(z,non_vre) Non_VRE capacity in each zone
var_non_vre_gen(z,h,non_vre) Non_VRE generation by hour and technology

*var_vre_curtail(z,h,vre,r)   Power curtailed
*var_non_vre_curtail(z,h,non_vre)

var_trans_flow(z,h,z_alias,trans) Flow of electricity from node to node by hour (MW)
var_trans_cap(z,z_alias,trans) Capacity of node to node transmission links (MW)

var_pgen(z,h)

;

*** Transmission set up ***

* Sets up bidirectionality of links

trans_links(z_alias,z,trans)$(trans_links(z,z_alias,trans))=trans_links(z,z_alias,trans);

trans_links_cap(z_alias,z,trans)$(trans_links_cap(z,z_alias,trans) > 0.)=trans_links_cap(z,z_alias,trans);

trans_links_dist(z,z_alias,trans)=trans_links_dist(z,z_alias,trans)/100.;

* Bidirectionality of link distances for import flow reduction -> both monodir and bidir needed,
* former for capex.

parameter trans_links_dist_bidir(z,z_alias,trans);

trans_links_dist_bidir(z,z_alias,trans)=trans_links_dist(z,z_alias,trans);
trans_links_dist_bidir(z_alias,z,trans)$(trans_links_dist(z,z_alias,trans) > 0.)=trans_links_dist(z,z_alias,trans);

* Set transmission capacities to National Grid current (2015) if not making investments
*var_trans_cap.FX(z,z_alias,trans) = trans_links_cap(z,z_alias,trans);


*******************************

var_non_vre_cap_z.UP(z,non_vre)=non_vre_cap_lim(z,non_vre)*1000.;



* Fix total capacities to UKTM input capacities

*set flex(g) / NaturalgasOCGTnew, Nuclear, Biomass /;

*var_non_vre_cap.FX(non_vre(g))$(not flex(g))=uktm_gen_cap(non_vre);
*var_non_vre_cap.FX(non_vre(g))$(not (pgen(g) or flex(g)))=uktm_gen_cap(non_vre);
*var_non_vre_cap.FX(non_vre(g))$(flex(g))=0. ;
*var_vre_cap.FX(vre)=uktm_gen_cap(vre);

*var_non_vre_cap.FX(non_vre(g))$(not flex(g))=uktm_gen_cap(non_vre);
*var_non_vre_cap.FX(non_vre)=uktm_gen_cap(non_vre);
*var_vre_cap.FX(vre)=uktm_gen_cap(vre);

* Sets to ensure ramp/mingen constraints are only created where relevant

set ramp_on(z,non_vre);
ramp_on(z,non_vre)=(max_ramp(non_vre) < 1.0 and max_ramp(non_vre) >0. and non_vre_lim(z,non_vre));

set mingen_on(z,non_vre);
mingen_on(z,non_vre)=(min_gen(non_vre) > 0. and non_vre_lim(z,non_vre));

set ramp_and_mingen(z,non_vre);
ramp_and_mingen(z,non_vre) = (ramp_on(z,non_vre) or mingen_on(z,non_vre));

$IF "%water%"==OFF $GOTO nowater

$BATINCLUDE highres_water_setup.gms

non_vre_lim(z,"BiomassOT")$(not water_lim(z))=NO;
non_vre_lim(z,"BiomassHy")$(not water_lim(z))=NO;
non_vre_lim(z,"BiomassCL")$(not water_lim(z))=NO;

$label nowater

Equations
eq_obj
eq_elc_balance

eq_gen_max
eq_gen_min
eq_cap_non_vre
*eq_cap_non_vre_z
eq_ramp_up
eq_ramp_down
*eq_curtail_max_non_vre

eq_gen_vre
eq_cap_vre
eq_cap_vre_z
*eq_curtail_max_vre
eq_area_max

eq_trans_flow
eq_trans_bidirect

eq_co2_intensity

eq_max_non_vre

;


******************************************
* OBJECTIVE FUNCTION

eq_obj .. costs =E=

* variable costs
sum((non_vre_lim(z,non_vre),h),var_non_vre_gen(z,h,non_vre)*generator_varom(non_vre))
+sum((vre_lim(vre,z,r),h),var_vre_gen(z,h,vre,r)*generator_varom(vre))

*+sum((trans_links(z,z_alias),h),var_trans_flow(z,h,z_alias,trans)*trans_varom(trans))

* annualised capital costs
+sum(non_vre,var_non_vre_cap(non_vre)*generator_capex(non_vre))
+sum(vre,var_vre_cap(vre)*generator_capex(vre))

+sum(trans_links(z,z_alias,trans),var_trans_cap(z,z_alias,trans)*trans_links_dist(z,z_alias,trans)*trans_capex(trans))

* storage costs
$IF "%storage%" == OFF   $GOTO skip1
+sum((s_lim(z,s),h),var_store_gen(z,h,s)*storage_varom(s))
+sum(s,var_store_gen_cap(s)*storage_gen_capex(s)+var_store_gen_cap(s)*store_gen_to_cap(s)*storage_cap_capex(s))
$label skip1

*+sum((z,h),var_pgen(z,h)*pgen_acost)

;
******************************************

******************************************
* SUPPLY-DEMAND BALANCE EQUATION (hourly)

eq_elc_balance(z,h) ..

* Generation
sum(non_vre_lim(z,non_vre),var_non_vre_gen(z,h,non_vre))
+sum(vre_lim(vre,z,r),var_vre_gen(z,h,vre,r))

* NonVRE Curtailment due to ramp rates
*-sum(non_vre,var_non_vre_curtail(z,h,non_vre))

* Transmission, import-export
-sum(trans_links(z,z_alias,trans),var_trans_flow(z_alias,h,z,trans))
+sum(trans_links(z,z_alias,trans),var_trans_flow(z,h,z_alias,trans)*(1-(trans_links_dist_bidir(z,z_alias,trans)*trans_loss(trans))))

$IF "%storage%" == OFF   $GOTO skip2
* Storage, generated-stored
-sum(s_lim(z,s),var_store(z,h,s))
+sum(s_lim(z,s),var_store_gen(z,h,s))
$label skip2

*+var_pgen(z,h)

=G= demand(z,h);

******************************************

*********************
*** VRE equations ***
*********************

* Curtailment of VRE - generation curtailed has to be less than or equal to current hourly generation

*eq_curtail_max_vre(z,h,vre)$vre_lim(vre,z,r) .. var_vre_curtail(z,h,vre) =E= sum(vre_lim(vre,z,r),vre_gen(vre,r,h)*var_vre_cap_r(z,vre,r)-var_vre_gen(z,h,vre,r));

* VRE generation is input data x capacity in each region

eq_gen_vre(vre_lim(vre,z,r),h) .. var_vre_gen(z,h,vre,r) =L= vre_gen(vre,r,h)*var_vre_cap_r(z,vre,r);

* VRE capacity across all zones must sum to be equal to national capacity of each technology

eq_cap_vre(vre) .. sum(vre_lim(vre,z,r),var_vre_cap_z(z,vre)) =E= var_vre_cap(vre);

* VRE capacity across all regions in a zone must be equal to capacity in that zone

eq_cap_vre_z(z,vre) .. sum(vre_lim(vre,z,r),var_vre_cap_r(z,vre,r)) =E= var_vre_cap_z(z,vre);

* VRE capacity in each region must be less than or equal to buildable area for each technology in that region

eq_area_max(vre_lim(vre,z,r)) .. var_vre_cap_r(z,vre,r) =L= area(vre,z,r);

* Equation for minimum renewable share of generation, set based on restricting non VRE generation.

scalar dem_tot;
dem_tot=sum((z,h),demand(z,h));

eq_max_non_vre .. sum((z,non_vre,h)$non_vre_lim(z,non_vre),var_non_vre_gen(z,h,non_vre)) =L= dem_tot*(1-RPS);


*************************
*** NON VRE equations ***
*************************

* Non VRE capacities across the zones must sum to total Non VRE cap

eq_cap_non_vre(non_vre) .. var_non_vre_cap(non_vre) =E= sum(non_vre_lim(z,non_vre),var_non_vre_cap_z(z,non_vre));

* Maximum generation of Non VRE

eq_gen_max(non_vre_lim(z,non_vre),h) .. var_non_vre_cap_z(z,non_vre)*avail_factor(non_vre) =G= var_non_vre_gen(z,h,non_vre) ;

* Minimum generation of Non VRE

eq_gen_min(mingen_on(z,non_vre),h) .. var_non_vre_gen(z,h,non_vre) =G= var_non_vre_cap_z(z,non_vre)*min_gen(non_vre);

* Ramp equations applied to Non VRE generation, characterised as fraction of total installed
* capacity per hour

eq_ramp_up(ramp_on(z,non_vre),h) .. var_non_vre_gen(z,h,non_vre) =L= var_non_vre_gen(z,h-1,non_vre)+max_ramp(non_vre)*var_non_vre_cap_z(z,non_vre) ;

eq_ramp_down(ramp_on(z,non_vre),h) .. var_non_vre_gen(z,h,non_vre) =G= var_non_vre_gen(z,h-1,non_vre)-max_ramp(non_vre)*var_non_vre_cap_z(z,non_vre) ;

* Non VRE curtailment due to ramping/min generation

*eq_curtail_max_non_vre(ramp_and_mingen(z,non_vre),h) .. var_non_vre_curtail(z,h,non_vre) =L= var_non_vre_gen(z,h,non_vre);

******************************
*** Transmission equations ***
******************************

* Transmitted electricity each hour must not exceed transmission capacity

eq_trans_flow(trans_links(z,z_alias,trans),h) .. var_trans_flow(z,h,z_alias,trans) =L= var_trans_cap(z,z_alias,trans);

* Bidirectionality equation is needed when investments into new links are made...I think :)

eq_trans_bidirect(trans_links(z,z_alias,trans)) ..  var_trans_cap(z,z_alias,trans) =E= var_trans_cap(z_alias,z,trans);

***********************
*** Misc. equations ***
***********************

* Rough CO2 intensity equation - needs to be improved

eq_co2_intensity .. sum((z,h,non_vre),var_non_vre_gen(z,h,non_vre)*emis_fac(non_vre))*1000/sum((z,h),demand(z,h)) =L= 4.4




Model Dispatch /all/;

Option LP = CPLEX;
$onecho > cplex.opt
lpmethod=4
threads=4
barcrossalg=-1
tilim=7200
baralg=1

barepcomp=1E-8

names no

scaind=1

ppriind=1

epmrk=0.99
eprhs=1E-3

predual=-1


$offecho
Dispatch.OptFile = 1;

* 12:18
* 11 min bar order=3 and baralg=1

*writelp="C:\science\highRES\work\highres.lp"

* 2003 flexgen+store baralg=2, scaind=1 optimal
* barepcomp=1E-8
* ppriind=1

Solve Dispatch minimizing costs using LP;

parameter trans_f(z,z_alias,h,trans);
trans_f(z,z_alias,h,trans)=var_trans_flow.l(z_alias,h,z,trans)$(var_trans_flow.l(z,h,z_alias,trans)>1.0);
*display trans_f;

parameter maxtrans;
maxtrans=smax((z,z_alias,h,trans),trans_f(z,z_alias,h,trans));
*display maxtrans;

parameter pgen_tot;
pgen_tot=sum((z,h),var_non_vre_gen.l(z,h,"pgen"));

$IF "%log%" == "" $GOTO nolog
scalar now,year,month,day,hour,minute;
now=jnow;
year=gyear(now);
month=gmonth(now);
day=gday(now);
hour=ghour(now);
minute=gminute(now);

file fname /"%log%"/;
put fname;
fname.ap=1;
put "%outname%"","day:0:0"/"month:0:0"/"year:0:0" "hour:0:0":"minute:0:0","Dispatch.modelStat:1:0","Dispatch.resUsd:0;
$LABEL nolog

$BATINCLUDE highres_results.gms

execute_unload "%outname%"

$IF "%gdx2sql%" == OFF   $GOTO nosql
execute "gdx2sqlite -i %outname%.gdx -o %outname%.db -fast"
$LABEL nosql





