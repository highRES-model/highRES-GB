parameters

abstract_coeffs(non_vre)
/
$BATINCLUDE generator_abstract.dd
/

consum_coeffs(non_vre)
/
$BATINCLUDE generator_consume.dd
/

abstract_lim(z,h)
/
$BATINCLUDE abstract_lim_%water_restrict%.dd
/

consum_lim(z,h)
/
$BATINCLUDE consumption_lim_%water_restrict%.dd
/
;

equations
eq_abstract_lim
eq_consum_lim

;

set water_lim(z);
water_lim(z)=(sum(h,abstract_lim(z,h))>0. and sum(h,consum_lim(z,h)>0.));

set water_tech(non_vre);
water_tech(non_vre)=(abstract_coeffs(non_vre) > 0. and consum_coeffs(non_vre) > 0.);

eq_abstract_lim(z,h)$(water_lim(z)) .. sum(non_vre,var_non_vre_gen(z,h,non_vre)*abstract_coeffs(non_vre)) =L= abstract_lim(z,h) ;

eq_consum_lim(z,h)$(water_lim(z)) .. sum(non_vre,var_non_vre_gen(z,h,non_vre)*consum_coeffs(non_vre)) =L= consum_lim(z,h) ;

