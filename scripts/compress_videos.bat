:: PAIGC

@echo off
:: Switch to UTF-8 code page so PowerShell output with non-ASCII paths is handled correctly.
chcp 65001 > nul
setlocal EnableExtensions EnableDelayedExpansion

:: ==============================================================================
:: compress_videos.bat -- Batch video compression using FFmpeg.
::
:: SYNOPSIS
::   compress_videos.bat <input_dir> <output_dir> [size_mb] [-use_gpu] [-lossless]
::
:: ARGUMENTS
::   input_dir    Required. Source directory to scan for video files (recursive).
::   output_dir   Required. Destination directory for compressed output files.
::   size_mb      Optional. Minimum file size in MB to process.  Default: 2000
::   -use_gpu     Optional. Enable NVIDIA NVENC GPU acceleration. Default: disabled
::   -lossless    Optional. Enable lossless encoding.            Default: disabled
::
:: ENCODING MODES
::   Lossy  + CPU : libx264    CRF 23  preset medium  -- output .mp4
::   Lossy  + GPU : h264_nvenc QP  23  preset p4  rc constqp  -- output .mp4
::   Lossless     : libx264    CRF  0  preset medium  -- output .mkv  (GPU ignored)
::   Audio stream is always copied without re-encoding (-c:a copy).
::
:: EXAMPLES
::   compress_videos.bat "C:\Videos" "C:\Output"
::   compress_videos.bat "C:\Videos" "C:\Output" 1000
::   compress_videos.bat "C:\Videos" "C:\Output" 1000 -use_gpu
::   compress_videos.bat "C:\Videos" "C:\Output" -lossless
::   compress_videos.bat "C:\Videos" "C:\Output" 1000 -use_gpu -lossless
::
:: REQUIREMENTS
::   FFmpeg must be installed and accessible via PATH.
::   GPU mode requires an NVIDIA GPU with NVENC support.
::   File discovery uses PowerShell; PowerShell must be available (Windows 5.1+).
::   Press Ctrl+C to abort; you will be prompted "Terminate batch job (Y/N)?".
:: ==============================================================================

:: ------------------------------------------------------------------------------
:: Get the carriage-return (CR) character using a well-known batch trick.
:: This is used to overwrite the progress bar line in-place.
:: ------------------------------------------------------------------------------
for /f %%A in ('copy /Z "%~f0" NUL') do set "CR=%%A"

:: ------------------------------------------------------------------------------
:: Default configuration
:: ------------------------------------------------------------------------------
set "DEFAULT_SIZE_MB=2000"

:: Width of the progress bar in characters
set /a BAR_WIDTH=40

:: Supported video extensions passed to PowerShell (comma-separated, no dots)
set "VIDEO_EXTS=mp4,mkv,avi,mov,wmv,flv,ts,m4v,rmvb"

:: Temp file that holds the discovered file list (one path per line)
set "TMPLIST=%TEMP%\compress_videos_%RANDOM%.txt"

:: ------------------------------------------------------------------------------
:: Argument parsing
:: ------------------------------------------------------------------------------
if "%~1"==""       goto :show_usage
if "%~1"=="--help" goto :show_usage
if "%~1"=="-h"     goto :show_usage
if "%~2"=="" (
    call :log_error "Missing required argument: output_dir"
    goto :show_usage
)

:: Resolve arguments 1 and 2 to their absolute paths
set "INPUT_DIR=%~f1"
set "OUTPUT_DIR=%~f2"
set "SIZE_LIMIT_MB=%DEFAULT_SIZE_MB%"
set "USE_GPU=no"
set "LOSSLESS=no"
shift /1
shift /1

:: Parse remaining optional arguments; -use_gpu/-lossless flags and size_mb may appear in any order.
:arg_loop
if "%~1"=="" goto :arg_done
if /i "%~1"=="-use_gpu"   ( set "USE_GPU=yes"  & shift /1 & goto :arg_loop )
if /i "%~1"=="--use_gpu"  ( set "USE_GPU=yes"  & shift /1 & goto :arg_loop )
if /i "%~1"=="-lossless"  ( set "LOSSLESS=yes" & shift /1 & goto :arg_loop )
if /i "%~1"=="--lossless" ( set "LOSSLESS=yes" & shift /1 & goto :arg_loop )
:: Unrecognized token — treat as size_mb
set "SIZE_LIMIT_MB=%~1"
shift /1
goto :arg_loop
:arg_done

