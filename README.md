# Dentassure 360 - IT Workforce & SaaS Employee Management

Dentassure 360 is a modern multi-tenant SaaS employee management and workforce attendance platform built with **Flutter** and **Firebase** (Firebase Authentication & Cloud Firestore).

## 🚀 Key Features

- **Multi-Tenant Architecture**: Complete tenant data isolation across organizations.
- **Company & Admin Registration**: Onboard IT companies with automated admin profile setup and Firestore security rules.
- **Employee Management**:
  - Auto-generated Employee IDs (`EMP-001`, `EMP-002`, ...).
  - Department assignments (Software Engineering, DevOps & Cloud, QA, HR, etc.).
  - Role management (`COMPANY_ADMIN`, `MANAGER`, `EMPLOYEE`).
  - Search, filter by department/status, and profile status toggles (Active / Suspended).
- **Attendance & Shift Tracking**:
  - Live digital clock and 1-tap Clock-In / Clock-Out.
  - Automatic Late arrival detection (> 09:30 AM) and Half-Day calculation (< 4 hrs).
  - Admin daily attendance dashboard with date picker and summary metrics.
- **Leave Management & Attendance Synchronization**:
  - Leave categories: Casual, Sick, Annual, Unpaid.
  - Automated leave balance calculation.
  - Admin approval/rejection workflows with review notes.
  - Approved leave automatically reflects as `LEAVE` on the attendance board rather than `ABSENT`.

## 🛠 Tech Stack

- **Frontend**: Flutter (Dart) - Material 3
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore
- **Security**: Granular multi-tenant Firestore Security Rules

## 📦 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.19+)
- [Firebase CLI](https://firebase.google.com/docs/cli) & FlutterFire CLI

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/manikumarsadhu/dentassure_360.git
   cd dentassure_360
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run unit tests & analyze:
   ```bash
   flutter test
   flutter analyze
   ```

4. Run the application:
   ```bash
   flutter run -d chrome
   ```
