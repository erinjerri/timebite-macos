import SwiftUI

struct AppSpaceSwitcher: View {
	let selectedSpace: AppSpace
	let onSelect: (AppSpace) -> Void
	@State private var pickerSelection: AppSpace

	init(selectedSpace: AppSpace, onSelect: @escaping (AppSpace) -> Void) {
		self.selectedSpace = selectedSpace
		self.onSelect = onSelect
		_pickerSelection = State(initialValue: selectedSpace)
	}

	var body: some View {
		Picker("App Space", selection: $pickerSelection) {
			ForEach(AppSpace.allCases) { space in
				Text(space.displayTitle).tag(space)
			}
		}
        .pickerStyle(.segmented)
		.labelsHidden()
		.font(TimeBiteTypography.font(.callout, weight: .medium))
		.onChange(of: pickerSelection) { _, newValue in
			onSelect(newValue)
		}
		.onChange(of: selectedSpace) { _, newValue in
			pickerSelection = newValue
		}
	}
}
