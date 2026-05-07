-- ============================================================
-- BASE DE DATOS: sistema_futbol
-- Proyecto: Sistema de Scoring, Analisis de Rendimiento
--           y Control de Lesiones - SD Eibar
-- ============================================================
DROP DATABASE IF EXISTS sistema_futbol;

CREATE DATABASE sistema_futbol;

USE sistema_futbol;

-- ============================================================
-- TABLAS DE USUARIOS Y ACCESO
-- ============================================================
CREATE TABLE
    usuarios (
        id_usuario INT AUTO_INCREMENT PRIMARY KEY,
        nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
        contraseña_hash VARCHAR(255) NOT NULL, -- Se guarda con bcrypt o texto plano en pruebas
        rol ENUM ('admin', 'entrenador', 'analista') NOT NULL,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- ============================================================
-- TABLAS PRINCIPALES DEL CLUB
-- ============================================================
CREATE TABLE
    temporadas (
        id_temporada INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(20) NOT NULL, -- Ej: '2025/26'
        fecha_inicio DATE,
        fecha_fin DATE,
        activa BOOLEAN DEFAULT FALSE
    );

CREATE TABLE
    jugadores (
        id_jugador INT AUTO_INCREMENT PRIMARY KEY,
        nombre VARCHAR(50) NOT NULL,
        apellidos VARCHAR(50) NOT NULL,
        alias VARCHAR(50),
        posicion_habitual VARCHAR(50),
        estado ENUM ('activo', 'lesionado', 'baja') DEFAULT 'activo',
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Dorsal de cada jugador por temporada
CREATE TABLE
    dorsales_jugador (
        id_dorsal INT AUTO_INCREMENT PRIMARY KEY,
        id_jugador INT,
        id_temporada INT,
        dorsal INT UNIQUE,
        FOREIGN KEY (id_jugador) REFERENCES jugadores (id_jugador) ON DELETE CASCADE,
        FOREIGN KEY (id_temporada) REFERENCES temporadas (id_temporada) ON DELETE CASCADE
    );

CREATE TABLE
    partidos (
        id_partido INT AUTO_INCREMENT PRIMARY KEY,
        id_temporada INT,
        fecha DATE NOT NULL,
        competicion VARCHAR(100),
        rival VARCHAR(100),
        local_visitante ENUM ('local', 'visitante'),
        goles_favor INT DEFAULT 0,
        goles_contra INT DEFAULT 0,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_temporada) REFERENCES temporadas (id_temporada)
    );

-- ============================================================
-- TABLAS DE LESIONES
-- ============================================================
CREATE TABLE
    lesiones (
        id_lesion INT AUTO_INCREMENT PRIMARY KEY,
        id_jugador INT,
        fecha_inicio DATE NOT NULL,
        fecha_fin DATE,
        tipo_lesion VARCHAR(100),
        gravedad ENUM ('leve', 'moderada', 'grave'),
        fecha_prevista_retorno DATE,
        observaciones TEXT,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_jugador) REFERENCES jugadores (id_jugador)
    );

-- ============================================================
-- TABLAS DEL SISTEMA DE PUNTUACIONES (gestionadas por Python)
-- ============================================================
-- Catalogo de posiciones
CREATE TABLE
    posiciones (
        codigo_posicion VARCHAR(5) PRIMARY KEY,
        nombre_posicion VARCHAR(50) NOT NULL,
        linea ENUM ('defensa', 'medio', 'ataque') NOT NULL
    );

-- Configuraciones de pesos del modelo de scoring
CREATE TABLE
    configuraciones_pesos (
        id_configuracion INT AUTO_INCREMENT PRIMARY KEY,
        nombre_configuracion VARCHAR(100) NOT NULL,
        activa BOOLEAN DEFAULT FALSE,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

-- Pesos por bloque (ataque / construccion / defensa) segun posicion
CREATE TABLE
    pesos_bloque_posicion (
        id_peso INT AUTO_INCREMENT PRIMARY KEY,
        id_configuracion INT,
        codigo_posicion VARCHAR(5),
        porcentaje_ataque DECIMAL(5, 2),
        porcentaje_construccion DECIMAL(5, 2),
        porcentaje_defensa DECIMAL(5, 2),
        FOREIGN KEY (id_configuracion) REFERENCES configuraciones_pesos (id_configuracion),
        FOREIGN KEY (codigo_posicion) REFERENCES posiciones (codigo_posicion)
    );

-- Pesos de cada metrica dentro de su bloque
CREATE TABLE
    pesos_metrica_posicion (
        id_peso_metrica INT AUTO_INCREMENT PRIMARY KEY,
        id_configuracion INT,
        codigo_posicion VARCHAR(5),
        bloque ENUM ('ataque', 'construccion', 'defensa'),
        clave_metrica VARCHAR(50),
        porcentaje DECIMAL(5, 2),
        penaliza BOOLEAN DEFAULT FALSE,
        FOREIGN KEY (id_configuracion) REFERENCES configuraciones_pesos (id_configuracion),
        FOREIGN KEY (codigo_posicion) REFERENCES posiciones (codigo_posicion)
    );

-- Puntuaciones calculadas por Python para cada jugador en cada partido
CREATE TABLE
    puntuaciones (
        id_puntuacion INT AUTO_INCREMENT PRIMARY KEY,
        id_partido INT,
        id_jugador INT,
        posicion_evaluada VARCHAR(50),
        puntuacion_ataque DECIMAL(4, 2),
        puntuacion_construccion DECIMAL(4, 2),
        puntuacion_defensa DECIMAL(4, 2),
        factor_minutos DECIMAL(4, 2),
        puntuacion_final DECIMAL(4, 2),
        explicacion_positiva TEXT,
        explicacion_negativa TEXT,
        version_modelo VARCHAR(50),
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_partido) REFERENCES partidos (id_partido),
        FOREIGN KEY (id_jugador) REFERENCES jugadores (id_jugador)
    );

-- Estadisticas raw de cada jugador por partido (importadas desde Excel por Python)
DROP TABLE IF EXISTS `estadisticas_jugador_partido`;

/*!40101 SET @saved_cs_client     = @@character_set_client */;

/*!50503 SET character_set_client = utf8mb4 */;

