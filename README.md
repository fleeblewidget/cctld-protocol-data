# Prereqs

* Install ruby
* Install bundler gem: `gem install bundler`
* Install project gems: `bundle install`

# Methodology

- ccTLD list - from Iana (https://www.iana.org/domains/root/db) filtered to country-code entries, names from Countries gem
- DS in root - based on dig for DS in .[TLD] against a.root-servers.net.
- RDAP - checked against RDAP bootstrap file, from https://data.iana.org/rdap/dns.json.
- WHOIS - lookup using WHOIS for nic.[TLD] (which exists in most zones) against the whois server listed by IANA (whois.iana.org), with special-case coding for known exceptions (see WHOIS Notes).

# Generating data
The script generate_data.rb produces a CSV based on a fresh scrape of the TLD list from IANA.

# WHOIS Notes
WHOIS responses are very varied, and in particular the chosen search string for these metrics (nic.TLD) has
some surprising responses for some TLDs and doesn't work for IDNS. In these cases, an attempt is made to match
to a known server, otherwise fall back on exceptions coded into the scripts based on offline checking.

A final note on WHOIS: the protocol is being replaced with RDAP and some registries have deprecated it. Therefore,
absence of WHOIS in registries which have RDAP is likely not a sign of an immature technology stack.

# EPP Notes
EPP doesn't have a standard discoverability mechanism, and EPP servers are not publicly accessible. To try and determine the existence or otherwise of an EPP endpoint for a registry, the following steps have been followed.

1. CoCCA provides an EPP server, so all users are assumed to have EPP (https://cocca.org.nz/#Patrons)
2. FRED also provides an EPP server, so FRED users are also assumed to have EPP (https://fred.nic.cz/en/)
3. Newer open source registry Namingo is in use at .ye, this is therefore also assumed to include EPP
4. .as is being run by https://www.gdns.com/ but it is unclear whether this includes an EPP implementation, .as has been marked unknown
5. Clues can be found in WHOIS output which suggest provision from other backend registry operators who are presumed to provide EPP (see hunt-epp-in-whois script)
6. Any cases where the nic.TLD domain has client or server statuses reported in the WHOIS (e.g. serverDeleteProhibited) are assumed to have EPP