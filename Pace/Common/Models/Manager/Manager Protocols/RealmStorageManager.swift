//
//  RealmStorageManager.swift
//  Pace
//
//  Created by Julius Sander on 15/4/19.
//  Copyright © 2019 nus.cs3217.pace. All rights reserved.
//

import RealmSwift

protocol RealmStorageManager {
    /// A Typealias for handling errors.
    typealias ErrorHandler = (Error?) -> Void

    /// The default (persistent) realm for this manager.
    var persistentRealm: Realm { get }

    /// The default in-memory realm for this manager.
    var inMemoryRealm: Realm { get }

    /// Attempts to fetch a route within this area.
    func fetchRoutesWithin(latitudeMin: Double, latitudeMax: Double, longitudeMin: Double, longitudeMax: Double,
                           _ errorHandler: @escaping ErrorHandler)

    /// Attempts to fetch the runs for this specific Route.
    /// - Precondition: `route` must exist in a realm.
    func getRunsFor(route: Route)

    /// Attempts to fetch the runs for a specific User
    /// - Precondition: `user` must exist in a realm.
    func getRunsFor(user: User)

    /// Saves a new route.
    func saveNewRoute(_ route: Route, _ completion: ErrorHandler?)

    /// Saves a new run.
    func saveNewRun(_ run: Run, toRoute: Route, _ completion: ErrorHandler?)

    /// Adds a route to a user's favourites
    func addFavouriteRoute(_ route: Route, toUser user: User, _ completion: ErrorHandler?)

    /// Removes a route from a user
    func removeFavouriteRoute(_ route: Route, fromUser user: User, _ completion: ErrorHandler?)
}