CREATE TABLE
    `estadisticas_jugador_partido` (
        `id_estadistica` int NOT NULL AUTO_INCREMENT,
        `id_partido` int NOT NULL,
        `id_jugador` int NOT NULL,
        `posicion_jugada` varchar(10) DEFAULT NULL,
        `minutos_jugados` float DEFAULT NULL,
        `acciones_totales` float DEFAULT '0',
        `acciones_logradas` float DEFAULT '0',
        `acciones_fallidas` float DEFAULT '0',
        `goles` float DEFAULT '0',
        `asistencias` float DEFAULT '0',
        `tiros_totales` float DEFAULT '0',
        `tiros_logrados` float DEFAULT '0',
        `tiros_fallados` float DEFAULT '0',
        `xg` float DEFAULT '0',
        `xa` float DEFAULT '0',
        `second_assists` float DEFAULT '0',
        `asistencias_tiro` float DEFAULT '0',
        `pases_totales` float DEFAULT '0',
        `pases_completados` float DEFAULT '0',
        `pases_fallados` float DEFAULT '0',
        `pases_largos_totales` float DEFAULT '0',
        `pases_largos_logrados` float DEFAULT '0',
        `pases_largos_fallados` float DEFAULT '0',
        `pases_area_penalti_totales` float DEFAULT '0',
        `pases_area_penalti_logrados` float DEFAULT '0',
        `pases_area_penalti_perdidos` float DEFAULT '0',
        `pases_profundidad_totales` float DEFAULT '0',
        `pases_profundidad_logrados` float DEFAULT '0',
        `pases_profundidad_perdidos` float DEFAULT '0',
        `pases_hacia_delante_totales` float DEFAULT '0',
        `pases_hacia_delante_logrados` float DEFAULT '0',
        `pases_hacia_delante_perdidos` float DEFAULT '0',
        `pases_hacia_atras_totales` float DEFAULT '0',
        `pases_hacia_atras_logrados` float DEFAULT '0',
        `pases_hacia_atras_perdidos` float DEFAULT '0',
        `pases_recibidos` float DEFAULT '0',
        `carreras_profundidad` float DEFAULT '0',
        `duelos_totales` float DEFAULT '0',
        `duelos_ganados` float DEFAULT '0',
        `duelos_perdidos` float DEFAULT '0',
        `duelos_defensivos_totales` float DEFAULT '0',
        `duelos_defensivos_ganados` float DEFAULT '0',
        `duelos_ofensivos_totales` float DEFAULT '0',
        `duelos_ofensivos_ganados` float DEFAULT '0',
        `duelos_ofensivos_perdidos` float DEFAULT '0',
        `duelos_aereos_totales` float DEFAULT '0',
        `duelos_aereos_ganados` float DEFAULT '0',
        `duelos_aereos_perdidos` float DEFAULT '0',
        `regates_totales` float DEFAULT NULL,
        `regates_exitosos` float DEFAULT NULL,
        `interceptaciones` float DEFAULT '0',
        `despejes` float DEFAULT '0',
        `balones_perdidos_totales` float DEFAULT '0',
        `balones_perdidos_propia_mitad` float DEFAULT '0',
        `balones_recuperados` float DEFAULT '0',
        `balones_recuperados_mitad_adversaria` float DEFAULT '0',
        `tarjeta_amarilla` int DEFAULT '0',
        `tarjeta_roja` int DEFAULT '0',
        `archivo_origen` varchar(255) DEFAULT NULL,
        `fecha_creacion` datetime DEFAULT NULL,
        PRIMARY KEY (`id_estadistica`),
        KEY `id_partido` (`id_partido`),
        KEY `id_jugador` (`id_jugador`),
        CONSTRAINT `estadisticas_jugador_partido_ibfk_1` FOREIGN KEY (`id_partido`) REFERENCES `partidos` (`id_partido`) ON DELETE CASCADE,
        CONSTRAINT `estadisticas_jugador_partido_ibfk_2` FOREIGN KEY (`id_jugador`) REFERENCES `jugadores` (`id_jugador`) ON DELETE CASCADE
    );

-- Notas manuales del entrenador (opcional)
CREATE TABLE
    notas_entrenador (
        id_nota INT AUTO_INCREMENT PRIMARY KEY,
        id_partido INT,
        id_jugador INT,
        nota DECIMAL(4, 2),
        comentario TEXT,
        fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (id_partido) REFERENCES partidos (id_partido),
        FOREIGN KEY (id_jugador) REFERENCES jugadores (id_jugador)
    );

-- ============================================================
-- DATOS INICIALES DEL SISTEMA
-- ============================================================
-- Posiciones del catalogo
INSERT INTO
    posiciones (codigo_posicion, nombre_posicion, linea)
VALUES
    ('POR', 'Portero', 'defensa'),
    ('DFC', 'Central', 'defensa'),
    ('LD', 'Lateral Derecho', 'defensa'),
    ('LI', 'Lateral Izquierdo', 'defensa'),
    ('MCD', 'Mediocentro Defensivo', 'medio'),
    ('MC', 'Mediocentro', 'medio'),
    ('MCO', 'Mediocentro Ofensivo', 'medio'),
    ('EXTD', 'Extremo Derecho', 'ataque'),
    ('EXTI', 'Extremo Izquierdo', 'ataque'),
    ('DC', 'Delantero Centro', 'ataque');

-- Usuarios del sistema (contraseñas en texto plano para pruebas locales)
INSERT INTO
    usuarios (nombre_usuario, contraseña_hash, rol)
VALUES
    ('admin', '1234', 'admin'),
    ('mister', '1234', 'entrenador'),
    ('analista1', '1234', 'analista');

-- Configuracion de pesos del modelo de scoring
INSERT INTO
    configuraciones_pesos (nombre_configuracion, activa)
VALUES
    ('Modelo Estándar 2026', TRUE);

-- Peso de bloques para la posicion DC (de prueba)
INSERT INTO
    pesos_bloque_posicion (
        id_configuracion,
        codigo_posicion,
        porcentaje_ataque,
        porcentaje_construccion,
        porcentaje_defensa
    )
VALUES
    (1, 'DC', 0.60, 0.30, 0.10);

-- ============================================================
-- DATOS DE PRUEBA (mock data temporada 2025/26)
-- ============================================================
-- Temporada activa
INSERT INTO
    temporadas (nombre, fecha_inicio, fecha_fin, activa)
VALUES
    ('2025/26', '2025-08-15', '2026-06-30', TRUE);

-- Plantilla de jugadores
INSERT INTO
    jugadores (
        nombre,
        apellidos,
        alias,
        posicion_habitual,
        estado
    )
