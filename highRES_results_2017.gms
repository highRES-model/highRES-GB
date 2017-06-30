$ontext
2017_a: zeroing out selected parameters just before the gdx unload to reduce file size
2017_b: using Option clear instead of zeroing out
2017_c: reverted to zeroing out because Option clear not working
2-17_d: new curtailment variable - produced a few parameters for output
2017_f: fixed lcoe output parameters

$offtext
***************
*Costs
***************
display uktm_gen_cap;

$offlisting
scalar demand_tot;
demand_tot = sum((z,h),demand(z,h));


Scalar system_lcoe cost from objective function divided by annual demand;
system_lcoe = (costs.L / demand_tot);

*Variable Costs
parameter variableC_vre(g);
variableC_vre(vre) = sum( (z,h,r),var_vre_gen.L(z,h,vre,r)*generator_varom(vre) );
variableC_vre(non_vre) = sum( (z,h),var_non_vre_gen.L(z,h,non_vre)*generator_varom(non_vre) );

parameter variableC variable operating costs;
variableC=
sum((non_vre_lim(z,non_vre),h),var_non_vre_gen.L(z,h,non_vre)*generator_varom(non_vre))
+sum((vre_lim(vre,z,r),h),var_vre_gen.L(z,h,vre,r)*generator_varom(vre))
+sum((trans_links(z,z_alias,trans),h),var_trans_flow.L(z,h,z_alias,trans)*trans_varom(trans))


Parameter nonVREVarC variable operating costs non_vre generators;
nonVREVarC=sum((non_vre_lim(z,non_vre),h),var_non_vre_gen.L(z,h,non_vre)*generator_varom(non_vre))

parameter VREVarC variable operating costs vre generators;
VREVarC=sum((vre_lim(vre,z,r),h),var_vre_gen.L(z,h,vre,r)*generator_varom(vre))

parameter transVarC variable operating costs transmission;
transVarC=sum((trans_links(z,z_alias,trans),h),var_trans_flow.L(z,h,z_alias,trans)*trans_varom(trans))


* Annualised capital costs
parameter capitalC total capital expenditure;
capitalC=sum(non_vre,var_non_vre_cap.L(non_vre)*generator_capex(non_vre))
+sum(vre,var_vre_cap.L(vre)*generator_capex(vre))
+sum(trans_links(z,z_alias,trans),var_trans_cap.L(z,z_alias,trans)*trans_links_dist(z,z_alias,trans)*trans_capex(trans))

parameter nonVRECapC total capital expenditure on non_vre;
nonVRECapC=sum(non_vre,var_non_vre_cap.L(non_vre)*generator_capex(non_vre))

parameter VRECapC total capital expenditure on vre;
VRECapC = sum((vre_notfloating,z,r)$vre_lim(vre_notfloating,z,r),var_vre_cap_r.l(z,r,vre_notfloating)*generator_capex(vre_notfloating))+sum((z,r)$vre_lim("Windoffshore_Floating",z,r),var_vre_cap_r.l(z,r,"Windoffshore_Floating")*generator_capex("Windoffshore_Floating")*floating_cost_depth_scale(r))

parameter capex_vre_r(vre,r) capital expenditure for each vre in reach region - £k;
capex_vre_r(vre_notfloating,r) = sum( (z)$vre_lim(vre_notfloating,z,r),var_vre_cap_r.l(z,r,vre_notfloating)*generator_capex(vre_notfloating) );
capex_vre_r("Windoffshore_Floating",r) = sum((z)$vre_lim("Windoffshore_Floating",z,r),var_vre_cap_r.l(z,r,"Windoffshore_Floating")*generator_capex("Windoffshore_Floating")*floating_cost_depth_scale(r)) ;

parameter capex_vre(vre) national capital expenditure for each vre - £k;
capex_vre(vre) = sum(r,capex_vre_r(vre,r));

* LCOE measures

