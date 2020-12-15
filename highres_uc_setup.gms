******************************************
* highres unit commitment module
******************************************

option IntVarUp=0
$ONEPS

* f_response = 10 seconds
* reserve = 20 minutes

scalars
f_res_time                               frequency response ramp up window (minutes)                             /0.167/
res_time                                 operating reserve ramp up window (minutes)                              /20./
unit_cap_lim_z                           limit the maximum capacity of each units deployed in each zone (MW)     /50000./
res_margin                               operating reserve margin (fraction of demand)                           / 0.05 /
;

parameter
vre_margin(vre)                          vre forecast errors (fraction of output) - both from NatGrid 2017 - Demand Forecasting
/
Windonshore 0.14
Windoffshore 0.14
Solar 0.12
/
;



* ancillary service type

sets
service_type                             ancillary service type                                                  /f_response, reserve/
;

* hour alias used for minimum up/down time equations

alias(h,h_alias);

set map_minup(h,non_vre,h)
    map1_minup(h,non_vre,h)
    map_mindown(h,non_vre,h)
    map1_mindown(h,non_vre,h)
    hh_minup(h) max minup hours / 0*23 /
    hh_mindown(h) /0*7/;

*map1_minup(h,non_vre,h_alias) = ord(h_alias) ge (ord(h) - gen_minup(non_vre)+1) and ord(h_alias) lt ord(h);
map_minup(h,non_vre,h_alias+(ord(h)-gen_minup(non_vre)))$[hh_minup(h_alias) and ord (h_alias)<gen_minup(non_vre)] = yes;

*map1_mindown(h,non_vre,h_alias) = ord(h_alias) ge (ord(h) - gen_mindown(non_vre)+1) and ord(h_alias) lt ord(h);
map_mindown(h,non_vre,h_alias+(ord(h)-gen_mindown(non_vre)))$[hh_mindown(h_alias) and ord (h_alias)<gen_mindown(non_vre)] = yes;


parameter gen_max_res(non_vre,service_type);

* compute maximum power ramp in MW for each tech for in each reserve window

gen_max_res(non_vre,"reserve")$(gen_uc_int(non_vre) or gen_uc_lin(non_vre))=gen_maxramp(non_vre)*res_time;
gen_max_res(non_vre,"f_response")$(gen_uc_int(non_vre) or gen_uc_lin(non_vre))=gen_maxramp(non_vre)*f_res_time;


* rescale from MW to GW for better numerics (allegedly)
* also need to change var_H equation to include a /1E3 and remove
* var_freq_req scaling

gen_startupcost(non_vre)=gen_startupcost(non_vre)/MWtoGW;
unit_cap_lim_z=unit_cap_lim_z/MWtoGW;

parameter res_req(h)                     operating reserve requirement based on demand level;
res_req(h)=sum(z,demand(z,h))*res_margin;


*************************

*************************

Positive variables
var_res(h,z,non_vre)                     operating reserve offered by tech zone and hour (MW)
var_res_quick(h,z,non_vre)               quick start operating reserve by tech zone and hour (MW)
var_f_res(h,z,non_vre)                   frequency resonse by tech zone and hour (MW)
var_tot_n_units_lin(z,non_vre)           total number of units (linear)
var_new_n_units_lin(z,non_vre)           number of new units (linear)
var_exist_n_units_lin(z,non_vre)         number of existing units (linear)
var_up_units_lin(h,z,non_vre)            units starting up by tech zone and hour (linear)
var_down_units_lin(h,z,non_vre)          units shutdown by tech zone and hour (linear)
var_com_units_lin(h,z,non_vre)           units committed by tech zone and hour (linear)
;

Integer variables
var_tot_n_units(z,non_vre)               total units per zone
var_new_n_units(z,non_vre)               newly installed units per zone
var_exist_n_units(z,non_vre)             existing units per zone
var_up_units(h,z,non_vre)                units started per tech hour and zone
var_down_units(h,z,non_vre)              units shutdown per tech hour and zone
var_com_units(h,z,non_vre)               committed units per tech hour and zone
;




* set integer upper limit for existing capacity being represented as units, based on:
* a) existing cap, floored to ensure it doesn't breach existing cap limit
* b) if no existing cap, set equal to 0

var_exist_n_units.UP(z,non_vre)$(gen_uc_int(non_vre) and gen_exist_pcap_z(z,non_vre,"UP"))=floor(gen_exist_pcap_z(z,non_vre,"UP")/gen_unitsize(non_vre));
var_exist_n_units.L(z,non_vre)$(gen_uc_int(non_vre) and gen_exist_pcap_z(z,non_vre,"UP"))=floor(gen_exist_pcap_z(z,non_vre,"UP")/gen_unitsize(non_vre));

