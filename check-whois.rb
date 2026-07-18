require 'json'
require 'open3'
require 'open-uri'

# Configure exceptions - these have been tested separately and status determined based
# on a particular response.
#
# Y = WHOIS server exists and responds to other strings
# N = WHOIS server does not exist
#
# Format is: {TLD => ["Expected Text","Y/N"]}
KNOWN_EXCEPTIONS = {
	"cn" => ["the Domain Name you apply can not be registered online. Please consult your Domain Name registrar", "Y"],
	"hk" => ["This domain is currently not available for registration. Please select other domain.", "Y"],
	"mm" => ["The queried object does not exist: DOMAIN NOT FOUND", "Y"],
	"qa" => ["The Domain Name is not Available", "Y"],
	"th" => ["No match found", "Y"],
	"vg" => ["The queried object does not exist: DOMAIN NOT FOUND", "Y"],
	"xn--clchc0ea0b2g2a9gcd" => ["The domain name requested has usage restrictions applied to it. Please see your Registrar for more details.", "Y"],
	"xn--yfro4i67o" => ["The domain name requested has usage restrictions applied to it. Please see your Registrar for more details.", "Y"],
	"xn--fiqs8s" => ["the Domain Name you apply can not be registered online. Please consult your Domain Name registrar","Y"],
	"xn--fiqz9s" => ["the Domain Name you apply can not be registered online. Please consult your Domain Name registrar","Y"],
	"xn--j6w193g" => ["This domain is currently not available for registration. Please select other domain.","Y"],
	"xn--o3cw4h" => ["% No match found.","Y"],
	"xn--wgbl6a" => ["No Data Found","Y"]
}


# Try IANA first, but fall back on list from https://whoislist.org/whois_servers.json for TLDs not in the list
whoislist_servers = JSON.parse(URI.open('https://whoislist.org/whois_servers.json').read)

# IDN lookups are hard, because 'nic' needs translating into the appropriate language and the language isn't part
# of the IANA dataset. As a shortcut, if the whois server we're looking up against has already been checked, use
# that result and assume that IDN lookups also work. Note that this only works for TLDs earlier in the
# alphabet than xn-- (sorry again, Zambia)
checked_whois_servers = {}

File.readlines('cctld-list.txt', chomp: true).each do |cctld|
	print "#{cctld},"

	# Check whether IANA lists a whois server
	tld_whois_server = `whois -h whois.iana.org #{cctld} | grep -ie "^whois: " | sed 's/whois:\s*//'`.chomp

	if tld_whois_server.empty?
		# Check for an entry in whoislist
		if whoislist_servers.has_key?(cctld)
			tld_whois_server = whoislist_servers[cctld]
		else
			# Final effort - try operating system whois
			tld_whois_server = `whois #{cctld} | grep -ie "^whois: " | sed 's/whois:\s*//'`.chomp

			if tld_whois_server.empty?
				# Can't find a server
				puts "N - No WHOIS server found"
				next
			end
		end
	end

	# For IDNs, check whether we've already verified this server
	if cctld.start_with?("xn--") && checked_whois_servers.has_key?(tld_whois_server)
		puts "#{checked_whois_servers[tld_whois_server]} - previously checked server #{tld_whois_server}"
		next
	end

	# Check the WHOIS server responds
	nic_tld = "nic.#{cctld}"
  	stdout, stderr, status = Open3.capture3("whois -h #{tld_whois_server} #{nic_tld}")

	if status.success? && !stdout.empty?
		# Ensure the target is in the response
		if stdout.scrub(".") =~ /#{cctld}/i
			puts "Y"
			checked_whois_servers[tld_whois_server] = "Y"
		else

			if stdout =~ /This TLD has no whois server/i
				puts "N - Response states no whois server"
				checked_whois_servers[tld_whois_server] = "N"
			else
				# Handle exceptions - known servers which handle other domains but not nic.tld
				if KNOWN_EXCEPTIONS.has_key?(cctld) && stdout =~ /#{KNOWN_EXCEPTIONS[cctld][0]}/
					puts "#{KNOWN_EXCEPTIONS[cctld][1]}"
				else
					# Bail, unknown response
					puts "Unexpected output: "
					puts stdout
				end
			end
		end
	else
		# Lookup failed, print error (or stdout if no error)
		puts "N - #{(stderr.empty? ? stdout : stderr).chomp}"
		checked_whois_servers[tld_whois_server] = "N"
	end
end