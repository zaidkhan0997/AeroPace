# AeroPace Release Changelog

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
