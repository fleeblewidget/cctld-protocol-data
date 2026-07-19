module Checks
  module DS
    def self.check(tld)
      load_algorithm_table unless @algorithm_table

      result = `dig +time=5 +tries=2 +short DS #{tld}. @a.root-servers.net`

      if result.empty?
        return { ds: 'N', ds_algorithm_number: 'n/a', 
                 ds_algorithm_name: 'n/a', ds_algorithm_status: 'n/a' }
      end

      # DS format: keytag algorithm digesttype digest
      # Take algorithm from first DS record
      algorithm_number = result.lines.first.split[1].to_i
      algorithm_info = @algorithm_table[algorithm_number] || 
                       { mnemonic: 'UNKNOWN', signing_use: 'UNKNOWN' }

      {
        ds: 'Y',
        ds_algorithm_number: algorithm_number,
        ds_algorithm_name: algorithm_info[:mnemonic],
        ds_algorithm_status: algorithm_info[:signing_use]
      }
    end

    def self.load_algorithm_table
      require 'csv'
      require 'open-uri'

      expected_columns = ['Number', 'Mnemonic', 'Use forDNSSEC Signing']
  
      csv_data = CSV.parse(
        URI.open('https://www.iana.org/assignments/dns-sec-alg-numbers/dns-sec-alg-numbers-1.csv').read,
        headers: true
      )

      missing = expected_columns - csv_data.headers
      if missing.any?
        raise "IANA algorithm CSV is missing expected columns: #{missing.join(', ')}\n" \
          "Found columns: #{csv_data.headers.join(', ')}"
      end

      @algorithm_table = {}
      csv_data.each do |row|
        num = row['Number'].to_i
        @algorithm_table[num] = {
          mnemonic: row['Mnemonic'],
          signing_use: row['Use forDNSSEC Signing']
        }
      end
    end
    private_class_method :load_algorithm_table
  end
end
