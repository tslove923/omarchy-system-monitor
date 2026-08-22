import QtQuick
import qs.Ui
import qs.Commons

// Compact Omarchy-style text meter for the bar row: "cpu: 25%".
//
// Built on WidgetButton so the label font, family, and urgent-active coloring
// match every other text widget in the bar. Non-interactive so the row's
// HoverHandler owns the pointer and the details card opens on hover instead of
// a per-meter tooltip.
WidgetButton {
  id: root

  property bool warn: false
  property real meterFontSize: Style.font.caption

  fontSize: root.meterFontSize
  horizontalMargin: 3
  interactive: false
  pressable: false
  tooltipText: ""
  active: root.warn
}
