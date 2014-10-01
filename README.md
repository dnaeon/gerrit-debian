## Gerrit for Debian GNU/Linux

This is a package of [Gerrit](http://code.google.com/p/gerrit/) for [Debian GNU/Linux](http://http://www.debian.org/)

## How to build the package

* First make sure you have **build-essential**, **git-core** and **java7-runtime-headless** package installed on your system.
* Clone the package repository for [gerrit-debian](https://github.com/dnaeon/gerrit-debian)

Now building the package is easy as executing the command below:

	$ cd /path/to/gerrit-debian
	$ dpkg-buildpackage -us -uc

