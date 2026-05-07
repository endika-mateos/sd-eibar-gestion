<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido el ID
if (!$data || !isset($data['id_temporada'])) {
    echo json_encode(['ok' => false, 'error' => 'No se ha recibido el ID de la temporada']);
    exit;
}

$id_temporada = $data['id_temporada'];

// No se puede borrar una temporada si tiene partidos asociados
$sqlCheck = "SELECT COUNT(*) AS total FROM partidos WHERE id_temporada = ?";
$stmtCheck = $conexion->prepare($sqlCheck);
$stmtCheck->bind_param("i", $id_temporada);
$stmtCheck->execute();
$fila = $stmtCheck->get_result()->fetch_assoc();
$stmtCheck->close();

if ($fila['total'] > 0) {
    echo json_encode(['ok' => false, 'error' => 'No se puede eliminar la temporada porque tiene partidos asociados']);
    exit;
}

$sql = "DELETE FROM temporadas WHERE id_temporada = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("i", $id_temporada);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Temporada eliminada correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