parameter lcoe_vre_r(vre,r) lcoe for each vre in each region - £k per MWh;
lcoe_vre_r(vre,r) = generator_varom(vre) + (  capex_vre_r(vre,r) / sum((z,h), var_vre_gen.l(z,h,vre,r))  );

parameter lcoe_vre(vre) national average lcoe for each vre - £k per MWh;
lcoe_vre(vre) = generator_varom(vre)  + (capex_vre(vre) / sum((z,h,r)$vre_lim(vre,z,r), var_vre_gen.l(z,h,vre,r)) );

parameter lcoe_non_vre(non_vre) national average lcoe for each nonvre - £k per MWh;
* from main file: generator_varom(non_vre)=fuelC(non_vre)+emis_fac(non_vre)*emis_price+generator_varom(non_vre)
lcoe_non_vre(non_vre) = generator_varom(non_vre) + ( var_non_vre_cap.L(non_vre)*generator_capex(non_vre) / sum((z,h),var_non_vre_gen.L(z,h,non_vre)) );



parameter transCapc;
transCapc=sum(trans_links(z,z_alias,trans),var_trans_cap.L(z,z_alias,trans)*trans_links_dist(z,z_alias,trans)*trans_capex(trans))

* Storage costs

*Variable Storage costs
parameter variableStorageC;
variableStorageC=sum((s_lim(z,s),h),var_store_gen.L(z,h,s)*storage_varom(s))

*Capital Storage Costs
parameter capitalStorageC;
capitalStorageC=sum((z,s),var_store_gen_cap_z.L(z,s)*( storage_gen_capex(s) + store_gen_to_cap(s,z)*storage_cap_capex(s) ) )

*Total Capital Costs
parameter capitalC_tot;
capitalC_tot=capitalStorageC+capitalC

*Total Variable Costs
parameter variableC_tot;
variableC_tot=variableStorageC+variableC       ;

*display variableC;
*display capitalC;
*display variableStorageC;
*display capitalStorageC;
*display variableC_tot;
*display capitalC_tot;
*display costs.L;

***************
*Emissions
***************

parameter emissions(z,h,non_vre);
emissions(z,h,non_vre)=var_non_vre_gen.L(z,h,non_vre)*emis_fac(non_vre) ;
*display emissions;

parameter emissions_all;
emissions_all=Sum((z,h,non_vre), emissions(z,h,non_vre));
*display emissions_all;


***************
*Curtailment
***************
parameter curtail_disagg(z,h,vre,r) curtailment in MWh;
curtail_disagg(z,h,vre,r) = (vre_gen(vre,r,h)*var_vre_cap_r.L(z,r,vre) ) - var_vre_gen.L(z,h,vre,r) ;
curtail_disagg(z,h,vre,r)$( curtail_disagg(z,h,vre,r) < 0.1) = 0;

parameter curtail_pct_vre(vre) annual curtailment ratio by vre;
curtail_pct_vre(vre) = sum((z,h,r),curtail_disagg(z,h,vre,r)) / sum((z,r,h),vre_gen(vre,r,h)*var_vre_cap_r.l(z,r,vre));

parameter curtail(h);
curtail(h)=sum((z,vre,r),curtail_disagg(z,h,vre,r));
*display curtail;

*sum of curtailment over all regions
parameter curtail_z (h,vre);
curtail_z(h,vre)=sum((z,r),curtail_disagg(z,h,vre,r))
*display curtail_z;

*sum of curtailment over all regions and hours
parameter curtail_z_h (vre);
curtail_z_h(vre)=sum((z,h,r),curtail_disagg(z,h,vre,r))
*display curtail_z_h;

scalar curtail_tot;
curtail_tot = sum(h,curtail(h));

***************
*Transmission
***************

display var_trans_flow.l;

parameter trans_f1(z);
trans_f1(z)=sum(trans_links(z,z_alias,trans),var_trans_flow.l(z,"1",z_alias,trans));
*display trans_f1;

