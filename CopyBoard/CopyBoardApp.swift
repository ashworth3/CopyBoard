import SwiftUI

@main
struct CopyBoardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("CopyBoard", id: "main") {
            ContentView()
                .frame(width: 300, height: 400)
        }

        if #available(macOS 13.0, *) {
            Window("About CopyBoard", id: "about") {
                VStack {
                    Text("📋 CopyBoard")
                        .font(.title)
                    Text("Version 1.1")
                    Text("Built with ❤️ using Swift")
                    Text("macOS Clipboard Manager")
                }
                .padding()
                .frame(width: 250, height: 150)
            }
        }
    }
}
