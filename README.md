# hinance

Automated personal bookkeeping for hackers.

For the introduction please see [homepage](http://www.hinance.org).

This page describes how to use Hinance.

# Installation

There's a [package](https://aur.archlinux.org/packages/hinance) for Arch Linux.

There's also a reproducible Dockerized
[build automation](https://github.com/hinance/www) for the project homepage,
which includes all the necessary dependencies and the example.
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

Run the daemon: `hinance`

It'll generate an empty report in `out/www` folder.
Desktop version is here: `out/www/dtp-home.html`.
Mobile version is here: `out/www/mob-home.html`.

Once the report is generated, hit `Ctrl-C` to stop the daemon.

# How It Works

Hinance uses [Weboob](http://weboob.org) to **scrape** data from websites,
**transforms** it into a single consistent bookkeeping journal, and
**generates** the human-readable report.

Key point here is that in contrast to other bookkeeping solutions, Hinance
doesn't store an editable database of transactions.
Instead, it transforms immutable list of transactions from the external
websites (banks and shops) into consistent bookkeeping journal.

The user customizes each stage of the process.
On the scraping stage user specifies from which websites he/she wants to
import the data.
On the transformation stage user patches imported data, specifies rules to
combine banks and shops data, etc.
On the generation stage user categorizes financial operations and
specifies budget planning.

## Scraping Stage

On the scraping stage Hinance runs [Weboob](http://weboob.org) to scrape
the data from **banks** and **shops** websites.
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

### Merging Old and New Scraped Data

Some websites store only recent user data, and delete the data that is, for
example, 1 year old.
In this case it comes in handy to merge recently scraped data with the data
which was scraped a while ago, when the website still had it.

Hinance can do just that if you copy an archived scraped data into the input
folder. For example:

```
cp out/arc/2015_05_26_12_12/out/banks.hs.part in/banks_2015_05_26_12_12.hs.part
cp out/arc/2015_05_26_12_12/out/shops.hs.part in/shops_2015_05_26_12_12.hs.part
```

## Transformation Stage

On the transformation stage Hinance transforms scraped data into a
single consistent bookkeeping journal.

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
4. Grouping: groups pairs of changes representing the same operation.
5. Expanding: complements ungrouped singular changes to the groups.

Steps are executed in the order specified above in the pipeline fashion.
That is, the output of each step is connected to the input of the next step.

### Patching Step

On the patching step user can modify scraped data in terms of accounts,
transactions, orders, etc.
It comes in handy when some small amount of information is missing on the
websites (like refunds, or gift cards operations), or if you want to adjust
scraped data in some other way to assist further steps.

User can modify scraped data using callback function `patched` in
`in/user_data.hs` file.

### Converting Step

On the converting step the patched scraped data is converted from
accounts, transactions and orders into changes.

Each bank transaction is converted into a single change with empty group
identifier. That is, the resulting change is **ungrouped**.

Each shopping order is converted into multiple changes grouped together.
There are 3 special changes: **discount**, **shipping** and **tax**.
There's a change for each **item** purchased in the order.
There's a change for each **payment** for the order.
Group identifier for all of these changes is based on the shop name and
order number.

User specifies how to assign tags to the changes using `tagged` callback in
`in/user_data.hs` file.
Tags are specified in `in/user_tags.hs` file.

### Merging Step

On the merging step a pair of changes can be combined into a single change.
This is how banks and shops data are integrated together:
each change corresponding to order payment is merged with the ungrouped change
corresponding to the banking transaction of the same amount.
The resulting change has all tags of both input changes, and group identifier
of the input change that has a non-empty one.
Here's an
[example](http://www.hinance.org/examples/max/out/www/dtp-group1062.html)
changes group representing a shop order with merged payment transactions.

User specifies which changes pairs can be combined using `canmerge` callback
in `in/user_data.hs` file.

### Grouping Step

On the grouping step a pair of changes can be grouped together.
This is how banking transfers are handled:
ungrouped changes with the same absolute amount, but of different sign, are
being assigned the same unique group identifier.
Here's an
[example](http://www.hinance.org/examples/max/out/www/dtp-group769.html)
changes group representing a payment for a credit card.

User specifies which changes pairs can be grouped using `canxfer` callback
in `in/user_data.hs` file.

### Expanding Step

On the expanding step an ungrouped change can be grouped together with a new
change of the same absolute amount but of different sign.
This is how Hinance handles regular banking transactions, for example
a payment for gas, or a bill at a restaurant.

User specifies which changes need to be complemented and how to tag them
using `addtagged` callback in `in/user_data.hs` file.

## Generation Stage

On the generation stage a list of changes is converted into a human-readable
report.
Changes are categorized, the actual changes are displayed in comparison with
the planned budget, validation is performed and validation errors are
shown.

### Categorizing the Changes

To improve report readability, changes can be organized into **slices**
(like expenses, travel, car, hobbies, income, assets), each of which can
be further subdivided into **categories** like recurring expenses, household,
food, clothes, etc.
([example](http://www.hinance.org/examples/max/out/www/dtp-slice0-step5605201-ofs0-col15-cat4.html))

User can specify how to split changes into slices and categories using
`slices` list in `in/user_data.hs` file.

### Budget Planning

One of the main purposes of Hinance is to allow for budget planning and
to monitor how the actual financial operations compare with this plan.
In order to monitor this, three figures are shown in the report:
**actual**, **actual minus planned** and **planned**
([example](http://www.hinance.org/examples/max/out/www/dtp-slice0-step5605201-ofs0-col15-cat4.html)).

User can specify budget plan as a list of changes `planned` covering
time span `planfrom` to `planto` in `in/user_data.hs` file.

### Validation

Hinance validates the resulting bookkeeping journal to ensure its consistency.
Validation report can be found at `out/www/dtp-diag.html` after generation
was finished
([example](http://www.hinance.org/examples/min/out/www/dtp-diag.html)).

Validation consists of the following verifications.

**Banking account balance mismatch**.
Banking account transactions must add up to the account balance declared
by the banking website.
This error occurs if they don't.
Most of the time it means that the state of the banking website is
inconsistent, and usually this error will disappear disappears after scraping
again a few hours later.

**Changes without groups**.
All changes must add up to zero.
Transformation steps are designed in such a way that changes within each
group always add up to zero.
This error means that there are some ungrouped changes, which usually
indicates that more user customization is required on expanding step.

**Slices mismatch**.
Each slice must consist only of non-intersecting categories.
This error means that either there are some changes in a slice, but not in
any of its categories, or vice versa.

# Usage Summary

Create working directory where all program files will be stored:
```
mkdir <<<my-work-dir>>>
cd <<<my-work-dir>>>
```

Copy and edit customization files:
```
cp -r /usr/lib/hinance/default in
vim config.sh
vim user_tag.hs
vim user_data.hs
```

Configure [Weboob](http://weboob.org) backends.

Copy weboob backends file: `cp ~/.config/weboob/backends in/backends`

Run the daemon: `hinance`

It'll generate the report in `out/www` folder.
Desktop version is here: `out/www/dtp-home.html`.
Mobile version is here: `out/www/mob-home.html`.

To exit press `Ctrl-C`.

To view the logs: `tail -f out/log/hinance.log`

To skip the waiting period between running cycles: `touch cmd/restart`
