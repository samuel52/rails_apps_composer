# Application template recipe for the rails_apps_composer. Change the recipe here:
# https://github.com/RailsApps/rails_apps_composer/blob/master/recipes/deployment.rb

prefs[:deployment] = multiple_choice "Prepare for deployment?", [["no", "none"],
    ["Heroku", "heroku"],
    ["Capistrano", "capistrano3"]] unless prefs.has_key? :deployment

if prefer :deployment, 'heroku'
  say_wizard "installing gems for Heroku"
  if prefer :database, 'sqlite'
    gsub_file 'Gemfile', /.*gem 'sqlite3'\n/, ''
    add_gem 'sqlite3', group: [:development, :test]
    add_gem 'pg', group: :production
  end
  stage_three do
    say_wizard "recipe stage three"
    case prefs[:email]
      when 'gmail'
        append_file 'app.json' do <<-TEXT
    "GMAIL_USERNAME": {
      "description": "Your Gmail address for sending mail.",
      "value": "user@example.com",
      "required": false
    },
    "GMAIL_PASSWORD": {
      "description": "Your Gmail password for sending mail.",
      "value": "changeme",
      "required": false
    },
TEXT
        end
      when 'sendgrid'
        append_file 'app.json' do <<-TEXT
    "SENDGRID_USERNAME": {
      "description": "Your SendGrid address for sending mail.",
      "value": "user@example.com",
      "required": false
    },
    "SENDGRID_PASSWORD": {
      "description": "Your SendGrid password for sending mail.",
      "value": "changeme",
      "required": false
    },
TEXT
        end
      when 'mandrill'
        append_file 'app.json' do <<-TEXT
    "MANDRILL_USERNAME": {
      "description": "Your Mandrill address for sending mail.",
      "value": "user@example.com",
      "required": false
    },
    "MANDRILL_APIKEY": {
      "description": "Your Mandrill API key for sending mail.",
      "value": "changeme",
      "required": false
    },
TEXT
      end
    end
    if prefer :authentication, 'omniauth'
      append_file 'app.json' do <<-TEXT
    "OMNIAUTH_PROVIDER_KEY": {
      "description": "Credentials from Twitter, Facebook, or another provider.",
      "value": "some_long_key",
      "required": false
    },
    "OMNIAUTH_PROVIDER_SECRET": {
      "description": "Credentials from Twitter, Facebook, or another provider.",
      "value": "some_long_key",
      "required": false
    },
TEXT
      end
    end
    if prefer :authentication, 'devise'
      append_file 'app.json' do <<-TEXT
    "ADMIN_EMAIL": {
      "description": "The administrator's email address for signing in.",
      "value": "user@example.com",
      "required": true
    },
    "ADMIN_PASSWORD": {
      "description": "The administrator's password for signing in.",
      "value": "changeme",
      "required": true
    },
    "DOMAIN_NAME": {
      "description": "Required for sending mail. Give an app name or use a custom domain.",
      "value": "myapp.herokuapp.com",
      "required": false
    },
TEXT
      end
    end
    if (!prefs[:secrets].nil?)
      prefs[:secrets].each do |secret|
        append_file 'app.json' do <<-TEXT
    "#{secret.upcase}": {
      "description": "no description",
      "required": false
    },
TEXT
        end
      end
    end
    append_file 'app.json' do <<-TEXT
    "RAILS_ENV": "production"
  }
}
TEXT
    end
    if File.exists?('db/migrate')
      gsub_file 'app.json', /"scripts": {/,
          "\"scripts\": {\"postdeploy\": \"bundle exec rake db:migrate; bundle exec rake db:seed\""
    end
  end
end

if prefer :deployment, 'capistrano3'
  say_wizard "installing gems for Capistrano"
  add_gem 'capistrano', '~> 3.0.1', group: :development
  add_gem 'capistrano-rvm', '~> 0.1.1', group: :development
  add_gem 'capistrano-bundler', group: :development
  add_gem 'capistrano-rails', '~> 1.1.0', group: :development
  add_gem 'capistrano-rails-console', group: :development
  stage_two do
    say_wizard "recipe stage two"
    say_wizard "installing Capistrano files"
    run 'bundle exec cap install'
  end
end

stage_three do
  ### GIT ###
  git :add => '-A' if prefer :git, true
  git :commit => '-qm "rails_apps_composer: prepare for deployment"' if prefer :git, true
end

__END__

name: deployment
description: "Prepare for deployment"
author: RailsApps

requires: [setup]
run_after: [init]
category: development
