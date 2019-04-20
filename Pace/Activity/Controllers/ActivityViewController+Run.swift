//
//  ActivityViewController+Run.swift
//  Pace
//
//  Created by Ang Wei Neng on 3/4/19.
//  Copyright © 2019 nus.cs3217.pace. All rights reserved.
//

import UIKit
import CoreLocation
import GoogleMaps

// MARK: - Running methods
extension ActivityViewController {
    @objc
    func startRun(_ sender: UIButton) {
        guard !runStarted else {
            return
        }
        startingRun()
    }

    func resumeRun(run persistedRun: OngoingRun,
                   startedAt timeStarted: Date,
                   interruptedAt timeInterrupted: Date,
                   persistedOffset: Double) {
        ongoingRun = persistedRun
        let offset = timeInterrupted.timeIntervalSince(timeStarted)
        VoiceAssistant.say("Continuing Run")
        coreLocationManager.startUpdatingLocation()
        stopwatch.resume(with: persistedOffset + offset)
        setMapButton(imageUrl: Constants.endButton, action: #selector(endRun))
        updateValues()
        // If the terminated run was followin3g
        if let _ = ongoingRun?.paceRun {
            updatePacingStats()
        }
    }

    func startingRun() {
        guard let startLocation = coreLocationManager.location else {
            return
        }
        initiateRunPlot(at: startLocation)
        setMapButton(imageUrl: Constants.endButton, action: #selector(endRun(_:)))
        startNewRunSession(at: startLocation)
        updateValues()
    }

    func startingFollowRun(with paceRun: Run) -> Bool {
        guard
            let startingLocation = coreLocationManager.location,
            let paceRunStart = paceRun.startingLocation else {
                return false
        }
        guard startingLocation.isSameAs(other: paceRunStart) else {
            return false
        }
        initiateRunPlot(at: startingLocation, following: paceRun)
        setMapButton(imageUrl: Constants.endButton, action: #selector(endRun(_:)))
        startFollowRunSession(at: startingLocation, following: paceRun)
        updateValues()
        updatePacingStats()
        return true
    }

    private func initiateRunPlot(at location: CLLocation, following paceRun: Run? = nil) {
        googleMapView.startRun(at: location.coordinate, followingRun: paceRun)
    }

    private func startNewRunSession(at location: CLLocation) {
        VoiceAssistant.say("Starting new run")
        coreLocationManager.startUpdatingLocation()
        stopwatch.start()
        ongoingRun = OngoingRun(runner: userSession.currentUser, startingLocation: location)
    }

    private func startFollowRunSession(at location: CLLocation, following paceRun: Run) {
        VoiceAssistant.say("Starting follow run")
        coreLocationManager.startUpdatingLocation()
        stopwatch.start()
        ongoingRun = OngoingRun(runner: userSession.currentUser, startingLocation: location, paceRun: paceRun)
    }

    @objc
    func endRun(_ sender: UIButton) {
        guard runStarted else {
            return
        }
        VoiceAssistant.say("Run completed")

        // TODO: ALL OUR ENDRUN LOGIC SHOULD BE DONE HERE
        // 1. Start loading animation
        // 2. Perform normalisation shit here
        // 3. Add end flag
        // 4. Rerender the normalized-map and take a screenshot
        // 5. Show the map in the summary page. Cannot just be screenshot
        //    because of runAnalysis.
        // 6. When we press "exit summary", clean up flag drawings.
        googleMapView.addMarker(Constants.endFlag, position: coreLocationManager.location!.coordinate)
        googleMapView.completeRun()

        setMapButton(imageUrl: Constants.startButton, action: #selector(startRun(_:)))

        showSummary()

        ongoingRun = nil
        stopwatch.reset()
        coreLocationManager.stopUpdatingLocation()
        updateLabels()
    }

    private func showSummary() {
        let storyBoard: UIStoryboard = UIStoryboard(name: Identifiers.storyboard, bundle: nil)
        let summaryVC =
            storyBoard.instantiateViewController(
                withIdentifier: Identifiers.summaryViewController)
                as! ActivitySummaryViewController
        summaryVC.setRun(as: ongoingRun)
        self.navigationController?.pushViewController(summaryVC, animated: true)
    }

    private func updatePacingStats() {
        guard runStarted else {
            return
        }
        VoiceAssistant.reportPacing(using: ongoingRun?.getPacingStats())
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.updatePacingStats()
        }
    }

    private func updateValues() {
        guard runStarted else {
            return
        }
        updateLabels()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.updateValues()
        }
    }

    private func updateLabels() {
        guard let distanceSoFar = ongoingRun?.distanceSoFar else {
            runStats.setStats(distance: 0, time: 0)
            return
        }
        runStats.setStats(distance: distanceSoFar, time: stopwatch.timeElapsed)
    }
}
