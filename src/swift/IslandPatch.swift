//
//  IslandPatch.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

func islandPatch(_ island: Rect, screen: Rect) -> Patch {
  let margin = Int(Island.feather) + Island.blur
  let rect = Rect(
    x: island.x - screen.x - margin,
    y: island.y - screen.y - margin,
    w: island.w + margin * 2,
    h: island.h + margin * 2
  )
  let inner = Rect(x: margin, y: margin, w: island.w, h: island.h)

  var mask = [UInt8](repeating: 0, count: rect.w * rect.h)
  for y in 0..<rect.h {
    for x in 0..<rect.w {
      let dx = max(inner.x - x, 0, x - (inner.x + inner.w - 1))
      let dy = max(inner.y - y, 0, y - (inner.y + inner.h - 1))
      mask[y * rect.w + x] = smoothFalloff(Float(dx * dx + dy * dy).squareRoot() / Island.feather)
    }
  }
  return Patch(rect: rect, fill: .interpolate(inner), mask: mask, blur: Island.blur)
}
