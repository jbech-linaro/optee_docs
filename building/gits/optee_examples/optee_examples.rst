.. _optee_examples:

==============
optee_examples
==============
This document describes the sample applications that are included in the OP-TEE,
that aim to showcase specific functionality and use cases.

For sake of simplicity, all OP-TEE example test application are prefixed with
``optee_example_``. All of them works as standalone host and Trusted Application
and can be found in separate directories.

acipher
^^^^^^^

    ================================ ========================================
    Application name                 UUID
    ================================ ========================================
    ``optee_example_acipher``        ``a734eed9-d6a1-4244-aa50-7c99719e7b7b``
    ================================ ========================================

Generates an RSA key pair of specified size and encrypts a supplied string with
it using the GlobalPlatform TEE Internal Core API.

aes
^^^

    ================================ ========================================
    Application name                 UUID
    ================================ ========================================
    ``optee_example_aes``            ``5dbac793-f574-4871-8ad3-04331ec17f24``
    ================================ ========================================

Runs an AES encryption and decryption from a TA using the GlobalPlatform TEE
Internal Core API. Non secure test application provides the key, initial vector
and ciphered data.

.. _hello_world:

hello_world
^^^^^^^^^^^

    ================================ ========================================
    Application name                 UUID
    ================================ ========================================
    ``optee_example_hello_world``    ``8aaaf200-2450-11e4-abe2-0002a5d5c51b``
    ================================ ========================================

This is a very simple Trusted Application to answer a hello command and
incrementing an integer value.

hotp
^^^^

    ================================ ========================================
    Application name                 UUID
    ================================ ========================================
    ``optee_example_hotp``           ``484d4143-2d53-4841-3120-4a6f636b6542``
    ================================ ========================================

.. include:: hotp.rst

random
^^^^^^

    ================================ ========================================
    Application name                 UUID
    ================================ ========================================
    ``optee_example_random``         ``b6c53aba-9669-4668-a7f2-205629d00f86``
    ================================ ========================================

Generates a random UUID using capabilities of TEE API
(``TEE_GenerateRandom()``).

secure_storage
^^^^^^^^^^^^^^

    ================================ ========================================
    Application name                 UUID
    ================================ ========================================
    ``optee_example_secure_storage`` ``f4e750bb-1437-4fbf-8785-8d3580c34994``
    ================================ ========================================

A Trusted Application to read/write raw data into the OP-TEE secure storage
using the GlobalPlatform TEE Internal Core API.


.. todo::

    How to build a Trusted Application
    [TA basics] documentation presents the basics for  implementing and building
    an OP-TEE trusted application.

    One can also refer to the examples provided: source files and make scripts.

    [TA basics]:	./docs/TA_basics.md
