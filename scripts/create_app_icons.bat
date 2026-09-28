:: PAIGC

@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM Usage check
if "%~1"=="" goto :usage
if "%~2"=="" goto :usage

set "SRC=%~1"
set "OUT_DIR=%~2"
set "OUT_NAME=%~3"
if "%OUT_NAME%"=="" set "OUT_NAME=app"
set "MARGIN=%~4"
if "%MARGIN%"=="" set "MARGIN=0"

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

REM Validate margin
echo %MARGIN%|findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 (
    echo [ERROR] Margin must be a non-negative integer percentage: "%MARGIN%"
    exit /b 1
)
if %MARGIN% GEQ 50 (
    echo [ERROR] Margin percentage must be within [0, 50): "%MARGIN%"
    exit /b 1
)

REM Create output directory
if not exist "%OUT_DIR%" (
    mkdir "%OUT_DIR%" || (
        echo [ERROR] Failed to create output directory: "%OUT_DIR%"
        exit /b 1
    )
)

REM Apply safe-zone margin (macOS auto-masks edge-to-edge icons; padding avoids that)
set "WORK_SRC=%SRC%"
set "TMP_PADDED="
if %MARGIN% GTR 0 (
    for /f %%W in ('magick identify -format "%%w" "%SRC%"') do set "CANVAS=%%W"
    set /a CONTENT=CANVAS * (100 - 2*MARGIN) / 100
    set "TMP_PADDED=%OUT_DIR%\.%OUT_NAME%_padded_src.png"
    echo [INFO] Applying %MARGIN%%% safe-zone margin ^(content !CONTENT!px of !CANVAS!px canvas^)
    magick "%SRC%" -resize !CONTENT!x!CONTENT! -background none -gravity center -extent !CANVAS!x!CANVAS! "!TMP_PADDED!"
    if errorlevel 1 (
        echo [ERROR] Failed to apply margin padding
        exit /b 1
    )
    set "WORK_SRC=!TMP_PADDED!"
)

echo [INFO] Output name prefix: "%OUT_NAME%"
echo [INFO] Generating PNG sizes: 16,32,64,128,256,512,1024
for %%S in (16 32 64 128 256 512 1024) do (
    magick "!WORK_SRC!" -resize %%Sx%%S -filter Lanczos -strip "%OUT_DIR%\%OUT_NAME%_%%S.png"
    if errorlevel 1 (
        echo [ERROR] Failed to generate %OUT_NAME%_%%S.png
        exit /b 1
    )
)

echo [INFO] Generating ICO (16,24,32,48,64,128,256)
magick "!WORK_SRC!" -define icon:auto-resize=16,24,32,48,64,128,256 "%OUT_DIR%\%OUT_NAME%.ico"
if errorlevel 1 (
    echo [ERROR] Failed to generate %OUT_NAME%.ico
    exit /b 1
)

echo [INFO] Generating ICNS (16,32,64,128,256,512,1024)
magick "!WORK_SRC!" -define icon:auto-resize=16,32,64,128,256,512,1024 "%OUT_DIR%\%OUT_NAME%.icns"
if errorlevel 1 (
    echo [ERROR] Failed to generate %OUT_NAME%.icns
    exit /b 1
)

if defined TMP_PADDED del /q "!TMP_PADDED!" >nul 2>nul

echo [OK] Done
echo [OK] Output directory: "%OUT_DIR%"
exit /b 0

:usage
echo Usage:
echo   %~nx0 ^<input.png^> ^<output_folder^> [output_name] [margin_percent]
echo Example:
echo   %~nx0 "C:\images\logo_1024.png" "C:\images\out" "myicon" 9
exit /b 2
