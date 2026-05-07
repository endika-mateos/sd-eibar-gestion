@echo off
title Sistema SD Eibar
echo =====================================
echo    INICIANDO SISTEMA SD EIBAR
echo =====================================
echo.

:: ===== ARRANCA APACHE Y MYSQL =====
echo [1/3] Arrancando Apache y MySQL...
start "" "C:\xampp\apache_start.bat"
timeout /t 3 /nobreak > nul
start "" "C:\xampp\mysql_start.bat"

:: Espera hasta que Apache responda
echo Esperando a que Apache este listo...
:esperar_apache
timeout /t 2 /nobreak > nul
curl -s http://localhost > nul 2>&1
if %errorlevel% neq 0 goto esperar_apache
echo Apache listo!

:: Espera a que MySQL termine de arrancar
timeout /t 8 /nobreak > nul
echo MySQL listo!

:: ===== ARRANCA LA API DE PYTHON =====
echo [2/3] Arrancando API Python...
cd /d "C:\xampp\htdocs\Proyecto_SDEibar\proyecto_Eibar_Phyton"

:: Si no existe el venv lo crea e instala las dependencias
if not exist "venv" (
    echo Creando entorno virtual Python por primera vez...
    python -m venv venv
    call venv\Scripts\activate.bat
    pip install -r requirements.txt
    echo Dependencias instaladas correctamente.
)

call venv\Scripts\activate.bat
start "" uvicorn main:app --port 8030
timeout /t 5 /nobreak > nul

:: ===== ABRE EL NAVEGADOR =====
echo [3/3] Abriendo aplicacion...
start "" "http://localhost/Proyecto_SDEibar/proyecto_futbol/frontend/dashboard.html"

echo.
echo Sistema iniciado correctamente.
echo Para cerrar la API cierra la ventana negra de Python.
