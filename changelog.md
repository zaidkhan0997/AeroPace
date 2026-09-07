# AeroPace Release Changelog

## v1.1.0 (Code: 110)
- Extended operating system support up to Android 17 (API 30–37).
- High-accuracy package focus detection engine updated for Android 11 through Android 17 (`cmd activity activities`, `topResumedActivity`, `dumpsys window`, and top-app cpuset fallbacks).
- Live Telemetry & Heartbeat Engine:
  - Instantaneous logging when foreground window/app switches.
  - Active gaming telemetry every ~9 seconds (temperatures, CPU/GPU clocks, governor status, LMK shield).
  - Ambient idle heartbeat every 30 seconds confirming active background surveillance.
  - Atomic real-time status snapshot file `/sdcard/AeroPace/live_monitor.status` updated every 3 seconds for instant terminal/UI checking.
- Zero-root user storage logging: outputs human-readable runtime verification logs directly to `/sdcard/AeroPace/aeropace.log` (with `/sdcard/aeropace` alias compatibility).
- Built-in 24-hour auto-purge engine: logs automatically self-destruct after 24 hours and are capped at 1,500 lines to prevent storage bloat.
- Developer diagnostic session: logs kernel version, SoC architecture, root manager, and baseline snapshot restoration.
- Resolved baseline snapshot directory targeting bug (`SNAPSHOT_DIR` correctly set to `$INTERNAL_LOG_DIR/snapshot`).
- Enforced 100% offline User Privacy & Data Safety Policy (zero network calls, zero tracking, zero personal data access).

## v1.0.0 (Initial Release)
- Universal root support across Magisk, KernelSU, and APatch.
- Dynamic game lifecycle: automatically engages performance mode on foreground detection across 20 popular gaming titles (BGMI, PUBG Mobile variants, MLBB, Free Fire MAX, Call of Duty: Mobile, Genshin Impact, Roblox, Minecraft, Honor of Kings, EA SPORTS FC Mobile, eFootball, Clash of Clans, and more) and seamlessly reverts to boot baseline on exit.
- Process priority boosting (`renice -n -20`, `top-app` cpusets, and LMK protection `oom_score_adj = -1000`).
- Safe Linux Virtual Memory tuning (`vfs_cache_pressure=100`, `dirty_ratio=10`, `dirty_background_ratio=5`) with no placebo task killers.
- Architecture-specific optimization engines:
  - Qualcomm Snapdragon: Adreno GPU devfreq scaling, clk/bus boost, CPU governor escalation.
  - MediaTek Dimensity/Helio: `mtk_fpsgo` frame prediction boost, GED smart boost, CPU governor escalation.
- Continuous Thermal Watchdog: graceful governor step-down to prevent thermal throttling cliff drops (>43°C battery / >75°C SoC).
- Low latency TCP network tuning (`tcp_low_latency`, `tcp_slow_start_after_idle=0`).
- SurfaceFlinger buffer latency and touch dispatching optimizations.
- Zero-root user storage logging: outputs human-readable runtime verification logs directly to `/sdcard/AeroPace/aeropace.log`.
- Built-in 24-hour auto-purge engine: logs automatically self-destruct after 24 hours and are hard-capped to prevent storage bloat.
- Developer diagnostic session: logs kernel version, SoC architecture, root manager, and sysfs write diagnostics.
- Enforced 100% offline User Privacy & Data Safety Policy (zero network calls, zero tracking, zero personal data access).
