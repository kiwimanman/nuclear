require 'sqlite3'
require 'celluloid'

# Idea is:
# One transaction per store, one store per thread.
module Nuclear
  class Storage
    include Celluloid

    attr_accessor :db, :auto_commit, :replica

    def initialize(database, options = {})
      self.db = SQLite3::Database.new database

      self.auto_commit = options[:auto_commit].nil? ? true : options[:auto_commit]

      # Create a database
      rows = db.execute <<-SQL
        create table if not exists Store (
          id INTEGER PRIMARY KEY ASC,
          key   text UNIQUE NOT NULL,
          value text
        );
      SQL
    end

    def get(key)
      db.execute( "select * from Store where key = \"#{key}\"" ) do |row|
        return row[2]
      end
      return nil
    end

    def put(key, value)
      db.transaction unless auto_commit
      db.execute "INSERT OR REPLACE INTO Store (key, value) VALUES ( ?, ?)", key.to_s, value.to_s
    end

    def delete(key)
      db.transaction unless auto_commit
      db.execute "DELETE FROM Store WHERE key = \"#{key}\""
    end

    def commit
      db.commit
      replica.enqueue if replica
    end

    def rollback
      db.rollback
      replica.enqueue if replica
    end
  end
end