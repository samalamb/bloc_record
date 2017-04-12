require 'sqlite3'
require 'pg'

module PG
  class Connection
    def execute(*args)
      self.exec(*args)
    end

    def get_first_row(*args)
      self.exec(*args)[0]
    end
  end
end

module Connection
  def connection
    if BlocRecord.database == :sqlite3
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    elsif BlocRecord.database == :pg
      @connection ||= PG.connect(dbname: BlocRecord.database_filename)
    end
  end
end
