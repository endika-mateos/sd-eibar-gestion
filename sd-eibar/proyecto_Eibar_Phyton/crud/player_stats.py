from sqlalchemy.orm import Session
from models.player_stats import PlayerStats
from schemas.player_stats import PlayerStatsCreate

def get_all_stats(db: Session):
    return db.query(PlayerStats).all()

def get_stats_by_competition(db: Session, competicion: str):
    return db.query(PlayerStats).filter(
        PlayerStats.competicion == competicion
    ).all()

def create_stat(db: Session, stat: PlayerStatsCreate):
    db_stat = PlayerStats(**stat.model_dump())
    db.add(db_stat)
    db.commit()
    db.refresh(db_stat)
    return db_stat