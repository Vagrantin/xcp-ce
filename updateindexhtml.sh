#!/bin/bash
grep -Irl 'lite\.xen-orchestra\.com' . | head -n 1 | xargs -r sed -i -e '/try {/,/\/\/ Fallback to local version of XO Lite/d' -e '/^        }$/d'
