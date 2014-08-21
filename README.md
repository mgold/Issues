#GitHub Issues Report
_A report/dashboard for repo owners trying to keep their issue backlogs in historical perspective._

#About
(to come)

#Roll your own
What, you want science to be reproducible? More likely you want to analyze your private repos. Clone the repository and then
* Add your credentials to `octokit_auth.rb`, e.g. `Octokit.configure {|c| c.login = 'foo'; c.password = 'bar' }`
* `mkdir -p private/data public/data`
* Set up cron to run `ruby download.rb && analyze.rb` (with absolute filepaths and redirected stdout) every few hours.
* Optionally, configure your server. Just running `rackup` should work fine for small loads. I'm using nginx and Phusion Passenger, [configured](https://www.phusionpassenger.com/documentation/Users%20guide%20Nginx.html#deploying_rails_to_sub_uri). Nginx serves files in /ghdata/public as if they were in /ghdata, but sinatra will take care of this if nginx doesn't.

#Community
##Contributing
The code is hacky enough that I don't intend to do long-term development or support, but if there's something that's driving you nuts, send a PR. If you need help getting your local install working, open an issue and I'll be happy to assist.

##Thanks
Thanks to the following open source projects on which I'm building: [Sinatra](http://www.sinatrarb.com/), [Nginx](http://nginx.org/), [Ruby](https://www.ruby-lang.org/), [D3](http://d3js.org/), and whatever is in the Gemfile. Thanks to Edward Tufte and Stephen Few, from whom I learned everything about data presentation and visualization. Thanks to GitHub for their API and Ruby [client](https://github.com/octokit/octokit.rb).
