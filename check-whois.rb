require 'open3'

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
				print "Unexpected output:"
				print stdout
			end
		else
			# Lookup failed, print error (or stdout if no error)
			print "N - #{(stderr.empty? ? stdout : stderr).chomp}\n"
		end
	end
end