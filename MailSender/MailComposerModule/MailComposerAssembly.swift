//
//  MailComposerAssembly.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import UIKit

enum MailComposerAssembly {
    static func build(
        credentials: UserCredentials,
        credentialsService: CredentialsService,
        router: MailComposerRouterProtocol
    ) -> UIViewController {
        let view = MailComposerViewController()
        let smtpClient = SMTPClient(
            credentials: SMTPCredentials(
                host: credentials.server,
                username: credentials.email,
                loadPassword: { try credentialsService.password }
            )
        )

        let presenter = MailComposerPresenter(
            view: view,
            router: router,
            credentials: credentials,
            smtpClient: smtpClient
        )
        view.presenter = presenter
        return view
    }
}
