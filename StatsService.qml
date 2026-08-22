import QtQuick
import Quickshell.Io

// Polled CPU / GPU / NPU / RAM / swap / disk monitor.
//
// One atomic snapshot per tick: a single `sh -c` reads every source and emits
// `KEY=VALUE` lines, parsed once in parse(). The script is a compile-time
// constant — no user input, no QML interpolation — so it is safe to run in the
// shell session. All sources are world-readable /proc and /sys files plus df.
//
// A missing sysfs path prints the `NA` sentinel (never a bare 0) so a missing
// GPU/NPU device sets available=false and the meter hides, distinct from a real
// idle reading.
QtObject {
  id: root

  // ---- public surface (bound by the meters row + hover card) ----
  property real cpuUsage: 0          // 0..1
  property int cpuFreqMhz: 0
  property int cpuMaxMhz: 0
  property real memUsedKb: 0
  property real memTotalKb: 0
  property real swapUsedKb: 0
  property real swapTotalKb: 0
  property bool gpuAvailable: false
  property real gpuUsage: 0
  property int gpuFreqMhz: 0
  property int gpuMaxMhz: 0
  property bool npuAvailable: false
  property real npuUsage: 0
  property int npuFreqMhz: 0
  property int npuMaxMhz: 0
  property real npuMemBytes: 0        // NPU memory utilization (bytes)
  property string npuStatus: ""
  property real diskUsedKb: 0
  property real diskAvailKb: 0
  property real diskTotalKb: 0
  property int diskPct: 0

  property int interval: 3000
  property bool enabled: true

  // ---- diff state (first sample records, second computes) ----
  property var prevCpu: null
  property real prevGpuIdle: -1
  property real prevGpuWall: 0
  property real prevNpuBusy: -1
  property real prevNpuWall: 0

  function refresh() {
    if (!pollProc.running) pollProc.running = true
  }

  Timer {
    id: pollTimer
    interval: root.interval
    running: root.enabled
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // Intel Lunar Lake sysfs layout (Arc iGPU tile0/gt0 + accel0 NPU).
  readonly property string SCRIPT: """
LANG=C
{
  echo "cpu=$(head -1 /proc/stat)"
  echo "cur=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo NA)"
  echo "cmax=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 2>/dev/null || echo NA)"
  echo "mem=$(grep -E '^(MemTotal|MemAvailable|SwapTotal|SwapFree):' /proc/meminfo | xargs)"
  echo "gact=$(cat /sys/class/drm/card0/device/tile0/gt0/freq0/act_freq 2>/dev/null || echo NA)"
  echo "gmax=$(cat /sys/class/drm/card0/device/tile0/gt0/freq0/max_freq 2>/dev/null || echo NA)"
  echo "gidle=$(cat /sys/class/drm/card0/device/tile0/gt0/gtidle/idle_residency_ms 2>/dev/null || echo NA)"
  echo "nbusy=$(cat /sys/class/accel/accel0/device/npu_busy_time_us 2>/dev/null || echo NA)"
  echo "nstat=$(cat /sys/class/accel/accel0/device/power/runtime_status 2>/dev/null || echo NA)"
  echo "ncur=$(cat /sys/class/accel/accel0/device/npu_current_frequency_mhz 2>/dev/null || echo NA)"
  echo "nmax=$(cat /sys/class/accel/accel0/device/npu_max_frequency_mhz 2>/dev/null || echo NA)"
  echo "nmem=$(cat /sys/class/accel/accel0/device/npu_memory_utilization 2>/dev/null || echo NA)"
  echo "disk=$(df -P / | awk 'NR==2 {print $2, $3, $4, $5}')"
}
"""

  Process {
    id: pollProc
    command: ["sh", "-c", root.SCRIPT]
    stdout: StdioCollector {
      id: pollOutput
      waitForEnd: true
      onStreamFinished: root.parse(pollOutput.text)
    }
  }

  function parse(text) {
    const raw = {}
    const lines = (text || "").split("\n")
    for (let line of lines) {
      const i = line.indexOf("=")
      if (i < 0) continue
      raw[line.slice(0, i)] = line.slice(i + 1)
    }
    const now = Date.now()

    // CPU: aggregate /proc/stat delta. Fields after the "cpu" token are
    // user nice system idle iowait irq softirq — idle is index 4.
    const c = (raw.cpu || "").trim().split(/\s+/)
    if (c.length >= 8) {
      const idle = parseInt(c[4]) || 0
      const total = (parseInt(c[1]) || 0) + (parseInt(c[2]) || 0) + (parseInt(c[3]) || 0)
        + idle + (parseInt(c[5]) || 0) + (parseInt(c[6]) || 0) + (parseInt(c[7]) || 0)
      if (root.prevCpu) {
        const dT = total - root.prevCpu.total
        const dI = idle - root.prevCpu.idle
        root.cpuUsage = dT > 0 ? Math.max(0, Math.min(1, 1 - dI / dT)) : 0
      }
      root.prevCpu = { total: total, idle: idle }
    }
    root.cpuFreqMhz = Math.round((parseInt(raw.cur) || 0) / 1000)   // kHz -> MHz
    root.cpuMaxMhz = Math.round((parseInt(raw.cmax) || 0) / 1000)

    // Memory / swap (KB)
    let mt = 0, ma = 0, st = 0, sf = 0
    const mems = (raw.mem || "").match(/MemTotal:\s*\d+|MemAvailable:\s*\d+|SwapTotal:\s*\d+|SwapFree:\s*\d+/g) || []
    for (const m of mems) {
      const bits = m.split(/\s+/)
      const n = parseInt(bits[1]) || 0
      if (bits[0] === "MemTotal:") mt = n
      else if (bits[0] === "MemAvailable:") ma = n
      else if (bits[0] === "SwapTotal:") st = n
      else if (bits[0] === "SwapFree:") sf = n
    }
    root.memTotalKb = mt
    root.memUsedKb = Math.max(0, mt - ma)
    root.swapTotalKb = st
    root.swapUsedKb = Math.max(0, st - sf)

    // GPU utilization via gtidle idle_residency_ms (like nvtop): usage = 1 - idleDelta/wallDelta
    const gidle = parseFloat(raw.gidle)
    root.gpuMaxMhz = parseInt(raw.gmax) || 0
    root.gpuFreqMhz = parseInt(raw.gact) || 0
    root.gpuAvailable = !isNaN(gidle) && root.gpuMaxMhz > 0
    if (root.gpuAvailable) {
      if (root.prevGpuIdle >= 0 && root.prevGpuWall > 0) {
        const wall = now - root.prevGpuWall
        const dI = gidle - root.prevGpuIdle
        if (wall > 0 && dI >= 0) root.gpuUsage = Math.max(0, Math.min(1, 1 - dI / wall))
      }
      root.prevGpuIdle = gidle
      root.prevGpuWall = now
    } else {
      root.gpuUsage = 0
      root.prevGpuIdle = -1
    }

    // NPU usage via npu_busy_time_us delta; busy counter freezes while suspended.
    const nbusy = parseFloat(raw.nbusy)
    root.npuMaxMhz = parseInt(raw.nmax) || 0
    root.npuFreqMhz = parseInt(raw.ncur) || 0
    root.npuMemBytes = parseFloat(raw.nmem) || 0
    root.npuStatus = (raw.nstat || "").trim()
    root.npuAvailable = !isNaN(nbusy) && root.npuMaxMhz > 0
    if (root.npuAvailable) {
      if (root.prevNpuBusy >= 0 && root.prevNpuWall > 0) {
        const wallUs = (now - root.prevNpuWall) * 1000
        const d = nbusy - root.prevNpuBusy
        if (wallUs > 0 && d >= 0) root.npuUsage = Math.max(0, Math.min(1, d / wallUs))
      }
      if (root.npuStatus === "suspended") root.npuUsage = 0
      root.prevNpuBusy = nbusy
      root.prevNpuWall = now
    } else {
      root.npuUsage = 0
      root.prevNpuBusy = -1
    }

    // Disk: `df -P /` prints "total used avail pct%". On a btrfs root this is
    // the subvolume allocation, so used + free != total (reserved space).
    const d = (raw.disk || "").trim().split(/\s+/)
    if (d.length >= 4) {
      root.diskTotalKb = parseFloat(d[0]) || 0
      root.diskUsedKb = parseFloat(d[1]) || 0
      root.diskAvailKb = parseFloat(d[2]) || 0
      root.diskPct = parseInt(d[3]) || 0
    }
  }
}
