<?php

require '../requiere_fisio_o_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido datos
if (!$data) {
    echo json_encode(['ok' => false, 'error' => 'No se han recibido los datos']);
    exit;
}

$id_jugador = $data['id_jugador'] ?? '';
$fecha_inicio = $data['fecha_inicio'] ?? '';
$fecha_fin = $data['fecha_fin'] ?? null;
$tipo_lesion = $data['tipo_lesion'] ?? '';
$gravedad = $data['gravedad'] ?? 'leve';
$fecha_prevista_retorno = $data['fecha_prevista_retorno'] ?? null;
$observaciones = $data['observaciones'] ?? '';

// Jugador fecha de inicio y tipo de lesion son obligatorios
if (empty($id_jugador) || empty($fecha_inicio) || empty($tipo_lesion)) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos obligatorios']);
    exit;
}

$sql = "INSERT INTO lesiones (id_jugador, fecha_inicio, fecha_fin, tipo_lesion, gravedad, fecha_prevista_retorno, observaciones) VALUES (?, ?, ?, ?, ?, ?, ?)";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("issssss", $id_jugador, $fecha_inicio, $fecha_fin, $tipo_lesion, $gravedad, $fecha_prevista_retorno, $observaciones);

if ($stmt->execute()) {
    // Al registrar la lesion se marca de por si como lesionado
    $sqlEstado = "UPDATE jugadores SET estado = 'lesionado' WHERE id_jugador = ?";
    $stmtEstado = $conexion->prepare($sqlEstado);
    $stmtEstado->bind_param("i", $id_jugador);
    $stmtEstado->execute();
    $stmtEstado->close();

    echo json_encode(['ok' => true, 'mensaje' => 'Lesión registrada y estado del jugador actualizado']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
