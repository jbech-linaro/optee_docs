.. _globalplatform_api:

GlobalPlatform API
==================

Introduction
^^^^^^^^^^^^
GlobalPlatform_ works across industries to identify, develop and publish
specifications which facilitate the secure and interoperable deployment and
management of multiple embedded applications on secure chip technology. OP-TEE
has support for GlobalPlatform TEE Client API Specification_ v1.0 (GPD_SPE_007)
and TEE Internal Core API Specification v1.1.2 (GPD_SPE_010).

.. _tee_client_api:

TEE Client API
^^^^^^^^^^^^^^
The TEE Client API describes and defines how a client running in a rich
operating environment (REE) should communicate with the TEE. To identify a
Trusted Application (TA) to be used, the client provides an UUID_. All TA's
exposes one or several functions. Those functions corresponds to a so called
``commandID`` which also is sent by the client.

TEE Contexts
~~~~~~~~~~~~
The TEE Context is used for creating a logical connection between the client
and the TEE. The context must be initialized before the TEE Session can be
created. When the client has completed a jobs running in secure world, it
should finalize the context and thereby also releasing resources.

TEE Sessions
~~~~~~~~~~~~
Sessions are used to create logical connections between a client and a specific
Trusted Application. When the session has been established the client have a
opened up the communication channel towards the specified Trusted Application
identified by the ``UUID``. At this stage the client and the Trusted
Application can start to exchange data.


TEE Client API example / usage
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Below you will find the main functions as defined by GlobalPlatform and which
are used in the communication between the client and the TEE.

.. code-block:: c

    TEEC_Result TEEC_InitializeContext(
    	const char* name,
    	TEEC_Context* context)

    void TEEC_FinalizeContext(
    	TEEC_Context* context)

    TEEC_Result TEEC_OpenSession (
    	TEEC_Context* context,
    	TEEC_Session* session,
    	const TEEC_UUID* destination,
    	uint32_t connectionMethod,
    	const void* connectionData,
    	TEEC_Operation* operation,
    	uint32_t* returnOrigin)

    void TEEC_CloseSession (
    	TEEC_Session* session)

    TEEC_Result TEEC_InvokeCommand(
    	TEEC_Session* session,
    	uint32_t commandID,
    	TEEC_Operation* operation,
    	uint32_t* returnOrigin)

In principle the commands are called in this order:

.. code-block:: c

    TEEC_InitializeContext(...)
    TEEC_OpenSession(...)
    TEEC_InvokeCommand(...)
    TEEC_CloseSession(...)
    TEEC_FinalizeContext(...)

It is not uncommon that ``TEEC_InvokeCommand`` is called several times in row
when the session has been established.

For a complete example, please see chapter **5.2 Example 1: Using the TEE
Client API** in the GlobalPlatform TEE Client API Specification_ v1.0.

.. _tee_internal_core_api:

TEE Internal Core API
^^^^^^^^^^^^^^^^^^^^^
The Internal Core API is the API that is exposed to the Trusted Applications
running in the secure world. The TEE Internal API consists of four major parts:

1. Trusted Storage API for Data and Keys
2. Cryptographic Operations API
3. Time API
4. Arithmetical API

Examples / usage
~~~~~~~~~~~~~~~~
Calling the Internal Core API is done in the same way as described above using
Client API. The best place to find information how this should be done is in
the TEE Internal Core API Specification_ v1.1.2 which contains many examples of
how to call the various APIs. One can also have a look at the examples in the
optee_examples_ git.

.. _extensions:

Extensions
^^^^^^^^^^
In addition to what is stated in :ref:`tee_internal_core_api`, there are some
non-official extensions in OP-TEE.

Cache Maintenance Support
~~~~~~~~~~~~~~~~~~~~~~~~~
Following functions have been introduced in order to operate with cache:

.. code-block:: c

    TEE_Result TEE_CacheClean(char *buf, size_t len);
    TEE_Result TEE_CacheFlush(char *buf, size_t len);
    TEE_Result TEE_CacheInvalidate(char *buf, size_t len);

