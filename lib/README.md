# Texting_App_Using_Flutter
# Flutter Application - Project Overview

This Flutter project implements a chat application with Firebase authentication and Firestore integration. Below is a summary of the main files and their responsibilities in the `lib` directory.

## File Overview

### [main.dart](lib/main.dart)
- **Purpose:** Entry point of the app. Initializes Firebase and sets up routing.
- **Key Features:**  
  - Initializes Firebase with platform-specific options.
  - Sets up routes for login, sign-in, homepage, and settings.
  - Uses `authgate` to determine if the user is logged in.

### [firebase_options.dart](lib/firebase_options.dart)
- **Purpose:** Stores Firebase configuration for different platforms.
- **Key Features:**  
  - Provides `DefaultFirebaseOptions.currentPlatform` for initializing Firebase.

### [loginpage/auth_gate.dart](lib/loginpage/auth_gate.dart)
- **Purpose:** Handles authentication state.
- **Key Features:**  
  - Uses a `StreamBuilder` to listen to authentication changes.
  - Navigates to `Homepage` if logged in, otherwise shows `loginPage`.

### [loginpage/auth_services.dart](lib/loginpage/auth_services.dart)
- **Purpose:** Provides authentication methods.
- **Key Features:**  
  - Methods for signing in and signing up with email/password.
  - Interacts with Firestore to store user data.

### [loginpage/loginpage.dart](lib/loginpage/loginpage.dart)
- **Purpose:** Login screen UI.
- **Key Features:**  
  - Collects user credentials and calls sign-in logic.
  - Navigates to registration if the user is not registered.

### [loginpage/signinpage.dart](lib/loginpage/signinpage.dart)
- **Purpose:** Registration screen UI.
- **Key Features:**  
  - Collects user information for account creation.
  - Calls sign-up logic from `AuthServices`.

### [loginpage/homepage.dart](lib/loginpage/homepage.dart)
- **Purpose:** Main screen after login.
- **Key Features:**  
  - Displays user list and chat options.
  - Integrates with `drawer` for navigation.

### [loginpage/drawer.dart](lib/loginpage/drawer.dart)
- **Purpose:** Navigation drawer.
- **Key Features:**  
  - Provides navigation to Home, Settings, and Logout.
  - Calls sign-out logic from `AuthServices`.

### [loginpage/chatpage.dart](lib/loginpage/chatpage.dart)
- **Purpose:** Chat interface between users.
- **Key Features:**  
  - Displays chat messages.
  - Allows sending new messages via `ChatServices`.

### [loginpage/chat_services.dart](lib/loginpage/chat_services.dart)
- **Purpose:** Handles chat-related Firestore operations.
- **Key Features:**  
  - (Assumed) Methods for sending and receiving messages.

### [loginpage/usertile.dart](lib/loginpage/usertile.dart)
- **Purpose:** UI component for displaying user information in lists.
- **Key Features:**  
  - (Assumed) Used in `Homepage` to show users.

### [loginpage/settings.dart](lib/loginpage/settings.dart)
- **Purpose:** Settings screen.
- **Key Features:**  
  - (Assumed) Allows users to modify app preferences.

---

## How to Run

1. Install dependencies:
   ```sh
   flutter pub get
   ```

   ![image](https://github.com/user-attachments/assets/16f1e445-df12-454c-b929-6afd7940da5f)
   ![image](https://github.com/user-attachments/assets/38b23a14-3ebc-44e4-8c9f-cbd16b7a43d3)
   ![image](https://github.com/user-attachments/assets/241b5a2d-de9f-449f-8aa1-f56d9d73598e)
   ![image](https://github.com/user-attachments/assets/3d4228c8-7ca4-4323-9799-62ff726ee7ac)
   ![image](https://github.com/user-attachments/assets/d536d738-e10b-4169-97a5-5e0488c3dd15)





   
