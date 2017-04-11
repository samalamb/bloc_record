require 'sqlite3'

module Connection
  def connection
    if BlocRecord.database == :sqlite3
      @connection ||= SQLite3::Database.new(BlocRecord.database_filename)
    elsif BlocRecord.database == :pg
      @connection ||= PG.connect(dbname: BlocRecord.database_filename)
    end
  end
end
