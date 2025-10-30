# iOS Capacitor Implementation Guide

Complete step-by-step guide for implementing Google Sign-In in your iOS Capacitor app with the Coach SaaS Platform backend.

---

## Overview

This guide shows you how to:
1. Set up Google Sign-In in your iOS Capacitor app
2. Load the web app with iOS parameter
3. Intercept the Google button click
4. Send the ID token to the backend
5. Handle the JWT response

**Backend URL:** `https://app.my-coach-finder.com`

---

## Prerequisites

- Xcode 14.0+
- iOS 13.0+
- Capacitor 5.0+
- Google Cloud Project with OAuth 2.0 credentials
- Node.js & npm installed

---

## Step 1: Install Dependencies

### Install Capacitor Google Auth Plugin

```bash
npm install @codetrix-studio/capacitor-google-auth
npx cap sync ios
```

### Install Capacitor Core (if not already installed)

```bash
npm install @capacitor/core @capacitor/ios
```

---

## Step 2: Configure Google Cloud Console

### 2.1 Create iOS OAuth Client

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. Navigate to **APIs & Services** > **Credentials**
4. Click **Create Credentials** > **OAuth 2.0 Client ID**
5. Select **iOS** as application type
6. Enter your iOS Bundle ID (e.g., `com.yourcompany.yourapp`)
7. Copy the **Client ID** (format: `XXXXX.apps.googleusercontent.com`)

### 2.2 Get Web Client ID

You also need the **Web Client ID** (used by backend):
1. In the same Credentials page, find your **Web application** client
2. Copy the **Client ID**
3. Share this with your backend team (already configured in your case)

---

## Step 3: Configure iOS Project

### 3.1 Update Info.plist

Open `ios/App/App/Info.plist` and add:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>

<key>GIDClientID</key>
<string>YOUR_IOS_CLIENT_ID.apps.googleusercontent.com</string>

<key>GIDServerClientID</key>
<string>YOUR_WEB_CLIENT_ID.apps.googleusercontent.com</string>
```

**Example:**
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.123456789-abcdefg</string>
        </array>
    </dict>
</array>

<key>GIDClientID</key>
<string>123456789-abcdefg.apps.googleusercontent.com</string>

<key>GIDServerClientID</key>
<string>987654321-xyz.apps.googleusercontent.com</string>
```

### 3.2 Update capacitor.config.ts

```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.yourcompany.yourapp',
  appName: 'Your App Name',
  webDir: 'dist',
  plugins: {
    GoogleAuth: {
      scopes: ['profile', 'email'],
      serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
      iosClientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
      forceCodeForRefreshToken: true,
    }
  }
};

export default config;
```

---

## Step 4: Initialize Google Auth

### 4.1 Create Auth Service

Create `src/services/auth.service.ts`:

```typescript
import { Injectable } from '@angular/core';
import { GoogleAuth } from '@codetrix-studio/capacitor-google-auth';
import { HttpClient } from '@angular/common/http';
import { Capacitor } from '@capacitor/core';

export interface AuthResponse {
  access_token: string;
  token_type: string;
  expires_in: null;
  user: {
    id: string;
    email: string;
    first_name: string;
    last_name: string;
    avatar_url: string;
    current_role: string;
  };
}

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = 'https://app.my-coach-finder.com';

  constructor(private http: HttpClient) {
    this.initialize();
  }

  private initialize() {
    // Initialize Google Auth on iOS
    if (Capacitor.getPlatform() === 'ios') {
      GoogleAuth.initialize({
        clientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
        scopes: ['profile', 'email'],
        grantOfflineAccess: true,
      });
    }
  }

  async signInWithGoogle(): Promise<{ success: boolean; data?: AuthResponse; error?: any }> {
    try {
      // Step 1: Trigger native Google Sign-In
      console.log('Starting Google Sign-In...');
      const googleUser = await GoogleAuth.signIn();

      console.log('Google Sign-In successful:', {
        email: googleUser.email,
        name: googleUser.name,
      });

      // Step 2: Send ID token to backend
      console.log('Sending ID token to backend...');
      const response = await this.http.post<AuthResponse>(
        `${this.apiUrl}/auth/google/native`,
        {
          id_token: googleUser.authentication.idToken,
          os: 'apple' // or 'ios'
        }
      ).toPromise();

      // Step 3: Store JWT token
      console.log('Backend authentication successful');
      localStorage.setItem('token', response.access_token);
      localStorage.setItem('user', JSON.stringify(response.user));

      return {
        success: true,
        data: response
      };
    } catch (error) {
      console.error('Google Sign-In failed:', error);
      return {
        success: false,
        error: error
      };
    }
  }

  async signOut(): Promise<void> {
    try {
      await GoogleAuth.signOut();
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      console.log('Sign out successful');
    } catch (error) {
      console.error('Sign out failed:', error);
    }
  }

  getToken(): string | null {
    return localStorage.getItem('token');
  }

  getUser(): any {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
  }

  isAuthenticated(): boolean {
    return !!this.getToken();
  }
}
```

