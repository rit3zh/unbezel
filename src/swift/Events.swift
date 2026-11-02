//
//  Events.swift
//  unbezel
//
//  Created by rit3zh CX on 11/2/26.
//

import Foundation

func emit(_ event: String, _ fields: [String: Any] = [:]) {
  var payload = fields
  payload["event"] = event
  guard let data = try? JSONSerialization.data(withJSONObject: payload) else { return }
  FileHandle.standardOutput.write(data + Data([0x0A]))
}

extension Rect {
  var json: [String: Int] { ["x": x, "y": y, "w": w, "h": h] }
}
