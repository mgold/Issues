require 'time'
require 'fileutils'
require 'duration'

require_relative 'octokit_auth'
require_relative 'issue'

def download(target)
  owner, repo = target.split("/")
  dir = "private/data/#{owner}/#{repo}"
  FileUtils.mkdir_p dir
  files = Dir.entries(dir).reject{|f| [".", ".."].include? f}
  timestamps = files.map{|f| f.chomp(File.extname(f)).to_i }
  most_recent = Time.at(timestamps.max) rescue nil
  now = Time.now

  opts = {state: "all", per_page: 100}
  if most_recent
    puts "Unmarshalling old issues for #{target}..."
    file_handle = File.open("#{dir}/#{most_recent.to_i}.marshal", "r")
    issues = Marshal.load(file_handle)
    file_handle.close
    opts.merge! since: most_recent.utc.iso8601
    puts "Downloading recent issues for #{target}..."
  else
    issues = {}
    puts "Downloading all issues for #{target}..."
  end

  old_issue_count = issues.length
  new_or_updated_issue_count = 0
  additions = Octokit.issues(target, opts)
  last_response = Octokit.last_response
  loop do
    new_or_updated_issue_count += additions.length
    additions.map!{|sawyer_obj| Issue.new owner, repo, sawyer_obj}
    additions.each do |issue|
      issues[issue.number] = issue
    end
    break if last_response.rels[:next].nil?
    last_response = last_response.rels[:next].get
    additions = last_response.data
  end
  new_issue_count = issues.size - old_issue_count
  updated_issue_count = new_or_updated_issue_count - new_issue_count
  puts "#{target}: #{old_issue_count} old, #{new_issue_count} new, #{updated_issue_count} updated, #{issues.size} total."

  unless new_or_updated_issue_count == 0
    puts "Marshalling updated issues for #{target}..."
    filename = "#{dir}/#{now.to_i}.marshal"
    File.open(filename, 'w') {|f| f.write(Marshal.dump(issues)) }
  end
end

if __FILE__ == $0
  if ARGV.empty?
    Dir.foreach("private/data") do |owner|
      next if owner.start_with? '.'
      Dir.foreach("private/data/#{owner}") do |repo|
        next if repo.start_with? '.'
        target = "#{owner}/#{repo}"
        download target
      end
    end
  else
    ARGV.each {|target| download target}
  end
  puts "#{Octokit.ratelimit.remaining} remaining GitHub API queries"
end
