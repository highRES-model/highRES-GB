Sets

h hours /
$BATINCLUDE tstep_%year%.dd
/


r regions /
$BATINCLUDE regions.dd
/

z zones /
$BATINCLUDE zones.dd
/

g /
$BATINCLUDE generator_all.dd
/
non_vre(g) /
$BATINCLUDE generator_nonvre.dd
/
vre(g) /
$BATINCLUDE generator_vre.dd
/

;

alias(z,z_alias) ;

Sets

trans transmission techs /
$BATINCLUDE transmission_all.dd
/

trans_links(z,z_alias,trans) transmission links /
$BATINCLUDE transmission_links.dd
/

;

$ontext
inter /
$BATINCLUDE inter.dd
/
$offtext

;

Parameter

non_vre_cap_lim(z,non_vre)/
$BATINCLUDE generator_lim_%nuc_restrict%.dd
/

area(vre,z,r) /
$BATINCLUDE vre_areas_%year%_agg_%area_scen%.dd
*$BATINCLUDE vre_areas_%year%_agg.dd
*$BATINCLUDE vre_areas_%year%.dd
/

cap2area(vre) /
$BATINCLUDE generator_cap2area.dd
/

trans_links_cap(z,z_alias,trans)/
$BATINCLUDE transmission_links_cap.dd
/

trans_links_dist(z,z_alias,trans)/
$BATINCLUDE transmission_links_dist.dd
/

demand(z,h)  demand per hour in MW
/
$BATINCLUDE %uktm_scen%_annual_demand_%year%.dd
/

vre_gen(vre,r,h) variable renewable generation (cap factor) by region hour and technology
/
$BATINCLUDE vre_%year%_agg_%area_scen%.dd
*$BATINCLUDE vre_%year%_agg.dd
*$BATINCLUDE vre_%year%.dd
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

generator_varom(g)
/
$BATINCLUDE generator_varom.dd
/

avail_factor(non_vre)
/
$BATINCLUDE generator_avail_factor.dd
/



trans_loss(trans)
/
$BATINCLUDE transmission_loss.dd
/

trans_varom(trans)
/
$BATINCLUDE transmission_varom.dd
/

trans_capex(trans)
/
$BATINCLUDE transmission_capex.dd
/


;
