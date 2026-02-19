import SwiftUI
import os
import NoctuaSDK

struct EventStorageSection: View {
    let logger: Logger

    @State private var savedEvents: [String] = []
    @State private var statusText: String = ""

    var body: some View {
        VStack(spacing: 8) {
            Button(action: {
                let samplePayload = "{\"type\":\"test\",\"ts\":\(Int(Date().timeIntervalSince1970))}"
                Noctua.saveEvents(jsonString: samplePayload)
                statusText = "Saved: \(samplePayload)"
                logger.debug("Saved event: \(samplePayload)")
            }) {
                actionButtonLabel("Save Event", color: .blue)
            }

            Button(action: {
                Noctua.getEvents { events in
                    savedEvents = events
                    statusText = "Retrieved \(events.count) events"
                    logger.debug("Got \(events.count) events")
                }
            }) {
                actionButtonLabel("Get Events", color: .blue)
            }

            Button(action: {
                Noctua.deleteEvents()
                savedEvents = []
                statusText = "All events deleted"
                logger.debug("Deleted all events")
            }) {
                actionButtonLabel("Delete All Events", color: .red)
            }

            if !statusText.isEmpty {
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }

            if !savedEvents.isEmpty {
                Text("Events (\(savedEvents.count))")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(Array(savedEvents.prefix(5).enumerated()), id: \.offset) { _, event in
                    Text(String(event.prefix(60)) + (event.count > 60 ? "..." : ""))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(Color.blue.opacity(0.08))
                        .cornerRadius(4)
                }

                if savedEvents.count > 5 {
                    Text("+\(savedEvents.count - 5) more")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
    }
}
