require 'time'
require 'fileutils'
require 'duration'

require_relative 'octokit_auth'
require_relative 'issue'

def download(target)
  owner, repo = target.split("/")
  dir = "data/raw/#{owner}/#{repo}"
  FileUtils.mkdir_p dir
  files = Dir.entries(dir).reject{|f| [".", ".."].include? f}
  timestamps = files.map{|f| f.chomp(File.extname(f)).to_i }
  most_recent = Time.at(timestamps.max) rescue nil
  now = Time.now
  cache_persistence = 3.hours

  opts = {state: "all", per_page: 100}
  if most_recent
    $stderr.puts "Unmarshalling old issues for #{target}..."
    file_handle = File.open("#{dir}/#{most_recent.to_i}.marshal", "r")
    issues = Marshal.load(file_handle)
    file_handle.close
    opts.merge! since: most_recent.utc.iso8601
    $stderr.puts "Downloading recent issues for #{target}..."
  else
    issues = {}
    $stderr.puts "Downloading all issues for #{target}..."
  end

  old_issue_count = issues.length
  new_issue_count = 0
  additions = Octokit.issues(target, opts)
  last_response = Octokit.last_response
  loop do
    new_issue_count += additions.length
    additions.map!{|sawyer_obj| Issue.new owner, repo, sawyer_obj}
    additions.each do |issue|
      issues[issue.number] = issue
    end
    break if last_response.rels[:next].nil?
    last_response = last_response.rels[:next].get
    additions = last_response.data
  end
  $stderr.puts "#{target}: #{old_issue_count} old, #{new_issue_count} new or updated, #{issues.size} total."
  print target unless new_issue_count == 0

  $stderr.puts "Marshalling updated issues for #{target}..."
  filename = "#{dir}/#{now.to_i}.marshal"
  File.open(filename, 'w') {|f| f.write(Marshal.dump(issues)) }
end


if __FILE__ == $0
  if ARGV.empty?
    Dir.foreach("data/raw") do |owner|
      next if owner.start_with? '.'
      Dir.foreach("data/raw/#{owner}") do |repo|
        next if repo.start_with? '.'
        target = "#{owner}/#{repo}"
        download target
      end
    end
  else
    ARGV.each {|target| download target}
  end
  $stderr.puts "#{Octokit.ratelimit.remaining} remaining GitHub API queries"
end
