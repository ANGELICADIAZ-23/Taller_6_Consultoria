*==============================================================================
* TALLER 6 - EXPERIMENTOS | Consultoría: acueductos veredales
* PARTE 2.2 - DESCRIBIENDO DATOS  (P2.2.1 a P2.2.5)
*------------------------------------------------------------------------------
* Datos   : Herrmann, Thöni y Gächter (2008)
*             - Figura 3  : contribuciones SIN castigo (16 ciudades x 10 períodos)
*             - Figura 2A : contribuciones CON castigo (16 ciudades x 10 períodos)
* Entrada : RawData/doing-economics-datafile-working-in-excel-project-2.xlsx
* Salidas : Figures/Gráfica P.2.2.1  y  Gráfica P.2.2.2   (.gph y .png)
*           Tables/Tabla P2_2_1, P2_2_3, P2_2_4 y P2_2_5 (.xlsx)
*           Tables/Log P.2.2.txt
*
* USO     : solo ejecutar este do-file completo (Do). No hay que cambiar rutas:
*           el código ubica solo la raíz del repositorio clonado.
*
* Nota    : la unidad de observación es el PROMEDIO DE CADA CIUDAD (n = 16 por
*           experimento y período). Por eso la desviación estándar, la varianza,
*           el mínimo y el máximo describen la dispersión ENTRE ciudades.
*           La desviación estándar y la varianza son muestrales (divisor n-1),
*           igual que summarize/egen en Stata.
*==============================================================================

version 14
clear all
set more off
capture log close

*------------------------------------------------------------------------------
* 0. UBICAR LA RAÍZ DEL REPOSITORIO (sin rutas manuales)
*------------------------------------------------------------------------------
local archivo "RawData/doing-economics-datafile-working-in-excel-project-2.xlsx"
local raiz ""

* (a) La carpeta de trabajo es la raíz del repo, o una subcarpeta (p. ej. DoFiles)
foreach rel in "." ".." "../.." {
    if "`raiz'" == "" {
        capture confirm file "`rel'/`archivo'"
        if _rc == 0 {
            quietly cd "`rel'"
            local raiz "`c(pwd)'"
        }
    }
}

* (b) Si Stata está abierto en otra carpeta: buscar el repo en lugares habituales
if "`raiz'" == "" {
    local hogar : environment USERPROFILE
    if "`hogar'" == "" local hogar : environment HOME
    foreach base in "`hogar'/Documents/GitHub" "`hogar'/GitHub" ///
                    "`hogar'/OneDrive/Documents/GitHub" "`hogar'/Documents" ///
                    "`hogar'/Desktop" "`hogar'/Downloads" {
        if "`raiz'" == "" {
            local subs ""
            capture local subs : dir "`base'" dirs "*"
            foreach s of local subs {
                if "`raiz'" == "" {
                    capture confirm file "`base'/`s'/`archivo'"
                    if _rc == 0 local raiz "`base'/`s'"
                }
            }
        }
    }
}

if "`raiz'" == "" {
    display as error "No se encontró el repositorio (busqué RawData/doing-economics-datafile-working-in-excel-project-2.xlsx)."
    display as error "Verifique que el archivo esté en la carpeta RawData del repo clonado."
    display as error "Como último recurso: use el comando cd de Stata para entrar a la carpeta del repositorio y vuelva a ejecutar."
    exit 601
}

cd "`raiz'"
display as text "Raíz del repositorio: `c(pwd)'"

foreach carpeta in Figures Tables {
    capture mkdir "`carpeta'"
}

log using "Tables/Log P.2.2.txt", text replace


*------------------------------------------------------------------------------
* 1. IMPORTAR Y ORDENAR LOS DATOS (formato largo: una fila = ciudad x período x experimento)
*------------------------------------------------------------------------------
local datos "RawData/doing-economics-datafile-working-in-excel-project-2.xlsx"
local hoja  "Public goods contributions"

* 1.1 Nombres de las 16 ciudades (encabezados en la fila 2 de la hoja)
import excel "`datos'", sheet("`hoja'") cellrange(B2:Q2) allstring clear
local i = 0
foreach v of varlist * {
    local ++i
    local ciudad`i' = `v'[1]
}

* 1.2 Cada bloque de la hoja: Período en A, ciudades en B:Q
local rango0 "A3:Q12"      // Sin castigo (Figura 3)
local rango1 "A17:Q26"     // Con castigo (Figura 2A)

