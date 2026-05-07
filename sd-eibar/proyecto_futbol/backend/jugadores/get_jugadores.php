<?php

require '../conexion.php';

$jugadores = [];

// Si hay busqueda filtramos por nombre, apellidos o alias
if (isset($_GET['query'])) {
    $query = '%' . $_GET['query'] . '%';

    $sql = "SELECT j.id_jugador, j.nombre, j.apellidos, j.alias,
                    j.posicion_habitual, j.estado,
                    d.dorsal
                FROM jugadores j
                LEFT JOIN dorsales_jugador d ON d.id_jugador = j.id_jugador
                LEFT JOIN temporadas t ON t.id_temporada = d.id_temporada AND t.activa = 1
                WHERE j.nombre LIKE ? OR j.apellidos LIKE ? OR j.alias LIKE ?";
    $stmt = $conexion->prepare($sql);
    $stmt->bind_param("sss", $query, $query, $query);

} else {
    // Sin busqueda devolvemos todos ordenados por dorsal
    $sql = "SELECT j.id_jugador, j.nombre, j.apellidos, j.alias,
                    j.posicion_habitual, j.estado,
                    d.dorsal
                FROM jugadores j
                LEFT JOIN dorsales_jugador d ON d.id_jugador = j.id_jugador
                LEFT JOIN temporadas t ON t.id_temporada = d.id_temporada AND t.activa = 1
                ORDER BY d.dorsal ASC";
    $stmt = $conexion->prepare($sql);
}

$stmt->execute();
$resultado = $stmt->get_result();

while ($fila = $resultado->fetch_assoc()) {
    $jugadores[] = $fila;
}

$stmt->close();

echo json_encode(['ok' => true, 'data' => $jugadores]);

?>