:: Lossless overrides GPU -- GPU lossless encoding is unreliable
if /i "!LOSSLESS!"=="yes" (
    if /i "!USE_GPU!"=="yes" (
        call :log_warn "Lossless mode enabled. GPU will not be used (falling back to CPU libx264)."
        set "USE_GPU=no"
    )
)

:: ------------------------------------------------------------------------------
:: Validate arguments
:: ------------------------------------------------------------------------------
:: Validate SIZE_LIMIT_MB is a positive integer.
:: Use for /f with digit delimiters: if any non-digit token is found, the value is invalid.
set "_INVALID="
for /f "delims=0123456789" %%D in ("!SIZE_LIMIT_MB!") do set "_INVALID=1"
if "!SIZE_LIMIT_MB!"=="" set "_INVALID=1"
if defined _INVALID (
    call :log_error "size_mb must be a positive integer (got: '!SIZE_LIMIT_MB!')"
    exit /b 1
)

:: Validate input directory exists
if not exist "!INPUT_DIR!\" (
    call :log_error "Input directory not found: !INPUT_DIR!"
    exit /b 1
)

:: ------------------------------------------------------------------------------
:: Check FFmpeg
:: ------------------------------------------------------------------------------
call :check_ffmpeg
if errorlevel 1 exit /b 1

:: If GPU mode is requested, verify h264_nvenc supports the p4 preset (added in FFmpeg 5.0).
:: Legacy GUID presets (default/medium/hq) are rejected by NVENC drivers >= 520;
:: new p1-p7 presets are not recognised by FFmpeg < 5.0.
:: Detect support at runtime and fall back to CPU if p4 is not listed.
if /i "!USE_GPU!"=="yes" (
    set "_NVENC_OK="
    for /f "delims=" %%P in ('ffmpeg -hide_banner -h encoder^=h264_nvenc 2^>^&1 ^| findstr /c:" p4"') do set "_NVENC_OK=1"
    if not defined _NVENC_OK (
        call :log_warn "GPU mode requires FFmpeg 5.0+ (h264_nvenc p4 preset not found in this build)."
        call :log_warn "Falling back to CPU encoding (libx264). Update FFmpeg to enable GPU support."
        set "USE_GPU=no"
    )
)

:: Print configuration summary
echo.
echo === Video Compression Script ===
call :log_info "Input directory  : !INPUT_DIR!"
call :log_info "Output directory : !OUTPUT_DIR!"
call :log_info "Size filter      : > !SIZE_LIMIT_MB! MB"
if /i "!USE_GPU!"=="yes" (
    call :log_info "GPU acceleration : yes (NVIDIA NVENC -- h264_nvenc)"
) else (
    call :log_info "GPU acceleration : no  (CPU -- libx264)"
)
if /i "!LOSSLESS!"=="yes" (
    call :log_info "Encoding mode    : lossless  (libx264 CRF 0 -> .mkv)"
) else (
    call :log_info "Encoding mode    : lossy     (CRF/CQ 23 -> .mp4)"
)
echo.

:: ==============================================================================
:: Step 1: Discover video files larger than SIZE_LIMIT_MB using PowerShell.
:: One PowerShell call enumerates all matching files, which is much faster than
:: launching PowerShell once per file found by "for /r".
:: Paths are read from environment variables to handle spaces and special chars.
:: ==============================================================================
call :log_info "Scanning '!INPUT_DIR!' for video files larger than !SIZE_LIMIT_MB! MB..."

set "PS_INPUT=!INPUT_DIR!"
set "PS_SIZELIMIT=!SIZE_LIMIT_MB!"
set "PS_EXTS=!VIDEO_EXTS!"

if exist "!TMPLIST!" del "!TMPLIST!"

powershell -NoProfile -Command ^
    "$exts = $env:PS_EXTS.Split(',');" ^
    "$limit = [long]$env:PS_SIZELIMIT * 1MB;" ^
    "$results = Get-ChildItem -LiteralPath $env:PS_INPUT -Recurse -File" ^
    " | Where-Object { $exts -contains $_.Extension.TrimStart('.').ToLower() -and $_.Length -gt $limit }" ^
    " | Sort-Object FullName" ^
    " | Select-Object -ExpandProperty FullName;" ^
    "[IO.File]::WriteAllLines('!TMPLIST!', $results, [Text.UTF8Encoding]::new($false))" 2>nul

