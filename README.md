# Prereqs

* Install ruby
* Install bundler gem: `gem install bundler`
* Install project gems: `bundle install`

# Methodology

- ccTLD list - from Iana (https://www.iana.org/domains/root/db) filtered to country-code entries, names from Countries gem
- DS in root - based on dig for DS in .[TLD] against a.root-servers.net.
- RDAP - checked against RDAP bootstrap file, from https://data.iana.org/rdap/dns.json, then lookups attempted against nic.tld, the RDAP servername if within the zone, or a known exception.
- WHOIS - lookup using WHOIS for nic.[TLD] (which exists in most zones) against the whois server listed by IANA (whois.iana.org), with special-case coding for known exceptions (see WHOIS Notes). Some TLDs have been manually tested with other known domain names, particularly IDNs.

**Note** This is an evolving dataset, to submit clarifications or exceptions please raise an issue.

# Generating data

The script generate_data.rb produces a CSV based on a fresh scrape of the TLD list from IANA. The results are written to stdout, it is recommended to redirect output to a file e.g. `ruby generate_data.rb > protocol_support_data.csv`

# Visualisations

Separate scripts for producing visualisations are available in https://github.com/fleeblewidget/cctld-protocol-support-visualisation

# WHOIS Notes

WHOIS responses are very varied, and in particular the chosen search string for these metrics (nic.TLD) has some surprising responses for some TLDs and doesn't work for IDNS. In these cases, an attempt is made to match to a known server, otherwise fall back on exceptions coded into the scripts based on offline checking.

There is no timeout implemented, to allow for cases such as .do which takes approx. 15 minutes to respond (as measured from Vienna during the IETF 126 hackathon) but does eventually return a correct response.

A final note on WHOIS: the protocol is being replaced with RDAP and some registries have deprecated or removed it entirely. Therefore, WHOIS has not been included in groupings for registries which have RDAP.

# EPP Notes - in progress

EPP doesn't have a standard discoverability mechanism, and EPP servers are not publicly accessible. To try and determine the existence or otherwise of an EPP endpoint for a registry, the following steps have been followed.

1. CoCCA provides an EPP server, so all users are assumed to have EPP (https://cocca.org.nz/#Patrons)
2. FRED also provides an EPP server, so FRED users are also assumed to have EPP (https://fred.nic.cz/en/)
3. Newer open source registry Namingo is in use at .ye, this is therefore also assumed to include EPP
4. .as is being run by https://www.gdns.com/ but it is unclear whether this includes an EPP implementation, .as has been marked unknown
5. Clues can be found in WHOIS output which suggest provision from other backend registry operators who are presumed to provide EPP (see hunt-epp-in-whois script)
6. Any cases where the nic.TLD domain has client or server statuses reported in the WHOIS (e.g. serverDeleteProhibited) are assumed to have EPP

So far EPP is not represented in the dataset, it may be that gathering this data requires surveys or similar rather than a technical solution.

# Acknowledgements

Grateful thanks to Karl Dyson, Gordon Dick and Jim Galvin for feedback and guidance on early versions of this project.