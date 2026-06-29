#!/usr/bin/env bash

# PAIGC

# compress_videos.sh — Batch video compression using FFmpeg.
#
# SYNOPSIS
#   bash compress_videos.sh <input_dir> <output_dir> [size_mb] [-use_gpu] [-lossless]
#
# ARGUMENTS
#   input_dir    Required. Source directory to scan for video files (recursive).
#   output_dir   Required. Destination directory for compressed output files.
#   size_mb      Optional. Minimum file size in MB to process.  Default: 2000
#   -use_gpu     Optional. Enable NVIDIA NVENC GPU acceleration. Default: disabled
#   -lossless    Optional. Enable lossless encoding.            Default: disabled
#
# ENCODING MODES
#   Lossy  + CPU : libx264    CRF 23  preset medium  — output .mp4
#   Lossy  + GPU : h264_nvenc QP  23  preset p4  rc constqp  — output .mp4
#   Lossless     : libx264    CRF  0  preset medium  — output .mkv  (GPU ignored)
#   Audio stream is always copied without re-encoding (-c:a copy).
#
# EXAMPLES
#   bash compress_videos.sh /mnt/videos /mnt/output
#   bash compress_videos.sh /mnt/videos /mnt/output 1000
#   bash compress_videos.sh /mnt/videos /mnt/output 1000 -use_gpu
#   bash compress_videos.sh /mnt/videos /mnt/output -lossless
#   bash compress_videos.sh /mnt/videos /mnt/output 1000 -use_gpu -lossless
#
# REQUIREMENTS
#   FFmpeg must be installed and accessible via PATH.
#   GPU mode requires an NVIDIA GPU with NVENC support.
#   Press Ctrl+C to abort; any incomplete output file will be removed automatically.
# ==============================================================================

# Treat unset variables as errors; do NOT use -e so per-file FFmpeg failures
# are recoverable without aborting the entire batch.
set -u

# ------------------------------------------------------------------------------
# Constants
# ------------------------------------------------------------------------------
readonly SCRIPT_NAME="$(basename "$0")"
readonly DEFAULT_SIZE_MB=2000
readonly BAR_WIDTH=40

# Supported video file extensions (space-separated, all lowercase)
readonly VIDEO_EXTS="mp4 mkv avi mov wmv flv ts m4v rmvb"

# ------------------------------------------------------------------------------
# ANSI color codes — disabled automatically when stdout is not a terminal
# ------------------------------------------------------------------------------
if [[ -t 1 ]]; then
    C_RESET="\033[0m"
    C_RED="\033[0;31m"
    C_GREEN="\033[0;32m"
    C_YELLOW="\033[0;33m"
    C_BLUE="\033[0;34m"
    C_CYAN="\033[0;36m"
    C_BOLD="\033[1m"
else
    C_RESET="" C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_CYAN="" C_BOLD=""
fi

# ------------------------------------------------------------------------------
# Logging helpers
# ------------------------------------------------------------------------------
log_info()  { printf "%s\n"                      "$*"; }
log_ok()    { printf "${C_GREEN}%s${C_RESET}\n"   "$*"; }
log_warn()  { printf "${C_YELLOW}%s${C_RESET}\n"  "$*" >&2; }
log_error() { printf "${C_RED}%s${C_RESET}\n"     "$*" >&2; }

# ------------------------------------------------------------------------------
# usage — print help text
# ------------------------------------------------------------------------------
usage() {
    cat <<EOF
${C_BOLD}${SCRIPT_NAME}${C_RESET} — Batch video compression using FFmpeg

${C_BOLD}USAGE${C_RESET}
  bash ${SCRIPT_NAME} <input_dir> <output_dir> [size_mb] [-use_gpu] [-lossless]

${C_BOLD}ARGUMENTS${C_RESET}
  input_dir    Required. Source directory to scan for video files (recursive).
  output_dir   Required. Destination directory for compressed output files.

${C_BOLD}OPTIONS${C_RESET}  (all optional, flags and size_mb may appear in any order)
  size_mb      Minimum file size in MB to process.  Default: ${DEFAULT_SIZE_MB}
  -use_gpu     Enable NVIDIA NVENC GPU acceleration. Default: disabled
  -lossless    Enable lossless encoding.             Default: disabled

${C_BOLD}ENCODING${C_RESET}
  Lossy  + CPU : libx264    CRF 23  preset medium  -> .mp4
  Lossy  + GPU : h264_nvenc QP  23  preset p4  rc constqp  -> .mp4
  Lossless     : libx264    CRF  0  preset medium  -> .mkv  (GPU is ignored)
  Audio is always copied without re-encoding.

${C_BOLD}EXAMPLES${C_RESET}
  bash ${SCRIPT_NAME} /mnt/videos /mnt/output
  bash ${SCRIPT_NAME} /mnt/videos /mnt/output 1000
  bash ${SCRIPT_NAME} /mnt/videos /mnt/output 1000 -use_gpu
  bash ${SCRIPT_NAME} /mnt/videos /mnt/output -lossless
  bash ${SCRIPT_NAME} /mnt/videos /mnt/output 1000 -use_gpu -lossless

${C_BOLD}NOTES${C_RESET}
  The directory structure of input_dir is preserved in output_dir.
  Original files are never modified or deleted.
  Press Ctrl+C to abort; any incomplete output file will be removed.
EOF
}

