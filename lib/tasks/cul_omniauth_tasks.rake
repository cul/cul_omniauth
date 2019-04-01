# desc "Explaining what the task does"
# task :cul_omniauth do
#   # Task goes here
# end
namespace :cul_omniauth do
  begin
    # This code is in a begin/rescue block so that the Rakefile is usable
    # in an environment where RSpec is unavailable (i.e. production).

    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new(:rspec) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rspec_opts = ['--backtrace'] if ENV['CI']
    end

    RSpec::Core::RakeTask.new(:rcov) do |spec|
      spec.pattern = FileList['spec/**/*_spec.rb']
      spec.pattern += FileList['spec/*_spec.rb']
      spec.rcov = true
    end

  rescue LoadError => e
    # https://github.com/rspec/rspec-core/issues/1638
    # rspec is not available
  end
  desc "Execute specs with coverage"
  task :coverage do
    # Put spec opts in a file named .rspec in root
    ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : "ruby"
    ENV['COVERAGE'] = 'true' unless ruby_engine == 'jruby'

   # Rake::Task["active_fedora:fixtures"].invoke
    Rake::Task["cul_omniauth:rspec"].invoke
  end
end
