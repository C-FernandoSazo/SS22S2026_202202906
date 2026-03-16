# Informe – Práctica 2

## Implementación de Dashboard Analítico en Power BI

### 1. Introducción

El objetivo de esta práctica fue construir un sistema de análisis de datos basado en un modelo dimensional tipo **estrella** y desarrollar un **dashboard interactivo en Power BI** que permita analizar información relacionada con vuelos y venta de boletos.

Para ello se utilizó una base de datos en **SQL Server**, donde se modelaron dimensiones y una tabla de hechos que posteriormente fueron conectadas a Power BI para realizar análisis mediante medidas DAX y visualizaciones interactivas.

---

# 2. Modelo Dimensional

El modelo implementado sigue la arquitectura **Star Schema**, donde una tabla de hechos central almacena las métricas principales y se relaciona con varias tablas de dimensión que describen el contexto del evento.

## Tabla de Hechos

**FactTicketFlight**

Contiene la información principal de cada ticket de vuelo, incluyendo métricas y claves hacia las dimensiones.

Principales métricas:

* `ticket_price`
* `ticket_price_usd_est`
* `duration_min`
* `delay_min`
* `bags_total`
* `bags_checked`

También contiene atributos operativos como:

* número de vuelo
* asiento
* estado del vuelo

---

## Dimensiones

Se crearon varias dimensiones para describir el contexto del ticket de vuelo.

### DimPassenger

Contiene información del pasajero:

* género
* edad
* nacionalidad

Esta dimensión permite realizar análisis demográficos.

---

### DimAirline

Contiene información de las aerolíneas:

* código de aerolínea
* nombre de aerolínea

Permite analizar ingresos y operaciones por aerolínea.

---

### DimAirport

Contiene los códigos de aeropuerto utilizados en los vuelos.

Se utiliza para identificar aeropuertos de origen y destino.

---

### DimAircraft

Describe el tipo de aeronave utilizada en el vuelo.

---

### DimCabin

Contiene la clase de cabina del pasajero, por ejemplo:

* Economy
* Business
* First Class

---

### DimSalesChannel

Indica el canal mediante el cual se vendió el ticket.

---

### DimPaymentMethod

Describe el método de pago utilizado en la compra del ticket.

---

### DimCurrency

Permite identificar la moneda utilizada en la transacción.

---

### DimDateTime

Dimensión temporal que permite analizar los datos en función del tiempo.

Contiene atributos como:

* año
* mes
* día
* hora
* minuto

---

# 3. Relaciones del Modelo

La tabla **FactTicketFlight** se relaciona con todas las dimensiones mediante claves sustitutas.

Algunas de las relaciones más importantes son:

* FactTicketFlight → DimPassenger
* FactTicketFlight → DimAirline
* FactTicketFlight → DimAirport (origen y destino)
* FactTicketFlight → DimDateTime

Esto permite realizar análisis multidimensionales del negocio.

---

# 4. Jerarquías Implementadas

Se crearon jerarquías dentro del modelo para facilitar la exploración de datos.

### Jerarquía temporal

DimDateTime:

```
Year → Month → Day
```

Esta jerarquía permite analizar los datos por diferentes niveles de tiempo.

---

### Jerarquía de aerolínea

DimAirline:

```
Airline Name → Airline Code
```

Permite explorar información por aerolínea y su código correspondiente.

---

### Jerarquía demográfica

DimPassenger:

```
Passenger Nationality → Passenger Gender
```

Esta jerarquía permite analizar el comportamiento de los pasajeros según su origen y género.

---

# 5. Medidas DAX Implementadas

Para realizar los análisis se implementaron varias medidas utilizando **DAX**.

### Total de Tickets

```DAX
Total Tickets = COUNT(FactTicketFlight[record_id])
```

Calcula la cantidad total de tickets vendidos.

---

### Ingresos Totales

```DAX
Ingresos Totales USD =
SUM(FactTicketFlight[ticket_price_usd_est])
```

Calcula el ingreso total estimado en dólares.

---

### Delay Promedio

```DAX
Delay Promedio =
AVERAGE(FactTicketFlight[delay_min])
```

Permite analizar el retraso promedio de los vuelos.

---

### Porcentaje de vuelos cancelados

```DAX
Porcentaje Cancelados =
DIVIDE([Vuelos Cancelados],[Total Tickets],0)
```

Esta medida calcula el porcentaje de vuelos cancelados sobre el total de tickets.

---

# 6. Indicadores KPI

Se implementaron indicadores clave de desempeño (KPI) para monitorear métricas importantes del sistema.

