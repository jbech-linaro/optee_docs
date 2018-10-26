.. _coding_standards:

Coding standards
================

In this project we are trying to adhere to the same coding convention as used
in the Linux kernel (see CodingStyle_). We achieve this by running
checkpatch_ from Linux kernel. However there are a few exceptions that we had
to make since the code also follows GlobalPlatform standards. The exceptions
are as follows:

    - CamelCase for GlobalPlatform types are allowed.
    - And we also exclude checking third party code that we might use in this
      project, such as LibTomCrypt, MPA, newlib (not in this particular git,
      but those are also part of the complete TEE solution, see
      repository-structure_). The reason for excluding and
      not fixing third party code is because we would probably deviate too much
      from upstream and therefore it would be hard to rebase against those
      projects later on and we don't expect that it is easy to convince other
      software projects to change coding style. Automatic variables should
      always be initialized. Mixed declarations and statements are allowed, and
      may be used to avoid assigning useless values. Please leave one blank
      line before and after such declarations.

Regarding the checkpatch tool, it is not included directly into this project.
Please use checkpatch.pl from the Linux kernel git in combination with the
local `checkpatch script`_.

.. _checkpatch script: https://github.com/OP-TEE/optee_os/blob/master/scripts/checkpatch.sh
.. _checkpatch: http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/scripts/checkpatch.pl
.. _CodingStyle: https://www.kernel.org/doc/html/latest/process/coding-style.html
.. _repository-structure: fixme::after-sphinks-updates
