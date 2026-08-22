import QtQuick
import qs.Commons

// One meter in the bar row.
//
// Text mode: "cpu: 25%" as a single run in the bar font.
// Icon mode: "glyph 25%" as two runs — the glyph may use a different font
// (Font Awesome 7 Free for fa-brain / fa-memory, since Qt does not reliably
// fontconfig-fallback Private Use glyphs) and the percentage stays in the bar
// font so all percentages look identical.
//
// Non-interactive: the row's MouseArea/HoverHandler own click and hover.
Item {
  id: root

  property string label: ""            // text-mode string, e.g. "cpu: 25%"
  property string glyph: ""            // icon-mode glyph char ("" = text mode)
  property string pct: ""              // icon-mode percentage, e.g. "25%"
  property string glyphFont: ""        // explicit font for the glyph ("" -> fontFamily)
  property string fontFamily: Style.font.family
  property real meterFontSize: Style.font.caption
  property bool warn: false
  property color normalColor: Color.foreground
  property color warnColor: Color.urgent
  property real horizontalMargin: 3
  property int barSize: Style.bar.sizeHorizontal

  readonly property color meterColor: root.warn ? root.warnColor : root.normalColor
  readonly property bool iconMode: root.glyph !== ""
  readonly property string glyphFamily: root.glyphFont !== "" ? root.glyphFont : root.fontFamily
  readonly property real scaledMargin: Style.spaceReal(root.horizontalMargin)

  implicitWidth: layout.implicitWidth + scaledMargin * 2
  implicitHeight: root.barSize

  Row {
    id: layout
    anchors.centerIn: parent
    spacing: Style.space(3)

    Text {
      visible: root.iconMode
      text: root.glyph
      color: root.meterColor
      font.family: root.glyphFamily
      font.pixelSize: root.meterFontSize
      renderType: Text.NativeRendering
    }
    Text {
      visible: root.iconMode
      text: root.pct
      color: root.meterColor
      font.family: root.fontFamily
      font.pixelSize: root.meterFontSize
      renderType: Text.NativeRendering
    }
    Text {
      visible: !root.iconMode
      text: root.label
      color: root.meterColor
      font.family: root.fontFamily
      font.pixelSize: root.meterFontSize
      renderType: Text.NativeRendering
    }
  }
}
