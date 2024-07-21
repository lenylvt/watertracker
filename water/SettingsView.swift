//
//  SettingsView.swift
//  water
//
//  Created by Leny Levant on 21/07/2024.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: WaterTrackerModel
    @State private var newPresetName = ""
    @State private var newPresetVolume = ""
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Goal")) {
                    HStack {
                        TextField("Goal (mL)", value: $model.dailyGoal, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                        Text("mL")
                    }
                }

                Section(header: Text("Cup Presets")) {
                    ForEach(model.cupPresets) { preset in
                        HStack {
                            Text("\(preset.name) (\(preset.volume) mL)")
                        }
                    }
                    .onDelete(perform: deletePreset)

                    HStack {
                        TextField("Name", text: $newPresetName)
                        TextField("Volume", text: $newPresetVolume)
                            .keyboardType(.numberPad)
                        Button(action: addPreset) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section {
                    Button(action: model.resetDaily) {
                        Text("Reset Daily Progress")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Done") {
                model.saveDailyGoal()
                presentationMode.wrappedValue.dismiss()
            })
        }
    }

    private func addPreset() {
        guard let volume = Int(newPresetVolume), !newPresetName.isEmpty else { return }
        model.cupPresets.append(CupPreset(name: newPresetName, volume: volume))
        model.saveCupPresets()
        newPresetName = ""
        newPresetVolume = ""
    }

    private func deletePreset(at offsets: IndexSet) {
        model.cupPresets.remove(atOffsets: offsets)
        model.saveCupPresets()
    }
}
