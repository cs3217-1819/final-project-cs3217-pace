//
//  ProfileViewController.swift
//  Pace
//
//  Created by Ang Wei Neng on 21/3/19.
//  Copyright © 2019 nus.cs3217.pace. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Facebook login button setup
        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = view.center
        loginButton.delegate = self

        view.addSubview(loginButton)

        indicator.center = view.center.applying(CGAffineTransform(translationX: 0, y: -100))
        updateIndicator()

        view.addSubview(indicator)
    }
    // MARK: - Login & Firestore methods

    /// An indicator for whether the user is logged in.
    private var indicator: UILabel = {
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 300, height: 50))
        label.backgroundColor = .clear
        label.textAlignment = .center
        return label
    }()

    /// Information about routes (show how the api is working)
    private var routeInfo: UILabel = {
        let label = UILabel(frame: CGRect(x: 0.0, y: 0.0, width: 300, height: 50))
        label.backgroundColor = .clear
        label.textAlignment = .center
        label.font = UIFont(name: "System", size: 10.0)
        return label
    }()

    // (Should store an instance in each controller I think?)

    /// Updates the log in indicator.
    private func updateIndicator() {
        UserManager.currentUser { user in
            guard let user = user else {
                self.indicator.text = "Please log in"
                return
            }
            self.indicator.text = "Welcome back \(user.name)"
        }
    }

}

extension ProfileViewController: LoginButtonDelegate {
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        switch result {
        case .success(_, _, let token):
            UserManager.logIn(withFacebookToken: token) {
                if $0 {
                    print("success!")
                } else {
                    print("error signing in")
                }
                self.updateIndicator()
            }
        case .failed(let err):
            print(err.localizedDescription)
        case .cancelled:
            print("cancelled by user")
        }
    }

    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        do {
            try UserManager.logOut { self.updateIndicator() }
        } catch {
            print(error.localizedDescription)
        }
    }
}