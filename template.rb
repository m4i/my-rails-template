def indent(string, width = 2)
  string.gsub(/^(?=.)/, ' ' * width)
end

def deindent(string, width = nil)
  width ||= string.lines.grep(/./).map do |line|
    line[/^ */].length
  end.min || 0
  string.gsub(/^ {#{width}}/, '')
end

def append_trailing_newline(path)
  gsub_file path, /(?<=[^\n])\z/, "\n"
end

def rstrip_newline(path)
  gsub_file path, /\n+\z/, ''
end

def rstrip_duplicated_newline(path)
  gsub_file path, /\n+\z/, "\n"
end

def gem_group(*names, &block)
  if names.empty?
    yield
    append_trailing_newline 'Gemfile'
  else
    super
  end
end

def append_to_gitignore(line)
  unless @appended
    @appended = true
    spacer    = "\n"
  end
  append_to_file '.gitignore', "#{spacer}#{line}\n"
end

def bundle_path
  unless @bundle_path == false
    bundle_config_file = File.expand_path('../.bundle/config', __FILE__)
    @bundle_path ||=
      if File.exist?(bundle_config_file)
        require 'yaml'
        YAML.load_file(bundle_config_file)['BUNDLE_PATH']
      end || false
  end || nil
end

def use_slim?
  if @use_slim.nil?
    @use_slim = yes? 'do you want to use slim? [yN]:'
  end
  @use_slim
end

def use_mongoid?
  ENV['USE_MONGOID'] == 'true'
end

def disable_jbuilder?
  ENV['DISABLE_JBUILDER'] == 'true'
end




Bundler.with_clean_env do
  ENV.delete('GEM_HOME')

  begin
    git :init
    git commit: '--allow-empty -m "Initialize repository"'
  end


  begin
    git add: '.', commit: "-m 'Exec rails new #{File.basename(ARGV.first)} #{ARGV.drop(1).join(' ')}'"
  end


  begin
    append_to_gitignore '/public/assets/'
    git add: '.', commit: '-m "Add public/assets to .gitignore"'
  end


  begin
    if disable_jbuilder?
      comment_lines 'Gemfile', /gem 'jbuilder'/
      git add: '.', commit: '-m "Comment out jbuilder"'
    end
  end


  begin
    if use_slim?
      gem_group do
        gem 'slim-rails'
      end
      git add: '.', commit: '-m "Add slim-rails to Gemfile"'
    end
  end


  begin
    if use_mongoid?
      gem_group do
        gem 'mongoid', github: 'mongoid/mongoid'
        gem 'bson_ext'
      end
      git add: '.', commit: '-m "Add mongoid to Gemfile"'
    end
  end


  begin
    gem_group :development do
      gem 'better_errors'
      gem 'binding_of_caller' # for better_errors
      gem 'bullet'
      gem 'guard-rspec', require: false
      gem 'quiet_assets'
      gem 'rubocop-git', require: false
      gem 'thin'
    end

    gem_group :development, :test do
      gem 'awesome_print'
      gem 'hirb-unicode'
      gem 'pry-byebug'
      gem 'pry-doc'
      gem 'pry-rails'
      gem 'tapp'
    end

    git add: '.', commit: '-m "Add gems for development to Gemfile"'
  end


  begin
    gem_group :test do
      gem 'capybara'
      gem 'factory_girl_rails', group: :development
      gem 'parallel_tests', group: :development
      gem 'rspec-rails', group: :development
      gem 'simplecov', require: false
    end
    git add: '.', commit: '-m "Add testing frameworks to Gemfile"'
  end


  begin
    command = 'bundle install'
    command << " --path #{bundle_path}" if bundle_path
    run command
    git add: '.', commit: '-m "Exec bundle install"'
  end


  begin
    if use_mongoid?
      run 'bundle exec rails generate mongoid:config'
      git add: '.', commit: '-m "Exec rails generate mongoid:config"'

      append_to_gitignore '/config/mongoid.yml'
      git add: '.', commit: '-m "Add config/mongoid.yml to .gitignore"'

      copy_file File.expand_path('config/mongoid.yml'), 'config/mongoid.yml.example'
      git rm: '--cached config/mongoid.yml'
      git add: '.', commit: '-m "Rename mongoid.yml to mongoid.yml.example"'
    end
  end


  begin
    run 'bundle exec rails generate rspec:install'
    git add: '.', commit: '-m "Exec rails generate rspec:install"'
  end


  #begin
  #  append_to_file '.rspec', deindent(<<-__EOT__)
  #    --format documentation
  #  __EOT__
  #  git add: '.', commit: '-m "Add rspec options"'
  #end


  begin
    if use_mongoid?
      comment_lines 'spec/spec_helper.rb', /config\.fixture_path =/
      comment_lines 'spec/spec_helper.rb', /config\.use_transactional_fixtures =/
      git add: '.', commit: '-m "Comment out fixture configs for mongoid"'
    end
  end


  begin
    run 'bundle exec guard init rspec'
    git add: '.', commit: '-m "Exec guard init rspec"'
  end


  git gc: '--aggressive'
end
