# frozen_string_literal: true

require 'rails/generators'

module Erd
  class GenaratorRunner
    class << self
      # runs `rails g model [name]`
      # @return generated migration filename
      def execute_generate_model(name, options = nil)
        result = execute_generator 'model', name, options
        result.flatten.grep(%r(/db/migrate/.*\.rb))
      end

      # runs `rails g migration [name]`
      # @return generated migration filename
      def execute_generate_migration(name, options = nil)
        result = execute_generator 'migration', name, options
        # Rails 7+ returns nested arrays differently
        if result.is_a?(Array)
          result.flatten.grep(%r(/db/migrate/.*\.rb)).first || result.last&.last
        else
          result
        end
      end

      private
      # a dirty workaround to make rspec-rails run
      def overwriting_argv(value, &block)
        original_argv = ARGV.dup
        ARGV.clear
        ARGV.concat value
        block.call
      ensure
        ARGV.clear
        ARGV.concat original_argv
      end

      def execute_generator(type, name, options = nil)
        overwriting_argv([name, options]) do
          Rails::Generators.configure! Rails.application.config.generators
          result = Rails::Generators.invoke type, [name, options], :behavior => :invoke, :destination_root => Rails.root
          raise ::Erd::MigrationError, "#{name}#{"(#{options})" if options}" unless result
          # Rails 7.2+ changes: result may be an array of results, or true/false
          # If result is just true, we need to find the generated file
          if result == true || result.empty?
            # Find the most recently created migration file
            Dir.glob(Rails.root.join('db/migrate/*.rb')).max_by {|f| File.mtime(f)}
          else
            result
          end
        end
      end
    end
  end
end
