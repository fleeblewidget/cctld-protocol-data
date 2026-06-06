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
			# See whether CentralNIC is mentioned - if so, assume EPP
			if stdout =~ /CentralNIC/i
				print "Y - CentralNIC\n"
			else
				print "? - UNKNOWN OUTPUT: #{stdout}"
			end
		else
			# Lookup failed, game over
			print "N - Error from WHOIS\n"
		end
	end
end