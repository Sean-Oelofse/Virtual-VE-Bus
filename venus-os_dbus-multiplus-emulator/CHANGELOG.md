# Changelog

## v1.1.0
* Added: Built-in MQTT client so values (battery, grid, AC-load, PV) can be pushed straight into the emulator without separate dbus-mqtt-* drivers
* Added: Install directly from the GitHub repository (nested-folder aware download.sh, auto-installs paho-mqtt)
* Fixed: `config.ini` is now actually read (was previously ignored; only hard coded values were used)
* Fixed: AC consumption going weird while charging or on grid - AC-out is now estimated from grid + DC + PV when no AC-load meter is present, and clamped to the inverter's nominal power
* Added: Nominal-voltage fallback so per-phase current is still computed when only power is provided

## v1.0.0
* Added: Calculate ratio between phases based on grid and PV inverter
* Added: Config file for more convinient settings changes
* Added: Specify an AC Load Meter to get correct inverter data
* Changed: Fixed wrong calculations
* Changed: Rewrote the whole driver

## v0.1.0
* Added: Support for three phases
* Added: Some fields

## v0.0.3
* Added: Energy sum of power from `Out to Inverter` and `Inverter to Out`
* Added: LED display
* Added: Units to the values

## v0.0.2
* Added: Get automatically the grid and battery meter, if there is only one
* Added: Select on which phase the PV Inverter is connected to
* Changed: Fixed caluclations for AC-Out

## v0.0.1
Initial release
