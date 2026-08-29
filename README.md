# Prereqs

* Install ruby
* Install bundler gem: `gem install bundler`
* Install project gems: `bundle install`

OR

Build and run Dockerfile and skip all that.

# Methodology

- ccTLD list - from Iana (https://www.iana.org/domains/root/db) filtered to country-code entries, names from Countries gem
- DS in root - based on dig for DS in .[TLD] against a.root-servers.net., algorithms cross-referenced against IANA recommendations list at https://www.iana.org/assignments/dns-sec-alg-numbers/dns-sec-alg-numbers.xhtml
- RDAP - checked against RDAP bootstrap file, from https://data.iana.org/rdap/dns.json, then lookups attempted against nic.tld, the RDAP servername if within the zone, or a known exception.
- WHOIS - lookup using WHOIS for nic.[TLD] (which exists in most zones) against the whois server listed by IANA (whois.iana.org), with special-case coding for known exceptions (see WHOIS Notes). Some TLDs have been manually tested with other known domain names, particularly IDNs.

**Note** This is an evolving dataset, to submit clarifications or exceptions please raise an issue.

# Generating data

The script generate_data.rb produces a CSV based on a fresh scrape of the TLD list from IANA. The results are written to stdout, it is recommended to redirect output to a file e.g. `ruby generate_data.rb > protocol_support_data.csv`

# Visualisations

Separate scripts for producing visualisations are available at https://github.com/fleeblewidget/cctld-protocol-support-visualisation

# WHOIS Notes

WHOIS responses are very varied, and in particular the chosen search string for these metrics (nic.TLD) has some surprising responses for some TLDs and doesn't work for IDNS. In these cases, an attempt is made to match to a known server, otherwise fall back on exceptions coded into the scripts based on offline checking.

There is no timeout implemented, to allow for some cases which can take up to 15 minutes to respond (as measured from Vienna during the IETF 126 hackathon) but do eventually return a correct response.

A final note on WHOIS: the protocol is being replaced with RDAP and some registries have deprecated or removed it entirely.

# EPP Notes - in progress

Automated provisioning is a very interesting element of registry stacks, however this data is not publicly accessible. The proposed RPP protocol may include a discoverability mechanism, but for the time being it may be that the only way to get this data is through separate research. This may be tackled in a later phase of the work.

# Acknowledgements

Grateful thanks to Karl Dyson, Gordon Dick and Jim Galvin for feedback and guidance on early versions of this project. Thankyou to Dan Q for help with Ruby build shenanigans. Any errors are my own - please let me know if you spot anything that can be improved!