parameter trans_f2(z);
trans_f2(z)=sum(trans_links(z,z_alias,trans),var_trans_flow.l(z_alias,"1",z,trans));
*display trans_f2;

parameter trans_f(z,z_alias,h,trans);
trans_f(z,z_alias,h,trans)=var_trans_flow.l(z_alias,h,z,trans)$(var_trans_flow.l(z,h,z_alias,trans)>0);
*display trans_f;


*display var_trans_cap.L;


parameter trans_cap_tot total transmission capacity;
trans_cap_tot(trans)=sum((z,z_alias),var_trans_cap.L(z,z_alias,trans))/2  ;
*display trans_cap_tot;


*parameter trans_cap_tot(z_alias);
*trans_cap_tot(z_alias)=sum(z,var_trans_cap.L(z,z_alias))/2  ;
*display trans_cap_tot;

*parameter trans_cap_tot(z_alias);
*trans_cap_tot(z_alias)=sum(z,var_trans_cap.L(z,z_alias))  ;
*display trans_cap_tot;

***************
*Costs
***************

*parameter pen_gen_tot;
*pen_gen_tot=sum((z,h),p_gen.l(z,h));
*display pen_gen_tot;

***************
*Capacities
***************

parameter vre_cap_z(vre,z) zonal vre capacity;
vre_cap_z(vre,z)=sum(vre_lim(vre,z,r),var_vre_cap_r.l(z,r,vre));

parameter vre_cap_r(vre,r) regional vre capacity;
vre_cap_r(vre,r)=sum(vre_lim(vre,z,r),var_vre_cap_r.l(z,r,vre));

parameter vre_cap_tot(vre) total vre capacity;
vre_cap_tot(vre)=sum(vre_lim(vre,z,r),var_vre_cap_r.l(z,r,vre)) ;

display vre_cap_tot;
*display vre_cap_z;
*display vre_cap_r;
*display var_non_vre_cap.L;

*display vre_notwindoff;
*display vre_windoff;

***************
*Generation
***************
parameter vre_CF_r(vre_loadCF,r) average CF for each region;
vre_CF_r(vre_loadCF,r) = sum(h,vre_gen_load(vre_loadCF,r,h))/ card(h);

parameter non_vre_gen_tot(non_vre);
non_vre_gen_tot(non_vre)=sum((h,z),var_non_vre_gen.l(z,h,non_vre));
*display non_vre_gen_tot;

parameter non_vre_gen_out(non_vre,h);
non_vre_gen_out(non_vre,h)= sum(z,var_non_vre_gen.l(z,h,non_vre)$(var_non_vre_gen.l(z,h,non_vre) >0.));
*display non_vre_gen_out;

parameter vre_gen_out(vre,h);
vre_gen_out(vre,h)=sum((z,r),var_vre_gen.l(z,h,vre,r)$vre_lim(vre,z,r))
*display vre_gen_out;

parameter gen_out(g,h);
gen_out(vre,h)=vre_gen_out(vre,h) ;
gen_out(non_vre,h)=non_vre_gen_out(non_vre,h) ;

*display gen_out;

parameter vre_cap(vre);
vre_cap(vre)=sum((z,r),var_vre_cap_r.l(z,r,vre));
*display vre_cap;


***************
*Economics
***************

*zonal electricity price
*display eq_elc_balance.m ;
*display eq_gen_max.m;


parameter price(z,h);
price(z,h)=eq_elc_balance.m(z,h);
*display price   ;


*grossRet is the gross return fom power production (revenues - (variable)costs)

*gross Margins non VRE
parameter grossRet_non_vre(z,non_vre);
grossRet_non_vre(z,non_vre)=sum(h,((price(z,h)*var_non_vre_gen.L(z,h,non_vre))- (var_non_vre_gen.L(z,h,non_vre)*generator_varom(non_vre))))  ;
*display grossRet_non_vre;

*gross Margins VRE
parameter grossRet_vre(z,vre,r);
grossRet_vre(z,vre,r)=sum(h,(price(z,h)*var_vre_gen.L(z,h,vre,r))- (var_vre_gen.L(z,h,vre,r)*generator_varom(vre)))
*display grossRet_non_vre;

