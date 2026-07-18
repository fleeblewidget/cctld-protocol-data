require 'csv'
require_relative 'lib/checks/ds'
require_relative 'lib/iana_data/cctlds'

CHECKS = [Checks::DS]

# Get initial dataset from IANA
tld_data = IanaData::Cctlds.fetch

# Print headings for first row only
first_row = true

CSV($stdout) do |csv|
  tld_data.each_key do |cctld|
    CHECKS.each { |c| tld_data[cctld].merge(c.check(cctld)) }

    if first_row
      csv << tld_data[cctld].keys
      first_row = false
    end

    csv << tld_data[cctld].values
  end
end