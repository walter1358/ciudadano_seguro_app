@echo off
echo Iniciando proceso de limpieza y preparacion del proyecto...

:: 1. ELIMINACION DE CARPETAS DE BUILD Y CACHE (rd /s /q)
echo.
echo Eliminando carpetas de build y cache...
rd /s /q build 
rd /s /q .dart_tool
rd /s /q ios\Flutter\ephemeral
rd /s /q linux\flutter\ephemeral
rd /s /q macos\Flutter\ephemeral
rd /s /q windows\flutter\ephemeral
echo Limpieza de carpetas completada.

:: 2. COMANDO OFICIAL DE FLUTTER CLEAN
echo.
echo Ejecutando flutter clean...
flutter clean
if errorlevel 1 (
    echo [ERROR] No se pudo ejecutar 'flutter clean'. Asegurate de que Flutter este en el PATH.
    goto :end
)
echo flutter clean completado.

:: 3. DESCARGA E INSTALACION DE DEPENDENCIAS
echo.
echo Descargando dependencias (flutter pub get)...
flutter pub get
if errorlevel 1 (
    echo [ERROR] No se pudo ejecutar 'flutter pub get'.
    goto :end
)
echo flutter pub get completado.

:: 4. ACTUALIZACION DE DEPENDENCIAS
echo.
echo Actualizando dependencias (flutter pub upgrade)...
flutter pub upgrade
if errorlevel 1 (
    echo [ERROR] No se pudo ejecutar 'flutter pub upgrade'.
    goto :end
)
echo flutter pub upgrade completado.

echo.
echo PROCESO FINALIZADO EXITOSAMENTE.
:end
pause