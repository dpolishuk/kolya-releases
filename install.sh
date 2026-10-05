#!/bin/sh
# Release template. scripts/package-release.py replaces every @...@ value.
# Only the rendered script in dpolishuk/kolya-releases is a public entry point.
# Keep all work inside main: a truncated curl stream cannot execute a prefix.
kolya_main() {
 set -eu
 umask 077
 unset IFS
 CDPATH=
 export CDPATH
 case "${1:-}" in
  --help|-h) printf '%s\n' 'Kolya: install [--root PATH] [--no-onboard] [--plain]' 'Requires curl and sha256sum or shasum. Linux/macOS amd64/arm64.'; return 0 ;;
 esac
 kolya_version='v0.1.0-rc.11'
 case "$kolya_version" in *@*) printf '%s\n' 'error=INSTALL_UNRENDERED_RELEASE: use the generated public release installer.' >&2; return 1;; esac
 case "$(uname -s)" in Linux) kolya_os=linux;; Darwin) kolya_os=darwin;; *) printf '%s\n' 'error=INSTALL_PLATFORM_UNSUPPORTED' >&2; return 1;; esac
 case "$(uname -m)" in x86_64|amd64) kolya_arch=amd64;; aarch64|arm64) kolya_arch=arm64;; *) printf '%s\n' 'error=INSTALL_PLATFORM_UNSUPPORTED' >&2; return 1;; esac
 case "$kolya_os-$kolya_arch" in
  linux-amd64) kolya_sha='7825488cd956c4cc224765d7c6c33926b1b0ad10ce5b7db86c6a7d0d24f1091f';;
  linux-arm64) kolya_sha='621d68ee8d63794b3cbba7891eade4694e0af3e3e2673e92f73b2d5fd33b766e';;
  darwin-amd64) kolya_sha='747bcfdc2c1c265962209e7bb607b22bc7e45039f273b2a3931927ad1c990057';;
  darwin-arm64) kolya_sha='d475d638b082aac75741a02d8ecb2dd11e28b99b92a2f7a5ef7db0035dc4f283';;
 esac
 case "$kolya_sha" in ''|*[!0-9a-f]*) printf '%s\n' 'error=INSTALL_UNRENDERED_RELEASE' >&2; return 1;; esac
 [ "${#kolya_sha}" -eq 64 ] || return 1
 command -v curl >/dev/null 2>&1 || { printf '%s\n' 'error=INSTALL_CURL_REQUIRED' >&2; return 1; }
 if command -v sha256sum >/dev/null 2>&1; then kolya_hasher=sha256sum
 elif command -v shasum >/dev/null 2>&1; then kolya_hasher=shasum
 else printf '%s\n' 'error=INSTALL_SHA256_REQUIRED' >&2; return 1; fi
 kolya_tmp_base=$(cd "${TMPDIR:-/tmp}" && pwd -P) || return 1
 kolya_tmp=$(mktemp -d "$kolya_tmp_base/kolya-download.XXXXXXXX") || return 1
 trap 'rm -f "$kolya_tmp/kolya-agent"; rmdir "$kolya_tmp" 2>/dev/null || :' EXIT
 trap 'exit 130' INT
 trap 'exit 143' TERM HUP
 kolya_url="https://github.com/dpolishuk/kolya-releases/releases/download/$kolya_version/kolya-agent-$kolya_os-$kolya_arch"
 if ! (
  # Older curl only checks known Content-Length. Bound writes during download,
  # leaving the installer/program's limits intact. Shell blocks are 512/1024
  # bytes: 262144 blocks never exceed 256MiB. Preserve any lower inherited limit.
  kolya_file_limit=$(ulimit -f) || exit 1
  case "$kolya_file_limit" in
   unlimited) kolya_file_limit=262144;;
   ''|*[!0-9]*) exit 1;;
   *) [ "$kolya_file_limit" -le 262144 ] || kolya_file_limit=262144;;
  esac
  # SIGXFSZ must not leave a core dump when an oversized write is refused.
  ulimit -c 0 || exit 1
  ulimit -f "$kolya_file_limit" || exit 1
  kolya_applied_limit=$(ulimit -f) || exit 1
  case "$kolya_applied_limit" in ''|*[!0-9]*) exit 1;; esac
  [ "$kolya_applied_limit" -le "$kolya_file_limit" ] || exit 1
  curl -q --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 10 --max-time 180 --retry 2 --retry-max-time 240 --max-filesize 268435456 --output "$kolya_tmp/kolya-agent" "$kolya_url"
 ); then
  printf '%s\n' 'error=INSTALL_DOWNLOAD_FAILED: rerun the installer after checking your connection.' >&2; return 1
 fi
 if [ "$kolya_hasher" = sha256sum ]; then kolya_actual=$(sha256sum "$kolya_tmp/kolya-agent")
 else kolya_actual=$(shasum -a 256 "$kolya_tmp/kolya-agent"); fi
 kolya_actual=${kolya_actual%% *}
 [ "$kolya_actual" = "$kolya_sha" ] || { printf '%s\n' 'error=INSTALL_CHECKSUM_MISMATCH: downloaded program was not executed.' >&2; return 1; }
 chmod 700 "$kolya_tmp/kolya-agent"
 # Do not exec: EXIT must remove the downloaded temporary executable.
 "$kolya_tmp/kolya-agent" install "$@"
}
kolya_main "$@"
