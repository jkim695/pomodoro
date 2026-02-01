import SwiftUI
import FamilyControls

struct AppSelectionView: View {
    @EnvironmentObject var session: PomodoroSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pomCream
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Family Activity Picker
                    FamilyActivityPicker(selection: $session.selection)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.pomCardBackground)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.pomBrown.opacity(0.1), radius: 8, x: 0, y: 4)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.pomButton)
                    .foregroundColor(.pomPeach)
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 40))
                .foregroundColor(.pomPeach)

            Text("Choose Apps to Block")
                .font(.pomHeading)
                .foregroundColor(.pomBrown)

            Text("Select apps and categories that will be blocked during your focus sessions.")
                .font(.pomBody)
                .foregroundColor(.pomLightBrown)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
    }
}

#Preview {
    AppSelectionView()
        .environmentObject(PomodoroSession())
}
