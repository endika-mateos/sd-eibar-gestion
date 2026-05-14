<?php

session_start();
require 'conexion.php';

$data     = json_decode(file_get_contents('php://input'), true);
$usuario  = $data['usuario'] ?? '';
$password = $data['password'] ?? '';

$sql  = "SELECT id_usuario, contrasena_hash, rol FROM usuarios WHERE nombre_usuario = ?";
$stmt = $conexion->prepare($sql);
$stmt->bind_param("s", $usuario);
$stmt->execute();
$resultado = $stmt->get_result();
$fila      = $resultado->fetch_assoc();
$stmt->close();

if (!$fila) {
    echo json_encode(['ok' => false, 'error' => 'Usuario no encontrado']);
    exit;
}

$passwordValida = ($password === $fila['contrasena_hash']) || password_verify($password, $fila['contrasena_hash']);

if (!$passwordValida) {
    echo json_encode(['ok' => false, 'error' => 'Contraseña incorrecta']);
    exit;
}

$_SESSION['id_usuario'] = $fila['id_usuario'];
$_SESSION['rol']        = $fila['rol'];

echo json_encode(['ok' => true, 'rol' => $fila['rol']]);

?>