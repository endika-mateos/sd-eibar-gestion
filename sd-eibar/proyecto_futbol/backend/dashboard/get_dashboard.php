<?php

require '../conexion.php';

$response = [];

// ===== 1. ULTIMO PARTIDO =====
$sql = "SELECT id_partido, rival, fecha, competicion, local_visitante, goles_favor, goles_contra
        FROM partidos
        ORDER BY fecha DESC
        LIMIT 1";

$res    = $conexion->query($sql);
$partido = $res->fetch_assoc();

if ($partido) {
    $esLocal  = $partido['local_visitante'] === 'local';
    $marcador = $partido['goles_favor'] . ' - ' . $partido['goles_contra'];
    $localidad = $esLocal ? 'vs' : '@';

    if ($partido['goles_favor'] > $partido['goles_contra'])       $resultado = 'Victoria';
    elseif ($partido['goles_favor'] < $partido['goles_contra'])   $resultado = 'Derrota';
    else                                                           $resultado = 'Empate';

    $response['ultimo_partido'] = [
        'rival'       => $partido['rival'],
        'fecha'       => date('d/m/Y', strtotime($partido['fecha'])),
        'competicion' => $partido['competicion'],
        'marcador'    => $marcador,
        'resultado'   => $resultado,
        'localidad'   => $localidad
    ];
} else {
    $response['ultimo_partido'] = null;
}

// ===== 2. TOP 3 JUGADORES POR NOTA MEDIA =====
$sql = "SELECT j.id_jugador, j.nombre, j.apellidos, j.posicion_habitual,
            ROUND(AVG(p.puntuacion_final), 2) AS nota_media,
            COUNT(p.id_puntuacion) AS partidos_puntuados
        FROM jugadores j
        INNER JOIN puntuaciones p ON p.id_jugador = j.id_jugador
        GROUP BY j.id_jugador
        ORDER BY nota_media DESC
        LIMIT 3";

$res = $conexion->query($sql);
$top = [];
while ($fila = $res->fetch_assoc()) {
    $top[] = $fila;
}
$response['top_jugadores'] = $top;

// ===== 3. LESIONES ACTIVAS HOY =====
$sql = "SELECT j.id_jugador, j.nombre, j.apellidos, j.posicion_habitual,
            l.tipo_lesion, l.gravedad, l.observaciones, l.fecha_inicio,
            IFNULL(l.fecha_fin, l.fecha_prevista_retorno) AS fecha_alta,
            DATEDIFF(IFNULL(l.fecha_fin, l.fecha_prevista_retorno), CURDATE()) AS dias_restantes
        FROM lesiones l
        INNER JOIN jugadores j ON j.id_jugador = l.id_jugador
        WHERE CURDATE() BETWEEN l.fecha_inicio AND IFNULL(l.fecha_fin, l.fecha_prevista_retorno)
        ORDER BY dias_restantes ASC";

$res     = $conexion->query($sql);
$lesiones = [];
while ($fila = $res->fetch_assoc()) {
    $fila['fecha_inicio']    = date('d/m/Y', strtotime($fila['fecha_inicio']));
    $fila['fecha_alta']      = $fila['fecha_alta'] ? date('d/m/Y', strtotime($fila['fecha_alta'])) : 'Sin fecha';
    $fila['dias_restantes']  = (int) $fila['dias_restantes'];
    $lesiones[] = $fila;
}
$response['lesiones_activas'] = $lesiones;

// ===== 4. AVISOS DEL SISTEMA =====

// 4a. Partidos con estadísticas importadas pero sin puntuaciones calculadas
$sql = "SELECT p.id_partido, p.rival, p.fecha
        FROM partidos p
        INNER JOIN estadisticas_jugador_partido e ON e.id_partido = p.id_partido
        LEFT  JOIN puntuaciones pu ON pu.id_partido = p.id_partido
        WHERE pu.id_puntuacion IS NULL
        GROUP BY p.id_partido
        ORDER BY p.fecha DESC";

$res = $conexion->query($sql);
$sin_puntuacion = [];
while ($fila = $res->fetch_assoc()) {
    $fila['fecha']    = date('d/m/Y', strtotime($fila['fecha']));
    $sin_puntuacion[] = $fila;
}
$response['avisos_sin_puntuacion'] = $sin_puntuacion;

// 4b. Partidos con importaciones incompletas
// (hay jugadores con estadísticas pero sin puntuación en ese partido)
$sql = "SELECT p.id_partido, p.rival, p.fecha,
            COUNT(DISTINCT e.id_jugador) AS jugadores_importados,
            COUNT(DISTINCT pu.id_jugador) AS jugadores_puntuados
        FROM partidos p
        INNER JOIN estadisticas_jugador_partido e ON e.id_partido = p.id_partido
        LEFT  JOIN puntuaciones pu ON pu.id_partido = p.id_partido AND pu.id_jugador = e.id_jugador
        GROUP BY p.id_partido
        HAVING jugadores_importados > jugadores_puntuados
        ORDER BY p.fecha DESC";

$res = $conexion->query($sql);
$incompletos = [];
while ($fila = $res->fetch_assoc()) {
    $fila['fecha']      = date('d/m/Y', strtotime($fila['fecha']));
    $fila['pendientes'] = (int)$fila['jugadores_importados'] - (int)$fila['jugadores_puntuados'];
    $incompletos[]      = $fila;
}
$response['avisos_incompletos'] = $incompletos;

echo json_encode($response, JSON_UNESCAPED_UNICODE);