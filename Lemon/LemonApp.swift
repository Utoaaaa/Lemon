import SwiftUI

@main
struct LemonApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
    }
}

struct MainTabView: View {
    @StateObject private var viewModel = LemonViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            LemonView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "drop.fill")
                }
                .tag(0)
            
            StatsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                }
                .tag(1)
        }
    }
}
