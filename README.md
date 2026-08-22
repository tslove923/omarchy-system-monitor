# System Monitor (Omarchy bar-widget)

CPU / GPU / NPU / RAM / swap / disk monitoring for the Omarchy shell bar,
ported from the illogical-impulse QuickShell config.

Compact meters in the bar — `cpu: 25% gpu: 12% ram: 41%` etc. in text mode, or
a Nerd glyph + percentage in icon mode. **Click the widget to toggle text <->
icons** (the choice is persisted to shell.json). GPU and NPU only appear when
the device is present. Hovering the row opens a details card with CPU, GPU, NPU,
RAM, swap, disk rows (load, frequency, used/free/total). A meter flips to a
warning color (`bar.urgent`) above its configured threshold.

## Install

```sh
omarchy plugin add https://github.com/tlove923/omarchy-system-monitor --enable
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
| `showCpu`       | Auto    | CPU meter: `Auto` / `Show` / `Hide`   |
| `showGpu`       | Auto    | GPU meter: `Auto` / `Show` / `Hide`   |
| `showNpu`       | Auto    | NPU meter: `Auto` / `Show` / `Hide`   |
| `showRam`       | Auto    | RAM meter: `Auto` / `Show` / `Hide`   |
| `showSwap`      | Auto    | Swap meter: `Auto` / `Show` / `Hide`  |
| `showDisk`      | Auto    | Disk meter: `Auto` / `Show` / `Hide`  |
| `displayMode`   | Text    | `Text` / `Icons` (click the widget to toggle) |

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
| RAM clock   | `sudo -n dmidecode -t memory` (Configured Memory Speed)        |
| SSD clock   | `/sys/class/nvme/nvme*/device/current_link_speed` (first NVMe) |

Paths are the Intel Lunar Lake layout (Arc iGPU tile0/gt0, accel0 NPU). If a
sysfs path is missing the corresponding meter hides rather than erroring.

## Hardware portability

The plugin never crashes on other hardware. Every GPU/NPU sysfs read falls back
to an `NA` sentinel; a missing device just means `gpuAvailable`/`npuAvailable`
are false and those meters hide. CPU, RAM, swap, and disk are universal.

- GPU load is read from the Intel tile0/gt0 `gtidle` residency counter — on AMD
  or NVIDIA machines this auto-hides. There's no vendor-agnostic load source.
- NPU is read from the Intel `accel0` driver (`npu_busy_time_us`) — on machines
  without an NPU it auto-hides.
- Swap auto-hides on systems with no swap device.
- Every meter has a `show<X>` setting (`Auto`/`Show`/`Hide`): `Auto` follows
  detection, `Show` forces the meter on any hardware, `Hide` removes it (bar
  and hover card). The config UI or `omarchy bar set trevor.system-monitor
  showGpu Show` set them.

## Notes

- **Disk is btrfs allocation.** The root filesystem is btrfs, so `df` reports
  subvolume/allocated space and `used + free ≠ total` is normal (reserved
  blocks). The disk meter is still useful for runaway usage.
- **NPU suspend.** When the NPU is `suspended` the busy counter is frozen, so
  usage is forced to 0 and the card shows `Suspended`.
- **Safety.** The plugin spawns one `sh -c` per poll with a fixed, literal
  script (no user input, no shell interpolation). All sources are world-readable
  `/proc` and `/sys` files plus `df`. No network, no persistent state.
  A separate one-shot `sh -c` at startup reads the RAM clock via
  `sudo -n dmidecode -t memory` — it never prompts, and without dmidecode or
  passwordless sudo the RAM clock simply shows `—` (the SSD clock needs no
  privileges).

## License

MIT
