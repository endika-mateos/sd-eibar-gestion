<?php

set_time_limit(60);

$id_estadistica = $_GET['id_estadistica'] ?? 0;
$nueva_posicion = $_GET['nueva_posicion'] ?? '';

// Comprobamos que tenemos los dos parametros
if (!$id_estadistica || !$nueva_posicion) {
    echo json_encode(['ok' => false, 'error' => 'Faltan parámetros: id_estadistica y nueva_posicion son obligatorios']);
    exit;
}

// Llamamos al endpoint de Python
$url      = "http://127.0.0.1:8030/stats/compare-position?id_estadistica={$id_estadistica}&nueva_posicion={$nueva_posicion}";
$opciones = ['http' => ['method' => 'GET', 'timeout' => 30]];
$contexto  = stream_context_create($opciones);
$respuesta = @file_get_contents($url, false, $contexto);

if ($respuesta === false) {
    echo json_encode(['ok' => false, 'error' => 'No se pudo conectar con la API de Python. ¿Está arrancada en el puerto 8030?']);
    exit;
}

$resultado = json_decode($respuesta, true);

if (isset($resultado['nota'])) {
    echo json_encode(['ok' => true, 'nota' => $resultado['nota']]);
} else {
    echo json_encode(['ok' => false, 'error' => $resultado['detail'] ?? 'Error desconocido en la API']);
}

?>