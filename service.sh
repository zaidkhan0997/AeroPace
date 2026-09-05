#!/system/bin/sh
##########################################################################################
# AeroPace Performance Engine - State-Managed Background Daemon
# Universal Root Gaming Optimization & Thermal Guard
# Target architectures: Qualcomm Snapdragon & MediaTek Dimensity/Helio
##########################################################################################

MODDIR=${0%/*}
LOG_DIR="/data/local/tmp/aeropace"
LOG_FILE="$LOG_DIR/daemon.log"
mkdir -p "$LOG_DIR"

log_info() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [AeroPace] $1"
    echo "$msg" >> "$LOG_FILE"
    # Keep log file bounded to 500 lines max
    if [ -f "$LOG_FILE" ] && [ "$(wc -l < "$LOG_FILE" 2>/dev/null || echo 0)" -gt 500 ]; then
        tail -n 250 "$LOG_FILE" > "$LOG_FILE.tmp" 2>/dev/null && mv "$LOG_FILE.tmp" "$LOG_FILE"
    fi
}

log_info "AeroPace Daemon initializing..."

# 1. Wait for Android boot completion
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 3
done

# Allow core system services to stabilize
sleep 10
log_info "Android boot completed. Initializing performance baseline..."

# 2. Target Competitive Gaming Packages
TARGET_PACKAGES="com.pubg.imobile com.tencent.ig com.pubg.krmobile com.vng.pubgmobile"

# 3. Detect Platform Architecture
SOC_PLATFORM="$(getprop ro.board.platform)"
SOC_HARDWARE="$(getprop ro.hardware)"
SOC_CHIP="$(getprop ro.soc.manufacturer)"
ARCH_TYPE="GENERIC"

if echo "$SOC_PLATFORM $SOC_HARDWARE $SOC_CHIP" | grep -qiE "qcom|qualcomm|snapdragon|sm[0-9]|sdm[0-9]|msm[0-9]"; then
    ARCH_TYPE="QUALCOMM"
elif echo "$SOC_PLATFORM $SOC_HARDWARE $SOC_CHIP" | grep -qiE "mtk|mediatek|dimensity|helio|mt[0-9]"; then
    ARCH_TYPE="MEDIATEK"
fi
log_info "Detected Hardware Architecture: $ARCH_TYPE"

# 4. Capture Boot Baseline Snapshots for 100% Clean Restore
SNAPSHOT_DIR="$LOG_DIR/snapshot"
mkdir -p "$SNAPSHOT_DIR"

# Snapshot VM parameters
SNAP_VFS_CACHE_PRESSURE="$(cat /proc/sys/vm/vfs_cache_pressure 2>/dev/null || echo 100)"
SNAP_DIRTY_RATIO="$(cat /proc/sys/vm/dirty_ratio 2>/dev/null || echo 20)"
SNAP_DIRTY_BG_RATIO="$(cat /proc/sys/vm/dirty_background_ratio 2>/dev/null || echo 10)"

# Snapshot Network parameters
SNAP_TCP_LOW_LATENCY="$(cat /proc/sys/net/ipv4/tcp_low_latency 2>/dev/null || echo 0)"
SNAP_TCP_SLOW_START="$(cat /proc/sys/net/ipv4/tcp_slow_start_after_idle 2>/dev/null || echo 1)"
SNAP_TCP_NOTSENT_LOWAT="$(cat /proc/sys/net/ipv4/tcp_notsent_lowat 2>/dev/null || echo 4294967295)"

# Snapshot CPU Governors per policy
for policy in /sys/devices/system/cpu/cpufreq/policy*; do
    if [ -d "$policy" ]; then
        pol_name=$(basename "$policy")
        cat "$policy/scaling_governor" 2>/dev/null > "$SNAPSHOT_DIR/gov_${pol_name}"
    fi
done

# Fallback for older kernels without policy abstraction
for cpu_gov in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
    if [ -f "$cpu_gov" ]; then
        cpu_name=$(echo "$cpu_gov" | awk -F'/' '{print $(NF-2)}')
        cat "$cpu_gov" 2>/dev/null > "$SNAPSHOT_DIR/gov_${cpu_name}"
    fi
done

# Snapshot Qualcomm GPU governor if present
if [ -f "/sys/class/kgsl/kgsl-3d0/devfreq/governor" ]; then
    cat "/sys/class/kgsl/kgsl-3d0/devfreq/governor" 2>/dev/null > "$SNAPSHOT_DIR/adreno_gov"
fi

log_info "Baseline snapshot saved successfully."

# State tracking variables
CURRENT_STATE="IDLE"
THERMAL_THROTTLED=0
ACTIVE_GAME_PACKAGE=""
ACTIVE_GAME_PID=""

# 5. Helper Functions

# Helper to write to sysfs safely
safe_write() {
    local val="$1"
    local path="$2"
    if [ -f "$path" ]; then
        chmod 0664 "$path" 2>/dev/null
        echo "$val" > "$path" 2>/dev/null
    fi
}

# Function to detect currently focused package across Android 11 to 15
get_focused_package() {
    local pkg=""
    
    # Method 1: dumpsys window (Fastest & most accurate across Android 11-14)
    pkg=$(dumpsys window 2>/dev/null | grep -E 'mCurrentFocus|mFocusedApp|mFocusedWindow' | head -n 1 | sed -n 's/.*\([a-zA-Z0-9_.]*\)\/\([a-zA-Z0-9_.]*\).*/\1/p')
    
    # Method 2: cmd activity (Android 12-15 fallback)
    if [ -z "$pkg" ]; then
        pkg=$(cmd activity activities 2>/dev/null | grep -E 'ResumedActivity|mResumedActivity' | head -n 1 | sed -n 's/.*\([a-zA-Z0-9_.]*\)\/\([a-zA-Z0-9_.]*\).*/\1/p')
    fi
    
    # Method 3: dumpsys activity fallback
    if [ -z "$pkg" ]; then
        pkg=$(dumpsys activity activities 2>/dev/null | grep -E 'mResumedActivity' | head -n 1 | sed -n 's/.*\([a-zA-Z0-9_.]*\)\/\([a-zA-Z0-9_.]*\).*/\1/p')
    fi

    echo "$pkg"
}

