# Smart Event Check-in & Crowd Management App

A production-ready Flutter application for efficient event entry and crowd monitoring.

## Features
*   **QR-based & Manual Check-in**: High-speed entry system using camera or participant ID.
*   **Crowd Insight**: Real-time occupancy tracking with color-coded safety indicators.
*   **Smart Validation**: Prevents duplicate entries and event cross-contamination.
*   **Offline-First**: Powered by Hive for instantaneous local storage and automatic cloud synchronization.
*   **Testing Simulation**: Built-in tools to test check-in flows without physical hardware.

## Tech Stack
*   **Framework**: Flutter
*   **State Management**: Provider
*   **Local DB**: Hive
*   **Dependencies**: mobile_scanner, qr_flutter, connectivity_plus, uuid, intl

## Setup Instructions
1.  **Clone the Repo**:
    ```bash
    git clone <repo-url>
    cd smart_event_checkin
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run
    ```