var_exist_n_units.LO(z,non_vre)$(gen_uc_int(non_vre) and gen_exist_pcap_z(z,non_vre,"LO")) = floor(gen_exist_pcap_z(z,non_vre,"LO")/gen_unitsize(non_vre));
var_exist_n_units.FX(z,non_vre)$(gen_uc_int(non_vre) and gen_exist_pcap_z(z,non_vre,"FX")) = floor(gen_exist_pcap_z(z,non_vre,"FX")/gen_unitsize(non_vre));

var_exist_n_units.UP(z,non_vre)$(gen_uc_int(non_vre) and not sum(lt,gen_exist_pcap_z(z,non_vre,lt)))=0.;

* set integer upper limit for new capacity being represented as units, based on:
* a) total cap limit per zone
* b) some arbitrary number (unit_cap_lim_z)

var_tot_n_units.UP(z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre) and gen_lim_pcap_z(z,non_vre,'UP') < INF)=ceil(gen_lim_pcap_z(z,non_vre,'UP')/gen_unitsize(non_vre));
var_tot_n_units.UP(z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre) and gen_lim_pcap_z(z,non_vre,'UP') = INF)=ceil(unit_cap_lim_z/gen_unitsize(non_vre));

*var_n_units.UP(z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre))=ceil(50000/gen_unitsize(non_vre));
var_up_units.UP(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre))=var_tot_n_units.UP(z,non_vre);
var_down_units.UP(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre))=var_tot_n_units.UP(z,non_vre);
var_com_units.UP(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre))=var_tot_n_units.UP(z,non_vre);

var_com_units.UP(h,z,non_vre)$(gen_uc_int(non_vre) and not gen_lim(z,non_vre))=0.;

Equations

* integer operability equations

eq_uc_tot_units
eq_uc_units
eq_uc_unit_state
eq_uc_cap
eq_uc_exist_cap
eq_uc_gen_max
eq_uc_gen_min
eq_uc_gen_minup
eq_uc_gen_mindown

* linear operability equations

eq_uc_tot_units_lin
eq_uc_units_lin
eq_uc_unit_state_lin
eq_uc_cap_lin
eq_uc_exist_cap_lin
eq_uc_gen_max_lin
eq_uc_gen_min_lin
eq_uc_gen_minup_lin
eq_uc_gen_mindown_lin

* reserves/response

eq_uc_reserve_quickstart
eq_uc_reserve

eq_uc_response
* no quickstart frequency response at the moment
*eq_uc_response_quickstart

eq_uc_max_reserve
eq_uc_max_reserve_lin

eq_uc_max_response
eq_uc_max_response_lin

;

** Capacity balance equations

