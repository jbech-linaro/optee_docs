.. _core:

Core
====

.. _interrupt_handling:

Interrupt handling
^^^^^^^^^^^^^^^^^^

.. _memory_objects:

Memory objects
^^^^^^^^^^^^^^
A memory object, **MOBJ**, describes a piece of memory. The interface provided
is mostly abstract when it comes to using the MOBJ to populate translation
tables etc. There are different kinds of MOBJs describing:

    - Physically contiguous memory
        - created with ``mobj_phys_alloc()``.
    - Virtual memory
        - one instance with the name ``mobj_virt`` available.
        - spans the entire virtual address space.
    - Physically contiguous memory allocated from a ``tee_mm_pool_t *``
        - created with ``mobj_mm_alloc()``.
    - Paged memory
        - created with ``mobj_paged_alloc()``.
        - only contains the supplied size and makes ``mobj_is_paged()`` return
          true if supplied as argument.
    - Secure copy paged shared memory
        - created with ``mobj_seccpy_shm_alloc()``.
        - makes ``mobj_is_paged()`` and ``mobj_is_secure()`` return true if
          supplied as argument.

.. _mmu:

MMU
^^^

Translation tables
~~~~~~~~~~~~~~~~~~
OP-TEE uses several L1 translation tables, one large spanning 4 GiB and two or
more small tables spanning 32 MiB. The large translation table handles kernel
mode mapping and matches all addresses not covered by the small translation
tables. The small translation tables are assigned per thread and covers the
mapping of the virtual memory space for one TA context.

Memory space between small and large translation table is configured by TTBRC.
TTBR1 always points to the large translation table. TTBR0 points to the a small
translation table when user mapping is active and to the large translation table
when no user mapping is currently active. For details about registers etc,
please refer to a Technical Reference Manual for your architecture, for example
`Cortex-A53 TRM`_.

The translation tables has certain alignment constraints, the alignment (of the
physical address) has to be the same as the size of the translation table. The
translation tables are statically allocated to avoid fragmentation of memory due
to the alignment constraints.

Each thread has one small L1 translation table of its own. Each TA context has a
compact representation of its L1 translation table. The compact representation
is used to initialize the thread specific L1 translation table when the TA
context is activated.

.. image:: ../images/core/xlat_table.png

Switching to user mode
~~~~~~~~~~~~~~~~~~~~~~
This section only applies with following configuration flags:

    - ``CFG_WITH_LPAE=n``
    - ``CFG_CORE_UNMAP_CORE_AT_EL0=y``

When switching to user mode only a minimal kernel mode mapping is kept. This is
achieved by selecting a zeroed out big L1 translation in TTBR1 when
transitioning to user mode. When returning back to kernel mode the original L1
translation table is restored in TTBR1.

Switching to normal world
~~~~~~~~~~~~~~~~~~~~~~~~~
When switching to normal world either via a foreign interrupt or RPC there is a
chance that secure world will resume execution on a different CPU. This means
that the new CPU need to be configured with the context of the currently active
TA. This is solved by always setting the TA context in the CPU when resuming
execution. Here is room for improvements since it is more likely than not that
it is the same CPU that resumes execution in secure world.

.. _pager:

Pager
^^^^^
OP-TEE currently requires ~256 KiB RAM for OP-TEE kernel memory. This is not a
problem if OP-TEE uses TrustZone protected DDR, but for security reasons OP-TEE
may need to use TrustZone protected SRAM instead. The amount of available SRAM
varies between platforms, from just a few KiB up to over 512 KiB. Platforms with
just a few KiB of SRAM cannot be expected to be able to run a complete TEE
solution in SRAM. But those with 128 to 256 KiB of SRAM can be expected to have
a capable TEE solution in SRAM. The pager provides a solution to this by demand
paging parts of OP-TEE using virtual memory.

Secure memory
~~~~~~~~~~~~~
TrustZone protected SRAM is generally considered more secure than TrustZone
protected DRAM as there is usually more attack vectors on DRAM. The attack
vectors are hardware dependent and can be different for different platforms.

Backing store
~~~~~~~~~~~~~
TrustZone protected DRAM or in some cases non-secure DRAM is used as backing
store. The data in the backing store is integrity protected with one hash
(SHA-256) per page (4KiB). Readonly pages are not encrypted since the OP-TEE
binary itself is not encrypted.

Partitioning of memory
~~~~~~~~~~~~~~~~~~~~~~
The code that handles demand paging must always be available as it would
otherwise lead to deadlock. The virtual memory is partitioned as:

