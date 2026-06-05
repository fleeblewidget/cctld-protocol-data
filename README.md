# Methodology

- ccTLD list - from Iana (https://www.iana.org/domains/root/db) filtered to country-code entries, cross-referenced with https://www.worldstandards.eu/other/tlds/ for country names
- DS in root - based on dig for DS in .[TLD] against a.root-servers.net
- RDAP - checked against RDAP bootstrap file, from https://www.iana.org/assignments/rdap-dns/rdap-dns.xhtml
- WHOIS - lookup using WHOIS for nic.[TLD] (which exists in most zones) against the whois server listed by IANA (whois.iana.org)

# Scripts
The included Ruby scripts can be used to generate fresh data. They require a newline-separated ccTLD list file (cctld-list.txt). The WHOIS checker requires the whois gem.

# WHOIS Notes

