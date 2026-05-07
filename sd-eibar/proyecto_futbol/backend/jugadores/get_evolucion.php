<?php

require '../conexion.php';

$id_jugador = isset($_GET['id_jugador']) ? (int) $_GET['id_jugador'] : 0;

// El ID es obligatorio
if (!$id_jugador) {
    echo json_encode(['ok' => false, 'error' => 'ID de jugador requerido']);
    exit;
}

// Devuelve una fila por partido con las puntuaciones (para el grafico de evolucion)
$sql = "SELECT pa.fecha, pa.rival, pa.local_visitante,
               pu.puntuacion_ataque, pu.puntuacion_construccion,
               pu.puntuacion_defensa, pu.puntuacion_final
        FROM puntuaciones pu
        INNER JOIN partidos pa ON pa.id_partido = pu.id_partido
        WHERE pu.id_jugador = ?
        ORDER BY pa.fecha ASC";

$stmt = $conexion->prepare($sql);
$stmt->bind_param("i", $id_jugador);
$stmt->execute();
$res = $stmt->get_result();

$datos = [];
while ($fila = $res->fetch_assoc()) {
    $datos[] = [
        'fecha' => date('d/m/Y', strtotime($fila['fecha'])),
        'rival' => $fila['rival'],
        'localidad' => $fila['local_visitante'],
        'puntuacion_ataque' => (float) $fila['puntuacion_ataque'],
        'puntuacion_construccion' => (float) $fila['puntuacion_construccion'],
        'puntuacion_defensa' => (float) $fila['puntuacion_defensa'],
        'puntuacion_final' => (float) $fila['puntuacion_final']
    ];
}

$stmt->close();

echo json_encode(['ok' => true, 'data' => $datos], JSON_UNESCAPED_UNICODE);

?>