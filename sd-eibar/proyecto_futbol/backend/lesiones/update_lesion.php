<?php

require '../requiere_admin.php';
require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que hemos recibido datos y que existe el ID
if (!$data || !isset($data['id_lesion'])) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos o el ID de la lesión']);
    exit;
}

$id_lesion = $data['id_lesion'];
$fecha_inicio = $data['fecha_inicio'] ?? '';
$fecha_fin = $data['fecha_fin'] ?? null;
$tipo_lesion = $data['tipo_lesion'] ?? '';
$gravedad = $data['gravedad'] ?? 'leve';
$fecha_prevista_retorno = $data['fecha_prevista_retorno'] ?? null;
$observaciones = $data['observaciones'] ?? '';

// Fecha de inicio y tipo de lesion son obligatorios
if (empty($fecha_inicio) || empty($tipo_lesion)) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos obligatorios']);
    exit;
}

$sql = "UPDATE lesiones SET fecha_inicio = ?, fecha_fin = ?, tipo_lesion = ?, gravedad = ?, fecha_prevista_retorno = ?, observaciones = ? WHERE id_lesion = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("ssssssi", $fecha_inicio, $fecha_fin, $tipo_lesion, $gravedad, $fecha_prevista_retorno, $observaciones, $id_lesion);

if ($stmt->execute()) {
    // Al editar las fechas recalculamos el estado del jugador afectado
    $sqlEstado = "UPDATE jugadores SET estado = IF(EXISTS(SELECT 1 FROM lesiones 
                    WHERE id_jugador = jugadores.id_jugador AND fecha_inicio <= CURDATE() AND IFNULL(fecha_fin, fecha_prevista_retorno) >= CURDATE()),'lesionado', 'activo')
                        WHERE id_jugador = (SELECT id_jugador FROM lesiones WHERE id_lesion = ?)";
    $stmtEstado = $conexion->prepare($sqlEstado);
    $stmtEstado->bind_param("i", $id_lesion);
    $stmtEstado->execute();
    $stmtEstado->close();

    echo json_encode(['ok' => true, 'mensaje' => 'Lesión actualizada y estado del jugador recalculado']);
} else {
    echo json_encode(['ok' => false, 'error' => $stmt->error]);
}

$stmt->close();

?>