.. code-block:: none

      Type      Sections
    +--------------+-----------------+
    |              | text            |
    |              | rodata          |
    |              | data            |
    | unpaged      | bss             |
    |              | heap1           |
    |              | nozi            |
    |              | heap2           |
    +--------------+-----------------+
    | init / paged | text_init       |
    |              | rodata_init     |
    +------------- +-----------------+
    | paged        | text_pageable   |
    |              | rodata_pageable |
    +--------------+-----------------+
    | demand alloc |                 |
    |              |                 |
    +--------------+-----------------+

Where ``nozi`` stands for "not zero initialized", this section contains entry
stacks (thread stack when TEE pager is not enabled) and translation tables (TEE
pager cached translation table when the pager is enabled and LPAE MMU is used).

The ``init`` area is available when OP-TEE is initializing and contains
everything that is needed to initialize the pager. After the pager has been
initialized this area will be used for demand paged instead.

The ``demand alloc`` area is a special area where the pages are allocated and
removed from the pager on demand. Those pages are returned when OP-TEE does not
need them any longer. The thread stacks currently belongs this area. This means
that when a stack is not used the physical pages can be used by the pager for
better performance.

The technique to gather code in the different area is based on compiling all
functions and data into separate sections. The unpaged text and rodata is then
gathered by linking all object files with ``--gc-sections`` to eliminate
sections that are outside the dependency graph of the entry functions for
unpaged functions. A script analyzes this ELF file and generates the bits of the
final link script. The process is repeated for init text and rodata. What is
not "unpaged" or "init" becomes "paged".

Partitioning of the binary
~~~~~~~~~~~~~~~~~~~~~~~~~~
The binary is partitioned into four parts as:

.. code-block:: none

    +----------+
    | Header   |
    +----------+
    | Init     |
    +----------+
    | Hashes   |
    +----------+
    | Pageable |
    +----------+

The header is defined as:

.. code-block:: c

    #define OPTEE_MAGIC             0x4554504f
    #define OPTEE_VERSION           1
    #define OPTEE_ARCH_ARM32        0
    #define OPTEE_ARCH_ARM64        1

    struct optee_header {
            uint32_t magic;
            uint8_t version;
            uint8_t arch;
            uint16_t flags;
            uint32_t init_size;
            uint32_t init_load_addr_hi;
            uint32_t init_load_addr_lo;
            uint32_t init_mem_usage;
            uint32_t paged_size;
    };

The header is only used by the loader of OP-TEE, not OP-TEE itself. To
initialize OP-TEE the loader loads the complete binary into memory and copies
what follows the header and the following ``init_size`` bytes to
``(init_load_addr_hi << 32 | init_load_addr_lo)``. ``init_mem_usage`` is used by
the loader to be able to check that there is enough physical memory available
for OP-TEE to be able to initialize at all. The loader supplies in ``r0/x0`` the
address of the first byte following what was not copied and jumps to the load
address to start OP-TEE.

In addition to overall binary with partitions inside described as above, extra
three binaries are generated simultaneously during build process for loaders who
support loading separate binaries:

.. code-block:: none

    +----------+
    | Header   |
    +----------+

    +----------+
    | Init     |
    +----------+
    | Hashes   |
    +----------+

    +----------+
    | Pageable |
    +----------+

In this case, loaders load header binary first to get image list and information
of each image; and then load each of them into specific load address assigned in
structure. These binaries are named with v2 suffix to distinguish from the
existing binaries. Header format is updated to help loaders loading binaries
efficiently:

.. code-block:: c

    #define OPTEE_IMAGE_ID_PAGER    0
    #define OPTEE_IMAGE_ID_PAGED    1

    struct optee_image {
            uint32_t load_addr_hi;
            uint32_t load_addr_lo;
            uint32_t image_id;
            uint32_t size;
    };

    struct optee_header_v2 {
            uint32_t magic;
            uint8_t version;
            uint8_t arch;
            uint16_t flags;
            uint32_t nb_images;
            struct optee_image optee_image[];
    };

Magic number and architecture are identical as original. Version is increased to
two. ``load_addr_hi`` and ``load_addr_lo`` may be ``0xFFFFFFFF`` for pageable
binary since pageable part may get loaded by loader into dynamic available
position. ``image_id`` indicates how loader handles current binary. Loaders who
don't support separate loading just ignore all v2 binaries.

Initializing the pager
~~~~~~~~~~~~~~~~~~~~~~
The pager is initialized as early as possible during boot in order to minimize
the "init" area. The global variable ``tee_mm_vcore`` describes the virtual
memory range that is covered by the level 2 translation table supplied to
``tee_pager_init()``.

