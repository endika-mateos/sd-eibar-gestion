<?php

require '../conexion.php';

$id_jugador = $_GET['id_jugador'] ?? '';

// El ID es obligatorio
if (empty($id_jugador)) {
    echo json_encode(['ok' => false, 'error' => 'Falta el ID del jugador']);
    exit;
}

// Devuelve todas las estadisticas del jugador (para el grafico radar)
$sql = "SELECT * FROM estadisticas_jugador_partido WHERE id_jugador = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("i", $id_jugador);
$stmt->execute();
$resultado = $stmt->get_result();

$estadisticas = [];
while ($fila = $resultado->fetch_assoc()) {
    $estadisticas[] = $fila;
}

$stmt->close();

echo json_encode(['ok' => true, 'data' => $estadisticas]);

?>