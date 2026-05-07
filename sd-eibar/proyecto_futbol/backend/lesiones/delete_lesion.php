<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido el ID
if (!$data || !isset($data['id_lesion'])) {
    echo json_encode(['ok' => false, 'error' => 'No se ha recibido el ID de la lesión']);
    exit;
}

$id_lesion = $data['id_lesion'];

$sql = "DELETE FROM lesiones WHERE id_lesion = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("i", $id_lesion);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Lesión eliminada correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
