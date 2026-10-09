cat > README.md << 'EOF'
# 💰 Monefy

A clean, dark-mode personal finance tracker built with Flutter. Track expenses and income, organize spending into groups, set budgets, and visualize your money — all offline, all private.

---

## ✨ Features

### 💵 Track money in and out
- Log **expenses** and **income** with amount, category, date, and description
- Edit or delete any entry with a swipe
- Auto-calculated **net balance**, income, and expense totals per month

### 📅 Month-by-month
- Navigate between months to see historical spending
- Date picker for logging past entries
- Filtered totals per month

### 📁 Groups
- Create groups for trips, projects, or events
- Optional per-group budget
- Category breakdown inside each group
- Separate from your personal tracking

### 📊 Insights
- Category pie chart
- Daily spending bar chart
- Top category & daily average

### 🎯 Budgets
- Set a monthly spending limit
- Status banner at 75% / 90% / 100%
- Snackbar alerts when you cross thresholds

### 📤 Export
- Export to CSV — personal, groups, or both
- Filter by date range and group
- Native share sheet (Save to Files, WhatsApp, Drive, etc.)

### 🌙 Design
- Arctic Blue dark theme
- Custom launcher icon
- Animated splash screen
- Smooth transitions and empty states

---

## 🛠 Tech Stack

- **Flutter** — Material 3, dark theme
- **sqflite** — local SQLite database
- **fl_chart** — pie & bar charts
- **csv** + **share_plus** — data export
- **path_provider** — file storage
- **flutter_launcher_icons** + **flutter_native_splash** — branding

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.5+)
- Android Studio or Xcode
- A connected device or emulator

### Run locally

```bash
git clone https://github.com/Sahil077-UI/Monefy.git
cd Monefy
flutter pub get
flutter run