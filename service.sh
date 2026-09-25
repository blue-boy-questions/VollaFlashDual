#!/system/bin/sh
# VollaFlashDual v4.0 service.sh - runs late (system booted to a healthy state).
# Reaching this point means we did NOT crash-loop, so clear the boot-fail counter.
# Wait for boot completion first.
until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
done
sleep 5
rm -f /data/local/tmp/vollaflashdual_bootcount
