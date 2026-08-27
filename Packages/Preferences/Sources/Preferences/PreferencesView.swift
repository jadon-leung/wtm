import SwiftUI
import WTMCore

public struct PreferencesView: View {
    private let user: WTMUser
    private let onSaved: () -> Void

    @Environment(\.services) private var services
    @State private var viewModel: PreferencesViewModel?

    public init(user: WTMUser, onSaved: @escaping () -> Void) {
        self.user = user
        self.onSaved = onSaved
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Theme.Colors.paper.ignoresSafeArea()

                if let viewModel {
                    content(for: viewModel)
                } else {
                    ProgressView()
                }
            }
            .navigationTitle("Your Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel?.save() == true {
                                onSaved()
                            }
                        }
                    } label: {
                        if viewModel?.isSaving == true {
                            ProgressView()
                        } else {
                            Text("Save").fontWeight(.bold)
                        }
                    }
                    .tint(Theme.Colors.coral)
                    .disabled(viewModel?.isSaving ?? true)
                }
            }
        }
        .task {
            if viewModel == nil {
                let model = PreferencesViewModel(userID: user.id, preferencesService: services.preferences)
                viewModel = model
                await model.load()
            }
        }
    }

    @ViewBuilder
    private func content(for viewModel: PreferencesViewModel) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("What's the plan?")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.ink)
                    Text("Your group's itinerary gets built from everyone's picks combined.")
                        .font(Theme.Typography.display(14, weight: .medium))
                        .foregroundStyle(Theme.Colors.mauve)
                }

                budgetSection(viewModel)
                chipSection(
                    title: "What are you in the mood for?",
                    options: ActivityType.allCases,
                    label: \.label,
                    isSelected: { viewModel.selectedActivityTypes.contains($0) },
                    toggle: { viewModel.toggleActivityType($0) }
                )
                chipSection(
                    title: "Cuisines",
                    options: PreferenceOptions.cuisines,
                    label: { $0 },
                    isSelected: { viewModel.selectedCuisines.contains($0) },
                    toggle: { viewModel.toggleCuisine($0) }
                )
                chipSection(
                    title: "Dietary restrictions",
                    options: PreferenceOptions.dietaryRestrictions,
                    label: { $0 },
                    isSelected: { viewModel.selectedDietaryRestrictions.contains($0) },
                    toggle: { viewModel.toggleDietaryRestriction($0) }
                )

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }

    private func budgetSection(_ viewModel: PreferencesViewModel) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            EyebrowLabel("Budget")
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(BudgetTier.allCases) { tier in
                    Button {
                        viewModel.budgetTier = tier
                    } label: {
                        Text(tier.label)
                            .font(Theme.Typography.display(15, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Theme.Spacing.sm + 2)
                            .foregroundStyle(viewModel.budgetTier == tier ? .white : Theme.Colors.ink)
                            .background(viewModel.budgetTier == tier ? Theme.Colors.coral : Theme.Colors.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                                    .strokeBorder(
                                        viewModel.budgetTier == tier ? Color.clear : Theme.Colors.hairline,
                                        lineWidth: 1.5
                                    )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func chipSection<Option: Hashable>(
        title: String,
        options: [Option],
        label: @escaping (Option) -> String,
        isSelected: @escaping (Option) -> Bool,
        toggle: @escaping (Option) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            EyebrowLabel(title)
            ChipFlowLayout(spacing: Theme.Spacing.sm) {
                ForEach(options, id: \.self) { option in
                    SelectableChip(label(option), isSelected: isSelected(option)) {
                        toggle(option)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .wtmCard()
    }
}

#Preview {
    PreferencesView(user: WTMUser(id: UUID(), displayName: "Jordan"), onSaved: {})
        .environment(\.services, .mock)
}
