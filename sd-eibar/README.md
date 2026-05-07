# SD Eibar — Aplicación de Gestión de Fútbol

Aplicación web completa para la gestión del equipo SD Eibar. Permite administrar jugadores, temporadas, estadísticas, rivales y mucho más.

## 🚀 Tecnologías utilizadas

### Frontend & Backend Web (desarrollado por Endika Mateos)
- HTML5
- CSS3
- Bootstrap
- PHP
- MySQL

### API REST (desarrollado por el equipo de Python)
- Python
- FastAPI
- SQLAlchemy
- MySQL Connector

## 📁 Estructura del proyecto

```
Aplicacion_SDEibar/
├── proyecto_futbol/          # Aplicación web principal (PHP + HTML + CSS + Bootstrap)
│   ├── frontend/             # Vistas y estilos
│   ├── backend/              # Lógica de negocio en PHP
│   │   ├── jugadores/        # CRUD de jugadores
│   │   ├── temporadas/       # Gestión de temporadas
│   │   ├── partidos/         # Registro de partidos
│   │   ├── lesiones/         # Control de lesiones
│   │   └── dashboard/        # Panel de control
│   ├── assets/               # Imágenes y recursos
│   └── mysql/                # Scripts de base de datos
│
├── proyecto_Eibar_Phyton/    # API REST (Python/FastAPI)
│   ├── main.py               # Punto de entrada
│   ├── models/               # Modelos de base de datos
│   ├── schemas/              # Esquemas Pydantic
│   ├── routers/              # Rutas de la API
│   └── config/               # Configuración
│
└── INICIAR_SISTEMA.bat       # Script de arranque del sistema
```

## ⚙️ Instalación y uso

### Requisitos
- XAMPP (Apache + MySQL)
- Python 3.x
- Navegador web moderno

### Pasos
1. Clona el repositorio
2. Importa el script SQL en MySQL
3. Configura la conexión a la base de datos en `config/database.py`
4. Ejecuta `INICIAR_SISTEMA.bat` para arrancar el sistema
5. Abre el navegador en `http://localhost/proyecto_futbol`

## 👥 Equipo de desarrollo

| Parte | Desarrollador | Tecnologías |
|-------|--------------|-------------|
| Aplicación web | Endika Mateos | PHP, MySQL, HTML, CSS, Bootstrap |
| API REST | Equipo Python | Python, FastAPI, SQLAlchemy |

## 📸 Funcionalidades

- ✅ Gestión de jugadores (altas, bajas, modificaciones)
- ✅ Control de temporadas
- ✅ Registro de estadísticas
- ✅ Gestión de rivales
- ✅ Control de lesiones
- ✅ Dashboard con resumen general
- ✅ API REST para integración externa