# ------------------------------------------------------------------------------
# format_bytes <bytes> — print a human-readable size string
# Uses awk to avoid a dependency on bc.
# ------------------------------------------------------------------------------
format_bytes() {
    awk -v b="$1" 'BEGIN {
        if      (b >= 1073741824) printf "%.2f GB", b / 1073741824
        else if (b >= 1048576)   printf "%.2f MB", b / 1048576
        else if (b >= 1024)      printf "%.2f KB", b / 1024
        else                     printf "%d B",    b
    }'
}

# ------------------------------------------------------------------------------
# draw_progress <current> <total> — print a single progress bar line
# ------------------------------------------------------------------------------
draw_progress() {
    local cur=${1:-0} tot=${2:-0}
    local pct=0 filled=0 empty
    (( tot > 0 )) && pct=$(( 100 * cur / tot )) && filled=$(( BAR_WIDTH * cur / tot ))
    empty=$(( BAR_WIDTH - filled ))
    local bar
    bar="$(printf '%*s' "$filled" "" | tr ' ' '=')"
    bar+="$(printf '%*s' "$empty"  "")"
    printf "${C_CYAN}Progress: [%-${BAR_WIDTH}s] %3d%%  (%d/%d)${C_RESET}\n" \
        "$bar" "$pct" "$cur" "$tot"
}

# ------------------------------------------------------------------------------
# check_ffmpeg — exit 1 if ffmpeg is not found in PATH
# ------------------------------------------------------------------------------
check_ffmpeg() {
    if ! command -v ffmpeg > /dev/null 2>&1; then
        log_error "FFmpeg not found. Please install FFmpeg and add it to PATH."
        log_error "  Download: https://ffmpeg.org/download.html"
        exit 1
    fi
    log_info "FFmpeg: $(ffmpeg -version 2>&1 | head -1)"
}

# ------------------------------------------------------------------------------
# is_video_file <path> — return 0 if the file has a recognized video extension
# ------------------------------------------------------------------------------
is_video_file() {
    local ext="${1##*.}"
    ext="${ext,,}"    # convert to lowercase (requires Bash 4+)
    local e
    for e in $VIDEO_EXTS; do
        [[ "$ext" == "$e" ]] && return 0
    done
    return 1
}

# ------------------------------------------------------------------------------
# get_file_size <path> — print file size in bytes
# Tries Linux stat first, then macOS/BSD stat, then falls back to wc.
# ------------------------------------------------------------------------------
get_file_size() {
    stat -c '%s' "$1" 2>/dev/null   \
        || stat -f '%z' "$1" 2>/dev/null \
        || wc -c < "$1" 2>/dev/null      \
        || echo 0
}

# ------------------------------------------------------------------------------
# Signal handler — remove incomplete output file and exit cleanly on Ctrl+C
# ------------------------------------------------------------------------------
_CURRENT_OUTPUT=""
_PROCESSED=0

_cleanup() {
    printf "\n"
    log_warn "Interrupted by user (SIGINT). Aborting..."
    if [[ -n "${_CURRENT_OUTPUT}" && -f "${_CURRENT_OUTPUT}" ]]; then
        log_warn "Removing incomplete output file: ${_CURRENT_OUTPUT}"
        rm -f "${_CURRENT_OUTPUT}"
    fi
    log_warn "${_PROCESSED} file(s) fully processed before interruption."
    exit 130
}
trap _cleanup INT

