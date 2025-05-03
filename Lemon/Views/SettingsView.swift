import SwiftUI

struct SettingsView: View {
    // 移除舊的震動設定
    @Binding var autoSqueezeEnabled: Bool
    @AppStorage("fallingAnimationEnabled") private var fallingAnimationEnabled = true
    
    init(autoSqueezeEnabled: Binding<Bool>) {
        self._autoSqueezeEnabled = autoSqueezeEnabled
    }
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    HStack {
                        Text("設定")
                            .font(.title.bold())
                            .foregroundColor(.black)
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, hasNotch() ? 70 : 110)
                    .padding(.horizontal, 30)
                    
                    VStack(spacing: 15) {
                        Toggle("震動效果", isOn: Binding(
                            get: { UserDefaults.standard.bool(forKey: "hapticsEnabled") },
                            set: { UserDefaults.standard.set($0, forKey: "hapticsEnabled") }
                        ))
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .foregroundColor(.black)
                            .tint(.orange)

                        Toggle("掉落效果", isOn: $fallingAnimationEnabled)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .foregroundColor(.black)
                            .tint(.orange)
                        
                        Toggle("自動榨檸檬", isOn: $autoSqueezeEnabled)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .foregroundColor(.black)
                            .tint(.orange)
                        
                    }
                    .padding(.horizontal, 30)
                    
                    Text(String(format: NSLocalizedString("版本 %@", comment: ""), "1.1.0"))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 30)
                    
                    Text(NSLocalizedString("免責聲明本遊戲故事純屬虛構如有雷同那是你想太多", comment: ""))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                        .multilineTextAlignment(.center)
                    
                    Spacer()
                }
            }
        }
    }
}
