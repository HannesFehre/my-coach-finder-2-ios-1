package com.mycoachfinder.app;

import android.app.Activity;
import android.content.Intent;
import android.util.Log;
import androidx.activity.result.ActivityResult;
import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.ActivityCallback;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.Task;

@CapacitorPlugin(name = "NativeAuth")
public class NativeAuthPlugin extends Plugin {

    private GoogleSignInClient googleSignInClient;
    private static final String GOOGLE_CLIENT_ID = "353309305721-ir55d3eiiucm5fda67gsn9gscd8eq146.apps.googleusercontent.com";

    @Override
    public void load() {
        // Configure Google Sign-In
        // requestIdToken needs the Web OAuth Client ID (server client ID)
        // The Android OAuth client is automatically detected by package name + SHA-1
        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestIdToken(GOOGLE_CLIENT_ID)  // This should be your WEB client ID from backend
                .requestEmail()
                .requestProfile()
                .build();

        googleSignInClient = GoogleSignIn.getClient(getActivity(), gso);
    }

    @PluginMethod
    public void signInWithGoogle(PluginCall call) {
        Log.d("NativeAuth", "Starting Google Sign-In");

        // Check if already signed in
        GoogleSignInAccount account = GoogleSignIn.getLastSignedInAccount(getActivity());
        if (account != null) {
            Log.d("NativeAuth", "Already signed in: " + account.getEmail());
            // Sign out first to force account picker
            googleSignInClient.signOut().addOnCompleteListener(getActivity(), task -> {
                Log.d("NativeAuth", "Signed out, now launching sign-in");
                Intent signInIntent = googleSignInClient.getSignInIntent();
                startActivityForResult(call, signInIntent, "handleGoogleSignInResult");
            });
        } else {
            Log.d("NativeAuth", "Not signed in, launching sign-in");
            // Launch Google Sign-In intent
            Intent signInIntent = googleSignInClient.getSignInIntent();
            startActivityForResult(call, signInIntent, "handleGoogleSignInResult");
        }
    }

    @ActivityCallback
    private void handleGoogleSignInResult(PluginCall call, ActivityResult result) {
        Log.d("NativeAuth", "Google Sign-In result code: " + result.getResultCode());
        Log.d("NativeAuth", "RESULT_OK value: " + Activity.RESULT_OK);
        Log.d("NativeAuth", "RESULT_CANCELED value: " + Activity.RESULT_CANCELED);

        if (result.getResultCode() == Activity.RESULT_OK) {
            Intent data = result.getData();
            Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);

            try {
                GoogleSignInAccount account = task.getResult(ApiException.class);
                String idToken = account.getIdToken();
                String email = account.getEmail();
                String displayName = account.getDisplayName();
                String photoUrl = account.getPhotoUrl() != null ? account.getPhotoUrl().toString() : null;

                Log.d("NativeAuth", "Sign-In successful: " + email);
                Log.d("NativeAuth", "ID Token present: " + (idToken != null));

                // Return the ID token to JavaScript
                JSObject ret = new JSObject();
                ret.put("idToken", idToken);
                ret.put("email", email);
                ret.put("displayName", displayName);
                ret.put("photoUrl", photoUrl);
                call.resolve(ret);

            } catch (ApiException e) {
                Log.e("NativeAuth", "Sign-In failed with ApiException", e);
                Log.e("NativeAuth", "Status code: " + e.getStatusCode());
                call.reject("Google Sign-In failed: " + e.getStatusCode() + " - " + e.getMessage(), e);
            }
        } else {
            Log.d("NativeAuth", "Sign-In cancelled or failed");
            call.reject("User cancelled sign-in");
        }
    }

    @PluginMethod
    public void signOut(PluginCall call) {
        googleSignInClient.signOut()
            .addOnCompleteListener(getActivity(), task -> {
                JSObject ret = new JSObject();
                ret.put("success", true);
                call.resolve(ret);
            });
    }
}
