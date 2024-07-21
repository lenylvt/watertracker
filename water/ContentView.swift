//
//  ContentView.swift
//  water
//
//  Created by Leny Levant on 21/07/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model = WaterTrackerModel()
    @State private var showingSettings = false
    @State private var showingCustomAdd = false
    @State private var customVolume: Double = 250

    var body: some View {
        NavigationView {
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
                        Text("Current Progress")
                            .font(.caption)
                            .italic()
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

                Text("Add Water")
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
                            Text("Add")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .bold()
                            Text("Custom")
                                .font(.caption2)
                                .foregroundColor(.gray)
                                .bold()
                        }
                    }
                    .sheet(isPresented: $showingCustomAdd) {
                        CustomVolumeAddView(model: model, showingModal: $showingCustomAdd)
                        .presentationDetents([.height(350)])
                    }

                    ForEach(model.cupPresets) { preset in
                        Button(action: {
                            model.addWater(preset.volume)
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
                    }
                }
                .padding()

                Spacer()
            }
            .navigationTitle("Water Tracker")
            .navigationBarItems(trailing: Button(action: {
                showingSettings = true
            }) {
                Image(systemName: "gearshape.fill")
            })
            .sheet(isPresented: $showingSettings) {
                SettingsView(model: model)
            }
        }
    }
}


#Preview {
  ContentView()
}
