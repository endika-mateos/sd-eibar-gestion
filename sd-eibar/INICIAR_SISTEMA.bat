@echo off
title Sistema SD Eibar
echo =====================================
echo    INICIANDO SISTEMA SD EIBAR
echo =====================================
echo.

:: ===== RUTAS DINAMICAS (funcionan desde cualquier ubicacion) =====
:: %~dp0 = carpeta donde esta este .bat (sea cual sea la ruta de instalacion)
set "RAIZ=%~dp0"
set "PYTHON_DIR=%RAIZ%proyecto_Eibar_Phyton"
set "VENV_DIR=%PYTHON_DIR%\venv"

:: Calcula la URL relativa quitando C:\xampp\htdocs\ del inicio
set "RUTA_WEB=%RAIZ:C:\xampp\htdocs\=%"
set "RUTA_WEB=%RUTA_WEB:\=/%"
set "URL_APP=http://localhost/%RUTA_WEB%proyecto_futbol/frontend/dashboard.html"

:: ===== ARRANCA APACHE Y MYSQL =====
echo [1/3] Arrancando Apache y MySQL...
start "" "C:\xampp\apache_start.bat"
timeout /t 3 /nobreak > nul
start "" "C:\xampp\mysql_start.bat"

echo Esperando a que Apache este listo...
:esperar_apache
timeout /t 2 /nobreak > nul
curl -s http://localhost > nul 2>&1
if %errorlevel% neq 0 goto esperar_apache
echo Apache listo!

timeout /t 8 /nobreak > nul
echo MySQL listo!

:: ===== ARRANCA LA API DE PYTHON =====
echo [2/3] Arrancando API Python...

if not exist "%PYTHON_DIR%" (
    echo ERROR: No se encontro la carpeta: %PYTHON_DIR%
    pause
    exit /b 1
)

cd /d "%PYTHON_DIR%"

:: Crea el venv si no existe todavia
if not exist "%VENV_DIR%" (
    echo Creando entorno virtual Python por primera vez...
    python -m venv venv
    call "%VENV_DIR%\Scripts\activate.bat"
    pip install -r requirements.txt
    echo Dependencias instaladas correctamente.
)

:: Lanza uvicorn en ventana separada con titulo reconocible
start "API Python SD Eibar" cmd /k "cd /d "%PYTHON_DIR%" && call venv\Scripts\activate.bat && python -m uvicorn main:app --port 8030"

timeout /t 5 /nobreak > nul

:: ===== ABRE EL NAVEGADOR =====
echo [3/3] Abriendo aplicacion...
echo URL: %URL_APP%
start "" "%URL_APP%"

echo.
echo Sistema iniciado correctamente.
echo Para cerrar la API cierra la ventana "API Python SD Eibar".