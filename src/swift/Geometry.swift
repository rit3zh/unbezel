//
//  Geometry.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

struct Rect {
  var x: Int
  var y: Int
  var w: Int
  var h: Int
}

struct FrameInfo {
  var screen: Rect
  var radius: Int
  var island: Rect?
}
