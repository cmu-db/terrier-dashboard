SUCCESS = 'Successful'
FAILED = 'Failed'

def api_functions
  return {
    'Travis' => lambda { |build_id| get_travis_build_health build_id},
    'TeamCity' => lambda { |build_id| get_teamcity_build_health build_id},
    'Bamboo' => lambda { |build_id| get_bamboo_build_health build_id},
    'Go' => lambda { |build_id| get_go_build_health build_id},
    'Jenkins' => lambda { |build_id| get_jenkins_build_health build_id}
  }
end

def get_url(url, auth = nil)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.scheme == 'https'
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Get.new(uri.request_uri)

  if auth != nil then
    request.basic_auth *auth
  end

  response = http.request(request)
  #puts (response.code)
  # check for errors
  if (response.code != '200') 
    puts ('cannot access: ' + url + ' -- there is likely an issue with the api itself')
    return nil
  end

  return JSON.parse(response.body)
end

def calculate_health(successful_count, count)
  return (successful_count / count.to_f * 100).round
end

def get_build_health(build)
  api_functions[build['server']].call(build['id'])
end

def get_teamcity_build_health(build_id)
  builds = TeamCity.builds(count: 25, buildType: build_id)
  latest_build = TeamCity.build(id: builds.first['id'])
  successful_count = builds.count { |build| build['status'] == 'SUCCESS' }

  return {
    name: latest_build['buildType']['name'],
    status: latest_build['status'] == 'SUCCESS' ? SUCCESS : FAILED,
    link: builds.first['webUrl'],
    health: calculate_health(successful_count, builds.count)
  }
end

def get_travis_build_health(build_id)
  url = "https://api.travis-ci.org/repos/#{build_id}/builds?event_type=push"
  results = get_url url
  successful_count = results.count { |result| result['result'] == 0 }
  latest_build = results[0]

  return {
    name: 'Travis',
    status: latest_build['result'] == 0 ? SUCCESS : FAILED,
    duration: latest_build['duration'],
    link: "https://travis-ci.org/#{build_id}/builds/#{latest_build['id']}",
    health: calculate_health(successful_count, results.count),
    time: latest_build['started_at']
  }
end

def get_go_pipeline_status(pipeline)
  return pipeline['stages'].index { |s| s['result'] == 'Failed' } == nil ? SUCCESS : FAILED
end

def get_go_build_health(build_id)
  url = "#{Builds::BUILD_CONFIG['goBaseUrl']}/go/api/pipelines/#{build_id}/history"

  if ENV['GO_USER'] != nil then
    auth = [ ENV['GO_USER'], ENV['GO_PASSWORD'] ]
  end

  build_info = get_url url, auth

  results = build_info['pipelines']
  successful_count = results.count { |result| get_go_pipeline_status(result) == SUCCESS }
  latest_pipeline = results[0]

  return {
    name: latest_pipeline['name'],
    status: get_go_pipeline_status(latest_pipeline),
    link: "#{Builds::BUILD_CONFIG['goBaseUrl']}/go/tab/pipeline/history/#{build_id}",
    health: calculate_health(successful_count, results.count),
  }
end

def get_bamboo_build_health(build_id)
  url = "#{Builds::BUILD_CONFIG['bambooBaseUrl']}/rest/api/latest/result/#{build_id}.json?expand=results.result"
  build_info = get_url url

  results = build_info['results']['result']
  successful_count = results.count { |result| result['state'] == 'Successful' }
  latest_build = results[0]

  return {
    name: latest_build['plan']['shortName'],
    status: latest_build['state'] == 'Successful' ? SUCCESS : FAILED,
    duration: latest_build['buildDurationDescription'],
    link: "#{Builds::BUILD_CONFIG['bambooBaseUrl']}/browse/#{latest_build['key']}",
    health: calculate_health(successful_count, results.count),
    time: latest_build['buildRelativeTime']
  }
end

def get_jenkins_build_health(build_id)
  url = JENKINS_URL + '/api/json?tree=builds[url]'

  if ENV['JENKINS_USER'] != nil then
    auth = [ ENV['JENKINS_USER'], ENV['JENKINS_TOKEN'] ]
  end

  build_info = get_url URI.encode(url), auth
  if (build_info == nil)
    raise StandardError, 'cannot get ' + url
  end
  builds = build_info['builds']
  successful_count = 0
  failure_count = 0
  #logger = Logger.new(STDOUT)
  for build in builds do
    build_url = build['url'] + '/api/json?tree=result'
    single_build_info = get_url URI.encode(build_url), auth
    if (single_build_info == nil)
      failure_count += 1
      puts 'issue -- cannot get ' + build_url
    else
      if single_build_info['result'] == 'SUCCESS'
        successful_count += 1
      else
        failure_count += 1
      end
    end
    
  end

  latest_build_url = JENKINS_URL + '/lastBuild/api/json?tree=status,timestamp,id,result,duration,url,fullDisplayName'
  latest_build_info = get_url URI.encode(latest_build_url), auth
  if (latest_build_info == nil)
    raise StandardError, 'cannot access ' + latest_build_url
  end
  #logger.info(successful_count)
  #logger.info(failure_count)

  return {
    name: 'Jenkins',
    status: latest_build_info['result'] == 'SUCCESS' ? SUCCESS : FAILED,
    duration: latest_build_info['duration'] / 1000,
    link: latest_build_info['url'],
    health: calculate_health(successful_count, successful_count + failure_count),
    time: latest_build_info['timestamp']
  }
end

SCHEDULER.every '20s' do
  Builds::BUILD_LIST.each do |build|
    send_event(build['id'], get_build_health(build))
  end
end