These functions are available to any Trusted Application defined with the flag
``TA_FLAG_CACHE_MAINTENANCE`` sets on. When not set, each function returns the
error code ``TEE_ERROR_NOT_SUPPORTED``.

Within these extensions, a Trusted Application is able to operate on the data
cache, with the following specification:

.. list-table::
    :widths: 10 60
    :header-rows: 1

    * - Function
      - Description

    * - ``TEE_CacheClean()``
      - Write back to memory any dirty data cache lines. The line is marked as
        not dirty. The valid bit is unchanged.

    * - ``TEE_CacheFlush()``
      - Purges any valid data cache lines. Any dirty cache lines are first
        written back to memory, then the cache line is invalidated.

    * - ``TEE_CacheInvalidate()``
      - Invalidate any valid data cache lines. Any dirty line are not written
        back to memory.

In the following two cases, the error code ``TEE_ERROR_ACCESS_DENIED`` is
returned:

    - The memory range has not the write access, that is
      ``TEE_MEMORY_ACCESS_WRITE`` is not set.
    - The memory is **not** user space memory.


.. _concat_kdf:

Concat KDF
~~~~~~~~~~
Support for the Concatenation Key Derivation Function (Concat KDF) according to
`SP 800-56A`_ (*Recommendation for Pair-Wise Key Establishment Schemes Using
Discrete Logarithm Cryptography*) can be found in OP-TEE.

You may disable this extension by setting the following configuration variable
in ``conf.mk``:

.. code-block:: make

    CFG_CRYPTO_CONCAT_KDF := n

**Implementation notes**

All key and parameter sizes **must** be multiples of 8 bits. That is:

    - Input parameters: the shared secret (``Z``) and ``OtherInfo``.
    - Output parameter: the derived key (``DerivedKeyingMaterial``).

In addition, the maximum size of the derived key is limited by the size of an
object of type ``TEE_TYPE_GENERIC_SECRET`` (512 bytes).

This implementation does **not** enforce any requirement on the content of the
``OtherInfo`` parameter. It is the application's responsibility to make sure
this parameter is constructed as specified by the NIST specification if
compliance is desired.

**API extension**

To support Concat KDF, the :ref:`tee_internal_core_api` v1.1 was extended with
new algorithm descriptors, new object types, and new object attributes as
described below.

**p.95 Add new object type to TEE_PopulateTransientObject**

The following entry shall be added to **Table 5-8**:

.. list-table::
    :widths: 10 60
    :header-rows: 1

    * - Object type
      - Parts

    * - TEE_TYPE_CONCAT_KDF_Z
      - The ``TEE_ATTR_CONCAT_KDF_Z`` part (input shared secret) must be
        provided.

**p.121 Add new algorithms for TEE_AllocateOperation**

The following entry shall be added to **Table 6-3**:

.. list-table::
    :widths: 10 60
    :header-rows: 1

    * - Algorithm
      - Possible Modes

    * - TEE_ALG_CONCAT_KDF_SHA1_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA224_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA256_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA384_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA512_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA512_DERIVE_KEY
      - TEE_MODE_DERIVE

**p.126 Explain usage of HKDF algorithms in TEE_SetOperationKey**

In the bullet list about operation mode, the following shall be added:

    - For the Concat KDF algorithms, the only supported mode is
      ``TEE_MODE_DERIVE``.

**p.150 Define TEE_DeriveKey input attributes for new algorithms**

The following sentence shall be deleted:

.. code-block:: none

    The TEE_DeriveKey function can only be used with the algorithm
    TEE_ALG_DH_DERIVE_SHARED_SECRET.

The following entry shall be added to **Table 6-7**:

.. list-table::
    :header-rows: 1

    * - Algorithm
      - Possible operation parameters

    * - TEE_ALG_CONCAT_KDF_SHA1_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA224_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA256_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA384_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA512_DERIVE_KEY
        TEE_ALG_CONCAT_KDF_SHA512_DERIVE_KEY
      - TEE_ATTR_CONCAT_KDF_DKM_LENGTH: up to 512 bytes. This parameter is
        mandatory: TEE_ATTR_CONCAT_KDF_OTHER_INFO

