* ==============================================================================
* TALLER 6: CONSULTORÍA EN EXPERIMENTOS Y JUEGOS DE BIENES PÚBLICOS
* Proyecto: Análisis de comportamiento para acueductos veredales
* Script 01: Importación de datos y gráfico de contribución promedio (P2.1)
* ==============================================================================

clear all
set more off

* 1. Cargar la base de datos de clase desde la carpeta RawData
import excel "RawData/datos.xlsx", sheet("Hoja1") firstrow clear

* 2. Renombrar variables para facilidad de manejo
rename Round ronda
rename Playerscontributions contribucion
rename PayoffsinthisGame pago

* 3. Calcular la contribución promedio por ronda y generar la gráfica (P2.1.1)
preserve
    * Colapsar la base de datos para obtener la media por cada período
    collapse (mean) contrib_prom = contribucion, by(ronda)
    
    * Generar el gráfico de líneas de la contribución promedio
    twoway (line contrib_prom ronda, sort lwidth(medium) lcolor(navy) mcolor(navy)), ///
        title("Contribución Promedio por Ronda") ///
        subtitle("Experimento de Clase - Juego de Bienes Públicos") ///
        xtitle("Ronda (1 a 10)") ///
        ytitle("Contribución Promedio") ///
        xlabel(1(1)10, grid)
        
    * Exportar automáticamente la gráfica a la carpeta Figures
    graph export "Figures/grafico_clase.png", replace
restore

* Fin del script 01 (Parte 2.1)
