import pandas as pd

DATASET1_PATH = "../data/Dataset 1.csv"
DATASET2_PATH = "../data/Dataset 2.csv"

def extract():
    df1 = pd.read_csv(DATASET1_PATH)              
    df2 = pd.read_csv(DATASET2_PATH, sep=";")      

    # Asegura unión por record_id (df2 no trae record_id, lo creamos)
    df2 = df2.copy()
    df2["record_id"] = range(1, len(df2) + 1)

    return df1, df2