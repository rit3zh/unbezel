//
//  BrightnessMap.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

import AVFoundation
import CoreVideo

func brightnessMap(_ asset: AVAsset, _ track: AVAssetTrack, width: Int, height: Int, onFrame: (CMTime) -> Void) throws -> [UInt8] {
  let reader = try AVAssetReader(asset: asset)
  let output = AVAssetReaderTrackOutput(
    track: track,
    outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
  )
  reader.add(output)
  reader.startReading()

  var peak = [UInt8](repeating: 0, count: width * height)
  var index = 0
  while let sample = output.copyNextSampleBuffer() {
    defer { index += 1 }
    onFrame(CMSampleBufferGetPresentationTimeStamp(sample))
    guard index % Bezel.sampleEvery == 0, let buffer = CMSampleBufferGetImageBuffer(sample) else { continue }

    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    let base = CVPixelBufferGetBaseAddressOfPlane(buffer, 0)!.assumingMemoryBound(to: UInt8.self)
    let stride = CVPixelBufferGetBytesPerRowOfPlane(buffer, 0)
    peak.withUnsafeMutableBufferPointer { peak in
      for y in 0..<height {
        let row = base + y * stride
        for x in 0..<width where row[x] > peak[y * width + x] {
          peak[y * width + x] = row[x]
        }
      }
    }
    CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
  }

  if reader.status == .failed { throw reader.error! }
  return peak
}
