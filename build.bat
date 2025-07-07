@echo off
setlocal

:: Set names and paths
set EXE_NAME=game.exe
set BUILD_DIR=build
set ZIP_TEMP=zip_temp
set ZIP_NAME=game_package.zip
set SEVEN_ZIP="C:\Program Files\7-Zip\7z.exe"

:: Update the path above if 7z.exe is elsewhere

echo [1/4] Creating build directory if needed...
if not exist %BUILD_DIR% mkdir %BUILD_DIR%

echo [2/4] Building the game with Odin...
odin build . -out:%BUILD_DIR%\%EXE_NAME%
if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo [3/4] Preparing files for zipping...
if exist %ZIP_TEMP% rmdir /s /q %ZIP_TEMP%
mkdir %ZIP_TEMP%

copy "%BUILD_DIR%\%EXE_NAME%" %ZIP_TEMP% >nul

:: Copy PNG files
for %%f in (*.png) do (
    copy "%%f" %ZIP_TEMP% >nul
)

echo [4/4] Creating zip archive with 7-Zip...
%SEVEN_ZIP% a %ZIP_NAME% %ZIP_TEMP%\*

:: Cleanup
rmdir /s /q %ZIP_TEMP%

echo Done. Output: %ZIP_NAME%
endlocal
