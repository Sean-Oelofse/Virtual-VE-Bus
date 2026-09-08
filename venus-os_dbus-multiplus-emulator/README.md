## Virtual VE.Bus (dbus-multiplus-emulator) - Emulates a MultiPlus II 48/5000/70-50

<small>GitHub repository: [sean-oelofse/virtual-ve-bus](https://github.com/sean-oelofse/virtual-ve-bus)</small>
<small>Based on the original by [mr-manuel/venus-os_dbus-multiplus-emulator](https://github.com/mr-manuel/venus-os_dbus-multiplus-emulator)</small>

## Index

1. [Disclaimer](#disclaimer)
1. [Purpose](#purpose)
1. [Config](#config)
1. [Feeding values over MQTT](#feeding-values-over-mqtt)
1. [Install / Update](#install--update)
1. [Uninstall](#uninstall)
1. [Restart](#restart)
1. [Debugging](#debugging)
1. [Compatibility](#compatibility)


## Disclaimer

I wrote this script for myself. I'm not responsible, if you damage something using my script.

## Purpose
The script emulates a MultiPlus II in Venus OS. This allows the correct values to be shown in the overview.

## Config
All settings live in `config.ini` (a copy of `config.sample.ini` is created automatically on first install). Edit that file and then restart the driver:

```bash
nano /data/etc/dbus-multiplus-emulator/config.ini
bash /data/etc/dbus-multiplus-emulator/restart.sh
```

> **Note:** earlier versions ignored `config.ini` and only used the hard coded values inside the `.py` file. This version actually reads the config file, so editing it now takes effect.

You can set the phase combination, inverter power, grid frequency/voltage, the dbus service names to read from, and the MQTT input (see below).

### AC consumption while charging / on grid
The AC-out (consumption) power is derived like this:

- If an **AC-load meter** is configured (`dbus_service_name_ac_load`), its readings are used (measured loads minus any PV on the output).
- Otherwise the value is estimated from the physics of the system, per phase: `AC-out = grid_in − battery_charge`. In a multi-phase system the battery (DC) power is split across the phases proportionally to each phase's grid power.

This keeps the consumption correct whether the system is inverting, passing grid through, or **charging the battery from the grid/generator** — which is where the old "consumption goes weird when charging" behaviour came from. Values are also clamped to the inverter's nominal power so a single bad reading can't produce a nonsensical spike.

⚠️ The `AC Loads` value may not exactly match the real value because conversion losses are counted as part of the load.

## Feeding values over MQTT
Instead of running separate `dbus-mqtt-*` drivers, the emulator can read values directly from an MQTT broker. Enable it in `config.ini`:

```ini
mqtt_enabled = True
mqtt_address = 127.0.0.1
mqtt_port = 1883
mqtt_username =
mqtt_password =
mqtt_base_topic = veemu
```

The `paho-mqtt` python package is required and is installed automatically by `install.sh`.

**Topics**

- `veemu/set` — publish a full JSON document to update several values at once:

    ```json
    {
      "battery": {"soc": 80, "power": -1200, "voltage": 52.1},
      "grid": {"power": 300},
      "acload": {"power": 450},
      "pvinverter": {"power": 0}
    }
    ```

- `veemu/set/<group>/<key>` — publish a single value, e.g.:

    ```
    topic  veemu/set/battery/soc     payload  80
    topic  veemu/set/grid/power      payload  300
    topic  veemu/set/grid/L1/power   payload  120
    ```

- `veemu/state` — the emulator publishes the current battery / AC-out / grid-in values here (retained) so you can read them back.

Recognised keys:
- **battery**: `soc`, `power`, `current`, `voltage`, `temperature` (battery `power` is positive when charging)
- **grid / acload / pvinverter**: `power`, `current`, `voltage`, `frequency`, optionally nested under `L1` / `L2` / `L3`

Example with `mosquitto_pub` on the device:

```bash
mosquitto_pub -h 127.0.0.1 -t veemu/set -m '{"battery":{"soc":75,"power":-800},"grid":{"power":200}}'
```

## Install / Update

1. Login to your Venus OS device via SSH. See [Venus OS: Root Access](https://www.victronenergy.com/live/ccgx:root_access#root_access) for more details.

2. Download and run the installer directly from GitHub:

    ```bash
    wget -O /tmp/download_virtual-ve-bus.sh https://raw.githubusercontent.com/sean-oelofse/virtual-ve-bus/main/venus-os_dbus-multiplus-emulator/download.sh

    bash /tmp/download_virtual-ve-bus.sh
    ```

    To install a specific branch instead of `main`, pass it as an argument, e.g.:

    ```bash
    bash /tmp/download_virtual-ve-bus.sh claude/virtual-vebus-mqtt-tyfebu
    ```

### Extra steps for your first installation

3. Edit the config file (phases, MQTT, custom settings):

    ```bash
    nano /data/etc/dbus-multiplus-emulator/config.ini
    ```

    Otherwise, skip this step.

4. Install the driver as a service:

    ```bash
    bash /data/etc/dbus-multiplus-emulator/install.sh
    ```

    The daemon-tools should start this service automatically within seconds.

## Uninstall

Run `/data/etc/dbus-multiplus-emulator/uninstall.sh`

## Restart

Run `/data/etc/dbus-multiplus-emulator/restart.sh`

## Debugging

The service status can be checked with svstat `svstat /service/dbus-multiplus-emulator`

This will output somethink like `/service/dbus-multiplus-emulator: up (pid 5845) 185 seconds`

If the seconds are under 5 then the service crashes and gets restarted all the time. If you do not see anything in the logs you can increase the log level in `/data/etc/dbus-multiplus-emulator/dbus-multiplus-emulator.py` by changing `level=logging.WARNING` to `level=logging.INFO` or `level=logging.DEBUG`

If the script stops with the message `dbus.exceptions.NameExistsException: Bus name already exists: com.victronenergy.grid.mqtt_grid"` it means that the service is still running or another service is using that bus name.

## Compatibility

This software supports the latest three stable versions of Venus OS. It may also work on older versions, but this is not guaranteed.
