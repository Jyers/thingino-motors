
## Load kernel module before use
ingenic-motor is a command line tool to be able to send commands to the motor.ko camera module. By default this module is not loaded and so it is necessary to enter the following commands:

```
modprobe motor hmaxstep=2540 vmaxstep=720 hst1=52 hst2=53 hst3=57 hst4=51 vst1=59 vst2=61 vst3=62 vst4=63
```

To automate this process during boot, add the line `motor hmaxstep=2540 vmaxstep=720 hst1=52 hst2=53 hst3=57 hst4=51 vst1=59 vst2=61 vst3=62 vst4=63` to `/etc/modules`.

## Module Configuration

- `hstX`: Horizontal motor phase GPIO pins.
- `vstX`: Vertical motor phase GPIO pins.
- `hmaxstep` and `vmaxstep`: Specify the maximum number of steps your hardware can handle.
Note that the maximum steps for the horizontal and vertical motors are passed as arguments when inserting the `motor` module.

### Examples for Wyze Pan Cam v3

1) connect to the camera via ssh
```
ssh root@ip.of.your.camera
```
2) load the kernel module:

check if the motor module is loaded:
```
lsmod
```
if any of them are on the list then unload them first:
```
rmmod motor
```
load the modules with parameters (you may need to experiment with the hmaxstep and vmaxstep values for your specific camera):

```
insmod /path/to/motor.ko hmaxstep=2130 vmaxstep=1600
```

3) testing

By passing the -S command line argument, the current status and x,y parameters will be returned:
```
ingenic-motor -S
```
it will look like this:
```
Max X Steps 2130.
Max Y Steps 1600.
Status Move: 0.
X Steps 1065.
Y Steps 800.
Speed 900.
```
Note: Seems like `900` is the maximum speed of the kernel module, hence why it can't be set further than that value.

### Command line options
```
Usage : ingenic-motor
         -d Direction step.
         -s Speed step (default 900).
         -x X position/step (default 0).
         -y Y position/step (default 0).
         -r two-phase homing (daemon-side), then return to center.
         -j return json string xpos,ypos,status,speed.
         -i return json string for all camera parameters
         -S show status
```

## Examples

* go to mid position of X and Y (assuming max X steps 2130 and max y steps 1600):
```
ingenic-motor -d h -x 1065 -y 800
```
* go to position of begining of X and Y
```
ingenic-motor -d h -x 0 -y 0
```
* go to x 1065 and y 0
```
ingenic-motor -d h -x 1992 -y 0
```
* get camera details as json string
```
ingenic-motor -i
```
* stop the motors
```
ingenic-motor -d s
```
* reset the motors (two-phase homing: half to one side, then full to the opposite; ends centered)
```
ingenic-motor -r
```


## JSON Configuration

The daemon and client read an optional JSON config file at startup from the first existing path:
- /etc/motors.json
- ./motors.json (working directory)

Configuration schema (per-axis parameters):

```
{
  "loglevel": "INFO",            // optional: DEBUG or INFO
  "pan": {                        // X axis
    "max_steps": 2130,            // overrides driver-reported max (optional)
    "home": 1065,                 // custom center position (optional)
    "speed": 900,                 // default/maximum speed for X
    "timeout": 10                 // seconds, used by homing waits
  },
  "tilt": {                       // Y axis
    "max_steps": 1600,
    "home": 800,
    "speed": 900,                 // default/maximum speed for Y
    "timeout": 10                 // seconds, used by homing waits
  }
}
```

Behavior:
- If the file is missing or a field is absent, built-in defaults and driver values are used.
- Homing uses configured max_steps and home (center) when provided; otherwise falls back to driver max and half-range center.
- Homing timeouts use the max of the per-axis `timeout` (in seconds). If not set, defaults are 10s/15s/10s for phases 1/2/center.
- Per-axis speed limits are enforced server-side: effective move speed is clamped to the most restrictive axis speed.
- The client also reads the config and uses the per-axis speed to initialize its default speed. Command-line `-s` overrides the config.

Example config lives well in /etc/motors.json.
