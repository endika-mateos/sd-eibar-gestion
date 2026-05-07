<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido datos y que existe el ID
if (!$data || !isset($data['id_partido'])) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos o el ID del partido']);
    exit;
}

$id_partido = $data['id_partido'];
$id_temporada = $data['id_temporada'] ?? '';
$rival = $data['rival'] ?? '';
$fecha = $data['fecha'] ?? '';
$competicion = $data['competicion'] ?? '';
$local_visitante = $data['local_visitante'] ?? 'local';
$goles_favor = $data['goles_favor'] ?? 0;
$goles_contra = $data['goles_contra'] ?? 0;

// Rival fecha y temporada son obligatorios
if (empty($rival) || empty($fecha) || empty($id_temporada)) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos obligatorios']);
    exit;
}

$sql = "UPDATE partidos SET rival = ?, fecha = ?, competicion = ?, local_visitante = ?, goles_favor = ?, goles_contra = ?, id_temporada = ? WHERE id_partido = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("ssssiiii", $rival, $fecha, $competicion, $local_visitante, $goles_favor, $goles_contra, $id_temporada, $id_partido);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Partido actualizado correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
