import Foundation
import AppKit

enum ClipboardContent: Equatable {
    case text(String)
    case image(NSImage)
    case file(URL)

    static func == (lhs: ClipboardContent, rhs: ClipboardContent) -> Bool {
        switch (lhs, rhs) {
        case (.text(let a), .text(let b)): return a == b
        case (.file(let a), .file(let b)): return a == b
        case (.image(let a), .image(let b)):
            return a.tiffRepresentation == b.tiffRepresentation
        default: return false
        }
    }
}

struct ClipboardItem: Identifiable, Equatable {
    let id = UUID()
    let content: ClipboardContent

    func copyToPasteboard() {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch content {
        case .text(let text):
            pb.setString(text, forType: .string)
        case .image(let image):
            pb.writeObjects([image])
        case .file(let url):
            pb.writeObjects([url as NSURL])
        }
    }
}
