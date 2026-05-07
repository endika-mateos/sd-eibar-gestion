from sqlalchemy import Column, Integer, String, Float
from config.database import Base

class PlayerStats(Base):
    __tablename__ = "player_stats"
    __tablename__ = "estadisticas_jugador_partido"

    id = Column(Integer, primary_key=True, index=True)
    id_estadistica = Column(Integer, primary_key=True, index=True, autoincrement=True)

    id_partido = Column(Integer) 
    id_jugador = Column(Integer) 

    posicion_jugada = Column(String(50))
    minutos_jugados = Column(Integer)

    partido = Column(String(255))
    competicion = Column(String(255))
    date = Column(String(15))
    posicion = Column(String(50))
    minutos = Column(Integer)

    # General y Ofensivo
    acciones_totales = Column(Integer)
    acciones_exitosas = Column(Integer)
    goles = Column(Integer)
    asistencias = Column(Integer)
    tiros_totales = Column(Integer)
    tiros_puerta = Column(Integer)
    xg = Column(Float)
    xa = Column(Float)
    asistencias_tiro = Column(Integer)
    segundas_asistencias = Column(Integer)

    # Pases y Distribución
    pases_totales = Column(Integer)
    pases_completados = Column(Integer)
    pases_largos_totales = Column(Integer)
    pases_largos_completados = Column(Integer)
    centros_totales = Column(Integer)
    centros_precisos = Column(Integer)
    pases_profundidad_totales = Column(Integer)
    pases_profundidad_completados = Column(Integer)
    pases_area_totales = Column(Integer)
    pases_area_completados = Column(Integer)
    pases_adelante_totales = Column(Integer)
    pases_adelante_completados = Column(Integer)
    pases_atras_totales = Column(Integer)
    pases_atras_completados = Column(Integer)
    pases_recibidos = Column(Integer)

    # Duelos y Regates
    regates_totales = Column(Integer)
    regates_exitosos = Column(Integer)
    duelos_totales = Column(Integer)
    duelos_ganados = Column(Integer)
    duelos_aereos_totales = Column(Integer)
    duelos_aereos_ganados = Column(Integer)
    duelos_defensivos_totales = Column(Integer)
    duelos_defensivos_ganados = Column(Integer)
    duelos_ofensivos_totales = Column(Integer)
    duelos_ofensivos_ganados = Column(Integer)

    # Movimiento y Defensa
    carreras_profundidad = Column(Integer)
    intercepciones = Column(Integer)
    despejes = Column(Integer)
    perdidas_totales = Column(Integer)
    perdidas_propia_mitad = Column(Integer)
    recuperaciones_totales = Column(Integer)
    recuperaciones_mitad_rival = Column(Integer)

    # Disciplina
    tarjetas_amarillas = Column(Integer)
    tarjetas_rojas = Column(Integer)