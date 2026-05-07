from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import text 
from config.database import SessionLocal
from typing import List, Dict, Any
import crud
from datetime import datetime
from schemas.player_stats import PlayerStatsCreate, PlayerStatsResponse
import math
import pandas as pd
import numpy as np
import re
import os

router = APIRouter(prefix="/stats", tags=["Player Stats"])

#Variables estaticas
NOTA_BASE = 5.0
NOMBRE_EQUIPO_PROPIO = "XXXX"
POSICIONES_MAP = {
        "GK": "POR", "CB": "DFC", "RB": "LD", "LB": "LI",
        "DMF": "MCD", "CMF": "MC", "AMF": "MCO", "LAMF": "MCO", "RAMF": "MCO","CAM": "MCO","CDM": "MCD", "CM": "MC",
        "RWF": "EXTD", "LWF": "EXTI", "LW": "EXTI", "RW": "EXTD", "CF": "DC", "ST":"DC"
}
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR = os.path.join(BASE_DIR, "data")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

@router.get("/", response_model=list[PlayerStatsResponse])
def read_stats(db: Session = Depends(get_db)):
    return crud.get_all_stats(db)

@router.get("/competition/{competicion}", response_model=list[PlayerStatsResponse])
def read_by_competition(competicion: str, db: Session = Depends(get_db)):
    return crud.get_stats_by_competition(db, competicion)

@router.post("/", response_model=PlayerStatsResponse)
def create_stat(stat: PlayerStatsCreate, db: Session = Depends(get_db)):
    return crud.create_stat(db, stat)

def limpiar_datos_jugador(datos_recibidos: List[Dict[str, Any]], jugador_id: int, db: Session):
    df = pd.DataFrame(datos_recibidos)
    errores_leves = []
    errores_graves = []
    
    #Verificamos que hayan llegado datos
    if df.empty:
        return [], 0, 0, "No se recibieron datos para procesar."

    #Limpieza inicial de valores nulos
    pseudo_nulos = ["-", "n/a", "N/A", "null", " ", "???", ""]
    df.replace(pseudo_nulos, np.nan, inplace=True)

    indices_a_eliminar = []

    #Validación de ERRORES GRAVES
    for indice, fila in df.iterrows():
        motivos_grave = []
        valor_partido = str(fila.get('Partido', ''))
        patron_resultado = r'(.+) - (.+) (\d+):(\d+)'
        
        #Validaciones de campos OBLIGATORIOS
        if pd.isna(fila.get('Partido')):
            motivos_grave.append("Falta el campo 'Partido'")
        
        fecha_partido = fila.get('Date')
        if pd.isna(fecha_partido):
            motivos_grave.append("Falta el campo 'Date'")

        #Validación de formato y duplicados en Base de Datos
        coincidencia = re.match(patron_resultado, valor_partido)
        if not coincidencia:
            motivos_grave.append("Formato de 'Partido' incorrecto")
        elif not pd.isna(fecha_partido):
            # Si el formato es OK y hay fecha, buscamos si ya existe en la BD
            equipo_local, equipo_visitante, _, _ = coincidencia.groups()
            # Determinamos quién es el rival
            rival = equipo_visitante.strip() if NOMBRE_EQUIPO_PROPIO.lower() in equipo_local.lower() else equipo_local.strip()
            
            # CONSULTA DE DUPLICADOS:
            # Buscamos si ya existe una puntuación o estadística para este jugador en este partido/fecha
            consulta_duplicado = text("""
                SELECT p.id_partido 
                FROM partidos p
                JOIN puntuaciones pun ON p.id_partido = pun.id_partido
                WHERE pun.id_jugador = :id_j 
                  AND p.rival = :rival 
                  AND p.fecha = :fecha
                LIMIT 1
            """)
            
            existe = db.execute(consulta_duplicado, {
                "id_j": jugador_id, 
                "rival": rival, 
                "fecha": fecha_partido
            }).fetchone()

            if existe:
                motivos_grave.append(f"El jugador ya tiene puntuaciones registradas para el partido contra {rival} en fecha {fecha_partido}")

        #Validar Minutos jugados
        try:
            minutos = float(fila.get('Minutos jugados'))
            if pd.isna(minutos):
                motivos_grave.append("Falta el campo 'Minutos jugados'")
        except (ValueError, TypeError):
            motivos_grave.append("'Minutos jugados' no es un número válido")

        if motivos_grave:
            errores_graves.append({
                "partido_indice": indice,
                "referencia": valor_partido if valor_partido != 'nan' else "Desconocido",
                "detalles": motivos_grave
            })
            indices_a_eliminar.append(indice)

    # Eliminar partidos con errores graves
    df_limpio = df.drop(indices_a_eliminar).copy()

    # Validación de ERRORES LEVES (Rellenar con 0)
    columnas_identidad = ['Partido', 'Competition', 'Date', 'Posición específica']
    for columna in df_limpio.columns:
        if columna not in columnas_identidad:
            df_limpio[columna] = pd.to_numeric(df_limpio[columna], errors='coerce')
            nulos_en_columna = df_limpio[df_limpio[columna].isna()].index.tolist()
            for idx in nulos_en_columna:
                errores_leves.append({
                    "partido": df_limpio.at[idx, 'Partido'],
                    "campo": columna,
                    "mensaje": "Valor no encontrado, puesto a 0"
                })
            df_limpio[columna] = df_limpio[columna].fillna(0)

    explicacion = (
        f"Limpieza finalizada. {len(df_limpio)} partidos listos. "
        f"{len(errores_graves)} descartados (errores de formato o ya existentes en BD). "
        f"{len(errores_leves)} correcciones leves."
    )

    return df_limpio.to_dict(orient='records'), len(errores_leves), len(errores_graves), explicacion

