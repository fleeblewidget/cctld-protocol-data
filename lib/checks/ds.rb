module Checks
  module DS
    def self.check(tld)
      result = `dig +time=5 +tries=2 +short DS #{tld}. @a.root-servers.net`
      { ds: result.empty? ? 'N' : 'Y' }
    end
  end
end
