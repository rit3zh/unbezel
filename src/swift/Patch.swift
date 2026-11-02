//
//  Patch.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

struct Patch {
  enum Fill {
    case nearest([Int32])
    case interpolate(Rect)
  }

  var rect: Rect
  var fill: Fill
  var mask: [UInt8]
  var blur: Int
}

func smoothFalloff(_ t: Float) -> UInt8 {
  let t = min(max(t, 0), 1)
  return UInt8(((1 - t * t * (3 - 2 * t)) * 255).rounded())
}
