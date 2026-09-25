#!/system/bin/sh
# Emergency self-disable: if the swapped camera HAL misbehaves, the user can
# create the flag file over ADB and reboot; the module removes its overlay so
# stock vendor libraries are used again.
FLAG=/data/local/tmp/vollaflashdual_disable
if [ -f "$FLAG" ]; then
    touch "${0%/*}/disable"
fi
