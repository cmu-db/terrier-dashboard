# Terrier Dashboard

## Demo on Heroku
https://nameless-lake-50241.herokuapp.com/builds
https://nameless-lake-50241.herokuapp.com/benchmarks

## Get started

1. Install [smashing](http://smashing.github.io/)
2. Clone this project and `bundle install`
3. `smashing start`
4. Duplicate the contents of '.env.template' file and rename the copy '.env'. If you surpass the maximum number of allowed GitHub http requests, fill in the GITHUB_LOGIN and GITHUB_OAUTH_TOKEN from your GitHub account.

Important Note: Smashing is a recent fork of Dashing, so any code created using Dashing will work interchangeably with Smashing. The command "dashing" can be replaced with the word "smashing" with no errors.

## Tutorial
This is a highly recommended tutorial to learn the basics of Smashing/Dashing:
https://vimeo.com/95307499
As mentioned before, the command "dashing" can be replaced with the command "smashing".

## How to create a new widget
Follow the steps [here](https://github.com/Shopify/dashing/wiki/Dashing-Workshop)
As mentioned before, any resources involving dashing will still work with smashing.

1. `smashing generate widget <widget-name>` This will create a folder under widgets with widget-name. It contains three files.
    - Modify `.html` file to structure the widget.
    - Modify `.scss` file to style the widget using [Scss](http://sass-lang.com/). 
    - Modify `.coffee` file to add dynamic UI using [CoffeeScript](http://coffeescript.org/).
2. `smashing generate job <job-name>` This will create a `.rb` file under `jobs` folder which is in charge of pulling the data into the widget.
    - It uses [rufus-scheduler](https://github.com/jmettraux/rufus-scheduler).
    - `config.rb` under jobs contains all constants needed for pulling data from Jenkins, Github and Coverall.

(Smashing uses [batman.js](http://batmanjs.org/) as its MVC framework.)

## How to create a new dashboard
1. `smashing generate dashboard <dashboard-name>`
2. Access it at `http://0.0.0.0:3030/<dashboard-name>`

## More useful widgets
- Progress bar: https://gist.github.com/mdirienzo/6716905
- Sparkline: https://gist.github.com/jorgemorgado/26068a72540619a4d4ec
- Timeline: https://github.com/aysark/dashing-timeline
- Rickshaw graph: https://gist.github.com/jwalton/6614023
- Line Charts: https://github.com/jorgemorgado/dashing-linechart
- Leaderboard: https://github.com/chillu/github-dashing
