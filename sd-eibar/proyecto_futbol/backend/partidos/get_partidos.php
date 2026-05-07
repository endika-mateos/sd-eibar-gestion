<?php

require '../conexion.php';

$partidos = [];

// Filtramos segun los parametros que lleguen por GET
if (isset($_GET['rival'])) {
    $rival = '%' . $_GET['rival'] . '%';

    $sql = "SELECT id_partido, id_temporada, rival, fecha, competicion, local_visitante, goles_favor, goles_contra
                FROM partidos
                WHERE rival LIKE ?
                ORDER BY fecha DESC";
    $stmt = $conexion->prepare($sql);
    $stmt->bind_param("s", $rival);

} elseif (isset($_GET['id_temporada'])) {
    $id_temporada = (int) $_GET['id_temporada'];

    $sql = "SELECT id_partido, id_temporada, rival, fecha, competicion, local_visitante, goles_favor, goles_contra
                FROM partidos
                WHERE id_temporada = ?
                ORDER BY fecha DESC";
    $stmt = $conexion->prepare($sql);
    $stmt->bind_param("i", $id_temporada);

} else {
    // Sin filtros devuelve todos
    $sql = "SELECT id_partido, id_temporada, rival, fecha, competicion, local_visitante, goles_favor, goles_contra
                FROM partidos
                ORDER BY fecha DESC";
    $stmt = $conexion->prepare($sql);
}

$stmt->execute();
$resultado = $stmt->get_result();

while ($fila = $resultado->fetch_assoc()) {
    $partidos[] = $fila;
}

$stmt->close();

echo json_encode(['ok' => true, 'data' => $partidos]);

?>