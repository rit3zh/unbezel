//
//  main.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

import AVFoundation

func run() throws {
  let options = Options.parse(CommandLine.arguments.dropFirst())

  let asset = AVURLAsset(url: options.inputURL)
  guard let videoTrack = asset.tracks(withMediaType: .video).first else {
    fail("No video track in \(options.inputURL.path)")
  }
  let audioTrack = asset.tracks(withMediaType: .audio).first
  let width = Int(videoTrack.naturalSize.width)
  let height = Int(videoTrack.naturalSize.height)

  let duration = asset.duration.seconds.isFinite ? asset.duration.seconds : 0
  emit("start", [
    "input": options.inputURL.path,
    "output": options.outputURL.path,
    "width": width,
    "height": height,
    "duration": duration,
    "fps": Double(videoTrack.nominalFrameRate),
    "audio": audioTrack != nil,
  ])

  var frameCount = 0
  let brightness = try brightnessMap(asset, videoTrack, width: width, height: height) { time in
    frameCount += 1
    let progress = duration > 0 && time.seconds.isFinite ? min(max(time.seconds / duration, 0), 1) : 0
    emit("analyze", ["progress": progress])
  }
  let info = detectFrame(brightness, width: width, height: height)
  let screen = info.screen
  emit("detected", [
    "screen": screen.json,
    "radius": info.radius,
    "island": info.island.map { $0.json as Any } ?? NSNull(),
    "keepIsland": options.keepIsland,
    "frames": frameCount,
  ])

  var patches = cornerPatches(brightness, width: width, screen: screen, radius: info.radius)
  if let island = info.island, !options.keepIsland {
    patches.append(islandPatch(island, screen: screen))
  }

  let exporter = VideoExporter(
    asset: asset,
    videoTrack: videoTrack,
    audioTrack: audioTrack,
    screen: screen,
    renderers: patches.map(PatchRenderer.init),
    onFrame: { [total = frameCount] in emit("export", ["frames": $0, "total": total]) }
  )
  let frames = try exporter.export(to: options.outputURL)
  emit("saved", ["output": options.outputURL.path, "frames": frames])
}

setvbuf(stdout, nil, _IOLBF, 0)

do {
  try run()
} catch {
  fail("\(error)")
}
