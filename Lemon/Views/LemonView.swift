import SwiftUI

// 添加檢測瀏海的工具
extension View {
    func hasNotch() -> Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return false
        }
        return window.safeAreaInsets.top > 20
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
    @AppStorage("vibrationEnabled") private var vibrationEnabled = true
    @AppStorage("fallingAnimationEnabled") private var fallingAnimationEnabled = true
    private var autoSqueezeEnabled: Binding<Bool> {
        Binding(
            get: { viewModel.autoSqueezeEnabled },
            set: { newValue in
                viewModel.autoSqueezeEnabled = newValue
                if newValue {
                    startAutoSqueezeTimerIfEnabled()
                } else {
                    stopAutoSqueezeTimer()
                }
            }
        )
    }
    @State private var autoSqueezeTimer: Timer? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    private let screenHeight = UIScreen.main.bounds.height
    private let lemonSize: CGFloat = 30
    private let maxStackHeight: CGFloat = UIScreen.main.bounds.height * 0.6
    
    init(viewModel: LemonViewModel) {
        self.viewModel = viewModel
    }
    
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
                        .foregroundColor(.black)
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
                            .foregroundColor(.black)
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
                            .foregroundColor(.black)
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
                            .foregroundColor(.white)
                        Text(String(format: NSLocalizedString("你被偷了%d杯檸檬汁", comment: ""), viewModel.stolenAmount))
                            .font(.system(size: 14))
                            .foregroundColor(.white)
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
                            // 简化点击动画
                            withAnimation(.easeOut(duration: 0.1)) {
                                lemonScale = 0.98
                            }
                            
                            // 触发震动
                            if vibrationEnabled {
                                let generator = UIImpactFeedbackGenerator(style: .heavy)
                                generator.impactOccurred()
                            }

                            if viewModel.lemonState == .squeezed {
                                createJuiceImages()
                            }
                            
                            if fallingAnimationEnabled {    
                                addFallingLemon()
                            }
                            viewModel.handleLemonTap()
                            
                            // 恢复大小
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                withAnimation(.easeOut(duration: 0.1)) {
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
                        .foregroundColor(.black)
                    Text("點擊兩下可榨一杯檸檬汁")
                        .font(.subheadline)
                        .foregroundColor(.black)
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
                        .foregroundColor(.black)
                    Text("一定點擊次數內有25%到75%機率被偷走25%到75%擁有檸檬汁")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.black)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(autoSqueezeEnabled: autoSqueezeEnabled)
        }
        .onAppear {
            startAutoSqueezeTimerIfEnabled()
        }
        .onDisappear {
            stopAutoSqueezeTimer()
        }
    }
    
    // 啟動自動榨檸檬計時器（如果啟用）
    private func startAutoSqueezeTimerIfEnabled() {
        guard autoSqueezeEnabled.wrappedValue else { return }
        
        // 創建計時器並明確添加到主線程的RunLoop中
        let timer = Timer(timeInterval: 0.3, repeats: true) { _ in
            // 執行與點擊相同的動作
            withAnimation(.easeOut(duration: 0.1)) {
                lemonScale = 0.98
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    lemonScale = 1.0
                }
            }
        }
        
        // 明確添加到主線程的RunLoop中，並設置為默認模式
        RunLoop.main.add(timer, forMode: .common)
        autoSqueezeTimer = timer
    }
    
    // 停止自動榨檸檬計時器
    private func stopAutoSqueezeTimer() {
        autoSqueezeTimer?.invalidate()
        autoSqueezeTimer = nil
    }


    
    private func createJuiceImages() {
        juiceImages = []
        var randomPositions: [(x: CGFloat, y: CGFloat)] = []
        
        // 减少动画数量，从5个改为3个
        for _ in 0..<2 {
            let randomX = CGFloat.random(in: -5...5)  // 减小随机范围
            let randomY = CGFloat.random(in: -5...5)
            randomPositions.append((x: randomX, y: randomY))
            
            let randomScale = CGFloat.random(in: 5...6)  // 减小缩放范围
            juiceImages.append((
                offset: .zero,
                scale: randomScale,
                opacity: 0.8
            ))
        }
        
        // 简化动画
        for i in 0..<juiceImages.count {
            withAnimation(Animation.easeOut(duration: 0.15).delay(Double(i) * 0.02)) {  // 减少动画时间和延迟
                juiceImages[i].offset = CGSize(
                    width: randomPositions[i].x,
                    height: randomPositions[i].y
                )
                juiceImages[i].opacity = 0
            }
        }
        
        // 提前清理动画并切换到 Lemon1 图片
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            juiceImages = []
            viewModel.lemonState = .full  // 直接切换到 Lemon1 图片
        }
    }
    
    private func addFallingLemon() {
        // 限制同时存在的柠檬数量
        if fallingLemons.count >= 100 {
            return
        }
        
        // 计算新柠檬的随机水平位置
        let xOffset = CGFloat.random(in: -200...200)  // 减小范围
        
        // 找到该x位置附近最高的柠檬
        var highestY = screenHeight * 0.25 // 基础高度
        
        for lemon in fallingLemons {
            if abs(lemon.xOffset - xOffset) < lemonSize * 0.7 && lemon.opacity > 0.5 {
                let topOfLemon = lemon.finalYOffset - lemonSize * 0.7
                if topOfLemon < highestY {
                    highestY = topOfLemon
                }
            }
        }
        
        // 确保不超过最大堆叠高度
        if highestY < -maxStackHeight {
            return
        }
        
        let newLemon = (
            id: UUID(),
            yOffset: -screenHeight * 0.1,
            xOffset: xOffset,
            finalYOffset: highestY,
            opacity: 1.0
        )
        
        fallingLemons.append(newLemon)
        
        // 简化动画
        withAnimation(.easeOut(duration: 0.3)) {  // 使用更简单的动画
            if let index = fallingLemons.firstIndex(where: { $0.id == newLemon.id }) {
                fallingLemons[index].yOffset = newLemon.finalYOffset
            }
        }
        
        // 提前清理动画
        DispatchQueue.main.asyncAfter(deadline: .now() + 14.0) {
            if let index = fallingLemons.firstIndex(where: { $0.id == newLemon.id }) {
                withAnimation(.easeOut(duration: 0.3)) {
                    fallingLemons[index].opacity = 0
                }
                
                // 检查并更新上方柠檬的位置
                updateLemonsAbove(removedLemon: fallingLemons[index])
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 14.5) {
            fallingLemons.removeAll { $0.id == newLemon.id }
        }
    }
    
    private func updateLemonsAbove(removedLemon: (id: UUID, yOffset: CGFloat, xOffset: CGFloat, finalYOffset: CGFloat, opacity: Double)) {
        // 找出所有在被移除柠檬上方的柠檬
        let affectedLemons = fallingLemons.filter { lemon in
            lemon.opacity > 0.5 &&
            abs(lemon.xOffset - removedLemon.xOffset) < lemonSize * 1.2 &&
            lemon.finalYOffset < removedLemon.finalYOffset
        }
        
        // 更新这些柠檬的位置
        for affectedLemon in affectedLemons {
            if let index = fallingLemons.firstIndex(where: { $0.id == affectedLemon.id }) {
                // 计算新的最终位置
                var newHighestY = screenHeight * 0.25
                
                // 检查下方的柠檬
                for lemon in fallingLemons {
                    if lemon.opacity > 0.5 &&
                       abs(lemon.xOffset - affectedLemon.xOffset) < lemonSize * 0.7 &&
                       lemon.finalYOffset > affectedLemon.finalYOffset &&
                       lemon.id != affectedLemon.id {
                        let topOfLemon = lemon.finalYOffset - lemonSize * 0.7
                        if topOfLemon < newHighestY {
                            newHighestY = topOfLemon
                        }
                    }
                }
                
                // 使用更简单的动画
                withAnimation(.easeOut(duration: 0.3)) {
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
