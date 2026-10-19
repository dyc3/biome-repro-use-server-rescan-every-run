#!/usr/bin/env bash
# Usage: ./repro.sh [runs]
# Set BIOME to the Biome binary to test; defaults to `biome` on the PATH.
set -eu
cd "$(dirname "$0")"
RUNS=${1:-8}
BIOME=$(command -v "${BIOME:-biome}")

# A private cache directory gives this daemon its own socket, so the script
# neither talks to nor disturbs a daemon started by an editor. It lives in the
# temporary directory because socket paths must be shorter than about 100 bytes.
CACHE=$(mktemp -d "${TMPDIR:-/tmp}/biome-repro.XXXXXX")
export XDG_CACHE_HOME="$CACHE"

echo "biome: $BIOME ($("$BIOME" --version))"
echo "in-process:"
"$BIOME" check --verbose . 2>&1 | grep -E "^(Scanned|Checked)" | sed 's/^/  /' || true

"$BIOME" __run_server >/dev/null 2>&1 &
DAEMON=$!
trap 'kill "$DAEMON" 2>/dev/null || true; rm -rf "$CACHE"' EXIT
for _ in $(seq 100); do
  ls "$CACHE"/biome/biome-daemon/biome-socket-* >/dev/null 2>&1 && break
  sleep 0.1
done
ls "$CACHE"/biome/biome-daemon/biome-socket-* >/dev/null 2>&1 || { echo "the daemon didn't open its socket"; exit 1; }
rss_mb() { echo $(( $(ps -o rss= -p "$DAEMON") / 1024 )); }

echo "daemon (pid $DAEMON), RSS before the first run: $(rss_mb) MB"
for i in $(seq 1 "$RUNS"); do
  summary=$("$BIOME" check --use-server --verbose . 2>&1 | grep -E "^(Scanned|Checked)" | tr '\n' ' ' || true)
  echo "  run $i: ${summary}daemon RSS: $(rss_mb) MB"
done
"$BIOME" stop >/dev/null 2>&1 || true
