#!/usr/bin/env bash
# Build SmallStep as a static library and install headers + lib into xenolexia-objc/include and xenolexia-objc/lib.
# Usage: ./scripts/install-smallstep.sh [path-to-SmallStep-repo]
#   If no path given, uses SMALLSTEP_SRC env or ../SmallStep (from xenolexia-objc).
# Run from xenolexia-objc root, or set XENOLEXIA_OBJC to xenolexia-objc root.

set -e
XENOLEXIA_OBJC="${XENOLEXIA_OBJC:-$(cd "$(dirname "$0")/.." && pwd)}"
SMALLSTEP_SRC="${1:-${SMALLSTEP_SRC:-$(cd "$XENOLEXIA_OBJC/../SmallStep" 2>/dev/null && pwd)}}"

if [ -z "$SMALLSTEP_SRC" ] || [ ! -d "$SMALLSTEP_SRC" ]; then
  echo "Usage: $0 [path-to-SmallStep-repo]" >&2
  echo "  Or set SMALLSTEP_SRC to the SmallStep source directory." >&2
  echo "  SmallStep not found at: ${1:-../SmallStep}" >&2
  exit 1
fi

echo "SmallStep source: $SMALLSTEP_SRC"
echo "Install target:   $XENOLEXIA_OBJC (include/ and lib/)"
mkdir -p "$XENOLEXIA_OBJC/include" "$XENOLEXIA_OBJC/lib"

# Source GNUStep env if available (for gnustep-config)
if [ -f /usr/share/GNUstep/Makefiles/GNUstep.sh ]; then
  . /usr/share/GNUstep/Makefiles/GNUstep.sh
fi

cd "$SMALLSTEP_SRC"
make -f Makefile.install clean 2>/dev/null || true
make -f Makefile.install install DESTDIR="$XENOLEXIA_OBJC"

echo "Done. Headers in $XENOLEXIA_OBJC/include, library in $XENOLEXIA_OBJC/lib"
