//
//  ContentView.swift
//  water
//
//  Created by Leny Levant on 21/07/2024.
//

import SwiftUI

struct CupPreset: Identifiable, Codable {
  var id = UUID()
  var name: String
  var volume: Int
}

class WaterTrackerModel: ObservableObject {
  @Published var dailyGoal: Int
  @Published var currentIntake: Int
  @Published var cupPresets: [CupPreset]
  @Published var showAlert: Bool

  init() {
    let storedDailyGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
    self.dailyGoal = storedDailyGoal != 0 ? storedDailyGoal : 2000
    self.currentIntake = UserDefaults.standard.integer(forKey: "currentIntake")
    self.showAlert = false

    if let savedPresets = UserDefaults.standard.data(forKey: "cupPresets"),
      let decodedPresets = try? JSONDecoder().decode([CupPreset].self, from: savedPresets)
    {
      self.cupPresets = decodedPresets
    } else {
      self.cupPresets = [
        CupPreset(name: "Small", volume: 200),
        CupPreset(name: "Medium", volume: 350),
        CupPreset(name: "Large", volume: 500),
      ]
    }
  }

  func saveDailyGoal() {
    UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
  }

  func saveCurrentIntake() {
    UserDefaults.standard.set(currentIntake, forKey: "currentIntake")
    checkGoalReached()
  }

  func saveCupPresets() {
    if let encoded = try? JSONEncoder().encode(cupPresets) {
      UserDefaults.standard.set(encoded, forKey: "cupPresets")
    }
  }

  private func checkGoalReached() {
    if currentIntake >= dailyGoal && currentIntake > 0 {
      showAlert = true
    }
  }

  func resetDaily() {
    currentIntake = 0
    showAlert = false
    saveCurrentIntake()
  }

  func addWater(_ volume: Int) {
    currentIntake = min(currentIntake + volume, dailyGoal)
    saveCurrentIntake()
  }
}

struct WaveShape: Shape {
  var yOffset: CGFloat

  var animatableData: CGFloat {
    get { yOffset }
    set { yOffset = newValue }
  }

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let width = rect.width
    let height = rect.height
    let midWidth = width / 2
    let waveMidWidth = width / 4

    path.move(to: CGPoint(x: 0, y: yOffset))

    path.addCurve(
      to: CGPoint(x: midWidth, y: yOffset),
      control1: CGPoint(x: waveMidWidth, y: yOffset + 20),
      control2: CGPoint(x: midWidth - waveMidWidth, y: yOffset - 20)
    )

    path.addCurve(
      to: CGPoint(x: width, y: yOffset),
      control1: CGPoint(x: midWidth + waveMidWidth, y: yOffset + 20),
      control2: CGPoint(x: width - waveMidWidth, y: yOffset - 20)
    )

    path.addLine(to: CGPoint(x: width, y: height))
    path.addLine(to: CGPoint(x: 0, y: height))
    path.closeSubpath()

    return path
  }
}

struct ContentView: View {
  @StateObject private var model = WaterTrackerModel()
  @State private var showingSettings = false
  @State private var waveOffset: CGFloat = 0
  @State private var showingCustomAdd = false
  @State private var customVolume: Double = 250  // Default starting volume
  @State private var isEditing = false

