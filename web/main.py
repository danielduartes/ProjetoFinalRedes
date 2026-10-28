import os
import psycopg2
from fastapi import FastAPI

app = FastAPI()

def conectar():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "10.0.3.10"),
        dbname="app_db",
        user="app_user",
        password=os.getenv("DB_PASSWORD", "123"),
        connect_timeout=5,
    )

@app.on_event("startup")
def criar_tabela():
    with conectar() as conn, conn.cursor() as cur:
        cur.execute("CREATE TABLE IF NOT EXISTS mensagens (id SERIAL PRIMARY KEY, texto TEXT NOT NULL)")

@app.post("/mensagens")
def criar(texto: str):
    with conectar() as conn, conn.cursor() as cur:
        cur.execute("INSERT INTO mensagens (texto) VALUES (%s) RETURNING id", (texto,))
        return {"id": cur.fetchone()[0], "texto": texto}

@app.get("/mensagens")
def listar():
    with conectar() as conn, conn.cursor() as cur:
        cur.execute("SELECT id, texto FROM mensagens ORDER BY id")
        return [{"id": i, "texto": t} for i, t in cur.fetchall()]
