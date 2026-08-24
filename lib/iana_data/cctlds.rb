require 'bundler/setup'

require 'nokogiri'
require 'open-uri'
require 'countries'

# This script expects a TLD row in the IANA output that looks roughly like this:
#<tr>
#  <td>
#    <span>
#      <a href="/domains/root/db/PUNYCODE_TLD.html">.DISPLAY_TLD</a>
#    </span>
#  </td>
#  <td data-label="Type">country-code</td>
#  <td data-label="Manager">REGISTRY MANAGER ORG</td>
#</tr>

module IanaData
  module Cctlds
    # These countries aren't recognised by the 'countries' gem
    OTHER_COUNTRY_NAMES = {
      'ac' => 'Ascension Island',
      'eu' => 'European Union',
      'su' => 'Soviet Union / Russia',
      'uk' => 'United Kingdom',
      # These ones are IDNs where the 'manager' name doesn't match the ascii label
      'xn--3e0b707e' => 'South Korea',
      'xn--90ae' => 'Bulgaria',
      'xn--fzc2c9e2c' => 'Sri Lanka',
      'xn--j1amh' => 'Ukraine',
      'xn--l1acc' => 'Mongolia',
      'xn--mgba3a4f16a' => 'Iran',
      'xn--mgbai9azgqp6j' => 'Pakistan',
      'xn--node' => 'Georgia',
      'xn--wgbh1c' => 'Egypt',
      'xn--xkc2al3hye2a' => 'Sri Lanka',
      'xn--ygbi2ammx' => 'Palestine, State of'
    }.freeze

    # These codes are in the ccTLD list but not in use
    DEFUNCT_CODES = %w[an tp].freeze

    def self.fetch
      iana_list = Nokogiri::HTML(URI.open('https://www.iana.org/domains/root/db'))

      # Slightly hacky way to try and get country names for IDN variants - build list of managers and names as we
      # go through, check IDNs against it. Should work for any TLD where the variant and ascii labels are listed
      # with exactly the same manager, so long as they appear earlier in the alphabet than xn--
      # (At present there are no IDNs for countries later in the list than xn)
      manager_hash = {}
      tlds = {}

      iana_list.css('table#tld-table tbody tr').each do |row|
        tld_data = row.css('td')
        next if tld_data.empty?

        type = tld_data[1].text.strip
        next unless type == 'country-code'

        punycode_label = tld_data[0].css('a').attr('href').text
                                    .gsub('/domains/root/db/', '')
                                    .gsub('.html', '')
                                    .strip
        display_label = tld_data[0].css('a').children.first.text.strip[1..-1]

        next if DEFUNCT_CODES.include?(display_label)

        manager = tld_data[2].text.strip
        lc_manager = manager.downcase

        country_name = resolve_country_name(punycode_label, lc_manager, manager_hash)
        manager_hash[lc_manager] = country_name if country_name != 'NAME NOT FOUND'

        tlds[punycode_label] = {
          label: display_label,
          punycode_label: punycode_label,
          manager: manager,
          country: country_name
        }
      end

      tlds
    end

    def self.resolve_country_name(punycode_label, lc_manager, manager_hash)
      if (country = ISO3166::Country.new(punycode_label))
        country.common_name
      elsif OTHER_COUNTRY_NAMES.key?(punycode_label)
        OTHER_COUNTRY_NAMES[punycode_label]
      elsif manager_hash.key?(lc_manager)
        manager_hash[lc_manager]
      else
        'NAME NOT FOUND'
      end
    end
    private_class_method :resolve_country_name
  end
end