**p.152 Add new algorithm identifiers**

The following entries shall be added to **Table 6-8**:

.. list-table::
    :header-rows: 1

    * - Algorithm
      - Identifier

    * - TEE_ALG_CONCAT_KDF_SHA1_DERIVE_KEY
      - 0x800020C1

    * - TEE_ALG_CONCAT_KDF_SHA224_DERIVE_KEY
      - 0x800030C1

    * - TEE_ALG_CONCAT_KDF_SHA256_DERIVE_KEY
      - 0x800040C1

    * - TEE_ALG_CONCAT_KDF_SHA384_DERIVE_KEY
      - 0x800050C1

    * - TEE_ALG_CONCAT_KDF_SHA512_DERIVE_KEY
      - 0x800060C1

**p.154 Define new main algorithm**

In **Table 6-9** in section 6.10.1, a new value shall be added to the value
column for row bits ``[7:0]``:

.. list-table::
    :header-rows: 1

    * - Bits
      - Function
      - Value

    * - Bits [7:0]
      - Identifiy the main underlying algorithm itself
      - ...

        0xC1: Concat KDF

The function column for ``bits[15:12]`` shall also be modified to read:

.. list-table::
    :header-rows: 1

    * - Bits
      - Function
      - Value

    * - Bits [15:12]
      - Define the message digest for asymmetric signature algorithms or Concat KDF
      -

**p.155 Add new object type for Concat KDF input shared secret**

The following entry shall be added to **Table 6-10**:

.. list-table::
    :header-rows: 1

    * - Name
      - Identifier
      - Possible sizes

    * - TEE_TYPE_CONCAT_KDF_Z
      - 0xA10000C1
      - 8 to 4096 bits (multiple of 8)

**p.156 Add new operation attributes for Concat KDF**

The following entries shall be added to **Table 6-11**:

.. list-table::
    :header-rows: 1

    * - Name
      - Value
      - Protection
      - Type
      - Comment

    * - TEE_ATTR_CONCAT_KDF_Z
      - 0xC00001C1
      - Protected
      - Ref
      - The shared secret (``Z``)

    * - TEE_ATTR_CONCAT_KDF_OTHER_INFO
      - 0xD00002C1
      - Public
      - Ref
      - ``OtherInfo``

    * - TEE_ATTR_CONCAT_KDF_DKM_LENGTH
      - 0xF00003C1
      - Public
      - Value
      - The length (in bytes) of the derived keying material to be generated,
        maximum 512. This is ``KeyDataLen`` / 8.


.. _hkdf:

HKDF
~~~~
OP-TEE implements the *HMAC-based Extract-and-Expand Key Derivation Function
(HKDF)* as specified in `RFC 5869`_. This file documents the extensions to the
:ref:`tee_internal_core_api` v1.1 that were implemented to support this
algorithm. Trusted Applications should include
``<tee_api_defines_extensions.h>`` to import the definitions.

Note that the implementation follows the recommendations of version 1.1 of the
specification for adding new algorithms. It should make it compatible with
future changes to the official specification.

You can disable this extension by setting the following in ``conf.mk``:

.. code-block:: make

    CFG_CRYPTO_HKDF := n

**p.95 Add new object type to TEE_PopulateTransientObject**

The following entry shall be added to **Table 5-8**:

.. list-table::
    :header-rows: 1

    * - Object type
      - Parts

    * - TEE_TYPE_HKDF_IKM
      - The TEE_ATTR_HKDF_IKM (Input Keying Material) part must be provided.

**p.121 Add new algorithms for TEE_AllocateOperation**

The following entry shall be added to **Table 6-3**:

.. list-table::
    :header-rows: 1

    * - Algorithm
      - Possible Modes

    * - TEE_ALG_HKDF_MD5_DERIVE_KEY
        TEE_ALG_HKDF_SHA1_DERIVE_KEY
        TEE_ALG_HKDF_SHA224_DERIVE_KEY
        TEE_ALG_HKDF_SHA256_DERIVE_KEY
        TEE_ALG_HKDF_SHA384_DERIVE_KEY
        TEE_ALG_HKDF_SHA512_DERIVE_KEY
        TEE_ALG_HKDF_SHA512_DERIVE_KEY
      - TEE_MODE_DERIVE

