#!/bin/bash
' --------------------------------------------------------------------------------------------'
# Use of this script

# Make the script executable:
# chmod +x build_patched_gasket_with_debuild.sh

# Run the script:
# ./build_patched_gasket_with_debuild.sh

# This script automates the process of downloading, patching, and building the Gasket DKMS driver
# for newer kernels. It also provides an option to install the patched package and load the necessary kernel modules.
# Ensure you have the necessary dependencies installed:
# sudo apt-get install -y devscripts fakeroot
# This script is intended for educational purposes and should be used with caution.
# It is recommended to test the patched driver in a safe environment before deploying it in production.
# This script is provided "as is" without warranty of any kind. Use at your own risk.   
' --------------------------------------------------------------------------------------------'

set -e

ORIG_REPO_URL="https://github.com/google/gasket-driver.git"
WORKDIR="$HOME/gasket-deb"
PATCHED_DEB="gasket-dkms_1.0-18_all.deb"
SRCDIR="$WORKDIR/gasket-driver"

echo "📥 Klone Repository..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"
git clone "$ORIG_REPO_URL"
cd "$SRCDIR"

echo "🩹 Wende Patch an..."
TARGET_FILE="$SRCDIR/src/gasket_core.c"
if grep -q "\.llseek = no_llseek" "$TARGET_FILE"; then
    sed -i 's/\.llseek = no_llseek/\.llseek = noop_llseek/g' "$TARGET_FILE"
    echo "✅ Patch angewendet."
else
    echo "⚠️ Kein Patch notwendig – Code bereits angepasst?"
fi

echo "📝 Aktualisiere Paket-Metadaten..."
# Optional: Passen Sie die Version und Beschreibung an
sed -i 's/^Version: .*/Version: 1.0-18patched/' "$SRCDIR/debian/control"
sed -i 's/^Description:.*/Description: Patched Gasket DKMS driver for newer kernels/' "$SRCDIR/debian/control"

echo "🔧 Baue gepatchtes Paket mit debuild..."
# Baue das Paket mit debuild
sudo apt-get install -y devscripts fakeroot
debuild -us -uc -tc -b

echo "📁 Fertig: $WORKDIR/$PATCHED_DEB"

read -p "❓ Möchtest du das neue Paket jetzt installieren? [j/N]: " choice
if [[ "$choice" =~ ^[JjYy]$ ]]; then
    echo "🚀 Installiere..."
    sudo dpkg -i "$WORKDIR/$PATCHED_DEB"
    echo "✅ Installation abgeschlossen!"
    
    echo "🔌 Lade Kernel-Module..."
    sudo modprobe gasket
    if [ $? -eq 0 ]; then
        echo "✅ Modul 'gasket' erfolgreich geladen."
    else
        echo "⚠️ Fehler beim Laden von 'gasket'."
    fi
    
    sudo modprobe apex
    if [ $? -eq 0 ]; then
        echo "✅ Modul 'apex' erfolgreich geladen."
    else
        echo "⚠️ Fehler beim Laden von 'apex'."
    fi
else
    echo "ℹ️ Du kannst es später installieren mit:"
    echo "   sudo dpkg -i $WORKDIR/$PATCHED_DEB"
fi
echo "🔚 Skript beendet."

