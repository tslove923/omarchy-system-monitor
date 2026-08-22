# System Monitor (Omarchy bar-widget)

CPU / GPU / NPU / RAM / swap / disk monitoring for the Omarchy shell bar,
ported from the illogical-impulse QuickShell config.

Six compact ring meters in the bar (GPU and NPU only appear when the device is
present). Hovering the meters opens a details card with load, frequency, NPU
memory + status, and used / free / total for RAM, swap, and disk. Meters flip
to the warning color (`bar.urgent`) above their configured threshold.

## Install

```sh
omarchy plugin add https://github.com/tslove923/omarchy-system-monitor --enable
omarchy-shell shell rescanPlugins
omarchy bar move trevor.system-monitor --section left
```

## Settings

Per-widget settings live in the inline shell.json entry for the widget
(edit with `omarchy bar set trevor.system-monitor <key> <value>` or the config
UI):

| key             | default | meaning                          |
|-----------------|---------|----------------------------------|
| `updateInterval`| 3000    | poll interval (ms)               |
| `cpuThreshold`  | 90      | CPU warning %                    |
| `gpuThreshold`  | 95      | GPU warning %                    |
| `npuThreshold`  | 95      | NPU warning %                    |
| `memoryThreshold`| 95     | RAM warning %                    |
| `swapThreshold` | 85      | swap warning %                   |
| `diskThreshold` | 90      | disk warning %                   |
| `showSwap`      | true    | show the swap meter              |
| `alwaysShowCpu` | true    | keep the CPU meter visible       |

## Data sources

One `sh -c` snapshot per poll, all read-only:

| metric      | source                                                        |
|-------------|---------------------------------------------------------------|
| CPU load    | `/proc/stat` aggregate line delta                             |
| CPU freq    | `/sys/devices/system/cpu/cpu0/cpufreq/scaling_{cur,max}_freq` |
| RAM / swap  | `/proc/meminfo` (MemTotal/MemAvailable/SwapTotal/SwapFree)    |
| GPU load    | `/sys/class/drm/card0/device/tile0/gt0/gtidle/idle_residency_ms` delta |
| GPU freq    | `/sys/class/drm/card0/device/tile0/gt0/freq0/{act,max}_freq`  |
| NPU load    | `/sys/class/accel/accel0/device/npu_busy_time_us` delta       |
| NPU freq    | `/sys/class/accel/accel0/device/npu_{current,max}_frequency_mhz` |
| NPU mem     | `/sys/class/accel/accel0/device/npu_memory_utilization` (bytes)  |
| NPU status  | `/sys/class/accel/accel0/device/power/runtime_status`         |
| disk        | `df -P /`                                                     |

Paths are the Intel Lunar Lake layout (Arc iGPU tile0/gt0, accel0 NPU). If a
sysfs path is missing the corresponding meter hides rather than erroring.

## Notes

- **Disk is btrfs allocation.** The root filesystem is btrfs, so `df` reports
  subvolume/allocated space and `used + free ≠ total` is normal (reserved
  blocks). The disk meter is still useful for runaway usage.
- **NPU suspend.** When the NPU is `suspended` the busy counter is frozen, so
  usage is forced to 0 and the card shows `Suspended`.
- **Safety.** The plugin spawns one `sh -c` per poll with a fixed, literal
  script (no user input, no QML interpolation). All sources are world-readable
  `/proc` and `/sys` files plus `df`. No network, no persistent state.

## License

MIT
