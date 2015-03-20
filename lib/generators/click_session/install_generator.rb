require 'rails/generators/base'
require 'rails/generators/active_record'

module ClickSession
  class InstallGenerator < Rails::Generators::Base
    include Rails::Generators::Migration

    source_root File.expand_path('../', __FILE__)

    def create_click_session_migration
      unless session_states_table_exists?
        copy_migration 'create_session_states.rb'
      end
    end

    private

    def copy_migration(migration_name, config = {})
      unless migration_exists?(migration_name)
        migration_template(
          "db/migration/#{migration_name}",
          "db/migrate/#{migration_name}",
          config
        )
      end
    end

    def migration_exists?(name)
      existing_migrations.include?(name)
    end

    def existing_migrations
      @existing_migrations ||= Dir.glob("db/migrate/*.rb").map do |file|
        migration_name_without_timestamp(file)
      end
    end

    def migration_name_without_timestamp(file)
      file.sub(%r{^.*(db/migrate/)(?:\d+_)?}, '')
    end

    def session_states_table_exists?
      ActiveRecord::Base.connection.table_exists?(:session_states)
    end

    def self.next_migration_number(dir)
      ActiveRecord::Generators::Base.next_migration_number(dir)
    end
  end
end