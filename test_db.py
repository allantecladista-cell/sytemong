import psycopg2
from config import Config

try:
    conn = psycopg2.connect(
        dbname=Config.DB_NAME,
        user=Config.DB_USER,
        password=Config.DB_PASSWORD,
        host=Config.DB_HOST,
        port=Config.DB_PORT
    )
    cur = conn.cursor()
    cur.execute("SELECT 1;")
    result = cur.fetchone()
    print("Conexão OK! Resultado do teste:", result)
    cur.close()
    conn.close()
except Exception as e:
    print("Erro ao conectar ao banco:", e)