:: Count matched files (each non-empty line is one file)
set "TOTAL=0"
if exist "!TMPLIST!" (
    for /f "usebackq delims=" %%L in ("!TMPLIST!") do set /a TOTAL+=1
)

if !TOTAL! EQU 0 (
    call :log_warn "No video files exceeding !SIZE_LIMIT_MB! MB were found. Nothing to do."
    if exist "!TMPLIST!" del "!TMPLIST!"
    exit /b 0
)

call :log_info "Found !TOTAL! file(s) to process:"

:: List each file with its size
for /f "usebackq delims=" %%L in ("!TMPLIST!") do (
    set "PS_FILEPATH=%%L"
    for /f %%M in ('powershell -NoProfile -Command "[Math]::Round((Get-Item -LiteralPath $env:PS_FILEPATH).Length/1MB,2)"') do set "SZ=%%M"
    call :log_info "  [!SZ! MB]  %%L"
)
echo.

:: Create output root directory via PowerShell.
:: New-Item -Force creates all parent directories (equivalent to mkdir -p).
set "PS_OUTPUT_DIR=!OUTPUT_DIR!"
powershell -NoProfile -Command ^
    "New-Item -ItemType Directory -LiteralPath $env:PS_OUTPUT_DIR -Force | Out-Null;" ^
    "exit $LASTEXITCODE" 2>nul
if errorlevel 1 (
    call :log_error "Cannot create output directory: !OUTPUT_DIR!"
    if exist "!TMPLIST!" del "!TMPLIST!"
    exit /b 1
)

:: ==============================================================================
:: Step 2: Compress each file
:: ==============================================================================
call :log_info "Starting compression of !TOTAL! file(s)..."
echo.

set "CURRENT=0"
set "SUCCESS=0"
set "FAILED=0"

for /f "usebackq delims=" %%L in ("!TMPLIST!") do (
    set /a CURRENT+=1
    call :draw_progress !CURRENT! !TOTAL!
    echo.
    call :process_file "%%L"
    echo.
)

:: Final 100% progress bar
call :draw_progress !TOTAL! !TOTAL!
echo.

:: ==============================================================================
:: Summary
:: ==============================================================================
echo.
echo === Summary ============================================
call :log_info "Processed successfully : !SUCCESS!"
call :log_info "Failed                 : !FAILED!"
echo ========================================================

:: Cleanup temp file
if exist "!TMPLIST!" del "!TMPLIST!"
exit /b 0

:: ==============================================================================
:: Subroutines
:: ==============================================================================

:: ------------------------------------------------------------------------------
:: :show_usage — print help text and exit
:: ------------------------------------------------------------------------------
:show_usage
echo.
echo compress_videos.bat -- Batch video compression using FFmpeg
echo.
echo USAGE
echo   compress_videos.bat ^<input_dir^> ^<output_dir^> [size_mb] [-use_gpu] [-lossless]
echo.
echo ARGUMENTS
echo   input_dir    Required. Source directory to scan for video files (recursive).
echo   output_dir   Required. Destination directory for compressed output files.
echo.
echo OPTIONS  (all optional, flags and size_mb may appear in any order^)
echo   size_mb      Minimum file size in MB to process.  Default: 2000
echo   -use_gpu     Enable NVIDIA NVENC GPU acceleration. Default: disabled
echo   -lossless    Enable lossless encoding.             Default: disabled
echo.
echo ENCODING
echo   Lossy  + CPU : libx264    CRF 23  preset medium  -^> .mp4
echo   Lossy  + GPU : h264_nvenc QP  23  preset p4  rc constqp  -^> .mp4
echo   Lossless     : libx264    CRF  0  preset medium  -^> .mkv  (GPU is ignored^)
echo   Audio is always copied without re-encoding.
echo.
echo EXAMPLES
echo   compress_videos.bat "C:\Videos" "C:\Output"
echo   compress_videos.bat "C:\Videos" "C:\Output" 1000
echo   compress_videos.bat "C:\Videos" "C:\Output" 1000 -use_gpu
echo   compress_videos.bat "C:\Videos" "C:\Output" -lossless
echo   compress_videos.bat "C:\Videos" "C:\Output" 1000 -use_gpu -lossless
echo.
echo NOTES
echo   FFmpeg must be installed and accessible via PATH.
echo   GPU mode requires an NVIDIA GPU with NVENC support.
echo   Press Ctrl+C to abort; you will be prompted "Terminate batch job (Y/N)?".
exit /b 1

