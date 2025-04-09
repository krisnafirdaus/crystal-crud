require "db"
require "sqlite3"

module Database
  @@db : DB::Database = DB.open "sqlite3:./data.db"

  def self.connection
    @@db
  end

  def self.setup
    connection.exec "CREATE TABLE IF NOT EXISTS tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      completed BOOLEAN DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )"
  end
end
