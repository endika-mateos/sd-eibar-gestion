<?php

set_time_limit(120);
ini_set('max_execution_time', 120);

require '../conexion.php';

$data = json_decode(file_get_contents('php://input'), true);

// Comprobamos que tenemos los dos datos necesarios
if (!$data || !isset($data['id_jugador']) || !isset($data['nombre_excel'])) {
    echo json_encode(['ok' => false, 'error' => 'Faltan datos: id_jugador y nombre_excel son obligatorios']);
    exit;
}

$id_jugador = (int) $data['id_jugador'];
$nombre_excel = $data['nombre_excel'];

// Verificamos que el jugador existe en la BD
$stmt = $conexion->prepare("SELECT nombre, apellidos FROM jugadores WHERE id_jugador = ?");
$stmt->bind_param("i", $id_jugador);
$stmt->execute();
$jugador = $stmt->get_result()->fetch_assoc();
$stmt->close();

if (!$jugador) {
    echo json_encode(['ok' => false, 'error' => 'Jugador no encontrado en la base de datos']);
    exit;
}

// Llamamos a la API de Python
$url = 'http://127.0.0.1:8030/stats/score';
$payload = json_encode([
    'id'         => $id_jugador,
    'ruta_excel' => $nombre_excel
]);

$opciones = [
    'http' => [
        'method' => 'POST',
        'header' => "Content-Type: application/json\r\n",
        'content' => $payload,
        'timeout' => 60
    ]
];

$contexto = stream_context_create($opciones);
$respuesta = @file_get_contents($url, false, $contexto);

// Si Python no responde
if ($respuesta === false) {
    echo json_encode(['ok' => false, 'error' => 'No se pudo conectar con la API de Python. ¿Está arrancada en el puerto 8030?']);
    exit;
}

$resultado = json_decode($respuesta, true);

// Devolvemos el resultado de Python al frontend
if (isset($resultado['estado']) && $resultado['estado'] === 'Éxito') {
    echo json_encode([
        'ok' => true,
        'jugador' => $resultado['jugador'],
        'partidos_procesados' => $resultado['total_procesados'],
        'detalles' => $resultado['resumen']
    ]);
} else {
    echo json_encode([
        'ok' => false,
        'error' => $resultado['mensaje'] ?? $resultado['detail'] ?? 'Error desconocido en la API',
        'detalles' => $resultado
    ]);
}

?>