set s
/
$BATINCLUDE storage_all.dd
/;

parameters uktm_store_cap(s)
/
$BATINCLUDE storage_capacities.dd
/

storage_gen_capex(s)
/
$BATINCLUDE storage_gen_capex2050.dd
/

storage_cap_capex(s)
/
$BATINCLUDE storage_cap_capex2050.dd
/

storage_varom(s)
/
$BATINCLUDE storage_varom.dd
/

store_loss(s)
/
$BATINCLUDE storage_loss.dd
/

store_loss_per_h(s)
/
$BATINCLUDE storage_loss_per_hour.dd
/

store_gen_to_cap(s)
/
$BATINCLUDE storage_gen_to_cap.dd
/
;

parameters
store_loss_in(s)
store_loss_out(s);

store_loss_in(s)=store_loss(s);
store_loss_out(s)=round(1/(1-store_loss(s)),2);

scalar
store_avail_factor
/0.9/;

positive variables
var_store_level(z,h,s) Amount of electricity currently stored by hour and technology (MWh)
var_store(z,h,s) Electricity into storage by hour and technology (MW)
var_store_gen(z,h,s) Electricity generated from storage by hour and technology (MW)
var_store_gen_cap_z(z,s) Capacity of storage generator (MW)
var_store_gen_cap(s)
;

*** Storage set up ***

var_store_level.FX(z,"0",s)=0;

*var_store_gen_cap.FX(s)=uktm_store_cap(s)*1000;

*var_store_gen_cap.FX("PumpedHydro")=uktm_store_cap("PumpedHydro")*1000;
*var_store_gen_cap_z.FX("Z9","PumpedHydro")=uktm_store_cap("PumpedHydro")*1000;

set s_lim(z,s);
s_lim(z,s) = YES;

*s_lim(z,s)=(var_store_gen_cap_z.l(z,s) > 0.);

equations
eq_store_balance
eq_store_level
eq_store_gen_max
eq_store_charge_max
eq_store_gen_cap
;

* Storage equations. Right now there is no ramp for storage

eq_store_gen_cap(s) .. var_store_gen_cap(s) =E= sum(z,var_store_gen_cap_z(z,s));

eq_store_balance(s_lim(z,s),h) ..
var_store_level(z,h,s) =E= var_store_level(z,h-1,s)*(1-store_loss_per_h(s)) + var_store(z,h,s)*(1-store_loss_in(s))- var_store_gen(z,h,s)*store_loss_out(s);

eq_store_level(s_lim(z,s),h) ..
var_store_level(z,h,s) =L= var_store_gen_cap_z(z,s)*store_gen_to_cap(s) ;

eq_store_gen_max(s_lim(z,s),h) ..
var_store_gen(z,h,s) =L= var_store_gen_cap_z(z,s)*store_avail_factor ;

eq_store_charge_max(s_lim(z,s),h) ..
var_store(z,h,s) =L= var_store_gen_cap_z(z,s)*store_avail_factor ;
