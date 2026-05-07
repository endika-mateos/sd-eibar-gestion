<?php

session_start();
header('Content-Type: application/json');

if (isset($_SESSION['rol'])) {
    echo json_encode(['ok' => true, 'rol' => $_SESSION['rol']]);
} else {
    echo json_encode(['ok' => false, 'error' => 'No hay sesión activa']);
}

?>