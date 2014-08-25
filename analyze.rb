require 'date'
require 'json'
require 'csv'

require 'descriptive_statistics'
require 'duration'

require_relative 'issue'

def analyze(target)
  owner, repo = target.split("/")
  dir = "private/data/#{owner}/#{repo}"
  filename = Dir.entries(dir).reject{|f| [".", ".."].include? f}.sort.last
  return if filename.nil?
  file_handle = File.open("#{dir}/#{filename}", "r")
  issues = Marshal.load(file_handle).values
  file_handle.close

  updated_at = filename.chomp(File.extname(filename)).to_i
  now = Time.at(updated_at)
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
  this_year = Time.local(now.year)

  still_open = issues.select{|i| i.open?}
  closed_this_week = issues.select{|i| i.closed_during? one_week_ago}
  opened_this_week = issues.select{|i| i.opened_during? one_week_ago}
  opened_and_closed_this_week = opened_this_week.select{|i| i.closed?}
  opened_yesterday = issues.select{|i| i.opened_during? last_24_hrs}
  opened_last_week = issues.select{|i| i.opened_during? two_weeks_ago, one_week_ago}
  closed_last_week = issues.select{|i| i.closed_during? two_weeks_ago, one_week_ago}
  opened_last_month = issues.select{|i| i.opened_during? last_month_start, last_month_end}
  closed_last_month = issues.select{|i| i.closed_during? last_month_start, last_month_end}
  opened_this_year = issues.select{|i| i.opened_during? this_year}
  closed_this_year = issues.select{|i| i.closed_during? this_year}

  data = {this_week: {opened: opened_this_week.length,
                      opened_and_closed: opened_and_closed_this_week.length,
                      closed: closed_this_week.length,
                      duration_percentiles: duration_percentiles(closed_this_week),
                      opened_issues: opened_this_week.count{|i| !i.pr?},
                      opened_pulls: opened_this_week.count{|i| i.pr?},
                      comments_median: opened_this_week.map{|i| i.comment_count}.median.to_i,
                      comments_max: opened_this_week.map{|i| i.comment_count}.max,
                      name: "Last 7 Days",
                      start_time: one_week_ago.strftime("%Y-%m-%d")},
          last_week: {duration_percentiles: duration_percentiles(closed_last_week),
                      opened_issues: opened_last_week.count{|i| !i.pr?},
                      opened_pulls: opened_last_week.count{|i| i.pr?},
                      comments_median: opened_last_week.map{|i| i.comment_count}.median.to_i,
                      comments_max: opened_last_week.map{|i| i.comment_count}.max,
                      name: "Week Before That",
                      start_time: two_weeks_ago.strftime("%Y-%m-%d"),
                      end_time: one_week_ago.strftime("%Y-%m-%d")},
          last_month:{duration_percentiles: duration_percentiles(closed_last_month),
                      opened_issues: opened_last_month.count{|i| !i.pr?},
                      opened_pulls: opened_last_month.count{|i| i.pr?},
                      comments_median: opened_last_month.map{|i| i.comment_count}.median.to_i,
                      comments_max: opened_last_month.map{|i| i.comment_count}.max,
                      name: Date::MONTHNAMES[last_month_start.month],
                      start_time: last_month_start.strftime("%Y-%m-%d"),
                      end_time: last_month_end.strftime("%Y-%m-%d")},
          this_year:{duration_percentiles: duration_percentiles(closed_this_year),
                      opened_issues: opened_this_year.count{|i| !i.pr?},
                      opened_pulls: opened_this_year.count{|i| i.pr?},
                      comments_median: opened_this_year.map{|i| i.comment_count}.median.to_i,
                      comments_max: opened_this_year.map{|i| i.comment_count}.max,
                      name: "YTD",
                      start_time: this_year.strftime("%Y-%m-%d")},
          yesterday: {opened: opened_yesterday.length},
          now: {open: still_open.length},
          meta: {owner: owner, repo: repo, updated: updated_at, percentiles:[25,50,75,90], table_rows: %w[this_week last_week last_month this_year]}
         }
  File.open("public/data/#{owner}_#{repo}.json", 'w'){|f| f.write data.to_json}

  CSV.open("public/data/#{owner}_#{repo}_issues_open.csv", "w") do |csv|
    csv << ["timestamp", "opening", "count", "number", "title"]
    cur_open_sort(issues).each {|row| csv << row}
  end

  issues.sort_by!{|issue| issue.opened_at}
  CSV.open("public/data/#{owner}_#{repo}_durations.csv", "w") do |csv|
    csv << ["timestamp", "duration", "is_pr", "number", "title"]
    issues.each do |issue|
      csv << [issue.opened_at.to_i, issue.duration, issue.pr?, issue.number, issue.title]
    end
  end

end

def cur_open_sort(issues)
  by_open_time = issues.sort_by {|issue| issue.opened_at}
  by_close_time = issues.select{|issue| issue.closed?}.sort_by {|issue| issue.closed_at}
  cur_open = 0
  events = []
  until by_open_time.empty? && by_close_time.empty?
    if (by_open_time.first.opened_at < by_close_time.first.closed_at rescue by_close_time.empty?)
      issue = by_open_time.shift
      events << [issue.opened_at.to_i, true, cur_open += 1, issue.number, issue.title]
    else
      issue = by_close_time.shift
      events << [issue.closed_at.to_i, false, cur_open -= 1, issue.number, issue.title]
    end
  end
  events
end

def duration_percentiles(issue_subset)
  durations = issue_subset.map{|i| i.duration}.sort!
  { p25: durations.percentile(25),
    p50: durations.median,
    p75: durations.percentile(75),
    p90: durations.percentile(90)
  }
end

if __FILE__ == $0
  if ARGV.empty?
    Dir.foreach("private/data") do |owner|
      next if owner.start_with? '.'
      Dir.foreach("private/data/#{owner}") do |repo|
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
