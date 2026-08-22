import QtQuick
import QtQuick.Shapes
import qs.Commons

// Small circular progress ring with a centered glyph.
// Drawn with QtQuick.Shapes (PathAngleArc); a value of 1.0 closes the ring.
Item {
  id: root

  property real ratio: 0                      // 0..1
  property color color: Color.foreground      // stroke + glyph color
  property string glyph: ""                   // Nerd Font glyph, centered
  property string fontFamily: Style.font.family
  property int diameter: Math.max(12, Math.round(Style.space(18)))
  property int strokeWidth: Math.max(1, Math.round(Style.spaceReal(2)))

  readonly property real radius: (diameter - strokeWidth) / 2

  implicitWidth: diameter
  implicitHeight: diameter

  Shape {
    id: ring
    anchors.fill: parent
    antialiasing: true

    // Dim track (full circle)
    ShapePath {
      strokeColor: Util.alpha(root.color, 0.15)
      strokeWidth: root.strokeWidth
      fillColor: "transparent"
      startX: root.diameter / 2
      startY: root.diameter / 2 - root.radius
      PathAngleArc {
        centerX: root.diameter / 2
        centerY: root.diameter / 2
        radiusX: root.radius
        radiusY: root.radius
        startAngle: 90
        sweepAngle: 360
      }
    }

    // Value arc (12 o'clock, clockwise). Hidden until ratio is meaningful.
    ShapePath {
      strokeColor: root.ratio > 0.005 ? root.color : "transparent"
      strokeWidth: root.strokeWidth
      fillColor: "transparent"
      startX: root.diameter / 2
      startY: root.diameter / 2 - root.radius
      PathAngleArc {
        centerX: root.diameter / 2
        centerY: root.diameter / 2
        radiusX: root.radius
        radiusY: root.radius
        startAngle: 90
        sweepAngle: -root.ratio * 360
      }
    }
  }

  Text {
    anchors.centerIn: parent
    text: root.glyph
    font.family: root.fontFamily
    font.pixelSize: Math.max(6, Math.round(root.diameter * 0.45))
    color: root.color
    renderType: Text.NativeRendering
    visible: root.glyph !== ""
  }
}
