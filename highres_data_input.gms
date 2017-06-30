*version notes
* 2017_b: new "all regions" set r_all. used to load waves, floating cost ratios and electrical losses

$offdigit
$offlisting

Sets
h hours /
$BATINCLUDE tstep_%year%.dd
/

hfirst(h) first hour
hlast (h) last hour

r_all all regions /
$BATINCLUDE regions_all.dd
/

r(r_all) regions /
$BATINCLUDE regions.dd
/

z zones /
$BATINCLUDE zones.dd
/

alias(z,z_alias);

set
trans transmission techs /
$BATINCLUDE transmission_all.dd
/
trans_links(z,z_alias,trans) transmission links /
$BATINCLUDE transmission_links.dd
/

$ontext
p plants /Gas,Coal,Oil,Biomass,Hydro,Nuclear, Hydrogen,Imports,PV, windonshore, windoffshore,PSP, CAES, Redox/
store(p)/PSP, CAES, Redox/
vre(p) variable renewables /windonshore, windoffshore, PV/
$offtext

g /
$BATINCLUDE generator_all.dd
/
non_vre(g) /
$BATINCLUDE generator_nonvre.dd
/
vre(g) /
$BATINCLUDE generator_vre.dd
/
vre_notwindoff(vre) /
$BATINCLUDE generator_vre_notwindoffshore.dd
/
vre_windoff(vre) /
$BATINCLUDE generator_windoffshore.dd
/
vre_notfloating(vre) /
$BATINCLUDE generator_vre_notfloating.dd
/
vre_loadCF(vre) /
$BATINCLUDE generator_vreCF.dd
/



;

Parameter

non_vre_cap_lim(z,non_vre)/
$BATINCLUDE generator_lim.dd
/

area(vre,z,r) /
$BATINCLUDE vre_areas.dd
/

cap2area(vre) /
$BATINCLUDE generator_cap2area.dd
/

trans_links_cap(z,z_alias,trans)/
$BATINCLUDE transmission_links_cap.dd
/

trans_links_dist(z,z_alias,trans) distance in km
/
$BATINCLUDE transmission_links_dist.dd
/
demand(z,h)  demand per hour in MW
/
$BATINCLUDE demand_%year%.dd
/

* vre generation is now loaded for a limited set of generators to avoid the need to duplicate file entries
vre_gen_load(vre_loadCF,r_all,h) variable renewable generation (cap factor) by region hour and technology
/
$BATINCLUDE vre_%year%.dd
/



waves_raw(r_all,h) significant wave height (cm) /
$BATINCLUDE waves_raw%year%.dd
/
windoff_waves(r,h) on-off for wave tolerance breaches/
/





fuelC(g) gbp 2050 per MWh
/
$BATINCLUDE generator_fuelcost2050.dd
/

uktm_gen_cap(g) UKTM installed capacities
/
$BATINCLUDE generator_capacities.dd
/

min_gen(non_vre) minimum activity
/
$BATINCLUDE generator_min_gen.dd
/

emis_fac(g) emissions factor in t per MWh
/
$BATINCLUDE generator_emission_factor.dd
/

max_ramp(g)
/
$BATINCLUDE generator_max_ramp.dd
/


generator_capex(g)
/
$BATINCLUDE generator_capex2050.dd
/
*this floating cost scale factor is accounted for directly in the objective function
floating_cost_depth_scale(r_all) scale factors for floating costs by region/
$BATINCLUDE floating_cost_ratio.dd
/
offwind_cost_scale(vre_windoff) scale factors for offshore wind/
$BATINCLUDE windoffshore_costratio.dd
/
floating_depth(r_all) depth of floating turbines in each region /
$BATINCLUDE floating_depths.dd
/
distance_to_shore(r_all) distance to shore (km) /
$BATINCLUDE distance_grid.dd
/
generator_varom(g)  �k per MWh
/
$BATINCLUDE generator_varom.dd
/

avail_factor(non_vre)
/
$BATINCLUDE generator_avail_factor.dd
/
windoff_elec(r_all) electrical loss factors for offshore wind (eg. 0.98) /
$BATINCLUDE windoff_elec_loss.dd
/


trans_loss_grad(trans) variable transmission loss (cable) per 100km (eg 0.01) /
$BATINCLUDE transmission_loss_grad.dd
/
trans_loss_const(trans) constant transmission loss (inverters) (eg. 0.02) /
$BATINCLUDe transmission_loss_const.dd
/


trans_varom(trans) cost per MWh
/
$BATINCLUDE transmission_varom.dd
/

trans_capex(trans) tranmission capex (�k per MVA per 100km) /
$BATINCLUDE transmission_capex.dd
/

;

*** CAPEX values for offshore wind are initially loaded as the UKTM 2050 value
* then they are scaled using offwind_cost_scale


parameter
vre_gen(vre,r,h) hourly CF for all vre;

vre_gen(vre_loadCF,r,h) = vre_gen_load(vre_loadCF,r,h);
vre_gen(vre_windoff,r,h) = vre_gen_load("Windoffshore_Shallow",r,h);





