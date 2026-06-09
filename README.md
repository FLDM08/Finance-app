# Finance-app
An accessible mobile finance manager built with Flutter and Hive NoSQL, specifically designed to promote digital inclusion and financial autonomy for the elderly.

# Accessible Finance App 📱💼

An offline-first, high-accessibility mobile personal finance manager tailored for seniors and individuals seeking a simplified financial tracking tool. This project was developed as an academic extension initiative aiming to bridge the digital divide and foster financial autonomy.
The app itself is in portuguese, but the comments are all in english.

## 🚀 Key Features

- **High Accessibility UI:** Optimized typography (18sp - 36sp), high-contrast elements, and generous touch targets complying with WCAG-inspired principles.
- **Frictionless Onboarding:** Quick-start profile configuration powered by `SharedPreferences`, eliminating the need for complex authentication or credentials.
- **Unified NoSQL Ledger:** Single-stream income and expense management using `Hive` for lightning-fast, binary local persistence.
- **Gesture-Driven UX:** Intuitively dismiss transactions with swipe-to-delete actions supported by real-time `SnackBar` undo operations.
- **Dynamic Data Aggregation:** Real-time data parsing and aggregation that merges identical entries into neat, proportional pie charts via `fl_chart`.

## 🛠️ Tech Stack

- **Framework:** [Flutter](https://flutter.dev) (Dart)
- **Local Database (NoSQL):** [Hive](https://pub.dev/packages/hive) & `hive_flutter`
- **Key-Value Storage:** `shared_preferences`
- **Data Visualization:** [fl_chart](https://pub.dev/packages/fl_chart)

## 🏗️ Architecture & Implementation Details

The core implementation prioritizes privacy and performance by working **100% offline**. 

- Data types are structured under a unified `Transacao` model with a boolean evaluator (`isGasto`) to avoid redundant database schemas.
- Before rendering charts, the system processes raw transaction values using a HashMap-based aggregation logic to prevent visual clutter and guarantee data clarity.
## 💻 Getting Started

### Prerequisites
Make sure you have the Flutter SDK installed and configured on your machine.

### Installation
1. Clone the repository:
```bash
   git clone https://github.com/FLDM08/Finance-app.git
```

2. Navigate to the project directory:
```bash
   cd Finance-app
```

3. Fetch dependencies:
```bash
   flutter pub get
```
   
4. Run code generation for Hive adapters:
```bash
   flutter pub run build_runner build --delete-conflicting-outputs
```
   
5. Launch the application:
```bash
   flutter run
```