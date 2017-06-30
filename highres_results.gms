
*execute_unload "%outname%"



***************
*Costs
***************

*Variable Costs
parameter variableC;
variableC=
sum((non_vre_lim(z,non_vre),h),var_non_vre_gen.L(z,h,non_vre)*generator_varom(non_vre))
+sum((vre_lim(vre,z,r),h),var_vre_gen.L(z,h,vre,r)*generator_varom(vre))
+sum((trans_links(z,z_alias,trans),h),var_trans_flow.l(z,h,z_alias,trans)*trans_varom(trans))


Parameter nonVREVarC;
nonVREVarC=sum((non_vre_lim(z,non_vre),h),var_non_vre_gen.L(z,h,non_vre)*generator_varom(non_vre))

parameter VREVarC ;
VREVarC=sum((vre_lim(vre,z,r),h),var_vre_gen.L(z,h,vre,r)*generator_varom(vre))

parameter transVarC;
transVarC=sum((trans_links(z,z_alias,trans),h),var_trans_flow.L(z,h,z_alias,trans)*trans_varom(trans))


* Annualised capital costs
parameter capitalC;
capitalC=sum(non_vre,var_non_vre_cap.L(non_vre)*generator_capex(non_vre))
+sum(vre,var_vre_cap.L(vre)*generator_capex(vre))
+sum(trans_links(z,z_alias,trans),var_trans_cap.l(z,z_alias,trans)*trans_links_dist(z,z_alias,trans)*trans_capex(trans))

parameter nonVRECapC;
nonVRECapC=sum(non_vre,var_non_vre_cap.L(non_vre)*generator_capex(non_vre))

parameter VRECapC;
VRECapC= sum(vre,var_vre_cap.L(vre)*generator_capex(vre))

parameter transCapc;
transCapc=sum(trans_links(z,z_alias,trans),var_trans_cap.l(z,z_alias,trans)*trans_links_dist(z,z_alias,trans)*trans_capex(trans))

* Storage costs

*Variable Storage costs
parameter variableStorageC;
variableStorageC=sum((s_lim(z,s),h),var_store_gen.L(z,h,s)*storage_varom(s))

*Capital Storage Costs
parameter capitalStorageC;
capitalStorageC=sum(s,var_store_gen_cap.L(s)*storage_gen_capex(s)+var_store_gen_cap.L(s)*store_gen_to_cap(s)*storage_cap_capex(s))

*Total Capital Costs
parameter capitalC_tot;
capitalC_tot=capitalStorageC+capitalC

*Total Variable Costs
parameter variableC_tot;
variableC_tot=variableStorageC+variableC       ;


***************
*Emissions
***************

parameter emissions(z,h,non_vre);
emissions(z,h,non_vre)=var_non_vre_gen.L(z,h,non_vre)*emis_fac(non_vre) ;

parameter emissions_all;
emissions_all=Sum((z,h,non_vre), emissions(z,h,non_vre));



***************
*Curtailment
***************

$ontext
parameter curtail(h);
curtail(h)=sum((z,vre,r),var_vre_curtail.l(z,h,vre));

*sum of curtailment over all regions
parameter curtail_z (h,vre);
curtail_z(h,vre)=sum(z,var_vre_curtail.l(z,h,vre))


*sum of curtailment over all regions and hours
parameter curtail_z_h (vre);
curtail_z_h(vre)=sum((z,h),var_vre_curtail.l(z,h,vre))
$offtext


***************
*Transmission
***************

parameter var_trans_cap_sum(trans);
var_trans_cap_sum(trans)=sum((z,z_alias),var_trans_cap.L(z,z_alias,trans))/2  ;





***************
*Capacities
***************

parameter vre_cap_z(vre,z);
vre_cap_z(vre,z)=sum(vre_lim(vre,z,r),var_vre_cap_r.l(z,vre,r));

parameter vre_cap_r(vre,r);
vre_cap_r(vre,r)=sum(vre_lim(vre,z,r),var_vre_cap_r.l(z,vre,r));

parameter vre_cap_tot(vre);
vre_cap_tot(vre)=sum(vre_lim(vre,z,r),var_vre_cap_r.l(z,vre,r)) ;


***************
*Generation
***************

