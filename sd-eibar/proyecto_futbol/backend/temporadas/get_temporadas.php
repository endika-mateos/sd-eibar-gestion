<?php

require '../conexion.php';

$temporadas = [];

// Devolvemos todas las temporadas ordenadas por fecha de inicio descendente
$sql = "SELECT id_temporada, nombre, fecha_inicio, fecha_fin, activa
            FROM temporadas
            ORDER BY fecha_inicio DESC";
$stmt = $conexion->prepare($sql);
$stmt->execute();
$resultado = $stmt->get_result();

while ($fila = $resultado->fetch_assoc()) {
    $temporadas[] = $fila;
}

$stmt->close();

echo json_encode(['ok' => true, 'data' => $temporadas]);

?>