**p.126 Explain usage of HKDF algorithms in TEE_SetOperationKey**

In the bullet list about operation mode, the following shall be added:

    - For the HKDF algorithms, the only supported mode is TEE_MODE_DERIVE.

**p.150 Define TEE_DeriveKey input attributes for new algorithms**

The following sentence shall be deleted:

.. code-block:: none

    The TEE_DeriveKey function can only be used with the algorithm
    TEE_ALG_DH_DERIVE_SHARED_SECRET

The following entry shall be added to **Table 6-7**:

.. list-table::
    :header-rows: 1

    * - Algorithm
      - Possible operation parameters

    * - TEE_ALG_HKDF_MD5_DERIVE_KEY
        TEE_ALG_HKDF_SHA1_DERIVE_KEY
        TEE_ALG_HKDF_SHA224_DERIVE_KEY
        TEE_ALG_HKDF_SHA256_DERIVE_KEY
        TEE_ALG_HKDF_SHA384_DERIVE_KEY
        TEE_ALG_HKDF_SHA512_DERIVE_KEY
        TEE_ALG_HKDF_SHA512_DERIVE_KEY
      - TEE_ATTR_HKDF_OKM_LENGTH: Number of bytes in the Output Keying Material

        TEE_ATTR_HKDF_SALT (optional) Salt to be used during the extract step

        TEE_ATTR_HKDF_INFO (optional) Info to be used during the expand step

**p.152 Add new algorithm identifiers**

The following entries shall be added to **Table 6-8**:

.. list-table::
    :header-rows: 1

    * - Algorithm
      - Identifier

    * - TEE_ALG_HKDF_MD5_DERIVE_KEY
      - 0x800010C0

    * - TEE_ALG_HKDF_SHA1_DERIVE_KEY
      - 0x800020C0

    * - TEE_ALG_HKDF_SHA224_DERIVE_KEY
      - 0x800030C0

    * - TEE_ALG_HKDF_SHA256_DERIVE_KEY
      - 0x800040C0

    * - TEE_ALG_HKDF_SHA384_DERIVE_KEY
      - 0x800050C0

    * - TEE_ALG_HKDF_SHA512_DERIVE_KEY
      - 0x800060C0

## p.154 Define new main algorithm

In **Table 6-9** in section 6.10.1, a new value shall be added to the value column
for row ``bits [7:0]``:

.. list-table::
    :header-rows: 1

    * - Bits
      - Function
      - Value

    * - Bits [7:0]
      - Identifiy the main underlying algorithm itself
      - ...

        0xC0: HKDF

The function column for ``bits[15:12]`` shall also be modified to read:

.. list-table::
    :header-rows: 1

    * - Bits
      - Function
      - Value

    * - Bits [15:12]
      - Define the message digest for asymmetric signature algorithms or HKDF
      -

**p.155 Add new object type for HKDF input keying material**

The following entry shall be added to **Table 6-10**:

.. list-table::
    :header-rows: 1

    * - Name
      - Identifier
      - Possible sizes

    * - TEE_TYPE_HKDF_IKM
      - 0xA10000C0
      - 8 to 4096 bits (multiple of 8)

**p.156 Add new operation attributes for HKDF salt and info**

The following entries shall be added to **Table 6-11**:

.. list-table::
    :widths: 40 10 10 10 40
    :header-rows: 1

    * - Name
      - Value
      - Protection
      - Type
      - Comment

    * - TEE_ATTR_HKDF_IKM
      - 0xC00001C0
      - Protected
      - Ref
      -

    * - TEE_ATTR_HKDF_SALT
      - 0xD00002C0
      - Public
      - Ref
      -

    * - TEE_ATTR_HKDF_INFO
      - 0xD00003C0
      - Public
      - Ref
      -

    * - TEE_ATTR_HKDF_OKM_LENGTH
      - 0xF00004C0
      - Public
      - Value
      -

.. _pbkdf2:

