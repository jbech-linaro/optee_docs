.. _rpi3:

==============
Raspberry Pi 3
==============
`Sequitur Labs`_ did the initial OP-TEE port which at the time also came with
modifications in U-Boot, Trusted Firmware A and Linux kernel. Since that initial
port more and more patches have found mainline trees and today the OP-TEE setup
for Raspberry Pi 3 uses only upstream tree's with the exception of Linux kernel.

Disclaimer
^^^^^^^^^^
.. warning::

    This port of Trusted Firmware A and OP-TEE to Raspberry Pi 3 **IS NOT
    SECURE!** Although the Raspberry Pi3 processor provides ARM TrustZone
    exception states, the mechanisms and hardware required to implement secure
    boot, memory, peripherals or other secure functions are not available. Use
    of OP-TEE or TrustZone capabilities within this package **does not result**
    in a secure implementation. This package is provided solely for
    **educational purposes** and **prototyping**.


.. _rpi3_software:

What is expected to work?
^^^^^^^^^^^^^^^^^^^^^^^^^
First, note that all OP-TEE builds have rather simple overall goals:

    - Successfully build OP-TEE for certain devices.
    - Run xtest successfully with no regressions using UART(s).

I.e., it is important to understand that our "OP-TEE builds" shall not be
compared with full Linux distributions which supports "everything". As a couple
of examples, we don't enable any particular drivers in Linux kernel, we don't
include all sorts of daemons, we do not include an X-environment etc. At the
same time this doesn't mean that you cannot use OP-TEE in real environments. It
is usually perfectly fine to run on all sorts of devices, environments etc. It's
just that for the OP-TEE developer configurations we have intentionally stripped
down the environment to make it rather fast to get all the source code, build it
all and run xtest.

We are highlighting this here, since over the years we have had tons of
questions at GitHub about things that people usually find working on their
Raspberry Pi devices when they are using Raspbian (which this is not).

+-----------------+------------+
| Name            | Supported? |
+=================+============+
| Buildroot       | Yes        |
+-----------------+------------+
| HDMI            | No         |
+-----------------+------------+
| NFS             | Yes        |
+-----------------+------------+
| Random packages | Maybe      |
+-----------------+------------+
| Raspbian        | No         |
+-----------------+------------+
| Secure boot     | Maybe      |
+-----------------+------------+
| TFTP            | Yes        |
+-----------------+------------+
| UART            | Yes        |
+-----------------+------------+
| Wi-Fi           | No         |
+-----------------+------------+


.. _rpi3_support_buildroot:

