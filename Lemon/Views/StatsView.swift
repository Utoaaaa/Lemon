import SwiftUI

struct StatsView: View {
    @ObservedObject var viewModel: LemonViewModel
    
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
                    .padding(.top, 90)
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
                        Text("連續榨檸檬（天）")
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
    @State private var activityData: [Int] = Array(repeating: 0, count: 365)
    @State private var stolenData: [Int] = Array(repeating: 0, count: 365)
    @State private var currentWeekdayIndex: Int = 0
    @State private var selectedDay: Int? = nil
    @State private var showingDayInfo: Bool = false
    @State private var selectedDayInfo: (date: Date, count: Int, stolen: Int) = (Date(), 0, 0)
    
    // 計算今天是星期幾 (0 = 星期日, 1 = 星期一, ..., 6 = 星期六)
    private var currentWeekday: Int {
        let calendar = Calendar.current
        let today = Date()
        // 轉換為 0-6 (星期日-星期六)
        return calendar.component(.weekday, from: today) - 1
    }
    
    private func getActivityColor(count: Int) -> Color {
        if count == 0 {
            return Color.gray.opacity(0.2)
        } else if count < 1000 {
            return Color.green.opacity(0.3)
        } else if count < 2000 {
            return Color.green.opacity(0.5)
        } else if count < 3000 {
            return Color.green.opacity(0.7)
        } else if count < 4000 {
            return Color.green.opacity(0.9)
        } else {
            return Color.green
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("yyyy年MM月dd日", comment: "")
        return formatter.string(from: date)
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
                        // 生成 52 週的格子
                        ForEach(0..<52, id: \.self) { weekIndex in
                            VStack(spacing: 4) {
                                ForEach(0..<7, id: \.self) { dayIndex in
                                    // 計算日期偏移
                                    let dayOffset = weekIndex * 7 + dayIndex
                                    
                                    // 獲取活動數據
                                    let dataIndex = dayOffset
                                    let activityCount = dataIndex < activityData.count ? activityData[dataIndex] : 0
                                    let _ = dataIndex < stolenData.count ? stolenData[dataIndex] : 0
                                    
                                    Rectangle()
                                        .fill(getActivityColor(count: activityCount))
                                        .frame(width: 15, height: 15)
                                        .cornerRadius(3)
                                        .overlay(
                                            // 高亮今天
                                            weekIndex == 0 && dayIndex == currentWeekday ? 
                                                RoundedRectangle(cornerRadius: 3)
                                                    .stroke(Color.orange, lineWidth: 2) : nil
                                        )
                                        .onTapGesture {
                                            // 計算選中日期
                                            let calendar = Calendar.current
                                            let today = calendar.startOfDay(for: Date())
                                            
                                            // 計算日期差異，考慮日期由上到下排列
                                            // 今天是 weekIndex=0, dayIndex=currentWeekday
                                            let dayDiff = weekIndex * 7 + (dayIndex - currentWeekday)
                                            
                                            if let selectedDate = calendar.date(byAdding: .day, value: dayDiff, to: today) {
                                                // 如果點擊的是同一個格子，切換顯示狀態
                                                if showingDayInfo && selectedDay == dayOffset {
                                                    showingDayInfo = false
                                                    selectedDay = nil
                                                } else {
                                                    // 查找該日期的活動數據
                                                    let activity = stats.getActivity(for: selectedDate)
                                                    let lemonCount = activity?.lemonCount ?? 0
                                                    let stolenCount = activity?.stolenCount ?? 0
                                                    
                                                    // 如果是今天，使用當前數據
                                                    if calendar.isDateInToday(selectedDate) {
                                                        selectedDayInfo = (selectedDate, stats.todayLemonCount, stats.todayStolenCount)
                                                    } else {
                                                        selectedDayInfo = (selectedDate, lemonCount, stolenCount)
                                                    }
                                                    
                                                    showingDayInfo = true
                                                    selectedDay = dayOffset
                                                }
                                            }
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
                
                ForEach([0, 1000, 2000, 3000, 4000], id: \.self) { count in
                    Rectangle()
                        .fill(getActivityColor(count: count))
                        .frame(width: 15, height: 15)
                        .cornerRadius(3)
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
                    
                    HStack {
                        Text(String(format: NSLocalizedString("榨檸檬：%d 杯", comment: ""), selectedDayInfo.count))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
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
        }
        .onAppear {
            // 獲取今天是星期幾，初始化時設置
            currentWeekdayIndex = currentWeekday
            
            // 載入活動數據
            loadActivityData()
        }
    }
    
    private func loadActivityData() {
        // 清空數據
        activityData = Array(repeating: 0, count: 365)
        stolenData = Array(repeating: 0, count: 365)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // 設置今天的數據
        let todayIndex = currentWeekday
        activityData[todayIndex] = stats.todayLemonCount
        stolenData[todayIndex] = stats.todayStolenCount
        
        // 載入歷史數據
        for activity in stats.dailyActivities {
            // 計算與今天的日期差異
            let components = calendar.dateComponents([.day], from: activity.date, to: today)
            if let dayDiff = components.day, dayDiff >= 0 && dayDiff < 365 {
                // 計算在數組中的索引
                let activityWeekday = calendar.component(.weekday, from: activity.date) - 1
                let weeksAgo = dayDiff / 7
                let index = (weeksAgo * 7) + activityWeekday
                
                // 將數據填充到對應位置
                if index < activityData.count {
                    activityData[index] = activity.lemonCount
                    stolenData[index] = activity.stolenCount
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
