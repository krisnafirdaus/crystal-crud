require "db"
require "sqlite3"

module Database
  @@db : DB::Database = DB.open "sqlite3:./data.db"

  def self.connection
    @@db
  end

  def self.setup
    # Users table with role-based access
    connection.exec "CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL UNIQUE,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'user',
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )"

    # Tasks table (existing)
    connection.exec "CREATE TABLE IF NOT EXISTS tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      description TEXT,
      completed BOOLEAN DEFAULT 0,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      user_id INTEGER,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )"

    # Invoices table
    connection.exec "CREATE TABLE IF NOT EXISTS invoices (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      invoice_number TEXT NOT NULL UNIQUE,
      amount REAL NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      issue_date TEXT NOT NULL,
      due_date TEXT NOT NULL,
      client_name TEXT NOT NULL,
      description TEXT,
      user_id INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )"

    # Reports table
    connection.exec "CREATE TABLE IF NOT EXISTS reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      report_type TEXT NOT NULL,
      user_id INTEGER NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )"
  end
end