**Assign pageable areas**

A virtual memory range to be handled by the pager is registered with a call to
``tee_pager_add_core_area()``.

.. code-block:: c

    bool tee_pager_add_area(tee_mm_entry_t *mm,
                            uint32_t flags,
                            const void *store,
                            const void *hashes);

which takes a pointer to ``tee_mm_entry_t`` to tell the range, flags to tell how
memory should be mapped (readonly, execute etc), and pointers to backing store
and hashes of the pages.

**Assign physical pages**

Physical SRAM pages are supplied by calling ``tee_pager_add_pages()``

.. code-block:: c

    void tee_pager_add_pages(tee_vaddr_t vaddr,
                             size_t npages,
                             bool unmap);

``tee_pager_add_pages()`` takes the physical address stored in the entry mapping
the virtual address "vaddr" and "npages" entries after that and uses it to map
new pages when needed. The unmap parameter tells whether the pages should be
unmapped immediately since they does not contain initialized data or be kept
mapped until they need to be recycled. The pages in the "init" area are supplied
with ``unmap == false`` since those page have valid content and are in use.

Invocation
~~~~~~~~~~
The pager is invoked as part of the abort handler. A pool of physical pages are
used to map different virtual addresses. When a new virtual address needs to be
mapped a free physical page is mapped at the new address, if a free physical
page cannot be found the oldest physical page is selected instead. When the page
is mapped new data is copied from backing store and the hash of the page is
verified. If it is OK the pager returns from the exception to resume the
execution.

Paging of user TA
~~~~~~~~~~~~~~~~~
Paging of user TAs can optionally be enabled with ``CFG_PAGED_USER_TA=y``.
Paging of user TAs is analogous to paging of OP-TEE kernel parts but with a few
differences:

    - Read/write pages are paged in addition to read-only pages
    - Page tables are managed dynamically

``tee_pager_add_uta_area()`` is used to setup initial read/write mapping needed
when populating the TA. When the TA is fully populated and relocated
``tee_pager_set_uta_area_attr()`` changes the mapping of the area to strict
permissions used when the TA is running.


.. _stacks:

Stacks
^^^^^^
Different stacks are used during different stages. The stacks are:

    - **Secure monitor stack** (128 bytes), bound to the CPU. Only available if
      OP-TEE is compiled with a secure monitor always the case if the target is
      Armv7-A but never for Armv8-A.
    - **Temp stack** (small ~1KB), bound to the CPU. Used when transitioning
      from one state to another. Interrupts are always disabled when using this
      stack, aborts are fatal when using the temp stack.
    - **Abort stack** (medium ~2KB), bound to the CPU. Used when trapping a data
      or pre-fetch abort. Aborts from user space are never fatal the TA is only
      killed. Aborts from kernel mode are used by the pager to do the demand
      paging, if pager is disabled all kernel mode aborts are fatal.
    - **Thread stack** (large ~8KB), not bound to the CPU instead used by the
      current thread/task. Interrupts are usually enabled when using this stack.

**Notes for Armv7-A/AArch32:**

.. list-table:: Armv7-A / AArch32
    :header-rows: 1

    * - Stack
      - Comment

    * - Temp
      - Assigned to ``SP_SVC`` during entry/exit, always assigned to ``SP_IRQ`` and ``SP_FIQ``

    * - Abort
      - Always assigned to ``SP_ABT``

    * - Thread
      - Assigned to ``SP_SVC`` while a thread is active

**Notes for AArch64:**

There are only two stack pointers, ``SP_EL1`` and ``SP_EL0``, available for
OP-TEE in AArch64. When an exception is received stack pointer is always
``SP_EL1`` which is used temporarily while assigning an appropriate stack
pointer for ``SP_EL0``. ``SP_EL1`` is always assigned the value of
``thread_core_local[cpu_id]``. This structure has some spare space for temporary
storage of registers and also keeps the relevant stack pointers. In general when
we talk about assigning a stack pointer to the CPU below we mean ``SP_EL0``.

Boot
~~~~
During early boot the CPU is configured with the temp stack which is used until
OP-TEE exits to normal world the first time.

**Notes for AArch64:**

``SPSEL`` is always ``0`` on entry/exit to have ``SP_EL0`` acting as stack
pointer.

Normal entry
~~~~~~~~~~~~
Each time OP-TEE is entered from normal world the temp stack is used as the
initial stack. For fast calls this is the only stack used. For normal calls an
empty thread slot is selected and the CPU switches to that stack.

