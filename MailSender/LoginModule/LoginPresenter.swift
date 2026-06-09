//
//  LoginPresenter.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

protocol LoginPresenterProtocol: AnyObject {
    func viewDidLoad()
    func saveDidTap(server: String?, email: String?, password: String?)
}

final class LoginPresenter {
    private weak var view: LoginViewProtocol?
    private let credentialsService = CredentialsService.shared
    private let router: LoginRouterProtocol

    init(view: LoginViewProtocol, router: LoginRouterProtocol) {
        self.view = view
        self.router = router
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
}

// MARK: LoginPresenterProtocol

extension LoginPresenter: LoginPresenterProtocol {
    func viewDidLoad() {
        guard let credentials = credentialsService.savedCredentials,
              let passwordData = try? credentialsService.password
        else {
            return
        }

        view?.prefillCredentials(
            server: credentials.server,
            email: credentials.email,
            password: passwordData
        )
    }

    func saveDidTap(server: String?, email: String?, password: String?) {
        view?.clearErrors()

        guard let server = server?.trimmingCharacters(in: .whitespaces), !server.isEmpty else {
            view?.showError("Enter server")
            return
        }

        guard let email = email?.trimmingCharacters(in: .whitespaces), !email.isEmpty else {
            view?.showError("Enter email")
            return
        }

        guard isValidEmail(email) else {
            view?.showError("Invalid email")
            return
        }

        guard let password = password, !password.isEmpty else {
            view?.showError("Enter password")
            return
        }

        let credentials = UserCredentials(server: server, email: email)
        do {
            try credentialsService.save(credentials: credentials, password: password)
        } catch {
            view?.showError("Cannot save credentials: \(error.localizedDescription)")
            return
        }

        router.navigateToMailComposer(with: credentials)
    }
}
