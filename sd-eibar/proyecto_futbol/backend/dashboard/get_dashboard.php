<?php

require '../conexion.php';

$response = [];

// ===== 1. ULTIMO PARTIDO =====

$sql = "SELECT id_partido, rival, fecha, competicion, local_visitante, goles_favor, goles_contra
        FROM partidos
        ORDER BY fecha DESC
        LIMIT 1";

$res = $conexion->query($sql);
$partido = $res->fetch_assoc();

if ($partido) {
    $esLocal = $partido['local_visitante'] === 'local';
    $marcador = $partido['goles_favor'] . ' - ' . $partido['goles_contra'];
    $localidad = $esLocal ? 'vs' : '@';

    if ($partido['goles_favor'] > $partido['goles_contra'])
        $resultado = 'Victoria';
    elseif ($partido['goles_favor'] < $partido['goles_contra'])
        $resultado = 'Derrota';
    else
        $resultado = 'Empate';

    $response['ultimo_partido'] = [
        'rival' => $partido['rival'],
        'fecha' => date('d/m/Y', strtotime($partido['fecha'])),
        'competicion' => $partido['competicion'],
        'marcador' => $marcador,
        'resultado' => $resultado,
        'localidad' => $localidad
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
// Si fecha_fin es NULL usa fecha_prevista_retorno como referencia

$sql = "SELECT j.id_jugador, j.nombre, j.apellidos, j.posicion_habitual,
            l.tipo_lesion, l.gravedad, l.observaciones, l.fecha_inicio,
            IFNULL(l.fecha_fin, l.fecha_prevista_retorno) AS fecha_alta,
            DATEDIFF(IFNULL(l.fecha_fin, l.fecha_prevista_retorno), CURDATE()) AS dias_restantes
        FROM lesiones l
        INNER JOIN jugadores j ON j.id_jugador = l.id_jugador
        WHERE CURDATE() BETWEEN l.fecha_inicio AND IFNULL(l.fecha_fin, l.fecha_prevista_retorno)
        ORDER BY dias_restantes ASC";

$res = $conexion->query($sql);
$lesiones = [];
while ($fila = $res->fetch_assoc()) {
    $fila['fecha_inicio'] = date('d/m/Y', strtotime($fila['fecha_inicio']));
    $fila['fecha_alta'] = $fila['fecha_alta'] ? date('d/m/Y', strtotime($fila['fecha_alta'])) : 'Sin fecha';
    $fila['dias_restantes'] = (int) $fila['dias_restantes'];
    $lesiones[] = $fila;
}
$response['lesiones_activas'] = $lesiones;

echo json_encode($response, JSON_UNESCAPED_UNICODE);

?>