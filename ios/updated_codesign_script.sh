#!/bin/bash
set -e

echo "Signing embedded Python modules..."

# Look for python-stdlib in multiple possible locations
POSSIBLE_PATHS=(
    "$CODESIGNING_FOLDER_PATH/python-stdlib"
    "$BUILT_PRODUCTS_DIR/python-stdlib"
    "$CONFIGURATION_BUILD_DIR/python-stdlib"
)

FOUND_PATH=""
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$path" ]; then
        echo "🔍 Found python-stdlib at: $path"
        FOUND_PATH="$path"
        break
    fi
done

if [ -n "$FOUND_PATH" ] && [ -d "$FOUND_PATH/lib-dynload" ]; then
    echo "🔍 Found lib-dynload at: $FOUND_PATH/lib-dynload"
    find "$FOUND_PATH/lib-dynload" -name "*.so" -exec /usr/bin/codesign --force --sign "$EXPANDED_CODE_SIGN_IDENTITY" --timestamp=none --preserve-metadata=identifier,entitlements,flags {} \;
    echo "✅ Python modules signed successfully"
else
    echo "⚠️  python-stdlib/lib-dynload not found in any of these locations:"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "   - $path"
    done
    echo "   This is normal if python-stdlib is not properly added to Copy Bundle Resources"
    echo "   or if the script runs before the resources are copied"
fi 