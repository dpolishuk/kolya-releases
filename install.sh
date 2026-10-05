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
 kolya_version='v0.1.0-rc.6'
 case "$kolya_version" in *@*) printf '%s\n' 'error=INSTALL_UNRENDERED_RELEASE: use the generated public release installer.' >&2; return 1;; esac
 case "$(uname -s)" in Linux) kolya_os=linux;; Darwin) kolya_os=darwin;; *) printf '%s\n' 'error=INSTALL_PLATFORM_UNSUPPORTED' >&2; return 1;; esac
 case "$(uname -m)" in x86_64|amd64) kolya_arch=amd64;; aarch64|arm64) kolya_arch=arm64;; *) printf '%s\n' 'error=INSTALL_PLATFORM_UNSUPPORTED' >&2; return 1;; esac
 case "$kolya_os-$kolya_arch" in
  linux-amd64) kolya_sha='730818af5eaa1f3107349fe67b3245ef1bea17845f8891bd4359ec9089175e28';;
  linux-arm64) kolya_sha='e0df4b5ccf9fdc578e29e885b5bde0ee7abc55404a2cbcedce9b12d6a3c7fa35';;
  darwin-amd64) kolya_sha='86696eb51ffb877f353f06239830313bab3d5c4e62f2de56ce98ba474b1cd883';;
  darwin-arm64) kolya_sha='42b7391b57ce06c32c7ce87b7c4cbd2525c0db0c3833eb61b869da975e293456';;
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
 if ! curl -q --fail --silent --show-error --location --proto '=https' --proto-redir '=https' --tlsv1.2 --connect-timeout 10 --max-time 180 --retry 2 --retry-max-time 240 --max-filesize 268435456 --output "$kolya_tmp/kolya-agent" "$kolya_url"; then
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
