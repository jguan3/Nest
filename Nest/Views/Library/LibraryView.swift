import SwiftData
import SwiftUI

/// Accordion library of color-coded folders and saved thoughts.
struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \ThoughtFolder.sortOrder) private var folders: [ThoughtFolder]
    @State private var expandedFolderIDs: Set<UUID> = []
    @State private var isCreateFolderPresented = false

    private var sections: [LibraryFolderSection] {
        LibraryViewModel.sections(from: folders)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                NestBackground()

                if sections.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(sections) { section in
                                FolderAccordionCard(
                                    section: section,
                                    isExpanded: binding(for: section.folder),
                                    onDeleteThought: { thought in
                                        LibraryViewModel.delete(thought, in: modelContext)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(NestTheme.secondaryText)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isCreateFolderPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(Color(red: 0.55, green: 0.62, blue: 1.0))
                    }
                    .accessibilityLabel("Create folder")
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                if expandedFolderIDs.isEmpty,
                   let music = folders.first(where: { $0.name == "Music" }) {
                    expandedFolderIDs.insert(music.id)
                }
            }
            .sheet(isPresented: $isCreateFolderPresented) {
                CreateFolderSheet()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(NestTheme.secondaryText)
            Text("No folders yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(NestTheme.primaryText)
            Button("Create Folder") { isCreateFolderPresented = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func binding(for folder: ThoughtFolder) -> Binding<Bool> {
        Binding(
            get: { expandedFolderIDs.contains(folder.id) },
            set: { isExpanded in
                if isExpanded {
                    expandedFolderIDs.insert(folder.id)
                } else {
                    expandedFolderIDs.remove(folder.id)
                }
            }
        )
    }
}

private struct FolderAccordionCard: View {
    let section: LibraryFolderSection
    @Binding var isExpanded: Bool
    let onDeleteThought: (Thought) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(FolderColor.gradient(for: section.folder.colorName))
                        .frame(width: 44, height: 44)
                        .overlay {
                            Image(systemName: section.folder.isInbox ? "tray.fill" : "folder.fill")
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(section.folder.name)
                            .font(.headline)
                            .foregroundStyle(NestTheme.primaryText)
                        if !section.folder.isInbox {
                            Text("Say \"\(section.folder.name)\"")
                                .font(.caption)
                                .foregroundStyle(NestTheme.secondaryText)
                        }
                    }

                    Spacer()

                    Text("\(section.thoughts.count)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(NestTheme.secondaryText)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.08)))

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(NestTheme.secondaryText)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(.plain)

            if isExpanded {
                Divider()
                    .overlay(NestTheme.cardStroke)

                if section.thoughts.isEmpty {
                    Text("No thoughts yet")
                        .font(.subheadline)
                        .foregroundStyle(NestTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(section.thoughts) { thought in
                            ThoughtRow(thought: thought, colorName: section.folder.colorName)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        onDeleteThought(thought)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            if thought.id != section.thoughts.last?.id {
                                Divider()
                                    .overlay(NestTheme.cardStroke)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(NestTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(NestTheme.cardStroke, lineWidth: 1)
                )
        )
    }
}

private struct ThoughtRow: View {
    let thought: Thought
    let colorName: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 2)
                .fill(FolderColor.from(name: colorName))
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text(thought.text)
                    .font(.body)
                    .foregroundStyle(NestTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(thought.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption)
                    .foregroundStyle(NestTheme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [Thought.self, ThoughtFolder.self], inMemory: true)
}
