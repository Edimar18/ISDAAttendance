# ISDAteendance 📱📝

**A Digital Attendance System for ISDA Tignapoloan**

ISDAteendance is a specialized mobile application built to streamline the attendance tracking process for the **ISDA (Iskolar ng Dakbayan)** association of **Barangay Tignapoloan**.

## 📖 Background & Motivation

Every scholar under the City Scholarship Program is required to render **SDP (Scholar Development Program)** or Return Service hours. As the **Chairperson** of the ISDA Tignapoloan association, keeping track of these hours is a critical responsibility. 

We are required to organize activities—ranging from community service to leadership training—and submit proof of attendance to the **CEDO (City Education Office)**. For a long time, we relied on manual paper attendance sheets, which were prone to damage, loss, and tedious data entry. 

**ISDAteendance** solves this by:
*   **Digitizing records:** No more lost papers.
*   **Ensuring Accuracy:** Precise Time In and Time Out recording.
*   **Simplifying Reporting:** One-click CSV export for submission to CEDO.

## ✨ Key Features

*   **📅 Event Management:**
    *   Create, edit, and delete events.
    *   Categorize activities (Leadership, Outreach, Thanksgiving, Community Service, Scholar Meetings, etc.).
    *   Visual indicators for events with recorded attendance.

*   **👥 Participant Database:**
    *   Maintain a local database of all scholars (Name, Course, Year Level).
    *   **Bulk Import:** Easily import scholar lists via CSV to avoid manual entry.
    *   Search and filter capabilities.

*   **⏱️ Real-Time Attendance:**
    *   **Time In:** Quickly search for a scholar and mark them present.
    *   **Time Out:** Record departure times individually or use the **"Time Out All"** feature for simultaneous dismissal.
    *   Status indicators (Active vs. Completed).

*   **📂 Data Export:**
    *   Export attendance records for specific events to **CSV format**.
    *   Files are formatted for easy sharing and submission to CEDO.

*   **🎨 Modern UI:**
    *   Fully designed with a sleek **Dark Theme**.
    *   Consistent and user-friendly interface using Flutter's Material Design.

## 🛠️ Tech Stack

*   **Framework:** [Flutter](https://flutter.dev/)
*   **Language:** [Dart](https://dart.dev/)
*   **Database:** SQLite (via [`sqflite`](https://pub.dev/packages/sqflite)) - *Offline-first architecture*
*   **Key Packages:**
    *   `csv` - For data import/export.
    *   `share_plus` - To share the exported reports.
    *   `file_picker` - For importing participant lists.
    *   `intl` - For date and time formatting.

## 🚀 Getting Started

To run this project locally:

1.  **Prerequisites:** Ensure you have the [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
2.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/isdateendance.git
    cd isdateendance
    ```
3.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```

## 📸 Screenshots

*(Add screenshots of your app here: Events Page, Attendance Page, Add Attendee Modal)*

---

**Developed with ❤️ for the Scholars of Brgy. Tignapoloan.**