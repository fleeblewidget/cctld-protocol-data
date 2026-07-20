require 'json'
require 'open-uri'
require 'net/http'

module Checks
  module RDAP
    # These don't respond to nic.TLD and the RDAP server is in a separate
    # zone, so we use known good names instead
    KNOWN_EXCEPTIONS = {
      'vg' => 'news.vg',
      'fj' => 'gov.fj'
    }.freeze

    def self.check(tld)
      load_bootstrap unless @rdap_servers

      unless @rdap_servers.key?(tld)
        return { rdap: 'N', rdap_error_detail: 'Not in IANA bootstrap list' }
      end

      result = nil
      @rdap_servers[tld].each do |url|
        result = probe(url.chomp('/'), tld)
        break if result == :ok
      end

      result == :ok \
        ? { rdap: 'Y', rdap_error_detail: 'n/a' }
        : { rdap: 'N', rdap_error_detail: result }
    end

    # -- private --

    def self.load_bootstrap
      bootstrap = JSON.parse(URI.open('https://data.iana.org/rdap/dns.json').read)
      @rdap_servers = {}
      bootstrap['services'].each do |tlds, urls|
        tlds.each { |tld| @rdap_servers[tld] = urls }
      end
    end

    def self.probe(base_url, tld)
      response = query(base_url, "nic.#{tld}")
      response = resolve_404(response, base_url, tld) if response.code.to_i == 404
      validate(response, base_url)
    rescue OpenSSL::SSL::SSLError => e
      "SSL error: #{e.message}"
    rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ETIMEDOUT,
           Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET
      "Server #{base_url} unreachable"
    rescue JSON::ParserError
      'Unparseable response'
    end

    def self.resolve_404(response, base_url, tld)
      # Check it's a proper RDAP 404, not a misconfigured web server
      data = JSON.parse(response.body) rescue nil
      return response unless data && data['errorCode'] == 404

      # Try RDAP server's own domain if it's within the zone
      better = try_server_domain(base_url, tld)
      return better if better

      # Try known exceptions
      if KNOWN_EXCEPTIONS.key?(tld)
        exception_domain = KNOWN_EXCEPTIONS[tld]
        $stderr.puts "404 on nic.#{tld}, trying known exception #{exception_domain}"
        candidate = query(base_url, exception_domain)
        return candidate if candidate.code.to_i == 200
      else
        $stderr.puts "404 from #{base_url}, no alternatives available"
      end

      response  # return original 404 if nothing worked
    end

    def self.try_server_domain(base_url, tld)
      server_host = URI.parse(base_url).host
      return nil unless server_host.end_with?(".#{tld}")

      labels = server_host.split('.')

      last_attempt = "nic.#{tld}"

      [labels.last(2), labels.last(3)].uniq.each do |label_set|
        domain = label_set.join('.')
        $stderr.puts "404 on #{last_attempt} at #{base_url}, trying #{domain}"
        last_attempt = domain
        candidate = query(base_url, domain)
        return candidate if candidate.code.to_i == 200
      end

      nil
    end

    def self.validate(response, base_url)
      return "Bad status: #{response.code}" unless response.code.to_i == 200

      data = JSON.parse(response.body)
      unless data['objectClassName'] || data['ldhName']
        raise "Unrecognised content from #{base_url}"
      end

      :ok
    end

    def self.query(base_url, domain)
      uri = URI("#{base_url}/domain/#{domain}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 5
      http.read_timeout = 10
      http.max_retries = 0  # we handle retries ourselves via multiple URLs
      http.get(uri.request_uri, { 'Accept' => 'application/rdap+json' })
    end

    private_class_method :load_bootstrap, :probe, :resolve_404,
                         :try_server_domain, :validate, :query
  end
end