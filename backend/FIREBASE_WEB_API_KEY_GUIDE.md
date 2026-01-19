# How to Get Your Firebase Web API Key

## Quick Steps:

1. **Go to Firebase Console**
   - Open: https://console.firebase.google.com/
   - Sign in with your Google account

2. **Select Your Project**
   - Click on your project "transit-live-pro" (or your project name)

3. **Go to Project Settings**
   - Click the gear icon (⚙️) at the top-left sidebar
   - Select "Project Settings"

4. **Find Your Web API Key**
   - Click on the "General" tab
   - Look for the section labeled "Your apps"
   - Or scroll down to find "Web API Key"
   - It should look like this: `AIzaSyD....(long string)`

5. **Add to .env File**
   - Open `backend/.env`
   - Find the line: `FIREBASE_WEB_API_KEY=your-web-api-key`
   - Replace `your-web-api-key` with your actual API key
   - Example: `FIREBASE_WEB_API_KEY=AIzaSyD1234567890abcdefghijklmnop`

6. **Save and Restart Backend**
   - Save the .env file
   - Restart your Node.js server

## What is the Web API Key?

The **Web API Key** is a public key used by your web/mobile app to communicate with Firebase services. It's safe to expose in client code because it's associated with your Firebase security rules.

It enables:
- ✅ User authentication (sign up, login, password reset)
- ✅ Password verification
- ✅ Token generation

## Security Note

The Web API Key is **safe to share** because:
- It's public (not like your private key)
- Firebase security rules protect your data
- It can only perform actions you allow in security rules

**Never share your Private Key** (`firebase-key.json`) - that's sensitive!

## If You Can't Find It

Alternative method:
1. Go to Firebase Console → Project Settings
2. Look for the **WEB SDK SETUP** code snippet
3. In that code, find: `apiKey: "..."`
4. That value is your Web API Key

## Troubleshooting

If you get an error like: `"Server configuration error: Firebase Web API Key not set"`

→ Your `.env` file doesn't have the correct key. Check:
- [ ] Key is actually in `.env` file
- [ ] Server was restarted after adding the key
- [ ] Key is not truncated or incomplete
- [ ] No extra spaces around the key