PBKDF2
~~~~~~
This document describes the OP-TEE implementation of the key derivation
function, *PBKDF2* as specified in `RFC 2898`_ section 5.2. This RFC is a
republication of PKCS #5 v2.0 from RSA Laboratories' Public-Key Cryptography
Standards (PKCS) series.

You may disable this extension by setting the following configuration variable
in ``conf.mk``:

.. code-block:: make

    CFG_CRYPTO_PBKDF2 := n

**API extension**

To support PBKDF2, the :ref:`tee_internal_core_api` v1.1 was extended with a new
algorithm descriptor, new object types, and new object attributes as described
below.

**p.95 Add new object type to TEE_PopulateTransientObject**

The following entry shall be added to **Table 5-8**:

.. list-table::
    :header-rows: 1

    * - Object type
      - Parts

    * - TEE_TYPE_PBKDF2_PASSWORD
      - The TEE_ATTR_PBKDF2_PASSWORD part must be provided.

**p.121 Add new algorithms for TEE_AllocateOperation**

The following entry shall be added to **Table 6-3**:

.. list-table::
    :header-rows: 1

    * - Algorithm
      - Possible Modes

    * - TEE_ALG_PBKDF2_HMAC_SHA1_DERIVE_KEY
      - TEE_MODE_DERIVE

**p.126 Explain usage of PBKDF2 algorithm in TEE_SetOperationKey**

In the bullet list about operation mode, the following shall be added:

    - For the PBKDF2 algorithm, the only supported mode is TEE_MODE_DERIVE.

**p.150 Define TEE_DeriveKey input attributes for new algorithms**

The following sentence shall be deleted:

.. code-block:: none

    The TEE_DeriveKey function can only be used with the algorithm
    TEE_ALG_DH_DERIVE_SHARED_SECRET

The following entry shall be added to **Table 6-7**:

.. list-table::
    :header-rows: 1

    * - Algorithm
      - Possible operation parameters

    * - TEE_ALG_PBKDF2_HMAC_SHA1_DERIVE_KEY
      - TEE_ATTR_PBKDF2_DKM_LENGTH: up to 512 bytes. This parameter is
        mandatory.

        TEE_ATTR_PBKDF2_SALT

        TEE_ATTR_PBKDF2_ITERATION_COUNT: This parameter is mandatory.

**p.152 Add new algorithm identifiers**

The following entries shall be added to **Table 6-8**:

.. list-table::
    :header-rows: 1

    * - Algorithm
      - Identifier

    * - TEE_ALG_PBKDF2_HMAC_SHA1_DERIVE_KEY
      - 0x800020C2

**p.154 Define new main algorithm**

In **Table 6-9** in section 6.10.1, a new value shall be added to the value
column for row ``bits [7:0]``:

.. list-table::
    :header-rows: 1

    * - Bits
      - Function
      - Value

    * - Bits [7:0]
      - Identifiy the main underlying algorithm itself
      - ...

        0xC2: PBKDF2

The function column for ``bits[15:12]`` shall also be modified to read:

.. list-table::
    :header-rows: 1

    * - Bits
      - Function
      - Value

    * - Bits [15:12]
      - Define the message digest for asymmetric signature algorithms or PBKDF2
      -

**p.155 Add new object type for PBKDF2 password**

The following entry shall be added to **Table 6-10**:

.. list-table::
    :header-rows: 1

    * - Name
      - Identifier
      - Possible sizes

    * - TEE_TYPE_PBKDF2_PASSWORD
      - 0xA10000C2
      - 8 to 4096 bits (multiple of 8)

**p.156 Add new operation attributes for Concat KDF**

The following entries shall be added to **Table 6-11**:

.. list-table::
    :widths: 40 10 10 10 40
    :header-rows: 1

    * - Name
      - Value
      - Protection
      - Type
      - Comment

    * - TEE_ATTR_PBKDF2_PASSWORD
      - 0xC00001C2
      - Protected
      - Ref
      -

    * - TEE_ATTR_PBKDF2_SALT
      - 0xD00002C2
      - Public
      - Ref
      -

    * - TEE_ATTR_PBKDF2_ITERATION_COUNT
      - 0xF00003C2
      - Public
      - Value
      -

    * - TEE_ATTR_PBKDF2_DKM_LENGTH
      - 0xF00004C2
      - Public
      - Value
      - The length (in bytes) of the derived keying material to be generated,
        maximum 512.


