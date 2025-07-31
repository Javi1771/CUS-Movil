@echo off
echo ========================================
echo    SOLUCIONANDO ERROR DE SURFACE
echo ========================================
echo.

echo 1. Verificando version de Flutter...
flutter --version

echo.
echo 2. Limpiando cache de Flutter...
flutter clean

echo.
echo 3. Obteniendo dependencias...
flutter pub get

echo.
echo 4. Limpiando cache de Gradle...
cd android
if exist gradlew.bat (
    gradlew.bat clean
) else (
    echo Gradle wrapper no encontrado, saltando limpieza de Gradle
)
cd ..

echo.
echo 5. Limpiando cache de pub...
flutter pub cache repair

echo.
echo 6. Verificando problemas...
flutter doctor

echo.
echo 7. Compilando en modo debug...
flutter build apk --debug

echo.
echo ========================================
echo    PROCESO COMPLETADO
echo ========================================
echo.
echo Si el error persiste, ejecuta:
echo flutter run --verbose
echo.
pause