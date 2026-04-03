#!/bin/bash
set -euo pipefail

SEARCH_ROOT="${RPM_BUILD_ROOT:-.}"

echo "Buildroot received: ${SEARCH_ROOT}"

JS_FILE=$(grep -Irl 'xoa\.io' "${SEARCH_ROOT}" --include='*.js' | head -n 1)

if [[ -z "${JS_FILE}" ]]; then
  echo "Could not find JS file containing xoa.io"
  exit 1
fi

echo "Patching: ${JS_FILE}"
sed -i 's|http://xoa.io/xva|http://192.168.0.1:3000/image.xva.gz|g' "${JS_FILE}"

grep -Irl 'lite\.xen-orchestra\.com' "${SEARCH_ROOT}" | head -n 1 | \
  xargs -r sed -i \
    -e '/try {/,/\/\/ Fallback to local version of XO Lite/d' \
    -e '/^        }$/d'

echo "Done"
