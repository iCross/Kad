#!/bin/bash

BUILD_DIR=${1:-"build"}
cd "$BUILD_DIR" || exit 1

JOBS=${2:-4}

echo "Starting build with -j${JOBS} parallel jobs..."
cmake --build . --verbose -- -j${JOBS} || true

find . -name link.txt -type f | while read -r file; do
  if grep -q -- "-static-libgcc\|-static-libstdc++" "$file"; then
    echo "Fixing $file..."
    sed -i '' -E 's/-static-libgcc[[:space:]]*//g; s/-static-libstdc\+\+[[:space:]]*//g' "$file"
  fi
done

echo "Continuing build with -j${JOBS} parallel jobs..."
cmake --build . --verbose -- -j${JOBS}
