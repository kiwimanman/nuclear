require 'sqlite3'

# Idea is:
# One transaction per store, one store per thread.
module Nuclear
  class Storage
    private
    attr_accessor :db

    public

    def initialize(database, options = {})
      self.db = SQLite3::Database.new database

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
      db.execute "INSERT OR REPLACE INTO Store (key, value) VALUES ( ?, ?)", key.to_s, value.to_s
    end

    def delete(key)
      db.execute "DELETE FROM Store WHERE key = \"#{key}\""
    end

    def commit
      db.commit
    end

    def rollback
      db.rollback
    end
  end
end