//
//  Options.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

import Foundation

struct Options {
  static let usage = "Usage: bun run unbezel <input> [output] [--keep-island]"

  var inputURL: URL
  var outputURL: URL
  var keepIsland: Bool

  static func parse(_ arguments: some Sequence<String>) -> Options {
    let flags = Set(arguments.filter { $0.hasPrefix("--") })
    let paths = arguments.filter { !$0.hasPrefix("--") }
    guard let inputPath = paths.first else { fail(usage) }

    let inputURL = URL(fileURLWithPath: inputPath).standardizedFileURL
    let inputName = inputURL.deletingPathExtension().lastPathComponent
    let name = inputName.replacingOccurrences(of: "-with-frame", with: "", options: [.anchored, .backwards])
    let outputURL = paths.count > 1
      ? URL(fileURLWithPath: paths[1]).standardizedFileURL
      : inputURL.deletingLastPathComponent().appendingPathComponent(name == inputName ? "\(name)-no-frame.mp4" : "\(name).mp4")

    return Options(inputURL: inputURL, outputURL: outputURL, keepIsland: flags.contains("--keep-island"))
  }
}
