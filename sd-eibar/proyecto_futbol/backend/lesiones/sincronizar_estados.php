<?php

require '../conexion.php';

// ===== 1. MARCAR COMO LESIONADO =====
// Jugadores con una lesion activa hoy que siguen en estado 'activo'

$sqlLesionados = "UPDATE jugadores SET estado = 'lesionado' WHERE estado = 'activo' AND id_jugador IN (SELECT DISTINCT id_jugador FROM lesiones
                        WHERE fecha_inicio <= CURDATE() AND IFNULL(fecha_fin, fecha_prevista_retorno) >= CURDATE())";

$conexion->query($sqlLesionados);
$actualizadosLesionados = $conexion->affected_rows;

// ===== 2. MARCAR COMO ACTIVO =====
// Jugadores marcados como lesionados cuya lesion ya termino y no tienen otra activa

$sqlRecuperados = "UPDATE jugadores SET estado = 'activo' WHERE estado = 'lesionado' AND id_jugador NOT IN (SELECT DISTINCT id_jugador FROM lesiones
                        WHERE fecha_inicio <= CURDATE() AND IFNULL(fecha_fin, fecha_prevista_retorno) >= CURDATE())";

$conexion->query($sqlRecuperados);
$actualizadosRecuperados = $conexion->affected_rows;

echo json_encode([
    'ok' => true,
    'lesionados' => $actualizadosLesionados,
    'recuperados' => $actualizadosRecuperados
], JSON_UNESCAPED_UNICODE);

?>