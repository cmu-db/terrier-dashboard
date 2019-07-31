require 'json'
require 'time'
require 'dashing'
require 'octokit'
require 'active_support'
require 'active_support/core_ext'
require File.expand_path('../../lib/helper', __FILE__)
require File.expand_path('../../lib/leaderboard', __FILE__)

SCHEDULER.every '1h', :first_in => '1s' do |job|
	backend = GithubBackend.new()
	leaderboard = Leaderboard.new(backend)

	leaderboard_weighting = "issues_opened=1,issues_closed=0,pulls_opened=0,pulls_closed=0,pulls_comments=0,issues_comments=0,commits_comments=0,commits=0"

	weighting = leaderboard_weighting.split(',')
		.inject({}) {|c,pair|c.merge Hash[*pair.split('=')]}

	edits_weighting = (ENV['LEADERBOARD_EDITS_WEIGHTING'] || '').split(',')
			.inject({}) {|c,pair|c.merge Hash[*pair.split('=')]}

	days_interval = 30
	date_until = Time.now.to_datetime
	date_since = Time.at(date_until.to_i - days_interval.days)

	actors = leaderboard.get( 
		:days_interval => days_interval,
		:date_until => date_until,
		:orgas=>(ENV['ORGAS'].split(',') if ENV['ORGAS']), 
		:repos=>(ENV['REPOS'].split(',') if ENV['REPOS']),
		:weighting=>weighting,
		:edits_weighting=>edits_weighting,
		:skip_orga_members=>(ENV['LEADERBOARD_SKIP_ORGA_MEMBERS'].split(',') if ENV['LEADERBOARD_SKIP_ORGA_MEMBERS'])
	)
	# First 11 on leaderboard
	actors = actors[0..10]

	rows = actors.map do |actor|
		actor_github_info = backend.user(actor[0])

		if actor_github_info['avatar_url']
			actor_icon = actor_github_info['avatar_url'] + "&s=128"
		elsif actor_github_info['email']
			actor_icon = "http://www.gravatar.com/avatar/" + Digest::MD5.hexdigest(actor_github_info['email'].downcase) + "?s=128"
		else
			actor_icon = ''
		end

		trend = GithubDashing::Helper.trend_percentage(
			actor[1]['previous_score'], 
			actor[1]['current_score']
		)

		{
			nickname: actor[0],
			fullname: actor_github_info['name'],
			icon: actor_icon,
			current_score: actor[1]['current_score'],
			current_score_desc: '<strong>Score from current %d days period.</strong><br>%s' % [days_interval, actor[1]['current_desc']],
			previous_score: actor[1]['previous_score'],
			previous_score_desc: '<strong>Score from previous %d days period.</strong><br>%s' % [days_interval, actor[1]['previous_desc']],
			trend: trend,
			trend_class: GithubDashing::Helper.trend_class(trend),
			github: actor_github_info
		}
	end #if actors
	
	send_event('leaderboard_issues', {
		rows: rows,
		date_since: date_since.strftime("%b #{date_since.day}"),
		date_until: date_until.strftime("%b #{date_until.day}"),
	})
end
