# Mapbox Android Setup Guide

## Issue: SDK Registry token is null

The Mapbox Maps Flutter package requires a download token to access the Mapbox SDK for Android.

## Solution: Add Mapbox Downloads Token

### Step 1: Get Your Mapbox Downloads Token

1. Go to [Mapbox Account Dashboard](https://account.mapbox.com/)
2. Sign in to your Mapbox account (or create one if you don't have it)
3. Navigate to **Account** → **Tokens** or go directly to [Access Tokens](https://account.mapbox.com/access-tokens/)
4. Click **"Create a token"**
5. Give it a name like "Android SDK Downloads"
6. Under **Token scopes**, make sure **"DOWNLOADS:READ"** is enabled
7. Click **"Create token"**
8. **Copy the token** (you won't be able to see it again!)

### Step 2: Add Token to gradle.properties

1. Open `android/gradle.properties` in your project
2. Find the line: `MAPBOX_DOWNLOADS_TOKEN=YOUR_MAPBOX_DOWNLOADS_TOKEN_HERE`
3. Replace `YOUR_MAPBOX_DOWNLOADS_TOKEN_HERE` with your actual token from Step 1

Example:
```properties
MAPBOX_DOWNLOADS_TOKEN=sk.eyJ1IjoieW91cnVzZXJuYW1lIiwiYSI6ImN...
```

### Step 3: Clean and Rebuild

After adding the token, run:

```bash
flutter clean
flutter pub get
flutter run
```

## Important Notes

- **Downloads Token vs Public Token**: You need a **Downloads token** (with DOWNLOADS:READ scope), not a public access token
- **Keep it Secret**: Never commit your token to version control. Consider adding `gradle.properties` to `.gitignore` if it contains sensitive tokens
- **Token Format**: The token should start with `sk.` (secret key) for downloads tokens

## Alternative: Using local.properties

If you prefer to keep the token in `local.properties` instead (which is typically gitignored), you can:

1. Add to `android/local.properties`:
```properties
MAPBOX_DOWNLOADS_TOKEN=your_token_here
```

2. Update `android/build.gradle.kts` to read from local.properties (if needed)

## Troubleshooting

- **Still getting "token is null" error**: Make sure the token is in `gradle.properties` and you've run `flutter clean`
- **Token not working**: Verify the token has DOWNLOADS:READ scope enabled
- **Build still failing**: Check that the token doesn't have extra spaces or quotes around it

## Security Best Practice

To avoid committing your token to git:

1. Add to `.gitignore`:
```
android/gradle.properties
android/local.properties
```

2. Create `android/gradle.properties.example`:
```properties
MAPBOX_DOWNLOADS_TOKEN=YOUR_MAPBOX_DOWNLOADS_TOKEN_HERE
```

3. Commit the example file, but not the actual one with your token