parameter non_vre_gen_tot(non_vre);
non_vre_gen_tot(non_vre)=sum((h,z),var_non_vre_gen.l(z,h,non_vre));

parameter non_vre_gen_out(non_vre,h);
non_vre_gen_out(non_vre,h)= sum(z,var_non_vre_gen.l(z,h,non_vre)$(var_non_vre_gen.l(z,h,non_vre) >0.));


parameter vre_gen_out(vre,h);
vre_gen_out(vre,h)=sum((z,r),var_vre_gen.l(z,h,vre,r)$vre_lim(vre,z,r))


parameter gen_out(g,h);
gen_out(vre,h)=vre_gen_out(vre,h) ;
gen_out(non_vre,h)=non_vre_gen_out(non_vre,h) ;



parameter vre_cap(vre);
vre_cap(vre)=sum((z,r),var_vre_cap_r.l(z,vre,r));


***************
*Economics
***************


parameter price(z,h);
price(z,h)=eq_elc_balance.m(z,h);


*grossRet is the gross return fom power production (revenues - (variable)costs)

*gross Margins non VRE
parameter grossRet_non_vre(z,non_vre);
grossRet_non_vre(z,non_vre)=sum(h,((price(z,h)*var_non_vre_gen.L(z,h,non_vre))- (var_non_vre_gen.L(z,h,non_vre)*generator_varom(non_vre))))  ;


*gross Margins VRE
parameter grossRet_vre(z,vre,r);
grossRet_vre(z,vre,r)=sum(h,(price(z,h)*var_vre_gen.L(z,h,vre,r))- (var_vre_gen.L(z,h,vre,r)*generator_varom(vre)))


*gross Margins Storage
parameter grossRet_store(z,s);
grossRet_store(z,s)=sum(h,(price(z,h)*var_store_gen.L(z,h,s))- (var_store_gen.L(z,h,s)*storage_varom(s)))



scalar gen_costs;
gen_costs=sum((z,h,non_vre),var_non_vre_gen.l(z,h,non_vre)*generator_varom(non_vre))+sum((vre_lim(vre,z,r),h),var_vre_gen.l(z,h,vre,r)*generator_varom(vre));


parameter sum_test;
sum_test=sum(vre_lim(vre,z,r),var_vre_cap.l(vre));



*sums up over all zones and gives installed capacity per renewable
parameter var_vre_cap_z_sum(vre,r);
var_vre_cap_z_sum(vre,r)=sum(z,var_vre_cap_r.L(z,vre,r));


parameter var_vre_cap_r_sum(z,vre) ;
var_vre_cap_r_sum(z,vre)=sum(r,var_vre_cap_r.L(z,vre,r));


*sums up over all zones and gives installed capacity per generation type
parameter var_non_vre_cap_z_sum(non_vre);
var_non_vre_cap_z_sum(non_vre)=sum(z,var_non_vre_cap_z.L(z,non_vre));


*sums up over all hours +regions and gives the generated electricity per renewable type
parameter var_vre_gen_sum_r(vre);
var_vre_gen_sum_r(vre)=sum((z,h,r),var_vre_gen.L(z,h,vre,r));


*sums up over all hours +zones and gives the generated electricity per renewable type
parameter var_vre_gen_sum_z(vre,r);
var_vre_gen_sum_z(vre,r)=sum((z,h),var_vre_gen.L(z,h,vre,r));


parameter var_vre_gen_sum_r_z(z,vre);
var_vre_gen_sum_r_z(z,vre)=sum((r,h),var_vre_gen.L(z,h,vre,r));


parameter var_vre_gen_sum_r_zone(z,h,vre);
var_vre_gen_sum_r_zone(z,h,vre)=sum((r),var_vre_gen.L(z,h,vre,r));



*sums over all regions and zones and gives the generated electricity per generation type
parameter var_vre_gen_sum_h(h,vre);
var_vre_gen_sum_h(h,vre)=sum((z,r),var_vre_gen.L(z,h,vre,r));


parameter var_non_vre_gen_sum_zone(z,non_vre)  ;
var_non_vre_gen_sum_zone(z,non_vre)=sum(h,var_non_vre_gen.L(z,h,non_vre));


