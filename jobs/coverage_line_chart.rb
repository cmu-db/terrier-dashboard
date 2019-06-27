require 'date'
require 'net/http'
require 'json'

SCHEDULER.every '1h', :first_in => 0 do |job|
  # Get the labels
  labels = []
  today = Date.today
  d = today - NUM_DAYS_TRACKED
  while d < today do
    d += 1
    labels.push(d.strftime("%b %d"))
  end

  pageNumber = 1
  # get_url is defined in build_hearth.rb by the way
  response = get_url(CODECOV_URL + '/commits?page=' + pageNumber.to_s);
  if (response == nil)
    raise StandardError, 'cannot get ' + CODECOV_URL + '/commits?page=' + pageNumber.to_s
  end
  commits = response['commits']
  minDay = today - NUM_DAYS_TRACKED + 1
  covData = Array.new(NUM_DAYS_TRACKED, 0)
  isDone = false
  while commits != [] do
    for commit in commits do
      date = Date.parse(commit['timestamp'][0,10])
      if date <= minDay && commit['parent_totals'] != nil
        covData[0] = commit['parent_totals']['c']
        i = 0
      
        while i < NUM_DAYS_TRACKED do
          if covData[i] == 0
            covData[i] = covData[i-1]
          end
          i += 1
        end

        isDone = true
        break
      end
      index = date - minDay
      if covData[index] == 0 && commit['parent_totals'] != nil
        covData[index] = commit['parent_totals']['c']
      end
      
    end
    if isDone
      break
    end
    pageNumber += 1
    response = get_url(CODECOV_URL + '/commits?page=' + pageNumber.to_s);
    if (response == nil)
      puts ('issue -- cannot get ' + CODECOV_URL + '/commits?page=' + pageNumber.to_s + ' -- breaking for safety')
      break
    end
    commits = response['commits']
  end
  #puts covData

  data = [
    {
      label: 'Coverage',
      data: covData,
      backgroundColor: [ 'rgba(56, 255, 195, 0.2)' ] * labels.length,
      borderColor: [ 'rgba(56, 255, 195, 1)' ] * labels.length,
      borderWidth: 1,
    }
  ]

  cornertext = "Latest: " + covData[covData.length-1].to_f.round(1).to_s + "%"

  send_event('coverage_line_chart', { labels: labels, datasets: data, cornertext: cornertext })
end
