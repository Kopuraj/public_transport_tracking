# How to Test All Screens

## 🎯 Overview
Your Flutter app has been configured with a **Screen Test Navigator** to easily test all screens.

## ✅ What Was Fixed

### 1. **C++ IntelliSense Errors - RESOLVED**
- Created `.vscode/c_cpp_properties.json` with correct Flutter include paths
- Headers are located at: `windows/flutter/ephemeral/cpp_client_wrapper/include`

### 2. **Firebase Authentication - RESOLVED**
- Added Firebase initialization in `main.dart`
- Created **Mock Authentication Service** (`lib/services/mock_auth_service.dart`)
- Updated `AuthService` to automatically fall back to mock when Firebase is not configured
- Login and SignUp now work with in-memory storage for testing

### 3. **Screen Testing Tool - NEW**
- Created `ScreenTestNavigator` at `lib/screens/screen_test_navigator.dart`
- Added route `/test-navigator` to main.dart
- Added orange "Test Screens" floating button on Welcome Screen

## 🚀 How to Test All Screens

### Method 1: Using the Test Navigator (Recommended)
1. Run the app: `flutter run -d windows`
2. On the Welcome Screen, tap the **orange "Test Screens" button** (bottom right)
3. You'll see a list of ALL screens organized by category:
   - **Authentication & Onboarding** (4 screens)
   - **Main User Screens** (4 screens)
   - **Driver & Staff Screens** (5 screens)
   - **Admin Screens** (4 screens)
4. Tap any button to navigate to that screen
5. Use the back button to return to the test navigator

### Method 2: Manual Navigation
Navigate through the app normally:
1. Welcome → Sign Up → Location Permission → Home
2. From Home, explore other screens

## 📝 Testing Checklist

### ✅ Authentication Screens
- [ ] Welcome Screen - Has "Test Screens" button
- [ ] Login Screen - Test with mock auth
- [ ] Sign Up Screen - Test with mock auth
- [ ] Location Permission Screen

### ✅ Main User Screens
- [ ] Home Screen
- [ ] Commuter Profile Screen
- [ ] Crowd Reporting Screen
- [ ] Route Insights Screen

### ✅ Driver/Staff Screens
- [ ] Driver/Staff Login Screen
- [ ] Trip Initialization Screen
- [ ] Driver Trip Dashboard Screen
- [ ] Emergency Alert Screen
- [ ] Trip Summary Screen

### ✅ Admin Screens
- [ ] Fleet Overview Screen
- [ ] Crowd Analytics Screen
- [ ] Emergency Broadcast Screen
- [ ] Schedule Feedback Screen

## 🧪 Testing Login/SignUp

### Mock Authentication is Active
The app uses in-memory authentication for testing:

**To Sign Up:**
1. Enter any name (e.g., "John Doe")
2. Enter any email (must contain @, e.g., "test@example.com")
3. Enter password (min 6 characters)
4. Check "I agree" checkbox
5. Tap Sign Up

**To Login:**
1. Use the same email/password you used to sign up
2. Tap Login

**Test Credentials:**
Create your own by signing up first, then login with those credentials.

## 📊 All Available Routes

```dart
/welcome              - Welcome Screen
/login                - Login Screen  
/signup               - Sign Up Screen
/location             - Location Permission
/home                 - Home Screen
/commuter-profile     - Commuter Profile
/crowd-reporting      - Crowd Reporting
/route-insights       - Route Insights
/driver-login         - Driver/Staff Login
/trip-initialization  - Trip Initialization
/driver-trip-dashboard - Driver Dashboard
/emergency-alert      - Emergency Alert
/trip-summary         - Trip Summary
/admin-fleet          - Fleet Overview
/admin-crowd-analytics - Crowd Analytics
/admin-broadcast      - Emergency Broadcast
/schedule-feedback    - Schedule Feedback
/test-navigator       - 🧪 Screen Test Tool
```

## 🐛 Debugging Tips

1. **Check Console Output**: Look for messages like:
   - `🎭 Using Mock Authentication (Firebase not configured)`
   - `✅ Mock SignUp successful: email@example.com`
   - `✅ Mock Login successful: email@example.com`

2. **Hot Reload**: Press `r` in terminal for quick code updates

3. **Hot Restart**: Press `R` in terminal to restart app with new code

4. **View Errors**: Check terminal output for any runtime errors

## 📁 Key Files Modified

- `lib/main.dart` - Added Firebase init, test navigator route, floating button
- `lib/services/auth_service.dart` - Added mock auth fallback
- `lib/services/mock_auth_service.dart` - New mock authentication
- `lib/screens/screen_test_navigator.dart` - New test navigator screen
- `.vscode/c_cpp_properties.json` - Fixed C++ IntelliSense

## 🎨 Next Steps

1. Test all screens using the Test Navigator
2. Configure real Firebase if needed (optional)
3. Add more features to screens as needed
4. Connect to backend APIs when ready
