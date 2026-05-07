from sqlalchemy import Column, Integer, String, Boolean, Date, Enum, TIMESTAMP,Float, func
from config.database import Base

class Usuario(Base):
    __tablename__ = "usuarios"
    id_usuario = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre_usuario = Column(String(50), unique=True, nullable=False)
    contrasena_hash = Column(String(255), nullable=False) # Nota: En tu SQL pusiste 'contraseña_hash', pero es mejor evitar la 'ñ' en código
    rol = Column(Enum('admin', 'entrenador', 'analista'), nullable=False)
    fecha_creacion = Column(TIMESTAMP, server_default=func.now())

class Temporada(Base):
    __tablename__ = "temporadas"
    id_temporada = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre = Column(String(20), nullable=False)
    fecha_inicio = Column(Date)
    fecha_fin = Column(Date)
    activa = Column(Boolean, default=False)

class Jugador(Base):
    __tablename__ = "jugadores"
    id_jugador = Column(Integer, primary_key=True, index=True, autoincrement=True)
    nombre = Column(String(50), nullable=False)
    apellidos = Column(String(50), nullable=False)
    alias = Column(String(50))
    posicion_habitual = Column(String(50))
    estado = Column(Enum('activo', 'lesionado', 'baja'), default='activo')
    fecha_creacion = Column(TIMESTAMP, server_default=func.now())

class Partido(Base):
    __tablename__ = "partidos"
    id_partido = Column(Integer, primary_key=True, index=True, autoincrement=True)
    id_temporada = Column(Integer)
    fecha = Column(Date, nullable=False)
    competicion = Column(String(100))
    rival = Column(String(100))
    local_visitante = Column(Enum('local', 'visitante'))
    goles_favor = Column(Integer, default=0)
    goles_contra = Column(Integer, default=0)

class Puntuacion(Base):
    __tablename__ = "puntuaciones"
    id_puntuacion = Column(Integer, primary_key=True, index=True, autoincrement=True)
    id_partido = Column(Integer)
    id_jugador = Column(Integer)
    posicion_evaluada = Column(String(50))
    puntuacion_final = Column(Float) # Esta será la "nota" que devuelvas