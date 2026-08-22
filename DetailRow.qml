import QtQuick
import qs.Commons

// One resource row in the hover details card: label | load | freq | used |
// free | total. Numeric columns are right-aligned; columns a resource doesn't
// use default to an em dash.
Row {
  id: row

  required property string label
  required property color color
  property string labelGlyph: ""          // optional leading icon
  property string labelGlyphFont: ""      // icon font ("" -> fontFamily); FA7 for fa-brain/fa-memory
  property string load: "—"
  property string freq: "—"
  property string used: "—"
  property string free: "—"
  property string total: "—"
  property color normalColor: Color.foreground
  property string fontFamily: Style.font.family

  readonly property real colLabel: Style.space(84)
  readonly property real colLoad: Style.space(52)
  readonly property real colFreq: Style.space(64)
  readonly property real colUsed: Style.space(76)
  readonly property real colFree: Style.space(76)
  readonly property real colTotal: Style.space(76)

  width: parent ? parent.width : (colLabel + colLoad + colFreq + colUsed + colFree + colTotal)
  spacing: 0

  Row {
    width: row.colLabel
    spacing: Style.space(4)
    Text {
      visible: row.labelGlyph !== ""
      text: row.labelGlyph
      font.family: row.labelGlyphFont !== "" ? row.labelGlyphFont : row.fontFamily
      font.pixelSize: Style.font.bodySmall
      color: row.normalColor
      renderType: Text.NativeRendering
    }
    Text {
      text: row.label
      font.family: row.fontFamily
      font.pixelSize: Style.font.bodySmall
      color: row.normalColor
      horizontalAlignment: Text.AlignLeft
      renderType: Text.NativeRendering
    }
  }
  Text {
    width: row.colLoad
    text: row.load
    font.family: row.fontFamily
    font.pixelSize: Style.font.bodySmall
    color: row.color
    horizontalAlignment: Text.AlignRight
    renderType: Text.NativeRendering
  }
  Text {
    width: row.colFreq
    text: row.freq
    font.family: row.fontFamily
    font.pixelSize: Style.font.bodySmall
    color: row.normalColor
    horizontalAlignment: Text.AlignRight
    renderType: Text.NativeRendering
  }
  Text {
    width: row.colUsed
    text: row.used
    font.family: row.fontFamily
    font.pixelSize: Style.font.bodySmall
    color: row.normalColor
    horizontalAlignment: Text.AlignRight
    renderType: Text.NativeRendering
  }
  Text {
    width: row.colFree
    text: row.free
    font.family: row.fontFamily
    font.pixelSize: Style.font.bodySmall
    color: row.normalColor
    horizontalAlignment: Text.AlignRight
    renderType: Text.NativeRendering
  }
  Text {
    width: row.colTotal
    text: row.total
    font.family: row.fontFamily
    font.pixelSize: Style.font.bodySmall
    color: row.normalColor
    horizontalAlignment: Text.AlignRight
    renderType: Text.NativeRendering
  }
}
