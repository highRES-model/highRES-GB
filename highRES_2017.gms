$ontext
option profile=1
option limrow=0, limcol=0, solprint=OFF

VERSION NOTES:

highRES_uktmcap:
using uktm capacities and scaling offshore wind use up
uktmcap_2: set a limit on the depth of floating turbine sites in order to reduce LP size
uktmcap_3: remove pgen as the model will just use flex gen
uktmcap_4: remove curtailment and set vre_gen equation to less than rather than equals
uktmcap_5: reducing floating cost by hard coding
uktmcap_6: using switch to control the floating cost change
uktmcap_7: switch now controls mid depth cost
uktmcap_8: switch now controls shallow cost
uktmcap_9: switch no controls all offshore wind costs

2017_b: bringing wave tolerance into GAMS code as a switch - input file of significant wave height values in centimetres
2017_c: adding a renewable portfolio standard using Palminter et al approach
2017_d: redefine renewable portfolio standard by using maximum non-vre generation as a percentage of demand. nuclear added to flex list
2017_e: introduce transmission set and constant transmission loss mechanism
2017_f: windoff_waves parameter was very large and causing the output db to be massive.
         solved by redefining the parameter so that 0 means there is no interuption and 1 means there is shutdown.
         full rows/columns of zeros are not stored, so this saves a lot of file space
2017_g: results file is now set by a switch
2017_h: changing cred to fc_change (floating cost change). floating and mid depth cost scale factors should be the same in the .dd file
2017_k: added limits to floating areas to reduce LP size. depth, distance, and area
2017_l: redefine floating cost as an absolute % rather than an increase. this allows for under 100% costs to be applied
2017_m:

$offtext
$offlisting

$set area_scen "high"
$set storage "ON"

$set write "ON"
$set floating "ON"
$set wind_elec_loss "ON"
$set splitwind "ON"

$set inputfile "highres_data_input_b"
$set resultsfile "highRES_results_2017_f"

*if RPS_on is set ON, most generators are set to be 'flexible' - not taking uktm capacities
$set UKTMCAP "ON"


$set RPS_on "ON"
*$set RPS_val 90
*   fcost is the absolute % cost for floating relative to mid depths
*$set fcost 100
*$set waves "OFF"
*$set wave_tol 0

*purely for the sake of logs, if waves are off, wave tol is set to a large number. this large number is not used anywhere
$if "%waves%" == OFF $set wave_tol 10000


$setglobal year "2002"
$set outname "hR_m_%year%_waves%wave_tol%_RPS%RPS_val%_fcost%fcost%_newfuelcost"

*switch ON to use the fcost parameter relative to the Offshore_Mid capex. otherwise .dd input is used
$set floatcostfix "ON"

*limitations to reduce LP size by removing certain floating turbine areas
* fdepth in m. fdist in km from shore.
$set fdepth 1000
$set fdist 200

$if %RPS_on% == OFF $goto RPSoff1
scalar RPS / %RPS_val% /;
display RPS;
$label RPSoff1


*cred is cost reduction as a percentage



scalar w_tol;
w_tol = %wave_tol%;


$log results file: %resultsfile%
$log outname %outname%    year: %year%   waves: %waves%
$log wave_tol:%wave_tol%    RPS:%RPS_val%    floating_cost:%fcost% %



*turn off penalty generation completely. can help with numerical difficulties. sets penalty generation to zero
$set penalty_switch "OFF"

$log no maximum depth for floating turbines



$offdigit

$onempty

$BATINCLUDE %inputfile%.gms

generator_varom("Solar") = 0.001;
$log solar varom 0.001

scalar factor;
factor = ( %fcost%*0.01 );

*display generator_capex;
*display factor;
$IF "%floatcostfix%" == OFF $goto floatcostoriginal
generator_capex("Windoffshore_Floating")=generator_capex("Windoffshore_Mid")*factor;
$label floatcostoriginal
*display generator_capex;
*$stop

$IF "%storage%" == OFF   $GOTO nostorage
$BATINCLUDE highres_storage_setup.gms
$LABEL nostorage

