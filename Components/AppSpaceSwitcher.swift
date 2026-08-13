import SwiftUI

struct AppSpaceSwitcher: View {
    @Binding var selectedSpace: AppSpace

    var body: some View {
        Picker("App Space", selection: $selectedSpace) {
            ForEach(AppSpace.allCases) { space in
                Text(space.displayTitle).tag(space)
            }
        }
        .pickerStyle(.segmented)
    }
}
