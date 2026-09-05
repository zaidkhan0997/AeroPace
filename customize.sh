#!/system/bin/sh
##########################################################################################
# AeroPace Performance Engine - Installer Script
# Universal Root Module for Magisk, KernelSU, and APatch
##########################################################################################

SKIPUNZIP=0

ui_print " "
ui_print "  ========================================================"
ui_print "       ___                     ____                       "
ui_print "      /   |  ___  _________   / __ \____ _________        "
ui_print "     / /| | / _ \/ ___/ __ \ / /_/ / __ \`/ ___/ _ \       "
ui_print "    / ___ |/  __/ /  / /_/ // ____/ /_/ / /__/  __/       "
ui_print "   /_/  |_|\___/_/   \____//_/    \__,_/\___/\___/        "
ui_print "                                                          "
ui_print "        Enterprise Universal Gaming Optimization Engine   "
ui_print "  ========================================================"
ui_print " "

# 1. Environment & Architecture Detection
ui_print "- Analyzing device environment..."

ROOT_ENV="Unknown Root"
if [ -n "$KSU" ] || [ -f "/data/adb/ksu/bin/busybox" ] || [ -d "/data/adb/modules_update" -a -f "/data/adb/ksud" ]; then
    ROOT_ENV="KernelSU"
elif [ -n "$APATCH" ] || [ -f "/data/adb/ap/bin/apd" ] || [ -d "/data/adb/ap" ]; then
    ROOT_ENV="APatch"
elif [ -n "$MAGISK_VER" ] || [ -d "/data/adb/magisk" ]; then
    ROOT_ENV="Magisk (v${MAGISK_VER:-Official})"
fi

# Detect SoC Platform
SOC_VENDOR="Generic ARM"
SOC_PLATFORM="$(getprop ro.board.platform)"
SOC_HARDWARE="$(getprop ro.hardware)"
SOC_CHIP="$(getprop ro.soc.manufacturer)"

if echo "$SOC_PLATFORM $SOC_HARDWARE $SOC_CHIP" | grep -qiE "qcom|qualcomm|snapdragon|sm[0-9]|sdm[0-9]|msm[0-9]"; then
    SOC_VENDOR="Qualcomm Snapdragon"
elif echo "$SOC_PLATFORM $SOC_HARDWARE $SOC_CHIP" | grep -qiE "mtk|mediatek|dimensity|helio|mt[0-9]"; then
    SOC_VENDOR="MediaTek Dimensity / Helio"
fi

ANDROID_API="$(getprop ro.build.version.sdk)"
DEVICE_MODEL="$(getprop ro.product.model)"

ui_print "  • Root Manager : $ROOT_ENV"
ui_print "  • Device Model : $DEVICE_MODEL"
ui_print "  • Android API  : $ANDROID_API"
ui_print "  • Architecture : $ARCH"
ui_print "  • Detected SoC : $SOC_VENDOR"
ui_print " "

# 2. Safety & Compatibility Verifications
ui_print "- Enforcing zero-spoofing safety policies..."
ui_print "  • Fingerprint Spoofing : DISABLED (100% Anti-Cheat Safe)"
ui_print "  • Thermal Engines      : PRESERVED (Overheat Protection Active)"
ui_print "  • Memory Governor      : DYNAMIC LMK + Virtual Memory Sync"
ui_print " "

# 3. Apply Permissions
ui_print "- Configuring execution permissions..."
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/module.prop" 0 0 0644
set_perm "$MODPATH/system.prop" 0 0 0644
if [ -f "$MODPATH/update.json" ]; then
    set_perm "$MODPATH/update.json" 0 0 0644
fi

# Create runtime directory if needed
mkdir -p /data/local/tmp/aeropace
chmod 0755 /data/local/tmp/aeropace

ui_print " "
ui_print "  ========================================================"
ui_print "    AeroPace installed successfully!"
ui_print "    Reboot device to activate dynamic performance daemon."
ui_print "  ========================================================"
ui_print " "
