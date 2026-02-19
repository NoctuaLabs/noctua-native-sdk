import SwiftUI
import os
import NoctuaSDK

struct OtherSection: View {
    let logger: Logger

    @State private var batchResult: String = ""
    @State private var eventCount: Int32 = 0

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                fatalError("Crash was triggered")
            }) {
                actionButtonLabel("Crash Me", color: .red)
            }

            Button(action: {
                let welcomeMessage = Noctua.getFirebaseRemoteConfigString(key: "welcome_message")
                logger.debug("Firebase Remote Config value: \(welcomeMessage ?? "")")
            }) {
                actionButtonLabel("Get Firebase Remote Config")
            }

            // Per-Row Storage (Unlimited)
            Divider().padding(.vertical, 4)

            Text("Per-Row Storage (Unlimited)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: {
                let timestamp = Int(Date().timeIntervalSince1970 * 1000)
                let sampleJson = "{\"event_name\":\"test_event\",\"timestamp\":\(timestamp)}"
                Noctua.insertEvent(eventJson: sampleJson)
                logger.debug("Inserted event: \(sampleJson)")
            }) {
                actionButtonLabel("Insert Event", color: .blue)
            }

            Button(action: {
                Noctua.getEventsBatch(limit: 10, offset: 0) { result in
                    batchResult = result
                    logger.debug("Batch result: \(result)")
                }
            }) {
                actionButtonLabel("Get Batch (10)", color: .blue)
            }

            Button(action: {
                Noctua.getEventCount { count in
                    eventCount = count
                    logger.debug("Event count: \(count)")
                }
            }) {
                actionButtonLabel("Get Count", color: .blue)
            }

            Button(action: {
                guard !batchResult.isEmpty, batchResult != "[]" else {
                    logger.debug("Get a batch first")
                    return
                }
                let pattern = try? NSRegularExpression(pattern: "\"id\":(\\d+)")
                let matches = pattern?.matches(in: batchResult, range: NSRange(batchResult.startIndex..., in: batchResult)) ?? []
                let ids = matches.compactMap { match -> String? in
                    guard let range = Range(match.range(at: 1), in: batchResult) else { return nil }
                    return String(batchResult[range])
                }
                if !ids.isEmpty {
                    let idsJson = "[\(ids.joined(separator: ","))]"
                    Noctua.deleteEventsByIds(idsJson: idsJson) { deletedCount in
                        batchResult = ""
                        logger.debug("Deleted \(deletedCount) events by IDs: \(idsJson)")
                    }
                }
            }) {
                actionButtonLabel("Delete By IDs", color: .red.opacity(0.7))
            }

            if eventCount > 0 {
                Text("Event Count: \(eventCount)")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if !batchResult.isEmpty && batchResult != "[]" {
                Text("Batch Result:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(batchResult)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
}
