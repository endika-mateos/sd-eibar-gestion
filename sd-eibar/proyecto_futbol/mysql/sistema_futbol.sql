-- ============================================================
-- BASE DE DATOS: sistema_futbol
-- Proyecto: Sistema de Scoring, Analisis de Rendimiento
--           y Control de Lesiones - SD Eibar
-- Version: limpia (Mayo 2026)
-- ============================================================

SET FOREIGN_KEY_CHECKS = 0;
DROP DATABASE IF EXISTS sistema_futbol;
CREATE DATABASE sistema_futbol CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sistema_futbol;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. USUARIOS Y ACCESO
-- ============================================================
CREATE TABLE usuarios (
    id_usuario       INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario   VARCHAR(50)  NOT NULL UNIQUE,
    contrasena_hash  VARCHAR(255) NOT NULL,
    rol              ENUM('admin', 'entrenador', 'analista', 'fisio') NOT NULL,
    fecha_creacion   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
-- 2. TEMPORADAS
-- ============================================================
CREATE TABLE temporadas (
    id_temporada  INT AUTO_INCREMENT PRIMARY KEY,
    nombre        VARCHAR(20) NOT NULL,         -- Ej: '2025/26'
    fecha_inicio  DATE,
    fecha_fin     DATE,
    activa        BOOLEAN DEFAULT FALSE
);

-- ============================================================
-- 3. JUGADORES Y DORSALES
-- ============================================================
CREATE TABLE jugadores (
    id_jugador        INT AUTO_INCREMENT PRIMARY KEY,
    nombre            VARCHAR(50) NOT NULL,
    apellidos         VARCHAR(50) NOT NULL,
    alias             VARCHAR(50),
    posicion_habitual VARCHAR(10),
    estado            ENUM('activo', 'lesionado', 'baja') DEFAULT 'activo',
    fecha_creacion    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE dorsales_jugador (
    id_dorsal    INT AUTO_INCREMENT PRIMARY KEY,
    id_jugador   INT NOT NULL,
    id_temporada INT NOT NULL,
    dorsal       INT NOT NULL,
    UNIQUE KEY uq_dorsal_temporada (id_temporada, dorsal),  -- Un dorsal unico por temporada
    FOREIGN KEY (id_jugador)   REFERENCES jugadores  (id_jugador)   ON DELETE CASCADE,
    FOREIGN KEY (id_temporada) REFERENCES temporadas (id_temporada) ON DELETE CASCADE
);

-- ============================================================
-- 4. PARTIDOS
-- ============================================================
CREATE TABLE partidos (
    id_partido      INT AUTO_INCREMENT PRIMARY KEY,
    id_temporada    INT,
    fecha           DATE         NOT NULL,
    competicion     VARCHAR(100),
    rival           VARCHAR(100),
    local_visitante ENUM('local', 'visitante'),
    goles_favor     INT DEFAULT 0,
    goles_contra    INT DEFAULT 0,
    fecha_creacion  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_temporada) REFERENCES temporadas (id_temporada)
);

-- ============================================================
-- 5. LESIONES
-- ============================================================
CREATE TABLE lesiones (
    id_lesion              INT AUTO_INCREMENT PRIMARY KEY,
    id_jugador             INT NOT NULL,
    fecha_inicio           DATE NOT NULL,
    fecha_fin              DATE,
    tipo_lesion            VARCHAR(100),
    gravedad               ENUM('leve', 'moderada', 'grave'),
    fecha_prevista_retorno DATE,
    observaciones          TEXT,
    fecha_creacion         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_jugador) REFERENCES jugadores (id_jugador) ON DELETE CASCADE
);

-- ============================================================
-- 6. SISTEMA DE SCORING (tablas gestionadas por Python)
-- ============================================================

-- Catalogo de posiciones
CREATE TABLE posiciones (
    codigo_posicion VARCHAR(5)  PRIMARY KEY,
    nombre_posicion VARCHAR(50) NOT NULL,
    linea           ENUM('defensa', 'medio', 'ataque') NOT NULL
);

-- Configuraciones del modelo de scoring
CREATE TABLE configuraciones_pesos (
    id_configuracion    INT AUTO_INCREMENT PRIMARY KEY,
    nombre_configuracion VARCHAR(100) NOT NULL,
    activa              BOOLEAN DEFAULT FALSE,
    fecha_creacion      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Porcentaje de cada bloque (ataque/construccion/defensa) por posicion
CREATE TABLE pesos_bloque_posicion (
    id_peso                  INT AUTO_INCREMENT PRIMARY KEY,
    id_configuracion         INT NOT NULL,
    codigo_posicion          VARCHAR(5) NOT NULL,
    porcentaje_ataque        DECIMAL(5,2) NOT NULL,
    porcentaje_construccion  DECIMAL(5,2) NOT NULL,
    porcentaje_defensa       DECIMAL(5,2) NOT NULL,
    UNIQUE KEY uq_config_posicion (id_configuracion, codigo_posicion),
    FOREIGN KEY (id_configuracion) REFERENCES configuraciones_pesos (id_configuracion),
    FOREIGN KEY (codigo_posicion)  REFERENCES posiciones (codigo_posicion)
);

-- Peso de cada metrica dentro de su bloque, por posicion
CREATE TABLE pesos_metrica_posicion (
    id_peso_metrica  INT AUTO_INCREMENT PRIMARY KEY,
    id_configuracion INT NOT NULL,
    codigo_posicion  VARCHAR(5) NOT NULL,
    bloque           ENUM('ataque', 'construccion', 'defensa') NOT NULL,
    clave_metrica    VARCHAR(50) NOT NULL,
    porcentaje       DECIMAL(5,2) NOT NULL,
    penaliza         BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (id_configuracion) REFERENCES configuraciones_pesos (id_configuracion),
    FOREIGN KEY (codigo_posicion)  REFERENCES posiciones (codigo_posicion)
);

-- Puntuaciones calculadas por Python
CREATE TABLE puntuaciones (
    id_puntuacion           INT AUTO_INCREMENT PRIMARY KEY,
    id_partido              INT NOT NULL,
    id_jugador              INT NOT NULL,
    posicion_evaluada       VARCHAR(10),
    puntuacion_ataque       DECIMAL(4,2),
    puntuacion_construccion DECIMAL(4,2),
    puntuacion_defensa      DECIMAL(4,2),
    factor_minutos          DECIMAL(4,2),
    puntuacion_final        DECIMAL(4,2),
    explicacion_positiva    TEXT,
    explicacion_negativa    TEXT,
    version_modelo          VARCHAR(50),
    fecha_creacion          TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_partido) REFERENCES partidos  (id_partido),
    FOREIGN KEY (id_jugador) REFERENCES jugadores (id_jugador)
);