.. _secure_element_api:

Secure Element API
^^^^^^^^^^^^^^^^^^
.. note::
    It's been a long time since this feature was tested. Most likely things will
    **not** work. There are no plans on updating this at the moment. But if
    there is anyone out there interested in this willing to spend time on this,
    it would of course be appreciated.

A ``Secure Element (SE)`` is a tamper-resistant platform (typically a one chip
secure microcontroller) capable of securely hosting applications and their
confidential and cryptographic data (e.g. key management) in accordance with
the rules and security requirements set forth by a set of well-identified
trusted authorities. Simplified speaking, SE is a secure platform that can run
application (called Applet) on it. In order to communicate with Applet, we need
a transport interface.

SE can be implemented via one of the following technologies

    - Embedded SE (accessed via platform dependent interface, unremovable)
    - Universal Integrated Circuit Card (UICC, accessed via SIM interface)
    - Advanced secure MicroSD (accessed via sdio/mmc interface)

Which means the physical interface between application processor (AP) and SE
can be quite different. GlobalPlatform tries to remove this gap and defined a
standard transport API called ``Secure Element API`` to cover those different
physical transport layer protocols. SE can be accessed directly in TEE, or
indirectly accessed via REE. In later case, a *secure channel* is needed to
ensure the data stream is not hijacked in REE. (For secure channel, we may
leverage TZC-400_ to create a secure memory that is not accessible in REE). To
understand SE API, you need to understand the following terms:

    - **Trusted Application (TA)**: An application execute in Trust Execution
      Environment (TEE), which is the initiator of SE API.

    - **Applet**: Applications that run on smartcard OS. Secure Element API
      defines the method to communicate between host application (in our case,
      TA) and Applet.

    - **Service**: A service can be used to retrieve all SE readers available
      in the system, it also provides a service to create a session from TA to
      a specific Reader.

    - **Session**: It maintains the connection between TA and a specific
      Reader. Different TAs can have a session opened on the same reader. It is
      SE manager's responsibility to demux the request from different TAs. Upon
      a session is opened by a TA, the card is power-up and ready to accept
      commands.

    - **Reader**: It is an abstraction to describe the transport interface
      between the system and SEs. You can imagine that a SD card slot is a
      Reader connected with assd. A ril daemon can be another read to talk with
      UICC cards. Even embedded SE should have a (virtual) Reader attached to
      it.

    - **Logical Channel**: It is used by host application (in our case, a TA)
      to communicate with applets on the smartcard. [GlobalPlatform Card
      Specification] defines maximum 20 logical channels, numbered from 0~19.
      Channel number 0 is so-called ``Basic logical channel``, or in short,
      ``Basic channel``. A channel can be opened or closed by a host
      application. It is the smartcard OS's responsibility to manage the state
      of each logical channel. Basic channel is always open and cannot be
      closed. A channel must select an applet, which means the command passed
      through the channel will be processed by the selected applet.
      GlobalPlatform requires a default applet must be selected on basic
      channel after system reset. Host application can select different applet
      by issuing a ``SELECT command`` on basic channel. Other logical channels
      (numbered 1~19) can be opened with or without a given ``Application
      Identifier`` (AID). If AID is not given, the applet selected on basic
      channel will be selected on the just opened logical channel.

    - **MultiSelectable or Non-MultiSelectable**: An applet can be
      MultiSelectable or Non-MultiSelectable. For a Non-MultiSelectable applet,
      it can only be selected by one channel, further ``SELECT command`` on
      another channel that is targeting to the applet will fail.
      MultiSelectable applet can be selected by multiple channels, the applet
      can decide maximum number of channels it is willing to accept.

