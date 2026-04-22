#!/usr/bin/env bash
set -euo pipefail

# Budget Beacon - Advanced Host Installer
# Designed for SavigeSystemZ distribution standards.

APP_NAME="BudgetBeacon"
INSTALL_DIR="/home/whyte/.MyAppZ/BudgetBeacon"
BIN_NAME="budget-beacon"
LOCAL_BIN="/home/whyte/.local/bin"

echo "=========================================="
echo "   Budget Beacon - System Installer"
echo "=========================================="

# 1. Dependency Check
echo "Checking dependencies..."
if ! command -v node &> /dev/null; then
    echo "Error: Node.js is not installed. Please install Node.js >= 18."
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "Error: npm is not installed."
    exit 1
fi

# 2. Build Application
echo "Building production assets..."
cd "$INSTALL_DIR"
export npm_config_cache="$INSTALL_DIR/.npm-cache"
npm install --silent --legacy-peer-deps
npm run build --silent

# 3. Create Local Launcher
echo "Configuring local execution..."
mkdir -p "$LOCAL_BIN"

cat > "$LOCAL_BIN/$BIN_NAME" <<EOF
#!/usr/bin/env bash
# Budget Beacon Runner
cd "$INSTALL_DIR"
npm run dev -- --open
EOF

chmod +x "$LOCAL_BIN/$BIN_NAME"

# 4. Create Desktop Entry
echo "Creating desktop entry..."
DESKTOP_DIR="/home/whyte/.local/share/applications"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/budget-beacon.desktop" <<EOF
[Desktop Entry]
Name=Budget Beacon
Comment=Private local-first budgeting cockpit
Exec=$LOCAL_BIN/$BIN_NAME
Icon=$INSTALL_DIR/public/vite.svg
Terminal=false
Type=Application
Categories=Office;Finance;
EOF

echo "------------------------------------------"
echo "Installation Complete!"
echo "------------------------------------------"
echo "You can now run Budget Beacon by typing:"
echo "  $BIN_NAME"
echo ""
echo "Or find it in your application menu."
echo "=========================================="