# Function to read peak thermal temperatures
# Returns status: 1 if overheating (>43°C battery or >75°C SoC), 0 if safe
check_thermal_status() {
    local max_soc_temp=0
    local max_bat_temp=0
    
    for zone in /sys/class/thermal/thermal_zone*; do
        if [ -d "$zone" ]; then
            local ztype=""
            local ztemp=0
            ztype=$(cat "$zone/type" 2>/dev/null | tr '[:upper:]' '[:lower:]')
            ztemp=$(cat "$zone/temp" 2>/dev/null || echo 0)
            
            # Normalize milli-celsius if temp > 1000
            if [ "$ztemp" -gt 10000 ]; then
                ztemp=$((ztemp / 1000))
            fi
            
            # Battery zone check
            if echo "$ztype" | grep -qE "bat|battery"; then
                if [ "$ztemp" -gt "$max_bat_temp" ]; then
                    max_bat_temp=$ztemp
                fi
            fi
            
            # SoC / CPU zone check
            if echo "$ztype" | grep -qE "soc|cpu|tsens|ap|cluster|bcl"; then
                if [ "$ztemp" -gt "$max_soc_temp" ]; then
                    max_soc_temp=$ztemp
                fi
            fi
        fi
    done
    
    # Overheat thresholds: Battery > 43°C or SoC > 75°C
    if [ "$max_bat_temp" -gt 43 ] || [ "$max_soc_temp" -gt 75 ]; then
        echo "HOT $max_bat_temp $max_soc_temp"
    elif [ "$max_bat_temp" -lt 40 ] && [ "$max_soc_temp" -lt 68 ]; then
        echo "COOL $max_bat_temp $max_soc_temp"
    else
        echo "NORMAL $max_bat_temp $max_soc_temp"
    fi
}