def obtener_o_crear_temporada(fecha_str, db):
    fecha = datetime.strptime(fecha_str, "%Y-%m-%d")
    mes = fecha.month
    año = fecha.year

    # Si es agosto o posterior, la temporada empieza este año. Si no, empezó el anterior.
    if mes >= 8:
        año_inicio = año
        año_fin = año + 1
    else:
        año_inicio = año - 1
        año_fin = año
    
    nombre_temporada = f"{año_inicio}/{str(año_fin)[2:]}"

    # Buscar si existe
    consulta = text("SELECT id_temporada FROM temporadas WHERE nombre = :n")
    resultado = db.execute(consulta, {"n": nombre_temporada}).fetchone()

    if resultado:
        return resultado[0]
    
    # Si no existe, crearla (1 de Agosto al 30 de Julio)
    inicio = f"{año_inicio}-08-01"
    fin = f"{año_fin}-07-31"
    
    insertar = text("""
        INSERT INTO temporadas (nombre, fecha_inicio, fecha_fin, activa) 
        VALUES (:n, :i, :f, false)
    """)
    db.execute(insertar, {"n": nombre_temporada, "i": inicio, "f": fin})
    db.commit()
    
    # Recuperar el ID recién creado
    return db.execute(consulta, {"n": nombre_temporada}).fetchone()[0]

@router.get("/score-batch")
def score_batch(rival: str, fecha: str, db: Session = Depends(get_db)): 

    #Buscar partido
    consulta_partido = text("SELECT * FROM partidos WHERE rival = :rival AND fecha = :fecha")
    partido = db.execute(consulta_partido, {"rival": rival, "fecha": fecha}).mappings().fetchone()

    if not partido:
        raise HTTPException(status_code=404, detail="Partido no encontrado")

    id_partido = partido["id_partido"]

    # Buscar estadísticas
    consulta_stats = text("SELECT * FROM estadisticas_jugador_partido WHERE id_partido = :id_p")
    estadisticas = db.execute(consulta_stats, {"id_p": id_partido}).mappings().fetchall()

    if not estadisticas:
        raise HTTPException(
            status_code=404,
            detail="No hay estadísticas en ese partido"
        )

    # Buscar puntuaciones
    consulta_puntuaciones = text("SELECT * FROM puntuaciones WHERE id_partido = :id_p")
    puntuaciones = db.execute(consulta_puntuaciones, {"id_p": id_partido}).mappings().fetchall()

    return {
        "partido": partido,
        "estadisticas": estadisticas,
        "puntuaciones": puntuaciones
    }