-- Estadisticas raw importadas desde Excel (una fila = un jugador en un partido)
CREATE TABLE estadisticas_jugador_partido (
    id_estadistica                   INT AUTO_INCREMENT PRIMARY KEY,
    id_partido                       INT NOT NULL,
    id_jugador                       INT NOT NULL,
    posicion_jugada                  VARCHAR(10)  DEFAULT NULL,
    minutos_jugados                  FLOAT        DEFAULT NULL,
    acciones_totales                 FLOAT        DEFAULT 0,
    acciones_logradas                FLOAT        DEFAULT 0,
    acciones_fallidas                FLOAT        DEFAULT 0,
    goles                            FLOAT        DEFAULT 0,
    asistencias                      FLOAT        DEFAULT 0,
    tiros_totales                    FLOAT        DEFAULT 0,
    tiros_logrados                   FLOAT        DEFAULT 0,
    tiros_fallados                   FLOAT        DEFAULT 0,
    xg                               FLOAT        DEFAULT 0,
    xa                               FLOAT        DEFAULT 0,
    second_assists                   FLOAT        DEFAULT 0,
    asistencias_tiro                 FLOAT        DEFAULT 0,
    pases_totales                    FLOAT        DEFAULT 0,
    pases_completados                FLOAT        DEFAULT 0,
    pases_fallados                   FLOAT        DEFAULT 0,
    pases_largos_totales             FLOAT        DEFAULT 0,
    pases_largos_logrados            FLOAT        DEFAULT 0,
    pases_largos_fallados            FLOAT        DEFAULT 0,
    pases_area_penalti_totales       FLOAT        DEFAULT 0,
    pases_area_penalti_logrados      FLOAT        DEFAULT 0,
    pases_area_penalti_perdidos      FLOAT        DEFAULT 0,
    pases_profundidad_totales        FLOAT        DEFAULT 0,
    pases_profundidad_logrados       FLOAT        DEFAULT 0,
    pases_profundidad_perdidos       FLOAT        DEFAULT 0,
    pases_hacia_delante_totales      FLOAT        DEFAULT 0,
    pases_hacia_delante_logrados     FLOAT        DEFAULT 0,
    pases_hacia_delante_perdidos     FLOAT        DEFAULT 0,
    pases_hacia_atras_totales        FLOAT        DEFAULT 0,
    pases_hacia_atras_logrados       FLOAT        DEFAULT 0,
    pases_hacia_atras_perdidos       FLOAT        DEFAULT 0,
    pases_recibidos                  FLOAT        DEFAULT 0,
    carreras_profundidad             FLOAT        DEFAULT 0,
    duelos_totales                   FLOAT        DEFAULT 0,
    duelos_ganados                   FLOAT        DEFAULT 0,
    duelos_perdidos                  FLOAT        DEFAULT 0,
    duelos_defensivos_totales        FLOAT        DEFAULT 0,
    duelos_defensivos_ganados        FLOAT        DEFAULT 0,
    duelos_ofensivos_totales         FLOAT        DEFAULT 0,
    duelos_ofensivos_ganados         FLOAT        DEFAULT 0,
    duelos_ofensivos_perdidos        FLOAT        DEFAULT 0,
    duelos_aereos_totales            FLOAT        DEFAULT 0,
    duelos_aereos_ganados            FLOAT        DEFAULT 0,
    duelos_aereos_perdidos           FLOAT        DEFAULT 0,
    regates_totales                  FLOAT        DEFAULT NULL,
    regates_exitosos                 FLOAT        DEFAULT NULL,
    interceptaciones                 FLOAT        DEFAULT 0,
    despejes                         FLOAT        DEFAULT 0,
    balones_perdidos_totales         FLOAT        DEFAULT 0,
    balones_perdidos_propia_mitad    FLOAT        DEFAULT 0,
    balones_recuperados              FLOAT        DEFAULT 0,
    balones_recuperados_mitad_adversaria FLOAT    DEFAULT 0,
    tarjeta_amarilla                 INT          DEFAULT 0,
    tarjeta_roja                     INT          DEFAULT 0,
    archivo_origen                   VARCHAR(255) DEFAULT NULL,
    fecha_creacion                   DATETIME     DEFAULT NULL,
    FOREIGN KEY (id_partido) REFERENCES partidos  (id_partido) ON DELETE CASCADE,
    FOREIGN KEY (id_jugador) REFERENCES jugadores (id_jugador) ON DELETE CASCADE
);

-- Notas manuales del entrenador (opcional)
CREATE TABLE notas_entrenador (
    id_nota        INT AUTO_INCREMENT PRIMARY KEY,
    id_partido     INT NOT NULL,
    id_jugador     INT NOT NULL,
    nota           DECIMAL(4,2),
    comentario     TEXT,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_partido) REFERENCES partidos  (id_partido),
    FOREIGN KEY (id_jugador) REFERENCES jugadores (id_jugador)
);

-- ============================================================
-- 7. DATOS INICIALES DEL SISTEMA
-- ============================================================

INSERT INTO posiciones (codigo_posicion, nombre_posicion, linea) VALUES
    ('POR',  'Portero',               'defensa'),
    ('DFC',  'Defensa Central',       'defensa'),
    ('LD',   'Lateral Derecho',       'defensa'),
    ('LI',   'Lateral Izquierdo',     'defensa'),
    ('MCD',  'Mediocentro Defensivo', 'medio'),
    ('MC',   'Mediocentro',           'medio'),
    ('MCO',  'Mediocentro Ofensivo',  'medio'),
    ('EXTD', 'Extremo Derecho',       'ataque'),
    ('EXTI', 'Extremo Izquierdo',     'ataque'),
    ('DC',   'Delantero Centro',      'ataque');

-- Usuarios (contrasenas en texto plano para entorno local de pruebas)
INSERT INTO usuarios (nombre_usuario, contrasena_hash, rol) VALUES
    ('admin',     '1234', 'admin'),
    ('mister',    '1234', 'entrenador'),
    ('analista1', '1234', 'analista'),
    ('fisio', '1234', 'fisio');

INSERT INTO configuraciones_pesos (nombre_configuracion, activa) VALUES
    ('Modelo Estandar 2026', TRUE);

-- Pesos de bloque por posicion (ataque / construccion / defensa)
INSERT INTO pesos_bloque_posicion
    (id_configuracion, codigo_posicion, porcentaje_ataque, porcentaje_construccion, porcentaje_defensa)
VALUES
    (1, 'POR',  0.05, 0.25, 0.70),
    (1, 'DFC',  0.10, 0.30, 0.60),
    (1, 'LD',   0.25, 0.35, 0.40),
    (1, 'LI',   0.25, 0.35, 0.40),
    (1, 'MCD',  0.20, 0.40, 0.40),
    (1, 'MC',   0.30, 0.45, 0.25),
    (1, 'MCO',  0.45, 0.40, 0.15),
    (1, 'EXTD', 0.50, 0.35, 0.15),
    (1, 'EXTI', 0.50, 0.35, 0.15),
    (1, 'DC',   0.60, 0.30, 0.10);

-- ============================================================
-- 8. PESOS DE METRICAS POR POSICION
-- ============================================================

