.. _fvp:

===
FVP
===

The instructions here will tell how to run OP-TEE using Foundation Models.
Start out by following the :ref:`get_and_build_the_solution` as described in
:ref:`build`. However, before trying to actually run the solution
(:ref:`run_xtest`), you must first obtain the `Armv8-A Foundation Platform (For
Linux Hosts Only)`_ (to download FVPs you’ll need to log in to Arm Self
Service). That binary should be untar'ed to the root of the repo forest. I.e.,
the folder named ``Foundation_Platformpkg`` must be in the root. When this
pre-condition has been done, then you can simply continue with

.. code-block:: bash

    $ make run

and the FVP should build the root fs and then start the simulation and when you
have a termnial you can log in and run xtest.

.. _Armv8-A Foundation Platform (For Linux Hosts Only): https://developer.arm.com/products/system-design/fixed-virtual-platforms
