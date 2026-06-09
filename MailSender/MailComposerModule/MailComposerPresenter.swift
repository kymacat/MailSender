//
//  MailComposerPresenter.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import Foundation

protocol MailComposerPresenterProtocol: AnyObject {
    func changeCredentialsDidTap()
    func send(to: String?, cc: String?, subject: String?, body: String?)
}

final class MailComposerPresenter {
    private weak var view: MailComposerViewProtocol?
    private let router: MailComposerRouterProtocol
    private let credentials: UserCredentials
    private let smtpClient: SMTPClient

    private var sendTask: Task<Void, Never>?

    init(
        view: MailComposerViewProtocol,
        router: MailComposerRouterProtocol,
        credentials: UserCredentials,
        smtpClient: SMTPClient
    ) {
        self.view = view
        self.router = router
        self.credentials = credentials
        self.smtpClient = smtpClient
    }

    deinit {
        sendTask?.cancel()
    }

    private func clearSendTask() {
        sendTask = nil
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
}

extension MailComposerPresenter: MailComposerPresenterProtocol {
    func changeCredentialsDidTap() {
        router.navigateToLogin()
    }

    func send(to: String?, cc: String?, subject: String?, body: String?) {
        guard sendTask == nil else { return }

        guard let to = to?.trimmingCharacters(in: .whitespaces), !to.isEmpty else {
            view?.showError("Enter email")
            return
        }

        guard isValidEmail(to) else {
            view?.showError("Invalid email")
            return
        }

        let cc = cc?.trimmingCharacters(in: .whitespaces).split(separator: ",").map { String($0) } ?? []

        guard let subject = subject?.trimmingCharacters(in: .whitespaces), !subject.isEmpty else {
            view?.showError("Enter subject")
            return
        }

        guard let body = body?.trimmingCharacters(in: .whitespaces), !body.isEmpty else {
            view?.showError("Enter body")
            return
        }

        
        view?.showLoading()
        sendTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard let from = self?.credentials.email else { return }

            do {
                try await self?.smtpClient.send(email: SMTPMail(from: from, to: to, cc: cc, subject: subject, body: body))
                await self?.view?.showSuccess()
            } catch {
                await self?.view?.showError("\(error)")
            }

            await self?.clearSendTask()
            await self?.view?.hideLoading()
        }
    }
}


