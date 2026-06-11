require 'open3'

# This script hunts for hints at possible EPP server existence using info from WHOIS
#
# We can't prove a negative this way, so absence of hints is indicated with '?', not 'N'

File.readlines('cctld-list.txt', chomp: true).each do |cctld|
	print "#{cctld},"

	# Check whether IANA lists a whois server
	tld_whois_server = `whois -h whois.iana.org #{cctld} | grep -ie "^whois: " | sed 's/whois:\s*//'`.chomp

	if tld_whois_server.empty?
		print "? - No WHOIS listed by IANA\n"
	else
		# Check the WHOIS server responds
		nic_tld = "nic.#{cctld}"
		stdout, stderr, status = Open3.capture3("whois -h #{tld_whois_server} #{nic_tld}")

		# Replace any characters ruby might have a cow over with dots
		stdout.scrub!(".")

		if status.success?
			# See whether known backend registry providers are mentioned - if so, assume EPP
			case stdout
			when /CentralNIC/i
				print "Y - CentralNIC\n"
			when /identity\s*digital/i 
				print "Y - IdentityDigital\n"
			when /CoCCA/
				# CoCCA's ROIDs seem to have CoCCA in them, but matching specifically on case will hopefully weed out false positives
				print "Y - CoCCA\n"
			when /sidn.nl/
				# At least one TLD has sidn nameservers on their nic, implying SIDN are involved in operations and presumably providing EPP
				print "Y - SIDN\n"
			when /versign/i
				print "Y - Verisign\n"
			when /afnic/i
				print "Y - Afnic\n"
			when /tucows/i
				print "Y - Tucows\n"
			when /radix/i
				print "Y - Radix\n"
			when /cira/i
				print "Y - CIRA\n"
			when /nominet/i
				print "Nominet\n"
			when /registry.godaddy/i
				print "GoDaddy Registry\n"
			else
				if stdout =~ /[client|server][a-z]*[Prohibited|Hold]/
					print "Y - EPP statuses applied\n" 
				else
					print "? - Unable to determine backend status from whois\n"
				end
			end

		else
			# Lookup failed, game over
			print "N - Error from WHOIS\n"
		end
	end
end