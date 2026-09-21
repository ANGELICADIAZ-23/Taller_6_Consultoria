*==============================================================================
* Taller 6 - Consultoria acueductos veredales
* Seccion 2.3.do
* Ejecutar parado en la carpeta DoFiles
*==============================================================================

clear all
set more off
version 17

local raw "../RawData"
local out "../Tables"
capture mkdir "`out'"

capture log close
log using "`out'/Seccion_2_3.txt", text replace

* P2.3.1 simulacion de lanzamientos de moneda
display as text _n "=== P2.3.1 ==="

set seed 20260916

clear
set obs 10000
gen int caras = rbinomial(6, 0.5)
label variable caras "Numero de caras en 6 lanzamientos"

tabulate caras
summarize caras

clear
set obs 10000
gen int tanda_a = rbinomial(6, 0.5)
gen int tanda_b = rbinomial(6, 0.5)
gen byte difieren = (tanda_a != tanda_b)

summarize difieren

* Datos Herrmann et al. (2008)
local archivo "`raw'/doing-economics-datafile-working-in-excel-project-2.xlsx"
local hoja    "Public goods contributions"

import excel using "`archivo'", sheet("`hoja'") cellrange(A3:Q12) clear
rename A periodo
rename (B C D E F G H I J K L M N O P Q) ///
       (contribucion1 contribucion2 contribucion3 contribucion4 ///
        contribucion5 contribucion6 contribucion7 contribucion8 ///
        contribucion9 contribucion10 contribucion11 contribucion12 ///
        contribucion13 contribucion14 contribucion15 contribucion16)
gen byte castigo = 0
tempfile sincastigo
save `sincastigo'

import excel using "`archivo'", sheet("`hoja'") cellrange(A17:Q26) clear
rename A periodo
rename (B C D E F G H I J K L M N O P Q) ///
       (contribucion1 contribucion2 contribucion3 contribucion4 ///
        contribucion5 contribucion6 contribucion7 contribucion8 ///
        contribucion9 contribucion10 contribucion11 contribucion12 ///
        contribucion13 contribucion14 contribucion15 contribucion16)
gen byte castigo = 1

append using `sincastigo'
reshape long contribucion, i(periodo castigo) j(ciudad)

label define castigo 0 "Sin castigo" 1 "Con castigo"
label values castigo castigo

assert _N == 320

tempfile herrmann
save `herrmann'

* P2.3.2 prueba t en el periodo 1
display as text _n "=== P2.3.2 ==="

tabstat contribucion if periodo == 1, by(castigo) ///
    statistics(n mean sd min max) columns(statistics) format(%9.3f)

ttest contribucion if periodo == 1, by(castigo)

scalar dif_p1 = r(mu_2) - r(mu_1)
scalar t_p1   = r(t)
scalar p_p1   = r(p)
display as result "Diferencia (con - sin), periodo 1: " %6.3f dif_p1
display as result "t = " %6.3f t_p1 "   valor p = " %6.4f p_p1

ttest contribucion if periodo == 1, by(castigo) unequal

* P2.3.3 prueba t en el periodo 10
display as text _n "=== P2.3.3 ==="

tabstat contribucion if periodo == 10, by(castigo) ///
    statistics(n mean sd min max) columns(statistics) format(%9.3f)

ttest contribucion if periodo == 10, by(castigo)

scalar dif_p10 = r(mu_2) - r(mu_1)
scalar t_p10   = r(t)
scalar p_p10   = r(p)
display as result "Diferencia (con - sin), periodo 10: " %6.3f dif_p10
display as result "t = " %6.3f t_p10 "   valor p = " %6.4f p_p10

ttest contribucion if periodo == 10, by(castigo) unequal

* Robustez: prueba pareada por ciudad
display as text _n "=== Robustez: prueba pareada ==="

foreach p in 1 10 {
    use `herrmann', clear
    keep if periodo == `p'
    keep ciudad castigo contribucion
    reshape wide contribucion, i(ciudad) j(castigo)
    rename contribucion0 sin_castigo
    rename contribucion1 con_castigo
    display as text _n "Periodo `p'"
    ttest con_castigo == sin_castigo
}

log close

display as result _n "Seccion 2.3.do finalizado sin errores."
