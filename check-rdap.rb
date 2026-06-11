require 'json'
require 'open-uri'
require 'net/http'

# Configure exception - this doesn't respond to nic.TLD and the RDAP server
# is in a separate zone so we can't use that, so use a known good name
# (at time of writing)
#
# Format is: {TLD => name}
KNOWN_EXCEPTIONS = {
	"vg" => "news.vg",
	"fj" => "gov.fj"
}

# Utility method to open a connection and send a request
def send_request(url)
	uri = URI(url)
  	http = Net::HTTP.new(uri.host, uri.port)
  	http.use_ssl = (uri.scheme == 'https')
  	http.open_timeout = 5
  	http.read_timeout = 10
  	http.max_retries = 5

  	return http.get(uri.request_uri, { 'Accept' => 'application/rdap+json' })
end

# Utility method to check response for an RDAP server at the given URL
def probe_rdap(base_url, cctld)
	# Most RDAP servers will have a record for nic.TLD
	response = send_request("#{base_url}/domain/nic.#{cctld}")

  	if response.code.to_i == 404
  		# Check if it's an RDAP 404 - server works, just no record
  		data = JSON.parse(response.body) rescue nil
  		return "Bad status: #{response.code}" unless data && data['errorCode'] == 404

  		# If no record, try the RDAP server name itself if it's in the zone
  		# Note that it could be a second-level server (e.g. rdap.co.tld), so we'll try
  		# last 2 and last 3 labels
  		rdap_server = URI.parse(base_url).host

  		if rdap_server.end_with?(".#{cctld}")
  			rdap_server_labels = rdap_server.split('.')
	  		rdap_server_1st_level = rdap_server_labels.last(2).join('.')
	  		STDERR.puts("404 on nic.#{cctld} at #{base_url}, trying #{rdap_server_1st_level}")
  			response_rdap_server = send_request("#{base_url}/domain/#{rdap_server_1st_level}")

	  		if response_rdap_server.code.to_i == 200
	  			# Got a proper response, use that and carry on
				response = response_rdap_server
			elsif rdap_server_labels.length > 2
				# Try second-level (if name long enough)
				rdap_server_2nd_level = rdap_server_labels.last(3).join('.')
				STDERR.puts("404 on #{rdap_server_1st_level} at #{base_url}, trying #{rdap_server_2nd_level}")
				response_rdap_server2 = send_request("#{base_url}/domain/#{rdap_server_2nd_level}")

				# Again, if get a proper response sub it into the logic and carry on
				response = response_rdap_server2 if response_rdap_server2.code.to_i == 200
			end
		end

		# If still have 404 after that, check if we've recorded an exception
		if response.code.to_i == 404 
			if KNOWN_EXCEPTIONS.has_key?(cctld)
				STDERR.puts("404 on nic.#{cctld} at #{base_url}, trying known exception #{KNOWN_EXCEPTIONS[cctld]}")
				response_exception = send_request("#{base_url}/domain/#{KNOWN_EXCEPTIONS[cctld]}")

				# Again, if get a proper response sub it into the logic and carry on
				response = response_exception if response_exception.code.to_i == 200
			else
				STDERR.puts("404 from #{base_url} but no alternatives work - bailing")
			end
		end
	end

  	return "Bad status: #{response.code}" unless response.code.to_i == 200

  	data = JSON.parse(response.body)
  	raise "Unrecognised content: #{data.inspect}" unless data['objectClassName'] || data['ldhName']

  	return :ok

rescue OpenSSL::SSL::SSLError => e
  	return "SSL error: #{e.message}"
rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT,
       Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET
  	return "Server #{base_url} unreachable"
rescue JSON::ParserError
  	return "Unparseable response #{response.body}"
end

# Build lookup: tld -> [server_urls]
rdap_bootstrap = JSON.parse(URI.open('https://data.iana.org/rdap/dns.json').read)
rdap_servers = {}
rdap_bootstrap["services"].each do |service|
  	tlds, urls = service[0], service[1]
  	tlds.each { |tld| rdap_servers[tld] = urls }
end

File.readlines('cctld-list.txt', chomp: true).each do |cctld|
  	print "#{cctld},"

  	unless rdap_servers.key?(cctld)
    		print "N - not in IANA bootstrap list\n"
    		next
  	end

  	# Try each server URL until one works
  	result = nil
  	rdap_servers[cctld].each do |url|
	    	result = probe_rdap(url.chomp('/'), cctld)
    		break if result == :ok
  	end

  	if result == :ok
	    	print "Y\n"
  	else
    		print "N - #{result}\n"
  	end
end