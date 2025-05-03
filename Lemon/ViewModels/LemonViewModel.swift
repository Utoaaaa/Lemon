import Foundation
import SwiftUI
import AVFoundation
import CoreHaptics

class LemonViewModel: ObservableObject {
    // 發布的屬性
    @Published var lemonState: LemonState = .full
    @Published var stats: LemonStats = LemonStats.defaultStats()
    @Published var showThiefAlert = false
    @Published var stolenAmount = 0
    @Published var autoSqueezeEnabled = false
    
    // 音效和震動
    private var audioPlayer: AVAudioPlayer?
    private var hapticEngine: CHHapticEngine?
    
    // 檸檬小偷事件
    private var thiefEvent = ThiefEvent.random()
    private var clickCountSinceLastThief = 0
    
    init() {
        loadStats()
        setupHaptics()
        checkAndUpdateDate()
    }
    
    // MARK: - 遊戲邏輯
    
    func handleLemonTap() {
        switch lemonState {
        case .full:
            lemonState = .squeezed
        case .squeezed:
            lemonState = .empty
            stats.todayLemonCount += 1
            stats.totalLemonCount += 1
            clickCountSinceLastThief += 1
            checkThiefEvent()
            saveStats()
            saveTodayActivity() // 保存今天的活動數據
            
            // 延遲重置檸檬狀態
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.lemonState = .full
            }
        case .empty:
            break
        }
    }
    
    private func checkThiefEvent() {
        if clickCountSinceLastThief >= thiefEvent.triggerCount {
            clickCountSinceLastThief = 0
            thiefEvent = ThiefEvent.random()
            
            if Double.random(in: 0...1) < thiefEvent.stealProbability {
                let stolenCount = Int(Double(stats.todayLemonCount) * thiefEvent.stealPercentage)
                if stolenCount > 0 {
                    stats.todayLemonCount -= stolenCount
                    stats.todayStolenCount += stolenCount
                    stats.totalStolenCount += stolenCount
                    stolenAmount = stolenCount
                    showThiefAlert = true
                    saveStats()
                }
            }
        }
    }
    
    // MARK: - 數據管理
    
    private func loadStats() {
        if let data = UserDefaults.standard.data(forKey: "LemonStats"),
           let savedStats = try? JSONDecoder().decode(LemonStats.self, from: data) {
            stats = savedStats
        }
    }
    
    private func saveStats() {
        if let encoded = try? JSONEncoder().encode(stats) {
            UserDefaults.standard.set(encoded, forKey: "LemonStats")
        }
    }
    
    private func checkAndUpdateDate() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastPlayDate = stats.lastPlayDate.map({ calendar.startOfDay(for: $0) }) {
            // 嚴格計算實際間隔完整天數（排除當天）
            // 嚴格計算自然天數差（包含調試日誌）
            // 使用更精確的日期比較方式
            let components = calendar.dateComponents([.hour], from: lastPlayDate, to: today)
            let hoursSinceLast = abs(components.hour ?? 0)
            
            // 如果超過24小時才算新的一天
            if hoursSinceLast >= 24 {
                let days = calendar.dateComponents([.day], from: lastPlayDate, to: today).day ?? 0
                
                // 嚴格判斷是否為連續天數（昨天）
                if calendar.isDate(lastPlayDate, inSameDayAs: calendar.date(byAdding: .day, value: -1, to: today)! ) {
                    stats.consecutiveDays += 1
                    stats.maxConsecutiveDays = max(stats.consecutiveDays, stats.maxConsecutiveDays)
                    print("[DEBUG] 連續天數更新：+1天 → 總計 \(stats.consecutiveDays) 天")
                } else if days > 1 {
                    stats.consecutiveDays = 0
                    print("[DEBUG] 重置連續天數，間隔天數：\(days) 天")
                }
                
                // 每日跨天時重置數據
                print("[DEBUG] 重置今日數據：檸檬 \(stats.todayLemonCount) → 0，被偷 \(stats.todayStolenCount) → 0")
                stats.todayLemonCount = 0
                stats.todayStolenCount = 0
                stats.lastPlayDate = today
                saveStats()
            } else {
                print("[DEBUG] 未滿24小時（\(hoursSinceLast)小時），不重置數據")
            }
        } else {
            // 首次使用，設置今天為最後遊玩日期
            stats.lastPlayDate = today
            saveStats()
        }
    }
    
    // 保存每日活動數據
    private func saveDailyActivity(for date: Date) {
        // 檢查是否已有該日期的記錄
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: dateOnly)
        
        // 如果已有該日期的記錄，則更新；否則添加新記錄
        if let index = stats.dailyActivities.firstIndex(where: { $0.id == dateString }) {
            stats.dailyActivities[index].lemonCount = stats.todayLemonCount
            stats.dailyActivities[index].stolenCount = stats.todayStolenCount
        } else {
            let activity = DailyActivity(
                date: dateOnly,
                lemonCount: stats.todayLemonCount,
                stolenCount: stats.todayStolenCount
            )
            stats.dailyActivities.append(activity)
        }
        
        // 只保留最近 365 天的數據
        if stats.dailyActivities.count > 365 {
            stats.dailyActivities.sort { $0.date > $1.date }
            stats.dailyActivities = Array(stats.dailyActivities.prefix(365))
        }
    }
    
    // 保存今天的活動數據
    func saveTodayActivity() {
        guard let lastPlayDate = stats.lastPlayDate else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 只有在今天才保存
        if calendar.isDate(lastPlayDate, inSameDayAs: today) {
            saveDailyActivity(for: today)
            saveStats()
        }
    }
    
    private func setupHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            
            // 添加重啟回調
            hapticEngine?.resetHandler = { [weak self] in
                print("重啟震動引擎")
                do {
                    try self?.hapticEngine?.start()
                } catch {
                    print("重啟震動引擎失敗: \(error.localizedDescription)")
                }
            }
            
            // 停止回調
            hapticEngine?.stoppedHandler = { reason in
                print("震動引擎停止，原因: \(reason)")
            }
            
        } catch {
            print("震動引擎初始化失敗: \(error.localizedDescription)")
        }
    }
    
    private func triggerHapticFeedback() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        // 直接從 UserDefaults 獲取最新設定值
        guard UserDefaults.standard.bool(forKey: "hapticsEnabled") else { return }
        
        // 確保在主線程執行
        DispatchQueue.main.async {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        }
    }
    
}
