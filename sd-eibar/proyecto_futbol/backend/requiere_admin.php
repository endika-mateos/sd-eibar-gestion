<?php

// ============================================================
// GUARD DE SESION: solo admin
// ============================================================
// Este archivo se incluye al principio de los endpoints que
// solo deben poder ser ejecutados por usuarios con rol 'admin'.
// Si la sesion no existe o el rol no es admin devuelve 403 y
// detiene la ejecucion antes de tocar la base de datos.
// ============================================================

session_start();
header('Content-Type: application/json');

if (!isset($_SESSION['rol']) || $_SESSION['rol'] !== 'admin') {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'No tienes permisos para realizar esta acción.']);
    exit;
}

?>
