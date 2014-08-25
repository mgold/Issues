#GitHub Issues Report
_A dashboard for repo owners trying to keep their issue backlogs in historical perspective._

#About
This project was made for the [Third Annual GitHub Data Challenge](https://github.com/blog/1864-third-annual-github-data-challenge). It was created by [one person](https://github.com/mgold) in about two weeks as a side project. While it's a bit rough around the edges, I think that it can provide valuable insight into issue histories.

_Issues Report_ is hosted on the project website linked at the top of the page. You can request a specific repo, or look at one of the ones already available. Once asked for, a repo is updated automatically every few hours.

The issue report itself contains several pieces of helpful information. At the top is a short summary in paragraph form. Then there are two tables that show how closed and open issues have changed over time. Then there are two plots showing the history of issues for the repo. The first shows, at any given date, how many issues were open? (Note that this does not take closures and reopenings into account, just the creation date and most recent closure date if the issue is closed.) The second plot shows, for any given date, how long issues opening on that date took before closing. Only closed issues are shown. There is a slider on the left that allows you to adjust the scale. You can hover over the plots to see the same data point across them, which will also create a link at the bottom to that issue page.

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
