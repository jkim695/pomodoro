import SwiftUI

/// Shop for purchasing new orb styles
struct ShopView: View {
    @EnvironmentObject var rewardsManager: RewardsManager
    @State private var selectedStyle: OrbStyle?
    @State private var selectedCategory: OrbCategory?

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Balance header
                HStack {
                    Text("Shop")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.pomTextPrimary)

                    Spacer()

                    StardustBadge(amount: rewardsManager.balance.current, size: .medium)
                }
                .padding(.horizontal)

                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryButton(
                            title: "All",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(OrbCatalog.sortedCategories, id: \.self) { category in
                            CategoryButton(
                                title: category.rawValue,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Orbs grid by category
                if let category = selectedCategory {
                    // Single category view
                    CategorySection(
                        category: category,
                        styles: stylesForCategory(category),
                        isOwned: { rewardsManager.collection.owns($0.id) },
                        isEquipped: { rewardsManager.collection.isEquipped($0.id) },
                        onSelect: { selectedStyle = $0 }
                    )
                } else {
                    // All categories
                    ForEach(OrbCatalog.sortedCategories, id: \.self) { category in
                        let styles = stylesForCategory(category)
                        if !styles.isEmpty {
                            CategorySection(
                                category: category,
                                styles: styles,
                                isOwned: { rewardsManager.collection.owns($0.id) },
                                isEquipped: { rewardsManager.collection.isEquipped($0.id) },
                                onSelect: { selectedStyle = $0 }
                            )
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .background(Color.pomBackground)
        .navigationTitle("Shop")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedStyle) { style in
            OrbDetailSheet(style: style)
        }
    }

    private func stylesForCategory(_ category: OrbCategory) -> [OrbStyle] {
        OrbCatalog.all.filter { $0.category == category }
    }
}

// MARK: - Supporting Views

private struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : .pomTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.pomPrimary : Color.pomCardBackground)
                )
        }
    }
}

private struct CategorySection: View {
    let category: OrbCategory
    let styles: [OrbStyle]
    let isOwned: (OrbStyle) -> Bool
    let isEquipped: (OrbStyle) -> Bool
    let onSelect: (OrbStyle) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(category.rawValue)
                    .font(.headline)
                    .foregroundColor(.pomTextPrimary)

                Spacer()

                Text("\(styles.count) orbs")
                    .font(.caption)
                    .foregroundColor(.pomTextTertiary)
            }
            .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(styles) { style in
                    OrbPreviewCard(
                        style: style,
                        isOwned: isOwned(style),
                        isEquipped: isEquipped(style)
                    ) {
                        onSelect(style)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    NavigationStack {
        ShopView()
            .environmentObject(RewardsManager.shared)
    }
}
