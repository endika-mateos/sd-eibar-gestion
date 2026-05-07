<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido datos y que existe el ID
if (!$data || !isset($data['id_temporada'])) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos o el ID de la temporada']);
    exit;
}

$id_temporada = $data['id_temporada'];
$nombre = $data['nombre'] ?? '';
$fecha_inicio = $data['fecha_inicio'] ?? '';
$fecha_fin = $data['fecha_fin'] ?? '';
$activa = !empty($data['activa']) ? 1 : 0;

// Nombre y fecha de inicio son obligatorios
if (empty($nombre) || empty($fecha_inicio)) {
    echo json_encode(['ok' => false, 'error' => 'Nombre y fecha de inicio son obligatorios']);
    exit;
}

// Si esta temporada se marca como activa, desactivamos el resto.
// Asi garantizamos que solo haya una temporada activa a la vez.
if ($activa === 1) {
    $stmtDes = $conexion->prepare("UPDATE temporadas SET activa = 0 WHERE id_temporada != ?");
    $stmtDes->bind_param("i", $id_temporada);
    $stmtDes->execute();
    $stmtDes->close();
}

$sql = "UPDATE temporadas SET nombre = ?, fecha_inicio = ?, fecha_fin = ?, activa = ? WHERE id_temporada = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("sssii", $nombre, $fecha_inicio, $fecha_fin, $activa, $id_temporada);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Temporada actualizada correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
