//
//  FirebaseDB+Paces.swift
//  Pace
//
//  Created by Tan Zheng Wei on 22/3/19.
//  Copyright © 2019 nus.cs3217.pace. All rights reserved.
//

import Foundation

/* Paces Collection API */
extension FirebaseDB {
    /// Retrieve Paces of a certain route
    static func retrievePaces(of route: Route, callback: @escaping ([Pace]?) -> Void) {
        guard let routeId = route.docId else {
            return
        }
        paces.whereField(FireDB.Pace.routeId, isEqualTo: routeId).getDocuments { snapshot, error in
            guard let snapshot = snapshot else {
                print("Error acquiring paces of route: \(String(describing: error))")
                return
            }
            var paces = [Pace]()

            for document in snapshot.documents {
                var data = document.data()
                guard let userId = data[FireDB.Pace.userId] as? String else {
                    continue
                }
                users.document(userId).getDocument { userSnapshot, _ in
                    data[FireDB.Pace.userData] = userSnapshot?.data()
                }
                guard let pace = Pace(docId: document.documentID, data: data) else {
                    continue
                }
                paces.append(pace)
            }
            callback(paces)
        }
    }

    /// Retrieve the timings of a pace
    static func retrieveTimings(of pace: Pace, callback: @escaping ([Double]?) -> Void) {
        guard let paceId = pace.docId else {
            return
        }
        paces.document(paceId).getDocument { snapshot, error in
            guard
                let snapshot = snapshot,
                let timings = snapshot.data()?[FireDB.Pace.timings] as? [Double] else {
                print("Error loading pace \(String(describing: error))")
                return
            }
            callback(timings)
        }
    }
}