tempfile base
forvalues e = 0/1 {
    import excel "`datos'", sheet("`hoja'") cellrange(`rango`e'') clear
    rename A periodo
    local i = 0
    foreach v of varlist B-Q {
        local ++i
        rename `v' contrib`i'
    }
    quietly reshape long contrib, i(periodo) j(id_ciudad)
    gen byte castigo = `e'
    if `e' == 1 append using `base'
    save `base', replace
}

* 1.3 Etiquetas y orden
rename contrib contribucion
gen str30 ciudad = ""
forvalues i = 1/16 {
    replace ciudad = "`ciudad`i''" if id_ciudad == `i'
}

label define lbl_castigo 0 "Sin castigo" 1 "Con castigo"
label values castigo lbl_castigo
label variable castigo      "Experimento"
label variable periodo      "Período"
label variable id_ciudad    "ID de ciudad"
label variable ciudad       "Ciudad"
label variable contribucion "Contribución promedio de la ciudad (unidades del juego)"

order castigo periodo id_ciudad ciudad contribucion
sort castigo periodo id_ciudad

* 1.4 Verificaciones de integridad
assert _N == 320                         // 2 experimentos x 10 períodos x 16 ciudades
isid castigo periodo id_ciudad
assert !missing(contribucion)
assert inrange(contribucion, 0, 20)      // dotación de 20 unidades por jugador
assert inrange(periodo, 1, 10)

* Control contra el libro: la contribución promedio del Período 1 es 10.6 en ambos
foreach e in 0 1 {
    quietly summarize contribucion if castigo == `e' & periodo == 1
    assert abs(r(mean) - 10.6) < 0.05
}
display as text "Datos importados y verificados: 320 observaciones."


*------------------------------------------------------------------------------
* 2. P2.2.1  Contribución promedio por período, ambos experimentos
*------------------------------------------------------------------------------
preserve
    collapse (mean) media = contribucion, by(castigo periodo)
    reshape wide media, i(periodo) j(castigo)
    rename media0 media_sin
    rename media1 media_con
    gen dif = media_con - media_sin

    label variable periodo    "Período"
    label variable media_sin  "Contribución promedio SIN castigo (Figura 3)"
    label variable media_con  "Contribución promedio CON castigo (Figura 2A)"
    label variable dif        "Diferencia (con - sin castigo)"

    display as text _n "P2.2.1 - Contribución promedio por período"
    list periodo media_sin media_con dif, noobs sep(0) abbreviate(12)

    * Tabla
    foreach v of varlist media_sin media_con dif {
        replace `v' = round(`v', 0.001)
    }
    export excel periodo media_sin media_con dif using "Tables/Tabla P2_2_1.xlsx", ///
        sheet("P.2.2.1") firstrow(varlabels) replace

    * Gráfico de líneas
    twoway ///
        (connected media_sin periodo, lcolor("0 114 178") mcolor("0 114 178") ///
            msymbol(O) lpattern(solid) lwidth(medthick)) ///
        (connected media_con periodo, lcolor("213 94 0") mcolor("213 94 0") ///
            msymbol(D) lpattern(dash) lwidth(medthick)), ///
        title("Contribución promedio por período") ///
        subtitle("Juego de bienes públicos con y sin castigo (promedio de 16 ciudades)") ///
        xtitle("Período") ///
        ytitle("Contribución promedio (unidades del juego)") ///
        xlabel(1(1)10) ///
        ylabel(0(5)20, angle(horizontal) grid glcolor(gs14)) yscale(range(0 20)) ///
        legend(order(1 "Sin castigo" 2 "Con castigo") rows(1) position(6) ///
            region(lstyle(none))) ///
        note("Fuente: Herrmann, Thöni y Gächter (2008), datos de las Figuras 3 y 2A.") ///
        graphregion(color(white)) scheme(s1color) name(g_221, replace)

    graph save "Figures/Gráfica P.2.2.1.gph", replace
    graph export "Figures/Gráfica P.2.2.1.png", as(png) width(2000) replace
restore


*------------------------------------------------------------------------------
* 3. P2.2.2  Gráfico de columnas: Período 1 vs Período 10, ambos experimentos
*------------------------------------------------------------------------------
graph bar (mean) contribucion if inlist(periodo, 1, 10), ///
    over(castigo) over(periodo, relabel(1 "Período 1" 2 "Período 10")) asyvars ///
    bar(1, color("0 114 178")) bar(2, color("213 94 0")) ///
    blabel(bar, position(outside) format(%4.1f)) ///
    title("Contribución promedio en el primer y último período") ///
    subtitle("Con y sin castigo (promedio de 16 ciudades)") ///
    ytitle("Contribución promedio (unidades del juego)") ///
    ylabel(0(5)20, angle(horizontal) grid glcolor(gs14)) yscale(range(0 20)) ///
    legend(rows(1) position(6) region(lstyle(none))) ///
    note("Fuente: Herrmann, Thöni y Gächter (2008), datos de las Figuras 3 y 2A.") ///
    graphregion(color(white)) scheme(s1color) name(g_222, replace)

