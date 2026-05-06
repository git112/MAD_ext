# Context: Smart Event Check-in App (Refined)

## Architecture Overview
This application follows a **Clean Architecture** pattern adapted for Flutter with the **Provider** state management library. It is designed to be **offline-first**, ensuring functionality in remote event locations with limited connectivity.

### Layers
1. **Models**: Plain Data Objects (with Hive annotations). Includes `Event`, `Participant`, and `CheckInLog`.
2. **Services**: 
   - `HiveService`: Centralized, synchronous-oriented local storage access.
   - `SyncService`: Background logic for cloud synchronization (simulated).
   - `QRService`: Parsing and generation of event-specific QR payloads.
3. **Providers (Business Logic)**:
   - `EventProvider`: Manages event lifecycle and "Active Event" selection.
   - `CheckInProvider`: Orchestrates the 4-step validation logic and persistence.
   - `DashboardProvider`: Computes real-time statistics (Live Occupancy, Crowd Status).
4. **UI Layer**: Material 3 screens and modular widgets.

## Key Technical Solutions

### Handling Enums in Hive
Enums like `CheckInMethod` are handled using dedicated `TypeAdapters`. We strictly register these in `main.dart` *before* the boxes are opened to prevent serialization errors.

### Robust Validation Flow
Every check-in undergoes a secondary validation even if the QR code is scanned:
1. **Existence**: Does the ID exist in the database?
2. **Event Belonging**: Is the participant registered for *this specific* event?
3. **Duplicate Prevention**: Have they already checked in?
4. **Capacity Guard**: Is the event full?

### UI State Reliability
All asynchronous UI operations (like check-ins) use `try-catch-finally` blocks to ensure the loading state is cleared, preventing the app from hanging on a "Processing..." indicator if a runtime error occurs.

### Testing Tools
Built-in "Simulation" buttons allow developers to test the full QR flow and manual registration without physical hardware or a camera.
