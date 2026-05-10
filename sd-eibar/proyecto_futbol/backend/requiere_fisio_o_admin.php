<?php

// ============================================================
// GUARD DE SESION: admin o fisio
// ============================================================
// Se incluye en los endpoints de lesiones que requieren
// permisos de escritura. Admin puede hacer todo; fisio puede
// crear, editar y cerrar lesiones, pero no borrar jugadores
// ni gestionar partidos.
// ============================================================

session_start();
header('Content-Type: application/json');

$rol = $_SESSION['rol'] ?? '';

if (!in_array($rol, ['admin', 'fisio'])) {
    http_response_code(403);
    echo json_encode(['ok' => false, 'error' => 'No tienes permisos para realizar esta acción.']);
    exit;
}

?>