*gross Margins Storage
parameter grossRet_store(z,s);
grossRet_store(z,s)=sum(h,(price(z,h)*var_store_gen.L(z,h,s))- (var_store_gen.L(z,h,s)*storage_varom(s)))
*display grossRet_store;


scalar gen_costs;
gen_costs=sum((z,h,non_vre),var_non_vre_gen.l(z,h,non_vre)*generator_varom(non_vre))+sum((vre_lim(vre,z,r),h),var_vre_gen.l(z,h,vre,r)*generator_varom(vre));
*display gen_costs;

parameter sum_test;
sum_test=sum(vre_lim(vre,z,r),var_vre_cap.l(vre));
*display sum_test;

*display var_store_gen.L;

*sums up over all zones and gives installed capacity per renewable
parameter var_vre_cap_z_sum(vre,r);
var_vre_cap_z_sum(vre,r)=sum(z,var_vre_cap_r.l(z,r,vre));
*display var_vre_cap_z_sum    ;

parameter var_vre_cap_r_sum(z,vre) ;
var_vre_cap_r_sum(z,vre)=sum(r,var_vre_cap_r.l(z,r,vre));
*display var_vre_cap_r_sum;

*sums up over all zones and gives installed capacity per generation type
parameter var_non_vre_cap_z_sum(non_vre);
var_non_vre_cap_z_sum(non_vre)=sum(z,var_non_vre_cap_z.L(z,non_vre));
*display  var_non_vre_cap_z_sum;

*sums up over all hours +regions and gives the generated electricity per renewable type
parameter var_vre_gen_sum_r(vre);
var_vre_gen_sum_r(vre)=sum((z,h,r),var_vre_gen.L(z,h,vre,r));
*display var_vre_gen_sum_r;

*sums up over all hours +zones and gives the generated electricity per renewable type
parameter var_vre_gen_sum_z(vre,r);
var_vre_gen_sum_z(vre,r)=sum((z,h),var_vre_gen.L(z,h,vre,r));
*display var_vre_gen_sum_z;

parameter var_vre_gen_sum_r_z(z,vre) zonal generation by vre;
var_vre_gen_sum_r_z(z,vre)=sum((r,h),var_vre_gen.L(z,h,vre,r));
*display var_vre_gen_sum_r_z;

parameter var_vre_gen_sum_r_zone(z,h,vre) hourly zonal generation by vre;
var_vre_gen_sum_r_zone(z,h,vre)=sum((r),var_vre_gen.L(z,h,vre,r));
*display var_vre_gen_sum_r_zone;


*sums over all regions and zones and gives the generated electricity per generation type
parameter var_vre_gen_sum_h(h,vre) hourly generation by each vre type;
var_vre_gen_sum_h(h,vre)=sum((z,r),var_vre_gen.L(z,h,vre,r));
*display var_vre_gen_sum_h;

parameter var_non_vre_gen_sum_zone(z,non_vre) zonal generation by non_vre type;
var_non_vre_gen_sum_zone(z,non_vre)=sum(h,var_non_vre_gen.L(z,h,non_vre));
*display var_non_vre_gen_sum_zone;

*sums up over all hours +zones and gives the generated electricity per generation type
parameter var_non_vre_gen_sum_z(non_vre) total generation by each non_vre generator type;
var_non_vre_gen_sum_z(non_vre)=sum((z,h),var_non_vre_gen.L(z,h,non_vre));
display var_non_vre_gen_sum_z;

*sums over all zones and gives the generated electricity per generation type
parameter var_non_vre_gen_sum_h(h,non_vre) hourly generation by each non_vre generator type ;
var_non_vre_gen_sum_h(h,non_vre)=sum(z,var_non_vre_gen.L(z,h,non_vre));
display var_non_vre_gen_sum_h;

