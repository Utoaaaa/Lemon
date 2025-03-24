import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: LemonViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // 背景
            Image("background")
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("統計數據")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, hasNotch() ? 90 : 120)
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    // 連續榨檸檬
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(viewModel.stats.consecutiveDays)")
                            .font(.system(size: 40, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundColor(.black)
                        Text("連續被偷（天）")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(String(format: NSLocalizedString("最長紀錄：%d天", comment: ""), viewModel.stats.maxConsecutiveDays))
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    HStack(spacing: 15) {
                        // 總共榨檸檬
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(viewModel.stats.totalLemonCount)")
                                .font(.system(size: 40, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(.black)
                            Text("總共榨檸檬（杯）")
                                .font(.system(size: 16))
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
                        
                        // 總共被偷
                        VStack(alignment: .leading, spacing: 10) {
                            Text("\(viewModel.stats.totalStolenCount)")
                                .font(.system(size: 40, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .fixedSize(horizontal: false, vertical: true)
                                .foregroundColor(.black)
                            Text("總共被偷（杯）")
                                .font(.system(size: 16))
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
                    
                    // 活動記錄
                    VStack(alignment: .leading, spacing: 10) {
                        Text("榨檸檬記錄")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                            .padding(.bottom, 5)
                        
                        ActivityGridView(stats: viewModel.stats)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 15).fill(Color.white))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationBarTitle("統計", displayMode: .inline)
    }
}

struct ActivityGridView: View {
    let stats: LemonStats
    @State private var activityData: [[Int]] = []  // 二維陣列，儲存活動數據
    @State private var stolenData: [[Int]] = []    // 二維陣列，儲存被偷數據
    @State private var selectedDay: (column: Int, row: Int)? = nil
    @State private var showingDayInfo: Bool = false
    @State private var showingColorInfo: Bool = false
    @State private var selectedDayInfo: (date: Date, count: Int, stolen: Int) = (Date(), 0, 0)
    @State private var selectedColorInfo: Int = 0
    @State private var firstRecordWeekday: Int = 0  // 第一次記錄的星期幾
    @State private var totalDays: Int = 0          // 記錄總天數
    @Environment(\.colorScheme) private var colorScheme
    private let extraColumns = 26                   // 預設多生成一年的空格子
    
    // 計算需要的列數
    private var numberOfColumns: Int {
        let requiredColumns = (totalDays + firstRecordWeekday + 6) / 7  // +6 確保向上取整
        return requiredColumns + extraColumns  // 在需要的列數上額外加上一年的空格子
    }
    
    private func initializeGrids() {
        // 初始化二維陣列
        activityData = Array(repeating: Array(repeating: 0, count: 7), count: numberOfColumns)
        stolenData = Array(repeating: Array(repeating: 0, count: 7), count: numberOfColumns)
    }
    
    private func ensureExtraColumn(at column: Int) {
        // 如果接近當前數組大小，增加新的列
        if column >= activityData.count - 5 {  // 當剩餘少於5列時增加新列
            let newColumns = 26  // 每次增加一年的列數
            activityData.append(contentsOf: Array(repeating: Array(repeating: 0, count: 7), count: newColumns))
            stolenData.append(contentsOf: Array(repeating: Array(repeating: 0, count: 7), count: newColumns))
        }
    }
    
    private func calculatePosition(dayOffset: Int) -> (column: Int, row: Int)? {
        let totalOffset = dayOffset + firstRecordWeekday
        let column = totalOffset / 7
        let row = totalOffset % 7
        
        // 檢查是否在有效範圍內
        guard column >= 0, row >= 0, row < 7 else {
            return nil
        }
        
        // 確保有足夠的列
        ensureExtraColumn(at: column)
        
        return (column: column, row: row)
    }
    
    private func loadActivityData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 獲取並排序活動數據
        let sortedActivities = stats.dailyActivities.sorted(by: { $0.date < $1.date })
        
        // 設置第一天的星期幾
        if let firstActivity = sortedActivities.first {
            firstRecordWeekday = calendar.component(.weekday, from: firstActivity.date) - 1
            
            // 計算總天數
            if let days = calendar.dateComponents([.day], from: firstActivity.date, to: today).day {
                totalDays = days + 1  // +1 包含今天
            }
            
            // 初始化網格
            initializeGrids()
            
            // 填充歷史數據
            for activity in sortedActivities {
                if let days = calendar.dateComponents([.day], from: firstActivity.date, to: activity.date).day {
                    if let position = calculatePosition(dayOffset: days) {
                        activityData[position.column][position.row] = activity.lemonCount
                        stolenData[position.column][position.row] = activity.stolenCount
                    }
                }
            }
            
            // 設置今天的數據
            if let days = calendar.dateComponents([.day], from: firstActivity.date, to: today).day {
                if let position = calculatePosition(dayOffset: days) {
                    activityData[position.column][position.row] = stats.todayLemonCount
                    stolenData[position.column][position.row] = stats.todayStolenCount
                }
            }
        } else {
            // 如果沒有歷史數據，從今天開始記錄
            firstRecordWeekday = calendar.component(.weekday, from: today) - 1
            totalDays = 0
            initializeGrids()
            
            // 確保數組已經初始化且索引有效
            if numberOfColumns > 0 {
                activityData[0][firstRecordWeekday] = stats.todayLemonCount
                stolenData[0][firstRecordWeekday] = stats.todayStolenCount
            }
        }
    }
    
    private func getActivityColor(count: Int) -> Color {
        if count == 0 {
            return Color.gray.opacity(0.2)
        } else if count < 1000 {
            return Color.green.opacity(0.4)
        } else if count < 2000 {
            return Color.green.opacity(0.6)
        } else if count < 3000 {
            return Color.green.opacity(0.8)
        } else {
            return Color.green
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("yyyy年MM月dd日", comment: "")
        return formatter.string(from: date)
    }
    
    private func getCountRangeText(for count: Int) -> String {
        if count == 0 {
            return NSLocalizedString("0 杯被偷", comment: "")
        } else if count == 999 {
            return NSLocalizedString("1-999 杯被偷", comment: "")
        } else if count == 1999 {
            return NSLocalizedString("1000-1999 杯被偷", comment: "")
        } else if count == 2999 {
            return NSLocalizedString("2000-2999 杯被偷", comment: "")
        } else {
            return NSLocalizedString("3000+ 杯被偷", comment: "")
        }
    }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                // 星期標籤
                VStack(alignment: .trailing, spacing: 4) {
                    Text("日").frame(height: 15)
                    Text("一").frame(height: 15)
                    Text("二").frame(height: 15)
                    Text("三").frame(height: 15)
                    Text("四").frame(height: 15)
                    Text("五").frame(height: 15)
                    Text("六").frame(height: 15)
                }
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .padding(.top, 5)
                
                // 活動網格
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(0..<activityData.count, id: \.self) { column in
                            VStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { row in
                                    Rectangle()
                                        .fill(getActivityColor(count: getStolenCount(column: column, row: row)))
                                        .frame(width: 15, height: 15)
                                        .cornerRadius(3)
                                        .overlay(
                                            showingDayInfo && selectedDay?.column == column && selectedDay?.row == row ? 
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(Color.orange, lineWidth: 2) : nil
                                        )
                                        .onTapGesture {
                                            handleDaySelection(column: column, row: row)
                                        }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 5)
                    .padding(.horizontal, 10)
                }
            }
            
            // 顏色說明
            HStack(spacing: 4) {
                Text("較少")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.trailing, 6)
                
                ForEach([0, 999, 1999, 2999, 3999], id: \.self) { count in
                    Rectangle()
                        .fill(getActivityColor(count: count))
                        .frame(width: 15, height: 15)
                        .cornerRadius(3)
                        .overlay(
                            // 高亮選中的格子
                            showingColorInfo && selectedColorInfo == count ? 
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(Color.orange, lineWidth: 2) : nil
                        )
                        .onTapGesture {
                            if showingColorInfo && selectedColorInfo == count {
                                showingColorInfo = false
                            } else {
                                selectedColorInfo = count
                                showingColorInfo = true
                                showingDayInfo = false
                                selectedDay = nil
                            }
                        }
                }
                
                Text("較多")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
                    .padding(.leading, 6)
                
                Spacer()
            }
            .padding(.leading, 0)

            // 顯示選中日期的信息
            if showingDayInfo {
                VStack(alignment: .leading, spacing: 5) {
                    Text(formatDate(selectedDayInfo.date))
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .foregroundColor(.black)
                    
                    HStack {
                        Text(String(format: NSLocalizedString("被偷：%d 杯", comment: ""), selectedDayInfo.stolen))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.9)))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                .padding(.horizontal, 10)
                .padding(.top, 5)
                .transition(.opacity)
            }
            
            // 顯示顏色說明的信息
            if showingColorInfo {
                VStack(alignment: .leading, spacing: 5) {
                    Text(getCountRangeText(for: selectedColorInfo))
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .foregroundColor(.black)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.9)))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                .padding(.horizontal, 10)
                .padding(.top, 5)
                .transition(.opacity)
            }
        }
        .onAppear {
            loadActivityData()
        }
    }
    
    // 安全地獲取被偷數據
    private func getStolenCount(column: Int, row: Int) -> Int {
        guard column >= 0, column < stolenData.count,
              row >= 0, row < stolenData[column].count else {
            return 0
        }
        return stolenData[column][row]
    }
    
    private func handleDaySelection(column: Int, row: Int) {
        let calendar = Calendar.current
        
        // 計算選中日期
        if let firstActivity = stats.dailyActivities.sorted(by: { $0.date < $1.date }).first {
            let dayOffset = column * 7 + row - firstRecordWeekday
            if let selectedDate = calendar.date(byAdding: .day, value: dayOffset, to: firstActivity.date) {
                // 如果點擊的是同一個格子，切換顯示狀態
                if showingDayInfo && selectedDay?.column == column && selectedDay?.row == row {
                    showingDayInfo = false
                    selectedDay = nil
                } else {
                    let stolenCount = getStolenCount(column: column, row: row)
                    selectedDayInfo = (selectedDate, 0, stolenCount)
                    showingDayInfo = true
                    showingColorInfo = false
                    selectedDay = (column, row)
                }
            }
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}
