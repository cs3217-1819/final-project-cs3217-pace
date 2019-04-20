//
//  UserInteractor.swift
//  Pace
//
//  Created by Julius Sander on 31/3/19.
//  Copyright © 2019 nus.cs3217.pace. All rights reserved.
//

import RealmSwift
import FacebookCore

class RealmUserSessionManager: UserSessionManager {

    static let `default` = RealmUserSessionManager()

    private(set) var storageAPI: PaceUserAPI

    private var storageManager: RealmStorageManager

    private var realm: Realm {
        return storageManager.persistentRealm
    }

    var currentUser: User? {
        guard let uid = AccessToken.current?.userId else {
            return nil
        }
        return getRealmUser(uid)
    }

    convenience init() {
        self.init(storageManager: CachingStorageManager.default, storageAPI: PaceFirebaseAPI())
    }

    init(storageManager: RealmStorageManager, storageAPI: PaceUserAPI) {
        self.storageManager = storageManager
        self.storageAPI = storageAPI
    }

    /// Gets the realm user based on the uid in the current AccessToken
    /// Optionally can input a uid as an argument to override the access token
    func getRealmUser(_ uid: String?) -> User? {
        guard let currentUid = uid ?? AccessToken.current?.userId else {
            return nil
        }

        return storageManager.persistentRealm.objects(User.self)
            .filter { $0.uid == currentUid }.first
    }

    func findOrCreateUser(with uid: String, _ completion: @escaping UserResultsHandler) {
        storageAPI.findOrCreateFirebaseUser(with: uid) { user, error in
            guard let user = user else {
                return
            }
            try! self.realm.write {
                self.realm.add(user, update: true)
            }
            completion(user, error)
        }
    }

    func getFavouriteRoutes(of user: User) {
        storageAPI.fetchFavourites(userId: user.objectId) { routes, _ in
            guard let routes = routes else {
                return
            }
            try! self.realm.write {
                self.realm.add(routes, update: true)
                print("Before update: \(user.favouriteRoutes)")
                user.favouriteRoutes.removeAll()
                user.favouriteRoutes.append(objectsIn: routes)
                print("After update: \(user.favouriteRoutes)")
            }
        }
    }

    func addToFavourites(route: Route, to user: User?, _ completion: BooleanHandler?) {
        var success = true
        do {
            guard let user = user else {
                print("user not found")
                throw NSError()
            }
            storageManager.addFavouriteRoute(route, toUser: user) { completion?($0 == nil) }
        } catch {
            print("Operation unsuccessful: \(error.localizedDescription)")
            success = false
        }
        completion?(success)
    }

    func removeFromFavourites(route: Route, from user: User?, _ completion: BooleanHandler?) {
        var success = true
        do {
            guard let user = user else {
                print("user not found")
                throw NSError()
            }
            storageManager.removeFavouriteRoute(route, fromUser: user) { completion?($0 == nil) }
        } catch {
            print("Operation unsuccessful: \(error.localizedDescription)")
            success = false
        }
        completion?(success)
    }
}