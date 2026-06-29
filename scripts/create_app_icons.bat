:: PAIGC

@echo off
setlocal EnableExtensions

REM Usage check
if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set "SRC=%~1"
set "OUT_DIR=%~2"
set "OUT_NAME=%~3"
if "%OUT_NAME%"=="" set "OUT_NAME=app"

REM Check source file
if not exist "%SRC%" (
    echo [ERROR] Input image does not exist: "%SRC%"
    exit /b 1
)

REM Check magick
where magick >nul 2>nul
if errorlevel 1 (
    echo [ERROR] ImageMagick command "magick" not found. Please install it and add to PATH.
    exit /b 1
)

REM Create output directory
if not exist "%OUT_DIR%" (
    mkdir "%OUT_DIR%" || (
        echo [ERROR] Failed to create output directory: "%OUT_DIR%"
        exit /b 1
    )
)

echo [INFO] Output name prefix: "%OUT_NAME%"
echo [INFO] Generating PNG sizes: 16,32,64,128,256,512,1024
for %%S in (16 32 64 128 256 512 1024) do (
    magick "%SRC%" -resize %%Sx%%S -filter Lanczos -strip "%OUT_DIR%\%OUT_NAME%_%%S.png"
    if errorlevel 1 (
        echo [ERROR] Failed to generate %OUT_NAME%_%%S.png
        exit /b 1
    )
)

echo [INFO] Generating ICO (16,24,32,48,64,128,256)
magick "%SRC%" -define icon:auto-resize=16,24,32,48,64,128,256 "%OUT_DIR%\%OUT_NAME%.ico"
if errorlevel 1 (
    echo [ERROR] Failed to generate %OUT_NAME%.ico
    exit /b 1
)

echo [INFO] Generating ICNS (16,32,64,128,256,512,1024)
magick "%SRC%" -define icon:auto-resize=16,32,64,128,256,512,1024 "%OUT_DIR%\%OUT_NAME%.icns"
if errorlevel 1 (
    echo [ERROR] Failed to generate %OUT_NAME%.icns
    exit /b 1
)

echo [OK] Done
echo [OK] Output directory: "%OUT_DIR%"
exit /b 0

:usage
echo Usage:
echo   %~nx0 ^<input.png^> ^<output_folder^> [output_name]
echo Example:
echo   %~nx0 "C:\images\logo_1024.png" "C:\images\out" "myicon"
exit /b 2
