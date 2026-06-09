//
//  LoginRouterProtocol.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

protocol LoginRouterProtocol: AnyObject {
    func navigateToMailComposer(with credentials: UserCredentials)
}