# ==============================================================================
# Main entry point
# ==============================================================================
main() {
    # ── parse arguments ────────────────────────────────────────────────────────
    if [[ $# -lt 2 || "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        usage
        exit $(( $# < 2 ? 1 : 0 ))
    fi

    local input_dir="${1%/}"          # strip trailing slash for clean path joins
    local output_dir="${2%/}"
    shift 2

    local size_limit_mb="$DEFAULT_SIZE_MB"
    local use_gpu=0 lossless=0

    # Parse remaining optional arguments; flags and size_mb may appear in any order.
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -use_gpu|--use_gpu)     use_gpu=1          ;;
            -lossless|--lossless)   lossless=1         ;;
            [0-9]*)                 size_limit_mb="$1" ;;
            *) log_error "Unknown argument: '$1'"; usage; exit 1 ;;
        esac
        shift
    done

    # Validate size_limit_mb is a non-negative integer
    if ! [[ "$size_limit_mb" =~ ^[0-9]+$ ]]; then
        log_error "size_mb must be a non-negative integer (got: '${size_limit_mb}')"; exit 1
    fi

    # Validate input directory
    if [[ ! -d "$input_dir" ]]; then
        log_error "Input directory not found: ${input_dir}"; exit 1
    fi

    local size_bytes=$(( size_limit_mb * 1048576 ))

    # Lossless mode overrides GPU — GPU lossless encoding is unreliable
    if (( lossless && use_gpu )); then
        log_warn "Lossless mode enabled. GPU will not be used (falling back to CPU libx264)."
        use_gpu=0
    fi

    check_ffmpeg

    # If GPU mode is requested, verify h264_nvenc supports the p4 preset (added in FFmpeg 5.0).
    # Legacy GUID presets (default/medium/hq) are rejected by NVENC drivers >= 520;
    # new p1-p7 presets are not recognised by FFmpeg < 5.0.
    # Detect support at runtime and fall back to CPU if p4 is not listed.
    if (( use_gpu )); then
        if ! ffmpeg -hide_banner -h encoder=h264_nvenc 2>&1 | grep -qF ' p4'; then
            log_warn "GPU mode requires FFmpeg 5.0+ (h264_nvenc p4 preset not found in this build)."
            log_warn "Falling back to CPU encoding (libx264). Update FFmpeg to enable GPU support."
            use_gpu=0
        fi
    fi

    # Print configuration summary
    echo ""
    log_info "=== Video Compression Script ==="
    log_info "Input directory  : ${input_dir}"
    log_info "Output directory : ${output_dir}"
    log_info "Size filter      : > ${size_limit_mb} MB"
    if (( use_gpu )); then
        log_info "GPU acceleration : yes (NVIDIA NVENC — h264_nvenc)"
    else
        log_info "GPU acceleration : no  (CPU — libx264)"
    fi
    if (( lossless )); then
        log_info "Encoding mode    : lossless  (libx264 CRF 0 -> .mkv)"
    else
        log_info "Encoding mode    : lossy     (CRF/CQ 23 -> .mp4)"
    fi
    echo ""

    # ── step 1: discover matching video files ──────────────────────────────────
    log_info "Scanning '${input_dir}' for video files larger than ${size_limit_mb} MB..."

    local -a file_list=()
    local fp fsize
    # Use null-delimited output to safely handle filenames with spaces/newlines.
    # sort -z preserves null delimiters to keep the output deterministic.
    while IFS= read -r -d '' fp; do
        is_video_file "$fp" || continue
        fsize="$(get_file_size "$fp")"
        (( fsize > size_bytes )) && file_list+=("$fp")
    done < <(find "$input_dir" -type f -print0 | sort -z)

    local total=${#file_list[@]}
    if (( total == 0 )); then
        log_warn "No video files exceeding ${size_limit_mb} MB found in '${input_dir}'. Nothing to do."
        exit 0
    fi

    log_info "Found ${total} file(s) to process:"
    for fp in "${file_list[@]}"; do
        fsize="$(get_file_size "$fp")"
        log_info "  [$(format_bytes "$fsize")]  ${fp}"
    done
    echo ""

    # Create output root directory
    if ! mkdir -p "$output_dir"; then
        log_error "Cannot create output directory: ${output_dir}"; exit 1
    fi

    # ── step 2: compress each file ─────────────────────────────────────────────
    log_info "Starting compression of ${total} file(s)..."
    echo ""

    local current=0 success=0 failed=0
    local total_in=0 total_out=0
    local in_size out_size rel_path rel_dir base out_ext out_dir out_file saved pct
    local -a ffmpeg_args

    for fp in "${file_list[@]}"; do
        (( current++ )) || true

        # Print progress bar before each file block
        draw_progress "$current" "$total"

        in_size="$(get_file_size "$fp")"

        # Compute the relative path by stripping the input_dir prefix
        rel_path="${fp#${input_dir}/}"
        rel_dir="$(dirname "$rel_path")"
        base="$(basename "${fp%.*}")"

        if (( lossless )); then out_ext="mkv"; else out_ext="mp4"; fi

        out_dir="${output_dir}/${rel_dir}"
        out_file="${out_dir}/${base}.${out_ext}"
        _CURRENT_OUTPUT="$out_file"

        log_info "── File ${current}/${total} ──────────────────────────────────────────────────"
        log_info "  Input  : [$(format_bytes "$in_size")]  ${fp}"
        log_info "  Output : ${out_file}"

        # Create output subdirectory (mirrors the input structure)
        if ! mkdir -p "$out_dir"; then
            log_error "  Cannot create directory: ${out_dir}"
            (( failed++ )) || true
            _CURRENT_OUTPUT=""
            echo ""; continue
        fi

        # Build the FFmpeg argument list
        ffmpeg_args=("-y")                        # overwrite without prompting
        # NOTE: -hwaccel cuda is intentionally omitted. It mixes the CUDA decode context
        # with the NVENC encoder, which can trigger NV_ENC_ERR_UNSUPPORTED_PARAM on many GPUs.
        # GPU benefit comes from h264_nvenc (encoder); CPU decoding of the input is fast enough.
        ffmpeg_args+=("-i" "$fp")

        if (( lossless )); then
            # Lossless H.264: CRF 0 produces a mathematically lossless stream
            ffmpeg_args+=("-c:v" "libx264" "-preset" "medium" "-crf" "0")
        elif (( use_gpu )); then
            # Lossy NVENC: constqp (fixed-QP) with p4 preset.
            # NVENC SDK 12+ (driver >= 520) removed the old GUID-based presets (default/medium/hq).
            # Use the new performance presets p1-p7; p4 is the balanced equivalent of "medium".
            ffmpeg_args+=("-c:v" "h264_nvenc" "-preset" "p4" "-rc:v" "constqp" "-qp" "23")
        else
            # Lossy CPU: CRF 23 is the libx264 default and a good quality/size tradeoff
            ffmpeg_args+=("-c:v" "libx264" "-preset" "medium" "-crf" "23")
        fi
        # Copy audio without re-encoding to preserve quality and speed up processing
        ffmpeg_args+=("-c:a" "copy" "$out_file")

        # Run FFmpeg; suppress informational output, show only errors, and
        # display the one-line progress (frame/fps/time/speed) via -stats.
        # Each stats update uses CR (\r) to overwrite itself in-place.
        if ffmpeg "${ffmpeg_args[@]}" -loglevel error -stats 2>&1; then
            out_size="$(get_file_size "$out_file")"
            log_ok  "  Result : [$(format_bytes "$out_size")]  ${out_file}"

            saved=$(( in_size - out_size ))
            if (( saved > 0 && in_size > 0 )); then
                pct=$(( 100 * saved / in_size ))
                log_ok "  Saved  : $(format_bytes "$saved")  (${pct}% reduction)"
            else
                log_warn "  Note   : Output is not smaller than input. Consider adjusting settings."
            fi

            (( total_in  += in_size  )) || true
            (( total_out += out_size )) || true
            (( success++ ))            || true
            _PROCESSED=$success
        else
            log_error "  FFmpeg failed for: ${fp}"
            # Remove any partial/corrupt output file left by FFmpeg
            [[ -f "$out_file" ]] && rm -f "$out_file"
            (( failed++ )) || true
        fi

        _CURRENT_OUTPUT=""
        echo ""
    done

    # Print the final 100% progress bar
    draw_progress "$total" "$total"
    echo ""

    # ── summary ────────────────────────────────────────────────────────────────
    echo ""
    log_info "=== Summary ============================================"
    log_info "Processed successfully : ${success}"
    log_info "Failed                 : ${failed}"
    if (( success > 0 )); then
        log_info "Total input size       : $(format_bytes "$total_in")"
        log_info "Total output size      : $(format_bytes "$total_out")"
        local total_saved=$(( total_in - total_out ))
        if (( total_saved > 0 && total_in > 0 )); then
            local overall_pct=$(( 100 * total_saved / total_in ))
            log_ok  "Total saved            : $(format_bytes "$total_saved")  (${overall_pct}% overall reduction)"
        fi
    fi
    log_info "========================================================"
}

main "$@"
