<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido datos
if (!$data) {
    echo json_encode(['ok' => false, 'error' => 'No se han recibido los datos']);
    exit;
}

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

$sql = "INSERT INTO jugadores (nombre, apellidos, alias, posicion_habitual, estado) VALUES (?, ?, ?, ?, ?)";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("sssss", $nombre, $apellidos, $alias, $posicion, $estado);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Jugador creado correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
