<?php

// En produccion silenciamos los errores para que no aparezcan en las
// respuestas JSON. Si necesitas depurar comenta estas dos lineas.
error_reporting(0);
ini_set('display_errors', 0);

header('Content-Type: application/json');

// ===== CONFIGURACION DE LA BASE DE DATOS =====
// XAMPP por defecto: usuario root sin contrasena
define('SERVIDOR', 'localhost');
define('BBDD', 'sistema_futbol');
define('USUARIO', 'root');
define('CLAVE', '');

// Conexion a la base de datos
$conexion = new mysqli(SERVIDOR, USUARIO, CLAVE, BBDD);
$conexion->set_charset('utf8mb4');

if ($conexion->connect_error) {
    echo json_encode(['ok' => false, 'error' => 'Error de conexión a la base de datos']);
    exit;
}

?>