# Apply CPU Governors
set_cpu_governors() {
    local target_gov="$1"
    for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        if [ -d "$policy" ]; then
            local avail_govs
            avail_govs=$(cat "$policy/scaling_available_governors" 2>/dev/null)
            if echo "$avail_govs" | grep -qw "$target_gov"; then
                safe_write "$target_gov" "$policy/scaling_governor"
            elif echo "$avail_govs" | grep -qw "schedutil"; then
                safe_write "schedutil" "$policy/scaling_governor"
            fi
        fi
    done
    
    for cpu_gov in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_governor; do
        if [ -f "$cpu_gov" ]; then
            safe_write "$target_gov" "$cpu_gov"
        fi
    done
}

# Restore Baseline CPU Governors
restore_cpu_governors() {
    for snap_file in "$SNAPSHOT_DIR"/gov_policy*; do
        if [ -f "$snap_file" ]; then
            local pol_name
            pol_name=$(basename "$snap_file" | sed 's/gov_//')
            local orig_gov
            orig_gov=$(cat "$snap_file" 2>/dev/null)
            if [ -n "$orig_gov" ] && [ -d "/sys/devices/system/cpu/cpufreq/$pol_name" ]; then
                safe_write "$orig_gov" "/sys/devices/system/cpu/cpufreq/$pol_name/scaling_governor"
            fi
        fi
    done
    
    for snap_file in "$SNAPSHOT_DIR"/gov_cpu*; do
        if [ -f "$snap_file" ]; then
            local cpu_name
            cpu_name=$(basename "$snap_file" | sed 's/gov_//')
            local orig_gov
            orig_gov=$(cat "$snap_file" 2>/dev/null)
            if [ -n "$orig_gov" ] && [ -f "/sys/devices/system/cpu/$cpu_name/cpufreq/scaling_governor" ]; then
                safe_write "$orig_gov" "/sys/devices/system/cpu/$cpu_name/cpufreq/scaling_governor"
            fi
        fi
    done
}

