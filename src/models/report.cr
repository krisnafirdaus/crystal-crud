require "../db/database"
require "json"

class Report
  property id : Int64?
  property title : String
  property content : String
  property report_type : String
  property user_id : Int64
  property created_at : Time?

  def initialize(@title : String, @content : String, @report_type : String, @user_id : Int64, @id : Int64? = nil, @created_at : Time? = nil)
  end

  def self.all(limit : Int32 = 20, offset : Int32 = 0, user_id : Int64? = nil, report_type : String? = nil) : Array(Report)
    reports = [] of Report

    # Build query with filters
    query = "SELECT id, title, content, report_type, user_id, created_at FROM reports"
    params = [] of DB::Any

    # Add where clauses
    where_clauses = [] of String

    if user_id
      where_clauses << "user_id = ?"
      params << user_id
    end

    if report_type
      where_clauses << "report_type = ?"
      params << report_type
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
        title = rs.read(String)
        content = rs.read(String)
        report_type = rs.read(String)
        user_id = rs.read(Int64)
        created_at = rs.read(Time?)
        reports << Report.new(title, content, report_type, user_id, id, created_at)
      end
    end
    reports
  end

  def self.count(user_id : Int64? = nil, report_type : String? = nil) : Int64
    # Build query with filters
    query = "SELECT COUNT(*) FROM reports"
    params = [] of DB::Any

    # Add where clauses
    where_clauses = [] of String

    if user_id
      where_clauses << "user_id = ?"
      params << user_id
    end

    if report_type
      where_clauses << "report_type = ?"
      params << report_type
    end

    # Combine where clauses if any
    if where_clauses.size > 0
      query += " WHERE " + where_clauses.join(" AND ")
    end

    Database.connection.scalar(query, args: params).as(Int64)
  end

  def self.find(id : Int64) : Report?
    Database.connection.query "SELECT id, title, content, report_type, user_id, created_at FROM reports WHERE id = ?", id do |rs|
      if rs.move_next
        id = rs.read(Int64)
        title = rs.read(String)
        content = rs.read(String)
        report_type = rs.read(String)
        user_id = rs.read(Int64)
        created_at = rs.read(Time?)
        return Report.new(title, content, report_type, user_id, id, created_at)
      end
    end
    nil
  end

  def save
    if @id
      Database.connection.exec "UPDATE reports SET title = ?, content = ?, report_type = ?, user_id = ? WHERE id = ?", @title, @content, @report_type, @user_id, @id
    else
      Database.connection.exec "INSERT INTO reports (title, content, report_type, user_id) VALUES (?, ?, ?, ?)", @title, @content, @report_type, @user_id
      @id = Database.connection.scalar("SELECT last_insert_rowid()").as(Int64)
    end
    self
  end

  def delete
    if @id
      Database.connection.exec "DELETE FROM reports WHERE id = ?", @id
      true
    else
      false
    end
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field "id", @id
      json.field "title", @title
      json.field "content", @content
      json.field "report_type", @report_type
      json.field "user_id", @user_id
      json.field "created_at", @created_at.try &.to_s("%Y-%m-%d %H:%M")
    end
  end

  def to_csv : String
    "#{@id},#{@title},#{@content},#{@report_type},#{@user_id},#{@created_at.try &.to_s("%Y-%m-%d %H:%M")}"
  end

  def self.csv_header : String
    "id,title,content,report_type,user_id,created_at"
  end
end
