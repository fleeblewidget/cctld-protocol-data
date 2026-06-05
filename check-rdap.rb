require 'json'

rdap_tld_file = File.read('rdap-bootstrap.json')
rdap_tld_hash = JSON.parse(rdap_tld_file)

rdap_tlds = []
rdap_tld_hash["services"].each do |tld|
	rdap_tlds << tld[0][0]
end

File.readlines('cctld-list.txt', chomp: true).each do |cctld|
	print "#{cctld},"
	if rdap_tlds.include?(cctld)
		print "Y\n"
	else
		print "N\n"
	end
end