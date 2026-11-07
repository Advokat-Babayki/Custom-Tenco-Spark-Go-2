package dev.km4.pocketmode;

import android.app.Application;
import android.content.Intent;
import android.util.Log;

public class PocketApp extends Application {
    private static final String TAG = "Km4PocketMode";

    @Override
    public void onCreate() {
        super.onCreate();
        try {
            startService(new Intent(this, PocketService.class));
        } catch (Exception e) {
            Log.w(TAG, "service start deferred", e);
        }
    }
}
