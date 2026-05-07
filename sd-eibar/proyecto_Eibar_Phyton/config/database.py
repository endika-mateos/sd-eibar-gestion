from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker


# Configuración de la URL para XAMPP
# usuario: root | contraseña: 1234 | host: localhost | puerto: 3306 | bd: sistema_futbol
USER = "root"
PASSWORD = ""
HOST = "localhost"
PORT = "3306"
BD = "sistema_futbol"
SQLALCHEMY_DATABASE_URL = f"mysql+pymysql://{USER}:{PASSWORD}@{HOST}:{PORT}/{BD}"


# Creamos el motor de conexión
engine = create_engine(
    SQLALCHEMY_DATABASE_URL
)


# Sesión para interactuar con la BD
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)




def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# Base para los modelos
Base = declarative_base()

