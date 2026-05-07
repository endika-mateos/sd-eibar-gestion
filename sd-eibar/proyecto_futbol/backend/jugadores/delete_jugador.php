<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido el ID
if (!$data || !isset($data['id_jugador'])) {
    echo json_encode(['ok' => false, 'error' => 'No se ha recibido el ID del jugador']);
    exit;
}

$id_jugador = $data['id_jugador'];

$sql = "DELETE FROM jugadores WHERE id_jugador = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("i", $id_jugador);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Jugador eliminado correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
