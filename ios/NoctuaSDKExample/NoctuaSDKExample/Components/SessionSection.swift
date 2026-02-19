import SwiftUI
import os
import NoctuaSDK

struct SessionSection: View {
    let logger: Logger

    // Session Tags
    @State private var sessionTag: String = ""
    @State private var currentTags: String = ""

    // Experiments
    @State private var experimentValue: String = ""
    @State private var currentExperiment: String = ""

    // General Experiments
    @State private var generalExperimentValue: String = ""
    @State private var generalExperimentKey: String = ""
    @State private var currentGeneralExperiment: String = ""

    // Extra Params
    @State private var extraParamKey: String = ""
    @State private var extraParamValue: String = ""

    @State private var statusText: String = ""

    var body: some View {
        VStack(spacing: 8) {
            // Session Tags
            Text("Session Tags")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("Tag value", text: $sessionTag)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))

                Button(action: {
                    guard !sessionTag.isEmpty else { return }
                    Noctua.setSessionTag(tag: sessionTag)
                    statusText = "Tag set: \(sessionTag)"
                    logger.debug("Set session tag: \(sessionTag)")
                }) {
                    Text("Set")
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }

            Button(action: {
                let tags = Noctua.getSessionTags() ?? "nil"
                currentTags = tags
                statusText = "Tags: \(tags)"
                logger.debug("Session tags: \(tags)")
            }) {
                actionButtonLabel("Get Session Tags", color: .purple)
            }

            if !currentTags.isEmpty {
                ResultRow(label: "Tags", value: currentTags, color: .purple)
            }

            // Experiments
            Divider().padding(.vertical, 4)

            Text("Experiments")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("Experiment JSON", text: $experimentValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))

                Button(action: {
                    guard !experimentValue.isEmpty else { return }
                    Noctua.setExperiment(experiment: experimentValue)
                    statusText = "Experiment set"
                    logger.debug("Set experiment: \(experimentValue)")
                }) {
                    Text("Set")
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }

            Button(action: {
                let exp = Noctua.getExperiment() ?? "nil"
                currentExperiment = exp
                statusText = "Experiment: \(exp)"
                logger.debug("Experiment: \(exp)")
            }) {
                actionButtonLabel("Get Experiment", color: .blue)
            }

            if !currentExperiment.isEmpty {
                ResultRow(label: "Experiment", value: currentExperiment, color: .blue)
            }

            // General Experiments
            Divider().padding(.vertical, 4)

            Text("General Experiments")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("General Exp JSON", text: $generalExperimentValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))

                Button(action: {
                    guard !generalExperimentValue.isEmpty else { return }
                    Noctua.setGeneralExperiment(experiment: generalExperimentValue)
                    statusText = "General experiment set"
                    logger.debug("Set general experiment: \(generalExperimentValue)")
                }) {
                    Text("Set")
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.0, green: 0.7, blue: 0.5))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }

            HStack(spacing: 8) {
                TextField("Experiment key", text: $generalExperimentKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))

                Button(action: {
                    guard !generalExperimentKey.isEmpty else { return }
                    let value = Noctua.getGeneralExperiment(experimentKey: generalExperimentKey) ?? "nil"
                    currentGeneralExperiment = value
                    statusText = "General[\(generalExperimentKey)]: \(value)"
                    logger.debug("General experiment[\(generalExperimentKey)]: \(value)")
                }) {
                    Text("Get")
                        .font(.system(size: 12))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.0, green: 0.7, blue: 0.5))
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }

            if !currentGeneralExperiment.isEmpty {
                ResultRow(label: "General Experiment", value: currentGeneralExperiment, color: Color(red: 0.0, green: 0.7, blue: 0.5))
            }

            // Session Extra Params
            Divider().padding(.vertical, 4)

            Text("Session Extra Params")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                TextField("Key", text: $extraParamKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))

                TextField("Value", text: $extraParamValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))
            }

            Button(action: {
                guard !extraParamKey.isEmpty else { return }
                Noctua.setSessionExtraParams(payload: [extraParamKey: extraParamValue])
                statusText = "Extra param set: \(extraParamKey)=\(extraParamValue)"
                logger.debug("Set extra param: \(extraParamKey)=\(extraParamValue)")
            }) {
                actionButtonLabel("Set Extra Params", color: .purple)
            }

            // Status
            if !statusText.isEmpty {
                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
}

// MARK: - Result Row

private struct ResultRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        Text("\(label): \(value)")
            .font(.system(size: 11, design: .monospaced))
            .foregroundColor(.secondary)
            .lineLimit(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(color.opacity(0.1))
            .cornerRadius(6)
    }
}