parameter var_store_gen_sum_h(h,s) hourly output from each storage type ;
var_store_gen_sum_h(h,s)=sum(z,var_store_gen.L(z,h,s));
display var_store_gen_sum_h;

parameter store_gen_z(z,s) total storage generation by zone;
store_gen_z(z,s) = sum(h,var_store_gen.L(z,h,s));

parameter store_gen_tot(s);
store_gen_tot(s) = sum((z,h),var_store_gen.L(z,h,s));


*parameter trans_cap_tot(z_alias);
*trans_cap_tot(z_alias)=sum(z,var_trans_cap.L(z,z_alias))  ;
*display trans_cap_tot;

*sums over all hours and gives the electricity generated per zone and storage technology
parameter var_store_gen_sum(z,s);
var_store_gen_sum(z,s)=sum(h,var_store_gen.L(z,h,s));
display var_store_gen_sum;

*sums over all hours and zones and gives the electricity generated per zone and storage technology
parameter var_store_gen_all(s);
var_store_gen_all(s)=sum((z,h),var_store_gen.L(z,h,s));
display var_store_gen_all;

*sums up over all hours +zones and gives the generated electricity per generation type
parameter var_non_vre_gen_sum_z(non_vre)  ;
var_non_vre_gen_sum_z(non_vre)=sum((z,h),var_non_vre_gen.L(z,h,non_vre));
display var_non_vre_gen_sum_z;

parameter var_vre_gen_sum_r(vre);
var_vre_gen_sum_r(vre)=sum((z,h,r),var_vre_gen.L(z,h,vre,r));
display var_vre_gen_sum_r;



display var_store_gen_cap_z.L;

display var_store_gen.L;
display var_non_vre_gen.L;
display var_vre_gen.L

;

parameter Residual_D(z,h) demand not met by vre;
Residual_D(z,h)=demand(z,h)-sum(vre,var_vre_gen_sum_r_zone(z,h,vre));
display Residual_D;


display var_store_gen_cap.L;

*Average electricity price
parameter price_mean(h);
price_mean(h)= sum((z,non_vre),(price(z,h)*var_non_vre_gen.L(z,h,non_vre))/sum(vre,var_vre_gen_sum_r(vre)))
display price_mean;


parameter price_mean(h);
price_mean(h)=
(sum((z,non_vre),(price(z,h)*var_non_vre_gen.L(z,h,non_vre)))
+sum((z,vre),(price(z,h)*var_vre_gen_sum_r_zone(z,h,vre)))
+sum((z,s),(price(z,h)*var_store_gen.L(z,h,s))))
/(sum((z,vre),var_vre_gen_sum_r_zone(z,h,vre))+
sum((z,non_vre),var_non_vre_gen.L(z,h,non_vre))
+sum((z,s),var_store_gen.L(z,h,s)));
display price_mean;
*display p_gen.L;




$ontext
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

* Quality control Parameters
parameter trans_f_001(z,z_alias,h,trans);
trans_f_001(z,z_alias,h,trans)=var_trans_flow.l(z_alias,h,z,trans)$(var_trans_flow.l(z,h,z_alias,trans)>0.01);
parameter trans_f_010(z,z_alias,h,trans);
trans_f_010(z,z_alias,h,trans)=var_trans_flow.l(z_alias,h,z,trans)$(var_trans_flow.l(z,h,z_alias,trans)>0.1);
parameter trans_f_100(z,z_alias,h,trans);
trans_f_100(z,z_alias,h,trans)=var_trans_flow.l(z_alias,h,z,trans)$(var_trans_flow.l(z,h,z_alias,trans)>1.0);

parameter maxtrans_001(trans);
maxtrans_001(trans)=smax((z,z_alias,h),trans_f_001(z,z_alias,h,trans));
parameter maxtrans_010(trans);
maxtrans_010(trans)=smax((z,z_alias,h),trans_f_010(z,z_alias,h,trans));
parameter maxtrans_100(trans);
maxtrans_100(trans)=smax((z,z_alias,h),trans_f_100(z,z_alias,h,trans));