---

## Step 5: Load Web App in Webview

### Option A: Use In-App Browser (Recommended for Auth)

Create `src/pages/auth/login.page.ts`:

```typescript
import { Component, OnInit } from '@angular/core';
import { Browser } from '@capacitor/browser';
import { App } from '@capacitor/app';
import { AuthService } from '../../services/auth.service';
import { Router } from '@angular/router';

@Component({
  selector: 'app-login',
  template: `
    <ion-content class="ion-padding">
      <div class="login-container">
        <img src="/assets/logo.png" alt="Logo" class="logo">
        <h1>Welcome</h1>

        <!-- Email/Password Login -->
        <ion-button expand="block" (click)="openWebLogin()">
          Login with Email
        </ion-button>

        <!-- Native Google Sign-In -->
        <ion-button expand="block" (click)="signInWithGoogle()" color="light">
          <ion-icon slot="start" name="logo-google"></ion-icon>
          Continue with Google
        </ion-button>
      </div>
    </ion-content>
  `,
  styles: [`
    .login-container {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      height: 100%;
      gap: 1rem;
    }
    .logo {
      width: 120px;
      height: 120px;
      margin-bottom: 2rem;
    }
  `]
})
export class LoginPage implements OnInit {
  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit() {
    // Listen for deep links (if user completes web login)
    App.addListener('appUrlOpen', (event) => {
      console.log('Deep link received:', event.url);
      // Handle token from deep link if needed
    });
  }

  async openWebLogin() {
    // Open web login page for email/password
    await Browser.open({
      url: 'https://app.my-coach-finder.com/auth/login?os=apple',
      presentationStyle: 'fullscreen'
    });

    // Listen for browser close
    Browser.addListener('browserFinished', () => {
      console.log('Browser closed');
      // Check if user is authenticated
      if (this.authService.isAuthenticated()) {
        this.router.navigate(['/dashboard']);
      }
    });
  }

  async signInWithGoogle() {
    const result = await this.authService.signInWithGoogle();

    if (result.success) {
      // Navigate to dashboard based on user role
      const user = result.data?.user;
      const role = user?.current_role || 'coach';

      // You can navigate to your native dashboard
      this.router.navigate([`/${role}/dashboard`]);

      // Or open web dashboard
      // await Browser.open({
      //   url: `https://app.my-coach-finder.com/${role}/dashboard?os=apple`,
      //   presentationStyle: 'fullscreen'
      // });
    } else {
      // Show error
      console.error('Authentication failed');
      alert('Google Sign-In failed. Please try again.');
    }
  }
}
```

### Option B: Inject JavaScript into Webview

If you're loading the web page in a webview and want to intercept the button:

```typescript
import { Component, OnInit } from '@angular/core';
import { InAppBrowser } from '@awesome-cordova-plugins/in-app-browser/ngx';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-webview-login',
  template: `<div id="webview-container"></div>`
})
export class WebviewLoginPage implements OnInit {
  constructor(
    private iab: InAppBrowser,
    private authService: AuthService
  ) {}

  ngOnInit() {
    this.loadWebApp();
  }

  loadWebApp() {
    const browser = this.iab.create(
      'https://app.my-coach-finder.com/auth/login?os=apple',
      '_blank',
      {
        location: 'no',
        toolbar: 'no',
        fullscreen: 'yes'
      }
    );

    // Inject JavaScript to intercept Google button
    browser.on('loadstop').subscribe(() => {
      browser.executeScript({
        code: `
          (function() {
            const googleBtn = document.getElementById('googleAuthBtn');
            if (googleBtn) {
              googleBtn.addEventListener('click', async (e) => {
                e.preventDefault();
                e.stopPropagation();

                // Send message to native app
                window.webkit.messageHandlers.ionicWebView.postMessage({
                  type: 'GOOGLE_AUTH_REQUEST'
                });
              }, true);
            }
          })();
        `
      });
    });

    // Listen for messages from webview
    browser.on('message').subscribe(async (event) => {
      if (event.data.type === 'GOOGLE_AUTH_REQUEST') {
        browser.close();
        const result = await this.authService.signInWithGoogle();

        if (result.success) {
          // Navigate to dashboard
          const role = result.data?.user?.current_role || 'coach';
          browser.create(
            `https://app.my-coach-finder.com/${role}/dashboard?os=apple`,
            '_blank',
            { location: 'no', toolbar: 'no' }
          );
        }
      }
    });
  }
}
```

---

## Step 6: Handle HTTP Interceptor (Optional)

Add JWT token to all API requests:

Create `src/interceptors/auth.interceptor.ts`:

```typescript
import { Injectable } from '@angular/core';
import { HttpInterceptor, HttpRequest, HttpHandler, HttpEvent } from '@angular/common/http';
import { Observable } from 'rxjs';