# 6. Gameplay Boost Activation
apply_game_boost() {
    local pkg="$1"
    log_info "Entering GAMEPLAY mode for package: $pkg"
    
    # 6.1 Process Priority & Task Scheduling
    local pids
    pids=$(pidof "$pkg" 2>/dev/null)
    if [ -z "$pids" ]; then
        pids=$(pgrep -f "$pkg" 2>/dev/null)
    fi
    
    for pid in $pids; do
        ACTIVE_GAME_PID="$pid"
        # Renice to maximum interactive priority (-20)
        renice -n -20 -p "$pid" 2>/dev/null
        
        # Shield from Android LowMemoryKiller (LMK)
        safe_write "-1000" "/proc/$pid/oom_score_adj"
        
        # Assign to top-app cpuset & schedtune / uclamp
        safe_write "$pid" "/dev/cpuset/top-app/tasks"
        safe_write "$pid" "/dev/stune/top-app/tasks"
        safe_write "$pid" "/sys/fs/cgroup/top-app/cgroup.procs"
        
        # Sched latency tuning for game PID
        safe_write "100" "/dev/stune/top-app/schedtune.boost"
        safe_write "1" "/dev/stune/top-app/schedtune.prefer_idle"
    done
    
    # 6.2 Safe Linux Virtual Memory (VM) Tuning
    # Prevent page thrashing and micro-stutters from inode/dentry bloat
    safe_write "100" "/proc/sys/vm/vfs_cache_pressure"
    safe_write "10" "/proc/sys/vm/dirty_ratio"
    safe_write "5" "/proc/sys/vm/dirty_background_ratio"
    
    # Non-blocking background sync & drop_caches on game entry only
    (sync; echo 3 > /proc/sys/vm/drop_caches) 2>/dev/null &
    
    # 6.3 Low-Latency Network Tuning
    safe_write "1" "/proc/sys/net/ipv4/tcp_low_latency"
    safe_write "0" "/proc/sys/net/ipv4/tcp_slow_start_after_idle"
    safe_write "16384" "/proc/sys/net/ipv4/tcp_notsent_lowat"
    
    # 6.4 Architecture-Specific Tuning
    if [ "$ARCH_TYPE" = "QUALCOMM" ]; then
        # Qualcomm Snapdragon & Adreno Boost
        set_cpu_governors "performance"
        
        # Adreno GPU Devfreq & Bus Scaling
        safe_write "performance" "/sys/class/kgsl/kgsl-3d0/devfreq/governor"
        safe_write "1" "/sys/class/kgsl/kgsl-3d0/force_bus_on"
        safe_write "1" "/sys/class/kgsl/kgsl-3d0/force_clk_on"
        safe_write "1" "/sys/class/kgsl/kgsl-3d0/force_rail_on"
        safe_write "0" "/sys/class/kgsl/kgsl-3d0/bus_split"
        safe_write "0" "/sys/class/kgsl/kgsl-3d0/throttling"
        
        # MSM Performance nodes
        safe_write "1" "/sys/module/msm_performance/parameters/touchboost"
        safe_write "0" "/sys/module/cpu_boost/parameters/sched_boost_on_input"
    elif [ "$ARCH_TYPE" = "MEDIATEK" ]; then
        # MediaTek Dimensity & Helio Boost
        set_cpu_governors "performance"
        
        # MTK FPSGO Frame Prediction Optimization
        safe_write "1" "/sys/kernel/fpsgo/common/fpsgo_enable"
        safe_write "1" "/sys/module/mtk_fpsgo/parameters/enable"
        safe_write "1" "/sys/kernel/fpsgo/fstb/fstb_soft_level"
        safe_write "1" "/sys/kernel/fpsgo/fstb/fstb_fps_margin"
        
        # MTK GED Smart Boost
        safe_write "1" "/sys/module/ged/parameters/ged_smart_boost"
        safe_write "1" "/sys/module/ged/parameters/boost_gpu_enable"
        safe_write "1" "/sys/module/ged/parameters/gx_top_app_pid"
        safe_write "1" "/sys/module/ged/parameters/enable_game_self_frc"
        
        # MediaTek GPU devfreq governor
        for mtk_gpu_gov in /sys/class/misc/mali0/device/devfreq/*/governor; do
            safe_write "performance" "$mtk_gpu_gov"
        done
    else
        # Generic ARM fallback
        set_cpu_governors "performance"
    fi
    
    THERMAL_THROTTLED=0
    CURRENT_STATE="GAMING"
}

# 7. Idle Baseline Restoration
revert_to_idle() {
    log_info "Game closed or minimized. Reverting parameters to boot baseline..."
    
    # 7.1 Restore CPU Governors
    restore_cpu_governors
    
    # 7.2 Restore Virtual Memory (VM)
    safe_write "$SNAP_VFS_CACHE_PRESSURE" "/proc/sys/vm/vfs_cache_pressure"
    safe_write "$SNAP_DIRTY_RATIO" "/proc/sys/vm/dirty_ratio"
    safe_write "$SNAP_DIRTY_BG_RATIO" "/proc/sys/vm/dirty_background_ratio"
    
    # 7.3 Restore Network Parameters
    safe_write "$SNAP_TCP_LOW_LATENCY" "/proc/sys/net/ipv4/tcp_low_latency"
    safe_write "$SNAP_TCP_SLOW_START" "/proc/sys/net/ipv4/tcp_slow_start_after_idle"
    safe_write "$SNAP_TCP_NOTSENT_LOWAT" "/proc/sys/net/ipv4/tcp_notsent_lowat"
    
    # 7.4 Restore Architecture Defaults
    if [ "$ARCH_TYPE" = "QUALCOMM" ]; then
        if [ -f "$SNAPSHOT_DIR/adreno_gov" ]; then
            orig_adreno_gov=$(cat "$SNAPSHOT_DIR/adreno_gov" 2>/dev/null)
            safe_write "$orig_adreno_gov" "/sys/class/kgsl/kgsl-3d0/devfreq/governor"
        else
            safe_write "msm-adreno-tz" "/sys/class/kgsl/kgsl-3d0/devfreq/governor"
        fi
        safe_write "0" "/sys/class/kgsl/kgsl-3d0/force_bus_on"
        safe_write "0" "/sys/class/kgsl/kgsl-3d0/force_clk_on"
        safe_write "0" "/sys/class/kgsl/kgsl-3d0/force_rail_on"
        safe_write "1" "/sys/class/kgsl/kgsl-3d0/bus_split"
        safe_write "1" "/sys/class/kgsl/kgsl-3d0/throttling"
    elif [ "$ARCH_TYPE" = "MEDIATEK" ]; then
        safe_write "0" "/sys/module/ged/parameters/ged_smart_boost"
        for mtk_gpu_gov in /sys/class/misc/mali0/device/devfreq/*/governor; do
            safe_write "simple_ondemand" "$mtk_gpu_gov"
        done
    fi
    
    # Reset schedtune boost
    safe_write "0" "/dev/stune/top-app/schedtune.boost"
    safe_write "0" "/dev/stune/top-app/schedtune.prefer_idle"
    
    THERMAL_THROTTLED=0
    ACTIVE_GAME_PACKAGE=""
    ACTIVE_GAME_PID=""
    CURRENT_STATE="IDLE"
    log_info "Idle baseline restored cleanly."
}

