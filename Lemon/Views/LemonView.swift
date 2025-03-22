import SwiftUI
import AVFoundation

// 添加檢測瀏海的工具
extension View {
    func hasNotch() -> Bool {
        let keyWindow = UIApplication.shared.windows.filter { $0.isKeyWindow }.first
        return keyWindow?.safeAreaInsets.top ?? 0 > 20
    }
}

struct LemonView: View {
    @ObservedObject var viewModel: LemonViewModel
    @State private var showSettings = false
    @State private var lemonScale: CGFloat = 1.0
    @State private var juiceImages: [(offset: CGSize, scale: CGFloat, opacity: Double)] = []
    @State private var fallingLemons: [(id: UUID, yOffset: CGFloat, xOffset: CGFloat, finalYOffset: CGFloat, opacity: Double)] = []
    @State private var showLemonTip = false
    @State private var showStolenTip = false
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("fallingAnimationEnabled") private var fallingAnimationEnabled = true
    
    private let soundPlayer = try? AVAudioPlayer(contentsOf: Bundle.main.url(forResource: "pop sound", withExtension: "mp3")!)
    private let screenHeight = UIScreen.main.bounds.height
    private let lemonSize: CGFloat = 30
    private let maxStackHeight: CGFloat = UIScreen.main.bounds.height * 0.6
    
    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 0) {
                // 標題列
                HStack {
                    Text("今天你被偷了嗎？")
                        .font(.system(size: 25, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Spacer()
                    Button(action: {
                        showSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, hasNotch() ? 90 : 120)
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
                    .onTapGesture {
                        showLemonTip.toggle()
                    }
                    
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
                    .onTapGesture {
                        showStolenTip.toggle()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
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
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                viewModel.showThiefAlert = false
                            }
                        }
                    }
                }
                
                Spacer()
                
                // 檸檬圖片
                ZStack {
                    // 掉落的檸檬
                    ForEach(fallingLemons, id: \.id) { lemon in
                        Image("Lemon1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30)
                            .offset(x: lemon.xOffset, y: lemon.yOffset)
                            .opacity(lemon.opacity)
                    }
                    
                    // 檸檬汁圖片
                    ForEach(0..<juiceImages.count, id: \.self) { index in
                        Image("Lemon Juice")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50)
                            .scaleEffect(juiceImages[index].scale)
                            .offset(y: -60)
                            .opacity(juiceImages[index].opacity)
                    }
                    
                    Image(lemonImageName)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: UIScreen.main.bounds.height * 0.35)
                        .offset(y: -60)
                        .scaleEffect(lemonScale)
                        .onTapGesture {
                            // 點擊動畫
                            withAnimation(.spring(response: 0.05, dampingFraction: 0.6)) {
                                lemonScale = 0.9
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

                            if viewModel.lemonState == .squeezed {
                                createJuiceImages()
                            }
                            
                            if fallingAnimationEnabled {    
                                addFallingLemon()
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
        .overlay {
            if showLemonTip {
                VStack {
                    Text("遊戲提示")
                        .font(.headline)
                    Text("點擊兩下可榨一杯檸檬汁")
                        .font(.subheadline)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
            
            if showStolenTip {
                VStack {
                    Text("遊戲提示")
                        .font(.headline)
                    Text("一定點擊次數內有25%到75%機率被偷走25%到75%擁有檸檬汁")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
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
    
    private func addFallingLemon() {
        // 計算新檸檬的隨機水平位置
        let xOffset = CGFloat.random(in: -200...200)
        
        // 找到該x位置附近最高的檸檬
        var highestY = screenHeight * 0.25 // 基礎高度
        
        for lemon in fallingLemons {
            if abs(lemon.xOffset - xOffset) < lemonSize * 0.7 && lemon.opacity > 0.5 { // 只考慮不透明的檸檬
                let topOfLemon = lemon.finalYOffset - lemonSize * 0.7 // 留一點空間
                if topOfLemon < highestY {
                    highestY = topOfLemon
                }
            }
        }
        
        // 確保不超過最大堆疊高度
        if highestY < -maxStackHeight {
            return // 如果堆得太高就不再添加
        }
        
        let newLemon = (
            id: UUID(),
            yOffset: -screenHeight * 0.1, // 起始位置
            xOffset: xOffset,
            finalYOffset: highestY,
            opacity: 1.0
        )
        
        fallingLemons.append(newLemon)
        
        // 開始掉落動畫，使用彈跳效果模擬重力
        withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
            if let index = fallingLemons.firstIndex(where: { $0.id == newLemon.id }) {
                fallingLemons[index].yOffset = newLemon.finalYOffset
            }
        }
        
        // 15秒後淡出並移除
        DispatchQueue.main.asyncAfter(deadline: .now() + 14.5) {
            if let index = fallingLemons.firstIndex(where: { $0.id == newLemon.id }) {
                withAnimation(.easeOut(duration: 0.5)) {
                    fallingLemons[index].opacity = 0
                }
                
                // 檢查並更新上方檸檬的位置
                updateLemonsAbove(removedLemon: fallingLemons[index])
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 15.0) {
            fallingLemons.removeAll { $0.id == newLemon.id }
        }
    }
    
    private func updateLemonsAbove(removedLemon: (id: UUID, yOffset: CGFloat, xOffset: CGFloat, finalYOffset: CGFloat, opacity: Double)) {
        // 找出所有在被移除檸檬上方的檸檬
        let affectedLemons = fallingLemons.filter { lemon in
            lemon.opacity > 0.5 && // 只考慮不透明的檸檬
            abs(lemon.xOffset - removedLemon.xOffset) < lemonSize * 1.2 && // 在水平範圍內
            lemon.finalYOffset < removedLemon.finalYOffset // 在上方
        }
        
        // 更新這些檸檬的位置
        for affectedLemon in affectedLemons {
            if let index = fallingLemons.firstIndex(where: { $0.id == affectedLemon.id }) {
                // 計算新的最終位置
                var newHighestY = screenHeight * 0.25
                
                // 檢查下方的檸檬
                for lemon in fallingLemons {
                    if lemon.opacity > 0.5 && // 只考慮不透明的檸檬
                       abs(lemon.xOffset - affectedLemon.xOffset) < lemonSize * 0.7 && // 在水平範圍內
                       lemon.finalYOffset > affectedLemon.finalYOffset && // 在下方
                       lemon.id != affectedLemon.id { // 不是自己
                        let topOfLemon = lemon.finalYOffset - lemonSize * 0.7
                        if topOfLemon < newHighestY {
                            newHighestY = topOfLemon
                        }
                    }
                }
                
                // 使用彈跳動畫更新位置
                withAnimation(.interpolatingSpring(mass: 1.0, stiffness: 100, damping: 10, initialVelocity: 0)) {
                    fallingLemons[index].finalYOffset = newHighestY
                    fallingLemons[index].yOffset = newHighestY
                }
            }
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
    @AppStorage("fallingAnimationEnabled") private var fallingAnimationEnabled = true
    @Environment(\.dismiss) private var dismiss
    
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
                        Toggle("震動效果", isOn: $vibrationEnabled)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Toggle("點擊音效", isOn: $soundEnabled)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 15).fill(Color.white.opacity(0.9)))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        
                        Toggle("掉落效果", isOn: $fallingAnimationEnabled)
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
