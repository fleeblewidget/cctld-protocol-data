require 'nokogiri'
require 'open-uri'
require 'countries'

# These countries aren't recognised by the 'countries' gem
OTHER_COUNTRY_NAMES = {
  'ac' => 'Ascension Island',
  'eu' => 'European Union',
  'su' => 'Soviet Union / Russia',
  'uk' => 'United Kingdom'
}

# These codes are in the ccTLD list but not in use
DEFUNCT_CODES = ['an','tp']

iana_list = Nokogiri::HTML(URI.open('https://www.iana.org/domains/root/db'))

# Expected format - TLD, type, manager

# Slightly hacky way to try and get country names for IDN variants - build list of managers and names as we go through,
# check IDNs against it. Should work for any TLD where the variant and ascii labels are listed with exactly the same
# manager, so long as they appear earlier in the alphabet than xn-- (sorry, Zambia)
manager_hash = {}

iana_list.css('table#tld-table tbody tr').each do |tld|
  tld_data = tld.css('td')
  next if tld_data.empty?
  
  type = tld_data[1].text.strip
  next unless type == 'country-code'

  # At time of writing, each TLD has a link to a details page in format /domains/root/db/LABEL.html
  # This label is punycode which is handy for other processing
  punycode_label = tld_data[0].css('a').attr('href').text.gsub('/domains/root/db/','').gsub('.html','').strip
  # Grab display label, omitting initial dot
  display_label = tld_data[0].css('a').children.first.text.strip[1..-1]
  
  next if DEFUNCT_CODES.include?(display_label)

  manager = tld_data[2].text.strip

  # Use countries gem to get official name - provided label is a valid code
  country_name = 'NAME NOT FOUND'
  if country = ISO3166::Country.new(display_label)
    # TODO - handle punycode better
    country_name = country.common_name
  elsif OTHER_COUNTRY_NAMES.has_key?(display_label)
    country_name = OTHER_COUNTRY_NAMES[display_label]
  end

  lc_manager_string = manager.downcase

  if country_name != 'NAME NOT FOUND'
    # Only add to the hash if we found the name in the official list or hacky list
    manager_hash[lc_manager_string] = country_name
  else
    # If we haven't got the name yet, try the manager lookup
    if manager_hash.has_key?(lc_manager_string)
      country_name = manager_hash[lc_manager_string]
    end
  end

  puts "#{display_label},#{punycode_label},#{manager},#{country_name}"
end