from extract import extract
from transform import transform
from load import load

def main():
    df1, df2 = extract()
    df = transform(df1, df2)
    load(df)
    print("ETL completado: dimensiones y fact cargadas.")

if __name__ == "__main__":
    main()