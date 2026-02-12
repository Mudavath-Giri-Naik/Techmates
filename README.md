# Techmates

Techmates is a centralized mobile application designed to bridge the gap between students and technical opportunities like internships, hackathons, and events.

## Problem
Students and developers often struggle to stay updated with relevant opportunities because they are scattered across multiple platforms. Key issues include:
- **Fragmentation:** Opportunities are hosted on various disparate websites.
- **Missed Deadlines:** lack of timely reminders or "urgency" indicators leads to missed application windows.
- **Tracking Difficulty:** No easy way to separate "Applied" opportunities from those saved for later.

## Solution
Techmates aggregates these opportunities into a single, cohesive feed with powerful tools to manage the application lifecycle.
- **Centralized Feed:** Internships, Hackathons, and Events in one place.
- **Smart Filtering:** Advanced filters for Remote/Hybrid, Stipend, Tech Stack, and more.
- **Lifecycle Management:** Swipe actions to mark items as "Applied" or "Apply Later".
- **Urgency Alerts:** Visual indicators for "Ends Today" or "X days left".

## Tech Stack

### Frontend
- **Framework:** Flutter (Dart)
- **State Management:** Service-based architecture with local `setState` for UI reactivity.
- **UI Components:** Custom widgets (`InternshipCard`, `HackathonCard`, `EventCard`) with optimized rendering.

### Backend & Services
- **Database & Auth:** Supabase (PostgreSQL) for real-time data and secure authentication.
- **Notifications:** Firebase Cloud Messaging (FCM) & `flutter_local_notifications` for push alerts.
- **Local Storage:** `shared_preferences` for persisting user filters and settings.
- **Utilities:** 
  - `flutter_dotenv` for environment management.
  - `url_launcher` for external linking.
  - `cached_network_image` for performant image loading.

### Key Packages
- `supabase_flutter`: Backend connectivity.
- `firebase_messaging`: Push notifications.
- `shared_preferences`: Local data persistence.

## Project Structure
```
lib/
├── models/       # Data definitions (JSON parsing)
├── screens/      # Application pages (Home, Profile)
├── services/     # core logic & Supabase interactions
├── widgets/      # Reusable UI components (Cards, Chips)
└── main.dart     # Entry point & Config
```

## How to Run

1. **Prerequisites**
   - Flutter SDK installed (`flutter doctor`)
   - An Android Emulator or Physical Device

2. **Clone & Install**
   ```bash
   git clone <repository-url>
   cd Techmates
   flutter pub get
   ```

3. **Environment Setup**
   - Create a `.env` file in the root directory.
   - Add your Supabase credentials:
     ```env
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON=your_supabase_anon_key
     ```

4. **Run**
   ```bash
   flutter run
   ```

## Future Plannings

- **AI Recommendations:** Personalized opportunity suggestions based on user skills and behavior.
- **Community Features:** Team-finding chats for Hackathons.
- **Web Support:** Extending the Flutter codebase to deploy a responsive web version.
- **Calendar Integration:** One-tap sync of deadlines to Google/Apple Calendar.
