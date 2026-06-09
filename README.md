# MailSender

A lightweight iOS SMTP client built from scratch with no external dependencies. The app allows you to send emails directly via SMTP, supporting both SMTPS (port 465) and STARTTLS (port 587).

The project demonstrates how SMTP works under the hood: from opening a TCP socket and performing a TLS handshake to authenticating and submitting a message — all implemented using POSIX sockets and Apple's SecureTransport API.

## Connecting to an SMTP Server

The app works with any SMTP server that supports AUTH LOGIN over TLS. Below is an example using Gmail.

### Gmail Setup

1. Enable 2-Step Verification on your Google account (required for app passwords)
2. Create an App Password at [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
3. Use the generated 16-character password in the app

### App Configuration

| Field    | Value            |
|----------|------------------|
| Server   | `smtp.gmail.com` |
| Email    | your Gmail address |
| Password | app password from step 2 |

The app connects via SMTPS on port 465 by default.

## Features

- SMTPS (implicit TLS on port 465) and STARTTLS (explicit TLS on port 587)
- AUTH LOGIN authentication
- CC recipients support
- UTF-8 subject encoding (Base64)
- Secure password storage via iOS Keychain
- MVP architecture with protocol-based routing

## SMTP Session Flow

```
1. TCP connect to server
2. [SMTPS only] TLS handshake
3. Read 220 greeting
4. EHLO → expect 250
5. [STARTTLS only] STARTTLS → expect 220 → TLS handshake → EHLO again
6. AUTH LOGIN → expect 334 (Username:)
7. Send base64(username) → expect 334 (Password:)
8. Send base64(password) → expect 235
9. MAIL FROM:<...> → expect 250
10. RCPT TO:<...> → expect 250 (for each recipient)
11. DATA → expect 354
12. Send message body + <CRLF>.<CRLF> → expect 250
13. QUIT
```
