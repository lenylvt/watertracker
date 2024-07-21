//
//  CustomVolumeAddView.swift
//  water
//
//  Created by Leny Levant on 21/07/2024.
//

import SwiftUI

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
