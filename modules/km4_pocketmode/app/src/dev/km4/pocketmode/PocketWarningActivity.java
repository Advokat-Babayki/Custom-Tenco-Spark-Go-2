package dev.km4.pocketmode;

import android.app.Activity;
import android.app.KeyguardManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.view.KeyEvent;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import android.widget.Toast;

public class PocketWarningActivity extends Activity implements SensorEventListener {
    private static final String TAG = "Km4PocketMode";
    private static final long COMBO_HOLD_MS = 1000L;

    static volatile boolean isShowing = false;

    private SensorManager sensorManager;
    private Sensor proximitySensor;
    private KeyguardManager keyguardManager;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private boolean volUp = false;
    private boolean volDown = false;
    private boolean escaped = false;
    private boolean preview = false;

    private final BroadcastReceiver userPresentReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (Intent.ACTION_USER_PRESENT.equals(intent.getAction())) {
                finishAndRemoveTask();
            }
        }
    };

    private final Runnable escapeRunnable = new Runnable() {
        @Override
        public void run() {
            if (volUp && volDown && !escaped) {
                escaped = true;
                PocketService.pausedUntil =
                        SystemClock.elapsedRealtime() + 5 * 60 * 1000L;
                Toast.makeText(PocketWarningActivity.this,
                        R.string.paused, Toast.LENGTH_LONG).show();
                finishAndRemoveTask();
            }
        }
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        preview = getIntent().getBooleanExtra("preview", false);
        keyguardManager = (KeyguardManager) getSystemService(Context.KEYGUARD_SERVICE);
        if (!preview && (keyguardManager == null || !keyguardManager.isKeyguardLocked())) {
            finish();
            return;
        }
        isShowing = true;

        IntentFilter userPresentFilter = new IntentFilter(Intent.ACTION_USER_PRESENT);
        if (Build.VERSION.SDK_INT >= 33) {
            registerReceiver(userPresentReceiver, userPresentFilter,
                    Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(userPresentReceiver, userPresentFilter);
        }

        Window window = getWindow();
        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
        window.setStatusBarColor(0xff000000);
        window.setNavigationBarColor(0xff000000);
        setShowWhenLocked(true);
        setTurnScreenOn(false);
        setContentView(R.layout.activity_warning);
        hideBars();

        sensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        proximitySensor = sensorManager == null
                ? null
                : sensorManager.getDefaultSensor(Sensor.TYPE_PROXIMITY);
        if (proximitySensor == null) {
            finish();
        }
    }

    private void hideBars() {
        Window window = getWindow();
        if (window == null) {
            return;
        }
        WindowInsetsController controller = window.getInsetsController();
        if (controller != null) {
            controller.hide(WindowInsets.Type.statusBars()
                    | WindowInsets.Type.navigationBars());
            controller.setSystemBarsBehavior(
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (!preview && (keyguardManager == null || !keyguardManager.isKeyguardLocked())) {
            finish();
            return;
        }
        isShowing = true;
        hideBars();
        if (proximitySensor != null) {
            sensorManager.registerListener(
                    this, proximitySensor, SensorManager.SENSOR_DELAY_NORMAL);
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (sensorManager != null) {
            sensorManager.unregisterListener(this);
        }
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() != Sensor.TYPE_PROXIMITY) {
            return;
        }
        float max = proximitySensor != null ? proximitySensor.getMaximumRange() : 5f;
        if (!preview && event.values[0] >= max) {
            finish();
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
    }

    @Override
    public boolean dispatchKeyEvent(KeyEvent event) {
        int code = event.getKeyCode();
        if (code == KeyEvent.KEYCODE_VOLUME_UP || code == KeyEvent.KEYCODE_VOLUME_DOWN) {
            if (event.getAction() == KeyEvent.ACTION_DOWN) {
                boolean bothBefore = volUp && volDown;
                if (code == KeyEvent.KEYCODE_VOLUME_UP) {
                    volUp = true;
                } else {
                    volDown = true;
                }
                if (!bothBefore && volUp && volDown && !escaped) {
                    handler.removeCallbacks(escapeRunnable);
                    handler.postDelayed(escapeRunnable, COMBO_HOLD_MS);
                }
            } else if (event.getAction() == KeyEvent.ACTION_UP) {
                if (code == KeyEvent.KEYCODE_VOLUME_UP) {
                    volUp = false;
                } else {
                    volDown = false;
                }
                handler.removeCallbacks(escapeRunnable);
            }
            return true;
        }
        return super.dispatchKeyEvent(event);
    }

    @Override
    public void onBackPressed() {
        // Back must not dismiss the pocket warning.
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            hideBars();
        }
    }

    @Override
    protected void onDestroy() {
        isShowing = false;
        handler.removeCallbacks(escapeRunnable);
        try {
            unregisterReceiver(userPresentReceiver);
        } catch (Exception ignored) {
        }
        super.onDestroy();
    }
}
