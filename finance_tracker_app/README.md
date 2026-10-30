# SpendWise & Card Guard 💳 📱

A modern personal finance & credit card management Android application built with **Flutter**.

## 🌟 Key Features

1. **Income & Expense Tracking**:
   - Log income (Salary, Freelance, Investment, etc.) and everyday cash/bank expenses.
   - Real-time calculation of Total Income, Total Expenses, and Net Balance.
2. **Credit Card Limit & Expense Tracking**:
   - Track one or multiple credit cards.
   - Set Total Credit Limit, current spent balance, and calculate **Real-time Available Limit**.
   - Track **Statement Due Payment Amount** and **Payment Due Date**.
   - "Pay Bill" action to settle dues and automatically update credit limits.
3. **Smart Due Date Alerts & Notifications**:
   - Android notifications alerting you when a credit card payment is due (3 days before, 1 day before, and due date).
   - Visual status badges: *Due in X days*, *Due Today*, *Overdue*, and *Settled*.
4. **Visual Analytics & Credit Health**:
   - Spending breakdown chart by category.
   - Credit card utilization indicator (helps you keep credit usage under 30% for credit score health).
5. **100% Offline & Private**:
   - Powered by a local SQLite database (`spendwise.db`) on your phone. No logins or third-party servers required.

---

## 🚀 How to Build the APK File

You have two easy ways to compile the `.apk` file:

### Option A: 1-Click Cloud Build with GitHub Actions (Recommended — No heavy local install needed!)
1. Create a repository on [GitHub](https://github.com) (can be private or public).
2. Push or upload this project directory to your repository.
3. In GitHub, click on the **Actions** tab.
4. The **Build Android APK** workflow will automatically run (or you can trigger it manually with `Run workflow`).
5. Once completed (~3 minutes), download the **`SpendWise-Release-APK`** zip containing your ready-to-install `app-release.apk` file!
6. Transfer the `.apk` to your Android phone, tap install, and enjoy.

---

### Option B: Local Build on Windows

If you prefer building locally on your PC:
1. **Install Flutter**: Download Flutter SDK from [flutter.dev](https://docs.flutter.dev/get-started/install/windows) and add its `bin` folder to your Windows PATH.
2. **Install Android Studio & SDK**: Download [Android Studio](https://developer.android.com/studio) and install the Android SDK Command-line Tools.
3. Open a terminal in this project folder:
   ```powershell
   flutter pub get
   flutter build apk --release
   ```
4. Your finished APK will be generated at:
   `build\app\outputs\flutter-apk\app-release.apk`

---

## 📂 Project Architecture

```
finance_tracker_app/
├── .github/workflows/
│   └── build_apk.yml           # Automated cloud APK builder
├── android/                    # Android native configuration & permissions
├── lib/
│   ├── main.dart               # App entry point, themes & navigation shell
│   ├── models/
│   │   ├── credit_card.dart    # Credit card model & utilization logic
│   │   └── transaction_item.dart # Transaction data model
│   ├── database/
│   │   └── db_helper.dart      # SQLite local database & aggregations
│   ├── services/
│   │   └── notification_service.dart # Android local notifications & due reminders
│   ├── widgets/
│   │   ├── credit_card_widget.dart # Credit card UI card with chip & limit bar
│   │   ├── summary_card.dart   # Net balance & financial overview
│   │   └── transaction_tile.dart # Dismissible transaction item tile
│   └── screens/
│       ├── home_screen.dart    # Main dashboard & urgent payment banners
│       ├── cards_screen.dart   # Credit card management & manual pay dialog
│       ├── add_transaction_screen.dart # Log income, expense, or card spend
│       ├── add_card_screen.dart # Add/edit credit card & billing parameters
│       └── analytics_screen.dart # Pie charts & utilization analysis
└── pubspec.yaml                # Flutter dependencies
```