@router.post("/score")
def score(payload: Dict[str, Any], db: Session = Depends(get_db)):

    #Recoger id del jugador y el nombre del archivo
    jugador_id = payload.get("id")
    nombre_archivo = payload.get("ruta_excel")
    ruta_excel = os.path.join(DATA_DIR, nombre_archivo)

    if not jugador_id or not nombre_archivo:
        raise HTTPException(status_code=400, detail="Faltan parámetros")

    res_jugador = db.execute(text("SELECT id_jugador, nombre, apellidos FROM jugadores WHERE id_jugador = :id"), {"id": jugador_id}).fetchone()
    if not res_jugador:
        raise HTTPException(status_code=404, detail="Jugador no encontrado")

    id_db, nombre, apellidos = res_jugador
    resumen_partidos = []

    #leer excel y solucionar problema cabeceras separadas con /
    try:
        df_excel = pd.read_excel(ruta_excel, dtype=str)
        nuevas_columnas = []
        for i, col in enumerate(df_excel.columns):
            col_str = str(col).strip()
            if col_str.startswith("Unnamed:"):
                prev_col = str(df_excel.columns[i-1]).strip()
                if "/" in prev_col:
                    partes = prev_col.split("/")
                    nuevas_columnas.append(f"{partes[0].strip()} {partes[1].strip()}")
                else: nuevas_columnas.append(col_str)
            elif "/" in col_str: nuevas_columnas.append(col_str.split("/")[0].strip())
            else: nuevas_columnas.append(col_str)
        df_excel.columns = nuevas_columnas
        df_excel.fillna(0, inplace=True)
        lista_partidos = df_excel.to_dict(orient='records')
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error Excel: {str(e)}")

    #limpieza de datos recogidos
    partidos_limpios, _, _, _ = limpiar_datos_jugador(lista_partidos, jugador_id, db)
    if not partidos_limpios:
        return {"estado": "Sin cambios", "mensaje": "No hay partidos nuevos."}

    #conseguimos la configuracion de pesos activa
    config_id = db.execute(text("SELECT id_configuracion FROM configuraciones_pesos WHERE activa = 1")).scalar() or 1

    #obtenemos los datos del partido 
    for p_datos in partidos_limpios:
        texto_partido = str(p_datos.get("Partido", "Desconocido"))
        fecha_partido = p_datos.get("Date")
        
        coincidencia = re.match(r"(.+) - (.+) (\d+):(\d+)", texto_partido)
        if not coincidencia: continue
        eq_l, eq_v, g_l, g_v = coincidencia.groups()
        soy_local = 1 if NOMBRE_EQUIPO_PROPIO.lower() in eq_l.lower() else 0
        rival = eq_v.strip() if soy_local else eq_l.strip()
        id_temp = obtener_o_crear_temporada(fecha_partido, db)
        partido_existente = db.execute(text("SELECT id_partido FROM partidos WHERE rival=:r AND fecha=:f"), {"r": rival, "f": fecha_partido}).fetchone()
        
        if partido_existente:
            id_partido = partido_existente[0]
        else:  
            #si no existe creamos el partido en nuestra base de datos y obtenemos el id
            res_ins = db.execute(text("INSERT INTO partidos (id_temporada, rival, fecha, goles_favor, goles_contra, local_visitante, competicion) VALUES (:t, :r, :f, :gf, :gc, :lv, :c)"),
                {"t": id_temp, "r": rival, "f": fecha_partido, "gf": int(g_l if soy_local else g_v), "gc": int(g_v if soy_local else g_l), "lv": "local" if soy_local else "visitante", "c": p_datos.get("Competition")})
            id_partido = res_ins.lastrowid
            db.commit()

        minutos = float(p_datos.get("Minutos jugados", 90))
        def get_v(nombres_posibles):
            # Si nos pasan un solo string, lo metemos en una lista para que el bucle funcione
            if isinstance(nombres_posibles, str):
                nombres_posibles = [nombres_posibles]
        
            for nombre in nombres_posibles:
                if nombre in p_datos and p_datos[nombre] is not None:
            # Intentamos convertir a float, si hay algo raro (como un texto), devolvemos 0
                    try:
                        return float(p_datos[nombre])
                    except (ValueError, TypeError):
                        continue
            return 0.0

        raw_stats = {
            "acciones_totales": get_v(["Acciones totales"]),
            "acciones_logradas": get_v(["Acciones logradas", "Acciones totales logradas"]),
            "goles": get_v(["Goles"]),
            "asistencias": get_v(["Asistencias"]),
            "tiros_totales": get_v(["Tiros"]),
            "tiros_logrados": get_v(["Tiros logrados"]),
            "xg": get_v(["xG"]),
            "xa": get_v(["xA"]),
            "pases_totales": get_v(["Pases"]),
            "pases_completados": get_v(["Pases logrados"]),
            "pases_largos_totales": get_v(["Pases largos"]),
            "pases_largos_logrados": get_v(["Pases largos logrados"]),
            "pases_area_penalti_totales": get_v(["Pases hacia el área de penalti"]),
            "pases_area_penalti_logrados": get_v(["Pases hacia el área de penalti precisos"]),
            "pases_profundidad_totales": get_v(["Pases en profundidad"]),
            "pases_profundidad_logrados": get_v(["Pases en profundidad logrados"]),
            "pases_hacia_delante_totales": get_v(["Pases hacia adelante"]),
            "pases_hacia_delante_logrados": get_v(["Pases hacia adelante logrados"]),
            "pases_recibidos": get_v(["Pases recibidos"]),
            "duelos_totales": get_v(["Duelos"]),
            "duelos_ganados": get_v(["Duelos ganados"]),
            "duelos_defensivos_totales": get_v(["Duelos defensivos"]),
            "duelos_defensivos_ganados": get_v(["Duelos defensivos ganados"]),
            "duelos_ofensivos_totales": get_v(["Duelos ofensivos"]),
            "duelos_ofensivos_ganados": get_v(["Duelos ofensivos ganados"]),
            "duelos_aereos_totales": get_v(["Duelos aéreos"]),
            "duelos_aereos_ganados": get_v(["Duelos aéreos ganados"]),
            "regates_totales": get_v(["Regates"]),
            "regates_logrados": get_v(["Regates logrados"]),
            "interceptaciones": get_v(["Interceptaciones"]),
            "balones_recuperados": get_v(["Balones recuperados"]),
            "balones_perdidos_totales": get_v(["Balones perdidos"]),
            "asistencias_tiro": get_v(["Asistencias a tiro"]),
            "carreras_profundidad": get_v(["Carreras en profundidad"])
        }

        # Calculamos estadisticas de fallo
        raw_stats["acciones_fallidas"] = max(0, raw_stats["acciones_totales"] - raw_stats["acciones_logradas"])
        raw_stats["pases_fallados"] = max(0, raw_stats["pases_totales"] - raw_stats["pases_completados"])
        raw_stats["duelos_perdidos"] = max(0, raw_stats["duelos_totales"] - raw_stats["duelos_ganados"])
        raw_stats["tiros_fallados"] = max(0, raw_stats["tiros_totales"] - raw_stats["tiros_logrados"])

        # Calculo de nota por bloques y equivalencia de posicion
        pos_orig_raw = str(p_datos.get("Posición específica", "MC")).strip().upper()
        pos_orig = pos_orig_raw.split(',')[0].strip()
        pos_f = POSICIONES_MAP.get(pos_orig, "MC")
        
        pesos = db.execute(text("SELECT bloque, clave_metrica, porcentaje, penaliza FROM pesos_metrica_posicion WHERE codigo_posicion=:p AND id_configuracion=:c"), {"p": pos_f, "c": config_id}).fetchall()
        
        bloques = {"ataque": 0.0, "construccion": 0.0, "defensa": 0.0}
        factor_90 = 90.0 / minutos if minutos > 0 else 1.0

        for p in pesos:
            valor_metrica = raw_stats.get(str(p.clave_metrica).lower(), 0.0) * factor_90
            impacto = valor_metrica * float(p.porcentaje)
            
            if bool(p.penaliza):
                bloques[p.bloque] -= impacto
            else:
                bloques[p.bloque] += impacto


        bloque_ataque = max(0.0, bloques["ataque"])
        bloque_const = max(0.0, bloques["construccion"])
        bloque_def = max(0.0, bloques["defensa"])
        
        # La nota final empieza en 5.0 y suma/resta los bloques
        nota_final = max(0.0, min(10.0, 5.0 + sum(bloques.values())))

        # Guardar en DB
        db.execute(text("""
            INSERT INTO estadisticas_jugador_partido (
                id_partido, id_jugador, posicion_jugada, minutos_jugados, 
                goles, asistencias, tiros_totales, tiros_logrados, xg, xa,
                pases_totales, pases_completados, pases_largos_totales, pases_largos_logrados,
                duelos_totales, duelos_ganados,regates_totales,regates_exitosos, interceptaciones, balones_recuperados,
                balones_perdidos_totales, tarjeta_amarilla, tarjeta_roja, archivo_origen, fecha_creacion
            ) VALUES (
                :id_p, :id_j, :pos, :min, 
                :gol, :asi, :tt, :tl, :xg, :xa,
                :pt, :pc, :plt, :pll,
                :dt, :dg, :rt, :rl, :inter, :br,
                :bpt, :ta, :tr, :ao, :fc
            )
        """), {
            "id_p": id_partido, "id_j": id_db, "pos": pos_orig, "min": minutos,
            "gol": raw_stats["goles"], "asi": raw_stats["asistencias"],
            "tt": raw_stats["tiros_totales"], "tl": raw_stats["tiros_logrados"],
            "xg": raw_stats["xg"], "xa": raw_stats["xa"],
            "pt": raw_stats["pases_totales"], "pc": raw_stats["pases_completados"],
            "plt": raw_stats["pases_largos_totales"], "pll": raw_stats["pases_largos_logrados"],
            "dt": raw_stats["duelos_totales"], "dg": raw_stats["duelos_ganados"],
            "inter": raw_stats["interceptaciones"], "br": raw_stats["balones_recuperados"],
            "bpt": raw_stats["balones_perdidos_totales"],
            "ta": p_datos.get("Tarjeta amarilla", 0), "tr": p_datos.get("Tarjeta roja", 0),
            "ao": nombre_archivo, "fc":datetime.now(), "rt": raw_stats["regates_totales"], "rl": raw_stats["regates_logrados"]
        })

        # Guardar Puntuación
        db.execute(text("""
            INSERT INTO puntuaciones (id_partido, id_jugador, posicion_evaluada, puntuacion_ataque, 
            puntuacion_construccion, puntuacion_defensa, puntuacion_final, fecha_creacion) 
            VALUES (:ip, :ij, :pe, :pa, :pc, :pd, :pf, :fc)
        """), {
            "ip": id_partido, "ij": id_db, "pe": pos_orig, 
            "pa": round(bloque_ataque, 2), "pc": round(bloque_const, 2), "pd": round(bloque_def, 2), 
            "pf": round(nota_final, 2), "fc": datetime.now()
        })



        db.commit()

        
        resumen_partidos.append({
            "partido": rival,
            "fecha": str(fecha_partido),
            "nota": round(nota_final, 2),
            "posicion": pos_orig
        })

    return {
        "estado": "Éxito",
        "jugador": f"{nombre} {apellidos}",
        "total_procesados": len(partidos_limpios),
        "resumen": resumen_partidos 
    }