$IF "%waves%" == OFF   $GOTO nowaves
*wave tolerance is applied to the raw wave file to fill out windoff_waves
windoff_waves(r,h)$(waves_raw(r,h)>w_tol) = 1;
windoff_waves(r,h)$(waves_raw(r,h)<=w_tol) = 0;

*CF for floating turbines is 0 when wave tolerance is breached, unchanged when below wave tolerance
vre_gen("Windoffshore_Floating",r,h) = vre_gen("Windoffshore_Floating",r,h)*(1 - windoff_waves(r,h));
$LABEL nowaves


*floating turbines are only allowed up to a certain depth, controlled here
*regions with a depth below that are set to zero in the area parameter
*the area parameter is later used to define vre_lim. by setting regions to zero the LP size is reduced
*this is not as accurate as defining the shapefiles, but it is more flexible in that it can be controlled within GAMS
parameter area_raw(vre,z,r);
area_raw(vre,z,r)=area(vre,z,r);

*****  reduce LP size by removing some floating areas
set float_depth_discard(r) regions to be discarded because of depth;
float_depth_discard(r) = (floating_depth(r)>%fdepth%);
area("Windoffshore_Floating",z,r)$float_depth_discard(r) = 0;
display float_depth_discard,floating_depth;

set float_dist_discard(r) regions to be discarded because of distance;
float_dist_discard(r) = (distance_to_shore(r)>%fdist%);
area("Windoffshore_Floating",z,r)$float_dist_discard(r) = 0;

*regions with less than 10km^2 are removed
area("Windoffshore_Floating",z,r)$(area("Windoffshore_Floating",z,r)<10) = 0;



$IF "%floating%" == ON $GOTO floating_on
*if floating turbines are set off, then all floating regions are set to zero
area("Windoffshore_Floating",z,r)=0;
$LABEL floating_on


*unless offshore wind electrical losses are set to OFF, the losses will be applied
$IF "%wind_elec_loss%" == OFF $GOTO no_wind_elec
vre_gen(vre_windoff,r,h) = vre_gen(vre_windoff,r,h) *  windoff_elec(r);
$LABEL no_wind_elec

*display vre_gen



Scalar
emis_price
/0/

*penalty  expensive generation- if not supplied by the network for the model to run
*/0/
;

hfirst(h) = yes$(ord(h) eq 1) ;
hlast(h) = yes$(ord(h) eq card (h));

* UKTM capacities from GW to MW

uktm_gen_cap(g)=uktm_gen_cap(g)*1000.;

* Limit which regions a given VRE tech can be built in
* based on buildable area in that region. Stops offshore solar
* and onshore offshore wind.

* Reduce area file to single bottom mounted offshore wind technology
$if "%splitwind%" == ON  $goto separatewind
* aggregate mid and shallow areas to the shallow technology
area("Windoffshore_Shallow",z,r) = area("Windoffshore_Shallow",z,r)+area("Windoffshore_Mid",z,r);
* set mid and floating areas to zero to remove them from the model
area("Windoffshore_Mid",z,r)=0;
area("Windoffshore_Floating",z,r)=0;
* set the scale cost to 1 so that the uktm annual cost value is used
offwind_cost_scale("Windoffshore_Shallow")=1;
$label separatewind

*** CAPEX values for offshore wind are initially loaded as the UKTM 2050 value
* then they are scaled using offwind_cost_scale
generator_capex(vre_windoff) = generator_capex(vre_windoff) * offwind_cost_scale(vre_windoff);

display area;



set vre_lim(vre,z,r);
vre_lim(vre,z,r)=(area(vre,z,r)>0);
display vre_lim;


* Non VRE cap lim to dynamic set, stops Nuclear being built in London

set non_vre_lim(z,non_vre);
non_vre_lim(z,non_vre)=(non_vre_cap_lim(z,non_vre)>0.);

* Buildable area per cell from km2 to MW capacity

area(vre,z,r)=area(vre,z,r)$(vre_lim(vre,z,r))*cap2area(vre);
display area;
*$stop
* Fuel, varom and emission costs for non VRE generators;

