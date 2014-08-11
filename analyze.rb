require 'sawyer'
load 'sawyer_monkeypatch.rb'
require 'json'
require 'descriptive_statistics'

def analyze(target)
  user, repo = target.split("/")
  dir = "data/raw/#{user}/#{repo}"
  filename = Dir.entries(dir).reject{|f| [".", ".."].include? f}.sort.last
  return if filename.nil?
  file_handle = File.open("#{dir}/#{filename}", "r")
  issues = Marshal.load(file_handle)
  file_handle.close

  updated_at = filename.chomp(File.extname(filename)).to_i
  now = Time.now.utc
  one_week_ago  = now - 60*60*24*7
  two_weeks_ago = now - 60*60*24*7*2
  last_24_hrs   = now - 60*60*24

  still_open = issues.select{|i| i.closed_at.nil?}
  closed_this_week = issues.select{|i| i.closed_at && i.closed_at > one_week_ago}
  i = issues.rindex{|i| i.created_at < one_week_ago}
  opened_this_week = issues[i+1..-1]
  opened_and_closed_this_week = opened_this_week.select{|i| !i.closed_at.nil?}
  i = issues.rindex{|i| i.created_at < last_24_hrs}
  opened_yesterday = issues[i+1..-1]
  closed_last_week = issues.select{|i| i.closed_at && i.closed_at < one_week_ago && i.closed_at > two_weeks_ago}
  closed_last_month = issues.select do |i|
    ca = i.closed_at
    ca && (now.month == 1 ? ca.month == 12 && ca.year == now.year-1 : ca.month == now.month && ca.year == now.year)
  end

  data = {this_week: {opened: opened_this_week.length,
                      opened_and_closed: opened_and_closed_this_week.length,
                      closed: closed_this_week.length,
                      duration_percentiles: duration_percentiles(closed_this_week),
                      name: "Last 7 days"},
          last_week: {duration_percentiles: duration_percentiles(closed_last_week),
                      name: "Week before that"},
          last_month:{duration_percentiles: duration_percentiles(closed_last_month),
                      name: Date::MONTHNAMES[now.month-1] || "December"},
          yesterday: {opened: opened_yesterday.length},
          now: {open: still_open.length},
          meta: {user: user, repo: repo, updated: updated_at, percentiles:[25,50,75,90]}
         }
  File.open("data/srv/#{user}_#{repo}.json", 'w'){|f| f.write data.to_json}
end

def duration(an_issue)
  (an_issue.closed_at - an_issue.created_at).to_i rescue nil
end

def duration_percentiles(issue_subset)
  durations = issue_subset.map{|i| duration(i)}.sort!
  { p25: durations.percentile(25),
    p50: durations.median,
    p75: durations.percentile(75),
    p90: durations.percentile(90)
  }
end

def cur_open_sort(issues)
  opened_at = issues.sort_by {|issue| issue.created_at}
  closed_at = closed.reject{|issue| issue.closed_at.nil?}.sort_by {|issue| issue.closed_at}
  cur_open = 0
  events = []
  until opened_at.empty? && closed_at.empty?
    if (opened_at.first.created_at < closed_at.first.closed_at rescue closed_at.empty?)
      item = opened_at.shift
      events << [item, cur_open += 1, true]
    else
      item = closed_at.shift
      events << [item, cur_open -= 1, false]
    end
  end
  events
end

if __FILE__ == $0
  if ARGV.empty?
    Dir.foreach("data/raw") do |user|
      next if user.start_with? '.'
      Dir.foreach("data/raw/#{user}") do |repo|
        next if repo.start_with? '.'
        target = "#{user}/#{repo}"
        puts "Analyzing #{target}..."
        analyze target
      end
    end
  else
    ARGV.each do |target|
      puts "Analyzing #{target}..."
      analyze target
    end
  end
end