graph save "Figures/Gráfica P.2.2.2.gph", replace
graph export "Figures/Gráfica P.2.2.2.png", as(png) width(2000) replace


*------------------------------------------------------------------------------
* 4. P2.2.3, P2.2.4 y P2.2.5  Estadísticos descriptivos de los Períodos 1 y 10
*------------------------------------------------------------------------------
preserve
    keep if inlist(periodo, 1, 10)

    * Regla práctica: ¿qué proporción de ciudades cae dentro de la media +/- 1 y 2 DE?
    bysort castigo periodo: egen double m_aux = mean(contribucion)
    bysort castigo periodo: egen double s_aux = sd(contribucion)
    gen byte dentro_1de = abs(contribucion - m_aux) <= 1 * s_aux
    gen byte dentro_2de = abs(contribucion - m_aux) <= 2 * s_aux

    * Ciudades con el valor mínimo y máximo de cada grupo
    bysort castigo periodo (contribucion): gen str30 ciudad_min = ciudad[1]
    bysort castigo periodo (contribucion): gen str30 ciudad_max = ciudad[_N]

    collapse (count) n = contribucion                     ///
             (mean)  media = contribucion                 ///
             (sd)    desv = contribucion                  ///
             (min)   minimo = contribucion                ///
             (max)   maximo = contribucion                ///
             (sum)   dentro_1de dentro_2de                ///
             (first) ciudad_min ciudad_max,               ///
             by(castigo periodo)

    label values castigo lbl_castigo

    gen varianza       = desv^2
    gen rango          = maximo - minimo
    gen lim_inf        = media - 2 * desv
    gen lim_sup        = media + 2 * desv
    gen pct_dentro_1de = 100 * dentro_1de / n
    gen pct_dentro_2de = 100 * dentro_2de / n

    label variable castigo        "Experimento"
    label variable periodo        "Período"
    label variable n              "N (ciudades)"
    label variable media          "Media"
    label variable varianza       "Varianza"
    label variable desv           "Desviación estándar"
    label variable minimo         "Mínimo"
    label variable maximo         "Máximo"
    label variable rango          "Rango (máx - mín)"
    label variable ciudad_min     "Ciudad con el mínimo"
    label variable ciudad_max     "Ciudad con el máximo"
    label variable lim_inf        "Media - 2 DE"
    label variable lim_sup        "Media + 2 DE"
    label variable dentro_1de     "N dentro de ±1 DE"
    label variable pct_dentro_1de "% dentro de ±1 DE"
    label variable dentro_2de     "N dentro de ±2 DE"
    label variable pct_dentro_2de "% dentro de ±2 DE"

    sort castigo periodo
    foreach v of varlist media varianza desv minimo maximo rango lim_inf lim_sup ///
                         pct_dentro_1de pct_dentro_2de {
        replace `v' = round(`v', 0.001)
    }

    * ---- P2.2.3  Desviación estándar y regla práctica ------------------------
    display as text _n "P2.2.3 - Desviación estándar y regla práctica (media +/- 2 DE)"
    list castigo periodo n media desv lim_inf lim_sup dentro_2de pct_dentro_2de, ///
        noobs sepby(castigo) abbreviate(14)
    export excel castigo periodo n media desv lim_inf lim_sup dentro_1de ///
        pct_dentro_1de dentro_2de pct_dentro_2de using "Tables/Tabla P2_2_3.xlsx", ///
        sheet("P.2.2.3") firstrow(varlabels) replace

    * ---- P2.2.4  Máximos y mínimos -------------------------------------------
    display as text _n "P2.2.4 - Valores mínimo y máximo"
    list castigo periodo minimo ciudad_min maximo ciudad_max, ///
        noobs sepby(castigo) abbreviate(14)
    export excel castigo periodo minimo ciudad_min maximo ciudad_max ///
        using "Tables/Tabla P2_2_4.xlsx", ///
        sheet("P.2.2.4") firstrow(varlabels) replace

    * ---- P2.2.5  Tabla resumen -----------------------------------------------
    display as text _n "P2.2.5 - Tabla de estadísticas descriptivas"
    list castigo periodo n media varianza desv minimo maximo rango, ///
        noobs sepby(castigo) abbreviate(12)
    export excel castigo periodo n media varianza desv minimo maximo rango ///
        using "Tables/Tabla P2_2_5.xlsx", ///
        sheet("P.2.2.5") firstrow(varlabels) replace
restore


*------------------------------------------------------------------------------
* 5. CIERRE
*------------------------------------------------------------------------------
display as text _n "Parte 2.2 terminada. Archivos generados en Figures/ y Tables/."
log close
