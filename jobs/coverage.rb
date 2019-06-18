require 'net/http'
require 'json'

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1h', :first_in => 0 do |job|
  uri = URI(CODECOV_URL)
  response = Net::HTTP.get(uri)
  #logger = Logger.new(STDOUT)
  #logger.info(response)
  d = JSON.parse(response)
  #logger.info(d["commits"]);
  send_event('coverage',
  { value: d["commits"][0]["totals"]["c"].to_f.round,
    moreinfo: "Last Commit: " + d["commits"][0]["author"]["username"]
  })
end
