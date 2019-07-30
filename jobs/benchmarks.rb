require 'date'
require 'net/http'
require 'json'

thread = Thread.new {}
num_benchmarks_on_page = 9
benchmark_index = 0

SCHEDULER.every '1h', :first_in => 0 do |job|
	Thread.kill(thread)
	benchmark_titles = []
	labels = []
	# First get the number of benchmarks and title of benchmarks
	last_build_response = get_url(JENKINS_NIGHTLY_URL + '/lastSuccessfulBuild/api/json?')
	if (last_build_response == nil)
		raise StandardError, 'cannot get ' + JENKINS_NIGHTLY_URL + '/lastSuccessfulBuild/api/json?'
	end
	last_artifacts = last_build_response['artifacts']
	num_benchmarks = 0
	for artifact in last_artifacts do
		suite_url = JENKINS_NIGHTLY_URL + '/lastSuccessfulBuild/artifact/' + artifact['relativePath']
		suite_response = get_url(suite_url)
		if suite_response == nil
			raise StandardError, 'cannot get ' + suite_url
		end
		tests = suite_response['benchmarks']
		for test in tests do
			num_benchmarks += 1
			names = test['name'].split('/')
			title = names[0] + ":\n" + names[1]
			benchmark_titles.push(title)
		end
	end
	puts ("There are " + num_benchmarks.to_s + " benchmarks available.")
	# Initialize 2d array
	all_data = Array.new(num_benchmarks) {Array.new()}
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
			labels.push("no_data")
			all_data.each { |arr| arr.push(0) }
		else
			got_date_already = false
			# artifacts and suites are the same thing
			artifacts = build_response['artifacts']
			i = 0
			for artifact in artifacts do
				suite_url = build_url + 'artifact/' + artifact['relativePath']
				suite_response = get_url(suite_url)
				if suite_response == nil
					raise StandardError, 'cannot get ' + suite_url
				end
				tests = suite_response['benchmarks']
				for test in tests do
					all_data[i].push(test['items_per_second'].to_i)
					i += 1
				end
				# get date if haven't gotten it yet
				if not got_date_already
					date = Date.parse(suite_response['context']['date'][0,10])
					labels.push(date.strftime("%b %d"))
					got_date_already = true
				end
			end
		end
	end
	puts ('Benchmarks loaded')
	thread = Thread.new {
		loop do
			i = 0
			while i < num_benchmarks_on_page do
				bench_data = all_data[benchmark_index]
				random_r = rand(256)
				random_g = rand(256)
				random_b = rand(256)
				data = [
					{
						label: benchmark_titles[benchmark_index],
						data: bench_data,
						backgroundColor: [ "rgba(#{random_r}, #{random_g}, #{random_b}, 0.4)" ] * labels.length,
						borderColor: [ "rgba(#{random_r}, #{random_g}, #{random_b}, 1)" ] * labels.length,
						borderWidth: 1,
					}
				]
				trendPercentage = (((bench_data[bench_data.length-1] - bench_data[0]).to_f/bench_data[0])*100).round(2)
				cornertext = "30 Day Trend: " + trendPercentage.to_s + "%"
				send_event('benchmark'+(i+1).to_s, { title: benchmark_titles[benchmark_index], labels: labels, datasets: data , cornertext: cornertext, trendPercentage: trendPercentage})
				i += 1
				benchmark_index += 1
				if benchmark_index == num_benchmarks
					benchmark_index = 0
				end
			end
			#puts ('Benchmarks page sent')
			# number of seconds to sleep
			sleep(30)
		end
	}
end
