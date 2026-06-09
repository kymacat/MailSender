//
//  LoginViewController.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import UIKit

protocol LoginViewProtocol: AnyObject {
    func showError(_ message: String)
    func clearErrors()
    func prefillCredentials(server: String, email: String, password: Data)
}

final class LoginViewController: UIViewController {
    var presenter: LoginPresenterProtocol?

    // MARK: - UI Elements

    private let backgroundView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 18/255, green: 18/255, blue: 22/255, alpha: 1)
        return view
    }()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.keyboardDismissMode = .interactive
        return view
    }()

    private let stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 16
        view.alignment = .fill
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "MAIL SENDER"
        label.font = .monospacedSystemFont(ofSize: 34, weight: .heavy)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "SMTP client"
        label.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        label.textColor = UIColor(white: 0.5, alpha: 1)
        label.textAlignment = .center
        return label
    }()

    private lazy var serverTextField = textField(placeholder: "SMTP-server")
    private lazy var emailTextField = textField(placeholder: "Email", keyboardType: .emailAddress)
    private lazy var passwordTextField = textField(placeholder: "Password", isSecure: true)

    private func textField(
        placeholder: String,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default
    ) -> UITextField {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(white: 0.35, alpha: 1)]
        )
        field.borderStyle = .none
        field.keyboardType = keyboardType
        field.isSecureTextEntry = isSecure
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        field.textColor = .white
        field.backgroundColor = UIColor(white: 0.12, alpha: 1)
        field.layer.borderWidth = 2
        field.layer.borderColor = UIColor(white: 0.2, alpha: 1).cgColor
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        field.leftViewMode = .always
        field.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return field
    }

    private let topSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        return view
    }()

    private let bottomSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return view
    }()

    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("> SAVE", for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 15, weight: .bold)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        return button
    }()

    private let errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor(red: 1, green: 0.3, blue: 0.3, alpha: 1)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        setupActions()
        presenter?.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupKeyboardNotifications()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupView() {
        view.addSubview(backgroundView)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(topSpacer)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
        stackView.addArrangedSubview(serverTextField)
        stackView.addArrangedSubview(emailTextField)
        stackView.addArrangedSubview(passwordTextField)
        stackView.addArrangedSubview(errorLabel)
        stackView.addArrangedSubview(saveButton)
        stackView.addArrangedSubview(bottomSpacer)

        stackView.setCustomSpacing(4, after: titleLabel)
        stackView.setCustomSpacing(40, after: subtitleLabel)
        stackView.setCustomSpacing(12, after: passwordTextField)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 28),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -28),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -56),
        ])
    }

    private func setupActions() {
        saveButton.addTarget(self, action: #selector(saveButtonDidTap), for: .touchUpInside)
    }

    private func setupKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    // MARK: - Animations

    private func animateShake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.duration = 0.5
        animation.values = [-10, 10, -8, 8, -4, 4, -2, 2, 0]
        saveButton.layer.add(animation, forKey: "shake")
    }

    // MARK: - Actions

    @objc
    private func saveButtonDidTap() {
        presenter?.saveDidTap(
            server: serverTextField.text,
            email: emailTextField.text,
            password: passwordTextField.text
        )
    }

    @objc
    private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
            return
        }
        let inset = keyboardFrame.height - view.safeAreaInsets.bottom
        scrollView.contentInset.bottom = inset + 20
        scrollView.verticalScrollIndicatorInsets.bottom = inset + 20
    }

    @objc
    private func keyboardWillHide() {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
}

// MARK: - LoginViewProtocol

extension LoginViewController: LoginViewProtocol {
    func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        animateShake()
    }

    func clearErrors() {
        errorLabel.isHidden = true
        errorLabel.text = nil
    }

    func prefillCredentials(server: String, email: String, password: Data) {
        serverTextField.text = server
        emailTextField.text = email
        passwordTextField.text = String(data: password, encoding: .utf8)
    }
}
