import SwiftUI
import AVFoundation

struct LemonView: View {
    @ObservedObject var viewModel: LemonViewModel
    @State private var showSettings = false
    @State private var lemonScale: CGFloat = 1.0
    @State private var juiceImages: [(offset: CGSize, scale: CGFloat, opacity: Double)] = []
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    
    private let soundPlayer = try? AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "pop sound", withExtension: "mp3")!)
    
    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                // 標題列
                HStack {
                    Text("今天你榨檸檬了嗎？")
                        .font(.system(size: 25, weight: .bold))
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, 90)
                .padding(.horizontal, 20)
                
                HStack(spacing: 15) {
                    // 今日榨檸檬
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(viewModel.stats.todayLemonCount)")
                            .font(.system(size: 32, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("😀擁有檸檬汁（杯）")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    // 今日被偷
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(viewModel.stats.todayStolenCount)")
                            .font(.system(size: 30, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("😭今日被偷（杯）")
                            .font(.system(size: 14))
                            .foregroundColor(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                .overlay {
                    if viewModel.showThiefAlert {
                        VStack {
                            Text("檸檬小偷👻來了！")
                                .font(.system(size: 16, weight: .bold))
                            Text(String(format: NSLocalizedString("你被偷了%d杯檸檬汁", comment: ""), viewModel.stolenAmount))
                                .font(.system(size: 14))
                        }
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .offset(y: 120)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    viewModel.showThiefAlert = false
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 檸檬圖片
                ZStack {
                    // 檸檬汁圖片
                    ForEach(0..<juiceImages.count, id: \.self) { index in
                        Image("Lemon Juice")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50)
                            .scaleEffect(juiceImages[index].scale)
                            .offset(y: juiceImages[index].offset.height)
                            .opacity(juiceImages[index].opacity)
                    }
                    
                    Image(lemonImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.35)
                        .scaleEffect(lemonScale)
                        .onTapGesture {
                            // 點擊動畫
                            withAnimation(.spring(response: 0.05, dampingFraction: 0.6)) {
                                lemonScale = 0.9
                            }
                            
                            if viewModel.lemonState == .squeezed {
                                createJuiceImages()
                            }
                            
                            // 播放音效
                            if soundEnabled {
                                soundPlayer?.currentTime = 0
                                soundPlayer?.play()
                            }
                            
                            // 觸發震動
                            if vibrationEnabled {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                            }
                            
                            viewModel.handleLemonTap()
                            
                            // 恢復大小
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                withAnimation(.spring(response: 0.05, dampingFraction: 0.6)) {
                                    lemonScale = 1.0
                                }
                            }
                        }
                }
                .padding(.bottom, 180)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
    
    private func createJuiceImages() {
        juiceImages = []
        var randomPositions: [(x: CGFloat, y: CGFloat)] = []
        
        // 先生成所有隨機位置
        for _ in 0..<5 {
            let randomX = CGFloat.random(in: -10...10)
            let randomY = CGFloat.random(in: -10...10)
            randomPositions.append((x: randomX, y: randomY))
            
            let randomScale = CGFloat.random(in: 5...7)
            juiceImages.append((
                offset: .zero,
                scale: randomScale,
                opacity: 0.8
            ))
        }
        
        // 分開處理動畫
        for i in 0..<juiceImages.count {
            withAnimation(Animation.easeOut(duration: 0.2).delay(Double(i) * 0.03)) {
                juiceImages[i].offset = CGSize(
                    width: randomPositions[i].x,
                    height: randomPositions[i].y
                )
                juiceImages[i].opacity = 0
            }
        }
        
        // 清理動畫
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            juiceImages = []
        }
    }
    
    private var lemonImageName: String {
        switch viewModel.lemonState {
        case .full: return "Lemon1"
        case .squeezed: return "Lemon2"
        case .empty: return "Lemon Juice"
        }
    }
}

struct SettingsView: View {
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("autoSqueezeEnabled") private var autoSqueezeEnabled = false
    @AppStorage("darkModeEnabled") private var darkModeEnabled = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    Text("設定")
                        .font(.title.bold())
                        .padding(.top, 70)
                    
                    VStack(spacing: 15) {
                        Toggle("震動效果", isOn: $vibrationEnabled)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Toggle("點擊音效", isOn: $soundEnabled)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Toggle("自動榨檸檬（即將推出）", isOn: $autoSqueezeEnabled)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Toggle("深色模式（即將推出）", isOn: $darkModeEnabled)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    }
                    .padding(.horizontal, 30)
                    
                    Text(String(format: NSLocalizedString("版本 %@", comment: ""), "1.0.0"))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 30)
                    
                    Spacer()
                }
            }
        }
    }
}