*sums up over all hours +zones and gives the generated electricity per generation type
parameter var_non_vre_gen_sum_z(non_vre)  ;
var_non_vre_gen_sum_z(non_vre)=sum((z,h),var_non_vre_gen.L(z,h,non_vre));

*sums over all zones and gives the generated electricity per generation type
parameter var_non_vre_gen_sum_h(h,non_vre)  ;
var_non_vre_gen_sum_h(h,non_vre)=sum(z,var_non_vre_gen.L(z,h,non_vre));


parameter var_store_gen_sum_h(h,s)  ;
var_store_gen_sum_h(h,s)=sum(z,var_store_gen.L(z,h,s));



*parameter var_trans_cap_sum(z_alias);
*var_trans_cap_sum(z_alias)=sum(z,var_trans_cap.L(z,z_alias))  ;
*display var_trans_cap_sum;

*sums over all hours and gives the electricity generated per zone and storage technology
parameter var_store_gen_sum(z,s);
var_store_gen_sum(z,s)=sum(h,var_store_gen.L(z,h,s));


*sums over all hours and zones and gives the electricity generated per zone and storage technology
parameter var_store_gen_all(s);
var_store_gen_all(s)=sum((z,h),var_store_gen.L(z,h,s));


*sums up over all hours +zones and gives the generated electricity per generation type
parameter var_non_vre_gen_sum_z(non_vre)  ;
var_non_vre_gen_sum_z(non_vre)=sum((z,h),var_non_vre_gen.L(z,h,non_vre));


parameter var_vre_gen_sum_r(vre);
var_vre_gen_sum_r(vre)=sum((z,h,r),var_vre_gen.L(z,h,vre,r));

;

parameter Residual_D(z,h);
Residual_D(z,h)=demand(z,h)-sum(vre,var_vre_gen_sum_r_zone(z,h,vre));

$ontext
*Average electricity price
parameter price_mean(h);
price_mean(h)= sum((z,non_vre),(price(z,h)*var_non_vre_gen.L(z,h,non_vre))/sum(vre,var_vre_gen_sum_r(vre)))


parameter price_mean(h);
price_mean(h)=
(sum((z,non_vre),(price(z,h)*var_non_vre_gen.L(z,h,non_vre)))
+sum((z,vre),(price(z,h)*var_vre_gen_sum_r_zone(z,h,vre)))
+sum((z,s),(price(z,h)*var_store_gen.L(z,h,s))))
/(sum((z,vre),var_vre_gen_sum_r_zone(z,h,vre))+
sum((z,non_vre),var_non_vre_gen.L(z,h,non_vre))
+sum((z,s),var_store_gen.L(z,h,s)));




WORKS: parameter price_mean(h);
price_mean(h)=
(sum((z,non_vre),(price(z,h)*var_non_vre_gen.L(z,h,non_vre)))+sum((z,vre),(price(z,h)*var_vre_gen_sum_r_zone(z,h,vre))))
/(sum((z,vre),var_vre_gen_sum_r_zone(z,h,vre))+sum((z,non_vre),var_non_vre_gen.L(z,h,non_vre)));
display price_mean;

parameter price_mean(h);
price_mean(h)=
(sum((z,non_vre),(price(z,h)*var_non_vre_gen.L(z,h,non_vre)))
+sum((z,vre),(price(z,h)*var_vre_gen_sum_r_zone(z,h,vre)))
+sum((z,s),(price(z,h)*var_store_gen.L(z,h,s))
/((((sum((z,vre),var_vre_gen_sum_r_zone(z,h,vre))+sum((z,non_vre),var_non_vre_gen.L(z,h,non_vre))+sum((z,s),var_store_gen.L(z,h,s)));
display price_mean;

parameter price_mean(h);
price_mean(h)=
(sum((z,non_vre),(price(z,h)*var_non_vre_gen.L(z,h,non_vre)))
+sum((z,vre),(price(z,h)*var_vre_gen_sum_r_zone(z,h,vre)))
+sum((z,s),(price(z,h)*var_store_gen.L(z,h,s))
/(((sum((z,vre),var_vre_gen_sum_r_zone(z,h,vre))+sum((z,non_vre),var_non_vre_gen.L(z,h,non_vre))+sum((z,s),var_store_gen.L(z,h,s)));
display price_mean;

$offtext