@Injectable()
export class AuthInterceptor implements HttpInterceptor {
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const token = localStorage.getItem('token');

    if (token) {
      const cloned = req.clone({
        headers: req.headers.set('Authorization', `Bearer ${token}`)
      });
      return next.handle(cloned);
    }

    return next.handle(req);
  }
}
```

Register in `app.module.ts`:

```typescript
import { HTTP_INTERCEPTORS } from '@angular/common/http';
import { AuthInterceptor } from './interceptors/auth.interceptor';

@NgModule({
  providers: [
    {
      provide: HTTP_INTERCEPTORS,
      useClass: AuthInterceptor,
      multi: true
    }
  ]
})
export class AppModule {}
```

---

## Step 7: Testing

### 7.1 Build and Run

```bash
# Build the app
npm run build

# Sync with iOS
npx cap sync ios

# Open in Xcode
npx cap open ios
```

### 7.2 Test in Xcode

1. Select a simulator or device
2. Press **Run** (Cmd + R)
3. Tap "Continue with Google"
4. Sign in with test Google account
5. Verify backend receives token
6. Verify JWT is returned and stored
7. Verify navigation to dashboard

### 7.3 Debug Logs

Check logs in Xcode console:

```
Starting Google Sign-In...
Google Sign-In successful: { email: "test@gmail.com", name: "Test User" }
Sending ID token to backend...
Backend authentication successful
```

---

## Backend API Reference

### Endpoint

```
POST https://app.my-coach-finder.com/auth/google/native
```

### Request

```json
{
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjE4MmU...",
  "os": "apple"
}
```

### Response (Success - 200)

```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "expires_in": null,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "test@gmail.com",
    "first_name": "Test",
    "last_name": "User",
    "avatar_url": "https://lh3.googleusercontent.com/...",
    "current_role": "coach"
  }
}
```

### Response (Error - 401/400/500)

```json
{
  "detail": "Invalid Google ID token: Token expired"
}
```

---

## Troubleshooting

### Issue: "No suitable application records were found"

**Cause:** iOS Client ID not properly configured or Bundle ID mismatch

**Solution:**
1. Verify Bundle ID in Google Cloud Console matches Xcode
2. Regenerate iOS OAuth Client
3. Update Info.plist with new Client ID
4. Clean build folder (Cmd + Shift + K)
5. Rebuild app

### Issue: "The operation couldn't be completed. (com.google.GIDSignIn error -4.)"

**Cause:** URL scheme not properly configured

**Solution:**
1. Check CFBundleURLSchemes in Info.plist
2. Ensure reversed client ID format: `com.googleusercontent.apps.YOUR_CLIENT_ID`
3. Clean and rebuild

### Issue: "Invalid Google ID token" from backend

**Cause:** Token expired or wrong audience

**Solution:**
1. Verify backend has correct Web Client ID configured
2. Ensure `serverClientId` in capacitor.config.ts matches backend
3. Check token expiration (tokens expire in 1 hour)
4. Ensure device time is correct

### Issue: Sign-in works but backend returns 401

**Cause:** Backend not recognizing iOS tokens

**Solution:**
1. Verify backend accepts both iOS and Web client IDs
2. Check backend logs for error details
3. Ensure `os: 'apple'` is sent in request body

### Issue: Button not intercepted in webview

**Cause:** JavaScript injection timing or button not found

**Solution:**
1. Use `loadstop` event before injection
2. Add delay: `setTimeout(() => { /* inject */ }, 500)`
3. Check button ID is `googleAuthBtn`
4. Verify `?os=apple` parameter is in URL

---

## Security Best Practices

### 1. Store Tokens Securely

Instead of localStorage, use Capacitor Secure Storage:

```bash
npm install @capacitor/preferences
```

```typescript
import { Preferences } from '@capacitor/preferences';

