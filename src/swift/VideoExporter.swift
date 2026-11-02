//
//  VideoExporter.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

import AVFoundation
import CoreVideo

struct VideoExporter {
  let asset: AVAsset
  let videoTrack: AVAssetTrack
  let audioTrack: AVAssetTrack?
  let screen: Rect
  let renderers: [PatchRenderer]
  let onFrame: (Int) -> Void

  func export(to outputURL: URL) throws -> Int {
    let reader = try AVAssetReader(asset: asset)
    let videoOutput = AVAssetReaderTrackOutput(
      track: videoTrack,
      outputSettings: [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
    )
    videoOutput.alwaysCopiesSampleData = false
    reader.add(videoOutput)
    let audioOutput = audioTrack.map { AVAssetReaderTrackOutput(track: $0, outputSettings: nil) }
    if let audioOutput { reader.add(audioOutput) }

    try? FileManager.default.removeItem(at: outputURL)
    let writer = try AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    let videoInput = makeVideoInput()
    let adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoInput, sourcePixelBufferAttributes: [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
      kCVPixelBufferWidthKey as String: screen.w,
      kCVPixelBufferHeightKey as String: screen.h,
    ])
    writer.add(videoInput)
    let audioInput = makeAudioInput()
    if let audioInput { writer.add(audioInput) }

    reader.startReading()
    writer.startWriting()
    writer.startSession(atSourceTime: .zero)

    let group = DispatchGroup()
    var frames = 0

    group.enter()
    videoInput.requestMediaDataWhenReady(on: DispatchQueue(label: "video")) {
      while videoInput.isReadyForMoreMediaData {
        guard let sample = videoOutput.copyNextSampleBuffer(), let source = CMSampleBufferGetImageBuffer(sample) else {
          videoInput.markAsFinished()
          group.leave()
          return
        }
        var output: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &output)
        guard let output else { fail("Could not allocate an output frame") }

        renderFrame(from: source, into: output)
        adaptor.append(output, withPresentationTime: CMSampleBufferGetPresentationTimeStamp(sample))
        frames += 1
        onFrame(frames)
      }
    }

    if let audioInput, let audioOutput {
      group.enter()
      audioInput.requestMediaDataWhenReady(on: DispatchQueue(label: "audio")) {
        while audioInput.isReadyForMoreMediaData {
          guard let sample = audioOutput.copyNextSampleBuffer() else {
            audioInput.markAsFinished()
            group.leave()
            return
          }
          audioInput.append(sample)
        }
      }
    }

    group.wait()
    if reader.status == .failed { fail("Reading failed: \(reader.error!)") }

    let done = DispatchSemaphore(value: 0)
    writer.finishWriting { done.signal() }
    done.wait()
    if writer.status != .completed { fail("Writing failed: \(writer.error?.localizedDescription ?? "unknown error")") }

    return frames
  }

  private func renderFrame(from source: CVPixelBuffer, into output: CVPixelBuffer) {
    CVPixelBufferLockBaseAddress(source, .readOnly)
    CVPixelBufferLockBaseAddress(output, [])
    defer {
      CVPixelBufferUnlockBaseAddress(output, [])
      CVPixelBufferUnlockBaseAddress(source, .readOnly)
    }

    let src = CVPixelBufferGetBaseAddress(source)!.assumingMemoryBound(to: UInt8.self)
    let dst = CVPixelBufferGetBaseAddress(output)!.assumingMemoryBound(to: UInt8.self)
    let srcStride = CVPixelBufferGetBytesPerRow(source)
    let dstStride = CVPixelBufferGetBytesPerRow(output)
    for y in 0..<screen.h {
      (dst + y * dstStride).update(from: src + (screen.y + y) * srcStride + screen.x * 4, count: screen.w * 4)
    }
    for renderer in renderers { renderer.render(dst, stride: dstStride) }
  }

  private func makeVideoInput() -> AVAssetWriterInput {
    let sourceArea = videoTrack.naturalSize.width * videoTrack.naturalSize.height
    let bitrate = Double(videoTrack.estimatedDataRate) * Double(screen.w * screen.h) / Double(sourceArea) * 1.1

    let input = AVAssetWriterInput(mediaType: .video, outputSettings: [
      AVVideoCodecKey: AVVideoCodecType.h264,
      AVVideoWidthKey: screen.w,
      AVVideoHeightKey: screen.h,
      AVVideoColorPropertiesKey: [
        AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
        AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
        AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
      ],
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: Int(bitrate),
        AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
        AVVideoExpectedSourceFrameRateKey: videoTrack.nominalFrameRate,
        AVVideoAllowFrameReorderingKey: true,
      ],
    ])
    input.transform = videoTrack.preferredTransform
    input.expectsMediaDataInRealTime = false
    return input
  }

  private func makeAudioInput() -> AVAssetWriterInput? {
    guard let audioTrack else { return nil }
    let input = AVAssetWriterInput(
      mediaType: .audio,
      outputSettings: nil,
      sourceFormatHint: (audioTrack.formatDescriptions.first as! CMFormatDescription)
    )
    input.expectsMediaDataInRealTime = false
    return input
  }
}