generator_varom(non_vre)=fuelC(non_vre)+emis_fac(non_vre)*emis_price+generator_varom(non_vre)

Variables
costs total electricty system dispatch costs

Positive variables
var_vre_cap(vre) UKTM-listed VRE capacities (aggregated offshore wind)
var_vre_cap_z(z,vre) VRE capacity by zone and technology
var_vre_cap_r(z,r,vre) VRE capacity by region and technology
var_vre_gen(z,h,vre,r) VRE generation by region hour and technology

var_non_vre_cap(non_vre) Non_VRE capacity by technology
var_non_vre_cap_z(z,non_vre) Non_VRE capacity in each zone
var_non_vre_gen(z,h,non_vre) Non_VRE generation by hour and technology

*var_vre_curtail(z,h,vre)   Power curtailed

*var_non_vre_curtail(z,h,non_vre)

var_trans_flow(z,h,z_alias,trans) Flow of electricity from node to node by hour (MW)
var_trans_cap(z,z_alias,trans) Capacity of node to node transmission links (MW)


*p_gen(z,h) Penalty generation in hour h

;

$ontext
integer variable  int(r,vre);
int.up(r,vre) = 10000000;


set flex(g) / Nuclear /;
var_non_vre_cap.FX(non_vre(g))$(not flex(g))=uktm_gen_cap(non_vre);
$offtext

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


*set transmission capacities to National Grid current (2015) if not making investments
*var_trans_cap.FX(z,z_alias) = trans_links_cap(z,z_alias);

*******************************

*set vre_on(g) /Windonshore,Windoffshore/;
*set vre_off(g) / Solar/;
*set g_off(g) /Geothermal,Tidal,Wave,Hydro,Biomass,
*BiomassCCS,HydrogenOCGTnew,HydrogenCCGTnew/;
*set fx_off(g) /NaturalgasCCGTnew/;

* Fix total capacities to UKTM input capacities

$if %RPS_on% == OFF $goto RPSoff4
*not included: interconnectors, Biomass, Geothermal, Hydro
set flex(g) /
NaturalgasOCGTnew,
Solar,
Windoffshore_Shallow,
Windoffshore_Mid,
Windoffshore_Floating,
Windonshore,
Nuclear
/;
$goto RPSon1
$label RPSoff4

set flex(g) / NaturalgasOCGTnew /;

