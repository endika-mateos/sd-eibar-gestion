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
$fecha_inicio = $data['fecha_inicio'] ?? '';
$fecha_fin = $data['fecha_fin'] ?? '';
$activa = !empty($data['activa']) ? 1 : 0;

// Nombre y fecha de inicio son obligatorios
if (empty($nombre) || empty($fecha_inicio)) {
    echo json_encode(['ok' => false, 'error' => 'Nombre y fecha de inicio son obligatorios']);
    exit;
}

// Solo puede haber UNA temporada activa al mismo tiempo.
// Si esta nueva se marca como activa, desactivamos el resto antes.
if ($activa === 1) {
    $conexion->query("UPDATE temporadas SET activa = 0 WHERE activa = 1");
}

$sql = "INSERT INTO temporadas (nombre, fecha_inicio, fecha_fin, activa) VALUES (?, ?, ?, ?)";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("sssi", $nombre, $fecha_inicio, $fecha_fin, $activa);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Temporada creada correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
