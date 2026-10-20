module Checks
  module IPv6
    def self.check(tld)
      STDERR.print "-> IPv6..."
      ns_records = `dig +short NS #{tld}.`
                 .lines.map(&:strip).reject(&:empty?)
                 .map { |ns| ns.chomp('.') }

      has_ipv6 = ns_records.any? do |ns|
        !`dig +short AAAA #{ns}`.strip.empty?
      end

      STDERR.puts "Done"

      { ipv6: has_ipv6 ? 'Y' : 'N' }
    end
  end
end