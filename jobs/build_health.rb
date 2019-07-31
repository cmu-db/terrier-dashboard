SUCCESS = 'Successful'
FAILED = 'Failed'

def calculate_health(successful_count, count)
  return (successful_count / count.to_f * 100).round
end

def get_travis_build_health(build_id)
  url = "https://api.travis-ci.org/repos/#{build_id}/builds?event_type=push"
  results = get_url url
  successful_count = results.count { |result| result['result'] == 0 }
  #latest_build = results[0]
  latest_build = nil
  for result in results do
    if result['branch'] == 'master'
      latest_build = result
      break
    end
  end
  if latest_build == nil
    puts ("Cannot find the latest travis build in the master branch. This might happen if there are no builds for the master branch in the latest 25 or so builds.")
  else
    #puts ("Lastest Travis master build is build#" + latest_build['number'])
  end

  return {
    name: 'Travis',
    status: latest_build['result'] == 0 ? SUCCESS : FAILED,
    duration: latest_build['duration'],
    link: "https://travis-ci.org/#{build_id}/builds/#{latest_build['id']}",
    health: calculate_health(successful_count, results.count),
    time: latest_build['started_at']
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
  if (latest_build_info['result'] == nil)
    puts 'issue -- cannot get result property at ' + latest_build_url
  end
  #puts latest_build_info

  return {
    name: 'Jenkins',
    status: latest_build_info['result'] == 'SUCCESS' ? SUCCESS : FAILED,
    duration: latest_build_info['duration'] / 1000,
    link: latest_build_info['url'],
    health: calculate_health(successful_count, successful_count + failure_count),
    time: latest_build_info['timestamp']
  }
end

SCHEDULER.every '1h', :first_in => 0 do |job|
  send_event("travis", get_travis_build_health("cmu-db/terrier"))
  send_event("jenkins", get_jenkins_build_health("not used currently"))
end
