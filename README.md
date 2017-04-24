# badblocks
Scripts I've used to automate work on my dying hard-drive.

It enables running a self-test using `smartctl`, and will automatically check/poll the test status, providing a way to easily delete [with `dd`] (or `shred`) the problematic blocks (or entire file). It is very useful for [Orphaned Files](https://wiki.sleuthkit.org/index.php?title=Orphan_Files) spanning multiple bad sectors, for instance.

Heavily inspired by the guides at https://www.smartmontools.org/wiki/BadBlockHowto.

Disclaimer: This is my first attempt at shell script as well. So, things here can go wrong, and the scripts contained here are provided AS IS and with no warranties of any kind. Use at your own risk.