### KPI de ingresos

El KPI compara los **ingresos totales obtenidos** con una **meta de ingresos definida**, permitiendo evaluar si el desempeño financiero se encuentra por encima o por debajo del objetivo establecido.

---

### KPI de retrasos

Se implementó también un KPI basado en el **delay promedio**, comparándolo contra un valor objetivo para analizar el desempeño operativo de los vuelos.

---

# 7. Dashboard Analítico

El dashboard desarrollado permite visualizar la información mediante gráficos interactivos.

Entre las visualizaciones implementadas se encuentran:

### Tarjetas de indicadores

Se muestran indicadores clave como:

* Total de tickets
* Ingresos totales
* Delay promedio
* Porcentaje de vuelos cancelados

---

### Gráfico de líneas

Muestra la evolución de la cantidad de tickets a lo largo del tiempo por mes.

---

### Gráfico de barras

Permite analizar los ingresos totales por aerolínea.

---

### Gráfico de cascada

Permite observar la contribución de cada aerolínea al total de ingresos.

---

### Gráfico de pastel

Muestra la distribución de pasajeros por género.

---

### Segmentadores interactivos

Se implementaron filtros que permiten al usuario seleccionar:

* mes
* otros atributos

Esto permite explorar los datos de forma interactiva.

---

# 8. Conclusiones

El uso de un modelo dimensional tipo estrella permite organizar los datos de manera eficiente para análisis multidimensional.

La integración con Power BI facilita la creación de dashboards interactivos que permiten analizar métricas clave del negocio como ingresos, volumen de tickets y desempeño operativo de los vuelos.

Las visualizaciones implementadas permiten identificar patrones importantes en los datos y facilitan la toma de decisiones basada en información.

---

# 9. Análisis e Insights del Dashboard

A partir del dashboard construido se pueden identificar varios patrones relevantes en los datos.

## Distribución de pasajeros por género

El gráfico de distribución de pasajeros por género muestra que la mayoría de los tickets corresponden a pasajeros **masculinos y femeninos**, mientras que el grupo identificado como **X** representa una proporción mucho menor del total.

Esto sugiere que la distribución de pasajeros se concentra principalmente en dos categorías principales de género.

---

## Evolución de tickets a lo largo del tiempo

El gráfico de líneas muestra la evolución del número de tickets vendidos por mes.

Se observa que la cantidad de tickets se mantiene relativamente estable durante los meses analizados, con pequeñas variaciones entre aproximadamente **720 y 830 tickets por mes**.

Esto indica que la demanda de vuelos presenta cierta estabilidad en el periodo analizado.

---

## Ingresos generados por aerolínea

El gráfico de ingresos por aerolínea permite identificar qué compañías generan mayor volumen de ingresos.

Se observa que algunas aerolíneas concentran una mayor participación en los ingresos totales, lo que puede indicar una mayor demanda o mayor precio promedio de sus vuelos.

Este tipo de análisis permite identificar **las aerolíneas con mayor impacto financiero dentro del sistema**.

---

## Análisis del retraso promedio

El indicador de **delay promedio** muestra que el retraso medio de los vuelos se encuentra alrededor de **27 minutos**, superando la meta establecida de **15 minutos**.

Esto sugiere que existe margen de mejora en el desempeño operativo de los vuelos.

Este tipo de métrica es importante para evaluar la calidad del servicio y la puntualidad de las operaciones.

---

## Porcentaje de vuelos cancelados

El dashboard también incluye el cálculo del **porcentaje de vuelos cancelados**, el cual representa una fracción pequeña del total de vuelos registrados.

Esto indica que la mayoría de las operaciones se realizan con normalidad y que las cancelaciones representan un porcentaje relativamente bajo del total de tickets.

---

## Contribución de aerolíneas al total de ingresos

El gráfico de cascada permite observar cómo cada aerolínea contribuye al total de ingresos.

Este tipo de visualización facilita identificar la participación individual de cada compañía en el ingreso global del sistema.

---

# 10. Conclusión General

La implementación del modelo dimensional y del dashboard en Power BI permitió transformar los datos operativos de vuelos en información analítica útil para la toma de decisiones.

El dashboard desarrollado permite monitorear indicadores clave como ingresos, volumen de tickets, retrasos y cancelaciones, además de ofrecer herramientas interactivas para explorar los datos desde diferentes perspectivas.

El uso de visualizaciones, jerarquías y segmentadores facilita el análisis multidimensional de la información y demuestra el potencial de las herramientas de Business Intelligence para el análisis de datos en sistemas de transporte aéreo.

---