VALUES
    ('Joseba', 'Bermejo', '', 'POR', 'activo'),
    ('Unai', 'Ayala', 'Lunin', 'POR', 'activo'),
    ('Anartz', 'Amilibia', 'Ami', 'LD', 'activo'),
    ('Lucas', 'Sarasketa', 'Cabezon', 'LI', 'activo'),
    ('Oier', 'Llorente', 'Txo', 'DFC', 'activo'),
    ('Aitor', 'Larrañaga', 'Larra', 'DFC', 'activo'),
    ('Llorenc', 'Ferres', 'Ferreti', 'LI', 'activo'),
    ('Xavi', 'Pastor', 'Pastor', 'DFC', 'activo'),
    ('Oscar', 'Garcia', 'Osito', 'MC', 'activo'),
    ('Julen', 'Agirre', 'Jul', 'MCD', 'activo'),
    ('Ibai', 'Asenjo', 'Txejo', 'MCO', 'activo'),
    ('Asier', 'Santolaya', 'Santo', 'MCD', 'activo'),
    ('Jon', 'Lopez', 'Jonlo', 'DC', 'activo'),
    ('Marc', 'Delgado', '', 'MC', 'activo'),
    ('Endika', 'Mateos', 'Bezana', 'EXTI', 'activo'),
    ('Ekaitz', 'Redondo', 'Eka', 'DC', 'activo'),
    ('Iker', 'Zubiria', 'Zubi', 'EXTD', 'activo'),
    ('Marcos', 'Sotelo', 'Sote', 'EXTD', 'activo'),
    ('Ekain', 'Etxebarria', 'Eka', 'DC', 'activo'),
    ('Hugo', 'Garcia', 'Hugillo', 'EXTI', 'activo');

-- Dorsales de la temporada 2025/26
INSERT INTO
    dorsales_jugador (id_dorsal, id_jugador, id_temporada, dorsal)
VALUES
    (1, 1, 1, 1),
    (2, 2, 1, 13),
    (3, 3, 1, 2),
    (4, 4, 1, 3),
    (5, 5, 1, 4),
    (6, 6, 1, 5),
    (7, 7, 1, 22),
    (8, 8, 1, 23),
    (9, 9, 1, 8),
    (10, 10, 1, 6),
    (11, 11, 1, 14),
    (12, 12, 1, 16),
    (13, 13, 1, 17),
    (14, 14, 1, 21),
    (15, 15, 1, 7),
    (16, 16, 1, 9),
    (17, 17, 1, 10),
    (18, 18, 1, 11),
    (19, 19, 1, 18),
    (20, 20, 1, 19);

-- Calendario de partidos temporada 2025/26
INSERT INTO
    partidos (
        id_temporada,
        fecha,
        competicion,
        rival,
        local_visitante,
        goles_favor,
        goles_contra
    )
VALUES
    (
        1,
        '2025-09-07',
        'Segunda Federacion',
        'SD Logroñes',
        'visitante',
        2,
        0
    ),
    (
        1,
        '2025-09-14',
        'Segunda Federacion',
        'Alfaro',
        'local',
        4,
        3
    ),
    (
        1,
        '2025-09-21',
        'Segunda Federacion',
        'Tudelano',
        'visitante',
        1,
        0
    ),
    (
        1,
        '2025-09-28',
        'Segunda Federacion',
        'Deportivo Alaves B',
        'local',
        0,
        1
    ),
    (
        1,
        '2025-10-05',
        'Segunda Federacion',
        'Naxara',
        'visitante',
        1,
        1
    ),
    (
        1,
        '2025-10-11',
        'Segunda Federacion',
        'Ejea',
        'local',
        2,
        1
    ),
    (
        1,
        '2025-10-18',
        'Segunda Federacion',
        'Beasain KE',
        'visitante',
        1,
        2
    ),
    (
        1,
        '2025-10-25',
        'Segunda Federacion',
        'Real Union Club',
        'local',
        0,
        1
    ),
    (
        1,
        '2025-11-02',
        'Segunda Federacion',
        'CD Ebro',
        'visitante',
        1,
        1
    ),
    (
        1,
        '2025-11-08',
        'Segunda Federacion',
        'Mutilvera',
        'local',
        1,
        2
    ),
    (
        1,
        '2025-11-16',
        'Segunda Federacion',
        'UD Logroñes',
        'visitante',
        0,
        1
    ),
    (
        1,
        '2025-11-22',
        'Segunda Federacion',
        'Sestao River',
        'visitante',
        1,
        0
    ),
    (
        1,
        '2025-11-29',
        'Segunda Federacion',
        'Deportivo Aragon',
        'local',
        1,
        0
    ),
    (
        1,
        '2025-12-06',
        'Segunda Federacion',
        'CD Basconia',
        'visitante',
        1,
        1
    ),
    (
        1,
        '2025-12-13',
        'Segunda Federacion',
        'SD Amorebieta',
        'local',
        0,
        2
    ),
    (
        1,
        '2025-12-20',
        'Segunda Federacion',
        'SD Gernika',
        'visitante',
        1,
        2
    ),
    (
        1,
        '2026-01-04',
        'Segunda Federacion',
        'Utebo',
        'local',
        1,
        1
    ),
    (
        1,
        '2026-01-11',
        'Segunda Federacion',
        'CD Alfaro',
        'visitante',
        0,
        0
    ),
    (
        1,
        '2026-01-17',
        'Segunda Federacion',
        'SD Logroñes',
        'local',
        0,
        0
    ),
    (
        1,
        '2026-01-24',
        'Segunda Federacion',
        'Deportivo Alaves B',
        'visitante',
        2,
        0
    ),
    (
        1,
        '2026-01-31',
        'Segunda Federacion',
        'Tudelano',
        'local',
        1,
        0
    ),
    (
        1,
        '2026-02-08',
        'Segunda Federacion',
        'Deportivo Aragon',
        'visitante',
        0,
        1
    ),
    (
        1,
        '2026-02-15',
        'Segunda Federacion',
        'CD Basconia',
        'local',
        1,
        3
    ),
    (
        1,
        '2026-02-21',
        'Segunda Federacion',
        'Real Union Club',
        'visitante',
        2,
        1
    ),
    (
        1,
        '2026-02-28',
        'Segunda Federacion',
        'SD Gernika',
        'local',
        3,
        2
    ),
    (
        1,
        '2026-03-07',
        'Segunda Federacion',
        'Sestao River',
        'local',
        2,
        1
    ),
    (
        1,
        '2026-03-14',
        'Segunda Federacion',
        'Mutilvera',
        'visitante',
        4,
        0
    ),
    (
        1,
        '2026-03-21',
        'Segunda Federacion',
        'Beasain KE',
        'local',
        0,
        1
    );

-- Puntuaciones de prueba (partido 1 - SD Logroñes)
INSERT INTO
    puntuaciones (
        id_partido,
        id_jugador,
        posicion_evaluada,
        puntuacion_ataque,
        puntuacion_construccion,
        puntuacion_defensa,
        factor_minutos,
        puntuacion_final
    )
