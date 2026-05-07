<?php

require '../conexion.php';

$id_partido = isset($_GET['id_partido']) ? (int) $_GET['id_partido'] : 0;

// El ID es obligatorio
if (!$id_partido) {
    echo json_encode(['ok' => false, 'error' => 'ID de partido requerido']);
    exit;
}

// ===== INFO GENERAL DEL PARTIDO =====

$sql = "SELECT p.*, t.nombre AS nombre_temporada
            FROM partidos p
            LEFT JOIN temporadas t ON t.id_temporada = p.id_temporada
            WHERE p.id_partido = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("i", $id_partido);
$stmt->execute();
$partido = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$partido) {
    echo json_encode(['ok' => false, 'error' => 'Partido no encontrado']);
    exit;
}

// ===== PUNTUACIONES DEL PARTIDO (ordenadas de mayor a menor nota) =====
// Incluimos id_estadistica para poder usar el simulador de posicion con Python

$sql = "SELECT pu.id_puntuacion, pu.posicion_evaluada,
                pu.puntuacion_ataque, pu.puntuacion_construccion,
                pu.puntuacion_defensa, pu.factor_minutos, pu.puntuacion_final,
                pu.explicacion_positiva, pu.explicacion_negativa,
                j.id_jugador, j.nombre, j.apellidos, j.posicion_habitual,
                e.id_estadistica
            FROM puntuaciones pu
            INNER JOIN jugadores j ON j.id_jugador = pu.id_jugador
            LEFT JOIN estadisticas_jugador_partido e ON e.id_jugador = pu.id_jugador AND e.id_partido = pu.id_partido
            WHERE pu.id_partido = ?
            ORDER BY pu.puntuacion_final DESC";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("i", $id_partido);
$stmt->execute();
$res = $stmt->get_result();

$puntuaciones = [];
while ($fila = $res->fetch_assoc()) {
    $fila['puntuacion_ataque'] = (float) $fila['puntuacion_ataque'];
    $fila['puntuacion_construccion'] = (float) $fila['puntuacion_construccion'];
    $fila['puntuacion_defensa'] = (float) $fila['puntuacion_defensa'];
    $fila['puntuacion_final'] = (float) $fila['puntuacion_final'];
    $puntuaciones[] = $fila;
}

$stmt->close();

echo json_encode([
    'ok' => true,
    'partido' => $partido,
    'puntuaciones' => $puntuaciones
], JSON_UNESCAPED_UNICODE);