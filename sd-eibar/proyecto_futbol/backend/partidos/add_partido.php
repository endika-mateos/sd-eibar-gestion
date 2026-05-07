<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido datos
if (!$data) {
    echo json_encode(['ok' => false, 'error' => 'No se han recibido los datos']);
    exit;
}

$id_temporada = $data['id_temporada'] ?? '';
$rival = $data['rival'] ?? '';
$fecha = $data['fecha'] ?? '';
$competicion = $data['competicion'] ?? '';
$local_visitante = $data['local_visitante'] ?? 'local';
$goles_favor = $data['goles_favor'] ?? 0;
$goles_contra = $data['goles_contra'] ?? 0;

// Temporada rival y fecha son obligatorios
if (empty($id_temporada) || empty($rival) || empty($fecha)) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos obligatorios']);
    exit;
}

$sql = "INSERT INTO partidos (id_temporada, rival, fecha, competicion, local_visitante, goles_favor, goles_contra) VALUES (?, ?, ?, ?, ?, ?, ?)";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("issssii", $id_temporada, $rival, $fecha, $competicion, $local_visitante, $goles_favor, $goles_contra);

if ($stmt->execute()) {
    echo json_encode(['ok' => true, 'mensaje' => 'Partido creado correctamente']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
