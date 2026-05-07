from fastapi import FastAPI
from config.database import Base, engine
# Importamos los modelos para que Base.metadata.create_all sepa qué tablas existen
from models import player_stats, tablas_principales 
from routers import player_stats # Y otros routers que crees

# Esto intenta crear las tablas en MySQL si no existen
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Sistema Fútbol API")

# Incluimos los routers
app.include_router(player_stats.router)
# Si creas más, los añades aquí:
# app.include_router(usuarios.router)

@app.get("/")
def read_root():
    return {"message": "API de Sistema Fútbol conectada a MySQL (XAMPP)"}