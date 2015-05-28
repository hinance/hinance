# hinance

Automated personal bookkeeping for hackers.
For more information please see [homepage](http://www.hinance.org).

# Installation

There's a [package](https://aur.archlinux.org/packages/hinance) for Arch Linux.

There's also a reproducible Dockerized
[build automation](https://github.com/hinance/www) for the project homepage,
which includes all the necessary dependencies.
The Docker container is pre-built and uploaded to the repository, but if you
want to build it yourself, keep in mind that it takes about 1 hour on 4 cores,
8GB RAM machine.

Feel free to use the above as a reference when installing on your target
platform.

# Running

Create working directory where all program files will be stored:
```
mkdir <<<my-work-dir>>>
cd <<<my-work-dir>>>
```

Run: `hinance`

This should generate an empty report in `out/www` folder.
To add real data and customization, see below.
