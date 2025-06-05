# user-management-bash
A bash-based user management system with registration, login/logout, password reset via email, and user reports.
# User Management System in Bash

A command-line based user management system written in Bash. It simulates user registration, login/logout, password reset via email, and user report generation.

## 🛠 Features

- ✅ User Registration with:
  - Email and password validation
  - Password hashing using SHA256
  - Unique ID generation
  - Confirmation email sent via `msmtp`
- ✅ User Login with:
  - Last login timestamp update
  - Logged-in users list tracking
  - Interactive bash session in user's home directory
- ✅ Logout functionality
- ✅ Password Reset with verification code sent by email
- ✅ Asynchronous report generation:
  - Number of files and folders in user's home directory
  - Total size on disk

## 📁 Project Structure

```bash
.
├── main.sh                   # Main menu script
├── logout.sh                # Logout script
├── utilizatoriConectati.sh  # View logged in users
└── README.md                # Project documentation
```
Requirements
Bash 4
msmtp configured for sending emails
Unix-like enviroment(Linux recomanded)
🚀 How to Run

chmod +x sistemSO.sh
./sistemSO.sh

💡 Notes

    users.csv is used as a database for storing user info.

    loggedUsers.txt keeps track of currently logged-in users.

    Ensure msmtp is properly configured to send emails.

📧 Email Sending

All email notifications are handled via msmtp. You can set up your .msmtprc configuration in the home directory:

defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
account        gmail
host           smtp.gmail.com
port           587
from           your_email@gmail.com
user           your_email@gmail.com
password       your_password
account default : gmail

✉️ Email Configuration (msmtp)

This project uses msmtp to send email notifications (e.g., for password reset or registration confirmation).
🔧 Setup Instructions

To enable email functionality, you must manually configure the .msmtprc file with your own email credentials.

    Create a .msmtprc file in your home directory or project root:

touch ~/.msmtprc
chmod 600 ~/.msmtprc

Example configuration for Gmail:

defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log

account gmail
host smtp.gmail.com
port 587
from your_email@gmail.com
user your_email@gmail.com
password YOUR_APP_PASSWORD

account default : gmail

You must use an App Password if you use Gmail.
Make sure:

    You enable 2-Step Verification (2FA) on your Google account.

    You create an App Password here (choose "Mail" and "Linux").

    Replace YOUR_APP_PASSWORD in the config with the generated app password (not your actual Gmail password!).
