# This script is just a quick hack to provide the get_url function to all of the other scripts in the jobs folder.
# It is named with an underscore because it needs to be the first file in alphabetical order in the jobs folder,
# so that the get_url function can be accessed by subsequent files.
require 'net/http'
require 'json'

def get_url(url, auth=nil, retries=3)
  uri = URI.parse(url)
  http = Net::HTTP.new(uri.host, uri.port)
  # response will timeout after 3 seconds, change if too fast
  http.open_timeout = 3

  if uri.scheme == 'https'
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  request = Net::HTTP::Get.new(uri.request_uri)

  if auth != nil then
    request.basic_auth *auth
  end

  response = http.request(request)
  
  # check for errors
  if (response.code != '200') 
    puts ('cannot access: ' + url + ' -- the build probably did not run properly')
    return nil
  end
  
  return JSON.parse(response.body)

rescue Net::OpenTimeout => e
  puts "TRY #{4-retries} ERROR #{e}: timed out while trying to connect to #{url}. Trying again..."
  if retries <= 1
    raise
  end
  get_url(url, auth, retries-1)
end


#Jenkins server base URL
JENKINS_URL = 'http://jenkins.db.cs.cmu.edu:8080/job/terrier/job/master'

#Jenkins Nightly URL
JENKINS_NIGHTLY_URL = 'http://jenkins.db.cs.cmu.edu:8080/job/terrier-nightly'

#change to true if Jenkins is using SSL
JENKINS_USING_SSL = false

#credentials of Jenkins user (give these values if the above flag is true)
JENKINS_AUTH = {
    'name' => nil,
    'password' => nil
}

#CodeCov URL
CODECOV_URL = 'https://codecov.io/api/gh/cmu-db/terrier'

# Number of days tracked for Coverage Chart
NUM_DAYS_TRACKED = 30

#Github
GITHUB_ORG = 'cmu-db'
GITHUB_REPO = 'terrier'