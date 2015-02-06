# Myo for Linux

This module is implemented using [noble](https://github.com/sandeepmistry/noble) to connect to Myo,
providing a general interface for accessing Myo. You do not need the Myo dongle to use this but you do
need a working BT 4.0 dongle/device to work. I tested it using my laptop(Lenovo X230) which comes with
BT 4.0 and it works fine.

A Websocket interface is also implemented trying to mimic the behavior of Myo Connect.

# Installation
First, because [noble](https://github.com/sandeepmistry/noble)  is used please look at it's build requirement.
Mainly, you'll need to install `bluetooth, bluez-utils and libbluetooth-dev` packages in your system.

Normally the scanning requires root privileges but you can grant the `hci-ble` binary with permission by using this command
in your project root or in `node_modules/myo4l`:

`find -path '*noble*Release/hci-ble' -exec sudo setcap cap_net_raw+eip '{}' \;`

Otherwise you'll have to run your scripts as root all the time.

# How to use

## Websocket Interface
to setup websocket interface, run the `ws.js` script with your myo device name as argument

```sh
node ws.js Myo
```

the WS interface specification can be found on [Myo Developer Forum](https://developer.thalmic.com/forums/topic/534/?page=1).
I've tested this using [Myo.js](https://github.com/stolksdorf/myo.js) and it works fine but this is still an PoC-level
implementation so feel free to fire bug reports or send PRs.

## API

A simple example to use the library without WS interface can be found in the example folder but you can find almost
all possible usage in `ws.coffee` so it'd be a good place to dig into.

# Disclaimer

I studied the [myo-raw](https://github.com/dzhu/myo-raw) project and dig around the Android-SDK to find out most of
the constants and steps to setup a connection with Myo and I hold no responsibility if using this library damages
your devices in any way.
