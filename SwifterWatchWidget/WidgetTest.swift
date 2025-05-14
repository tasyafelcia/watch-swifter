//import WidgetKit
//import SwiftUI
//
//struct TestWidget: Widget {
//    let kind: String = "TestWidget"
//
//    var body: some WidgetConfiguration {
//        StaticConfiguration(kind: kind, provider: TestProvider()) { entry in
//            TestWidgetView(entry: entry)
//        }
//        .configurationDisplayName("Test Widget")
//        .description("Simple test widget")
//        .supportedFamilies([.accessoryRectangular])
//    }
//}
//
//struct TestEntry: TimelineEntry {
//    let date: Date
//}
//
//struct TestProvider: TimelineProvider {
//    func placeholder(in context: Context) -> TestEntry {
//        TestEntry(date: Date())
//    }
//
//    func getSnapshot(in context: Context, completion: @escaping (TestEntry) -> ()) {
//        completion(TestEntry(date: Date()))
//    }
//
//    func getTimeline(in context: Context, completion: @escaping (Timeline<TestEntry>) -> ()) {
//        let timeline = Timeline(entries: [TestEntry(date: Date())], policy: .atEnd)
//        completion(timeline)
//    }
//}
//
//struct TestWidgetView: View {
//    var entry: TestProvider.Entry
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            HStack {
//                Image(systemName: "swift")
//                    .foregroundColor(.orange)
//                Text("Swifter")
//                    .font(.headline)
//                    .bold()
//                    .foregroundColor(.white)
//            }
//
//            Text(entry.date, style: .time)
//                .font(.footnote)
//                .foregroundColor(.white.opacity(0.8))
//        }
//        .padding(.horizontal, 8)
//        .padding(.vertical, 4)
//        .containerBackground(Color.black, for: .widget)
//    }
//}
