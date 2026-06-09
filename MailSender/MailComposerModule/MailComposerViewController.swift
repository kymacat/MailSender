//
//  MailComposerViewController.swift
//  MailSender
//
//  Created by Yandola Vladislav on 05.05.2026.
//

import UIKit

protocol MailComposerViewProtocol: AnyObject {
    func showSuccess()
    func showError(_ message: String)
    func showLoading()
    func hideLoading()
}

final class MailComposerViewController: UIViewController {
    var presenter: MailComposerPresenterProtocol?

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

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "> NEW EMAIL"
        label.font = .monospacedSystemFont(ofSize: 22, weight: .heavy)
        label.textColor = .white
        return label
    }()

    private lazy var toTextField = textField(
        placeholder: "To",
        keyboardType: .emailAddress,
        autocapitalizationType: .none,
        autocorrectionType: .no
    )

    private lazy var ccTextField = textField(
        placeholder: "CC (separate with comma)",
        keyboardType: .emailAddress,
        autocapitalizationType: .none,
        autocorrectionType: .no
    )

    private lazy var subjectTextField = textField(placeholder: "Subject")

    private func textField(
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        autocapitalizationType: UITextAutocapitalizationType = .sentences,
        autocorrectionType: UITextAutocorrectionType = .yes
    ) -> UITextField {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(white: 0.35, alpha: 1)]
        )
        field.borderStyle = .none
        field.keyboardType = keyboardType
        field.autocapitalizationType = autocapitalizationType
        field.autocorrectionType = autocorrectionType
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

    private let bodyTextView: UITextView = {
        let view = UITextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        view.textColor = .white
        view.backgroundColor = UIColor(white: 0.12, alpha: 1)
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor(white: 0.2, alpha: 1).cgColor
        view.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        view.isScrollEnabled = false
        view.heightAnchor.constraint(greaterThanOrEqualToConstant: 180).isActive = true
        return view
    }()

    private let bodyPlaceholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Mail"
        label.font = .monospacedSystemFont(ofSize: 15, weight: .regular)
        label.textColor = UIColor(white: 0.35, alpha: 1)
        return label
    }()

    private let bottomBar: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(red: 14/255, green: 14/255, blue: 18/255, alpha: 1)
        return view
    }()

    private let bottomBorder: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor(white: 0.15, alpha: 1)
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return view
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("> SEND", for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 15, weight: .bold)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        button.heightAnchor.constraint(equalToConstant: 54).isActive = true
        return button
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.color = .black
        view.hidesWhenStopped = true
        return view
    }()

    private let changeCredentialsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("> CHANGE CREDENTIALS", for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        button.setTitleColor(UIColor(white: 0.4, alpha: 1), for: .normal)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupLayout()
        setupActions()

        bodyTextView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        setupKeyboardNotifications()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup

    private func setupView() {
        view.addSubview(backgroundView)
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        stackView.addArrangedSubview(headerLabel)
        stackView.addArrangedSubview(toTextField)
        stackView.addArrangedSubview(ccTextField)
        stackView.addArrangedSubview(subjectTextField)
        stackView.addArrangedSubview(bodyTextView)
        stackView.addArrangedSubview(changeCredentialsButton)

        stackView.setCustomSpacing(28, after: headerLabel)
        stackView.setCustomSpacing(8, after: bodyTextView)

        bodyTextView.addSubview(bodyPlaceholderLabel)

        view.addSubview(bottomBar)
        bottomBar.addSubview(bottomBorder)
        bottomBar.addSubview(sendButton)
        bottomBar.addSubview(loadingIndicator)
    }

    private func setupLayout() {
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),

            bodyPlaceholderLabel.topAnchor.constraint(equalTo: bodyTextView.topAnchor, constant: 14),
            bodyPlaceholderLabel.leadingAnchor.constraint(equalTo: bodyTextView.leadingAnchor, constant: 14),

            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            bottomBorder.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            bottomBorder.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            bottomBorder.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),

            sendButton.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor, constant: 20),
            sendButton.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor, constant: -20),
            sendButton.topAnchor.constraint(equalTo: bottomBar.topAnchor, constant: 10),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),

            loadingIndicator.centerXAnchor.constraint(equalTo: sendButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: sendButton.centerYAnchor),
        ])
    }

    private func setupActions() {
        sendButton.addTarget(self, action: #selector(sendButtonDidTap), for: .touchUpInside)
        changeCredentialsButton.addTarget(
            self,
            action: #selector(changeCredentialsDidTap),
            for: .touchUpInside
        )
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

    // MARK: - Actions

    @objc
    private func sendButtonDidTap() {
        presenter?.send(
            to: toTextField.text,
            cc: ccTextField.text,
            subject: subjectTextField.text,
            body: bodyTextView.text
        )
    }

    @objc
    private func changeCredentialsDidTap() {
        presenter?.changeCredentialsDidTap()
    }

    @objc
    private func keyboardWillShow(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
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

// MARK: - UITextViewDelegate

extension MailComposerViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        bodyPlaceholderLabel.isHidden = !textView.text.isEmpty
    }
}

// MARK: - MailComposerViewProtocol

extension MailComposerViewController: MailComposerViewProtocol {
    func showLoading() {
        sendButton.setTitle("", for: .normal)
        sendButton.isEnabled = false
        loadingIndicator.startAnimating()
    }

    func hideLoading() {
        sendButton.setTitle("> SEND", for: .normal)
        sendButton.isEnabled = true
        loadingIndicator.stopAnimating()
    }

    func showSuccess() {
        let alert = UIAlertController(
            title: "Success",
            message: "Mail was sent successfully",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
