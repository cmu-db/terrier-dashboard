require 'net/http'
require 'json'

# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every '1h', :first_in => 0 do |job|
  response = get_url CODECOV_URL
  
  send_event('coverage',
  { value: response["commits"][0]["totals"]["c"].to_f.round,
    moreinfo: "Last Commit: " + response["commits"][0]["author"]["username"]
  })
end
