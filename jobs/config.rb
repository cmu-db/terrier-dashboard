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