//
//  Diagnostics.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

import Foundation

func fail(_ message: String) -> Never {
  emit("error", ["message": message])
  exit(1)
}
