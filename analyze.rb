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

  closed_this_week_durations = closed_this_week.map{|i| duration(i)}.sort!
  ctwd_percentiles = { p25: closed_this_week_durations.percentile(25),
                       p50: closed_this_week_durations.median,
                       p75: closed_this_week_durations.percentile(75),
                       p90: closed_this_week_durations.percentile(90)
                     }

  closed_last_week_durations = closed_last_week.map{|i| duration(i)}.sort!
  clwd_percentiles = { p25: closed_last_week_durations.percentile(25),
                       p50: closed_last_week_durations.median,
                       p75: closed_last_week_durations.percentile(75),
                       p90: closed_last_week_durations.percentile(90)
                     }

  data = {this_week: {opened: opened_this_week.length,
                      opened_and_closed: opened_and_closed_this_week.length,
                      closed: closed_this_week.length,
                      duration_percentiles: ctwd_percentiles},
          last_week: {duration_percentiles: clwd_percentiles},
          yesterday: {opened: opened_yesterday.length},
          now: {open: still_open.length},
          meta: {user: user, repo: repo, updated: updated_at}
         }
  File.open("data/srv/#{user}_#{repo}.json", 'w'){|f| f.write data.to_json}
end

def duration(an_issue)
  (an_issue.closed_at - an_issue.created_at).to_i rescue nil
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
