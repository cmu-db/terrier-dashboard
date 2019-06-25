=begin
require 'octokit'

SCHEDULER.every '1h', :first_in => 0 do |job|
  client = Octokit::Client.new(
    :login => ENV['GITHUB_LOGIN'],
    :access_token => ENV['GITHUB_OAUTH_TOKEN']
  )
  my_organization = GITHUB_ORG
  repo = GITHUB_REPO

  # Placing all the open pull requests from specified repo into "pulls"
  pulls = []
  client.pull_requests("#{my_organization}/#{repo}", :state => 'open').each do |pull|
        pulls.push({
          title: pull.title,
          repo: repo,
          updated_at: pull.updated_at.strftime("%b %-d %Y, %l:%m %p"),
          creator: "@" + pull.user.login,
          })
  end
  
  send_event('github_open_pr', { header: "Pull Requests", pulls: pulls.first(7) })
end
=end