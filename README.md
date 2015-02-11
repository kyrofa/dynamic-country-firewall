# Dynamic Country Firewall

If you have a Linux server publicly available on the internet, you probably have
it locked down pretty hard. You may have Fail2Ban setup, etc. If you do, you may
be getting a lot of notifications about automated SSH attacks from China and
Russia, etc. Depending on why your server is accessible from the internet, you
may have no need to serve clients in those countries. In fact, you may know
exactly which countries you DO need to serve, and you couldn't care less about
anyone else.

If so, the Dynamic Country Firewall (DCF) was made for you. Note that it was
written and tested on Ubuntu 12.04 and later.


## Overview

The DCF is an extremely simple set of two scripts. One is a Python script that
downloads global IP blocks from Software77, and pulls country-specific networks
into a file. The other is a bash script that reads that file and turns the
country blocks into an `ipset`, and inserts an `iptables` rule to drop all
traffic not contained within that `ipset`.

The end result is a country-specific whitelist. All countries not specified in
the whitelist will never know your server existed (traffic is dropped
with DROP, not REJECT).


## Usage

It's pretty simple. Let's say you only want your server accessible from the
United States and Canada. No one hacks from Canada. The first step is to obtain
the country networks for both. That will use the `download_country_networks`
script, like the following:

```
$ ./download_country_networks.py /path/to/us_and_ca_networks US CA
```

That will dump all networks assigned to the United States and Canada into the
file `/path/to/us_and_ca_networks` (the path must already exist). Now let's use
that file to update our `iptables` whitelist, using the
`update_firewall_whitelist.bash` script:

```
$ ./update_firewall_whitelist.bash whitelist_networks /path/to/us_and_ca_networks eth0
```

That will create the whitelist within the ipset `whitelist_networks`, and create
a new rule in the first position of the INPUT chain to drop any traffic NOT
contained in that whitelist coming in over eth0 (change as necessary).


### Cron

A typical use-case is probably within a crontab. First, place the scripts in a
logical place (we recommend `/usr/local/bin/`). Then using Cron, download
country blocks however often you'd like (be careful about too often though--
Software77 will start penalizing you), then update the whitelist. Let's use the
example above, with and US and Canada in the whitelist. A crontab to do that
might look like this:

```
# Update networks once a day. Normally we'd use @daily, but Software77 kindly
# asks us not to pound it at midnight. So we'll use 0333.
33 03 * * * /usr/local/bin/download_country_networks.py /etc/country_networks/us_and_ca US CA | mail -s "US and CA Network Update" admin@example.com

# Update whitelist based on Software77 database update. That update takes a
# little while (depending on the countries in the whitelist), so we'll just wait
# until 0400. We'll whitelist the United States and Canada over eth0; everything
# else gets dropped.
00 04 * * * /usr/local/bin/update_firewall_whitelist.sh whitelist_networks /etc/country_networks/us_and_ca eth0 | mail -s "US and CA Network Whitelist Update" admin@example.com

# The whitelist is lost after each reboot, so let's build it when we boot
@reboot /usr/local/bin/update_firewall_whitelist.sh whitelist_networks /etc/country_networks/us_and_ca eth0 | mail -s "US and CA Network Whitelist Update" admin@example.com

```


## Contribute to the Dynamic Country Firewall

Contributions are always welcomed! I'm friendly, I promise.

1. Create issue (feature request, bug report, question-- doesn't matter).
2. Fork DCF.
3. Create feature branch.
4. Make changes and commit.
5. Make pull request into `develop` branch.


## Software77

If you like this tool, support [Software77](http://software77.net/geo-ip/).