// Store token
await Preferences.set({
  key: 'auth_token',
  value: token
});

// Retrieve token
const { value } = await Preferences.get({ key: 'auth_token' });
```

### 2. Validate SSL Certificates

Ensure you're using HTTPS for all API calls.

### 3. Token Refresh

Although current implementation uses non-expiring JWT, implement token refresh for production:

```typescript
async refreshToken() {
  try {
    const googleUser = await GoogleAuth.refresh();
    // Send new token to backend
  } catch (error) {
    // Force re-login
    await this.signOut();
  }
}
```

### 4. Handle Token Expiration

```typescript
intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
  return next.handle(req).pipe(
    catchError((error: HttpErrorResponse) => {
      if (error.status === 401) {
        // Token expired, redirect to login
        this.authService.signOut();
        this.router.navigate(['/login']);
      }
      return throwError(error);
    })
  );
}
```

---

## Complete Example App

### app.module.ts

```typescript
import { NgModule } from '@angular/core';
import { BrowserModule } from '@angular/platform-browser';
import { RouteReuseStrategy } from '@angular/router';
import { HttpClientModule, HTTP_INTERCEPTORS } from '@angular/common/http';

import { IonicModule, IonicRouteStrategy } from '@ionic/angular';
import { AppComponent } from './app.component';
import { AppRoutingModule } from './app-routing.module';
import { AuthInterceptor } from './interceptors/auth.interceptor';

@NgModule({
  declarations: [AppComponent],
  imports: [
    BrowserModule,
    IonicModule.forRoot(),
    AppRoutingModule,
    HttpClientModule
  ],
  providers: [
    { provide: RouteReuseStrategy, useClass: IonicRouteStrategy },
    { provide: HTTP_INTERCEPTORS, useClass: AuthInterceptor, multi: true }
  ],
  bootstrap: [AppComponent],
})
export class AppModule {}
```

### app-routing.module.ts

```typescript
import { NgModule } from '@angular/core';
import { PreloadAllModules, RouterModule, Routes } from '@angular/router';
import { AuthGuard } from './guards/auth.guard';

const routes: Routes = [
  {
    path: '',
    redirectTo: 'login',
    pathMatch: 'full'
  },
  {
    path: 'login',
    loadChildren: () => import('./pages/auth/login/login.module').then(m => m.LoginPageModule)
  },
  {
    path: 'dashboard',
    loadChildren: () => import('./pages/dashboard/dashboard.module').then(m => m.DashboardPageModule),
    canActivate: [AuthGuard]
  }
];

@NgModule({
  imports: [
    RouterModule.forRoot(routes, { preloadingStrategy: PreloadAllModules })
  ],
  exports: [RouterModule]
})
export class AppRoutingModule {}
```

---

## Testing Checklist

- [ ] Google Cloud Console iOS OAuth Client created
- [ ] Bundle ID matches in all configs
- [ ] Info.plist configured with Client IDs and URL scheme
- [ ] capacitor.config.ts has correct serverClientId
- [ ] App builds without errors
- [ ] Google Sign-In button appears
- [ ] Tapping button opens Google consent screen
- [ ] After approval, backend receives ID token
- [ ] Backend returns JWT
- [ ] JWT stored in localStorage/Preferences
- [ ] User navigated to dashboard
- [ ] API requests include Bearer token
- [ ] Sign out clears token

---

## Additional Resources

- [Capacitor Google Auth Plugin](https://github.com/CodetrixStudio/CapacitorGoogleAuth)
- [Google Sign-In iOS Documentation](https://developers.google.com/identity/sign-in/ios/start)
- [Capacitor Documentation](https://capacitorjs.com/docs)
- [Backend API Documentation](./LOGIN_FLOW.md)
- [Mobile Integration Guide](./MOBILE_INTEGRATION.md)

---

## Support

For issues:
1. Check Xcode console for errors
2. Verify all Client IDs are correct
3. Test with `curl` to isolate backend issues:

```bash
curl -X POST https://app.my-coach-finder.com/auth/google/native \
  -H "Content-Type: application/json" \
  -d '{"id_token": "VALID_ID_TOKEN", "os": "apple"}'
```

4. Check backend logs: `sudo journalctl -u fastapi -f`

---

**Last Updated:** 2025-10-30
**Version:** 1.0
**Platform:** iOS (Capacitor)
**Minimum iOS Version:** 13.0
