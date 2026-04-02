#!/bin/bash
grep -Irl 'xoa\.io' . --include='*.js' | head -n 1 | xargs -r sed -i 's|http://xoa.io/xva|https://xo-image.yawn.fi/downloads/image.xva.gz|g'
grep -Irl 'lite\.xen-orchestra\.com' . | head -n 1 | xargs -r sed -i -e '/try {/,/\/\/ Fallback to local version of XO Lite/d' -e '/^        }$/d'
