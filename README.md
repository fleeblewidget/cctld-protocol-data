# Methodology

- ccTLD list - from Iana (https://www.iana.org/domains/root/db) filtered to country-code entries, cross-referenced with https://www.worldstandards.eu/other/tlds/ for country names
- DS in root - based on dig for DS in .[TLD] against a.root-servers.net
- RDAP - checked against RDAP bootstrap file, from https://www.iana.org/assignments/rdap-dns/rdap-dns.xhtml
- WHOIS - lookup using WHOIS for nic.[TLD] (which exists in most zones) against the whois server listed by IANA (whois.iana.org)

# Scripts
The included Ruby scripts can be used to generate fresh data. They require a newline-separated ccTLD list file (cctld-list.txt).

# WHOIS Notes
WHOIS responses are very varied, and in particular the chosen search string for these metrics (nic.TLD) has
some surprising responses for some TLDs. In these cases, separate checks were carried out to try and determine
whether a server was available, and special cases coded into the script.

Several of these responses relate to domain availability (e.g. .qa "The Domain Name is not Available"), some
suggest that nic.TLD isn't registered - in some cases despite the whois being hosted on a subdomain of it.

A final note on WHOIS: the protocol is being replaced with RDAP and some registries have deprecated it. Therefore,
absence of WHOIS in registries which have RDAP is likely not a sign of an immature technology stack.