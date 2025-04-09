require "../db/database"
require "json"

class Task
  property id : Int64?
  property title : String
  property description : String?
  property completed : Bool
  property created_at : Time?

  def initialize(@title : String, @description : String? = nil, @completed : Bool = false, @id : Int64? = nil, @created_at : Time? = nil)
  end

  def self.all
    tasks = [] of Task
    Database.connection.query "SELECT id, title, description, completed, created_at FROM tasks ORDER BY created_at DESC" do |rs|
      rs.each do
        id = rs.read(Int64)
        title = rs.read(String)
        description = rs.read(String?)
        completed = rs.read(Bool)
        created_at = rs.read(Time?)
        tasks << Task.new(title, description, completed, id, created_at)
      end
    end
    tasks
  end

  def self.find(id : Int64)
    Database.connection.query "SELECT id, title, description, completed, created_at FROM tasks WHERE id = ?", id do |rs|
      if rs.move_next
        task_id = rs.read(Int64)
        title = rs.read(String)
        description = rs.read(String?)
        completed = rs.read(Bool)
        created_at = rs.read(Time?)
        return Task.new(title, description, completed, task_id, created_at)
      end
    end
    nil
  end

  def save
    if @id
      Database.connection.exec "UPDATE tasks SET title = ?, description = ?, completed = ? WHERE id = ?", @title, @description, @completed, @id
    else
      Database.connection.exec "INSERT INTO tasks (title, description, completed) VALUES (?, ?, ?)", @title, @description, @completed
      @id = Database.connection.scalar("SELECT last_insert_rowid()").as(Int64)
    end
    self
  end

  def delete
    if @id
      Database.connection.exec "DELETE FROM tasks WHERE id = ?", @id
      true
    else
      false
    end
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field "id", @id
      json.field "title", @title
      json.field "description", @description
      json.field "completed", @completed
      json.field "created_at", @created_at.try &.to_s("%Y-%m-%d %H:%M")
    end
  end
end
