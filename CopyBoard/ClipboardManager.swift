import Foundation
import AppKit
import UniformTypeIdentifiers

class ClipboardManager: ObservableObject {
    @Published var history: [ClipboardItem] = []
    @Published var showPasteConfirmation: Bool = false
    @Published var showCopyConfirmation: Bool = false
    @Published var showClipboardEmptyWarning: Bool = false

    private var lastChangeCount = NSPasteboard.general.changeCount
    private var lastWrittenItem: ClipboardItem?
    private var timer: Timer?

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.checkClipboard()
        }
    }

    func checkClipboard() {
        let pasteboard = NSPasteboard.general
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount

            var newItem: ClipboardItem?

            if let text = pasteboard.string(forType: .string) {
                newItem = ClipboardItem(content: .text(text))
            } else if let image = NSImage(pasteboard: pasteboard) {
                newItem = ClipboardItem(content: .image(image))
            } else if let file = pasteboard.propertyList(forType: .fileURL) as? String,
                      let url = URL(string: file) {
                newItem = ClipboardItem(content: .file(url))
            }

            if let item = newItem, item != lastWrittenItem {
                if insert(item) {
                    DispatchQueue.main.async {
                        self.showPasteConfirmation = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.showPasteConfirmation = false
                        }
                    }
                }
            }
        }
    }

    @discardableResult
    private func insert(_ item: ClipboardItem) -> Bool {
        if history.contains(where: { $0.content == item.content }) {
            return false
        }

        history.insert(item, at: 0)
        lastWrittenItem = item

        if history.count > 8 {
            history.removeLast()
        }

        return true
    }

    func handleInternalCopy(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        var current: ClipboardItem?

        if let text = pasteboard.string(forType: .string) {
            current = ClipboardItem(content: .text(text))
        } else if let image = NSImage(pasteboard: pasteboard) {
            current = ClipboardItem(content: .image(image))
        } else if let file = pasteboard.propertyList(forType: .fileURL) as? String,
                  let url = URL(string: file) {
            current = ClipboardItem(content: .file(url))
        }

        if current != item {
            item.copyToPasteboard()
            lastWrittenItem = item

            DispatchQueue.main.async {
                self.showCopyConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showCopyConfirmation = false
                }
            }
        }

        if !history.contains(where: { $0.content == item.content }) {
            insert(item)
        }
    }

    func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            if let image = NSImage(contentsOf: url) {
                                self.insert(ClipboardItem(content: .image(image)))
                            } else {
                                self.insert(ClipboardItem(content: .file(url)))
                            }
                        }
                    }
                }
            } else if provider.canLoadObject(ofClass: NSString.self) {
                _ = provider.loadObject(ofClass: NSString.self) { object, _ in
                    if let str = object as? String {
                        DispatchQueue.main.async {
                            self.insert(ClipboardItem(content: .text(str)))
                        }
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.tiff.identifier) {
                provider.loadDataRepresentation(forTypeIdentifier: UTType.tiff.identifier) { data, _ in
                    if let data = data,
                       let image = NSImage(data: data) {
                        DispatchQueue.main.async {
                            self.insert(ClipboardItem(content: .image(image)))
                        }
                    }
                }
            }
        }
    }

    func clearHistory() {
        history.removeAll()
    }

    func forcePasteClipboard() {
        let pasteboard = NSPasteboard.general
        var newItem: ClipboardItem?

        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            newItem = ClipboardItem(content: .text(text))
        } else if let image = NSImage(pasteboard: pasteboard) {
            newItem = ClipboardItem(content: .image(image))
        } else if let file = pasteboard.propertyList(forType: .fileURL) as? String,
                  let url = URL(string: file) {
            newItem = ClipboardItem(content: .file(url))
        }

        guard let item = newItem else {
            DispatchQueue.main.async {
                self.showClipboardEmptyWarning = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showClipboardEmptyWarning = false
                }
            }
            return
        }

        if insert(item) {
            DispatchQueue.main.async {
                self.showPasteConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.showPasteConfirmation = false
                }
            }
        }
    }
}