  var body: some View {
    NavigationView {
      ZStack {
        VStack {
          ZStack {
            Circle()
              .stroke(Color.blue.opacity(0.2), lineWidth: 20)
              .frame(width: 250, height: 250)

            Circle()
              .trim(from: 0, to: CGFloat(model.currentIntake) / CGFloat(model.dailyGoal))
              .stroke(Color.blue, style: StrokeStyle(lineWidth: 20, lineCap: .round))
              .frame(width: 250, height: 250)
              .rotationEffect(.degrees(-90))
              .animation(.spring(), value: model.currentIntake)

            VStack {
              Text("\(model.currentIntake)")
                .font(.system(size: 50, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
              Text("/ \(model.dailyGoal) mL")
                .font(.title3)
                .foregroundColor(.gray)
            }
          }
          .padding(.top, 50)

          Divider()
            .background(Color.gray)
            .padding([.leading, .trailing], 20)
            .padding(.top, 25)

          Text("Add Water's")
            .font(.headline)
            .foregroundColor(.gray)
            .padding(.top, 20)

          LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 20) {
            Button(action: {
              showingCustomAdd = true
            }) {
              VStack {
                Image(systemName: "plus.circle.fill")
                  .font(.system(size: 30))
                  .foregroundColor(.white)
                  .frame(width: 60, height: 60)
                  .background(Color.blue)
                  .clipShape(Circle())
                Text("Custom")
                  .font(.caption)
                  .foregroundColor(.gray)
                  .bold()
                Text("Add")
                  .font(.caption2)
                  .foregroundColor(.gray)
                  .bold()
              }
            }
            .buttonStyle(PlainButtonStyle())
            .sheet(isPresented: $showingCustomAdd) {
              CustomVolumeAddView(model: model, showingModal: $showingCustomAdd)
                .presentationDetents([.height(300)])
            }
            ForEach(model.cupPresets) { preset in
              Button(action: {
                withAnimation {
                  model.addWater(preset.volume)
                }
              }) {
                VStack {
                  Image(systemName: "drop.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.blue)
                    .clipShape(Circle())
                  Text(preset.name)
                    .font(.caption)
                    .foregroundColor(.gray)
                  Text("\(preset.volume) mL")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .italic()
                }
              }
              .buttonStyle(PlainButtonStyle())
            }
          }
          .padding()

          Spacer()
        }
      }
      .navigationTitle("Water Tracker")
      .navigationBarItems(
        trailing: Button(action: {
          showingSettings = true
        }) {
          Image(systemName: "gearshape.fill")
            .foregroundColor(.blue)
        }
      )
      .sheet(isPresented: $showingSettings) {
        SettingsView(model: model)
      }
      .alert(isPresented: $model.showAlert) {
        Alert(
          title: Text("Goal Reached!"),
          message: Text("Congratulations on reaching your daily water intake goal!"),
          dismissButton: .default(Text("Great!"))
        )
      }
      .onAppear {
        withAnimation(Animation.linear(duration: 2).repeatForever(autoreverses: false)) {
          waveOffset = 400
        }
      }
    }
  }
}

struct CustomVolumeAddView: View {
  @ObservedObject var model: WaterTrackerModel
  @Binding var showingModal: Bool
  @State private var selectedVolume: Int = 250
  @State private var dragOffset: CGFloat = 0
  @State private var isEditing = false
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    VStack(spacing: 30) {
      RoundedRectangle(cornerRadius: 3)
        .fill(Color.gray.opacity(0.3))
        .frame(width: 40, height: 6)
        .padding(.top, 10)

      Text("Add Water")
        .font(.headline)
        .foregroundColor(.primary)

      Text("\(selectedVolume) mL")
        .font(.system(size: 50, weight: .bold, design: .rounded))
        .foregroundColor(.blue)
        .frame(height: 60)
        .contentShape(Rectangle())
        .gesture(
          DragGesture()
            .onChanged { value in
              dragOffset = value.translation.height
              let change = Int(-dragOffset / 10)
              selectedVolume = max(0, min(2000, selectedVolume + change))
            }
            .onEnded { _ in
              dragOffset = 0
            }
        )
        .gesture(
          TapGesture()
            .onEnded {
              isEditing = true
            }
        )

      if isEditing {
        TextField("Enter volume", value: $selectedVolume, formatter: NumberFormatter())
          .keyboardType(.numberPad)
          .textFieldStyle(RoundedBorderTextFieldStyle())
          .multilineTextAlignment(.center)
          .frame(width: 150)
          .onSubmit {
            isEditing = false
          }
      }

      Button(action: {
        model.addWater(selectedVolume)
        showingModal = false
      }) {
        Text("Confirm")
          .font(.headline)
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .cornerRadius(15)
      }
      .padding(.horizontal)

      Spacer()
    }
    .padding()
    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
    .edgesIgnoringSafeArea(.bottom)
  }
}

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
      .navigationBarItems(
        trailing: Button("Done") {
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

#Preview {
  ContentView()
}
