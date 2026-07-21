require 'json'
require 'open3'
require 'open-uri'

module Checks
  module WHOIS
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
      "xn--wgbl6a" => ["No Data Found","Y"],
      "xn--4dbrk0ce" => ["Registration for this domain name is not allowed","Y"],
      "xn--80ao21a" => ["This server is maintained by KazNIC Organization, a ccTLD manager for Kazakhstan Republic.","Y"],
      "xn--90a3ac" => ["срб.срб","Y"], # TODO - automated check for U-label in output
      "xn--90ais" => ["бел.бел","Y"],
      "xn--d1alf" => ["мкд.мкд","Y"],
      "xn--kprw13d" => ["xn--kpry57d.xn--kpry57d","Y"],
      "xn--mgb9awbf" => ["No Data Found","Y"],
      "xn--mgbaam7a8h" => ["امارات.امارات has been reserved by aeDA Regulator","Y"],
      "xn--pgbs0dh" => ["تونس.تونس","Y"],
      "xn--y9a3aq" => ["Reserved name: Blocked governmental domain name","Y"]
    }.freeze

    def self.check(tld)
      # Try IANA first, but fall back on list from https://whoislist.org/whois_servers.json for TLDs not in the list
      @whoislist_servers ||= JSON.parse(URI.open('https://whoislist.org/whois_servers.json').read)

      # To save time, store list of servers which don't respond - if those ones are referenced for more than one
      # TLD, no point sending multiple requests
      @broken_whois_servers ||= []

    	# Check whether IANA lists a whois server
      tld_whois_server = `whois -h whois.iana.org #{tld} | grep -ie "^whois: " | sed 's/whois:\s*//'`.chomp

    	if tld_whois_server.empty?
		    # Check for an entry in whoislist
		    if @whoislist_servers.has_key?(tld)
          tld_whois_server = @whoislist_servers[tld]
		    else
          # Final effort - try operating system whois
          tld_whois_server = `whois #{tld} | grep -ie "^whois: " | sed 's/whois:\s*//'`.chomp

          if tld_whois_server.empty?
				    # Can't find a server
            return { whois: 'N', whois_detail: 'No whois server found' }
  		  	end
        end
      end

      # Bail if we already know this server doesn't work
      if @broken_whois_servers.any?(tld_whois_server)
        return { whois: 'N', whois_detail: "Known bad server #{tld_whois_server}" }
      end

      # Check the WHOIS server responds

      # If server is in the zone, use that
      whois_response, whois_response_detail = try_server_domain(tld_whois_server,tld)

      # Next testcase - nic.tld
      if whois_response == '?'
        whois_response, whois_response_detail = try_whois_lookup(tld_whois_server,"nic.#{tld}",tld)
      end

      if whois_response == "?"
        # Unknown response, try tld.tld
        whois_response, whois_response_detail = try_whois_lookup(tld_whois_server,"#{tld}.#{tld}",tld)
      end

      if whois_response == "N"
        @broken_whois_servers << "N"
      elsif whois_response == "?"
        $stderr.puts "Unexpected output for #{tld}: #{whois_response_detail}"
        whois_response_detail = "Unhandled exception"
      end        

      return { whois: whois_response, whois_detail: whois_response_detail }
    end

    def self.try_whois_lookup(server,domain,tld)
      stdout, stderr, status = Open3.capture3("whois -h #{server} #{domain}")

      whois_response = whois_response_detail = ""
      if status.success? && !stdout.empty?
        # Ensure the target is in the response
        if stdout.scrub(".") =~ /#{domain}/i
          whois_response = 'Y'
          whois_response_detail = 'Server available and responsive'
        else
          if stdout =~ /This TLD has no whois server/i
            whois_response = 'N'
            whois_response_detail = 'Response states no whois server'
          else
            # Handle exceptions - known servers which handle other domains but not nic.tld
            if KNOWN_EXCEPTIONS.has_key?(tld) && stdout =~ /#{KNOWN_EXCEPTIONS[tld][0]}/
              whois_response = KNOWN_EXCEPTIONS[tld][1]
              whois_response_detail = 'Manually tracked exception'
            else
              # Bail, unknown response
              whois_response = '?'
              whois_response_detail = "Unexpected output: #{stdout}"
            end
          end
        end
      else
        # Lookup failed, return error (or stdout if no error)
        whois_response = 'N'
        whois_response_detail = (stderr.empty? ? stdout : stderr).chomp
      end

      return whois_response, whois_response_detail
    end

    def self.try_server_domain(server_host, tld)
      return "?",nil unless server_host.end_with?(".#{tld}")

      labels = server_host.split('.')

      response = "?"
      detail = ""
      [labels.last(2), labels.last(3)].uniq.each do |label_set|
        domain = label_set.join('.')
        response, detail = try_whois_lookup(server_host, domain, tld)
        return response, detail if response == 'Y'
      end

      return response, detail
    end
    private_class_method :try_whois_lookup, :try_server_domain
  end
end