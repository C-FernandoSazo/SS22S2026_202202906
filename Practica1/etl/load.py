import pandas as pd
import pyodbc
from config import CONN_STR

def _to_py(v):
    """Convierte valores pandas/numpy a tipos Python compatibles con pyodbc."""
    if v is None:
        return None
    if pd.isna(v):
        return None
    if isinstance(v, pd.Timestamp):
        return v.to_pydatetime()
    try:
        import numpy as np
        if isinstance(v, (np.integer,)):
            return int(v)
        if isinstance(v, (np.floating,)):
            return float(v)
    except Exception:
        pass
    return v

def _insert_dim(cursor, table, cols, df_unique):
    placeholders = ",".join(["?"] * len(cols))
    col_list = ",".join(cols)
    sql = f"INSERT INTO dbo.{table} ({col_list}) VALUES ({placeholders});"

    for row in df_unique[cols].itertuples(index=False, name=None):
        row = tuple(_to_py(v) for v in row)
        try:
            cursor.execute(sql, row)
        except pyodbc.IntegrityError:
            pass
        except Exception as e:
            raise RuntimeError(f"Error insertando en {table} con row={row}") from e


def _fetch_key_map(cursor, table, natural_col, key_col):
    cursor.execute(f"SELECT {key_col}, {natural_col} FROM dbo.{table};")
    # Normalizar a minúsculas para comparación case-insensitive
    return {str(nat).lower(): key for (key, nat) in cursor.fetchall()}

def _fetch_dt_map(cursor):
    cursor.execute("SELECT DateTimeKey, dt FROM dbo.DimDateTime;")
    out = {}
    for key, dt in cursor.fetchall():
        out[dt.strftime("%Y-%m-%d %H:%M:%S")] = key
    return out

def _dt_to_key(series: pd.Series, dt_map: dict):
    s = pd.to_datetime(series, errors="coerce")
    s = s.dt.strftime("%Y-%m-%d %H:%M:%S")
    return s.map(dt_map)

