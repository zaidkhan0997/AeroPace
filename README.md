# AeroPace Performance Engine ⚡

[![Root Compatibility](https://img.shields.io/badge/Root-Magisk%20%7C%20KernelSU%20%7C%20APatch-success?style=for-the-badge&logo=android)](https://github.com/zaidkhan0997/AeroPace)
[![Architecture](https://img.shields.io/badge/SoC-Qualcomm%20%7C%20MediaTek-blue?style=for-the-badge&logo=qualcomm)](https://github.com/zaidkhan0997/AeroPace)
[![Anti--Cheat](https://img.shields.io/badge/Anti--Cheat-100%25%20Safe%20(Zero%20Spoofing)-brightgreen?style=for-the-badge)](https://github.com/zaidkhan0997/AeroPace)
[![License](https://img.shields.io/badge/License-GPL--3.0-orange?style=for-the-badge)](LICENSE)

**AeroPace** is an enterprise-grade, universal Android root performance module meticulously engineered for competitive mobile esports and demanding gaming titles (including **BGMI**, **PUBG Mobile**, **Mobile Legends**, **Free Fire**, **Call of Duty: Mobile**, **Genshin Impact**, and more). Built on modern Linux kernel scheduling principles, AeroPace provides hardware-level responsiveness, stable frame rendering, and safe thermal governance without placebos or account bans.

---

## 🌟 Key Engineering Highlights

### 1. 🔄 Dynamic State Lifecycle (Zero Battery Drain on Idle)
AeroPace never runs permanent overclocking loops. It continuously monitors window manager focus:
- **Idle State**: Device runs at 100% factory baseline parameters with standard power efficiency.
- **Gameplay State**: The instant a target game package enters the foreground, CPU governors, GPU frequencies, thread priorities, and network queues are escalated to maximum responsiveness.
- **Auto Restoration**: When you exit or minimize the game, all governors, kernel sysctls, and GPU states automatically revert to the exact snapshots taken at boot.

### 2. 🛡️ 100% Anti-Cheat Safe (Zero Device Spoofing)
Many gaming modules spoof `ro.product.model` or `ro.build.fingerprint` to trick games into unlocking 90/120 FPS. This frequently triggers security mismatches and bans.
- **AeroPace alters ZERO device fingerprints or product identifiers.**
- All optimizations operate strictly on Linux scheduler, cpusets, GPU bus clocks, and TCP buffer dispatching.

### 3. 🧠 Safe Virtual Memory Management (No Placebo Task Killers)
- **No aggressive OOM killing loops**: Repeatedly killing background processes thrashes the Android ZRAM and causes severe UI lag and redraws.
- **Surgical VM sysctl tuning**: During gameplay, `/proc/sys/vm/vfs_cache_pressure` is set to `100`, `dirty_ratio` to `10`, and `dirty_background_ratio` to `5` to eliminate I/O micro-stutters.
- **LMK Shield**: The active game PID receives `/proc/<pid>/oom_score_adj = -1000`, preventing the Android LowMemoryKiller from killing your game during intense team fights.

### 4. 🌡️ Active Hardware Thermal Guard
Completely disabling thermal throttlers (`mi_thermald`, `thermal-engine`) leads to severe battery degradation and motherboard warping. AeroPace respects hardware safety:
- It actively polls `/sys/class/thermal/thermal_zone*/temp`.
- If battery temperature exceeds **43°C** or SoC temperature exceeds **75°C**, AeroPace gracefully steps CPU governors down to `schedutil` until temperatures cool down.
- This prevents the dreaded thermal "cliff-drop" where the kernel violently drops CPU frequencies to minimum, causing massive frame freezes.

---

## 🎯 Supported Game Packages

AeroPace automatically monitors foreground activity and boosts the following 20 premier titles spanning Battle Royale, MOBA, FPS, RPG, Sandbox, Sports, Strategy, and Arcade:

| Package Name | Game Title | Genre / Category | Publisher / Studio |
| :--- | :--- | :--- | :--- |
| `com.pubg.imobile` | Battlegrounds Mobile India (BGMI) | Battle Royale | Krafton |
| `com.tencent.ig` | PUBG Mobile | Battle Royale | Level Infinite / Tencent |
| `com.pubg.krmobile` | PUBG Mobile (KR / JP) | Battle Royale | Krafton |
| `com.vng.pubgmobile` | PUBG Mobile (VN) | Battle Royale | VNG Games |
| `com.mobile.legends` | Mobile Legends: Bang Bang (MLBB) | MOBA | Moonton |
| `com.dts.freefiremax` | Free Fire MAX | Battle Royale | Garena |
| `com.dts.freefireth` | Garena Free Fire | Battle Royale | Garena |
| `com.activision.callofduty.shooter` | Call of Duty: Mobile (CODM) | FPS / Action | Activision |
| `com.levelinfinite.sgameGlobal` | Honor of Kings | MOBA | Level Infinite / TiMi |
| `com.miHoYo.GenshinImpact` | Genshin Impact | Open-World Action RPG | HoYoverse / Cognosphere |
| `com.mojang.minecraftpe` | Minecraft | Sandbox / Survival | Mojang Studios |
| `com.roblox.client` | Roblox | Sandbox / Metaverse | Roblox Corporation |
| `com.ea.gp.fifamobile` | EA SPORTS FC™ Mobile (FIFA Mobile) | Sports / Football | EA Sports |
| `jp.konami.pesam` | eFootball™ | Sports / Football | Konami |
| `com.supercell.clashofclans` | Clash of Clans | Strategy | Supercell |
| `com.supercell.clashroyale` | Clash Royale | Real-Time Strategy | Supercell |
| `com.miniclip.eightballpool` | 8 Ball Pool | Sports / Billiards | Miniclip |
| `com.miniclip.carrom` | Carrom Pool: Disc Game | Board / Casual | Miniclip |
| `com.kiloo.subwaysurf` | Subway Surfers | Endless Runner / Arcade | SYBO / Kiloo |
| `com.king.candycrushsaga` | Candy Crush Saga | Match-3 / Casual | King |

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

### 📱 For Mobile Gamers (Zero Root Skills Needed)
AeroPace automatically outputs a human-readable log directly in your device's standard internal storage:
- **Log Location**: Open any File Manager (Google Files, ZArchiver, MiXplorer, etc.) -> Open the **`AeroPace`** folder -> View **`aeropace.log`**.
- **What you can verify**:
  - Exact time your game was launched and detected.
  - Confirmation of CPU governor escalation (`performance`) and Adreno/Mali GPU clock locking.
  - Active LowMemoryKiller (LMK) protection applied to your game process (`oom_score_adj = -1000`).
  - Clean restoration back to stock factory baseline when you minimize or exit the game.
- **Auto-Cleaning / 24-Hour Purge**: To preserve storage and prevent clutter, the log file **automatically self-destructs after 24 hours** and is hard-capped at 500 lines (~50 KB max).

### 💻 For Developers & Bug Reporting (GitHub Issues)
When reporting bugs, thermal throttling step-downs, or kernel node incompatibilities, attach `/sdcard/AeroPace/aeropace.log` to your GitHub Issue. The log contains:
- **System Environment Header**: Android API, device model, exact kernel version (`uname -r`), detected SoC architecture, and root manager.
- **Kernel Node Warnings**: Any sysfs paths locked or missing on specific OEM kernels.
- **Thermal Sensor Diagnostics**: The exact `thermal_zone` and sensor type triggered during thermal guard events.

Advanced terminal monitoring (via Termux or ADB):
```bash
# View live AeroPace daemon activity
su -c tail -f /data/local/tmp/aeropace/daemon.log

# Check stored boot snapshot parameters
su -c ls -l /data/local/tmp/aeropace/snapshot/
```

---

## 🔒 User Privacy, Security & Data Safety Policy

AeroPace is engineered with an uncompromising commitment to gamer privacy and device integrity:

1. **100% Offline Architecture**:
   - AeroPace operates strictly through local Linux kernel and scheduler interfaces.
   - It contains **zero network sockets**, **zero telemetry trackers**, **zero analytics**, and **never connects to remote servers**.
2. **Zero Access to Personal Files or Accounts**:
   - AeroPace does not access, read, or scan your personal photos, media, messages, contacts, credentials, clipboard, or storage directories.
   - It strictly operates inside `/data/local/tmp/aeropace/` and creates its own temporary `/sdcard/AeroPace/` folder purely for the ephemeral log.
3. **Selective Gaming-Only Monitoring**:
   - The daemon's window focus detector strictly checks whether the foreground window matches one of the 20 explicitly supported game package IDs.
   - All other applications—including banking apps, messaging apps, browsers, and system tools—are completely ignored.
4. **Ephemeral Storage Lifecycle**:
   - Diagnostic logs automatically self-destruct after 24 hours to prevent lingering data and storage waste.
5. **Transparent Open Source**:
   - Every script in AeroPace is written in plain, human-readable shell code (`service.sh`, `customize.sh`). There are no pre-compiled closed-source binary blobs.

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
