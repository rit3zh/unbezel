//
//  Tuning.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

enum Bezel {
  static let darkThreshold: UInt8 = 35
  static let minRun = 8
  static let edgeInset = 3
  static let sampleEvery = 30
}

enum Corner {
  static let margin: Float = 10
  static let feather: Float = 24
  static let blur = 25
}

enum Island {
  static let padding = 6
  static let feather: Float = 10
  static let blur = 15
}
