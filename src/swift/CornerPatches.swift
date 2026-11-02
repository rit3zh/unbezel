//
//  CornerPatches.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

func cornerPatches(_ brightness: [UInt8], width: Int, screen: Rect, radius: Int) -> [Patch] {
  let reach = 60
  let box = min(Int(Double(radius) * 1.15) + Int(Corner.margin + Corner.feather), screen.w / 2, screen.h / 2)

  return [(false, false), (true, false), (false, true), (true, true)].map { fromRight, fromBottom in
    let toX = { (i: Int) in fromRight ? screen.w - 1 - i : i }
    let toY = { (j: Int) in fromBottom ? screen.h - 1 - j : j }
    var outside = [Bool](repeating: false, count: box * box)
    for j in 0..<box {
      let sy = screen.y + toY(j)
      let edge = plateauEdge(reach + box) { brightness[sy * width + screen.x + toX($0 - reach)] }
      let cut = edge < 0 ? box : max(0, edge - reach)
      for i in 0..<min(cut, box) { outside[j * box + i] = true }
    }
    var border: [(Int, Int)] = []
    for j in 0..<box {
      for i in 0..<box where outside[j * box + i] {
        if (i + 1 < box && !outside[j * box + i + 1]) || (j + 1 < box && !outside[(j + 1) * box + i]) {
          border.append((i, j))
        }
      }
    }
    var dist = [Float](repeating: 0, count: box * box)
    for j in 0..<box {
      for i in 0..<box where !outside[j * box + i] {
        var best = Int.max
        for (bi, bj) in border {
          best = min(best, (bi - i) * (bi - i) + (bj - j) * (bj - j))
        }
        dist[j * box + i] = border.isEmpty ? .infinity : Float(best).squareRoot()
      }
    }

    var clean: [(Int, Int)] = []
    for j in 0..<box {
      for i in 0..<box where dist[j * box + i] >= Corner.margin && dist[j * box + i] < Corner.margin + 1.5 {
        clean.append((i, j))
      }
    }
    let rect = Rect(x: fromRight ? screen.w - box : 0, y: fromBottom ? screen.h - box : 0, w: box, h: box)
    let local = { (i: Int, j: Int) in (toY(j) - rect.y) * box + (toX(i) - rect.x) }

    var sources = [Int32](repeating: -1, count: box * box)
    var mask = [UInt8](repeating: 0, count: box * box)
    for j in 0..<box {
      for i in 0..<box {
        let d = dist[j * box + i]
        if d < Corner.margin {
          var best = Int.max
          var source = (i, j)
          for (ci, cj) in clean {
            let dd = (ci - i) * (ci - i) + (cj - j) * (cj - j)
            if dd < best {
              best = dd
              source = (ci, cj)
            }
          }
          sources[local(i, j)] = Int32(local(source.0, source.1))
          mask[local(i, j)] = 255
        } else {
          mask[local(i, j)] = smoothFalloff((d - Corner.margin) / Corner.feather)
        }
      }
    }
    return Patch(rect: rect, fill: .nearest(sources), mask: mask, blur: Corner.blur)
  }
}
