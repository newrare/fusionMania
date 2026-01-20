#!/bin/bash

# Quick test script to verify Fusion Mania setup

echo "🚀 Testing Fusion Mania Project Setup..."
echo ""

cd "$(dirname "$0")"

# Check if godot is available
if ! command -v godot &> /dev/null; then
    echo "❌ Godot not found in PATH"
    exit 1
fi

echo "✅ Godot found"

# Check required files
echo ""
echo "📋 Checking project files..."

required_files=(
    "project.godot"
    "managers/AudioManager.gd"
    "managers/LanguageManager.gd"
    "managers/ScoreManager.gd"
    "managers/GameManager.gd"
    "managers/GridManager.gd"
    "managers/PowerManager.gd"
    "managers/SaveManager.gd"
    "managers/ToolsManager.gd"
    "scenes/GameScene.tscn"
    "scenes/GameScene.gd"
)

missing_files=0

for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (MISSING)"
        missing_files=$((missing_files + 1))
    fi
done

if [ $missing_files -gt 0 ]; then
    echo ""
    echo "❌ $missing_files file(s) missing!"
    exit 1
fi

echo ""
echo "📂 Checking directory structure..."

required_dirs=(
    "managers"
    "assets"
    "assets/sounds"
    "assets/images"
    "assets/icons"
    "objects"
    "overlays"
    "widgets"
    "visuals"
    "scenes"
)

missing_dirs=0

for dir in "${required_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "  ✅ $dir"
    else
        echo "  ❌ $dir (MISSING)"
        missing_dirs=$((missing_dirs + 1))
    fi
done

if [ $missing_dirs -gt 0 ]; then
    echo ""
    echo "❌ $missing_dirs directory(ies) missing!"
    exit 1
fi

echo ""
echo "✅ All files and directories found!"
echo ""
echo "🎮 Running Godot test (headless)..."
echo ""

timeout 10 godot --headless 2>&1 | grep -E "(^(🎵|🌍|🏆|🎯|🎲|⚡|💾|🔧|===)|ERROR:)"

echo ""
echo "✅ Setup verification complete!"
