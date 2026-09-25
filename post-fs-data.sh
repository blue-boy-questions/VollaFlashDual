#!/system/bin/sh
# Post-fs-data safety: if the camera HAL crashes on boot with the patched lib,
# the user can create /data/local/tmp/vollaflashdual_disable to force-restore
# the stock library on next boot without needing the KernelSU UI.
BK=/data/local/tmp/vollaflashdual_backup/libcameracustom.flashlight.so.orig
FLAG=/data/local/tmp/vollaflashdual_disable
if [ -f "$FLAG" ] && [ -f "$BK" ]; then
    # Remove our overlay by disabling the module directory.
    touch "${0%/*}/disable"
fi
