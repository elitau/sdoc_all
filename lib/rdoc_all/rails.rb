class RdocAll::Rails < RdocAll::Base
  class << self
    def each
      Gem.source_index.search(Gem::Dependency.new('rails', :all)).each do |spec|
        yield spec.full_name, spec.version.to_s
      end
    end

    def update_sources(options = {})
      to_clear = Dir['rails-*']
      each do |rails, version|
        to_clear.delete(rails)
        remove_if_present(rails) if options[:force]
        unless File.directory?(rails)
          with_env 'VERSION', version do
            system('rails', rails, '--freeze')
          end
        end
      end
      to_clear.each do |rails|
        remove_if_present(rails)
      end
    end

    def add_rdoc_tasks
      each do |rails, version|
        Dir.chdir(rails) do
          pathes = Rake::FileList.new
          File.open('vendor/rails/railties/lib/tasks/documentation.rake') do |f|
            true until f.readline['Rake::RDocTask.new("rails")']
            until (line = f.readline.strip) == '}'
              if line['rdoc.rdoc_files.include']
                pathes.include(line[/'(.*)'/, 1])
              elsif line['rdoc.rdoc_files.exclude']
                pathes.exclude(line[/'(.*)'/, 1])
              end
            end
          end
          add_rdoc_task(rails, pathes.resolve)
        end
      end
    end
  end
end