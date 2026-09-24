import SwiftUI

/// The round glass + button. Tapping it melts it into a text field (Liquid
/// Glass morph), so a task can be typed and added in one go. The field stays
/// open after adding, which makes typing a whole day's tasks quick.
struct QuickAddBar: View {
    @Binding var isExpanded: Bool
    var placeholder: LocalizedStringKey = "New Task"
    var onAdd: (String) -> Void
    /// Opens the full editor with the typed title. Hidden when nil.
    var onShowDetails: ((String) -> Void)?

    @Environment(\.accent) private var accent
    @State private var text = ""
    @FocusState private var isFocused: Bool
    @Namespace private var glass

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            HStack(spacing: 12) {
                if isExpanded {
                    field
                        .glassEffectID("field", in: glass)
                }
                mainButton
                    .glassEffectID("button", in: glass)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .onChange(of: isExpanded) { _, expanded in
            isFocused = expanded
            if !expanded {
                text = ""
            }
        }
        .onChange(of: isFocused) { _, focused in
            guard !focused else { return }
            // Close again when the keyboard goes away with nothing typed.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                if !isFocused && trimmed.isEmpty && isExpanded {
                    close()
                }
            }
        }
    }

    private var field: some View {
        HStack(spacing: 10) {
            TextField(placeholder, text: $text)
                .tikFont(.body)
                .focused($isFocused)
                .submitLabel(.done)
                .onSubmit(submit)
                .accessibilityIdentifier("quickAddField")

            if let onShowDetails {
                Button {
                    let title = trimmed
                    close()
                    onShowDetails(title)
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body.weight(.medium))
                        .frame(width: 32, height: 32)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .accessibilityLabel(Text("More Details"))
            }
        }
        .padding(.leading, 20)
        .padding(.trailing, 12)
        .frame(height: 54)
        .glassEffect(.regular.tint(Color(uiColor: .systemBackground).opacity(0.6)).interactive(), in: .capsule)
    }

    private var mainButton: some View {
        Button(action: mainButtonTapped) {
            Image(systemName: isExpanded && !trimmed.isEmpty ? "arrow.up" : "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(isExpanded && trimmed.isEmpty ? 45 : 0))
                .contentTransition(.symbolEffect(.replace))
                .frame(width: 54, height: 54)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
        .glassEffect(.regular.tint(accent.color).interactive(), in: .circle)
        .accessibilityLabel(isExpanded ? (trimmed.isEmpty ? Text("Close") : Text("Add")) : Text("New Task"))
        .accessibilityIdentifier("quickAddButton")
    }

    private func mainButtonTapped() {
        if !isExpanded {
            withAnimation(.bouncy(duration: 0.45)) { isExpanded = true }
        } else if trimmed.isEmpty {
            close()
        } else {
            submit()
        }
    }

    private func submit() {
        guard !trimmed.isEmpty else {
            close()
            return
        }
        onAdd(trimmed)
        text = ""
        // Pressing return hides the keyboard; bring it back for the next task.
        Task { @MainActor in
            isFocused = true
        }
    }

    private func close() {
        isFocused = false
        withAnimation(.bouncy(duration: 0.45)) { isExpanded = false }
    }
}
