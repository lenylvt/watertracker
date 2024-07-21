//
//  WaterTrackerModel.swift
//  water
//
//  Created by Leny Levant on 21/07/2024.
//

import SwiftUI
import WatchConnectivity

struct CupPreset: Identifiable, Codable {
    var id = UUID()
    var name: String
    var volume: Int
}

class WaterTrackerModel: NSObject, ObservableObject {
    @Published var dailyGoal: Int {
        didSet {
            saveDailyGoal()
        }
    }
    @Published var currentIntake: Int {
        didSet {
            saveCurrentIntake()
        }
    }
    @Published var cupPresets: [CupPreset] {
        didSet {
            saveCupPresets()
        }
    }

    override init() {
        let storedDailyGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        self.dailyGoal = storedDailyGoal != 0 ? storedDailyGoal : 2000
        self.currentIntake = UserDefaults.standard.integer(forKey: "currentIntake")

        if let savedPresets = UserDefaults.standard.data(forKey: "cupPresets"),
           let decodedPresets = try? JSONDecoder().decode([CupPreset].self, from: savedPresets) {
            self.cupPresets = decodedPresets
        } else {
            self.cupPresets = [
                CupPreset(name: "Small", volume: 200),
                CupPreset(name: "Medium", volume: 350),
                CupPreset(name: "Large", volume: 500),
            ]
        }

        super.init()
        setupWatchConnectivity()
    }

    func saveDailyGoal() {
        UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        syncData()
    }

    func saveCurrentIntake() {
        UserDefaults.standard.set(currentIntake, forKey: "currentIntake")
        syncData()
    }

    func saveCupPresets() {
        if let encoded = try? JSONEncoder().encode(cupPresets) {
            UserDefaults.standard.set(encoded, forKey: "cupPresets")
        }
        syncData()
    }

    func resetDaily() {
        currentIntake = 0
    }

    func addWater(_ volume: Int) {
        currentIntake = min(currentIntake + volume, dailyGoal)
    }

    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    private func syncData() {
        if WCSession.default.activationState == .activated {
            let data: [String: Any] = [
                "currentIntake": currentIntake,
                "dailyGoal": dailyGoal,
                "cupPresets": cupPresets.map { ["name": $0.name, "volume": $0.volume] }
            ]
            WCSession.default.transferUserInfo(data)
        }
    }
}

extension WaterTrackerModel: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle activation completion
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            if let intake = userInfo["currentIntake"] as? Int {
                self.currentIntake = intake
            }
            if let goal = userInfo["dailyGoal"] as? Int {
                self.dailyGoal = goal
            }
            if let presets = userInfo["cupPresets"] as? [[String: Any]] {
                self.cupPresets = presets.compactMap { preset in
                    guard let name = preset["name"] as? String,
                          let volume = preset["volume"] as? Int else { return nil }
                    return CupPreset(name: name, volume: volume)
                }
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive (iOS only)
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Handle session deactivation (iOS only)
        WCSession.default.activate()
    }
}
