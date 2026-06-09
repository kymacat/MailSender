//
//  LoginAssembly.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import UIKit

enum LoginAssembly {
    static func build(with router: LoginRouterProtocol) -> UIViewController {
        let view = LoginViewController()
        let presenter = LoginPresenter(view: view, router: router)
        view.presenter = presenter
        return view
    }
}
