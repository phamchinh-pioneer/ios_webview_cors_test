import SwiftUI

struct ContentView: View {
    var body: some View {
        WebView(htmlFileName: "index")
            .edgesIgnoringSafeArea(.all)
    }
}
