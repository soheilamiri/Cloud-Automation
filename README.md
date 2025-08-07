# ☁️ Cloud-Automation

A PowerShell-based toolkit for automating common cloud and on-premises infrastructure tasks, such as server inventory management, reboot status checks, and remote administration — designed to work with Active Directory environments and Windows Server hosts.

---

## 🔧 Features

- ✅ Check if remote Windows servers require a reboot
- 🕒 Fetch system uptime from multiple hosts
- 🔐 Authenticate with Active Directory credentials
- 📦 Use JSON files to manage host inventory
- 🧩 Easily extendable for other remote automation tasks
- 💡 Secure PowerShell Remoting with Kerberos support

---

## 📁 Folder Structure

```bash
cloud-automation/
├── Check-PendingReboot.ps1   # Main script to test reboot requirement
├── inventory.json            # JSON file containing list of target servers
├── README.md                 # You're here
└── .gitignore                # Git ignore rules (optional)
