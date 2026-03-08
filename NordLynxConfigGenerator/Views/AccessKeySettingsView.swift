import SwiftUI

struct AccessKeySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var accessKeyInput: String = ""
    @State private var showConfirmation: Bool = false
    @State private var showResetConfirmation: Bool = false
    @State private var saved: Bool = false

    private let accentColor = Color(red: 0.0, green: 0.78, blue: 1.0)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    statusCard
                    keyInputSection
                    infoSection
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(
                MeshGradient(
                    width: 3, height: 3,
                    points: [
                        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
                        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                    ],
                    colors: [
                        .black, Color(red: 0.03, green: 0.05, blue: 0.15), .black,
                        Color(red: 0.0, green: 0.08, blue: 0.12), Color(red: 0.02, green: 0.06, blue: 0.18), Color(red: 0.0, green: 0.04, blue: 0.1),
                        .black, Color(red: 0.0, green: 0.06, blue: 0.1), .black
                    ]
                )
                .ignoresSafeArea()
            )
            .preferredColorScheme(.dark)
            .navigationTitle("Access Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .onAppear {
                let stored = UserDefaults.standard.string(forKey: ConfigGenerator.accessKeyStorageKey) ?? ""
                accessKeyInput = stored
            }
            .alert("Replace Access Key?", isPresented: $showConfirmation) {
                Button("Replace", role: .destructive) {
                    saveKey()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently replace your NordLynx access key. All future configs will use the new key.")
            }
            .alert("Reset to Default?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) {
                    resetKey()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will revert to the original built-in access key.")
            }
        }
    }

    private var statusCard: some View {
        VStack(spacing: 12) {
            Image(systemName: ConfigGenerator.isUsingCustomKey ? "key.fill" : "key")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(ConfigGenerator.isUsingCustomKey ? .green : accentColor)
                .symbolEffect(.bounce, value: saved)

            Text(ConfigGenerator.isUsingCustomKey ? "Custom Key Active" : "Using Default Key")
                .font(.headline)
                .foregroundStyle(.white)

            Text(maskedKey(ConfigGenerator.activePrivateKey))
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            if saved {
                Label("Key saved successfully", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
    }

    private var keyInputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Access Key", systemImage: "lock.shield")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("Paste your NordVPN access key…", text: $accessKeyInput, axis: .vertical)
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.white)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .lineLimit(3)
                .padding(12)
                .background(Color.white.opacity(0.06), in: .rect(cornerRadius: 10))

            HStack(spacing: 10) {
                Button {
                    showConfirmation = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                        Text("Save Key")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .disabled(accessKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if ConfigGenerator.isUsingCustomKey {
                    Button {
                        showResetConfirmation = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset")
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("How to get your access key", systemImage: "questionmark.circle")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                infoRow(number: "1", text: "Log in to your NordVPN account dashboard")
                infoRow(number: "2", text: "Go to NordVPN → Manual Setup")
                infoRow(number: "3", text: "Copy your Access Token / Private Key")
                infoRow(number: "4", text: "Paste it above and tap Save Key")
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 16))
    }

    private func infoRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(.caption, design: .monospaced, weight: .bold))
                .foregroundStyle(accentColor)
                .frame(width: 20, height: 20)
                .background(accentColor.opacity(0.15), in: .circle)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func maskedKey(_ key: String) -> String {
        guard key.count > 12 else { return String(repeating: "•", count: key.count) }
        let prefix = key.prefix(6)
        let suffix = key.suffix(6)
        return "\(prefix)••••••••\(suffix)"
    }

    private func saveKey() {
        ConfigGenerator.updateAccessKey(accessKeyInput)
        withAnimation(.spring(response: 0.4)) {
            saved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                saved = false
            }
        }
    }

    private func resetKey() {
        ConfigGenerator.updateAccessKey("")
        accessKeyInput = ""
        withAnimation(.spring(response: 0.4)) {
            saved = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                saved = false
            }
        }
    }
}