VALUES
    (1, 13, 'DC', 7.20, 5.10, 3.40, 1.00, 7.50),
    (1, 16, 'DC', 6.80, 4.90, 2.10, 0.95, 6.90),
    (1, 9, 'MC', 4.50, 7.80, 5.20, 1.00, 6.40),
    (1, 10, 'MCD', 3.20, 6.90, 7.10, 1.00, 6.10),
    (1, 3, 'LD', 2.10, 5.40, 7.80, 0.90, 5.80),
    (1, 5, 'DFC', 1.80, 4.20, 8.30, 1.00, 5.60),
    (1, 6, 'DFC', 1.50, 3.90, 7.60, 0.85, 5.20),
    (1, 15, 'EXTI', 6.10, 5.30, 2.80, 0.80, 5.00);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (184, 1, 'POR', 'ataque', 'goles', 3.05, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (185, 1, 'POR', 'ataque', 'asistencias', 1.22, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (186, 1, 'POR', 'ataque', 'xg', 0.07, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (187, 1, 'POR', 'ataque', 'xa', 0.31, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        188,
        1,
        'POR',
        'ataque',
        'second_assists',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        189,
        1,
        'POR',
        'ataque',
        'asistencias_tiro',
        0.19,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        190,
        1,
        'POR',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        191,
        1,
        'POR',
        'construccion',
        'acciones_logradas',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        192,
        1,
        'POR',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (193, 1, 'POR', 'ataque', 'tiros_totales', 0.02, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        194,
        1,
        'POR',
        'ataque',
        'tiros_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        195,
        1,
        'POR',
        'ataque',
        'tiros_fallados',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        196,
        1,
        'POR',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        197,
        1,
        'POR',
        'construccion',
        'pases_largos_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        198,
        1,
        'POR',
        'construccion',
        'pases_largos_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        199,
        1,
        'POR',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        200,
        1,
        'POR',
        'defensa',
        'duelos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        201,
        1,
        'POR',
        'defensa',
        'duelos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        202,
        1,
        'POR',
        'defensa',
        'duelos_aereos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        203,
        1,
        'POR',
        'defensa',
        'duelos_aereos_ganados',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        204,
        1,
        'POR',
        'defensa',
        'duelos_aereos_perdidos',
        0.04,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        205,
        1,
        'POR',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        206,
        1,
        'POR',
        'ataque',
        'duelos_ofensivos_ganados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        207,
        1,
        'POR',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        208,
        1,
        'POR',
        'defensa',
        'interceptaciones',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (209, 1, 'POR', 'defensa', 'despejes', 0.10, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        210,
        1,
        'POR',
        'defensa',
        'balones_perdidos_totales',
        0.04,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        211,
        1,
        'POR',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.22,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        212,
        1,
        'POR',
        'defensa',
        'balones_recuperados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        213,
        1,
        'POR',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.31,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        214,
        1,
        'POR',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (215, 1, 'POR', 'defensa', 'tarjeta_roja', 0.82, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        216,
        1,
        'POR',
        'construccion',
        'carreras_profundidad',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        217,
        1,
        'POR',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        218,
        1,
        'POR',
        'construccion',
        'pases_profundidad_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        219,
        1,
        'POR',
        'construccion',
        'pases_profundidad_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        220,
        1,
        'POR',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        221,
        1,
        'POR',
        'construccion',
        'pases_area_penalti_logrados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        222,
        1,
        'POR',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        223,
        1,
        'POR',
        'construccion',
        'pases_recibidos',
        0.01,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        224,
        1,
        'POR',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        225,
        1,
        'POR',
        'construccion',
        'pases_hacia_delante_logrados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        226,
        1,
        'POR',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        227,
        1,
        'POR',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        228,
        1,
        'POR',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        229,
        1,
        'POR',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (230, 1, 'DFC', 'ataque', 'goles', 1.22, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (231, 1, 'DFC', 'ataque', 'asistencias', 0.62, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (232, 1, 'DFC', 'ataque', 'xg', 0.13, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (233, 1, 'DFC', 'ataque', 'xa', 0.10, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        234,
        1,
        'DFC',
        'ataque',
        'second_assists',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        235,
        1,
        'DFC',
        'ataque',
        'asistencias_tiro',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        236,
        1,
        'DFC',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        237,
        1,
        'DFC',
        'construccion',
        'acciones_logradas',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        238,
        1,
        'DFC',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (239, 1, 'DFC', 'ataque', 'tiros_totales', 0.02, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        240,
        1,
        'DFC',
        'ataque',
        'tiros_logrados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        241,
        1,
        'DFC',
        'ataque',
        'tiros_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        242,
        1,
        'DFC',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        243,
        1,
        'DFC',
        'construccion',
        'pases_largos_logrados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        244,
        1,
        'DFC',
        'construccion',
        'pases_largos_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        245,
        1,
        'DFC',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        246,
        1,
        'DFC',
        'defensa',
        'duelos_ganados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        247,
        1,
        'DFC',
        'defensa',
        'duelos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        248,
        1,
        'DFC',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        249,
        1,
        'DFC',
        'defensa',
        'duelos_aereos_ganados',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        250,
        1,
        'DFC',
        'defensa',
        'duelos_aereos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        251,
        1,
        'DFC',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        252,
        1,
        'DFC',
        'ataque',
        'duelos_ofensivos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        253,
        1,
        'DFC',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        254,
        1,
        'DFC',
        'defensa',
        'interceptaciones',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (255, 1, 'DFC', 'defensa', 'despejes', 0.10, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        256,
        1,
        'DFC',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        257,
        1,
        'DFC',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        258,
        1,
        'DFC',
        'defensa',
        'balones_recuperados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        259,
        1,
        'DFC',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        260,
        1,
        'DFC',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (261, 1, 'DFC', 'defensa', 'tarjeta_roja', 0.69, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        262,
        1,
        'DFC',
        'construccion',
        'carreras_profundidad',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        263,
        1,
        'DFC',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        264,
        1,
        'DFC',
        'construccion',
        'pases_profundidad_logrados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        265,
        1,
        'DFC',
        'construccion',
        'pases_profundidad_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        266,
        1,
        'DFC',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        267,
        1,
        'DFC',
        'construccion',
        'pases_area_penalti_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        268,
        1,
        'DFC',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        269,
        1,
        'DFC',
        'construccion',
        'pases_recibidos',
        0.01,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        270,
        1,
        'DFC',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        271,
        1,
        'DFC',
        'construccion',
        'pases_hacia_delante_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        272,
        1,
        'DFC',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        273,
        1,
        'DFC',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        274,
        1,
        'DFC',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        275,
        1,
        'DFC',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (276, 1, 'LD', 'ataque', 'goles', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (277, 1, 'LI', 'ataque', 'goles', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (278, 1, 'LD', 'ataque', 'asistencias', 0.73, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (279, 1, 'LI', 'ataque', 'asistencias', 0.73, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (280, 1, 'LD', 'ataque', 'xg', 0.19, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (281, 1, 'LI', 'ataque', 'xg', 0.19, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (282, 1, 'LD', 'ataque', 'xa', 0.26, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (283, 1, 'LI', 'ataque', 'xa', 0.26, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (284, 1, 'LD', 'ataque', 'second_assists', 0.10, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (285, 1, 'LI', 'ataque', 'second_assists', 0.10, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        286,
        1,
        'LD',
        'ataque',
        'asistencias_tiro',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        287,
        1,
        'LI',
        'ataque',
        'asistencias_tiro',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        288,
        1,
        'LD',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        289,
        1,
        'LI',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        290,
        1,
        'LD',
        'construccion',
        'acciones_logradas',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        291,
        1,
        'LI',
        'construccion',
        'acciones_logradas',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        292,
        1,
        'LD',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        293,
        1,
        'LI',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (294, 1, 'LD', 'ataque', 'tiros_totales', 0.02, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (295, 1, 'LI', 'ataque', 'tiros_totales', 0.02, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (296, 1, 'LD', 'ataque', 'tiros_logrados', 0.10, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (297, 1, 'LI', 'ataque', 'tiros_logrados', 0.10, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (298, 1, 'LD', 'ataque', 'tiros_fallados', 0.03, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (299, 1, 'LI', 'ataque', 'tiros_fallados', 0.03, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        300,
        1,
        'LD',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        301,
        1,
        'LI',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        302,
        1,
        'LD',
        'construccion',
        'pases_largos_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        303,
        1,
        'LI',
        'construccion',
        'pases_largos_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        304,
        1,
        'LD',
        'construccion',
        'pases_largos_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        305,
        1,
        'LI',
        'construccion',
        'pases_largos_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        306,
        1,
        'LD',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        307,
        1,
        'LI',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        308,
        1,
        'LD',
        'defensa',
        'duelos_ganados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        309,
        1,
        'LI',
        'defensa',
        'duelos_ganados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        310,
        1,
        'LD',
        'defensa',
        'duelos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        311,
        1,
        'LI',
        'defensa',
        'duelos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        312,
        1,
        'LD',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        313,
        1,
        'LI',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        314,
        1,
        'LD',
        'defensa',
        'duelos_aereos_ganados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        315,
        1,
        'LI',
        'defensa',
        'duelos_aereos_ganados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        316,
        1,
        'LD',
        'defensa',
        'duelos_aereos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        317,
        1,
        'LI',
        'defensa',
        'duelos_aereos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        318,
        1,
        'LD',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        319,
        1,
        'LI',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        320,
        1,
        'LD',
        'ataque',
        'duelos_ofensivos_ganados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        321,
        1,
        'LI',
        'ataque',
        'duelos_ofensivos_ganados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        322,
        1,
        'LD',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        323,
        1,
        'LI',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        324,
        1,
        'LD',
        'defensa',
        'interceptaciones',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        325,
        1,
        'LI',
        'defensa',
        'interceptaciones',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (326, 1, 'LD', 'defensa', 'despejes', 0.06, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (327, 1, 'LI', 'defensa', 'despejes', 0.06, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        328,
        1,
        'LD',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        329,
        1,
        'LI',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        330,
        1,
        'LD',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.09,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        331,
        1,
        'LI',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.09,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        332,
        1,
        'LD',
        'defensa',
        'balones_recuperados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        333,
        1,
        'LI',
        'defensa',
        'balones_recuperados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        334,
        1,
        'LD',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        335,
        1,
        'LI',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        336,
        1,
        'LD',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        337,
        1,
        'LI',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (338, 1, 'LD', 'defensa', 'tarjeta_roja', 0.55, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (339, 1, 'LI', 'defensa', 'tarjeta_roja', 0.55, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        340,
        1,
        'LD',
        'construccion',
        'carreras_profundidad',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        341,
        1,
        'LI',
        'construccion',
        'carreras_profundidad',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        342,
        1,
        'LD',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        343,
        1,
        'LI',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        344,
        1,
        'LD',
        'construccion',
        'pases_profundidad_logrados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        345,
        1,
        'LI',
        'construccion',
        'pases_profundidad_logrados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        346,
        1,
        'LD',
        'construccion',
        'pases_profundidad_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        347,
        1,
        'LI',
        'construccion',
        'pases_profundidad_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        348,
        1,
        'LD',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        349,
        1,
        'LI',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        350,
        1,
        'LD',
        'construccion',
        'pases_area_penalti_logrados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        351,
        1,
        'LI',
        'construccion',
        'pases_area_penalti_logrados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        352,
        1,
        'LD',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        353,
        1,
        'LI',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        354,
        1,
        'LD',
        'construccion',
        'pases_recibidos',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        355,
        1,
        'LI',
        'construccion',
        'pases_recibidos',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        356,
        1,
        'LD',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        357,
        1,
        'LI',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        358,
        1,
        'LD',
        'construccion',
        'pases_hacia_delante_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        359,
        1,
        'LI',
        'construccion',
        'pases_hacia_delante_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        360,
        1,
        'LD',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        361,
        1,
        'LI',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        362,
        1,
        'LD',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        363,
        1,
        'LI',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        364,
        1,
        'LD',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        365,
        1,
        'LI',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        366,
        1,
        'LD',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        367,
        1,
        'LI',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (368, 1, 'MCD', 'ataque', 'goles', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (369, 1, 'MCD', 'ataque', 'asistencias', 0.62, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (370, 1, 'MCD', 'ataque', 'xg', 0.13, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (371, 1, 'MCD', 'ataque', 'xa', 0.13, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        372,
        1,
        'MCD',
        'ataque',
        'second_assists',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        373,
        1,
        'MCD',
        'ataque',
        'asistencias_tiro',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        374,
        1,
        'MCD',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        375,
        1,
        'MCD',
        'construccion',
        'acciones_logradas',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        376,
        1,
        'MCD',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (377, 1, 'MCD', 'ataque', 'tiros_totales', 0.02, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        378,
        1,
        'MCD',
        'ataque',
        'tiros_logrados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        379,
        1,
        'MCD',
        'ataque',
        'tiros_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        380,
        1,
        'MCD',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        381,
        1,
        'MCD',
        'construccion',
        'pases_largos_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        382,
        1,
        'MCD',
        'construccion',
        'pases_largos_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        383,
        1,
        'MCD',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        384,
        1,
        'MCD',
        'defensa',
        'duelos_ganados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        385,
        1,
        'MCD',
        'defensa',
        'duelos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        386,
        1,
        'MCD',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        387,
        1,
        'MCD',
        'defensa',
        'duelos_aereos_ganados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        388,
        1,
        'MCD',
        'defensa',
        'duelos_aereos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        389,
        1,
        'MCD',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        390,
        1,
        'MCD',
        'ataque',
        'duelos_ofensivos_ganados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        391,
        1,
        'MCD',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        392,
        1,
        'MCD',
        'defensa',
        'interceptaciones',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (393, 1, 'MCD', 'defensa', 'despejes', 0.07, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        394,
        1,
        'MCD',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        395,
        1,
        'MCD',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.11,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        396,
        1,
        'MCD',
        'defensa',
        'balones_recuperados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        397,
        1,
        'MCD',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        398,
        1,
        'MCD',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (399, 1, 'MCD', 'defensa', 'tarjeta_roja', 0.55, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        400,
        1,
        'MCD',
        'construccion',
        'carreras_profundidad',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        401,
        1,
        'MCD',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        402,
        1,
        'MCD',
        'construccion',
        'pases_profundidad_logrados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        403,
        1,
        'MCD',
        'construccion',
        'pases_profundidad_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        404,
        1,
        'MCD',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        405,
        1,
        'MCD',
        'construccion',
        'pases_area_penalti_logrados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        406,
        1,
        'MCD',
        'construccion',
        'pases_area_penalti_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        407,
        1,
        'MCD',
        'construccion',
        'pases_recibidos',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        408,
        1,
        'MCD',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        409,
        1,
        'MCD',
        'construccion',
        'pases_hacia_delante_logrados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        410,
        1,
        'MCD',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        411,
        1,
        'MCD',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        412,
        1,
        'MCD',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        413,
        1,
        'MCD',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (414, 1, 'MC', 'ataque', 'goles', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (415, 1, 'MC', 'ataque', 'asistencias', 0.73, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (416, 1, 'MC', 'ataque', 'xg', 0.17, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (417, 1, 'MC', 'ataque', 'xa', 0.19, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (418, 1, 'MC', 'ataque', 'second_assists', 0.13, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        419,
        1,
        'MC',
        'ataque',
        'asistencias_tiro',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        420,
        1,
        'MC',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        421,
        1,
        'MC',
        'construccion',
        'acciones_logradas',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        422,
        1,
        'MC',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (423, 1, 'MC', 'ataque', 'tiros_totales', 0.02, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (424, 1, 'MC', 'ataque', 'tiros_logrados', 0.10, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (425, 1, 'MC', 'ataque', 'tiros_fallados', 0.03, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        426,
        1,
        'MC',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        427,
        1,
        'MC',
        'construccion',
        'pases_largos_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        428,
        1,
        'MC',
        'construccion',
        'pases_largos_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        429,
        1,
        'MC',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        430,
        1,
        'MC',
        'defensa',
        'duelos_ganados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        431,
        1,
        'MC',
        'defensa',
        'duelos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        432,
        1,
        'MC',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        433,
        1,
        'MC',
        'defensa',
        'duelos_aereos_ganados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        434,
        1,
        'MC',
        'defensa',
        'duelos_aereos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        435,
        1,
        'MC',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        436,
        1,
        'MC',
        'ataque',
        'duelos_ofensivos_ganados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        437,
        1,
        'MC',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        438,
        1,
        'MC',
        'defensa',
        'interceptaciones',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (439, 1, 'MC', 'defensa', 'despejes', 0.05, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        440,
        1,
        'MC',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        441,
        1,
        'MC',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.09,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        442,
        1,
        'MC',
        'defensa',
        'balones_recuperados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        443,
        1,
        'MC',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        444,
        1,
        'MC',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (445, 1, 'MC', 'defensa', 'tarjeta_roja', 0.55, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        446,
        1,
        'MC',
        'construccion',
        'carreras_profundidad',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        447,
        1,
        'MC',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        448,
        1,
        'MC',
        'construccion',
        'pases_profundidad_logrados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        449,
        1,
        'MC',
        'construccion',
        'pases_profundidad_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        450,
        1,
        'MC',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        451,
        1,
        'MC',
        'construccion',
        'pases_area_penalti_logrados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        452,
        1,
        'MC',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        453,
        1,
        'MC',
        'construccion',
        'pases_recibidos',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        454,
        1,
        'MC',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        455,
        1,
        'MC',
        'construccion',
        'pases_hacia_delante_logrados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        456,
        1,
        'MC',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        457,
        1,
        'MC',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        458,
        1,
        'MC',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        459,
        1,
        'MC',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (460, 1, 'MCO', 'ataque', 'goles', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (461, 1, 'MCO', 'ataque', 'asistencias', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (462, 1, 'MCO', 'ataque', 'xg', 0.22, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (463, 1, 'MCO', 'ataque', 'xa', 0.31, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        464,
        1,
        'MCO',
        'ataque',
        'second_assists',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        465,
        1,
        'MCO',
        'ataque',
        'asistencias_tiro',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        466,
        1,
        'MCO',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        467,
        1,
        'MCO',
        'construccion',
        'acciones_logradas',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        468,
        1,
        'MCO',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (469, 1, 'MCO', 'ataque', 'tiros_totales', 0.02, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        470,
        1,
        'MCO',
        'ataque',
        'tiros_logrados',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        471,
        1,
        'MCO',
        'ataque',
        'tiros_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        472,
        1,
        'MCO',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        473,
        1,
        'MCO',
        'construccion',
        'pases_largos_logrados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        474,
        1,
        'MCO',
        'construccion',
        'pases_largos_fallados',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        475,
        1,
        'MCO',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        476,
        1,
        'MCO',
        'defensa',
        'duelos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        477,
        1,
        'MCO',
        'defensa',
        'duelos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        478,
        1,
        'MCO',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        479,
        1,
        'MCO',
        'defensa',
        'duelos_aereos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        480,
        1,
        'MCO',
        'defensa',
        'duelos_aereos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        481,
        1,
        'MCO',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        482,
        1,
        'MCO',
        'ataque',
        'duelos_ofensivos_ganados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        483,
        1,
        'MCO',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        484,
        1,
        'MCO',
        'defensa',
        'interceptaciones',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (485, 1, 'MCO', 'defensa', 'despejes', 0.02, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        486,
        1,
        'MCO',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        487,
        1,
        'MCO',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.06,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        488,
        1,
        'MCO',
        'defensa',
        'balones_recuperados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        489,
        1,
        'MCO',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        490,
        1,
        'MCO',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (491, 1, 'MCO', 'defensa', 'tarjeta_roja', 0.55, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        492,
        1,
        'MCO',
        'construccion',
        'carreras_profundidad',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        493,
        1,
        'MCO',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        494,
        1,
        'MCO',
        'construccion',
        'pases_profundidad_logrados',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        495,
        1,
        'MCO',
        'construccion',
        'pases_profundidad_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        496,
        1,
        'MCO',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        497,
        1,
        'MCO',
        'construccion',
        'pases_area_penalti_logrados',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        498,
        1,
        'MCO',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        499,
        1,
        'MCO',
        'construccion',
        'pases_recibidos',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        500,
        1,
        'MCO',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        501,
        1,
        'MCO',
        'construccion',
        'pases_hacia_delante_logrados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        502,
        1,
        'MCO',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        503,
        1,
        'MCO',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        504,
        1,
        'MCO',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        505,
        1,
        'MCO',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (506, 1, 'EXTD', 'ataque', 'goles', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (507, 1, 'EXTI', 'ataque', 'goles', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (508, 1, 'EXTD', 'ataque', 'asistencias', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (509, 1, 'EXTI', 'ataque', 'asistencias', 0.92, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (510, 1, 'EXTD', 'ataque', 'xg', 0.26, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (511, 1, 'EXTI', 'ataque', 'xg', 0.26, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (512, 1, 'EXTD', 'ataque', 'xa', 0.31, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (513, 1, 'EXTI', 'ataque', 'xa', 0.31, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        514,
        1,
        'EXTD',
        'ataque',
        'second_assists',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        515,
        1,
        'EXTI',
        'ataque',
        'second_assists',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        516,
        1,
        'EXTD',
        'ataque',
        'asistencias_tiro',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        517,
        1,
        'EXTI',
        'ataque',
        'asistencias_tiro',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        518,
        1,
        'EXTD',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        519,
        1,
        'EXTI',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        520,
        1,
        'EXTD',
        'construccion',
        'acciones_logradas',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        521,
        1,
        'EXTI',
        'construccion',
        'acciones_logradas',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        522,
        1,
        'EXTD',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        523,
        1,
        'EXTI',
        'construccion',
        'acciones_fallidas',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        524,
        1,
        'EXTD',
        'ataque',
        'tiros_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        525,
        1,
        'EXTI',
        'ataque',
        'tiros_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        526,
        1,
        'EXTD',
        'ataque',
        'tiros_logrados',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        527,
        1,
        'EXTI',
        'ataque',
        'tiros_logrados',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        528,
        1,
        'EXTD',
        'ataque',
        'tiros_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        529,
        1,
        'EXTI',
        'ataque',
        'tiros_fallados',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        530,
        1,
        'EXTD',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        531,
        1,
        'EXTI',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        532,
        1,
        'EXTD',
        'construccion',
        'pases_largos_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        533,
        1,
        'EXTI',
        'construccion',
        'pases_largos_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        534,
        1,
        'EXTD',
        'construccion',
        'pases_largos_fallados',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        535,
        1,
        'EXTI',
        'construccion',
        'pases_largos_fallados',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        536,
        1,
        'EXTD',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        537,
        1,
        'EXTI',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        538,
        1,
        'EXTD',
        'defensa',
        'duelos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        539,
        1,
        'EXTI',
        'defensa',
        'duelos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        540,
        1,
        'EXTD',
        'defensa',
        'duelos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        541,
        1,
        'EXTI',
        'defensa',
        'duelos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        542,
        1,
        'EXTD',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        543,
        1,
        'EXTI',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        544,
        1,
        'EXTD',
        'defensa',
        'duelos_aereos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        545,
        1,
        'EXTI',
        'defensa',
        'duelos_aereos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        546,
        1,
        'EXTD',
        'defensa',
        'duelos_aereos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        547,
        1,
        'EXTI',
        'defensa',
        'duelos_aereos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        548,
        1,
        'EXTD',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        549,
        1,
        'EXTI',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        550,
        1,
        'EXTD',
        'ataque',
        'duelos_ofensivos_ganados',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        551,
        1,
        'EXTI',
        'ataque',
        'duelos_ofensivos_ganados',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        552,
        1,
        'EXTD',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        553,
        1,
        'EXTI',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        554,
        1,
        'EXTD',
        'defensa',
        'interceptaciones',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        555,
        1,
        'EXTI',
        'defensa',
        'interceptaciones',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (556, 1, 'EXTD', 'defensa', 'despejes', 0.02, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (557, 1, 'EXTI', 'defensa', 'despejes', 0.02, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        558,
        1,
        'EXTD',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        559,
        1,
        'EXTI',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        560,
        1,
        'EXTD',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.06,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        561,
        1,
        'EXTI',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.06,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        562,
        1,
        'EXTD',
        'defensa',
        'balones_recuperados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        563,
        1,
        'EXTI',
        'defensa',
        'balones_recuperados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        564,
        1,
        'EXTD',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        565,
        1,
        'EXTI',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        566,
        1,
        'EXTD',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        567,
        1,
        'EXTI',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        568,
        1,
        'EXTD',
        'defensa',
        'tarjeta_roja',
        0.55,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        569,
        1,
        'EXTI',
        'defensa',
        'tarjeta_roja',
        0.55,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        570,
        1,
        'EXTD',
        'construccion',
        'carreras_profundidad',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        571,
        1,
        'EXTI',
        'construccion',
        'carreras_profundidad',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        572,
        1,
        'EXTD',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        573,
        1,
        'EXTI',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        574,
        1,
        'EXTD',
        'construccion',
        'pases_profundidad_logrados',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        575,
        1,
        'EXTI',
        'construccion',
        'pases_profundidad_logrados',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        576,
        1,
        'EXTD',
        'construccion',
        'pases_profundidad_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        577,
        1,
        'EXTI',
        'construccion',
        'pases_profundidad_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        578,
        1,
        'EXTD',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        579,
        1,
        'EXTI',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        580,
        1,
        'EXTD',
        'construccion',
        'pases_area_penalti_logrados',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        581,
        1,
        'EXTI',
        'construccion',
        'pases_area_penalti_logrados',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        582,
        1,
        'EXTD',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        583,
        1,
        'EXTI',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        584,
        1,
        'EXTD',
        'construccion',
        'pases_recibidos',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        585,
        1,
        'EXTI',
        'construccion',
        'pases_recibidos',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        586,
        1,
        'EXTD',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        587,
        1,
        'EXTI',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        588,
        1,
        'EXTD',
        'construccion',
        'pases_hacia_delante_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        589,
        1,
        'EXTI',
        'construccion',
        'pases_hacia_delante_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        590,
        1,
        'EXTD',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        591,
        1,
        'EXTI',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        592,
        1,
        'EXTD',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        593,
        1,
        'EXTI',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        594,
        1,
        'EXTD',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        595,
        1,
        'EXTI',
        'construccion',
        'pases_hacia_atras_logrados',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        596,
        1,
        'EXTD',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        597,
        1,
        'EXTI',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (598, 1, 'DC', 'ataque', 'goles', 1.22, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (599, 1, 'DC', 'ataque', 'asistencias', 0.62, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (600, 1, 'DC', 'ataque', 'xg', 0.31, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (601, 1, 'DC', 'ataque', 'xa', 0.13, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (602, 1, 'DC', 'ataque', 'second_assists', 0.05, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        603,
        1,
        'DC',
        'ataque',
        'asistencias_tiro',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        604,
        1,
        'DC',
        'construccion',
        'acciones_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        605,
        1,
        'DC',
        'construccion',
        'acciones_logradas',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        606,
        1,
        'DC',
        'construccion',
        'acciones_fallidas',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (607, 1, 'DC', 'ataque', 'tiros_totales', 0.03, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (608, 1, 'DC', 'ataque', 'tiros_logrados', 0.19, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (609, 1, 'DC', 'ataque', 'tiros_fallados', 0.04, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        610,
        1,
        'DC',
        'construccion',
        'pases_largos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        611,
        1,
        'DC',
        'construccion',
        'pases_largos_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        612,
        1,
        'DC',
        'construccion',
        'pases_largos_fallados',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        613,
        1,
        'DC',
        'defensa',
        'duelos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        614,
        1,
        'DC',
        'defensa',
        'duelos_ganados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        615,
        1,
        'DC',
        'defensa',
        'duelos_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        616,
        1,
        'DC',
        'defensa',
        'duelos_aereos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        617,
        1,
        'DC',
        'defensa',
        'duelos_aereos_ganados',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        618,
        1,
        'DC',
        'defensa',
        'duelos_aereos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        619,
        1,
        'DC',
        'ataque',
        'duelos_ofensivos_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        620,
        1,
        'DC',
        'ataque',
        'duelos_ofensivos_ganados',
        0.13,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        621,
        1,
        'DC',
        'ataque',
        'duelos_ofensivos_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        622,
        1,
        'DC',
        'defensa',
        'interceptaciones',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (623, 1, 'DC', 'defensa', 'despejes', 0.02, 0);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        624,
        1,
        'DC',
        'defensa',
        'balones_perdidos_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        625,
        1,
        'DC',
        'defensa',
        'balones_perdidos_propia_mitad',
        0.09,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        626,
        1,
        'DC',
        'defensa',
        'balones_recuperados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        627,
        1,
        'DC',
        'defensa',
        'balones_recuperados_mitad_adversaria',
        0.17,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        628,
        1,
        'DC',
        'defensa',
        'tarjeta_amarilla',
        0.14,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (629, 1, 'DC', 'defensa', 'tarjeta_roja', 0.55, 1);

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        630,
        1,
        'DC',
        'construccion',
        'carreras_profundidad',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        631,
        1,
        'DC',
        'construccion',
        'pases_profundidad_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        632,
        1,
        'DC',
        'construccion',
        'pases_profundidad_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        633,
        1,
        'DC',
        'construccion',
        'pases_profundidad_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        634,
        1,
        'DC',
        'construccion',
        'pases_area_penalti_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        635,
        1,
        'DC',
        'construccion',
        'pases_area_penalti_logrados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        636,
        1,
        'DC',
        'construccion',
        'pases_area_penalti_perdidos',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        637,
        1,
        'DC',
        'construccion',
        'pases_recibidos',
        0.02,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        638,
        1,
        'DC',
        'construccion',
        'pases_hacia_delante_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        639,
        1,
        'DC',
        'construccion',
        'pases_hacia_delante_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        640,
        1,
        'DC',
        'construccion',
        'pases_hacia_delante_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        641,
        1,
        'DC',
        'construccion',
        'pases_hacia_atras_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        642,
        1,
        'DC',
        'construccion',
        'pases_hacia_atras_logrados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        643,
        1,
        'DC',
        'construccion',
        'pases_hacia_atras_perdidos',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        644,
        1,
        'POR',
        'construccion',
        'pases_totales',
        0.01,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        645,
        1,
        'POR',
        'construccion',
        'pases_completados',
        0.03,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        646,
        1,
        'DFC',
        'construccion',
        'pases_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        647,
        1,
        'DFC',
        'construccion',
        'pases_completados',
        0.06,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        648,
        1,
        'LI',
        'construccion',
        'pases_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        649,
        1,
        'LI',
        'construccion',
        'pases_completados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        650,
        1,
        'LD',
        'construccion',
        'pases_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        651,
        1,
        'LD',
        'construccion',
        'pases_completados',
        0.07,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        652,
        1,
        'MCD',
        'construccion',
        'pases_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        653,
        1,
        'MCD',
        'construccion',
        'pases_completados',
        0.10,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        654,
        1,
        'MC',
        'construccion',
        'pases_totales',
        0.03,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        655,
        1,
        'MC',
        'construccion',
        'pases_completados',
        0.12,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        656,
        1,
        'MCO',
        'construccion',
        'pases_totales',
        0.02,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        657,
        1,
        'MCO',
        'construccion',
        'pases_completados',
        0.08,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        658,
        1,
        'EXTI',
        'construccion',
        'pases_totales',
        0.01,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        659,
        1,
        'EXTI',
        'construccion',
        'pases_completados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        660,
        1,
        'EXTD',
        'construccion',
        'pases_totales',
        0.01,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        661,
        1,
        'EXTD',
        'construccion',
        'pases_completados',
        0.05,
        0
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        662,
        1,
        'DC',
        'construccion',
        'pases_totales',
        0.01,
        1
    );

INSERT INTO
    pesos_metrica_posicion (
        `id_peso_metrica`,
        `id_configuracion`,
        `codigo_posicion`,
        `bloque`,
        `clave_metrica`,
        `porcentaje`,
        `penaliza`
    )
VALUES
    (
        663,
        1,
        'DC',
        'construccion',
        'pases_completados',
        0.05,
        0
    );