Design
~~~~~~

    - **Manager** `core/include/tee/se/manager.h`_: This component manages all
      Readers on the system. It should provide reader interface for the Reader
      developers to register their own Reader instance. (In the case of
      [JavaCard Simulator], we should have [PC/SC Passthru Reader] to talk with
      simulator) It also provides an interface for client to get ``reader
      handle`` on the system.

    - **Reader** `core/include/tee/se/reader.h`_: It provides the operations that
      can be applied on a ``reader handle``. Just like get reader properties
      and create session to a reader. It’s also responsible for routing an
      operation(open, transmit...etc) to a specific Reader implementation.

    - **Protocol** (core/include/tee/se/{protocol.h,aid.h,apdu.h}): This module
      implements the *ISO7816 transport layer* protocol that is used to talk
      with smartcard. It relies on operations provided by Reader to transmit
      *Application Protocol Data Unit* (APDU, refer to ISO7816-4_) to a
      specific SE.

    - **Session** `core/include/tee/se/session.h`_: It provides the operations
      that can be applied on a session. Just like open basic or logical
      channel, and transmit APDU on the session. It relies on protocol layer to
      create logical, basic channel and transmit APDU.

    - **Channel** `core/include/tee/se/channel.h`_: It provides the operations
      that can be applied on a channel. Like transmit an APDU on the channel,
      select next applet. It relies on protocol module to select AID, and
      session module to transport APDU.

    - **Reader** interface `core/include/tee/se/reader/interface.h`_: The
      abstract layer used to implement a specific Reader instance, a set of
      operations need to be implemented to support a new Reader.

        - ``open()``: Triggered when the first session is connected, the Reader
          should be powered on and reset. Doing initialization. Detect SE is
          present or not.

        - ``close()``: Triggered when the last session to the Reader has been
          closed. The Reader can be powered down in this method.

        - ``get_properties()``: Get properties of the Reader. Something like
          the Reader is exclusive to TEE or not. SE is present...etc.

        - ``get_atr()``: Get ATR message from the Reader. ATR is defined in
          ISO7816-3, and it is the message report by SE to describe the ability
          of SE.

        - ``transmit()``: Transmit an APDU through the Reader which SE attached
          to.

How to try it out
~~~~~~~~~~~~~~~~~
To test SE API, you need `modified QEMU`_ and enhanced `JavaCard simulator`_.
Please use this `setup script`_ to setup test environment.

.. _GlobalPlatform: https://globalplatform.org
.. _ISO7816-4: http://www.embedx.com/pdfs/ISO_STD_7816/info_isoiec7816-4%7Bed2.0%7Den.pdf
.. _JavaCard simulator: https://github.com/m943040028/jcardsim/tree/se_api
.. _modified QEMU: https://github.com/m943040028/qemu/tree/smart_card_emul
.. _optee_examples: https://github.com/linaro-swg/optee_examples
.. _TZC-400: http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0504c/index.html
.. _RFC 2898: https://www.ietf.org/rfc/rfc2898.txt
.. _RFC 5869: https://tools.ietf.org/html/rfc5869
.. _setup script: https://raw.githubusercontent.com/m943040028/optee_os/48fe3bf418bda0047784327cbf72e6613ff547b2/scripts/setup_seapi_optee.sh
.. _Specification: https://globalplatform.org/specs-library/?filter-committee=tee
.. _SP 800-56A: http://csrc.nist.gov/publications/nistpubs/800-56A/SP800-56A_Revision1_Mar08-2007.pdf
.. _UUID: http://en.wikipedia.org/wiki/Universally_unique_identifier

.. _core/include/tee/se/channel.h: https://github.com/OP-TEE/optee_os/blob/master/core/include/tee/se/channel.h
.. _core/include/tee/se/manager.h: https://github.com/OP-TEE/optee_os/blob/master/core/include/tee/se/manager.h
.. _core/include/tee/se/reader.h: https://github.com/OP-TEE/optee_os/blob/master/core/include/tee/se/reader.h
.. _core/include/tee/se/reader/interface.h: https://github.com/OP-TEE/optee_os/blob/master/core/include/tee/se/reader/interface.h
.. _core/include/tee/se/session.h: https://github.com/OP-TEE/optee_os/blob/master/core/include/tee/se/session.h
