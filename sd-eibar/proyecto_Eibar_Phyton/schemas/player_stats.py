from pydantic import BaseModel

class PlayerStatsBase(BaseModel):
    partido: str
    competicion: str
    date: str
    posicion: str
    minutos: int
    
    acciones_totales: int
    acciones_exitosas: int
    goles: int
    asistencias: int
    tiros_totales: int
    tiros_puerta: int
    xg: float
    xa: float
    asistencias_tiro: int
    segundas_asistencias: int
    
    pases_totales: int
    pases_completados: int
    pases_largos_totales: int
    pases_largos_completados: int
    centros_totales: int
    centros_precisos: int
    pases_profundidad_totales: int
    pases_profundidad_completados: int
    pases_area_totales: int
    pases_area_completados: int
    pases_adelante_totales: int
    pases_adelante_completados: int
    pases_atras_totales: int
    pases_atras_completados: int
    pases_recibidos: int
    
    regates_totales: int
    regates_exitosos: int
    duelos_totales: int
    duelos_ganados: int
    duelos_aereos_totales: int
    duelos_aereos_ganados: int
    duelos_defensivos_totales: int
    duelos_defensivos_ganados: int
    duelos_ofensivos_totales: int
    duelos_ofensivos_ganados: int
    
    carreras_profundidad: int
    intercepciones: int
    despejes: int
    perdidas_totales: int
    perdidas_propia_mitad: int
    recuperaciones_totales: int
    recuperaciones_mitad_rival: int
    
    tarjetas_amarillas: int
    tarjetas_rojas: int

class PlayerStatsCreate(PlayerStatsBase):
    pass

class PlayerStatsResponse(PlayerStatsBase):
    id: int

    class Config:
        from_attributes = True