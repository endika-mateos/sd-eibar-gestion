<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido datos y que existe el ID
if (!$data || !isset($data['id_jugador'])) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos o el ID del jugador']);
    exit;
}

$id_jugador = $data['id_jugador'];
$nombre = $data['nombre'] ?? '';
$apellidos = $data['apellidos'] ?? '';
$alias = $data['alias'] ?? '';
$posicion = $data['posicion_habitual'] ?? '';
$estado = $data['estado'] ?? 'activo';

// Nombre y apellidos obligatorios
if (empty($nombre) || empty($apellidos)) {
    echo json_encode(['ok' => false, 'error' => 'Nombre y apellidos son obligatorios']);
    exit;
}

$sql = "UPDATE jugadores SET nombre = ?, apellidos = ?, alias = ?, posicion_habitual = ?, estado = ? WHERE id_jugador = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("sssssi", $nombre, $apellidos, $alias, $posicion, $estado, $id_jugador);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Jugador actualizado correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
