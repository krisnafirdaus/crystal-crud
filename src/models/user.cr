require "../db/database"
require "json"
require "crypto/bcrypt/password"
require "jwt"

class User
  property id : Int64?
  property email : String
  property username : String
  property password_hash : String
  property role : String
  property created_at : Time?

  def initialize(@email : String, @username : String, @password_hash : String, @role : String = "user", @id : Int64? = nil, @created_at : Time? = nil)
  end

  def self.create(email : String, username : String, password : String, role : String = "user") : User
    password_hash = Crypto::Bcrypt::Password.create(password).to_s
    user = User.new(email, username, password_hash, role)
    user.save
  end

  def self.find_by_email(email : String) : User?
    Database.connection.query "SELECT id, email, username, password_hash, role, created_at FROM users WHERE email = ?", email do |rs|
      if rs.move_next
        id = rs.read(Int64)
        email = rs.read(String)
        username = rs.read(String)
        password_hash = rs.read(String)
        role = rs.read(String)
        created_at = rs.read(Time?)
        return User.new(email, username, password_hash, role, id, created_at)
      end
    end
    nil
  end

  def self.find_by_username(username : String) : User?
    Database.connection.query "SELECT id, email, username, password_hash, role, created_at FROM users WHERE username = ?", username do |rs|
      if rs.move_next
        id = rs.read(Int64)
        email = rs.read(String)
        username = rs.read(String)
        password_hash = rs.read(String)
        role = rs.read(String)
        created_at = rs.read(Time?)
        return User.new(email, username, password_hash, role, id, created_at)
      end
    end
    nil
  end

  def self.find(id : Int64) : User?
    Database.connection.query "SELECT id, email, username, password_hash, role, created_at FROM users WHERE id = ?", id do |rs|
      if rs.move_next
        id = rs.read(Int64)
        email = rs.read(String)
        username = rs.read(String)
        password_hash = rs.read(String)
        role = rs.read(String)
        created_at = rs.read(Time?)
        return User.new(email, username, password_hash, role, id, created_at)
      end
    end
    nil
  end

  def self.all(limit : Int32 = 20, offset : Int32 = 0) : Array(User)
    users = [] of User
    Database.connection.query "SELECT id, email, username, password_hash, role, created_at FROM users ORDER BY created_at DESC LIMIT ? OFFSET ?", limit, offset do |rs|
      rs.each do
        id = rs.read(Int64)
        email = rs.read(String)
        username = rs.read(String)
        password_hash = rs.read(String)
        role = rs.read(String)
        created_at = rs.read(Time?)
        users << User.new(email, username, password_hash, role, id, created_at)
      end
    end
    users
  end

  def self.count : Int64
    Database.connection.scalar("SELECT COUNT(*) FROM users").as(Int64)
  end

  def save
    if @id
      Database.connection.exec "UPDATE users SET email = ?, username = ?, password_hash = ?, role = ? WHERE id = ?", @email, @username, @password_hash, @role, @id
    else
      Database.connection.exec "INSERT INTO users (email, username, password_hash, role) VALUES (?, ?, ?, ?)", @email, @username, @password_hash, @role
      @id = Database.connection.scalar("SELECT last_insert_rowid()").as(Int64)
    end
    self
  end

  def delete
    if @id
      Database.connection.exec "DELETE FROM users WHERE id = ?", @id
      true
    else
      false
    end
  end

  def authenticate(password : String) : Bool
    stored_hash = Crypto::Bcrypt::Password.new(@password_hash)
    stored_hash.verify(password)
  end

  def generate_jwt(exp_hours : Int32 = 24) : String
    exp = Time.utc.to_unix + exp_hours * 3600 # expires in exp_hours hours
    payload = {"user_id" => @id, "email" => @email, "role" => @role, "exp" => exp}
    JWT.encode(payload, User.jwt_secret, JWT::Algorithm::HS256)
  end

  def self.jwt_secret : String
    ENV["JWT_SECRET"]? || "super_secret_default_key_should_be_changed"
  end

  def self.validate_jwt(token : String) : Hash(String, JSON::Any)?
    begin
      payload = JWT.decode(token, jwt_secret, JWT::Algorithm::HS256)[0]
      payload.as_h
    rescue ex : JWT::Error
      nil
    end
  end

  def self.from_jwt(token : String) : User?
    if payload = validate_jwt(token)
      if user_id = payload["user_id"]?.try &.as_i64?
        User.find(user_id)
      end
    end
  end

  def to_json(json : JSON::Builder)
    json.object do
      json.field "id", @id
      json.field "email", @email
      json.field "username", @username
      json.field "role", @role
      json.field "created_at", @created_at.try &.to_s("%Y-%m-%d %H:%M")
    end
  end
end