:: ------------------------------------------------------------------------------
:: :check_ffmpeg — exit 1 if ffmpeg is not found in PATH
:: ------------------------------------------------------------------------------
:check_ffmpeg
where ffmpeg >nul 2>nul
if errorlevel 1 (
    call :log_error "FFmpeg not found. Please install FFmpeg and add it to PATH."
    call :log_error "  Download: https://ffmpeg.org/download.html"
    exit /b 1
)
:: Capture only the first line of "ffmpeg -version" output.
:: A guard variable is used instead of "goto" inside a for-loop body,
:: because "goto" inside a for (...) block causes CMD to print
:: "The syntax of the command is incorrect." after the loop exits.
set "FFVER="
for /f "tokens=*" %%V in ('ffmpeg -version') do (
    if "!FFVER!"=="" set "FFVER=%%V"
)
call :log_info "FFmpeg: !FFVER!"
set "FFVER="
exit /b 0

:: ------------------------------------------------------------------------------
:: :process_file "<filepath>" — compress a single video file with FFmpeg.
:: Updates SUCCESS and FAILED counters in the caller's scope.
:: ------------------------------------------------------------------------------
:process_file
set "FILEPATH=%~1"

:: Get input file size (in MB) via PowerShell using $env: to handle path spaces
set "PS_FILEPATH=!FILEPATH!"
set "IN_MB=0"
for /f %%M in ('powershell -NoProfile -Command "[Math]::Round((Get-Item -LiteralPath $env:PS_FILEPATH).Length/1MB,2)"') do set "IN_MB=%%M"

:: Compute the relative path from INPUT_DIR using PowerShell
set "PS_INPUTDIR=!INPUT_DIR!"
set "REL_PATH=!FILEPATH!"
for /f "delims=" %%R in ('powershell -NoProfile -Command "$b=$env:PS_INPUTDIR;$p=$env:PS_FILEPATH;if($p.StartsWith($b,[StringComparison]::OrdinalIgnoreCase)){$p.Substring($b.Length).TrimStart([char]92,[char]47)}else{$p}"') do set "REL_PATH=%%R"

:: Get the relative sub-directory (empty string if file is in the root of INPUT_DIR)
set "REL_DIR="
for /f "delims=" %%D in ('powershell -NoProfile -Command "$d=[IO.Path]::GetDirectoryName($env:REL_PATH); if($d -and $d -ne '.'){$d}"') do set "REL_DIR=%%D"

:: Get the filename without extension
set "BASENAME="
for /f "delims=" %%N in ('powershell -NoProfile -Command "[IO.Path]::GetFileNameWithoutExtension($env:PS_FILEPATH)"') do set "BASENAME=%%N"

:: Determine output extension and output paths
if /i "!LOSSLESS!"=="yes" (set "OUT_EXT=mkv") else (set "OUT_EXT=mp4")

if "!REL_DIR!"=="" (
    set "OUT_DIR=!OUTPUT_DIR!"
) else (
    set "OUT_DIR=!OUTPUT_DIR!\!REL_DIR!"
)
set "OUT_FILE=!OUT_DIR!\!BASENAME!.!OUT_EXT!"

call :log_info "-- File !CURRENT!/!TOTAL! ------------------------------------------------------------------"
call :log_info "  Input  : [!IN_MB! MB]  !FILEPATH!"
call :log_info "  Output : !OUT_FILE!"

:: Create output subdirectory via PowerShell.
:: PowerShell handles Unicode paths correctly; CMD's mkdir can fail with
:: "The system cannot find the drive specified." on Unicode paths under chcp 65001.
set "PS_OUTDIR=!OUT_DIR!"
powershell -NoProfile -Command ^
    "if(-not(Test-Path -LiteralPath $env:PS_OUTDIR)){" ^
    "  New-Item -ItemType Directory -LiteralPath $env:PS_OUTDIR -Force | Out-Null" ^
    "  if(-not $?){exit 1}" ^
    "}" 2>nul
if errorlevel 1 (
    call :log_error "  Cannot create directory: !OUT_DIR!"
    set /a FAILED+=1
    exit /b 0
)

