require "../db/database"
require "json"

class Invoice
  property id : Int64?
  property invoice_number : String
  property amount : Float64
  property status : String
  property issue_date : String
  property due_date : String
  property client_name : String
  property description : String?
  property user_id : Int64
  property created_at : Time?

  def initialize(@invoice_number : String, @amount : Float64, @issue_date : String, @due_date : String, @client_name : String, @user_id : Int64, @status : String = "pending", @description : String? = nil, @id : Int64? = nil, @created_at : Time? = nil)
  end

  def self.all(limit : Int32 = 20, offset : Int32 = 0, user_id : Int64? = nil, status : String? = nil) : Array(Invoice)
    invoices = [] of Invoice

    # Build query with filters
    query = "SELECT id, invoice_number, amount, status, issue_date, due_date, client_name, description, user_id, created_at FROM invoices"
    params = [] of DB::Any

    # Add where clauses
    where_clauses = [] of String

    if user_id
      where_clauses << "user_id = ?"
      params << user_id
    end

    if status
      where_clauses << "status = ?"
      params << status
    end

    # Combine where clauses if any
    if where_clauses.size > 0
      query += " WHERE " + where_clauses.join(" AND ")
    end

    # Add ordering and pagination
    query += " ORDER BY created_at DESC LIMIT ? OFFSET ?"
    params << limit
    params << offset

    Database.connection.query query, args: params do |rs|
      rs.each do
        id = rs.read(Int64)
        invoice_number = rs.read(String)
        amount = rs.read(Float64)
        status = rs.read(String)
        issue_date = rs.read(String)
        due_date = rs.read(String)
        client_name = rs.read(String)
        description = rs.read(String?)
        user_id = rs.read(Int64)
        created_at = rs.read(Time?)
        invoices << Invoice.new(invoice_number, amount, issue_date, due_date, client_name, user_id, status, description, id, created_at)
      end
    end
    invoices
  end

  def self.count(user_id : Int64? = nil, status : String? = nil) : Int64
    # Build query with filters
    query = "SELECT COUNT(*) FROM invoices"
    params = [] of DB::Any

    # Add where clauses
    where_clauses = [] of String

    if user_id
      where_clauses << "user_id = ?"
      params << user_id
    end

    if status
      where_clauses << "status = ?"
      params << status
    end

    # Combine where clauses if any
    if where_clauses.size > 0
      query += " WHERE " + where_clauses.join(" AND ")
    end

    Database.connection.scalar(query, args: params).as(Int64)
  end

  def self.find(id : Int64) : Invoice?
    Database.connection.query "SELECT id, invoice_number, amount, status, issue_date, due_date, client_name, description, user_id, created_at FROM invoices WHERE id = ?", id do |rs|
      if rs.move_next
        id = rs.read(Int64)
        invoice_number = rs.read(String)
        amount = rs.read(Float64)
        status = rs.read(String)
        issue_date = rs.read(String)
        due_date = rs.read(String)
        client_name = rs.read(String)
        description = rs.read(String?)
        user_id = rs.read(Int64)
        created_at = rs.read(Time?)
        return Invoice.new(invoice_number, amount, issue_date, due_date, client_name, user_id, status, description, id, created_at)
      end
    end
    nil
  end

  def self.find_by_invoice_number(invoice_number : String) : Invoice?
    Database.connection.query "SELECT id, invoice_number, amount, status, issue_date, due_date, client_name, description, user_id, created_at FROM invoices WHERE invoice_number = ?", invoice_number do |rs|
      if rs.move_next
        id = rs.read(Int64)
        invoice_number = rs.read(String)
        amount = rs.read(Float64)
        status = rs.read(String)
        issue_date = rs.read(String)
        due_date = rs.read(String)
        client_name = rs.read(String)
        description = rs.read(String?)
        user_id = rs.read(Int64)
        created_at = rs.read(Time?)
        return Invoice.new(invoice_number, amount, issue_date, due_date, client_name, user_id, status, description, id, created_at)
      end
    end
    nil
  end

  def save
    if @id
      Database.connection.exec "UPDATE invoices SET invoice_number = ?, amount = ?, status = ?, issue_date = ?, due_date = ?, client_name = ?, description = ?, user_id = ? WHERE id = ?", @invoice_number, @amount, @status, @issue_date, @due_date, @client_name, @description, @user_id, @id
    else
      Database.connection.exec "INSERT INTO invoices (invoice_number, amount, status, issue_date, due_date, client_name, description, user_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?)", @invoice_number, @amount, @status, @issue_date, @due_date, @client_name, @description, @user_id
      @id = Database.connection.scalar("SELECT last_insert_rowid()").as(Int64)
    end
    self
  end

  def delete
    if @id
      Database.connection.exec "DELETE FROM invoices WHERE id = ?", @id
      true
    else
      false
    end
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field "id", @id
      json.field "invoice_number", @invoice_number
      json.field "amount", @amount
      json.field "status", @status
      json.field "issue_date", @issue_date
      json.field "due_date", @due_date
      json.field "client_name", @client_name
      json.field "description", @description
      json.field "user_id", @user_id
      json.field "created_at", @created_at.try &.to_s("%Y-%m-%d %H:%M")
    end
  end

  def to_csv : String
    "#{@id},#{@invoice_number},#{@amount},#{@status},#{@issue_date},#{@due_date},#{@client_name},#{@description},#{@user_id},#{@created_at.try &.to_s("%Y-%m-%d %H:%M")}"
  end

  def self.csv_header : String
    "id,invoice_number,amount,status,issue_date,due_date,client_name,description,user_id,created_at"
  end
end
