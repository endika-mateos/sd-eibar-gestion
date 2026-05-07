<?php

require '../conexion.php';

$lesiones = [];

// Si llega un id_jugador filtramos por ese jugador
if (isset($_GET['id_jugador'])) {
    $id_jugador = (int) $_GET['id_jugador'];

    $sql = "SELECT lesiones.*, jugadores.nombre, jugadores.apellidos
                FROM lesiones
                JOIN jugadores ON lesiones.id_jugador = jugadores.id_jugador
                WHERE lesiones.id_jugador = ?
                ORDER BY lesiones.fecha_inicio DESC";
    $stmt = $conexion->prepare($sql);
    $stmt->bind_param("i", $id_jugador);

} else {
    // Sin filtro devolvemos todas las lesiones
    $sql = "SELECT lesiones.*, jugadores.nombre, jugadores.apellidos
                FROM lesiones
                JOIN jugadores ON lesiones.id_jugador = jugadores.id_jugador
                ORDER BY lesiones.fecha_inicio DESC";
    $stmt = $conexion->prepare($sql);
}

$stmt->execute();
$resultado = $stmt->get_result();

while ($fila = $resultado->fetch_assoc()) {
    $lesiones[] = $fila;
}

$stmt->close();

echo json_encode(['ok' => true, 'data' => $lesiones]);

?>