eq_uc_tot_units(z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_tot_n_units(z,non_vre) =E= var_exist_n_units(z,non_vre)+var_new_n_units(z,non_vre);

eq_uc_cap(z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_new_pcap_z(z,non_vre) =E= var_new_n_units(z,non_vre)*gen_unitsize(non_vre);

eq_uc_exist_cap(z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_exist_pcap_z(z,non_vre) =E= var_exist_n_units(z,non_vre)*gen_unitsize(non_vre);


eq_uc_tot_units_lin(z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) .. var_tot_n_units_lin(z,non_vre) =E= var_exist_n_units_lin(z,non_vre)+var_new_n_units_lin(z,non_vre);

eq_uc_cap_lin(z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) .. var_new_pcap_z(z,non_vre) =E= var_new_n_units_lin(z,non_vre)*gen_unitsize(non_vre);

eq_uc_exist_cap_lin(z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) .. var_exist_pcap_z(z,non_vre) =E= var_exist_n_units_lin(z,non_vre)*gen_unitsize(non_vre);


*eq_uc_cap_lin(z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) .. var_new_pcap_z(z,non_vre) =E= var_n_units_lin(z,non_vre)*gen_unitsize(non_vre);

*eq_uc_exist_cap(z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_exist_cap_z(z,non_vre) =E= var_exist_n_units(z,non_vre)*gen_unitsize(non_vre);

*eq_uc_new_cap(z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_new_pcap_z(z,non_vre) =E= var_new_n_units(z,non_vre)*gen_unitsize(non_vre);

** Integer operability

* total committed units must be less than installed units

eq_uc_units(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_com_units(h,z,non_vre) =L= var_tot_n_units(z,non_vre);

* committment state of units

eq_uc_unit_state(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) ..  var_com_units(h,z,non_vre) =E= var_com_units(h-1,z,non_vre)+var_up_units(h,z,non_vre)-var_down_units(h,z,non_vre);

* maximum generation limit

eq_uc_gen_max(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_com_units(h,z,non_vre)*gen_unitsize(non_vre)*gen_af(non_vre) =G= var_gen(h,z,non_vre)+var_res(h,z,non_vre)+var_f_res(h,z,non_vre) ;

* minimum stable generation

eq_uc_gen_min(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_gen(h,z,non_vre) =G= var_com_units(h,z,non_vre)*gen_mingen(non_vre)*gen_unitsize(non_vre);

* minimum up time

eq_uc_gen_minup(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre) and (gen_minup(non_vre) > 1) and (ord(h) > 1)) .. sum(map_minup(h,non_vre,h_alias),var_up_units(h_alias,z,non_vre)) =L= var_com_units(h,z,non_vre);

* minimum down time

eq_uc_gen_mindown(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre) and (gen_mindown(non_vre) > 1) and (ord(h) > 1)) .. sum(map_mindown(h,non_vre,h_alias),var_down_units(h_alias,z,non_vre)) =L= var_tot_n_units(z,non_vre)-var_com_units(h,z,non_vre);


** Linear operability


eq_uc_units_lin(h,z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) .. var_com_units_lin(h,z,non_vre) =L= var_tot_n_units_lin(z,non_vre);

eq_uc_unit_state_lin(h,z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) ..  var_com_units_lin(h,z,non_vre) =E= var_com_units_lin(h-1,z,non_vre)+var_up_units_lin(h,z,non_vre)-var_down_units_lin(h,z,non_vre);

eq_uc_gen_max_lin(h,z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) .. var_com_units_lin(h,z,non_vre)*gen_unitsize(non_vre)*gen_af(non_vre) =G= var_gen(h,z,non_vre)+var_res(h,z,non_vre)+var_f_res(h,z,non_vre) ;

eq_uc_gen_min_lin(h,z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) .. var_gen(h,z,non_vre) =G= var_com_units_lin(h,z,non_vre)*gen_mingen(non_vre)*gen_unitsize(non_vre);

eq_uc_gen_minup_lin(h,z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre) and (gen_minup(non_vre) > 1) and (ord(h) > 1)) .. sum(map_minup(h,non_vre,h_alias),var_up_units_lin(h_alias,z,non_vre)) =L= var_com_units_lin(h,z,non_vre);

eq_uc_gen_mindown_lin(h,z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre) and (gen_mindown(non_vre) > 1) and (ord(h) > 1)) .. sum(map_mindown(h,non_vre,h_alias),var_down_units_lin(h_alias,z,non_vre)) =L= var_tot_n_units_lin(z,non_vre)-var_com_units_lin(h,z,non_vre);



** Reserves

* Quickstart - units which can come online and ramp to full in the reserve window -> OCGT only

eq_uc_reserve_quickstart(h,z,non_vre)$(gen_lim(z,non_vre) and gen_quick(non_vre)) .. (var_tot_n_units_lin(z,non_vre)-var_com_units_lin(h,z,non_vre))*gen_unitsize(non_vre)*gen_af(non_vre) =G= var_res_quick(h,z,non_vre);

* Max reserve potential if needed - can be used to simulate different time scales over which reserve is offered

eq_uc_max_reserve(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_res(h,z,non_vre) =L= var_com_units(h,z,non_vre)*gen_max_res(non_vre,"reserve")*gen_af(non_vre);

eq_uc_max_reserve_lin(h,z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre) and not gen_quick(non_vre)) .. var_res(h,z,non_vre) =L= var_com_units_lin(h,z,non_vre)*gen_unitsize(non_vre)*gen_af(non_vre)*gen_max_res(non_vre,"reserve");

* Max frequency response potential

eq_uc_max_response(h,z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)) .. var_f_res(h,z,non_vre) =L= var_com_units(h,z,non_vre)*gen_max_res(non_vre,"f_response")*gen_af(non_vre);

eq_uc_max_response_lin(h,z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)) .. var_f_res(h,z,non_vre) =L= var_com_units_lin(h,z,non_vre)*gen_max_res(non_vre,"f_response")*gen_af(non_vre);

equations
eq_uc_H
;

Positive variables
var_H(h)                                 system inertia per hour (GWs per Hz)
;


scalar f_0 / 50. /;
scalar p_loss / 1650. /;
scalar p_loss_inertia  / 7./;

* compute system inertia

eq_uc_H(h) .. var_H(h) =E= sum((z,non_vre)$(gen_uc_int(non_vre) and gen_lim(z,non_vre)),gen_inertia(non_vre)*var_com_units(h,z,non_vre)*(gen_unitsize(non_vre)*MWtoGW/1E3)/f_0)
                               +sum((z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)),gen_inertia(non_vre)*var_com_units_lin(h,z,non_vre)*(gen_unitsize(non_vre)*MWtoGW/1E3)/f_0);

* -((p_loss/1E3)*p_loss_inertia/f_0);

var_H.LO(h) = 0.825;
*var_H.UP(h) = 9..

* Below piecewise segments derived using equations 37 and 38 from
* https://ieeexplore.ieee.org/document/7833096


set seg /1*8/;
set lin_param /slope,intercept/;

table linearise(seg,lin_param)
   slope  intercept
1  -4.25      12.76
2  -1.42       7.09
3  -0.71       4.96
4  -0.43       3.83
5  -0.28       3.12
6  -0.20       2.63
7  -0.15       2.28
8  -0.12       2.01
;


*var_H.UP(h) = 9.;
*var_H.LO(h) = 1.;



equations
eq_uc_freq_req
;

positive variable var_freq_req(h);

var_freq_req.UP(h)=var_H.LO(h)*linearise("1","slope")+linearise("1","intercept");
*var_freq_req.LO(h)=var_H.UP(h)*linearise("6","slope")+linearise("6","intercept");

* piecewise linear approximation of frequency response requirement.
* see:
* Teng, F. et al. (2017). Full stochastic scheduling for low-carbon electricity systems. IEEE Transactions on Automation Science and Engineering, 14(2), 461-470

eq_uc_freq_req(h,seg) .. var_freq_req(h) =G= (linearise(seg,"slope")*var_H(h)+linearise(seg,"intercept"))*1E3/MWtoGW;


$ifThen "%storage%" == ON


Equations
eq_uc_store_res_level
eq_uc_store_res_max
eq_uc_store_f_res_max
;

* limits response and reserve offered by storage to be less than the storage level - only for techs which can offer response or reserve

eq_uc_store_res_level(h,s_lim(z,s))$(store_max_res(s) > 0. or store_max_freq(s) > 0.) .. var_store_res(h,z,s)+var_store_f_res(h,z,s) =L= var_store_level(h,z,s);

* limits reserve offered by storage based on how much of its capacity can come online within the reserve time
* window - only for techs which can offer reserve

eq_uc_store_res_max(h,s_lim(z,s))$(store_max_res(s) > 0.) .. var_store_res(h,z,s) =L= var_tot_store_pcap_z(z,s)*store_af(s)*store_max_res(s);

* limits resposne offered by storage based on how much of its capacity can come online within the
* response window - only for techs which can offer response

eq_uc_store_f_res_max(h,s_lim(z,s))$(store_max_freq(s) > 0.) .. var_store_f_res(h,z,s) =L= var_tot_store_pcap_z(z,s)*store_af(s)*store_max_freq(s);

$endIf


* Main reserve equation

eq_uc_reserve(h) ..

* spinning - only techs which can offer reserve

sum((z,non_vre)$(gen_lim(z,non_vre) and gen_max_res(non_vre,"reserve") > 0.),var_res(h,z,non_vre))

* quick start

+sum((z,non_vre)$(gen_lim(z,non_vre) and gen_quick(non_vre)),var_res_quick(h,z,non_vre))

* storage

$IF "%storage%" == ON +sum(s_lim(z,s)$(store_max_res(s) > 0.),var_store_res(h,z,s))

*

-sum((z,vre),var_gen(h,z,vre)*vre_margin(vre))

=G= res_req(h);

* Main response equation



eq_uc_response(h) ..

* spinning

sum((z,non_vre)$(gen_lim(z,non_vre) and gen_max_res(non_vre,"f_response") > 0.),var_f_res(h,z,non_vre))

* quick start - no quick start for response

*+sum((z,non_vre)$(gen_uc_lin(non_vre) and gen_lim(z,non_vre)),var_res_quick(h,z,non_vre))

* storage

$IF "%storage%" == ON +sum(s_lim(z,s)$(store_max_freq(s) > 0.),var_store_f_res(h,z,s))

*

=G= var_freq_req(h);









