File.readlines('cctld-list.txt', chomp: true).each do |tld|
	print "#{tld},"
  result=`dig +time=5 +tries=2 +short DS #{tld}. @a.root-servers.net`
  if result.empty?
  	puts "N"
  else
  	puts "Y"
  end
end