require 'date'
require 'net/http'
require 'json'

SCHEDULER.every '1h', :first_in => 0 do |job|
  response = get_url(JENKINS_NIGHTLY_URL + '/api/json?')
  if (response == nil)
    raise StandardError, 'cannot get ' + JENKINS_NIGHTLY_URL + '/api/json?'
  end
  builds = response['builds'].reverse
  tpcc_data = []
  labels = []
  for build in builds do
    build_url = build['url']
    build_response = get_url(build_url + 'artifact/script/micro_bench/tpcc_benchmark.json')
    #puts (build_response)
    if (build_response == nil)
      labels.push("no_data")
      tpcc_data.push(0)
    else
      date = Date.parse(build_response['context']['date'][0,10])
      labels.push(date.strftime("%b %d"))
      # The second data set in this array is ScaleFactor4WithLogging
      tpcc_data.push(build_response['benchmarks'][1]['items_per_second'].to_i)
    end
  end
  
  data = [
    {
      label: 'TPCC',
      data: tpcc_data,
      backgroundColor: [ 'rgba(255, 99, 132, 0.2)' ] * labels.length,
      borderColor: [ 'rgba(255, 99, 132, 1)' ] * labels.length,
      borderWidth: 1,
    }
  ]

  cornertext = "30 Day Trend: " + (((tpcc_data[tpcc_data.length-1] - tpcc_data[0]).to_f/tpcc_data[0])*100).round(2).to_s + "%"

  send_event('tpcc_line_chart', { labels: labels, datasets: data , cornertext: cornertext})
end
