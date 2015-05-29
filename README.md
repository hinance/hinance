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

# Getting Started

Create working directory where all program files will be stored:
```
mkdir <<<my-work-dir>>>
cd <<<my-work-dir>>>
```

Run: `hinance`

It'll generate an empty report in `out/www` folder.
Desktop version is `out/www/dtp-home.html`, mobile - `out/www/mob-home.html`.

Once the report is generated, hit `Ctrl-C` to stop the daemon.

# How It Works

Hinance uses [Weboob](http://weboob.org) to **scrape** data from websites,
**transforms** it into a single consistent bookkeeping journal, and
**generates** the report.

Key point here is that in contrast to other bookkeeping solutions, Hinance
doesn't store an editable database of transactions.
Instead, it transforms immutable list of transactions from the external
websites (banks and shops) into consistent bookkeeping journal.

The user customizes each stage of the process.
On the scraping stage user specifies from which websites does he/she want to
import the data.
On the transformation stage user patches imported data, specifies rules to
combine banks and shops data, etc.
On the generation stage user categorizes financial operations and
specifies budget planning.

## Scraping Stage

On this stage Hinance runs Weboob to scrape the data from **banks** and
**shops** websites.
The output of this stage is expressed in terms of banks, shops, accounts,
transactions, orders, items and payments.

User needs to add a **Weboob backend** for each website he/she wants
to import the data from
(please see [Weboob website](http://weboob.org/modules) for the instructions
how to do this).
Weboob modules usable with Hinance must support `CapBank` or `CapShop`
capabilities.
After backends were configured, user must copy config file to the working
hinance directory: `cp ~/.config/weboob/backends in/backends`.

TODO: merging old and new data
TODO: diagnostics
TODO: planning
TODO: generation stage

## Transformation Stage

On this stage Hinance transforms scraped data into the consistent bookkeeping
journal.

The bookkeeping journal is represented as a list of **changes**.
Each change is a labelled **amount** of money at the specified **time**.
Changes are labelled with **tags** and human-readable **descriptions**.
Each row of the
[example report](http://www.hinance.org/examples/max/out/www/dtp-slice0-step5605201-ofs0-col15-cat4.html)
table represents one change.
Related changes are grouped together by using the same **group** identifier
([example](http://www.hinance.org/examples/max/out/www/dtp-group1062.html)).

Transformation of the scraped data into a list of changes is done in several
sequential steps:

1. Patching: post-processes the scraped data.
2. Converting: converts scraped data into a list of changes.
3. Merging: joins pairs of changes representing the same operation.
4. Grouping
5. Expanding

Steps are executed in the order specified above in the pipeline fashion.
That is, the output of each step is connected to the input of the next step.

### Patching Step

On this step user can modify scraped data in terms of accounts, transactions,
orders, etc.
It comes in handy when some small amount of information is missing on the
websites (like refunds, or gift cards operations), or if you want to adjust
scraped data in some other way to assist further steps.

User can modify scraped data using callback function `patched` in
`in/user_data.hs` file.

### Converting Step

Here the patched scraped data is converted from terms of accounts, transactions
and orders into changes.

Each bank transaction is converted into a single change with empty group
identifier.

Each shopping order is converted into multiple changes grouped together.
There are changes for **discount**, **shipping** and **tax** payments.
There's a change for each **item** purchased in the order.
There's a change for each **payment** for the order.
Group identifier for all of these changes is based on the shop name and
order number.

User specifies how to assign tags to the changes using `tagged` callback in
`in/user_data.hs` file.
Tags are specified in `in/user_tags.hs` file.

### Merging Step

On this step a pair of changes can be combined into a single change.
This is how banks and shops data are integrated together:
each change corresponding to order payment is merged with the change
of the banking transaction of the same amount.
The resulting change has all tags of both input changes.

User specifies which changes pairs can be combined using `canmerge` callback
in `in/user_data.hs` file.

### Grouping Step

### Expanding Step

# Usage

Create working directory where all program files will be stored:
```
mkdir <<<my-work-dir>>>
cd <<<my-work-dir>>>
```

Copy and edit customization files (see next sections for details):
```
cp -r /usr/lib/hinance/default in
vim config.sh
vim user_tag.hs
vim user_data.hs
```

Configure [Weboob](http://weboob.org) backends.

Copy weboob backends file: `cp ~/.config/weboob/backends in/backends`

Run: `hinance`

It'll generate the report in `out/www` folder.
Desktop version is `out/www/dtp-home.html`, mobile - `out/www/mob-home.html`.

To exit press `Ctrl-C`.
