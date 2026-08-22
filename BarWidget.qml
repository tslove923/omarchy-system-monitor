import QtQuick
import qs.Ui
import qs.Commons
import "Format.js" as Fmt

// System Monitor — CPU / GPU / NPU / RAM / swap / disk text meters with a
// hover details card. Ported from the illogical-impulse QuickShell config,
// rebuilt on the Omarchy widget kit (BarWidget + WidgetButton + PopupCard).
BarWidget {
  id: root
  moduleName: "trevor.system-monitor"

  // ---- settings (inline shell.json entry; fallback = manifest defaults) ----
  readonly property int updateIntervalMs: Math.max(500, root.setting("updateInterval", 3000))
  readonly property int cpuThreshold: root.setting("cpuThreshold", 90)
  readonly property int gpuThreshold: root.setting("gpuThreshold", 95)
  readonly property int npuThreshold: root.setting("npuThreshold", 95)
  readonly property int memoryThreshold: root.setting("memoryThreshold", 95)
  readonly property int swapThreshold: root.setting("swapThreshold", 85)
  readonly property int diskThreshold: root.setting("diskThreshold", 90)

  // ---- Nerd Font glyphs ----
  readonly property string cpuGlyph: ""   // fa-microchip
  readonly property string gpuGlyph: ""   // fa-bolt
  readonly property string npuGlyph: ""   // fa-brain
  readonly property string memGlyph: ""   // fa-memory
  readonly property string swapGlyph: ""  // fa-exchange
  readonly property string diskGlyph: ""  // fa-hdd-o

  // ---- theme ----
  readonly property color normalColor: root.bar ? root.bar.barForeground : Color.foreground
  readonly property color warnColor: root.bar ? root.bar.urgent : Color.urgent
  readonly property string fam: root.bar ? root.bar.fontFamily : Style.font.family

  function warn(p, threshold) {
    return Math.round(p * 100) >= threshold
  }

  // Per-meter visibility for every show<X> setting: "Show"/"Hide" override
  // detection, "Auto" (default) shows only when the resource is available on
  // this hardware. Legacy "true"/"false" strings (from the older bool
  // settings) are mapped onto Show/Hide so old configs keep working.
  function meterVisible(available, key) {
    var v = String(root.setting(key, "Auto")).toLowerCase()
    if (v === "show" || v === "true" || v === "1") return true
    if (v === "hide" || v === "false" || v === "0") return false
    return available
  }

  readonly property real memRatio: stats.memTotalKb > 0 ? stats.memUsedKb / stats.memTotalKb : 0
  readonly property real swapRatio: stats.swapTotalKb > 0 ? stats.swapUsedKb / stats.swapTotalKb : 0

  readonly property color cpuColor: root.warn(stats.cpuUsage, root.cpuThreshold) ? root.warnColor : root.normalColor
  readonly property color gpuColor: root.warn(stats.gpuUsage, root.gpuThreshold) ? root.warnColor : root.normalColor
  readonly property color npuColor: root.warn(stats.npuUsage, root.npuThreshold) ? root.warnColor : root.normalColor
  readonly property color memColor: root.warn(root.memRatio, root.memoryThreshold) ? root.warnColor : root.normalColor
  readonly property color swapColor: root.warn(root.swapRatio, root.swapThreshold) ? root.warnColor : root.normalColor
  readonly property color diskColor: root.warn(stats.diskPct / 100, root.diskThreshold) ? root.warnColor : root.normalColor

  // ---- data service (one instance per widget; meters + card share it) ----
  property QtObject stats: StatsService {
    id: svc
    interval: root.updateIntervalMs
    enabled: root.visible
  }

  onSettingsChanged: svc.interval = Math.max(500, root.setting("updateInterval", 3000))

  // ---- hover open/close with a grace period so the cursor can cross the gap
  // from the meters row into the card without it vanishing ----
  readonly property bool rowHovered: rowHover.hovered
  readonly property bool cardHovered: popup.containsMouse
  property bool popupOpen: false

  onRowHoveredChanged: {
    if (root.rowHovered) {
      closeTimer.stop()
      root.popupOpen = true
    } else {
      closeTimer.restart()
    }
  }
  onCardHoveredChanged: {
    if (!root.cardHovered && !root.rowHovered) closeTimer.restart()
  }

  Timer {
    id: closeTimer
    interval: 200
    onTriggered: if (!root.rowHovered && !root.cardHovered) root.popupOpen = false
  }

  implicitWidth: metersRow.implicitWidth
  implicitHeight: root.barSize

  // ---- text meters row (Omarchy WidgetButton style) ----
  Item {
    id: metersRow
    anchors.fill: parent
    implicitWidth: metersLayout.implicitWidth
    implicitHeight: root.barSize

    Row {
      id: metersLayout
      anchors.centerIn: parent
      spacing: 0

      // A little breathing room from the widget to the left (workspace numbers).
      Item { width: Style.spaceReal(8); height: 1 }

      MeterText {
        text: "cpu: " + Fmt.pct01(stats.cpuUsage)
        warn: root.warn(stats.cpuUsage, root.cpuThreshold)
        visible: root.meterVisible(true, "showCpu")
      }
      MeterText {
        text: "gpu: " + Fmt.pct01(stats.gpuUsage)
        warn: root.warn(stats.gpuUsage, root.gpuThreshold)
        visible: root.meterVisible(stats.gpuAvailable, "showGpu")
      }
      MeterText {
        text: "npu: " + Fmt.pct01(stats.npuUsage)
        warn: root.warn(stats.npuUsage, root.npuThreshold)
        visible: root.meterVisible(stats.npuAvailable, "showNpu")
      }
      MeterText {
        text: "ram: " + Fmt.pct01(root.memRatio)
        warn: root.warn(root.memRatio, root.memoryThreshold)
        visible: root.meterVisible(true, "showRam")
      }
      MeterText {
        text: "swap: " + Fmt.pct01(root.swapRatio)
        warn: root.warn(root.swapRatio, root.swapThreshold)
        visible: root.meterVisible(stats.swapTotalKb > 0, "showSwap")
      }
      MeterText {
        text: "disk: " + stats.diskPct + "%"
        warn: root.warn(stats.diskPct / 100, root.diskThreshold)
        visible: root.meterVisible(true, "showDisk")
      }
    }

    HoverHandler { id: rowHover }
  }

  // ---- hover details card ----
  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    triggerMode: "hover"
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(
      Style.space(84 + 52 + 64 + 76 * 3) + Style.spacing.popupPadding * 2 + Style.space(8))
    contentHeight: popup.fittedContentHeight(details.implicitHeight)

    Column {
      id: details
      width: parent.width
      spacing: Style.spacing.xs

      // header
      Row {
        width: parent.width
        spacing: 0
        Text { width: Style.space(84); text: "" }
        Text { width: Style.space(52); text: "Load"; font.family: root.fam; font.pixelSize: Style.font.caption; color: Util.alpha(root.normalColor, 0.6); horizontalAlignment: Text.AlignRight }
        Text { width: Style.space(64); text: "Freq"; font.family: root.fam; font.pixelSize: Style.font.caption; color: Util.alpha(root.normalColor, 0.6); horizontalAlignment: Text.AlignRight }
        Text { width: Style.space(76); text: "Used"; font.family: root.fam; font.pixelSize: Style.font.caption; color: Util.alpha(root.normalColor, 0.6); horizontalAlignment: Text.AlignRight }
        Text { width: Style.space(76); text: "Free"; font.family: root.fam; font.pixelSize: Style.font.caption; color: Util.alpha(root.normalColor, 0.6); horizontalAlignment: Text.AlignRight }
        Text { width: Style.space(76); text: "Total"; font.family: root.fam; font.pixelSize: Style.font.caption; color: Util.alpha(root.normalColor, 0.6); horizontalAlignment: Text.AlignRight }
      }

      PanelSeparator { foreground: root.normalColor }

      DetailRow {
        label: root.cpuGlyph + " CPU"
        color: root.cpuColor
        fontFamily: root.fam
        normalColor: root.normalColor
        load: Fmt.pct01(stats.cpuUsage)
        freq: stats.cpuFreqMhz > 0 ? Fmt.mhz(stats.cpuFreqMhz) : "Idle"
      }
      DetailRow {
        visible: root.meterVisible(stats.gpuAvailable, "showGpu")
        label: root.gpuGlyph + " GPU"
        color: root.gpuColor
        fontFamily: root.fam
        normalColor: root.normalColor
        load: Fmt.pct01(stats.gpuUsage)
        freq: stats.gpuFreqMhz > 0 ? Fmt.mhz(stats.gpuFreqMhz) : "Idle"
      }
      DetailRow {
        visible: root.meterVisible(stats.npuAvailable, "showNpu")
        label: root.npuGlyph + " NPU"
        color: root.npuColor
        fontFamily: root.fam
        normalColor: root.normalColor
        load: Fmt.pct01(stats.npuUsage)
        freq: stats.npuStatus === "suspended" ? "Suspended" : (stats.npuFreqMhz > 0 ? Fmt.mhz(stats.npuFreqMhz) : "Idle")
        used: stats.npuMemBytes > 0 ? (stats.npuMemBytes / 1048576).toFixed(0) + " MB" : "—"
      }
      DetailRow {
        label: root.memGlyph + " RAM"
        color: root.memColor
        fontFamily: root.fam
        normalColor: root.normalColor
        load: Fmt.pct01(root.memRatio)
        used: Fmt.gb(stats.memUsedKb)
        free: Fmt.gb(stats.memTotalKb - stats.memUsedKb)
        total: Fmt.gb(stats.memTotalKb)
      }
      DetailRow {
        visible: root.meterVisible(stats.swapTotalKb > 0, "showSwap")
        label: root.swapGlyph + " Swap"
        color: root.swapColor
        fontFamily: root.fam
        normalColor: root.normalColor
        load: Fmt.pct01(root.swapRatio)
        used: Fmt.gb(stats.swapUsedKb)
        free: Fmt.gb(stats.swapTotalKb - stats.swapUsedKb)
        total: Fmt.gb(stats.swapTotalKb)
      }
      DetailRow {
        label: root.diskGlyph + " Disk"
        color: root.diskColor
        fontFamily: root.fam
        normalColor: root.normalColor
        load: stats.diskPct + "%"
        used: Fmt.gb(stats.diskUsedKb)
        free: Fmt.gb(stats.diskAvailKb)
        total: Fmt.gb(stats.diskTotalKb)
      }

      Text {
        text: "disk: btrfs allocation via df (used + free ≠ total)"
        font.family: root.fam
        font.pixelSize: Style.font.caption
        color: Util.alpha(root.normalColor, 0.5)
      }
    }
  }
}