def load(df: pd.DataFrame):
    conn = pyodbc.connect(CONN_STR)
    conn.autocommit = False
    cur = conn.cursor()

    # ---------- DIMENSIONS ----------
    dim_passenger = df[["passenger_id", "passenger_gender", "passenger_age", "passenger_nationality"]].drop_duplicates()
    _insert_dim(cur, "DimPassenger",
                ["passenger_id", "passenger_gender", "passenger_age", "passenger_nationality"],
                dim_passenger)

    dim_airline = df[["airline_code", "airline_name"]].drop_duplicates()
    _insert_dim(cur, "DimAirline", ["airline_code", "airline_name"], dim_airline)

    airports = pd.concat([
        df[["origin_airport"]].rename(columns={"origin_airport": "airport_code"}),
        df[["destination_airport"]].rename(columns={"destination_airport": "airport_code"}),
    ]).drop_duplicates()
    _insert_dim(cur, "DimAirport", ["airport_code"], airports)

    dim_aircraft = df[["aircraft_type"]].drop_duplicates()
    _insert_dim(cur, "DimAircraft", ["aircraft_type"], dim_aircraft)

    dim_cabin = df[["cabin_class"]].drop_duplicates()
    _insert_dim(cur, "DimCabin", ["cabin_class"], dim_cabin)

    dim_sc = df[["sales_channel"]].drop_duplicates()
    _insert_dim(cur, "DimSalesChannel", ["sales_channel"], dim_sc)

    dim_pm = df[["payment_method"]].drop_duplicates()
    _insert_dim(cur, "DimPaymentMethod", ["payment_method"], dim_pm)

    dim_cur = df[["currency"]].drop_duplicates()
    _insert_dim(cur, "DimCurrency", ["currency"], dim_cur)

    dt_all = pd.concat([
        df[["booking_datetime"]].rename(columns={"booking_datetime": "dt"}),
        df[["departure_datetime"]].rename(columns={"departure_datetime": "dt"}),
        df[["arrival_datetime"]].rename(columns={"arrival_datetime": "dt"}),
    ]).dropna().drop_duplicates()

    dt_all = dt_all.copy()
    dt_all["year"]   = dt_all["dt"].dt.year
    dt_all["month"]  = dt_all["dt"].dt.month
    dt_all["day"]    = dt_all["dt"].dt.day
    dt_all["hour"]   = dt_all["dt"].dt.hour
    dt_all["minute"] = dt_all["dt"].dt.minute

    _insert_dim(cur, "DimDateTime", ["dt", "year", "month", "day", "hour", "minute"], dt_all)

    conn.commit()

    # ---------- MAP KEYS ----------
    passenger_map = _fetch_key_map(cur, "DimPassenger", "passenger_id", "PassengerKey")
    airline_map   = _fetch_key_map(cur, "DimAirline",   "airline_code", "AirlineKey")
    airport_map   = _fetch_key_map(cur, "DimAirport",   "airport_code", "AirportKey")
    aircraft_map  = _fetch_key_map(cur, "DimAircraft",  "aircraft_type", "AircraftKey")
    cabin_map     = _fetch_key_map(cur, "DimCabin",     "cabin_class",  "CabinKey")
    sc_map        = _fetch_key_map(cur, "DimSalesChannel",  "sales_channel",  "SalesChannelKey")
    pm_map        = _fetch_key_map(cur, "DimPaymentMethod", "payment_method", "PaymentMethodKey")
    cur_map       = _fetch_key_map(cur, "DimCurrency",  "currency", "CurrencyKey")

    # ---------- FACT ----------
    fact = df.copy()

    # Normalizar a minúsculas para que coincidan con las keys del mapa
    fact["PassengerKey"]          = fact["passenger_id"].astype("string").str.lower().map(passenger_map)
    fact["AirlineKey"]            = fact["airline_code"].astype("string").str.lower().map(airline_map)
    fact["OriginAirportKey"]      = fact["origin_airport"].astype("string").str.lower().map(airport_map)
    fact["DestinationAirportKey"] = fact["destination_airport"].astype("string").str.lower().map(airport_map)
    fact["AircraftKey"]           = fact["aircraft_type"].astype("string").str.lower().map(aircraft_map)
    fact["CabinKey"]              = fact["cabin_class"].astype("string").str.lower().map(cabin_map)
    fact["SalesChannelKey"]       = fact["sales_channel"].astype("string").str.lower().map(sc_map)
    fact["PaymentMethodKey"]      = fact["payment_method"].astype("string").str.lower().map(pm_map)
    fact["CurrencyKey"]           = fact["currency"].astype("string").str.lower().map(cur_map)

    dt_map = _fetch_dt_map(cur)

    fact["BookingDateKey"]   = _dt_to_key(fact["booking_datetime"],  dt_map)
    fact["DepartureDateKey"] = _dt_to_key(fact["departure_datetime"], dt_map)
    fact["ArrivalDateKey"]   = _dt_to_key(fact["arrival_datetime"],   dt_map)

    print("Missing BookingDateKey:",        fact["BookingDateKey"].isna().sum())
    print("Missing PassengerKey:",          fact["PassengerKey"].isna().sum())
    print("Missing AirlineKey:",            fact["AirlineKey"].isna().sum())
    print("Missing OriginAirportKey:",      fact["OriginAirportKey"].isna().sum())
    print("Missing DestinationAirportKey:", fact["DestinationAirportKey"].isna().sum())

    insert_cols = [
        "record_id",
        "PassengerKey","AirlineKey","OriginAirportKey","DestinationAirportKey",
        "AircraftKey","CabinKey","SalesChannelKey","PaymentMethodKey","CurrencyKey",
        "BookingDateKey","DepartureDateKey","ArrivalDateKey",
        "flight_number","seat","status",
        "ticket_price","ticket_price_usd_est","duration_min","delay_min","bags_total","bags_checked"
    ]

    placeholders = ",".join(["?"] * len(insert_cols))
    col_list     = ",".join(insert_cols)
    sql_ins = f"INSERT INTO dbo.FactTicketFlight ({col_list}) VALUES ({placeholders});"

    missing = fact[fact["DestinationAirportKey"].isna() | fact["OriginAirportKey"].isna()]
    print("Missing airport keys:", len(missing))
    if len(missing) > 0:
        print(missing[["record_id","origin_airport","destination_airport"]].head(10))

    for row in fact[insert_cols].itertuples(index=False, name=None):
        row = tuple(_to_py(v) for v in row)
        try:
            cur.execute(sql_ins, row)
        except pyodbc.IntegrityError:
            pass

    conn.commit()
    cur.close()
    conn.close()