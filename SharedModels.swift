// tasyafelcia/watch-swifter/watch-swifter-e582a31a3fb6dc08417297febf88ab00ecc25ae5/SharedModels.swift
import Foundation

struct SessionData: Codable, Identifiable { // Tambahkan Identifiable jika belum ada
    let id: String // Jadikan id sebagai eventCalendarID atau UUID().uuidString saat pembuatan
    let startTime: Date
    let endTime: Date
    let sessionType: String // Ini adalah nilai mentah seperti "Pre-jogging"
    let status: String
    let calendarEventID: String
}

// Pastikan ekstensi ini tersedia dan digunakan
extension String {
    var displayName: String {
        switch self {
        case "Pre-jogging":
            return "Pre-Jog"
        case "Jogging":
            return "Jog"
        case "Post-jogging":
            return "Post-Jog"
        default:
            return self
        }
    }
}
