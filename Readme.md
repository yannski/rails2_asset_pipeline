# Rails 2 Asset pipeline

Familiar asset handling for those stuck on Rails 2.

 - sprockets/coffee/sass etc goodness
 - application.js?time for development
 - application-MD5.js for production  (and development without config.ru, read from public/assets/manifest.json)
 - old asset versions can stay around during deploys
 - converter for jammit asset.yml
 - no forced monkey-patching, everything is opt-in

[Example application](https://github.com/grosser/rails2_asset_pipeline_exmaple)

# Usage

```
rake assets:precompile
rake assets:clean
rake assets:remove_old      # Keeps current + 2 older versions in public/assets
rake assets:convert_jammit  # reads config/assets.yml and converts packs into `app/assets/<type>/<pack>.js` with `//= require <dependency>`
```

```Erb
With ViewHelpers included you can:
<%= stylesheet_link_tag "application" %>
<%= javascript_include_tag "application" %>
<%= image_tag "foo.jpg" %> <-- will go to public if you set Rails2AssetPipeline::ViewHelpers.ignored_folders = ["images"]
From good old public <%= javascript_include_tag "/javascripts/application.js" %>
Just a path: <%= asset_path "application.js" %>
```


# Install

    gem install rails2_asset_pipeline

    # config/environment.rb
    config.gem "rails2_asset_pipeline"

    # Gemfile (if you have one)
    gem "rails2_asset_pipeline"

    group :development do
      gem "coffee-script", :require => false # need coffee ?
      gem "sass", :require => false # need sass ?
      gem "sprockets-sass", :require => false
    end


### Initializer
Here you can do configuration of sprockets.
 - loaded in `rake assets:precompile` **without** the rails environment (to enable compiling/deploying without development environment)
 - configure sprockets
 - require sprockets extensions like sprockets/sass

```Ruby
# config/initializers/rails2_asset_pipeline.rb
if Rails.env.development? # dynamic asset compilation needs these
  require 'coffee-script' # need coffee ?
  require 'sprockets/sass' # need sass ?
  autoload :Sass, 'sass' # autoload when used via rake assets:precompile
  require 'sprockets/source_url' # sprockets-source_url for debugable assets in chrome
end

# Use a different path for assets (as in config.assets.prefix from ")
# Rails2AssetPipeline.prefix = 'static_assets'

Rails2AssetPipeline.setup do |sprockets|
  # ... additional config ...
end

# let image_tag still go to public/images
require 'rails2_asset_pipeline/view_helpers'
Rails2AssetPipeline::ViewHelpers.ignored_folders = ["images"]
```

Optional: remove unnecessary Sass middleware + monkey-patches

```Ruby
# config/environment.rb
...

module Sass; RAILS_LOADED = true; end # prevent sass middleware + monkeypatches -> all handled by rails2_asset_pipeline (verify via: rake middleware | grep Sass)

Rails::Initializer.run do
...
```

### Tasks

    # Rakefile
    begin
      require "rails2_asset_pipeline/tasks"
    rescue LoadError
      puts "rails2_asset_pipeline is not installed, you probably should run 'rake gems:install' or 'bundle install'."
    end

### Dynamic assets for development
Setup a config.ru so development has dynamic assets

```Ruby
# config.ru
# we need to protect against multiple includes of the Rails environment (trust me)
require './config/environment' if !defined?(Rails) || !Rails.initialized?

Rails2AssetPipeline.config_ru(self)

map '/' do
  use Rails::Rack::LogTailer unless Rails.env.test?
  # use Rails::Rack::Debugger unless Rails.env.test?
  use Rails::Rack::Static
  run ActionController::Dispatcher.new
end
```

### View helpers
```
# app/helpers/application_helper.rb
require 'rails2_asset_pipeline/view_helpers'
module ApplicationHelper
  include Rails2AssetPipeline::ViewHelpers
  ...
end
```

### Static code
You can also use `Rails2AssetPipeline::ViewHelpers.asset_path("application.js")`

### Fast tests
To not compile assets during testing you can overwrite the manifest.

```Ruby
# spec/fixtures/empty_manifest.json
{"assets": {}, "files": {}}

# spec/spec_helper.rb
Rails2AssetPipeline.manifest = Rails.root.join("spec/fixtures/empty_manifest.json")
```

### Images vs CSS

    /* application.css */
    .image_via_sass_url{
      background: url('ok.gif');
    }

    /* application.css.erb ... not recommended but possible ... */
    .image_with_erb{
      background-image:url(<%= asset_data_uri 'ok.gif' %>);
    }

### Sass
 - add `sass` to your gems for sass parsing
 - add `sprockets-sass` to your gems for sass @import support

### Sprockets Helpers

If you'd like to use sprocket helpers in your stylesheets, you have to add the sprockets-helpers gem and configure it in your initializer.

    # Gemfile (if you have one)
    gem "rails2_asset_pipeline"

    group :development do
      gem "coffee-script", :require => false # need coffee ?
      gem "sass", :require => false # need sass ?
      gem "sprockets-sass", :require => false
      gem "sprockets-helpers", :require => false
    end

```Ruby
# config/initializers/rails2_asset_pipeline.rb
if Rails.env.development? # dynamic asset compilation needs these
  require 'coffee-script' # need coffee ?
  require 'sprockets/sass' # need sass ?
  autoload :Sass, 'sass' # autoload when used via rake assets:precompile
  # require 'sprockets/source_url' # sprockets-source_url for debugable assets in chrome
end

require 'sprockets-helpers'

# Use a different path for assets (as in config.assets.prefix from ")
# Rails2AssetPipeline.prefix = 'static_assets'

Rails2AssetPipeline.setup do |sprockets|
  # ... additional config ...
  Sprockets::Helpers.configure do |config|
    config.environment = sprockets
    config.prefix = "/assets"
    config.digest = Rails.env.production? || Rails.env.staging?
  end
end
```

# Todo
 - read config from Rails 3 style config.assets
 - sprockets 2.8 wants to use manifest-digest.json, had to overwrite that, find out if nonpstatic manifest makes sense for us and potentially have an option to turn it on

Author
======

### [Contributors](https://github.com/grosser/rails2_asset_pipeline/contributors)
 - [Michael Peteuil](https://github.com/mpeteuil)
 - [Elia Schito](https://github.com/elia)
 - [Massimo Maino](https://github.com/maintux)
 - [Sakumatti Luukkonen](https://github.com/sluukkonen)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>
[![Build Status](https://secure.travis-ci.org/grosser/rails2_asset_pipeline.png)](http://travis-ci.org/grosser/rails2_asset_pipeline)
