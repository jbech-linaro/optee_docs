Contact
=======

GitHub
^^^^^^
Our preference is to use GitHub for communication. The reason for that is that
it is an open source project, so there should be no real reason to hide
discussions from other people. GitHub also makes it possible for anyone to chime
in into discussion etc. So besides sending patches as pull requests on GitHub we
also encourage people to use the "issues_" to report bugs, give suggestions, ask
questions etc.

Please try to use the "issues" in the relevant git. I.e., if you want to discuss
something related to optee_client, then use "issues" in :ref:`optee_client` and
so on. If you have a general question etc about OP-TEE that doesn't really
belong to a specific git, then please use `issues in optee_os`_ in that case.

Email
^^^^^
You can reach the core team `core team`_ by sending an email to
<op-tee[at]linaro[dot]org>. However note that the team consist of engineers from
different companies, i.e, it **not** just Linaro engineers on that email
address.

From time to time we are also using the "TEE-dev" mailinglist
<tee-dev[at]lists[dot]linaro[dot]org>. It has mostly been used when we have
discussed and sent patches related to the TEE framework in Linux kernel.

For pure Linux kernel patches, please use the appropriate Linux kernel
mailinglist, basically run the ``get_maintainer.pl`` script to know where to
send your patches.

.. code-block:: bash

    $ cd <linux-kernel>
    $ ./scripts/get_maintainer.pl drivers/tee/


IRC
^^^
Some of the OP-TEE developers can be reached at Freenode (``chat.freenode.net``)
at channel ``#linaro-security``. Having that said, the activity there is a bit
limited, so it is probably **not** the best place to discuss OP-TEE.

Vulnerability reporting
^^^^^^^^^^^^^^^^^^^^^^^
Please send an email to the address mentioned above (**not** to TEE-dev). Don't
include any details at this point, just mention that you'd like to report a
security issue. An engineer from the core OP-TEE team will get back to you for
further communication and discussions about your findings.


.. _core team: https://github.com/orgs/OP-TEE/teams/linaro/members
.. _issues: https://help.github.com/articles/about-issues/
.. _issues in optee_os: https://github.com/OP-TEE/optee_os/issues
