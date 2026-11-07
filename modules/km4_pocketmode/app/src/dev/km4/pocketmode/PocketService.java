package dev.km4.pocketmode;

import android.app.KeyguardManager;
import android.app.Service;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Build;
import android.os.IBinder;
import android.os.PowerManager;
import android.os.SystemClock;
import android.util.Log;

public class PocketService extends Service implements SensorEventListener {
    private static final String TAG = "Km4PocketMode";
    private static final long PAUSE_MS = 5 * 60 * 1000L;

    static volatile long pausedUntil = 0L;

    private SensorManager sensorManager;
    private Sensor proximitySensor;
    private boolean listening = false;
    private boolean screenOn = false;

    private final BroadcastReceiver screenReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (Intent.ACTION_SCREEN_ON.equals(action)) {
                screenOn = true;
                startListening();
            } else if (Intent.ACTION_SCREEN_OFF.equals(action)) {
                screenOn = false;
                stopListening();
            }
        }
    };

    @Override
    public void onCreate() {
        super.onCreate();
        sensorManager = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        proximitySensor = sensorManager == null
                ? null
                : sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY);

        IntentFilter filter = new IntentFilter();
        filter.addAction(Intent.ACTION_SCREEN_ON);
        filter.addAction(Intent.ACTION_SCREEN_OFF);
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(screenReceiver, filter);
        }

        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        screenOn = pm != null && pm.isInteractive();
        if (screenOn) {
            startListening();
        }
        Log.i(TAG, "service created screenOn=" + screenOn
                + " sensor=" + (proximitySensor != null));
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        return START_STICKY;
    }

    private void startListening() {
        if (listening || sensorManager == null || proximitySensor == null) {
            return;
        }
        listening = sensorManager.registerListener(
                this, proximitySensor, SensorManager.SENSOR_DELAY_NORMAL);
        Log.i(TAG, "proximity listener registered=" + listening);
    }

    private void stopListening() {
        if (!listening) {
            return;
        }
        sensorManager.unregisterListener(this);
        listening = false;
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() != Sensor.TYPE_PROXIMITY) {
            return;
        }
        float max = proximitySensor != null ? proximitySensor.getMaximumRange() : 5f;
        boolean near = event.values[0] < max;
        Log.i(TAG, "proximity=" + event.values[0] + " near=" + near);
        if (near) {
            maybeShowWarning();
        }
    }

    private void maybeShowWarning() {
        if (!screenOn) {
            return;
        }
        KeyguardManager keyguardManager =
                (KeyguardManager) getSystemService(Context.KEYGUARD_SERVICE);
        if (keyguardManager == null || !keyguardManager.isKeyguardLocked()) {
            return;
        }
        if (SystemClock.elapsedRealtime() < pausedUntil) {
            return;
        }
        if (PocketWarningActivity.isShowing) {
            return;
        }
        Intent intent = new Intent(this, PocketWarningActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK
                | Intent.FLAG_ACTIVITY_NO_ANIMATION
                | Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS);
        try {
            startActivity(intent);
            Log.i(TAG, "warning activity started");
        } catch (Exception e) {
            Log.e(TAG, "failed to start warning activity", e);
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
    }

    @Override
    public void onDestroy() {
        stopListening();
        try {
            unregisterReceiver(screenReceiver);
        } catch (Exception ignored) {
        }
        super.onDestroy();
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
