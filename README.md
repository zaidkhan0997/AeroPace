# AeroPace Performance Engine ⚡

[![Root Compatibility](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-success?style=for-the-badge&logo=android)](https://github.com/zaidkhan0997/AeroPace)
[![Architecture](https://img.shields.io/badge/SoC-Qualcomm%20%7C%20MediaTek-blue?style=for-the-badge&logo=qualcomm)](https://github.com/zaidkhan0997/AeroPace)
[![Anti--Cheat](https://img.shields.io/badge/Anti--Cheat-100%25%20Safe%20(Zero%20Spoofing)-brightgreen?style=for-the-badge)](https://github.com/zaidkhan0997/AeroPace)
[![License](https://img.shields.io/badge/License-GPL--3.0-orange?style=for-the-badge)](LICENSE)

**AeroPace** is an enterprise-grade, universal Android root performance module meticulously engineered for competitive mobile esports (specifically **BGMI** and **PUBG Mobile**). Built on modern Linux kernel scheduling principles, AeroPace provides hardware-level responsiveness, stable frame rendering, and safe thermal governance without placebos or account bans.

---

## 🌟 Key Engineering Highlights

### 1. 🔄 Dynamic State Lifecycle (Zero Battery Drain on Idle)
AeroPace never runs permanent overclocking loops. It continuously monitors window manager focus:
- **Idle State**: Device runs at 100% factory baseline parameters with standard power efficiency.
- **Gameplay State**: The instant a target game package enters the foreground, CPU governors, GPU frequencies, thread priorities, and network queues are escalated to maximum responsiveness.
- **Auto Restoration**: When you exit or minimize the game, all governors, kernel sysctls, and GPU states automatically revert to the exact snapshots taken at boot.

### 2. 🛡️ 100% Anti-Cheat Safe (Zero Device Spoofing)
Many gaming modules spoof `ro.product.model` or `ro.build.fingerprint` to trick games into unlocking 90/120 FPS. This frequently triggers security mismatches and 10-year bans in BGMI and PUBG Mobile.
- **AeroPace alters ZERO device fingerprints or product identifiers.**
- All optimizations operate strictly on Linux scheduler, cpusets, GPU bus clocks, and TCP buffer dispatching.

### 3. 🧠 Safe Virtual Memory Management (No Placebo Task Killers)
- **No aggressive OOM killing loops**: Repeatedly killing background processes thrashes the Android ZRAM and causes severe UI lag and redraws.
- **Surgical VM sysctl tuning**: During gameplay, `/proc/sys/vm/vfs_cache_pressure` is set to `100`, `dirty_ratio` to `10`, and `dirty_background_ratio` to `5` to eliminate I/O micro-stutters.
- **LMK Shield**: The active game PID receives `/proc/<pid>/oom_score_adj = -1000`, preventing the Android LowMemoryKiller from killing your game during intense squad fights.

### 4. 🌡️ Active Hardware Thermal Guard
Completely disabling thermal throttlers (`mi_thermald`, `thermal-engine`) leads to severe battery degradation and motherboard warping. AeroPace respects hardware safety:
- It actively polls `/sys/class/thermal/thermal_zone*/temp`.
- If battery temperature exceeds **43°C** or SoC temperature exceeds **75°C**, AeroPace gracefully steps CPU governors down to `schedutil` until temperatures cool down.
- This prevents the dreaded thermal "cliff-drop" where the kernel violently drops CPU frequencies to minimum, causing massive frame freezes.

---

## 🎯 Supported Game Packages

| Package Name | Game Title | Target Region |
| :--- | :--- | :--- |
| `com.pubg.imobile` | Battlegrounds Mobile India (BGMI) | India |
| `com.tencent.ig` | PUBG Mobile Global | Global |
| `com.pubg.krmobile` | PUBG Mobile Korea / Japan | Korea / Japan |
| `com.vng.pubgmobile` | PUBG Mobile VN | Vietnam |

---

## 🧩 Architecture-Specific Tuning

### 🔴 Qualcomm Snapdragon
- **CPU Governance**: Sets performance governors across prime, gold, and silver clusters during active matches.
- **Adreno Devfreq & Bus Scaling**: Unlocks Adreno GPU performance frequency (`kgsl-3d0/devfreq/governor`), enables low-latency bus clock retention, and disables bus split bottlenecks.
- **MSM Performance Boost**: Calibrates touchboost parameters for sub-millisecond touch dispatching.

### 🔵 MediaTek Dimensity & Helio
- **MTK FPSGO Integration**: Activates `mtk_fpsgo` frame prediction modules (`fstb_soft_level`, `fstb_fps_margin`) to maintain continuous frame cadence.
- **GED Smart Boost**: Enables MediaTek Graphics Engine Driver (`ged_smart_boost` & `boost_gpu_enable`) for direct GPU-workload acceleration.
- **Mali / Immortalis Scaling**: Forces interactive GPU devfreq governance during combat sequences.

---

## 📲 Installation

AeroPace supports all modern open-source Android root solutions:

### Method 1: Magisk
1. Download the latest `AeroPace-vX.X.X.zip` from [Releases](https://github.com/zaidkhan0997/AeroPace/releases).
2. Open the **Magisk App** -> Tap **Modules** -> Tap **Install from storage**.
3. Select the downloaded ZIP file and wait for the installer to finish.
4. Reboot your device.

### Method 2: KernelSU (KSU)
1. Ensure KernelSU is installed with full module support.
2. Open the **KernelSU App** -> Tap **Modules** -> Tap the **+** (Install) icon.
3. Select `AeroPace-vX.X.X.zip`.
4. Reboot your device.

### Method 3: APatch
1. Open the **APatch Manager**.
2. Navigate to the **Modules** tab -> Tap **Install Module**.
3. Select `AeroPace-vX.X.X.zip`.
4. Reboot your device.

---

## 🔄 In-Manager Remote Updates

AeroPace natively implements the modern `updateJson` specification in `module.prop`. When an update is published on GitHub:
1. Open **Magisk / KernelSU / APatch**.
2. Go to the **Modules** section.
3. If an update is available, an **Update** button will appear automatically on the AeroPace card.
4. Tap **Update** to download and flash the latest version directly without visiting your web browser.

---

## 🛠️ Verification & Diagnostic Logs

To inspect runtime behavior and ensure the daemon is actively managing your games, run via Termux or ADB shell:

```bash
# View live AeroPace daemon activity
su -c tail -f /data/local/tmp/aeropace/daemon.log

# Check stored boot snapshot parameters
su -c ls -l /data/local/tmp/aeropace/snapshot/
```

---

## ❓ Frequently Asked Questions (FAQ)

### Will this module get my game account banned?
**No.** AeroPace does not touch game memory, inject libraries, hook game processes, or spoof device identifiers (`ro.product.model`, `ro.build.fingerprint`). It is an external kernel scheduler and system tuner.

### Does AeroPace cause battery drain?
**No.** Thanks to the dynamic state engine, AeroPace only boosts hardware when a supported game is actively in the foreground. While browsing, texting, or sleeping, the device stays at standard factory power curves.

### Does AeroPace remove thermal throttling?
**No, and that is intentional.** Completely removing thermal throttling leads to device damage, battery swelling, and screen discoloration. AeroPace uses a safety-managed Thermal Watchdog to prevent sudden throttling cliff drops while keeping maximum battery temperatures below 43°C.

---

## 🤝 Contributing & Building

To build the flashable ZIP locally:

```bash
git clone https://github.com/zaidkhan0997/AeroPace.git
cd AeroPace
chmod +x build.sh
./build.sh
```

Compiled flashable ZIPs and SHA-256 hashes will be generated in `out/`.