Buildroot
~~~~~~~~~
We are using Buildroot as the tool to create a stripped down filesystem for
Linux where we also put OP-TEE binaries like Trusted Applications, client
libraries and TEE supplicant. If a user want to add/enable additional packages,
then that is also possible by adding new lines in ``common.mk`` in :ref:`build`
(search for ``BR2_PACKAGE_`` to see how it's done).


.. _rpi3_support_hdmi:

HDMI
~~~~
X isn't enabled and we have not built nor enabled any drivers for graphics.


.. _rpi3_support_nfs:

NFS
~~~
Works to boot up a Linux root filesystem, more on that further down.


.. _rpi3_support_random_package:

Random packages
~~~~~~~~~~~~~~~
See the :ref:`rpi3_support_buildroot` section above. You can enable packages
supported by Buildroot, but as mentioned initially in this section, lack of
drivers and other daemons etc might make it impossible to run.


.. _rpi3_support_raspbian:

Raspbian
~~~~~~~~
We are not using it. However, people (from `Sequitur Labs`_) have successfully
been able to add OP-TEE to Raspbian builds. But since we're not using it and
haven't tried, we simply don't support it.


.. _rpi3_support_secure_boot:

Secure boot
~~~~~~~~~~~
First pay attention to the initial warning on this page. I.e., no matter what
you are doing with Raspberry Pi and TrustZone / OP-TEE you **cannot** make it
secure. But that doesn't mean that you cannot "enable" secure features as such
to learn how to build and use those. That knowledge can be transferred and used
on other devices which have all the necessary secure capabilities needed to make
a secure system. We haven't tested to enable secure boot on Raspberry Pi 3. But
we believe that a good starting point would be Trusted Firmware A's
documentation about the "`Authentication Framework`_" and `RPi3 in TF-A`_.


.. _rpi3_support_tftp:

TFTP
~~~~
When you reach U-Boot (see :ref:`rpi3_boot_sequence`), then you can start using
TFTP to load boot firmware etc. For more about TFTP, look at the TFTP section
further down.


.. _rpi3_support_uart:

UART
~~~~
Fully supported, for more details look at the UART section further down.


.. _rpi3_support_wifi:

Wi-Fi
~~~~~
Even though Raspberry Pi 3 has a Wi-Fi chip, we do not support it in our
stripped down builds.


.. _rpi_hardware:

What versions of Raspberry Pi will work?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Below is a table of supported hardware in our setup. We have only used the
Raspberry Pi 3 Model B, i.e., the first RPi 3 device that was released. But we
know that people have successfully been able to use it with both RPi 2's as well
as the newer RPi 3 B+. But as long as we in the `core team`_ doesn't have those
at hands we cannot guarantee anything, therefore we simply say "No" below.

+-------------------------------+------------+
| Hardware                      | Supported? |
+===============================+============+
| Raspberry Pi 1 Model A        | No         |
+-------------------------------+------------+
| Raspberry Pi 1 Model B        | No         |
+-------------------------------+------------+
| Raspberry Pi 1+ Model A       | No         |
+-------------------------------+------------+
| Raspberry Pi 1+ Model B       | No         |
+-------------------------------+------------+
| Raspberry Pi 2 Model B        | No         |
+-------------------------------+------------+
| Raspberry Pi 2 Model B v1.2   | No         |
+-------------------------------+------------+
| Raspberry Pi 3+ Model A       | No         |
+-------------------------------+------------+
| Raspberry Pi 3 Model B        | Yes        |
+-------------------------------+------------+
| Raspberry Pi 3+ Model B       | No         |
+-------------------------------+------------+
| Zero - all versions           | No         |
+-------------------------------+------------+
| Compute module - all versions | No         |
+-------------------------------+------------+


.. _rpi3_boot_sequence:

Boot sequence
^^^^^^^^^^^^^

    - The **GPU** starts executing the first stage bootloader, which is stored
      in ROM on the SoC. The first stage bootloader reads the SD-card, and loads
      the second stage bootloader (``bootcode.bin``) into the L2 cache, and runs
      it.
    - ``bootcode.bin`` enables SDRAM, and reads the third stage bootloader
      ``loader.bin`` from the SD-card into RAM, and runs it.
    - ``loader.bin`` reads the GPU firmware (``start.elf``).
    - ``start.elf`` reads ``config.txt``, pre-loads ``armstub8.bin`` (which
      contains: BL1/TF-A + BL2/TF-A + BL31/TF-A + BL32/OP-TEE + BL33/U-boot) to
      ``0x0`` and jumps to the first instruction.
    - A traditional boot sequence of TF-A -> OP-TEE -> U-boot is performed,
      i.e.,  BL1 loads BL2, then BL2 loads and run BL31(SM), BL32(OP-TEE),
      BL33(U-boot) (one after another)
    - U-Boot runs ``fatload/booti`` sequence  to load from eMMC to RAM both
      ``zImage`` and then ``DTB`` and boot.


.. _rpi3_build_instructions:

Build instructions
^^^^^^^^^^^^^^^^^^
1. Start by following the :ref:`get_and_build_the_solution` as described in
   :ref:`build`, but stop at the ":ref:`build_flash`" step (i.e., **don't** run
   the make flash command!).

2. Next step is to partition and format the memory card and to put the files
   onto the same. That is something we don't want to automate, since if anything
   goes wrong, in worst case it might wipe one of your regular hard disks.
   Instead what we have done, is that we have created another makefile target
   that will tell you exactly what to do. Run that command and follow the
   instructions there.

   .. code-block:: bash

        $ make img-help

   .. note::

       The mention of ``/dev/sdx1`` and ``/dev/sdx2`` when running the command
       above are just examples. You need to figure out and replace that with the
       correct name(s) for your computer and SD-card (typically run ``dmesg``
       and look for the device name matching your SD-card).

3. Put the SD-card back into the Raspberry Pi 3.

4. Plug in the UART cable and attach to the UART

    .. code-block:: bash

        $ picocom -b 115200 /dev/ttyUSB0

    .. note::

        Install picocom if not already installed ``$ sudo apt-get install picocom``.

5. Power up the Raspberry Pi 3 and the system shall start booting which you will
   see on the UART (not :ref:`rpi3_support_hdmi`).

6. When you have a shell, then it's simply just to follow the ":ref:`run_xtest`"
   instructions (eventually you need to load TEE supplicant before being able to
   run xtest, please see ":ref:`build_tee_supplicant`).

.. _rpi3_nfs:

NFS boot
^^^^^^^^
Booting via NFS is quite useful for several reasons, but the obvious reason when
working with Raspberry Pi is that you don't have to move the SD-card back and
forth between the host machine and the Raspberry Pi 3 itself when working with
**Normal World** files, like Linux kernel and user space programs. Here we will
describe how to setup NFS server, so the rootfs can be mounted via NFS.

.. warning::

    This guide doesn't focus on any desktop security, so eventually you would
    need to harden your setup.

In the description below we will use the following terminology, IP addresses and
paths. The reader of this guide is supposed to update this to match his
environment.

.. code-block:: none

    192.168.1.100   <--- This is your desktop computer (NFS server)
    192.168.1.200   <--- This is the Raspberry Pi
    /srv/nfs/rpi    <--- Location for the NFS share


Configure NFS
~~~~~~~~~~~~~
Start by installing the NFS server

.. code-block:: bash

    $ sudo apt-get install nfs-kernel-server

Then edit the exports file,

.. code-block:: bash

    $ sudo vim /etc/exports

In this file you shall tell where your files/folder are and the IP's allowed to
access the files. The way it's written below will make it available to every
machine on the same subnet (again, be careful about security here). Let's add
this line to the file (it's the only line necessary in the file, but if you have
several different filesystems available, then you should of course add them
too, one line for each share).

.. code-block:: none

    /srv/nfs/rpi 192.168.1.0/24(rw,sync,no_root_squash,no_subtree_check)

Next create the folder where you are going to put the root filesystem

.. code-block:: none

    $ sudo mkdir /srv/nfs/rpi

After this, restart the NFS kernel server

.. code-block:: none

    $ service nfs-kernel-server restart

Prepare files to be shared
~~~~~~~~~~~~~~~~~~~~~~~~~~
We are now going to put the root filesystem on the location we prepared in the
previous section.

.. note::

    The path to the ``rootfs.cpio.gz`` refers to <rpi3-project>, replace this so
    it matches your setup.

.. code-block:: bash

    $ cd /srv/nfs/rpi
    $ sudo gunzip -cd <rpi3-project>/out-br/images/rootfs.cpio.gz | sudo cpio -idmv
    $ sudo rm -rf /srv/nfs/rpi/boot/*

uboot.env configuration
~~~~~~~~~~~~~~~~~~~~~~~
The file ``uboot.env`` contains boot configurations that tells what binaries to
load and at what addresses. When using NFS you need to tell U-Boot where the NFS
server is located (IP and path). Since the exact IP and path varies for each
user, we must update ``uboot.env`` accordingly.

There are two ways to update ``uboot.env``, one is to update
``uboot.env.txt`` (in :ref:`build`) and the other is to update directly from
the U-Boot console. Pick the one that you suits your needs. We will cover each
of them separately here.

Edit uboot.env.txt
~~~~~~~~~~~~~~~~~~
In an editor open: ``<rpi3-project>/build/rpi3/firmware/uboot.env.txt`` and
change:

    - ``nfsserverip`` to match the IP address of your NFS server.
    - ``gatewayip`` to the IP address of your router.
    - ``nfspath`` to the exported filesystem in your NFS share.

As an example a section of ``uboot.env.txt`` could look like this:

.. code-block:: c
    :emphasize-lines: 2,4,5

    # NFS/TFTP boot configuraton
    gatewayip=192.168.1.1
    netmask=255.255.255.0
    nfsserverip=192.168.1.100
    nfspath=/srv/nfs/rpi

Next, you need to re-generate ``uboot.env``:

.. code-block:: bash

    $ cd <rpi3-project>/build
    $ make u-boot-env-clean
    $ make u-boot-env

Finally, you need to copy the updated ``<rpi3-project>/out/uboot.env`` to the
**BOOT** partition of your SD-card (mount it as described in
:ref:`rpi3_build_instructions` and then just overwrite (``cp``) the file on the
**BOOT** partition of your SD-card).

Update u-boot.env from U-Boot console
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Boot up the device until you see U-Boot running and counting down, then hit any
key and will see the ``U-Boot>`` prompt. You update the ``nfsserverip``,
``gatewayip`` and ``nfspath`` by writing

.. code-block:: bash

    U-Boot> setenv nfsserverip '192.168.1.100'
    U-Boot> setenv gatewayip '192.168.1.1'
    U-Boot> setenv nfspath '/srv/nfs/rpi'

If you want those environment variables to persist between boots, then type.

.. code-block:: bash

    U-Boot> saveenv


Boot up with NFS
~~~~~~~~~~~~~~~~
With all preparations done correctly above, you should now be able to boot up
the device and kernel, secure side OP-TEE and the entire root filesystem should
be loaded from the network shares (NFS). Power up the Raspberry, halt in U-Boot and
then type.

.. code-block:: bash

    U-Boot> run nfsboot


If everything works, you can simply copy paste files like ``xtest``, Trusted
Applications and other things that usually resides on the file system  directly
from your build folders to the ``/srv/nfs/rpi/...`` folders. By doing so you
don't have to reboot the device when doing development and testing. Just rebuild
and copy is sufficient.

.. note::

    You **cannot** make symlinks in the NFS share to the built files, i.e., you
    must copy them!


.. _rpi3_jtag:

JTAG
^^^^
To enable JTAG you need to add a line saying ``enable_jtag_gpio=1`` in
``<rpi3-project>/firmware/config.txt``.

JTAG cable
~~~~~~~~~~
We have created our own cables, get a standard 20-pin JTAG connector and 22-pin
connector for the Raspberry Pi 3 itself, then using a ribbon cable, connect the
cables according to the table below (JTAG pin <-> Header pin).

+----------+--------+--------+------+------------+
| JTAG pin | Signal | GPIO   | Mode | Header pin |
+==========+========+========+======+============+
| 1        | 3v3    | N/A    | N/A  | 1          |
+----------+--------+--------+------+------------+
| 3        | nTRST  | GPIO22 | ALT4 | 15         |
+----------+--------+--------+------+------------+
| 5        | TDI    | GPIO26 | ALT4 | 37         |
+----------+--------+--------+------+------------+
| 7        | TMS    | GPIO27 | ALT4 | 13         |
+----------+--------+--------+------+------------+
| 9        | TCK    | GPIO25 | ALT4 | 22         |
+----------+--------+--------+------+------------+
| 11       | RTCK   | GPIO23 | ALT4 | 16         |
+----------+--------+--------+------+------------+
| 13       | TDO    | GPIO24 | ALT4 | 18         |
+----------+--------+--------+------+------------+
| 18       | GND    | N/A    | N/A  | 14         |
+----------+--------+--------+------+------------+
| 20       | GND    | N/A    | N/A  | 20         |
+----------+--------+--------+------+------------+

.. warning::

    Be careful and cross check the wiring as incorrect wiring might **damage**
    your device!

Note that this configuration seems to remain in the Raspberry Pi 3 setup we're
using. But someone with root access could change the GPIO configuration at any
point in time and thereby disable JTAG functionality.

UART cable
^^^^^^^^^^
In addition to the JTAG connections we have also wired up the RX/TX to be able
to use the UART. Note, for this you don't need to do JTAG wirings, i.e., it's
perfectly fine to just wire up the UART only. There are many ready made cables
for this on the net (`eBay`_) and cost almost nothing. Get one of those if you
**don't** intend to use JTAG.

+-------------+-------+--------+------+-----------+
| UART pin    | Signal| GPIO   | Mode | Header pin|
+=============+=======+========+======+===========+
| Black (GND) | GND   | N/A    | N/A  | 6         |
+-------------+-------+--------+------+-----------+
| White (RXD) | TXD   | GPIO14 | ALT0 | 8         |
+-------------+-------+--------+------+-----------+
| Green (TXD) | RXD   | GPIO15 | ALT0 | 10        |
+-------------+-------+--------+------+-----------+

.. warning::

    Be careful and cross check the wiring as incorrect wiring might **damage**
    your device!

OpenOCD
^^^^^^^
Build OpenOCD
~~~~~~~~~~~~~
Before building OpenOCD, ``libusb-dev`` package should be installed in advance:

.. code-block:: bash

    $ sudo apt-get install libusb-1.0-0-dev

We are using the `official OpenOCD`_ release, simply clone that to your computer
and then building is like a lot of other software, i.e.,

.. code-block:: bash

    $ git clone http://repo.or.cz/openocd.git && cd openocd
    $ ./bootstrap
    $ ./configure
    $ make

If a JTAG debugger needs legacy ft2332 support, OpenOCD should be configured
accordingly:

.. code-block:: bash

    $ ./configure --enable-legacy-ft2232_libftdi

We leave it up to the reader of this guide to decide if he wants to install it
properly (``make install``) or if he will just run it from the tree directly.
The rest of this guide will just run it from the tree.

OpenOCD RPi3 configuration file
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Unfortunately, the necessary `RPi3 OpenOCD config`_ isn't upstreamed yet into
the `official OpenOCD`_ repository, so you should use the one stored here
``<rpi3-project/build/rpi3/debugger/pi3.cfg``. As you can read there, it's
prepared for four targets, but only one is enabled. The reason for that is
simply because it's a lot simpler to get started with JTAG when running on a
single core. When you have a stable setup using a single core, then you can
start playing with enabling additional cores.

.. code-block:: none

    ...
    target create $_TARGETNAME_0 aarch64 -chain-position $_CHIPNAME.dap -dbgbase 0x80010000 -ctibase 0x80018000
    #target create $_TARGETNAME_1 aarch64 -chain-position $_CHIPNAME.dap -dbgbase 0x80012000 -ctibase 0x80019000
    #target create $_TARGETNAME_2 aarch64 -chain-position $_CHIPNAME.dap -dbgbase 0x80014000 -ctibase 0x8001a000
    #target create $_TARGETNAME_3 aarch64 -chain-position $_CHIPNAME.dap -dbgbase 0x80016000 -ctibase 0x8001b000
    ...

Running OpenOCD
~~~~~~~~~~~~~~~
Depending on the JTAG debugger you are using you'll need to find and use the
interface file for that particular debugger. We've been using `J-Link
debuggers`_ and `Bus Blaster`_ successfully. To start an OpenOCD session using a
J-Link device you type:

.. code-block:: bash

    $ cd <openocd>
    $ ./src/openocd -f ./tcl/interface/jlink.cfg -f <rpi3-project>/build/rpi3/debugger/pi3.cfg

For Bus Blaster type:

.. code-block:: bash

    $ ./src/openocd -f ./tcl/interface/ftdi/dp_busblaster.cfg \ -f <rpi3_repo_dir>/build/rpi3/debugger/pi3.cfg

To be able to write commands to OpenOCD, you simply open up another shell and
type:

.. code-block:: bash

    $ nc localhost 4444

From there you can set breakpoints, examine memory etc ("``> help``" will give
you a list of available commands).

Use GDB
~~~~~~~
The ``pi3.cfg`` file is configured to listen to GDB connections on port
``3333``. So all you have to do in GDB after starting OpenOCD is to connect to
the target on that port, i.e.,

.. code-block:: bash

    # Ensure that you have gdb in your $PATH
    $ aarch64-linux-gnu-gdb -q
    (gdb) target remote localhost:3333

To load symbols you just use the ``symbol-file <path/to/my.elf`` as usual. For
convenience you can create an alias in the ``~/.gdbinit`` file. For TEE core
debugging this works:

.. code-block:: none

    define jlink_rpi3
      target remote localhost:3333
      symbol-file /home/jbech/devel/optee_projects/rpi3/optee_os/out/arm/core/tee.elf
    end

So, when running GDB, you simply type: ``(gdb) jlink_rpi3`` and it will both
connect and load the symbols for TEE core. For Linux kernel and other binaries
you would do the same.

Wrap it all up in a debug session
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
If you have everything prepared, i.e. a working setup for Raspberry Pi 3 and
OP-TEE. You've setup both OpenOCD and GDB according to the instructions, then
you should be good to go. Start by booting up to U-Boot, but stop there. In
there start by disable [SMP] and then continue the boot sequence.

.. code-block:: none

    U-Boot> setenv smp off
    U-Boot> boot

When Linux is up and running, start a new shell where you run OpenOCD:

.. code-block:: bash

    $ cd <openocd>
    $ ./src/openocd -f ./tcl/interface/jlink.cfg -f ./pi3.cfg

Start a third shell, where you run GDB

.. code-block:: bash

    $ aarch64-linux-gnu-gdb -q
    (gdb) target remote localhost:3333
    (gdb) symbol-file <rpi3-project>/optee_os/out/arm/core/tee.elf

Next, try to set a breakpoint, here use **hardware** breakpoints!

**TO-DO** Functions doesn't exist anymore

.. code-block:: bash

    (gdb) hb tee_ta_invoke_command
    Hardware assisted breakpoint 1 at 0x842bf98: file core/kernel/tee_ta_manager.c, line 534.
    (gdb) c
    Continuing.

And if you run tee-supplicant and xtest for example, the breakpoint should
trigger and you will see something like this in the GDB window:

.. code-block:: none

    Breakpoint 1, tee_ta_invoke_command (err=0x84940d4 <stack_thread+7764>,
        err@entry=0x8494104 <stack_thread+7812>, sess=sess@entry=0x847bf20, clnt_id=clnt_id@entry=0x0,
        cancel_req_to=cancel_req_to@entry=0xffffffff, cmd=0x2,
        param=param@entry=0x84940d8 <stack_thread+7768>) at core/kernel/tee_ta_manager.c:534
    534     {

From here you can debug using normal GDB commands.

Known issues when running the JTAG setup
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
As mentioned in the beginning, this is based on forks and etc, so it's a moving
targets. Sometime you will see that you loose the connection between GDB and
OpenOCD. If that happens, simply reconnect to the target. Another thing that you
will notice is that if you're running all on a single core, then Linux kernel
will be a bit upset when continue running after triggering a breakpoint in
secure world (rcu starving messages etc). If you have suggestion and or
improvements, as usual, feel free to contribute.

.. _`Authentication Framework`: https://github.com/ARM-software/arm-trusted-firmware/blob/master/docs/auth-framework.rst
.. _Bus Blaster: http://dangerousprototypes.com/docs/Bus_Blaster
.. _core team: https://github.com/orgs/OP-TEE/teams/linaro/members
.. _eBay: https://www.ebay.com/sch/i.html?&_nkw=UART+cable
.. _J-Link debuggers: https://www.segger.com/jlink_base.html
.. _Linaro rootfs: http://releases.linaro.org/debian/images/installer-arm64/latest/linaro*.tar.gz
.. _official OpenOCD: http://openocd.org
.. _RPi3 in TF-A: https://github.com/ARM-software/arm-trusted-firmware/blob/master/docs/plat/rpi3.rst
.. _RPi3 OpenOCD config: https://github.com/OP-TEE/build/blob/master/rpi3/debugger/pi3.cfg
.. _Sequitur Labs: http://www.sequiturlabs.com
