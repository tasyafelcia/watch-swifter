// tasyafelcia/watch-swifter/watch-swifter-e582a31a3fb6dc08417297febf88ab00ecc25ae5/SwifterWatchWidget/SwifterWatchWidget.swift
import WidgetKit
import SwiftUI

// Pastikan SharedModels.swift (yang berisi SessionData dan ekstensi displayName)
// juga merupakan bagian dari target SwifterWatchWidget.

@main
struct SwifterWatchWidgetBundle: WidgetBundle {
    var body: some Widget {
        SwifterWatchWidget()
    }
}

struct SwifterWatchWidget: Widget {
    let kind: String = "SwifterWatchWidget" // Pastikan kind ini unik

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SessionProvider()) { entry in
            SwifterWidgetView(entry: entry)
                .widgetURL(URL(string: "swifter://sessions")) // Untuk deep link jika diperlukan
        }
        .configurationDisplayName("Swifter Sessions")
        .description("Your upcoming jogging sessions.")
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Timeline Entry
struct SessionEntry: TimelineEntry {
    let date: Date
    let session: SessionData? // Jadikan opsional untuk menangani kasus tidak ada sesi

    // Computed properties untuk tampilan
    var displaySessionType: String {
        session?.sessionType.displayName ?? "Tidak Ada Sesi"
    }

    var timeText: String {
        guard let session = session else { return "--:--" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: session.startTime)) - \(formatter.string(from: session.endTime))"
    }

    var titleText: String {
        guard let session = session else { return "Tidak Ada Sesi" }
        // Gunakan displayName dari ekstensi yang ada di SharedModels.swift
        return "Upcoming \(session.sessionType.displayName)"
    }
}

// MARK: - Timeline Provider
struct SessionProvider: TimelineProvider {
    // GANTI DENGAN APP GROUP ID ANDA YANG SEBENARNYA
    private let appGroupId = "group.com.yourteam.swifter.shared"
    private let widgetSessionKey = "nextSessionWidgetData"

    func placeholder(in context: Context) -> SessionEntry {
        SessionEntry(
            date: Date(),
            session: SessionData(id: "placeholder",
                                 startTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!,
                                 endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date())!,
                                 sessionType: "Jogging", // Gunakan nilai mentah
                                 status: "Not started",
                                 calendarEventID: "placeholder")
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SessionEntry) -> ()) {
        let entry = SessionEntry(date: Date(), session: getNextSessionFromUserDefaultsForWidget())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SessionEntry>) -> ()) {
        let currentDate = Date()
        let session = getNextSessionFromUserDefaultsForWidget()
        let entry = SessionEntry(date: currentDate, session: session)

        // Tentukan waktu refresh berikutnya. Jika ada sesi, refresh setelah sesi berakhir.
        // Jika tidak ada sesi, refresh setelah interval tertentu (misalnya 15 menit).
        let refreshDate: Date
        if let session = session, session.endTime > currentDate {
            refreshDate = Calendar.current.date(byAdding: .minute, value: 1, to: session.endTime) ?? // Sedikit setelah sesi berakhir
                          Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)! // Fallback
        } else {
            refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        }
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }

    private func getNextSessionFromUserDefaultsForWidget() -> SessionData? {
        if let appGroupDefaults = UserDefaults(suiteName: appGroupId) {
            if let data = appGroupDefaults.data(forKey: widgetSessionKey) {
                do {
                    let decoder = JSONDecoder()
                    // Pastikan strategi dekoding tanggal konsisten dengan WatchSessionManager
                    decoder.dateDecodingStrategy = .iso8601
                    let decodedSession = try decoder.decode(SessionData.self, from: data)
                    print("SwifterWatchWidget: Successfully decoded session from app group: \(decodedSession.sessionType) at \(decodedSession.startTime)")
                    return decodedSession
                } catch {
                    print("SwifterWatchWidget: Error decoding session from app group: \(error)")
                }
            } else {
                print("SwifterWatchWidget: No data found in app group for key \(widgetSessionKey)")
            }
        } else {
            print("SwifterWatchWidget: Failed to get app group UserDefaults with suite name \(appGroupId)")
        }
        return nil // Kembalikan nil jika tidak ada data atau gagal decode
    }
}

// MARK: - Widget View
struct SwifterWidgetView: View {
    var entry: SessionProvider.Entry
    @Environment(\.widgetFamily) var family // Untuk kustomisasi berdasarkan ukuran widget jika diperlukan

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(entry.session != nil ? Color(.sRGB, red: 0.2, green: 0.9, blue: 0.6) : Color.gray) // Aksen bar
                .frame(width: 6)
                .cornerRadius(3)
                .edgesIgnoringSafeArea(.vertical)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.titleText) // Menggunakan titleText dari SessionEntry
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(entry.timeText) // Menggunakan timeText dari SessionEntry
                    .font(.system(size: entry.session != nil ? 20 : 16, weight: .bold)) // Ukuran font berbeda jika tidak ada sesi
                    .foregroundColor(entry.session != nil ? .white : .gray)
                    .lineLimit(1)

                Text("Swifter")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .padding(.leading, 12)
            .padding(.vertical, 8)

            Spacer(minLength: 8)

            if entry.session != nil { // Hanya tampilkan ikon jika ada sesi
                ZStack {
                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(Color(.sRGB, red: 0.2, green: 0.9, blue: 0.6))
                            .frame(width: 3, height: 14)
                            .cornerRadius(1.5)
                        Rectangle()
                            .fill(Color(.sRGB, red: 0.0, green: 0.7, blue: 0.9))
                            .frame(width: 3, height: 10)
                            .cornerRadius(1.5)
                        Rectangle()
                            .fill(Color(.sRGB, red: 0.2, green: 0.9, blue: 0.6))
                            .frame(width: 3, height: 6)
                            .cornerRadius(1.5)
                    }
                    .offset(x: -18, y: 0)

                    Image(systemName: "figure.run")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.trailing, 14)
            } else {
                // Tampilkan ikon placeholder atau kosongkan jika tidak ada sesi
                Image(systemName: "moon.zzz.fill")
                     .font(.system(size: 28, weight: .medium))
                     .foregroundColor(.gray)
                     .padding(.trailing, 14)
            }
        }
        .containerBackground(Color.black, for: .widget)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Preview
// (Opsional) Perbarui preview untuk mencerminkan SessionEntry dengan session opsional
#Preview(as: .accessoryRectangular) {
    SwifterWatchWidget()
} timeline: {
    SessionEntry(
        date: Date(),
        session: SessionData(
            id: "preview",
            startTime: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!,
            endTime: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date())!,
            sessionType: "Jogging",
            status: "Not started",
            calendarEventID: "preview_id"
        )
    )
    SessionEntry(date: Date(), session: nil) // Preview untuk kasus tidak ada sesi
}
