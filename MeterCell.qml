import QtQuick
import qs.Commons

// One compact bar cell: a small progress ring with a centered glyph plus a
// percentage readout. Sized to fit the 26px horizontal bar.
Item {
  id: cell

  required property color color
  required property string glyph
  required property double ratio
  required property string text
  property string fontFamily: Style.font.family
  property int barSize: 26
  property int diameter: Math.round(Style.space(18))

  implicitWidth: diameter + Style.space(2) + pctLabel.implicitWidth
  implicitHeight: barSize

  Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(2)

    RingMeter {
      diameter: cell.diameter
      ratio: cell.ratio
      color: cell.color
      glyph: cell.glyph
      fontFamily: cell.fontFamily
    }

    Text {
      id: pctLabel
      text: cell.text
      font.family: cell.fontFamily
      font.pixelSize: Style.font.caption
      color: cell.color
      renderType: Text.NativeRendering
    }
  }
}