-- POR
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (184, 1, 'POR', 'ataque', 'goles', 3.05, 0),
    (185, 1, 'POR', 'ataque', 'asistencias', 1.22, 0),
    (186, 1, 'POR', 'ataque', 'xg', 0.07, 0),
    (187, 1, 'POR', 'ataque', 'xa', 0.31, 0),
    (188, 1, 'POR', 'ataque', 'second_assists', 0.13, 0),
    (189, 1, 'POR', 'ataque', 'asistencias_tiro', 0.19, 0),
    (190, 1, 'POR', 'construccion', 'acciones_totales', 0.02, 1),
    (191, 1, 'POR', 'construccion', 'acciones_logradas', 0.05, 0),
    (192, 1, 'POR', 'construccion', 'acciones_fallidas', 0.02, 1),
    (193, 1, 'POR', 'ataque', 'tiros_totales', 0.02, 1),
    (194, 1, 'POR', 'ataque', 'tiros_logrados', 0.05, 0),
    (195, 1, 'POR', 'ataque', 'tiros_fallados', 0.02, 1),
    (196, 1, 'POR', 'construccion', 'pases_largos_totales', 0.02, 1),
    (197, 1, 'POR', 'construccion', 'pases_largos_logrados', 0.07, 0),
    (198, 1, 'POR', 'construccion', 'pases_largos_fallados', 0.03, 1),
    (199, 1, 'POR', 'defensa', 'duelos_totales', 0.02, 1),
    (200, 1, 'POR', 'defensa', 'duelos_ganados', 0.06, 0),
    (201, 1, 'POR', 'defensa', 'duelos_perdidos', 0.03, 1),
    (202, 1, 'POR', 'defensa', 'duelos_aereos_totales', 0.03, 1),
    (203, 1, 'POR', 'defensa', 'duelos_aereos_ganados', 0.17, 0),
    (204, 1, 'POR', 'defensa', 'duelos_aereos_perdidos', 0.04, 1),
    (205, 1, 'POR', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (206, 1, 'POR', 'ataque', 'duelos_ofensivos_ganados', 0.05, 0),
    (207, 1, 'POR', 'ataque', 'duelos_ofensivos_perdidos', 0.02, 1),
    (208, 1, 'POR', 'defensa', 'interceptaciones', 0.10, 0),
    (209, 1, 'POR', 'defensa', 'despejes', 0.10, 0),
    (210, 1, 'POR', 'defensa', 'balones_perdidos_totales', 0.04, 1),
    (211, 1, 'POR', 'defensa', 'balones_perdidos_propia_mitad', 0.22, 1),
    (212, 1, 'POR', 'defensa', 'balones_recuperados', 0.07, 0),
    (213, 1, 'POR', 'defensa', 'balones_recuperados_mitad_adversaria', 0.31, 0),
    (214, 1, 'POR', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (215, 1, 'POR', 'defensa', 'tarjeta_roja', 0.82, 1),
    (216, 1, 'POR', 'construccion', 'carreras_profundidad', 0.05, 0),
    (217, 1, 'POR', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (218, 1, 'POR', 'construccion', 'pases_profundidad_logrados', 0.07, 0),
    (219, 1, 'POR', 'construccion', 'pases_profundidad_perdidos', 0.03, 1),
    (220, 1, 'POR', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (221, 1, 'POR', 'construccion', 'pases_area_penalti_logrados', 0.10, 0),
    (222, 1, 'POR', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (223, 1, 'POR', 'construccion', 'pases_recibidos', 0.01, 0),
    (224, 1, 'POR', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (225, 1, 'POR', 'construccion', 'pases_hacia_delante_logrados', 0.06, 0),
    (226, 1, 'POR', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (227, 1, 'POR', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (228, 1, 'POR', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (229, 1, 'POR', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (644, 1, 'POR', 'construccion', 'pases_totales', 0.01, 1),
    (645, 1, 'POR', 'construccion', 'pases_completados', 0.03, 0);

-- DFC
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (230, 1, 'DFC', 'ataque', 'goles', 1.22, 0),
    (231, 1, 'DFC', 'ataque', 'asistencias', 0.62, 0),
    (232, 1, 'DFC', 'ataque', 'xg', 0.13, 0),
    (233, 1, 'DFC', 'ataque', 'xa', 0.10, 0),
    (234, 1, 'DFC', 'ataque', 'second_assists', 0.07, 0),
    (235, 1, 'DFC', 'ataque', 'asistencias_tiro', 0.10, 0),
    (236, 1, 'DFC', 'construccion', 'acciones_totales', 0.02, 1),
    (237, 1, 'DFC', 'construccion', 'acciones_logradas', 0.05, 0),
    (238, 1, 'DFC', 'construccion', 'acciones_fallidas', 0.02, 1),
    (239, 1, 'DFC', 'ataque', 'tiros_totales', 0.02, 1),
    (240, 1, 'DFC', 'ataque', 'tiros_logrados', 0.10, 0),
    (241, 1, 'DFC', 'ataque', 'tiros_fallados', 0.03, 1),
    (242, 1, 'DFC', 'construccion', 'pases_largos_totales', 0.02, 1),
    (243, 1, 'DFC', 'construccion', 'pases_largos_logrados', 0.08, 0),
    (244, 1, 'DFC', 'construccion', 'pases_largos_fallados', 0.03, 1),
    (245, 1, 'DFC', 'defensa', 'duelos_totales', 0.02, 1),
    (246, 1, 'DFC', 'defensa', 'duelos_ganados', 0.10, 0),
    (247, 1, 'DFC', 'defensa', 'duelos_perdidos', 0.03, 1),
    (248, 1, 'DFC', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (249, 1, 'DFC', 'defensa', 'duelos_aereos_ganados', 0.13, 0),
    (250, 1, 'DFC', 'defensa', 'duelos_aereos_perdidos', 0.03, 1),
    (251, 1, 'DFC', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (252, 1, 'DFC', 'ataque', 'duelos_ofensivos_ganados', 0.06, 0),
    (253, 1, 'DFC', 'ataque', 'duelos_ofensivos_perdidos', 0.02, 1),
    (254, 1, 'DFC', 'defensa', 'interceptaciones', 0.13, 0),
    (255, 1, 'DFC', 'defensa', 'despejes', 0.10, 0),
    (256, 1, 'DFC', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (257, 1, 'DFC', 'defensa', 'balones_perdidos_propia_mitad', 0.14, 1),
    (258, 1, 'DFC', 'defensa', 'balones_recuperados', 0.08, 0),
    (259, 1, 'DFC', 'defensa', 'balones_recuperados_mitad_adversaria', 0.13, 0),
    (260, 1, 'DFC', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (261, 1, 'DFC', 'defensa', 'tarjeta_roja', 0.69, 1),
    (262, 1, 'DFC', 'construccion', 'carreras_profundidad', 0.05, 0),
    (263, 1, 'DFC', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (264, 1, 'DFC', 'construccion', 'pases_profundidad_logrados', 0.06, 0),
    (265, 1, 'DFC', 'construccion', 'pases_profundidad_perdidos', 0.02, 1),
    (266, 1, 'DFC', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (267, 1, 'DFC', 'construccion', 'pases_area_penalti_logrados', 0.07, 0),
    (268, 1, 'DFC', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (269, 1, 'DFC', 'construccion', 'pases_recibidos', 0.01, 0),
    (270, 1, 'DFC', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (271, 1, 'DFC', 'construccion', 'pases_hacia_delante_logrados', 0.05, 0),
    (272, 1, 'DFC', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (273, 1, 'DFC', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (274, 1, 'DFC', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (275, 1, 'DFC', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (646, 1, 'DFC', 'construccion', 'pases_totales', 0.02, 1),
    (647, 1, 'DFC', 'construccion', 'pases_completados', 0.06, 0);

-- LD
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (276, 1, 'LD', 'ataque', 'goles', 0.92, 0),
    (278, 1, 'LD', 'ataque', 'asistencias', 0.73, 0),
    (280, 1, 'LD', 'ataque', 'xg', 0.19, 0),
    (282, 1, 'LD', 'ataque', 'xa', 0.26, 0),
    (284, 1, 'LD', 'ataque', 'second_assists', 0.10, 0),
    (286, 1, 'LD', 'ataque', 'asistencias_tiro', 0.10, 0),
    (288, 1, 'LD', 'construccion', 'acciones_totales', 0.02, 1),
    (290, 1, 'LD', 'construccion', 'acciones_logradas', 0.06, 0),
    (292, 1, 'LD', 'construccion', 'acciones_fallidas', 0.02, 1),
    (294, 1, 'LD', 'ataque', 'tiros_totales', 0.02, 1),
    (296, 1, 'LD', 'ataque', 'tiros_logrados', 0.10, 0),
    (298, 1, 'LD', 'ataque', 'tiros_fallados', 0.03, 1),
    (300, 1, 'LD', 'construccion', 'pases_largos_totales', 0.02, 1),
    (302, 1, 'LD', 'construccion', 'pases_largos_logrados', 0.07, 0),
    (304, 1, 'LD', 'construccion', 'pases_largos_fallados', 0.03, 1),
    (306, 1, 'LD', 'defensa', 'duelos_totales', 0.02, 1),
    (308, 1, 'LD', 'defensa', 'duelos_ganados', 0.08, 0),
    (310, 1, 'LD', 'defensa', 'duelos_perdidos', 0.03, 1),
    (312, 1, 'LD', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (314, 1, 'LD', 'defensa', 'duelos_aereos_ganados', 0.07, 0),
    (316, 1, 'LD', 'defensa', 'duelos_aereos_perdidos', 0.03, 1),
    (318, 1, 'LD', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (320, 1, 'LD', 'ataque', 'duelos_ofensivos_ganados', 0.08, 0),
    (322, 1, 'LD', 'ataque', 'duelos_ofensivos_perdidos', 0.03, 1),
    (324, 1, 'LD', 'defensa', 'interceptaciones', 0.08, 0),
    (326, 1, 'LD', 'defensa', 'despejes', 0.06, 0),
    (328, 1, 'LD', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (330, 1, 'LD', 'defensa', 'balones_perdidos_propia_mitad', 0.09, 1),
    (332, 1, 'LD', 'defensa', 'balones_recuperados', 0.07, 0),
    (334, 1, 'LD', 'defensa', 'balones_recuperados_mitad_adversaria', 0.10, 0),
    (336, 1, 'LD', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (338, 1, 'LD', 'defensa', 'tarjeta_roja', 0.55, 1),
    (340, 1, 'LD', 'construccion', 'carreras_profundidad', 0.08, 0),
    (342, 1, 'LD', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (344, 1, 'LD', 'construccion', 'pases_profundidad_logrados', 0.08, 0),
    (346, 1, 'LD', 'construccion', 'pases_profundidad_perdidos', 0.03, 1),
    (348, 1, 'LD', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (350, 1, 'LD', 'construccion', 'pases_area_penalti_logrados', 0.10, 0),
    (352, 1, 'LD', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (354, 1, 'LD', 'construccion', 'pases_recibidos', 0.02, 0),
    (356, 1, 'LD', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (358, 1, 'LD', 'construccion', 'pases_hacia_delante_logrados', 0.05, 0),
    (360, 1, 'LD', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (362, 1, 'LD', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (364, 1, 'LD', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (366, 1, 'LD', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (650, 1, 'LD', 'construccion', 'pases_totales', 0.02, 1),
    (651, 1, 'LD', 'construccion', 'pases_completados', 0.07, 0);

-- LI
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (277, 1, 'LI', 'ataque', 'goles', 0.92, 0),
    (279, 1, 'LI', 'ataque', 'asistencias', 0.73, 0),
    (281, 1, 'LI', 'ataque', 'xg', 0.19, 0),
    (283, 1, 'LI', 'ataque', 'xa', 0.26, 0),
    (285, 1, 'LI', 'ataque', 'second_assists', 0.10, 0),
    (287, 1, 'LI', 'ataque', 'asistencias_tiro', 0.10, 0),
    (289, 1, 'LI', 'construccion', 'acciones_totales', 0.02, 1),
    (291, 1, 'LI', 'construccion', 'acciones_logradas', 0.06, 0),
    (293, 1, 'LI', 'construccion', 'acciones_fallidas', 0.02, 1),
    (295, 1, 'LI', 'ataque', 'tiros_totales', 0.02, 1),
    (297, 1, 'LI', 'ataque', 'tiros_logrados', 0.10, 0),
    (299, 1, 'LI', 'ataque', 'tiros_fallados', 0.03, 1),
    (301, 1, 'LI', 'construccion', 'pases_largos_totales', 0.02, 1),
    (303, 1, 'LI', 'construccion', 'pases_largos_logrados', 0.07, 0),
    (305, 1, 'LI', 'construccion', 'pases_largos_fallados', 0.03, 1),
    (307, 1, 'LI', 'defensa', 'duelos_totales', 0.02, 1),
    (309, 1, 'LI', 'defensa', 'duelos_ganados', 0.08, 0),
    (311, 1, 'LI', 'defensa', 'duelos_perdidos', 0.03, 1),
    (313, 1, 'LI', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (315, 1, 'LI', 'defensa', 'duelos_aereos_ganados', 0.07, 0),
    (317, 1, 'LI', 'defensa', 'duelos_aereos_perdidos', 0.03, 1),
    (319, 1, 'LI', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (321, 1, 'LI', 'ataque', 'duelos_ofensivos_ganados', 0.08, 0),
    (323, 1, 'LI', 'ataque', 'duelos_ofensivos_perdidos', 0.03, 1),
    (325, 1, 'LI', 'defensa', 'interceptaciones', 0.08, 0),
    (327, 1, 'LI', 'defensa', 'despejes', 0.06, 0),
    (329, 1, 'LI', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (331, 1, 'LI', 'defensa', 'balones_perdidos_propia_mitad', 0.09, 1),
    (333, 1, 'LI', 'defensa', 'balones_recuperados', 0.07, 0),
    (335, 1, 'LI', 'defensa', 'balones_recuperados_mitad_adversaria', 0.10, 0),
    (337, 1, 'LI', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (339, 1, 'LI', 'defensa', 'tarjeta_roja', 0.55, 1),
    (341, 1, 'LI', 'construccion', 'carreras_profundidad', 0.08, 0),
    (343, 1, 'LI', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (345, 1, 'LI', 'construccion', 'pases_profundidad_logrados', 0.08, 0),
    (347, 1, 'LI', 'construccion', 'pases_profundidad_perdidos', 0.03, 1),
    (349, 1, 'LI', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (351, 1, 'LI', 'construccion', 'pases_area_penalti_logrados', 0.10, 0),
    (353, 1, 'LI', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (355, 1, 'LI', 'construccion', 'pases_recibidos', 0.02, 0),
    (357, 1, 'LI', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (359, 1, 'LI', 'construccion', 'pases_hacia_delante_logrados', 0.05, 0),
    (361, 1, 'LI', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (363, 1, 'LI', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (365, 1, 'LI', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (367, 1, 'LI', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (648, 1, 'LI', 'construccion', 'pases_totales', 0.02, 1),
    (649, 1, 'LI', 'construccion', 'pases_completados', 0.07, 0);

-- MCD
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (368, 1, 'MCD', 'ataque', 'goles', 0.92, 0),
    (369, 1, 'MCD', 'ataque', 'asistencias', 0.62, 0),
    (370, 1, 'MCD', 'ataque', 'xg', 0.13, 0),
    (371, 1, 'MCD', 'ataque', 'xa', 0.13, 0),
    (372, 1, 'MCD', 'ataque', 'second_assists', 0.10, 0),
    (373, 1, 'MCD', 'ataque', 'asistencias_tiro', 0.07, 0),
    (374, 1, 'MCD', 'construccion', 'acciones_totales', 0.02, 1),
    (375, 1, 'MCD', 'construccion', 'acciones_logradas', 0.06, 0),
    (376, 1, 'MCD', 'construccion', 'acciones_fallidas', 0.02, 1),
    (377, 1, 'MCD', 'ataque', 'tiros_totales', 0.02, 1),
    (378, 1, 'MCD', 'ataque', 'tiros_logrados', 0.10, 0),
    (379, 1, 'MCD', 'ataque', 'tiros_fallados', 0.03, 1),
    (380, 1, 'MCD', 'construccion', 'pases_largos_totales', 0.02, 1),
    (381, 1, 'MCD', 'construccion', 'pases_largos_logrados', 0.07, 0),
    (382, 1, 'MCD', 'construccion', 'pases_largos_fallados', 0.03, 1),
    (383, 1, 'MCD', 'defensa', 'duelos_totales', 0.02, 1),
    (384, 1, 'MCD', 'defensa', 'duelos_ganados', 0.10, 0),
    (385, 1, 'MCD', 'defensa', 'duelos_perdidos', 0.03, 1),
    (386, 1, 'MCD', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (387, 1, 'MCD', 'defensa', 'duelos_aereos_ganados', 0.08, 0),
    (388, 1, 'MCD', 'defensa', 'duelos_aereos_perdidos', 0.03, 1),
    (389, 1, 'MCD', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (390, 1, 'MCD', 'ataque', 'duelos_ofensivos_ganados', 0.07, 0),
    (391, 1, 'MCD', 'ataque', 'duelos_ofensivos_perdidos', 0.02, 1),
    (392, 1, 'MCD', 'defensa', 'interceptaciones', 0.13, 0),
    (393, 1, 'MCD', 'defensa', 'despejes', 0.07, 0),
    (394, 1, 'MCD', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (395, 1, 'MCD', 'defensa', 'balones_perdidos_propia_mitad', 0.11, 1),
    (396, 1, 'MCD', 'defensa', 'balones_recuperados', 0.10, 0),
    (397, 1, 'MCD', 'defensa', 'balones_recuperados_mitad_adversaria', 0.13, 0),
    (398, 1, 'MCD', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (399, 1, 'MCD', 'defensa', 'tarjeta_roja', 0.55, 1),
    (400, 1, 'MCD', 'construccion', 'carreras_profundidad', 0.05, 0),
    (401, 1, 'MCD', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (402, 1, 'MCD', 'construccion', 'pases_profundidad_logrados', 0.06, 0),
    (403, 1, 'MCD', 'construccion', 'pases_profundidad_perdidos', 0.02, 1),
    (404, 1, 'MCD', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (405, 1, 'MCD', 'construccion', 'pases_area_penalti_logrados', 0.06, 0),
    (406, 1, 'MCD', 'construccion', 'pases_area_penalti_perdidos', 0.02, 1),
    (407, 1, 'MCD', 'construccion', 'pases_recibidos', 0.02, 0),
    (408, 1, 'MCD', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (409, 1, 'MCD', 'construccion', 'pases_hacia_delante_logrados', 0.06, 0),
    (410, 1, 'MCD', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (411, 1, 'MCD', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (412, 1, 'MCD', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (413, 1, 'MCD', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (652, 1, 'MCD', 'construccion', 'pases_totales', 0.03, 1),
    (653, 1, 'MCD', 'construccion', 'pases_completados', 0.10, 0);

-- MC
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (414, 1, 'MC', 'ataque', 'goles', 0.92, 0),
    (415, 1, 'MC', 'ataque', 'asistencias', 0.73, 0),
    (416, 1, 'MC', 'ataque', 'xg', 0.17, 0),
    (417, 1, 'MC', 'ataque', 'xa', 0.19, 0),
    (418, 1, 'MC', 'ataque', 'second_assists', 0.13, 0),
    (419, 1, 'MC', 'ataque', 'asistencias_tiro', 0.13, 0),
    (420, 1, 'MC', 'construccion', 'acciones_totales', 0.02, 1),
    (421, 1, 'MC', 'construccion', 'acciones_logradas', 0.06, 0),
    (422, 1, 'MC', 'construccion', 'acciones_fallidas', 0.02, 1),
    (423, 1, 'MC', 'ataque', 'tiros_totales', 0.02, 1),
    (424, 1, 'MC', 'ataque', 'tiros_logrados', 0.10, 0),
    (425, 1, 'MC', 'ataque', 'tiros_fallados', 0.03, 1),
    (426, 1, 'MC', 'construccion', 'pases_largos_totales', 0.02, 1),
    (427, 1, 'MC', 'construccion', 'pases_largos_logrados', 0.07, 0),
    (428, 1, 'MC', 'construccion', 'pases_largos_fallados', 0.03, 1),
    (429, 1, 'MC', 'defensa', 'duelos_totales', 0.02, 1),
    (430, 1, 'MC', 'defensa', 'duelos_ganados', 0.07, 0),
    (431, 1, 'MC', 'defensa', 'duelos_perdidos', 0.03, 1),
    (432, 1, 'MC', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (433, 1, 'MC', 'defensa', 'duelos_aereos_ganados', 0.07, 0),
    (434, 1, 'MC', 'defensa', 'duelos_aereos_perdidos', 0.03, 1),
    (435, 1, 'MC', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (436, 1, 'MC', 'ataque', 'duelos_ofensivos_ganados', 0.08, 0),
    (437, 1, 'MC', 'ataque', 'duelos_ofensivos_perdidos', 0.03, 1),
    (438, 1, 'MC', 'defensa', 'interceptaciones', 0.08, 0),
    (439, 1, 'MC', 'defensa', 'despejes', 0.05, 0),
    (440, 1, 'MC', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (441, 1, 'MC', 'defensa', 'balones_perdidos_propia_mitad', 0.09, 1),
    (442, 1, 'MC', 'defensa', 'balones_recuperados', 0.07, 0),
    (443, 1, 'MC', 'defensa', 'balones_recuperados_mitad_adversaria', 0.10, 0),
    (444, 1, 'MC', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (445, 1, 'MC', 'defensa', 'tarjeta_roja', 0.55, 1),
    (446, 1, 'MC', 'construccion', 'carreras_profundidad', 0.07, 0),
    (447, 1, 'MC', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (448, 1, 'MC', 'construccion', 'pases_profundidad_logrados', 0.10, 0),
    (449, 1, 'MC', 'construccion', 'pases_profundidad_perdidos', 0.03, 1),
    (450, 1, 'MC', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (451, 1, 'MC', 'construccion', 'pases_area_penalti_logrados', 0.10, 0),
    (452, 1, 'MC', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (453, 1, 'MC', 'construccion', 'pases_recibidos', 0.02, 0),
    (454, 1, 'MC', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (455, 1, 'MC', 'construccion', 'pases_hacia_delante_logrados', 0.06, 0),
    (456, 1, 'MC', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (457, 1, 'MC', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (458, 1, 'MC', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (459, 1, 'MC', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (654, 1, 'MC', 'construccion', 'pases_totales', 0.03, 1),
    (655, 1, 'MC', 'construccion', 'pases_completados', 0.12, 0);

-- MCO
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (460, 1, 'MCO', 'ataque', 'goles', 0.92, 0),
    (461, 1, 'MCO', 'ataque', 'asistencias', 0.92, 0),
    (462, 1, 'MCO', 'ataque', 'xg', 0.22, 0),
    (463, 1, 'MCO', 'ataque', 'xa', 0.31, 0),
    (464, 1, 'MCO', 'ataque', 'second_assists', 0.10, 0),
    (465, 1, 'MCO', 'ataque', 'asistencias_tiro', 0.17, 0),
    (466, 1, 'MCO', 'construccion', 'acciones_totales', 0.02, 1),
    (467, 1, 'MCO', 'construccion', 'acciones_logradas', 0.06, 0),
    (468, 1, 'MCO', 'construccion', 'acciones_fallidas', 0.02, 1),
    (469, 1, 'MCO', 'ataque', 'tiros_totales', 0.02, 1),
    (470, 1, 'MCO', 'ataque', 'tiros_logrados', 0.13, 0),
    (471, 1, 'MCO', 'ataque', 'tiros_fallados', 0.03, 1),
    (472, 1, 'MCO', 'construccion', 'pases_largos_totales', 0.02, 1),
    (473, 1, 'MCO', 'construccion', 'pases_largos_logrados', 0.06, 0),
    (474, 1, 'MCO', 'construccion', 'pases_largos_fallados', 0.02, 1),
    (475, 1, 'MCO', 'defensa', 'duelos_totales', 0.02, 1),
    (476, 1, 'MCO', 'defensa', 'duelos_ganados', 0.06, 0),
    (477, 1, 'MCO', 'defensa', 'duelos_perdidos', 0.02, 1),
    (478, 1, 'MCO', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (479, 1, 'MCO', 'defensa', 'duelos_aereos_ganados', 0.06, 0),
    (480, 1, 'MCO', 'defensa', 'duelos_aereos_perdidos', 0.02, 1),
    (481, 1, 'MCO', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (482, 1, 'MCO', 'ataque', 'duelos_ofensivos_ganados', 0.10, 0),
    (483, 1, 'MCO', 'ataque', 'duelos_ofensivos_perdidos', 0.03, 1),
    (484, 1, 'MCO', 'defensa', 'interceptaciones', 0.06, 0),
    (485, 1, 'MCO', 'defensa', 'despejes', 0.02, 0),
    (486, 1, 'MCO', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (487, 1, 'MCO', 'defensa', 'balones_perdidos_propia_mitad', 0.06, 1),
    (488, 1, 'MCO', 'defensa', 'balones_recuperados', 0.06, 0),
    (489, 1, 'MCO', 'defensa', 'balones_recuperados_mitad_adversaria', 0.10, 0),
    (490, 1, 'MCO', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (491, 1, 'MCO', 'defensa', 'tarjeta_roja', 0.55, 1),
    (492, 1, 'MCO', 'construccion', 'carreras_profundidad', 0.10, 0),
    (493, 1, 'MCO', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (494, 1, 'MCO', 'construccion', 'pases_profundidad_logrados', 0.17, 0),
    (495, 1, 'MCO', 'construccion', 'pases_profundidad_perdidos', 0.03, 1),
    (496, 1, 'MCO', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (497, 1, 'MCO', 'construccion', 'pases_area_penalti_logrados', 0.17, 0),
    (498, 1, 'MCO', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (499, 1, 'MCO', 'construccion', 'pases_recibidos', 0.02, 0),
    (500, 1, 'MCO', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (501, 1, 'MCO', 'construccion', 'pases_hacia_delante_logrados', 0.06, 0),
    (502, 1, 'MCO', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (503, 1, 'MCO', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (504, 1, 'MCO', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (505, 1, 'MCO', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (656, 1, 'MCO', 'construccion', 'pases_totales', 0.02, 1),
    (657, 1, 'MCO', 'construccion', 'pases_completados', 0.08, 0);

-- EXTD
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (506, 1, 'EXTD', 'ataque', 'goles', 0.92, 0),
    (508, 1, 'EXTD', 'ataque', 'asistencias', 0.92, 0),
    (510, 1, 'EXTD', 'ataque', 'xg', 0.26, 0),
    (512, 1, 'EXTD', 'ataque', 'xa', 0.31, 0),
    (514, 1, 'EXTD', 'ataque', 'second_assists', 0.07, 0),
    (516, 1, 'EXTD', 'ataque', 'asistencias_tiro', 0.13, 0),
    (518, 1, 'EXTD', 'construccion', 'acciones_totales', 0.02, 1),
    (520, 1, 'EXTD', 'construccion', 'acciones_logradas', 0.06, 0),
    (522, 1, 'EXTD', 'construccion', 'acciones_fallidas', 0.02, 1),
    (524, 1, 'EXTD', 'ataque', 'tiros_totales', 0.02, 1),
    (526, 1, 'EXTD', 'ataque', 'tiros_logrados', 0.17, 0),
    (528, 1, 'EXTD', 'ataque', 'tiros_fallados', 0.03, 1),
    (530, 1, 'EXTD', 'construccion', 'pases_largos_totales', 0.02, 1),
    (532, 1, 'EXTD', 'construccion', 'pases_largos_logrados', 0.05, 0),
    (534, 1, 'EXTD', 'construccion', 'pases_largos_fallados', 0.02, 1),
    (536, 1, 'EXTD', 'defensa', 'duelos_totales', 0.02, 1),
    (538, 1, 'EXTD', 'defensa', 'duelos_ganados', 0.06, 0),
    (540, 1, 'EXTD', 'defensa', 'duelos_perdidos', 0.02, 1),
    (542, 1, 'EXTD', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (544, 1, 'EXTD', 'defensa', 'duelos_aereos_ganados', 0.06, 0),
    (546, 1, 'EXTD', 'defensa', 'duelos_aereos_perdidos', 0.02, 1),
    (548, 1, 'EXTD', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (550, 1, 'EXTD', 'ataque', 'duelos_ofensivos_ganados', 0.13, 0),
    (552, 1, 'EXTD', 'ataque', 'duelos_ofensivos_perdidos', 0.03, 1),
    (554, 1, 'EXTD', 'defensa', 'interceptaciones', 0.05, 0),
    (556, 1, 'EXTD', 'defensa', 'despejes', 0.02, 0),
    (558, 1, 'EXTD', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (560, 1, 'EXTD', 'defensa', 'balones_perdidos_propia_mitad', 0.06, 1),
    (562, 1, 'EXTD', 'defensa', 'balones_recuperados', 0.06, 0),
    (564, 1, 'EXTD', 'defensa', 'balones_recuperados_mitad_adversaria', 0.10, 0),
    (566, 1, 'EXTD', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (568, 1, 'EXTD', 'defensa', 'tarjeta_roja', 0.55, 1),
    (570, 1, 'EXTD', 'construccion', 'carreras_profundidad', 0.13, 0),
    (572, 1, 'EXTD', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (574, 1, 'EXTD', 'construccion', 'pases_profundidad_logrados', 0.13, 0),
    (576, 1, 'EXTD', 'construccion', 'pases_profundidad_perdidos', 0.03, 1),
    (578, 1, 'EXTD', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (580, 1, 'EXTD', 'construccion', 'pases_area_penalti_logrados', 0.17, 0),
    (582, 1, 'EXTD', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (584, 1, 'EXTD', 'construccion', 'pases_recibidos', 0.02, 0),
    (586, 1, 'EXTD', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (588, 1, 'EXTD', 'construccion', 'pases_hacia_delante_logrados', 0.05, 0),
    (590, 1, 'EXTD', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (592, 1, 'EXTD', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (594, 1, 'EXTD', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (596, 1, 'EXTD', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (660, 1, 'EXTD', 'construccion', 'pases_totales', 0.01, 1),
    (661, 1, 'EXTD', 'construccion', 'pases_completados', 0.05, 0);

-- EXTI
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (507, 1, 'EXTI', 'ataque', 'goles', 0.92, 0),
    (509, 1, 'EXTI', 'ataque', 'asistencias', 0.92, 0),
    (511, 1, 'EXTI', 'ataque', 'xg', 0.26, 0),
    (513, 1, 'EXTI', 'ataque', 'xa', 0.31, 0),
    (515, 1, 'EXTI', 'ataque', 'second_assists', 0.07, 0),
    (517, 1, 'EXTI', 'ataque', 'asistencias_tiro', 0.13, 0),
    (519, 1, 'EXTI', 'construccion', 'acciones_totales', 0.02, 1),
    (521, 1, 'EXTI', 'construccion', 'acciones_logradas', 0.06, 0),
    (523, 1, 'EXTI', 'construccion', 'acciones_fallidas', 0.02, 1),
    (525, 1, 'EXTI', 'ataque', 'tiros_totales', 0.02, 1),
    (527, 1, 'EXTI', 'ataque', 'tiros_logrados', 0.17, 0),
    (529, 1, 'EXTI', 'ataque', 'tiros_fallados', 0.03, 1),
    (531, 1, 'EXTI', 'construccion', 'pases_largos_totales', 0.02, 1),
    (533, 1, 'EXTI', 'construccion', 'pases_largos_logrados', 0.05, 0),
    (535, 1, 'EXTI', 'construccion', 'pases_largos_fallados', 0.02, 1),
    (537, 1, 'EXTI', 'defensa', 'duelos_totales', 0.02, 1),
    (539, 1, 'EXTI', 'defensa', 'duelos_ganados', 0.06, 0),
    (541, 1, 'EXTI', 'defensa', 'duelos_perdidos', 0.02, 1),
    (543, 1, 'EXTI', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (545, 1, 'EXTI', 'defensa', 'duelos_aereos_ganados', 0.06, 0),
    (547, 1, 'EXTI', 'defensa', 'duelos_aereos_perdidos', 0.02, 1),
    (549, 1, 'EXTI', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (551, 1, 'EXTI', 'ataque', 'duelos_ofensivos_ganados', 0.13, 0),
    (553, 1, 'EXTI', 'ataque', 'duelos_ofensivos_perdidos', 0.03, 1),
    (555, 1, 'EXTI', 'defensa', 'interceptaciones', 0.05, 0),
    (557, 1, 'EXTI', 'defensa', 'despejes', 0.02, 0),
    (559, 1, 'EXTI', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (561, 1, 'EXTI', 'defensa', 'balones_perdidos_propia_mitad', 0.06, 1),
    (563, 1, 'EXTI', 'defensa', 'balones_recuperados', 0.06, 0),
    (565, 1, 'EXTI', 'defensa', 'balones_recuperados_mitad_adversaria', 0.10, 0),
    (567, 1, 'EXTI', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (569, 1, 'EXTI', 'defensa', 'tarjeta_roja', 0.55, 1),
    (571, 1, 'EXTI', 'construccion', 'carreras_profundidad', 0.13, 0),
    (573, 1, 'EXTI', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (575, 1, 'EXTI', 'construccion', 'pases_profundidad_logrados', 0.13, 0),
    (577, 1, 'EXTI', 'construccion', 'pases_profundidad_perdidos', 0.03, 1),
    (579, 1, 'EXTI', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (581, 1, 'EXTI', 'construccion', 'pases_area_penalti_logrados', 0.17, 0),
    (583, 1, 'EXTI', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (585, 1, 'EXTI', 'construccion', 'pases_recibidos', 0.02, 0),
    (587, 1, 'EXTI', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (589, 1, 'EXTI', 'construccion', 'pases_hacia_delante_logrados', 0.05, 0),
    (591, 1, 'EXTI', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (593, 1, 'EXTI', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (595, 1, 'EXTI', 'construccion', 'pases_hacia_atras_logrados', 0.02, 0),
    (597, 1, 'EXTI', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (658, 1, 'EXTI', 'construccion', 'pases_totales', 0.01, 1),
    (659, 1, 'EXTI', 'construccion', 'pases_completados', 0.05, 0);

-- DC
INSERT INTO pesos_metrica_posicion
    (id_peso_metrica, id_configuracion, codigo_posicion, bloque, clave_metrica, porcentaje, penaliza)
VALUES
    (598, 1, 'DC', 'ataque', 'goles', 1.22, 0),
    (599, 1, 'DC', 'ataque', 'asistencias', 0.62, 0),
    (600, 1, 'DC', 'ataque', 'xg', 0.31, 0),
    (601, 1, 'DC', 'ataque', 'xa', 0.13, 0),
    (602, 1, 'DC', 'ataque', 'second_assists', 0.05, 0),
    (603, 1, 'DC', 'ataque', 'asistencias_tiro', 0.10, 0),
    (604, 1, 'DC', 'construccion', 'acciones_totales', 0.02, 1),
    (605, 1, 'DC', 'construccion', 'acciones_logradas', 0.07, 0),
    (606, 1, 'DC', 'construccion', 'acciones_fallidas', 0.03, 1),
    (607, 1, 'DC', 'ataque', 'tiros_totales', 0.03, 1),
    (608, 1, 'DC', 'ataque', 'tiros_logrados', 0.19, 0),
    (609, 1, 'DC', 'ataque', 'tiros_fallados', 0.04, 1),
    (610, 1, 'DC', 'construccion', 'pases_largos_totales', 0.02, 1),
    (611, 1, 'DC', 'construccion', 'pases_largos_logrados', 0.05, 0),
    (612, 1, 'DC', 'construccion', 'pases_largos_fallados', 0.02, 1),
    (613, 1, 'DC', 'defensa', 'duelos_totales', 0.02, 1),
    (614, 1, 'DC', 'defensa', 'duelos_ganados', 0.06, 0),
    (615, 1, 'DC', 'defensa', 'duelos_perdidos', 0.02, 1),
    (616, 1, 'DC', 'defensa', 'duelos_aereos_totales', 0.02, 1),
    (617, 1, 'DC', 'defensa', 'duelos_aereos_ganados', 0.13, 0),
    (618, 1, 'DC', 'defensa', 'duelos_aereos_perdidos', 0.03, 1),
    (619, 1, 'DC', 'ataque', 'duelos_ofensivos_totales', 0.02, 1),
    (620, 1, 'DC', 'ataque', 'duelos_ofensivos_ganados', 0.13, 0),
    (621, 1, 'DC', 'ataque', 'duelos_ofensivos_perdidos', 0.03, 1),
    (622, 1, 'DC', 'defensa', 'interceptaciones', 0.05, 0),
    (623, 1, 'DC', 'defensa', 'despejes', 0.02, 0),
    (624, 1, 'DC', 'defensa', 'balones_perdidos_totales', 0.03, 1),
    (625, 1, 'DC', 'defensa', 'balones_perdidos_propia_mitad', 0.09, 1),
    (626, 1, 'DC', 'defensa', 'balones_recuperados', 0.07, 0),
    (627, 1, 'DC', 'defensa', 'balones_recuperados_mitad_adversaria', 0.17, 0),
    (628, 1, 'DC', 'defensa', 'tarjeta_amarilla', 0.14, 1),
    (629, 1, 'DC', 'defensa', 'tarjeta_roja', 0.55, 1),
    (630, 1, 'DC', 'construccion', 'carreras_profundidad', 0.10, 0),
    (631, 1, 'DC', 'construccion', 'pases_profundidad_totales', 0.02, 1),
    (632, 1, 'DC', 'construccion', 'pases_profundidad_logrados', 0.07, 0),
    (633, 1, 'DC', 'construccion', 'pases_profundidad_perdidos', 0.03, 1),
    (634, 1, 'DC', 'construccion', 'pases_area_penalti_totales', 0.02, 1),
    (635, 1, 'DC', 'construccion', 'pases_area_penalti_logrados', 0.07, 0),
    (636, 1, 'DC', 'construccion', 'pases_area_penalti_perdidos', 0.03, 1),
    (637, 1, 'DC', 'construccion', 'pases_recibidos', 0.02, 0),
    (638, 1, 'DC', 'construccion', 'pases_hacia_delante_totales', 0.02, 1),
    (639, 1, 'DC', 'construccion', 'pases_hacia_delante_logrados', 0.05, 0),
    (640, 1, 'DC', 'construccion', 'pases_hacia_delante_perdidos', 0.02, 1),
    (641, 1, 'DC', 'construccion', 'pases_hacia_atras_totales', 0.02, 1),
    (642, 1, 'DC', 'construccion', 'pases_hacia_atras_logrados', 0.05, 0),
    (643, 1, 'DC', 'construccion', 'pases_hacia_atras_perdidos', 0.02, 1),
    (662, 1, 'DC', 'construccion', 'pases_totales', 0.01, 1),
    (663, 1, 'DC', 'construccion', 'pases_completados', 0.05, 0);

-- ============================================================
-- 9. DATOS DE PRUEBA (temporada 2025/26)
-- ============================================================

INSERT INTO temporadas (nombre, fecha_inicio, fecha_fin, activa) VALUES
    ('2025/26', '2025-08-15', '2026-06-30', TRUE);

INSERT INTO jugadores (nombre, apellidos, alias, posicion_habitual, estado) VALUES
    ('Joseba',  'Bermejo',    '',        'POR',  'activo'),
    ('Unai',    'Ayala',      'Lunin',   'POR',  'activo'),
    ('Anartz',  'Amilibia',   'Ami',     'LD',   'activo'),
    ('Lucas',   'Sarasketa',  'Cabezon', 'LI',   'activo'),
    ('Oier',    'Llorente',   'Txo',     'DFC',  'activo'),
    ('Aitor',   'Larrañaga',  'Larra',   'DFC',  'activo'),
    ('Llorenc', 'Ferres',     'Ferreti', 'LI',   'activo'),
    ('Xavi',    'Pastor',     'Pastor',  'DFC',  'activo'),
    ('Oscar',   'Garcia',     'Osito',   'MC',   'activo'),
    ('Julen',   'Agirre',     'Jul',     'MCD',  'activo'),
    ('Ibai',    'Asenjo',     'Txejo',   'MCO',  'activo'),
    ('Asier',   'Santolaya',  'Santo',   'MCD',  'activo'),
    ('Jon',     'Lopez',      'Jonlo',   'DC',   'activo'),
    ('Marc',    'Delgado',    '',        'MC',   'activo'),
    ('Endika',  'Mateos',     'Bezana',  'EXTI', 'activo'),
    ('Ekaitz',  'Redondo',    'Eka',     'DC',   'activo'),
    ('Iker',    'Zubiria',    'Zubi',    'EXTD', 'activo'),
    ('Marcos',  'Sotelo',     'Sote',    'EXTD', 'activo'),
    ('Ekain',   'Etxebarria', 'Eka',     'DC',   'activo'),
    ('Hugo',    'Garcia',     'Hugillo', 'EXTI', 'activo');

INSERT INTO dorsales_jugador (id_jugador, id_temporada, dorsal) VALUES
    (1,  1,  1), (2,  1, 13), (3,  1,  2), (4,  1,  3), (5,  1,  4),
    (6,  1,  5), (7,  1, 22), (8,  1, 23), (9,  1,  8), (10, 1,  6),
    (11, 1, 14), (12, 1, 16), (13, 1, 17), (14, 1, 21), (15, 1,  7),
    (16, 1,  9), (17, 1, 10), (18, 1, 11), (19, 1, 18), (20, 1, 19);