:: Build video encoder args (ASCII-only flags, no file paths).
if /i "!LOSSLESS!"=="yes" (
    set "FF_VENC=-c:v libx264 -preset medium -crf 0"
) else if /i "!USE_GPU!"=="yes" (
    :: NVENC SDK 12+ (driver >= 520) removed the old GUID-based presets (default/medium/hq).
    :: Use the new performance presets p1-p7 instead; p4 is the balanced equivalent of "medium".
    set "FF_VENC=-c:v h264_nvenc -preset p4 -rc:v constqp -qp 23"
) else (
    set "FF_VENC=-c:v libx264 -preset medium -crf 23"
)

:: Invoke FFmpeg via PowerShell so Unicode file paths are handled reliably.
:: $env: variables bypass CMD quote-expansion issues; PowerShell passes each
:: variable as a single token with no word-splitting, even for paths with spaces.
:: -stats forces the one-line progress display (frame/fps/time/speed) to stderr;
:: each update uses CR (\r) to overwrite the previous line in-place.
set "PS_FF_INPUT=!FILEPATH!"
set "PS_FF_OUTPUT=!OUT_FILE!"
powershell -NoProfile -Command ^
    "& ffmpeg -y -i $env:PS_FF_INPUT !FF_VENC! -c:a copy -loglevel error -stats $env:PS_FF_OUTPUT;" ^
    "exit $LASTEXITCODE"

if !errorlevel! EQU 0 (
    set "PS_OUTFILE=!OUT_FILE!"
    set "OUT_MB=0"
    for /f %%M in ('powershell -NoProfile -Command "[Math]::Round((Get-Item -LiteralPath $env:PS_OUTFILE).Length/1MB,2)"') do set "OUT_MB=%%M"

    call :log_ok "  Result : [!OUT_MB! MB]  !OUT_FILE!"

    :: Compute space savings via PowerShell to avoid 32-bit integer overflow in set /a
    set "PS_IN_MB=!IN_MB!"
    set "PS_OUT_MB=!OUT_MB!"
    for /f %%P in ('powershell -NoProfile -Command "if([double]$env:PS_IN_MB -gt 0){[int][Math]::Round((1-[double]$env:PS_OUT_MB/[double]$env:PS_IN_MB)*100)}else{0}"') do set "SAVED_PCT=%%P"
    for /f %%S in ('powershell -NoProfile -Command "[Math]::Round([double]$env:PS_IN_MB-[double]$env:PS_OUT_MB,2)"') do set "SAVED_MB=%%S"

    if !SAVED_PCT! GTR 0 (
        call :log_ok "  Saved  : !SAVED_MB! MB  (!SAVED_PCT!%% reduction)"
    ) else (
        call :log_warn "  Note   : Output is not smaller than input. Consider adjusting settings."
    )
    set /a SUCCESS+=1
) else (
    call :log_error "  FFmpeg failed for: !FILEPATH!"
    if exist "!OUT_FILE!" del "!OUT_FILE!"
    set /a FAILED+=1
)
exit /b 0

:: ------------------------------------------------------------------------------
:: :draw_progress <current> <total> — print a progress bar that overwrites itself
:: ------------------------------------------------------------------------------
:draw_progress
set /a "_CUR=%~1"
set /a "_TOT=%~2"
set /a "_PCT=_CUR*100/_TOT"
set /a "_FILL=_CUR*BAR_WIDTH/_TOT"
set /a "_EMPTY=BAR_WIDTH-_FILL"

set "_BAR="
for /l %%i in (1,1,!_FILL!)  do set "_BAR=!_BAR!="
for /l %%i in (1,1,!_EMPTY!) do set "_BAR=!_BAR! "

:: Print progress bar followed by CR to allow the next call to overwrite this line
<nul set /p "=Progress: [!_BAR!] !_PCT!%%  (!_CUR!/!_TOT!)   !CR!"
exit /b 0

:: ------------------------------------------------------------------------------
:: Logging subroutines.
:: Uses "<nul set /p" instead of "echo" so that special characters such as
:: >, <, |, & in the message are not interpreted as shell operators.
:: ------------------------------------------------------------------------------
:log_info
<nul set /p "=%~1"
echo.
exit /b 0

:log_ok
<nul set /p "=%~1"
echo.
exit /b 0

:log_warn
<nul set /p "=%~1"
echo.
exit /b 0

:log_error
<nul set /p "=%~1"
echo.
exit /b 0
