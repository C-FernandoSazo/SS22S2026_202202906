# Modelo constelación 

## Hechos

* `FactCompras`
* `FactVentas`

## Dimensiones compartidas

* `DimTiempo`
* `DimProducto`
* `DimSucursal`

## Dimensiones específicas

* `DimProveedor`
* `DimCliente`
* `DimVendedor`

---

# Tablas de hechos

## FactCompras

**Una fila representa una compra de un producto, en una fecha, a un proveedor, para una sucursal.**

## FactVentas

**Una fila representa una venta de un producto, en una fecha, a un cliente, realizada por un vendedor, en una sucursal.**

---

# Dimensiones

## DimTiempo

Se comparte entre compras y ventas.

### Campos

* `TiempoKey`
* `FechaCompleta`
* `Dia`
* `Mes`
* `NombreMes`
* `Trimestre`
* `Anio`

### Jerarquía SSAS

* **Año > Trimestre > Mes > Día**

---

## DimProducto

Compartida entre compras y ventas.

### Campos

* `ProductoKey`
* `CodProducto`
* `NombreProducto`
* `MarcaProducto`
* `Categoria`

### Jerarquía

* **Categoría > Marca > Producto**

---

## DimSucursal

Compartida entre compras y ventas.

### Campos

* `SucursalKey`
* `CodSucursal`
* `NombreSucursal`
* `Departamento`
* `Region`

### Jerarquía

* **Región > Departamento > Sucursal**

---

## DimProveedor

Solo para compras.

### Campos

* `ProveedorKey`
* `CodProveedor`
* `NombreProveedor`

---

## DimCliente

Solo para ventas.

### Campos

* `ClienteKey`
* `CodCliente`
* `NombreCliente`
* `TipoCliente`

### Jerarquía opcional

* **TipoCliente > Cliente**

---

## DimVendedor

Solo para ventas.

### Campos

* `VendedorKey`
* `CodVendedor`
* `NombreVendedor`

---

# Tablas de hechos finales

## FactCompras

### Llaves foráneas

* `TiempoKey`
* `ProductoKey`
* `SucursalKey`
* `ProveedorKey`

### Medidas

* `UnidadesCompradas`
* `CostoUnitario`
* `PrecioUnitario` ← **agregado para análisis de margen cruzado con FactVentas**
* `MontoCompra`

### Fórmulas

* `MontoCompra = UnidadesCompradas * CostoUnitario`
* `Margen = PrecioUnitario - CostoUnitario` *(medida calculada en SSAS, no columna física)*

### Estructura

* `CompraKey`
* `TiempoKey`
* `ProductoKey`
* `SucursalKey`
* `ProveedorKey`
* `UnidadesCompradas`
* `CostoUnitario`
* `PrecioUnitario`
* `MontoCompra`

---

## FactVentas

### Llaves foráneas

* `TiempoKey`
* `ProductoKey`
* `SucursalKey`
* `ClienteKey`
* `VendedorKey`

### Medidas

* `UnidadesVendidas`
* `PrecioUnitario`
* `MontoVenta`

### Fórmula

* `MontoVenta = UnidadesVendidas * PrecioUnitario`

### Estructura

* `VentaKey`
* `TiempoKey`
* `ProductoKey`
* `SucursalKey`
* `ClienteKey`
* `VendedorKey`
* `UnidadesVendidas`
* `PrecioUnitario`
* `MontoVenta`

---

## Núcleo compartido

* `DimTiempo`
* `DimProducto`
* `DimSucursal`

## Proceso 1: Compras

* `FactCompras`
* `DimProveedor`

## Proceso 2: Ventas

* `FactVentas`
* `DimCliente`
* `DimVendedor`