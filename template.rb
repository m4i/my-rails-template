def indent(string, width = 2)
  string.gsub(/^(?=.)/, ' ' * width)
end

def deindent(string, width = nil)
  width ||= string.lines.grep(/./).map do |line|
    line[/^ */].length
  end.min || 0
  string.gsub(/^ {#{width}}/, '')
end

def append_newline(path)
  gsub_file path, /\z/, "\n"
end

def rstrip_newline(path)
  gsub_file path, /\n+\z/, ''
end

def gem(*args)
  super.tap do
    append_newline 'Gemfile' unless @in_group
  end
end




use_haml = yes? 'do you want to use haml?'


# reset bundle environment
ENV.delete('BUNDLE_BIN_PATH')
ENV.delete('BUNDLE_GEMFILE')
ENV.delete('GEM_HOME')
ENV.delete('GEM_PATH')
ENV.delete('RUBYOPT')


begin
  git :init
  git add: '.', commit: '-m "Exec rails new"'
end


begin
  append_file '.gitignore', deindent(<<-__EOT__)

    /config/database.yml
    /db/schema.rb
    /db/structure.sql
    /public/assets/
    /vendor/bundle
  __EOT__
  git add: '.', commit: '-m "Add ignore files"'
end


begin
  if use_haml
    gem 'haml-rails'
    git add: '.', commit: '-m "Add haml-rails to Gemfile"'
  end
end


begin
  gem_group :development, :test do
    gem 'tapp'
    gem 'awesome_print'
  end
  git add: '.', commit: '-m "Add tapp to Gemfile"'
end


begin
  gem_group :development, :test do
    gem 'plymouth', require: false
    gem 'pry-exception_explorer'
    gem 'pry-nav'
    gem 'pry-rails'
    gem 'pry-remote'
    gem 'pry-stack_explorer'
  end
  git add: '.', commit: '-m "Add pry to Gemfile"'
end


begin
  gem_group :development, :test do
    gem 'rspec-rails'
    gem 'factory_girl_rails'
    gem 'capybara-webkit'
    gem 'guard-spork'
    gem 'guard-rspec'
    gem 'growl'
  end
  gsub_file 'Gemfile', /gem (["'])growl\1.*/,
    %q!\& if system('which growlnotify >/dev/null')!
  git add: '.', commit: '-m "Add testing frameworks to Gemfile"'
end


begin
  create_link 'vendor/bundle', Bundler.bundle_path.parent.parent

  run 'bundle install --path vendor/bundle'
  git add: '.', commit: '-m "Exec bundle install"'
end


begin
  run 'script/rails generate rspec:install'
  git add: '.', commit: '-m "Exec rails generate rspec:install"'
end


begin
  gsub_file 'spec/spec_helper.rb', /^ *(?=config\.fixture_path =)/, '\&#'
  git add: '.', commit: '-m "Comment out config for fixture"'
end


begin
  original_spec_helper = File.read('spec/spec_helper.rb')

  run 'bundle exec spork --bootstrap'
  git add: '.', commit: '-m "Exec spork --bootstrap"'

  gsub_file 'spec/spec_helper.rb', /\A.*\z/m do |match|
    appended = match[0 ... - original_spec_helper.length]
    appended.sub(/^Spork\.prefork do$.*?(?=^end$)/m) do
      $& + indent(original_spec_helper)
    end.sub(/\n*\z/, "\n")
  end
  git add: '.', commit: '-m "Modify spec_helper for Spork"'
end


begin
  run 'bundle exec guard init spork'
  git add: '.', commit: '-m "Exec guard init spork"'
end


begin
  run 'bundle exec guard init rspec'
  git add: '.', commit: '-m "Exec guard init rspec"'
end


begin
  append_file '.rspec', deindent(<<-__EOT__)
    --drb
    --format documentation
  __EOT__
  gsub_file 'Guardfile', /^guard (["'])rspec\1.*(?= do$)/ do |match|
    match + ", cli: '--drb --format documentation'"
  end
  git add: '.', commit: '-m "Add rspec options"'
end


begin
  remove_file 'public/index.html'
  git add: '-u .', commit: '-m "Delete index.html"'
end
