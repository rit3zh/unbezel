//
//  PatchRenderer.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

import Accelerate

final class PatchRenderer {
  let patch: Patch
  private var original: [UInt8]
  private var filled: [UInt8]
  private var blurred: [UInt8]
  private var scratch: [UInt8]

  init(_ patch: Patch) {
    self.patch = patch
    let size = patch.rect.w * patch.rect.h * 4
    original = [UInt8](repeating: 0, count: size)
    filled = original
    blurred = original
    scratch = original
  }

  func render(_ frame: UnsafeMutablePointer<UInt8>, stride: Int) {
    copyIn(frame, stride: stride)
    fill()
    blur()
    blend(into: frame, stride: stride)
  }

  private func copyIn(_ frame: UnsafeMutablePointer<UInt8>, stride: Int) {
    let r = patch.rect
    let rowBytes = r.w * 4
    for y in 0..<r.h {
      original.withUnsafeMutableBytes {
        $0.baseAddress!.advanced(by: y * rowBytes).copyMemory(from: frame + (r.y + y) * stride + r.x * 4, byteCount: rowBytes)
      }
    }
    filled = original
  }

  private func fill() {
    let r = patch.rect
    switch patch.fill {
    case .nearest(let sources):
      for (i, source) in sources.enumerated() where source >= 0 {
        for c in 0..<4 { filled[i * 4 + c] = original[Int(source) * 4 + c] }
      }

    case .interpolate(let inner):
      for y in inner.y..<(inner.y + inner.h) {
        for x in inner.x..<(inner.x + inner.w) {
          let neighbors = [
            (inner.x - 1, y, Float(x - inner.x + 1)),
            (inner.x + inner.w, y, Float(inner.x + inner.w - x)),
            (x, inner.y - 1, Float(y - inner.y + 1)),
            (x, inner.y + inner.h, Float(inner.y + inner.h - y)),
          ]
          let total = neighbors.reduce(0) { $0 + 1 / $1.2 }
          for c in 0..<4 {
            let value = neighbors.reduce(Float(0)) { $0 + Float(original[($1.1 * r.w + $1.0) * 4 + c]) / $1.2 }
            filled[(y * r.w + x) * 4 + c] = UInt8((value / total).rounded())
          }
        }
      }
    }
  }

  private func blur() {
    let r = patch.rect
    let rowBytes = r.w * 4
    filled.withUnsafeMutableBytes { filled in
      blurred.withUnsafeMutableBytes { blurred in
        scratch.withUnsafeMutableBytes { scratch in
          var a = vImage_Buffer(data: filled.baseAddress, height: vImagePixelCount(r.h), width: vImagePixelCount(r.w), rowBytes: rowBytes)
          var b = vImage_Buffer(data: blurred.baseAddress, height: vImagePixelCount(r.h), width: vImagePixelCount(r.w), rowBytes: rowBytes)
          var c = vImage_Buffer(data: scratch.baseAddress, height: vImagePixelCount(r.h), width: vImagePixelCount(r.w), rowBytes: rowBytes)
          let size = UInt32(patch.blur | 1)
          let flags = vImage_Flags(kvImageEdgeExtend)
          vImageBoxConvolve_ARGB8888(&a, &b, nil, 0, 0, size, size, nil, flags)
          vImageBoxConvolve_ARGB8888(&b, &c, nil, 0, 0, size, size, nil, flags)
          vImageBoxConvolve_ARGB8888(&c, &b, nil, 0, 0, size, size, nil, flags)
        }
      }
    }
  }

  private func blend(into frame: UnsafeMutablePointer<UInt8>, stride: Int) {
    let r = patch.rect
    for y in 0..<r.h {
      let row = frame + (r.y + y) * stride + r.x * 4
      for x in 0..<r.w {
        let m = Int(patch.mask[y * r.w + x])
        guard m > 0 else { continue }
        let i = (y * r.w + x) * 4
        for c in 0..<3 {
          row[x * 4 + c] = UInt8((Int(original[i + c]) * (255 - m) + Int(blurred[i + c]) * m + 127) / 255)
        }
      }
    }
  }
}
