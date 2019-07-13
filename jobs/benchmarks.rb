require 'date'
require 'net/http'
require 'json'

num_benchmarks = 9
suite_index_start = 0
test_index_start = 0

SCHEDULER.every '10s', :first_in => 0 do |job|
  suite_index_last = -1
  test_index_last = -1
  # Initialize empty arrays
  all_data = Array.new(num_benchmarks) {Array.new()}
  benchmark_titles = Array.new(num_benchmarks)
  # Get the labels
  labels = []
  today = Date.today
  d = today - NUM_DAYS_TRACKED
  while d < today do
    d += 1
    labels.push(d.strftime("%b %d"))
  end
  # Get all the benchmark data
  response = get_url(JENKINS_NIGHTLY_URL + '/api/json?')
  if (response == nil)
    raise StandardError, 'cannot get ' + JENKINS_NIGHTLY_URL + '/api/json?'
  end
  builds = response['builds'].reverse
  for build in builds do
    build_url = build['url']
    build_response = get_url(build_url + 'api/json?')
    if (build_response == nil || build_response['artifacts'] == [])
      all_data.each { |arr| arr.push(0) }
    else
      artifacts = build_response['artifacts']
      suite_index = suite_index_start
      test_index = test_index_start
      i = 0
      while i < num_benchmarks do
        suite_url = build_url + 'artifact/' + artifacts[suite_index]['relativePath']
        suite_response = get_url(suite_url)
        if suite_response == nil
          raise StandardError, 'cannot get ' + suite_url
        end
        test = suite_response['benchmarks'][test_index]
        all_data[i].push(test['items_per_second'].to_i)
        # find title of benchmark if not yet found
        if benchmark_titles[i] == nil
          names = test['name'].split('/')
          title = names[0] + ":\n" + names[1]
          benchmark_titles[i] = title
        end
        # find the next suite_index and test_index
        test_index += 1
        if test_index == suite_response['benchmarks'].length
          test_index = 0
          suite_index += 1
        end
        if suite_index == artifacts.length
          suite_index = 0
        end
        i += 1
      end
      suite_index_last = suite_index
      test_index_last = test_index
    end
  end
  suite_index_start = suite_index_last
  test_index_start = test_index_last
  i = 0
  while i < num_benchmarks do
    bench_data = all_data[i]
    random_r = rand(256)
    random_g = rand(256)
    random_b = rand(256)
    data = [
      {
        label: benchmark_titles[i],
        data: bench_data,
        backgroundColor: [ "rgba(#{random_r}, #{random_g}, #{random_b}, 0.2)" ] * labels.length,
        borderColor: [ "rgba(#{random_r}, #{random_g}, #{random_b}, 1)" ] * labels.length,
        borderWidth: 1,
      }
    ]
    cornertext = "30 Day Trend: " + (((bench_data[bench_data.length-1] - bench_data[0]).to_f/bench_data[bench_data.length-1])*100).round(2).to_s + "%"
    send_event('benchmark'+(i+1).to_s, { title: benchmark_titles[i], labels: labels, datasets: data , cornertext: cornertext})
    i += 1
  end
=begin  
  data = [
    {
      label: 'TPCC',
      data: tpcc_data,
      backgroundColor: [ 'rgba(255, 99, 132, 0.2)' ] * labels.length,
      borderColor: [ 'rgba(255, 99, 132, 1)' ] * labels.length,
      borderWidth: 1,
    }
  ]
=end
  #cornertext = "30 Day Trend: " + (((tpcc_data[tpcc_data.length-1] - tpcc_data[0]).to_f/tpcc_data[tpcc_data.length-1])*100).round(2).to_s + "%"

  #send_event('tpcc_line_chart', { labels: labels, datasets: data , cornertext: cornertext})
end
