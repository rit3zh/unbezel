//
//  EdgeScanner.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

func innerEdge(_ count: Int, _ pixel: (Int) -> UInt8) -> Int {
  var darkRun = 0
  for i in 0..<count {
    if pixel(i) < Bezel.darkThreshold {
      darkRun += 1
    } else if darkRun >= Bezel.minRun {
      return i
    } else {
      darkRun = 0
    }
  }
  return -1
}

func plateauEdge(_ count: Int, _ pixel: (Int) -> UInt8) -> Int {
  let edge = innerEdge(count, pixel)
  guard edge >= 0 else { return edge }
  var i = edge
  while i + 1 < count && i - edge < 32 && Int(pixel(i + 1)) > Int(pixel(i)) + 1 { i += 1 }
  return i
}

func medianEdge(_ values: [Int]) -> Int {
  let sorted = values.filter { $0 >= 0 }.sorted()
  if sorted.isEmpty { fail("Could not find the device bezel") }
  return sorted[sorted.count / 2]
}
