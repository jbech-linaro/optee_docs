.. _toolchains:

==========
Toolchains
==========

.. code-block:: bash

	$ cd $HOME
	$ mkdir toolchains
	$ cd toolchains
	$ wget [url/to/gcc_tarball]
	$ tar xvf [gcc_tarball]
	$ export PATH=$HOME/toolchains/[gcc_extracted_dir]/bin:$PATH