Normal exit
~~~~~~~~~~~
Normal exit occurs when a thread has finished its task and the thread is freed.
When the main thread function, ``tee_entry_std()``, returns interrupts are
disabled and the CPU switches to the temp stack instead. The thread is freed and
OP-TEE exits to normal world.

RPC exit
~~~~~~~~
RPC exit occurs when OP-TEE need some service from normal world. RPC can
currently only be performed with a thread is in running state. RPC is initiated
with a call to ``thread_rpc()`` which saves the state in a way that when the
thread is restored it will continue at the next instruction as if this function
did a normal return. CPU switches to use the temp stack before returning to
normal world.

Foreign interrupt exit
~~~~~~~~~~~~~~~~~~~~~~
Foreign interrupt exit occurs when OP-TEE receives a foreign interrupt. For Arm
GICv2 mode, foreign interrupt is sent as IRQ which is always handled in normal
world. Foreign interrupt exit is similar to RPC exit but it is
``thread_irq_handler()`` and ``elx_irq()`` (respectively for Armv7-A/Aarch32 and
for Aarch64) that saves the thread state instead. The thread is resumed in the
same way though. For Arm GICv3 mode, foreign interrupt is sent as FIQ which
could be handled by either secure world (EL3 in AArch64) or normal world. This
mode is not supported yet.

**Notes for Armv7-A/AArch32:**

SP_IRQ is initialized to temp stack instead of a separate stack.  Prior to
exiting to normal world CPU state is changed to SVC and temp stack is selected.

**Notes for AArch64:**

``SP_EL0`` is assigned temp stack and is selected during IRQ processing. The
original ``SP_EL0`` is saved in the thread context to be restored when resuming.

Resume entry
~~~~~~~~~~~~
OP-TEE is entered using the temp stack in the same way as for normal entry. The
thread to resume is looked up and the state is restored to resume execution. The
procedure to resume from an RPC exit or an foreign interrupt exit is exactly the
same.

Syscall
~~~~~~~
Syscalls are executed using the thread stack.

**Notes for Armv7-A/AArch32:**

Nothing special ``SP_SVC`` is already set with thread stack.

**Notes for syscall AArch64:**

Early in the exception processing the original ``SP_EL0`` is saved in ``struct
thread_svc_regs`` in case the TA is executed in AArch64. Current thread stack is
assigned to ``SP_EL0`` which is then selected. When returning ``SP_EL0`` is
assigned what is in ``struct thread_svc_regs``. This allows
``tee_svc_sys_return_helper()`` having the syscall exception handler return
directly to ``thread_unwind_user_mode()``.

.. _shared_memory:

Shared Memory
^^^^^^^^^^^^^

.. _smc:

SMC
^^^
SMC Interface
~~~~~~~~~~~~~
OP-TEE's SMC interface is defined in two levels using optee_smc.h_ and
optee_msg.h_. The former file defines SMC identifiers and what is passed in the
registers for each SMC. The latter file defines the OP-TEE Message protocol
which is not restricted to only SMC even if that currently is the only option
available.

SMC communication
~~~~~~~~~~~~~~~~~
The main structure used for the SMC communication is defined in ``struct
optee_msg_arg`` (in optee_msg.h_). If we are looking into the source code, we
could see that communication mainly is achieved using ``optee_msg_arg`` and
``thread_smc_args`` (in thread.h_), where ``optee_msg_arg`` could be seen as the
main structure. What will happen is that the :ref:`linux_kernel` driver will get
the parameters either from :ref:`optee_client` or directly from an internal
service in Linux kernel. The TEE driver will populate the struct
``optee_msg_arg`` with the parameters plus some additional bookkeeping
information.  Parameters for the SMC are passed in registers 1 to 7, register 0
holds the SMC id which among other things tells whether it is a standard or a
fast call.

.. _thread_handling:

Thread handling
^^^^^^^^^^^^^^^


.. _optee_smc.h: https://github.com/OP-TEE/optee_os/blob/master/core/arch/arm/include/sm/optee_smc.h
.. _optee_msg.h: https://github.com/OP-TEE/optee_os/blob/master/core/include/optee_msg.h
.. _thread.h: https://github.com/OP-TEE/optee_os/blob/master/core/arch/arm/include/kernel/thread.h

.. _Cortex-A53 TRM: http://infocenter.arm.com/help/topic/com.arm.doc.ddi0500j/DDI0500J_cortex_a53_trm.pdf
