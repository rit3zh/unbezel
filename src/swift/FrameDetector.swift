//
//  FrameDetector.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

func detectFrame(_ brightness: [UInt8], width: Int, height: Int) -> FrameInfo {
  let at = { (x: Int, y: Int) in brightness[y * width + x] }
  let rows = [0.4, 0.5, 0.6].map { Int(Double(height) * $0) }
  let cols = [0.3, 0.7].map { Int(Double(width) * $0) }
  let left = medianEdge(rows.map { y in innerEdge(width) { at($0, y) } })
  let right = width - 1 - medianEdge(rows.map { y in innerEdge(width) { at(width - 1 - $0, y) } })
  let top = medianEdge(cols.map { x in innerEdge(height) { at(x, $0) } })
  let bottom = height - 1 - medianEdge(cols.map { x in innerEdge(height) { at(x, height - 1 - $0) } })

  let diagonals = [(left, top, 1, 1), (right, top, -1, 1), (left, bottom, 1, -1), (right, bottom, -1, -1)]
    .map { x, y, dx, dy in innerEdge((right - left) / 2) { at(x + $0 * dx, y + $0 * dy) } }
  let radius = Int((Double(diagonals.max()!) / (1 - 0.5.squareRoot())).rounded(.up))
  let screen = Rect(
    x: left + Bezel.edgeInset,
    y: top + Bezel.edgeInset,
    w: (right - left + 1 - Bezel.edgeInset * 2) & ~1,
    h: (bottom - top + 1 - Bezel.edgeInset * 2) & ~1
  )
  let island = detectIsland(at, left: left, right: right, top: top, height: height)
  return FrameInfo(screen: screen, radius: radius, island: island)
}

private func detectIsland(_ at: (Int, Int) -> UInt8, left: Int, right: Int, top: Int, height: Int) -> Rect? {
  let dark = Bezel.darkThreshold
  let cx = (left + right) / 2
  let limit = top + height / 10

  var y = top + Bezel.edgeInset
  while y < limit && at(cx, y) >= dark { y += 1 }
  if y >= limit { return nil }
  let y0 = y
  while at(cx, y) < dark { y += 1 }
  let y1 = y - 1
  let cy = (y0 + y1) / 2
  var x0 = cx
  var x1 = cx
  while at(x0 - 1, cy) < dark { x0 -= 1 }
  while at(x1 + 1, cy) < dark { x1 += 1 }

  if y1 - y0 < 20 || x1 - x0 < y1 - y0 { return nil }
  return Rect(
    x: x0 - Island.padding,
    y: y0 - Island.padding,
    w: x1 - x0 + 1 + Island.padding * 2,
    h: y1 - y0 + 1 + Island.padding * 2
  )
}
