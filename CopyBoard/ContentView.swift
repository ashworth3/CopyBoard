import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject var clipboard = ClipboardManager()
    @State private var selectedText: String? = nil
    @State private var showingPreview = false
    @State private var isTargeted: Bool = false
    @State private var hoveringClear = false
    @State private var hoveringPaste = false
    @State private var hoveringLinkID: UUID?
    @State private var showingInfoModal = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Text("📋 CopyBoard")
                    .font(.title2)
                    .bold()

                Button(action: {
                    showingInfoModal = true
                }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.gray)
                        .help("How to use CopyBoard")
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button(action: {
                    clipboard.forcePasteClipboard()
                }) {
                    Label("Paste Clipboard", systemImage: "arrow.down.doc")
                        .foregroundColor(hoveringPaste ? .white : .blue)
                        .padding(6)
                        .background(hoveringPaste ? Color.blue.opacity(0.8) : Color.clear)
                        .cornerRadius(6)
                        .help("Manually paste the current clipboard content")
                }
                .buttonStyle(BorderlessButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveringPaste = hovering
                    }
                }

                Button(action: {
                    clipboard.clearHistory()
                }) {
                    Label("Clear History", systemImage: "trash")
                        .foregroundColor(hoveringClear ? .white : .red)
                        .padding(6)
                        .background(hoveringClear ? Color.red.opacity(0.8) : Color.clear)
                        .cornerRadius(6)
                        .help("Clear all clipboard items")
                }
                .buttonStyle(BorderlessButtonStyle())
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        hoveringClear = hovering
                    }
                }
            }
            .padding([.top, .horizontal])

            Divider()
                .padding(.horizontal)

            ZStack {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 8) {
                        ForEach(clipboard.history) { item in
                            HStack(spacing: 8) {
                                Group {
                                    switch item.content {
                                    case .text(let text):
                                        VStack(alignment: .leading, spacing: 4) {
                                            if let url = URL(string: text), url.scheme != nil {
                                                let cleanText = text
                                                    .replacingOccurrences(of: "https://", with: "")
                                                    .replacingOccurrences(of: "http://", with: "")
                                                    .replacingOccurrences(of: "www.", with: "")
                                                    .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                                                Text(cleanText)
                                                    .underline()
                                                    .foregroundColor(hoveringLinkID == item.id ? .blue.opacity(0.7) : .blue)
                                                    .onTapGesture {
                                                        NSWorkspace.shared.open(url)
                                                    }
                                                    .onHover { hovering in
                                                        if hovering {
                                                            NSCursor.pointingHand.push()
                                                            hoveringLinkID = item.id
                                                        } else {
                                                            NSCursor.pop()
                                                            hoveringLinkID = nil
                                                        }
                                                    }
                                                    .lineLimit(3)
                                                    .truncationMode(.tail)
                                            } else {
                                                Text(text)
                                                    .lineLimit(3)
                                                    .truncationMode(.tail)
                                            }

                                            if text.count > 100 {
                                                Button("Preview") {
                                                    selectedText = text
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                                        showingPreview = true
                                                    }
                                                }
                                                .font(.caption)
                                                .buttonStyle(BorderlessButtonStyle())
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)

                                    case .image(let img):
                                        Image(nsImage: img)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 64, height: 64)
                                            .cornerRadius(4)

                                    case .file(let url):
                                        VStack(alignment: .leading, spacing: 2) {
                                            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                            Text(url.lastPathComponent)
                                                .font(.caption2)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                }

                                Spacer(minLength: 8)

                                Button("Copy") {
                                    clipboard.handleInternalCopy(item)
                                }
                                .frame(width: 50)
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding(.horizontal)
                            .onDrag {
                                switch item.content {
                                case .text(let text):
                                    return NSItemProvider(object: text as NSString)
                                case .file(let url):
                                    return NSItemProvider(contentsOf: url)!
                                case .image(let image):
                                    if #available(macOS 13.0, *) {
                                        return NSItemProvider(object: image)
                                    } else {
                                        return NSItemProvider()
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }
                .onDrop(of: [UTType.fileURL.identifier, UTType.plainText.identifier, UTType.tiff.identifier], isTargeted: $isTargeted) { providers in
                    clipboard.handleDrop(providers: providers)
                    return true
                }

                if isTargeted {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            Text("📅 Drop item to add")
                                .font(.headline)
                                .foregroundColor(.blue)
                        )
                        .padding(12)
                        .transition(.opacity)
                }

                if clipboard.showPasteConfirmation {
                    VStack {
                        Spacer()
                        Text("✔️ Pasted!")
                            .font(.caption)
                            .padding(6)
                            .background(Color.green.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .transition(.opacity)
                        Spacer().frame(height: 12)
                    }
                    .animation(.easeInOut(duration: 0.2), value: clipboard.showPasteConfirmation)
                }

                if clipboard.showCopyConfirmation {
                    VStack {
                        Spacer()
                        Text("✔️ Copied!")
                            .font(.caption)
                            .padding(6)
                            .background(Color.blue.opacity(0.85))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .transition(.opacity)
                        Spacer().frame(height: 12)
                    }
                    .animation(.easeInOut(duration: 0.2), value: clipboard.showCopyConfirmation)
                }

                if clipboard.showClipboardEmptyWarning {
                    VStack {
                        Spacer()
                        Text("⚠️ Clipboard is empty")
                            .font(.caption)
                            .padding(6)
                            .background(Color.orange.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .transition(.opacity)
                        Spacer().frame(height: 12)
                    }
                    .animation(.easeInOut(duration: 0.2), value: clipboard.showClipboardEmptyWarning)
                }
            }
        }
        .frame(width: 600, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            clipboard.startMonitoring()
        }
        .sheet(isPresented: $showingPreview) {
            VStack(alignment: .leading) {
                Text("Full Text")
                    .font(.headline)
                    .padding(.bottom, 4)

                ScrollView {
                    Text(selectedText ?? "")
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(width: 300, height: 400)

                Button("Close") {
                    showingPreview = false
                }
                .padding(.top)
            }
            .padding()
        }
        .sheet(isPresented: $showingInfoModal) {
            VStack(alignment: .leading, spacing: 16) {
                Text("How to Use CopyBoard")
                    .font(.title2)
                    .bold()

                Group {
                    Label("Copy any text, link, or image as usual", systemImage: "doc.on.doc")
                    Label("Use the Paste button to manually save the clipboard", systemImage: "arrow.down.doc")
                    Label("Drag and drop images or files into the app window", systemImage: "tray.and.arrow.down")
                    Label("Click Copy to reuse an item", systemImage: "arrowshape.turn.up.left")
                    Label("Compatible with: text, links, images, files", systemImage: "checkmark.seal")
                }
                .font(.body)

                Spacer()

                Button("Got it!") {
                    showingInfoModal = false
                }
                .padding(.top)
            }
            .padding()
            .frame(width: 360, height: 340)
        }
    }
}