@router.get("/compare-position")
def compare_position(id_estadistica: int, nueva_posicion: str, db: Session = Depends(get_db)):

    query_stats = text("""
        SELECT s.*, j.nombre, j.apellidos, p.fecha, p.rival
        FROM estadisticas_jugador_partido s
        JOIN jugadores j ON s.id_jugador = j.id_jugador
        JOIN partidos p ON s.id_partido = p.id_partido
        WHERE s.id_estadistica = :id_est
    """)
    res = db.execute(query_stats, {"id_est": id_estadistica}).mappings().fetchone()
    if not res:
        raise HTTPException(status_code=404, detail="Estadística no encontrada")

    stats_db = {k.lower(): v for k, v in res.items()}

    pos_mapeada = POSICIONES_MAP.get(nueva_posicion.upper(), nueva_posicion.upper())

    config_id = db.execute(text("SELECT id_configuracion FROM configuraciones_pesos WHERE activa = 1")).scalar() or 1
    pesos = db.execute(text("""
        SELECT bloque, clave_metrica, porcentaje, penaliza 
        FROM pesos_metrica_posicion 
        WHERE codigo_posicion = :pos AND id_configuracion = :config
    """), {"pos": pos_mapeada, "config": config_id}).fetchall()


    minutos = float(stats_db.get("minutos_jugados", 90))
    factor_90 = 90.0 / minutos if minutos > 0 else 1.0
    puntos_totales = 0.0

    for p in pesos:
        clave = p.clave_metrica.lower().strip()
        if clave in stats_db:
            valor = float(stats_db[clave] or 0)
            if valor > 0:
                val_eval = 1.0 if "tarjeta" in clave else (valor * factor_90)
                impacto = val_eval * float(p.porcentaje)
                if bool(p.penaliza):
                    puntos_totales -= impacto
                else:
                    puntos_totales += impacto

    nota_final = 5.0 + puntos_totales
    return {"nota": round(nota_final, 2)}

