require 'open3'

# Configure exceptions - these have been tested separately and status determined based
# on a particular response.
#
# Y = WHOIS server exists and responds to other strings
# N = WHOIS server does not exist
#
# Format is: {TLD => ["Expected Text","Y/N"]}
known_exceptions = {
	"cn" => ["the Domain Name you apply can not be registered online. Please consult your Domain Name registrar", "Y"],
	"hk" => ["This domain is currently not available for registration. Please select other domain.", "Y"],
	"mm" => ["The queried object does not exist: DOMAIN NOT FOUND", "Y"],
	"qa" => ["The Domain Name is not Available", "Y"],
	"th" => ["No match found", "Y"],
	"vg" => ["The queried object does not exist: DOMAIN NOT FOUND", "Y"]
}

File.readlines('cctld-list.txt', chomp: true).each do |cctld|
	print "#{cctld},"

	# Check whether IANA lists a whois server
	tld_whois_server = `whois -h whois.iana.org #{cctld} | grep -ie "^whois: " | sed 's/whois:\s*//'`.chomp

	if tld_whois_server.empty?
		print "N - No WHOIS listed by IANA\n"
	else
		# Check the WHOIS server responds
		nic_tld = "nic.#{cctld}"
		stdout, stderr, status = Open3.capture3("whois -h #{tld_whois_server} #{nic_tld}")

		if status.success? && !stdout.empty?
			# Ensure the target is in the response
			if stdout.scrub(".") =~ /#{cctld}/i
				print "Y\n"
			else

				if stdout =~ /This TLD has no whois server/i
					print "N - Response states no whois server\n"
				else
					# Handle exceptions - known servers which handle nic.tld unusually
					if known_exceptions.has_key?(cctld) && stdout =~ /#{known_exceptions[cctld][0]}/
						print "#{known_exceptions[cctld][1]}\n"
					else
						# Bail, unknown response
						print "Unexpected output: "
						print stdout
					end
				end
			end
		else
			# Lookup failed, print error (or stdout if no error)
			print "N - #{(stderr.empty? ? stdout : stderr).chomp}\n"
		end
	end
end