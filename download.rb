load 'octokit_auth.rb'
require 'time'
require 'fileutils'

def download(target)
  user, repo = target.split("/")
  dir = "data/raw/#{user}/#{repo}"
  FileUtils.mkdir_p dir
  files = Dir.entries(dir).reject{|f| [".", ".."].include? f}
  timestamps = files.map{|f| f.chomp(File.extname(f)).to_i }
  most_recent = Time.at(timestamps.max) rescue nil
  now = Time.now

  Octokit.auto_paginate = true
  cache_persistence = 6*60*60 # six hours
  filename = "#{dir}/#{now.to_i}.marshal"
  opts = {state: "all", sort: "created", direction: "asc"}

  if most_recent.nil?
    puts "Downloading all issues for #{target}..."
    issues = Octokit.issues(target, opts)
    puts "Marshalling all issues for #{target}..."
    File.open(filename, 'w') {|f| f.write(Marshal.dump(issues)) }
  elsif most_recent + cache_persistence >= now
    puts "Already downloaded #{target} recently!"
  else
    puts "Downloading recent issues for #{target}..."
    opts.merge! since: most_recent.utc.iso8601
    additions = Octokit.issues(target, opts)
    if additions.size == 0
      puts "No updates for #{target}."
      return
    end
    additions_hash = Hash[additions.map{|i| [i.number, i]}]
    puts "Downloaded #{additions_hash.size} updated issues for #{target}."

    puts "Unmarshalling old issues for #{target}."
    file_handle = File.open("#{dir}/#{most_recent.to_i}.marshal", "r")
    previous = Marshal.load(file_handle)
    file_handle.close

    puts "Marshalling updated issues for #{target}..."
    previous.map!{|i| additions_hash[i.attrs[:number]] || i}
    File.open(filename, 'w') {|f| f.write(Marshal.dump(previous)) }
  end
end

if __FILE__ == $0
  download(ARGV[0]) if ARGV[0]
end
