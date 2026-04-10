import Foundation

extension Array where Element: Hashable {
    mutating func appendDeduplicating(contentsOf newItems: [Element]) {
        var seen = Set(self)
        for item in newItems where !seen.contains(item) {
            append(item)
            seen.insert(item)
        }
    }
}
