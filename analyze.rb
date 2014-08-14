require 'date'
require 'json'
require 'descriptive_statistics'
require 'duration'

require_relative 'issue'

def analyze(target)
  owner, repo = target.split("/")
  dir = "data/raw/#{owner}/#{repo}"
  filename = Dir.entries(dir).reject{|f| [".", ".."].include? f}.sort.last
  return if filename.nil?
  file_handle = File.open("#{dir}/#{filename}", "r")
  issues = Marshal.load(file_handle).values
  file_handle.close

  updated_at = filename.chomp(File.extname(filename)).to_i
  now = Time.now.utc
  one_week_ago  = now - 1.week
  two_weeks_ago = now - 2.week
  last_24_hrs   = now - 1.day
  if now.month == 1
    last_month_start = Time.local(now.year-1, 12)
    last_month_end = Time.local(now.year, 1) - 1
  else
    last_month_start = Time.local(now.year, now.month-1)
    last_month_end = Time.local(now.year, now.month) -1
  end

  still_open = issues.select{|i| i.open?}
  closed_this_week = issues.select{|i| i.closed_during? one_week_ago}
  opened_this_week = issues.select{|i| i.opened_during? one_week_ago}
  opened_and_closed_this_week = opened_this_week.select{|i| i.closed?}
  opened_yesterday = issues.select{|i| i.opened_during? last_24_hrs}
  closed_last_week = issues.select{|i| i.closed_during? two_weeks_ago, one_week_ago}
  closed_last_month = issues.select{|i| i.closed_during? last_month_start, last_month_end}

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
          meta: {owner: owner, repo: repo, updated: updated_at, percentiles:[25,50,75,90]}
         }
  File.open("public/data/#{owner}_#{repo}.json", 'w'){|f| f.write data.to_json}
end

def duration_percentiles(issue_subset)
  durations = issue_subset.map{|i| i.duration}.sort!
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
    Dir.foreach("data/raw") do |owner|
      next if owner.start_with? '.'
      Dir.foreach("data/raw/#{owner}") do |repo|
        next if repo.start_with? '.'
        target = "#{owner}/#{repo}"
        $stderr.puts "Analyzing #{target}..."
        analyze target
      end
    end
  else
    ARGV.each do |target|
      $stderr.puts "Analyzing #{target}..."
      analyze target
    end
  end
end
