package dev.km4.pocketmode;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.util.Log;

public class BootReceiver extends BroadcastReceiver {
    private static final String TAG = "Km4PocketMode";

    @Override
    public void onReceive(Context context, Intent intent) {
        try {
            context.startService(new Intent(context, PocketService.class));
        } catch (Exception e) {
            Log.w(TAG, "boot service start failed", e);
        }
    }
}
