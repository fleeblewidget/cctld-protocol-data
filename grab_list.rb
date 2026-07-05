require 'nokogiri'
require 'open-uri'
require 'countries'

iana_list = Nokogiri::HTML(URI.open('https://www.iana.org/domains/root/db'))

# Expected format - TLD, type, manager
# TODO - check that we have the elements we expect

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
  
  manager = tld_data[2].text.strip

  # Use countries gem to get official name - provided label is a valid code
  # TODO handle others better
  country_name = 'NAME NOT FOUND'
  if country = ISO3166::Country.new(display_label)
    # TODO - handle punycode better
    country_name = country.common_name
  end

  puts "#{display_label},#{punycode_label},#{manager},#{country_name}"
end