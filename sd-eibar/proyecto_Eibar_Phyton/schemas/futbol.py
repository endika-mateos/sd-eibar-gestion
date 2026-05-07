from pydantic import BaseModel
from typing import List, Optional, Union
from datetime import date, datetime

from schemas.player_stats import PlayerStatsResponse

# --- Esquemas para JUGADORES ---
class JugadorBase(BaseModel):
    nombre: str
    apellidos: str
    alias: Optional[str] = None
    posicion_habitual: Optional[str] = None
    estado: str = "activo"

class JugadorCreate(JugadorBase):
    pass # Se usa para el POST

class JugadorSchema(JugadorBase):
    id_jugador: int
    fecha_creacion: datetime

    class Config:
        from_attributes = True # Esto permite que Pydantic lea modelos de SQLAlchemy

# --- Esquemas para TEMPORADAS ---
class TemporadaBase(BaseModel):
    nombre: str
    fecha_inicio: Optional[date] = None
    fecha_fin: Optional[date] = None
    activa: bool = False

class TemporadaCreate(TemporadaBase):
    pass

class TemporadaSchema(TemporadaBase):
    id_temporada: int

    class Config:
        from_attributes = True

class InfoPartido(BaseModel):
    id_partido: int
    rival: str
    fecha: date

    class Config:
        from_attributes = True

class RendimientoJugador(BaseModel):
    jugador: JugadorSchema
    estadisticas: PlayerStatsResponse  # Aquí se usa el import de arriba
    nota: Union[float, str]

    class Config:
        from_attributes = True

class RespuestaEstadisticasPartido(BaseModel):
    informacion_partido: InfoPartido
    rendimiento_jugadores: List[RendimientoJugador]

    class Config:
        from_attributes = True