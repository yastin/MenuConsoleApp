import SwiftUI

struct SettingsView: View {
    @AppStorage("projectPath") private var projectPath = "~/DZO/dzo_local_environment"
    @AppStorage("composeFiles") private var composeFiles = "docker-compose.yml, docker-compose.override.yml"

    var body: some View {
        Form {
            LabeledContent("Project Path") {
                HStack {
                    TextField("", text: $projectPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse…") {
                        browseFolder()
                    }
                }
            }
            LabeledContent("Compose Files") {
                TextField("", text: $composeFiles)
                    .textFieldStyle(.roundedBorder)
            }
            Text("Comma-separated file names relative to project path")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 480)
    }

    private func browseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            projectPath = url.path
        }
    }
}
