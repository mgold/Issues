load 'octokit_auth.rb'

def download(target)
  user, repo = target.split("/")
  filename = "data/raw/#{user}_#{repo}.marshal"
  if File.file?(filename)
    puts "Already downloaded #{target}!"
  else
    Octokit.auto_paginate = true
    issues = Octokit.issues(target, state: "all", sort: "created", direction: "asc")
    File.open(filename, 'w') {|f| f.write(Marshal.dump(issues)) }
  end
end

if __FILE__ == $0
  download(ARGV[0]) if ARGV[0]
end
