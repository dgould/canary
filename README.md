# Power Canary


## Overview

This set of scripts makes up a system for monitoring the status of a UPS's
power input, as an alternative to having a smart UPS. That is, it's a way for
a computer to detect a power outage, so it can shut itself down cleanly and
safely before its UPS's battery power runs out.

This system operates in conjunction with a separate hardware device, which is
the "Canary" -- another computer that is running on wall current, _not_ on a
UPS, so it will go down immediately in the event of a power outage.

The monitoring script checks the Canary's health by attempting to `ping` it
every 5 minutes. If that fails some number of times in a row (configurable;
say, 3, which would imply the Canary has been down for 15-20 minutes), it
triggers a shutdown process.

The shutdown process is implemented across a hierarchy of generic and optional
host-specific scripts, allowing appropriate procedures to be defined, such as
cleanly stopping applications and services.

In my initial setup, I'm building this to protect two servers -- one NAS and
one VM host. The NAS server is configured with a longer time threshold before
shutdown (to give clients a chance to disconnect, etc). The VM sever has a
custom shutdown process that suspends the VMs first.


## Code Structure

### Main Canary Script

`canary.sh`

This is the script that is run periodically (once per 5 minutes, via cronjob)
to monitor Canary status. It has two modes of operation:

1. **Normal mode**: run with no arguments, to perform the check
1. **Sick Canary mode**: run with one argument, `--CANARY_SICK`, to remember
a failed check

Sick Canary mode is how the system maintains state: It needs to remember how
many recent checks have failed, so it can detect when the threshold is reached.
The mechanism is simple: When run in this mode, the script simply goes to sleep
for a period equal to the time theshold, then exits. Thus, at any given moment,
the number of failures that have occurred in that time is equal to the number
of such processes running at that moment. The `--CANARY_SICK` argument is a
very dictinctive string, so a Bash script can easily obtain this number, with  
`ps augxww | grep CANARY_SICK | grep -v grep | wc -l`.

In Normal mode, the script:

* attempts to ping the canary, and:
* if successful, logs a success message and exits
* or if unsuccessful, checks for Sick Canaries, logs the number found, and:
* if the threshold is reached, logs this fact and initiates shutdown*
  * by running the shutdown script, which is:
    * the Host-Specific Shutdown Script, if it exists
    * or the Generic Shutdown Script, as a default/fallback
* or if not, logs this fact, creates a Sick Canary*, and exits
  * by running a background command of itself with the `--CANARY_SICK` argument


### Generic Shutdown Script

`canary-shutdown.sh`

This script is the default implementation of the machine shutdown procedure.
It's basically a wrapper of the actual shutdown command, `shutdown -h now`,
plus logging, and the ability to do other stuff first, and/or to dry-run it
for testing purposes, etc.

It will be run directly from the Main Canary Script, if no Host-Specific
Shutdown Script is found. Typically (but not necessarily), it would also be run
from Host-Specific, and/or Type-Specific, Shutdown Scripts after they've done
their special extra stuff.


### Host-Specific Shutdown Scripts

`$HOST-canary-shutdown.sh`

This is a hook for implementing custom shutdown procedures on a per-machine
basis. That is, if this script is present, then when the Main Canary Script
goes to initiate a shutdown, it will do so by running this _instead of_ the
Generic Shutdown Script.

It provides a place to do stuff like gracefully stopping services before the
shutdown. It can do this itself, or by handing off to a Role-Specific Shutdown
Script. 

For example, in my setup, the host `cpu2` is a VirtualBox server, so I want it
to run a script that suspends the VMs. Realizing that this process is common
to VirtualBox servers, I define a `vbox` "role" (below) and make the Host
script `cpu2-canary-shutdown.sh` be just a wrapper that runs
`vbox-canary-shutdown.sh`.


### Role-Specific Shutdown Scripts

`$ROLE-canary-shutdown.sh`

This is a hook for implementing role-based custom shutdown procedures, such as
the above-mentioned example of a `vbox` role for handling VMs on a VirtualBox
server, which I implement in a script named `vbox-canary-shutdown.sh`.


## Hardware Considerations

The Canary device should be:

* Something for which abrupt shutdown by power loss is okay
  * Low/no risk of hardware damage
  * No data, services, etc. that would be harmed
* Able to start back up automatically when power is restored
  * With a quick boot-up cycle
* Stable/reliable (both software and hardware)
* Ideally, dedicated for this purpose
* small, quiet, inexpensive, low-power

These criteria point to something like a Raspberry Pi. In fact, the whole idea
for this system originated with the idea of using a Pi, and the realization of
how simple and inexpensive such a solution could be. (Though the system is not
tied to this platform.)

The physical setup should minimize potential false alarms. For example, the
Canary device should use a wired network connection, not wifi, because a wifi
router can freeze up at any time -- if the server's connection to the Canary
depends on it, that would cause an unnecessary shutdown. Even on the wired
network, the same goes for every switch between the two, etc. If the machines
to be protected have spare NICs, it might be worthwhile to have a separate
switch connecting them in a "CAN" (Canary Area Network). Or, if a Canary is to
protect just a single machine, and it has a spare NIC, they can be connected
directly.

It may be a bit of overkill, but this is exactly my initial setup: Each server
has its own UPS and its own Canary, which is connected directly to the server's
spare NIC, and plugged into one of the UPS's "Surge Protection Only" outlets.



## Roadmap

### Features

* Configuration
  * Make more behavior configurable
  * Good scheme for what goes where
* Well-factored code (shared)
* Improve logging -- clean, consistent, complete
* Install procedure
  * Correct install location, Base + custom
  * Document, make target, script
* Install as system service
  * `start`/`stop`/`status`/`restart`
    * Running/not = auto-shutdown enabled/disabled
    * Check on start, only enable if healthy


### Learning Goals

I'm also using this as an example/learning project, making it an opportunity
for me to do some new things.

Some "firsts for me" that this already represents are:

* Have something on github that others might find at least mildly interesting
* Do something with the Raspberry Pi platform
* Dip deeper into Bash scripting than I have before

Some things I might use it to learn/practice in the future are:

* More elaborate Makefile
* Receive and respond to a Pull Request on github _(...?)_
* Make it operate as a well-behaved system service (?)
  * Properly written, installed, and functioning init script
  * Doing the right things at the right times
    * `start`/`stop`/`status`/`restart`
    * enable/disable its own crontab entry when running/not running?
  * Proper logging: right place, good volume, auto-rotating
* Build it as a well-behaved Linux package (?)
  * `.rpm` and `.deb`
  * Build via Makefile
  * Correct metadata, etc.
  * Install all its parts in the right places
* Run a (private(?)) package repo (?)


## Revision History


### 0.1.0
2019-11-??  
Initial commit