# 8. Main Monitoring Daemon Loop
log_info "AeroPace dynamic monitor loop active."

while true; do
    FOCUSED_PKG=$(get_focused_package)
    
    # Determine if focused package is one of the target competitive games
    GAME_FOUND=""
    for target in $TARGET_PACKAGES; do
        if [ "$FOCUSED_PKG" = "$target" ]; then
            GAME_FOUND="$target"
            break
        fi
    done
    
    if [ -n "$GAME_FOUND" ]; then
        # Game is in foreground
        if [ "$CURRENT_STATE" != "GAMING" ]; then
            ACTIVE_GAME_PACKAGE="$GAME_FOUND"
            apply_game_boost "$GAME_FOUND"
        else
            # Ensure game PID is tracked and protected against LMK if PID changed (e.g. game relaunch)
            CURRENT_PID=$(pidof "$GAME_FOUND" 2>/dev/null | awk '{print $1}')
            if [ -n "$CURRENT_PID" ] && [ "$CURRENT_PID" != "$ACTIVE_GAME_PID" ]; then
                ACTIVE_GAME_PID="$CURRENT_PID"
                renice -n -20 -p "$CURRENT_PID" 2>/dev/null
                safe_write "-1000" "/proc/$CURRENT_PID/oom_score_adj"
                safe_write "$CURRENT_PID" "/dev/cpuset/top-app/tasks"
                safe_write "$CURRENT_PID" "/dev/stune/top-app/tasks"
            fi
            
            # Active Thermal Watchdog: Protect hardware and prevent throttling cliff-drops
            THERMAL_STATE=$(check_thermal_status)
            THERMAL_COND=$(echo "$THERMAL_STATE" | awk '{print $1}')
            BAT_T=$(echo "$THERMAL_STATE" | awk '{print $2}')
            SOC_T=$(echo "$THERMAL_STATE" | awk '{print $3}')
            
            if [ "$THERMAL_COND" = "HOT" ] && [ "$THERMAL_THROTTLED" -eq 0 ]; then
                log_info "THERMAL GUARD: Safety threshold breached (Bat: ${BAT_T}°C, SoC: ${SOC_T}°C). Scaling CPU governors down to schedutil..."
                set_cpu_governors "schedutil"
                THERMAL_THROTTLED=1
            elif [ "$THERMAL_COND" = "COOL" ] && [ "$THERMAL_THROTTLED" -eq 1 ]; then
                log_info "THERMAL GUARD: Temperatures normalized (Bat: ${BAT_T}°C, SoC: ${SOC_T}°C). Restoring performance governors..."
                set_cpu_governors "performance"
                THERMAL_THROTTLED=0
            fi
        fi
    else
        # Game is not in foreground
        if [ "$CURRENT_STATE" = "GAMING" ]; then
            revert_to_idle
        fi
    fi
    
    sleep 3
done
