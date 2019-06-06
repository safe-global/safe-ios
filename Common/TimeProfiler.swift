//
//  Copyright © 2019 Gnosis Ltd. All rights reserved.
//

import Foundation

public class TimeProfiler {

    typealias Point = (file: String, line: UInt, time: Date)
    typealias Diff = (current: Point, next: Point, diff: TimeInterval)
    let timeFormatter = NumberFormatter()
    var points = [Point]()

    public init() {
        timeFormatter.numberStyle = .decimal
    }

    public func checkpoint(file: String = #file, line: UInt = #line) {
        let basename = (file as NSString).lastPathComponent
        points.append((basename, line, Date()))
    }

    public func summary() -> String {
        let diffs = (0..<points.count - 1).map { index -> Diff in
            let current = points[index]
            let next = points[index + 1]
            let diff = next.time.timeIntervalSinceReferenceDate - current.time.timeIntervalSinceReferenceDate
            return (current, next, diff)
            }.sorted { a, b -> Bool in
                a.diff > b.diff
            }.map { diff -> String in
                "\(diff.next.file):\(diff.next.line)-\(diff.current.file):\(diff.current.line):" +
                " \(timeFormatter.string(from: NSNumber(value: diff.diff))!)"
        }
        return diffs.joined(separator: "\n")
    }
}
