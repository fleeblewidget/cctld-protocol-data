File.readlines('cctld-list.txt', chomp: true).each do |tld|
	print "#{tld},"
  result=`dig +short DS #{tld}. @a.root-servers.net`
  if result.empty?
  	print "N\n"
  else
  	print "Y\n"
  end
end