$label RPSon1
*If ("%flex_gen%" == "ON",
*var_non_vre_cap.FX(non_vre)=uktm_gen_cap(non_vre);
*Else


$IF "%UKTMCAP%" == OFF   $GOTO uktmoff

var_non_vre_cap.FX(non_vre(g))$(not flex(g))=uktm_gen_cap(non_vre);
var_vre_cap.FX(vre)$(not flex(vre))=uktm_gen_cap(vre);

$LABEL uktmoff


*$IF "%penalty_switch%" == ON $GOTO penalty_on
*p_gen.FX(z,h)=0;
*$LABEL penalty_on





* area(vre,z,r)


*$IF "%flex_gen%" == "ON" var_non_vre_cap.FX(non_vre(g))$(not flex(g))=uktm_gen_cap(non_vre);



*var_non_vre_cap.FX(non_vre(g))$(not flex(g))=uktm_gen_cap(non_vre);
*var_non_vre_cap.FX(non_vre)=uktm_gen_cap(non_vre);
*var_vre_cap.FX(vre)=uktm_gen_cap(vre);

set ramp_on(z,non_vre);
ramp_on(z,non_vre)=(max_ramp(non_vre) < 1.0 and max_ramp(non_vre) >0. and non_vre_lim(z,non_vre));

set mingen_on(z,non_vre);
mingen_on(z,non_vre)=(min_gen(non_vre) > 0. and non_vre_lim(z,non_vre));

*var_non_vre_gen.l(z,'0','Nuclear')=32000.

Equations
eq_obj
eq_elc_balance

eq_gen_max
eq_gen_min

*eq_cap_non_vre_z
eq_ramp_up
eq_ramp_down
*eq_curtail_max_non_vre


eq_gen_vre
*eq_cap_vre


eq_cap_non_vre
eq_cap_vre_notwindoff
eq_cap_vre_windoff


eq_cap_vre_z
*eq_curtail_max_vre
eq_area_max

eq_trans_flow
eq_trans_bidirect



$if %RPS_on% == OFF $goto RPSoff2
eq_RPS
$label RPSoff2


;


*eq_store_gen_cap_z

*eq_trans_cap

*eq_trans_netzero

*eq_trans_flow_b

*eq_co2_intensity

$ontext
***Equations for DC Load Flow to model the transmission grid between nodes
*Lineflowlim_up Upper capacity limit of lineflow
*Lineflowlim_low Lower capacity limit of lineflow
*Slackbus Delta at reference bus equals zero
$offtext

******************************************
* OBJECTIVE FUNCTION

eq_obj .. costs =E=

* variable costs
sum((non_vre_lim(z,non_vre),h),var_non_vre_gen(z,h,non_vre)*generator_varom(non_vre))
+sum((vre_lim(vre,z,r),h),var_vre_gen(z,h,vre,r)*generator_varom(vre))

+sum((trans_links(z,z_alias,trans),h),var_trans_flow(z,h,z_alias,trans)*trans_varom(trans))

* annualised capital costs
+sum(non_vre,var_non_vre_cap(non_vre)*generator_capex(non_vre))

* capex for vre that are not floating wind turbines have constant value

******** var_vre_cap_r is used because var_vre_cap is only for loading uktm values
+sum((vre_notfloating,z,r)$vre_lim(vre_notfloating,z,r),var_vre_cap_r(z,r,vre_notfloating)*generator_capex(vre_notfloating))
*************** 14/10/16 Andy - floating offshore wind takes a different capex for each grid cell
* costs are scaled against the standard CAPEX2050 values
+sum((z,r)$vre_lim("Windoffshore_Floating",z,r),var_vre_cap_r(z,r,"Windoffshore_Floating")*generator_capex("Windoffshore_Floating")*floating_cost_depth_scale(r))

*var_vre_cap_r(z,r,vre)
*trans_links_dist is NOT mirrored, so only one direction of this sum is counted up (links are not double counted)
+sum(trans_links(z,z_alias,trans),var_trans_cap(z,z_alias,trans)*trans_links_dist(z,z_alias,trans)*trans_capex(trans))


* storage costs
$IF "%storage%" == OFF   $GOTO skip1
+sum((s_lim(z,s),h),var_store_gen(z,h,s)*storage_varom(s))
* here cap means reservoir capacity:
+sum((s,z),var_store_gen_cap_z(z,s)*storage_gen_capex(s)+var_store_gen_cap_z(z,s)*store_gen_to_cap(s,z)*storage_cap_capex(s))
$label skip1

* penalty generation costs
*+sum((z,h),p_gen(z,h)*penalty)
;
******************************************

******************************************
* SUPPLY-DEMAND BALANCE EQUATION (hourly)

eq_elc_balance(z,h) ..

* Generation
sum(non_vre_lim(z,non_vre),var_non_vre_gen(z,h,non_vre))
+sum(vre_lim(vre,z,r),var_vre_gen(z,h,vre,r))

* VRE Curtailment
*-sum(vre,var_vre_curtail(z,h,vre))

* NonVRE Curtailment due to ramp rates
*-sum(non_vre,var_non_vre_curtail(z,h,non_vre))

* Transmission, import-export
-sum(trans_links(z,z_alias,trans),var_trans_flow(z_alias,h,z,trans))
*bidirectional distance grid required because flows can go either direction
*losses consist of constant (inverter) losses and distance based cable losses. cable distance in units of 100km
+sum(trans_links(z,z_alias,trans),var_trans_flow(z,h,z_alias,trans)*(1-trans_loss_const(trans)-(trans_links_dist_bidir(z,z_alias,trans)*trans_loss_grad(trans))))


$IF "%storage%" == OFF   $GOTO skip2
* Storage, generated-stored
-sum(s_lim(z,s),var_store(z,h,s))
+sum(s_lim(z,s),var_store_gen(z,h,s))
$label skip2

* Penalty generation
*+p_gen(z,h)

=E= demand(z,h);

******************************************

*********************
*** VRE equations ***
*********************

* Curtailment of VRE - generation curtailed has to be less than or equal to current hourly generation

*eq_curtail_max_vre(z,h,vre) .. var_vre_curtail(z,h,vre) =L= sum(vre_lim(vre,z,r),var_vre_gen(z,h,vre,r));

* VRE generation is input data x capacity in each region

eq_gen_vre(vre_lim(vre,z,r),h) .. var_vre_gen(z,h,vre,r) =L= vre_gen(vre,r,h)*var_vre_cap_r(z,r,vre);

***************** 13/1016 Andy
* changes made. splitting out wind technology into 3 pieces means the capacities set by UKTM are a sum not a one to one relationship
* VRE capacity across all zones must sum to be equal to national capacity of each technology
*eq_cap_vre(vre) .. sum(vre_lim(vre,z,r),var_vre_cap_r(z,r,vre)) =E= var_vre_cap(vre);


eq_cap_vre_notwindoff(vre_notwindoff) .. sum(vre_lim(vre_notwindoff,z,r),var_vre_cap_r(z,r,vre_notwindoff)) =E= var_vre_cap(vre_notwindoff);

*$vre_lim(vre,z,r)
eq_cap_vre_windoff .. sum(vre_lim(vre_windoff,z,r),var_vre_cap_r(z,r,vre_windoff)) =E= var_vre_cap("Windoffshore_Shallow");



****************************************************************************************************************************************************
* VRE capacity across all regions in a zone must be equal to capacity in that zone

eq_cap_vre_z(z,vre) .. sum(vre_lim(vre,z,r),var_vre_cap_r(z,r,vre)) =E= var_vre_cap_z(z,vre);



* VRE capacity in each region must be less than or equal to buildable area for each technology in that region

eq_area_max(vre,z,r) .. var_vre_cap_r(z,r,vre) =L= area(vre,z,r);


$if %RPS_on% == OFF $goto RPSoff3
*var_vre_gen already accounts for curtailment (it is less than or equal to rather than equal to CF)
eq_RPS .. sum( (z,h,non_vre)$non_vre_lim(z,non_vre),var_non_vre_gen(z,h,non_vre) ) =L= 0.01*(100 - RPS) * sum((z,h),demand(z,h)) ;

$label RPSoff3

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

*eq_curtail_max_non_vre(z,h,non_vre) .. var_non_vre_curtail(z,h,non_vre) =L= var_non_vre_gen(z,h,non_vre);

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

*eq_co2_intensity .. sum((z,h,non_vre),var_non_vre_gen(z,h,non_vre)*emis_fac(non_vre))*1000/sum((z,h),demand(z,h)) =L= 50.





$ontext
This equation ensure an integer number of turbines in each region
eq_bin(r,vre) .. var_vre_cap(r,vre)/2.5 =E= int(r,vre);
$offtext

$ontext
*Lineflowlim_up(h,l).. 0 =g= sum(n, hf(l,n) * DELTA(h,n)) - linemax(l) ;
*Lineflowlim_low(h,l).. 0 =g= - sum(n, hf(l,n) * DELTA(h,n)) - linemax(l) ;
*Slackbus(h,n).. 0 =e= slack(n) * DELTA(h,n) ;

$offtext


Model Dispatch /all/;

* barcrossalg is the crossover switch
* aggind 0 means there is no preprocessing
* aggind = 0
Option LP = CPLEX;
$onecho > cplex.opt
lpmethod=4
threads=16
barcrossalg=-1

tilim=72000
baralg=2

barepcomp=1E-7
bargrowth = 1E10
names no

scaind=1



$offecho
Dispatch.OptFile = 1;

*writelp="C:\science\highRES\work\highres.lp"

* 2003 flexgen+store baralg=2, scaind=1 optimal




Solve Dispatch minimizing costs using LP;

$IF "%write%" == OFF   $GOTO noresults
$BATINCLUDE %resultsfile%.gms
$LABEL noresults


