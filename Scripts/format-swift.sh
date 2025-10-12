#!/bin/bash

cd "$(dirname "$0")/.."

SOURCE_DIRS=(
  "CSUSTPlanet"
  "CSUSTPlanetWidget"
)

echo "开始格式化以下目录中的 Swift 文件: ${SOURCE_DIRS[*]}"

swift-format format --recursive --in-place "${SOURCE_DIRS[@]}"

echo "项目 Swift 文件格式化完毕。"