*scalar dumpmax;
*dumpmax = smax((z,h),var_dump.l(z,h));
*display dumpmax;


* system losses
parameter storeloss_tot(s);
storeloss_tot(s) = sum(  (z,h)$s_lim(z,s),var_store.l(z,h,s)-var_store_gen.l(z,h,s)  );

scalar transloss_tot;
transloss_tot = sum((h,z,z_alias,trans)$trans_links(z,z_alias,trans),var_trans_flow.l(z,h,z_alias,trans)*(trans_loss_const(trans)+trans_links_dist(z,z_alias,trans)*trans_loss_grad(trans)));

*scalar dump_tot;
*dump_tot = sum((z,h),var_dump.l(z,h));

scalar cost_tot;
cost_tot = costs.l;



scalar vre_gen_alltot;
vre_gen_alltot = sum((z,h,vre,r)$vre_lim(vre,z,r),var_vre_gen.l(z,h,vre,r));

scalar nonvre_gen_alltot;
nonvre_gen_alltot = sum((z,h,non_vre)$non_vre_lim(z,non_vre),var_non_vre_gen.l(z,h,non_vre));

*scalar vre_pen_1;
*vre_pen_1 = sum((z,h,vre,r)$vre_lim(vre,z,r),var_vre_gen.L(z,h,vre,r)) / (storeloss_tot + transloss_tot + demand_tot);

scalar vre_pen_2;
vre_pen_2 = vre_gen_alltot / (vre_gen_alltot + nonvre_gen_alltot)

parameter non_vre_gen;
non_vre_gen(z,h,non_vre) = var_non_vre_gen.L(z,h,non_vre);

parameter store_gen;
store_gen(z,h,s) = var_store_gen.L(z,h,s);

parameter store_demand;
store_demand(z,h,s) =  var_store.L(z,h,s);


*Zero out select parameters to reduce file size
*Option Clear = eq_gen_vre,eq_area_max,vre_gen_load
waves_raw(r,h) = 0;
vre_gen_load(vre_loadCF,r,h) = 0;




Execute_Unload "%outname%.gdx"
execute "gdx2sqlite -i %outname%.gdx -o %outname%.db -fast -small"
$ontext

Execute_Unload "%outname%.gdx",
vre_pen_1,vre_pen_2,
*Costs
variableC,capitalC,variableStorageC,capitalStorageC,variableC_tot,capitalC_tot,
nonVREVarC,VREVarC,transVarC, nonVRECapC, VRECapC, transCapc,
maxtrans,storeloss_tot,transloss_tot,
costs.L,system_lcoe,cost_tot,
*Curtailment
curtail_z_h,curtail_z,curtail_tot,
*Transmission
trans_cap_tot,var_trans_cap.L,var_trans_flow.L,
*Capacities
var_vre_cap.L,var_non_vre_cap.L,var_store_gen_cap.L,
var_vre_cap.L,var_non_vre_cap.L, var_store_gen_cap.L,
var_non_vre_cap_z.L, var_vre_cap_r_sum,var_store_gen_cap_z.L,
vre_cap_tot,vre_cap_r,vre_cap_z,area,

*Generation
vre_CF_r,
var_vre_gen_sum_r,var_non_vre_gen_sum_z,var_store_gen_all,
var_vre_gen_sum_r_z,var_non_vre_gen_sum_zone, var_store_gen_sum,

store_gen,

non_vre_gen,  var_vre_gen_sum_r_zone,
var_vre_gen_sum_h,var_non_vre_gen_sum_h,var_store_gen_sum_h,
store_gen_tot,store_gen_z,
*Storage
var_store_level.L,store_demand,
*Residual Demand
Residual_D, Demand,
*Electricity price
price, price_mean
*Pengen
*p_gen.L,
*emissions
*emissions_all,emissions

;

Execute 'gdx2xls %outname%.gdx'
$offtext


