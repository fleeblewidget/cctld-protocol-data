# Methodology

- ccTLD list - from Iana (https://www.iana.org/domains/root/db) filtered to country-code entries, cross-referenced with https://www.worldstandards.eu/other/tlds/ for country names.
- DS in root - based on dig for DS in .[TLD] against a.root-servers.net.
- RDAP - checked against RDAP bootstrap file, from https://data.iana.org/rdap/dns.json.
- WHOIS - lookup using WHOIS for nic.[TLD] (which exists in most zones) against the whois server listed by IANA (whois.iana.org), with special-case coding for known exceptions (see WHOIS Notes).
- EPP servers - there is no standard discovery mechanism for EPP, the data for these has been manually gathered. Rough notes on this are in EPP Notes, however the quality of the data is not great and so "confirmed no EPP" is distinguished from "No EPP found" in the results. Anyone with personal knowledge of the existence of standards-compliant EPP servers for TLDs of unknown status is welcome to raise an issue to request an update.

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

# EPP Notes
EPP doesn't have a standard discoverability mechanism, and EPP servers are not publicly accessible. To try and determine the existence or otherwise of an EPP endpoint for a registry, the following steps have been followed.

1. CoCCA provides an EPP server, so all users are assumed to have EPP (https://cocca.org.nz/#Patrons)
2. FRED also provides an EPP server, so FRED users are also assumed to have EPP (https://fred.nic.cz/en/)
3. Newer open source registry Namingo is in use at .ye, this is therefore also assumed to include EPP