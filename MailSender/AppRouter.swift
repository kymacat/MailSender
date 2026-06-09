//
//  AppRouter.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import UIKit

final class AppRouter {
    private let credentialsService = CredentialsService.shared
    private let navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        if let credentials = credentialsService.savedCredentials {
            let composerVC = MailComposerAssembly.build(
                credentials: credentials,
                credentialsService: credentialsService,
                router: self
            )
            navigationController.setViewControllers([composerVC], animated: false)
        } else {
            let loginVC = LoginAssembly.build(with: self)
            navigationController.setViewControllers([loginVC], animated: false)
        }
    }
}

// MARK: - LoginRouterProtocol

extension AppRouter: LoginRouterProtocol {
    func navigateToMailComposer(with credentials: UserCredentials) {
        let composerVC = MailComposerAssembly.build(
            credentials: credentials,
            credentialsService: credentialsService,
            router: self
        )
        navigationController.setViewControllers([composerVC], animated: true)
    }
}

// MARK: - MailComposerRouterProtocol

extension AppRouter: MailComposerRouterProtocol {
    func navigateToLogin() {
        let loginVC = LoginAssembly.build(with: self)
        navigationController.pushViewController(loginVC, animated: true)
    }
}
