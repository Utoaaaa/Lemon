import Foundation

// 檸檬狀態枚舉
enum LemonState {
    case full       // 完整的檸檬
    case squeezed   // 被擠壓的檸檬
    case empty      // 榨完的檸檬
}

// 每日活動記錄結構
struct DailyActivity: Codable, Identifiable {
    var id: String      // 日期字符串，格式：yyyy-MM-dd
    var lemonCount: Int // 當日榨檸檬數
    var stolenCount: Int // 當日被偷檸檬數
    var date: Date      // 日期
    
    init(date: Date, lemonCount: Int, stolenCount: Int) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.id = formatter.string(from: date)
        self.date = date
        self.lemonCount = lemonCount
        self.stolenCount = stolenCount
    }
}

// 檸檬統計數據結構
struct LemonStats: Codable {
    var todayLemonCount: Int       // 今日榨檸檬數
    var todayStolenCount: Int      // 今日被偷檸檬數
    var totalLemonCount: Int       // 總共榨檸檬數
    var totalStolenCount: Int      // 總共被偷檸檬數
    var consecutiveDays: Int       // 連續榨檸檬天數
    var maxConsecutiveDays: Int    // 最長連續榨檸檬天數
    var lastPlayDate: Date?        // 上次遊玩日期
    var dailyActivities: [DailyActivity] = [] // 每日活動記錄
    
    static func defaultStats() -> LemonStats {
        return LemonStats(
            todayLemonCount: 0,
            todayStolenCount: 0,
            totalLemonCount: 0,
            totalStolenCount: 0,
            consecutiveDays: 0,
            maxConsecutiveDays: 0,
            lastPlayDate: nil
        )
    }
    
    // 獲取指定日期的活動記錄
    func getActivity(for date: Date) -> DailyActivity? {
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: dateOnly)
        
        return dailyActivities.first { $0.id == dateString }
    }
}

// 檸檬小偷事件結構
struct ThiefEvent {
    let triggerCount: Int      // 觸發所需的檸檬數
    let stealProbability: Double    // 偷竊機率
    let stealPercentage: Double     // 偷竊百分比
    
    static func random() -> ThiefEvent {
        return ThiefEvent(
            triggerCount: Int.random(in: 1...10),
            stealProbability: Double.random(in: 0.2...0.7),
            stealPercentage: Double.random(in: 0.2...0.7)
        )
    }
}