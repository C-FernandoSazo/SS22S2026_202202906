import pandas as pd

def _parse_dt(series):
    # Formato primario: dd/mm/yyyy hh:mm
    result = pd.to_datetime(series, dayfirst=True, errors="coerce")

    # Formato secundario: MM-DD-YYYY hh:mm AM/PM
    mask = result.isna()
    if mask.any():
        result[mask] = pd.to_datetime(
            series[mask],
            format="%m-%d-%Y %I:%M %p",
            errors="coerce"
        )
    return result

def _clean_str(s):
    s = s.astype("string").str.strip()
    s = s.str.upper()
    s = s.replace({"": pd.NA, "NAN": pd.NA, "NONE": pd.NA, "NULL": pd.NA})
    return s

def transform(df1: pd.DataFrame, df2: pd.DataFrame) -> pd.DataFrame:
    df1 = df1.copy()
    df2 = df2.copy()

    # --- Normalización básica (strings) ---
    for col in ["airline_code", "origin_airport", "destination_airport", "aircraft_type", "cabin_class", "status"]:
        if col in df1.columns:
            df1[col] = _clean_str(df1[col])

    for col in ["sales_channel", "payment_method", "currency", "passenger_gender", "passenger_nationality"]:
        if col in df2.columns:
            df2[col] = _clean_str(df2[col])

    # --- Fechas ---
    df1["departure_datetime"] = _parse_dt(df1.get("departure_datetime"))
    df1["arrival_datetime"]   = _parse_dt(df1.get("arrival_datetime"))
    df2["booking_datetime"]   = _parse_dt(df2.get("booking_datetime"))

    # --- Numéricos ---
    if "ticket_price" in df2.columns:
        # convierte "77,60" -> "77.60"
        df2["ticket_price"] = (
            df2["ticket_price"].astype(str)
            .str.replace(",", ".", regex=False)
        )
        df2["ticket_price"] = pd.to_numeric(df2["ticket_price"], errors="coerce")

    for col in ["ticket_price_usd_est", "bags_total", "bags_checked", "passenger_age"]:
        if col in df2.columns:
            df2[col] = pd.to_numeric(df2[col], errors="coerce")

    df2["passenger_age"] = pd.to_numeric(df2["passenger_age"], errors="coerce").astype("Int64")

    for col in ["duration_min", "delay_min"]:
        if col in df1.columns:
            df1[col] = pd.to_numeric(df1[col], errors="coerce")

    # delays nulos -> 0
    if "delay_min" in df1.columns:
        df1["delay_min"] = df1["delay_min"].fillna(0)

    # --- Merge final por record_id ---
    df = pd.merge(df1, df2, on="record_id", how="inner")

    return df