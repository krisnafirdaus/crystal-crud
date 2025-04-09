require "kemal"
require "json"
require "../models/user"

module AuthController
  def self.register_routes
    # Register a new user
    post "/api/auth/register" do |env|
      begin
        # Parse request body
        request_json = env.request.body.try(&.gets_to_end)
        if request_json.nil? || request_json.empty?
          env.response.status_code = 400
          next {error: "Invalid request body"}.to_json
        end

        begin
          body = JSON.parse(request_json)

          # Fix JSON parsing
          email = body["email"]?.try(&.as_s)
          username = body["username"]?.try(&.as_s)
          password = body["password"]?.try(&.as_s)

          # Validate required fields
          if email.nil? || username.nil? || password.nil?
            env.response.status_code = 400
            next {error: "Email, username, and password are required"}.to_json
          end

          # Check if email or username already exists
          if User.find_by_email(email) || User.find_by_username(username)
            env.response.status_code = 400
            next {error: "Email or username already exists"}.to_json
          end

          # Create new user (default role is 'user')
          user = User.create(email, username, password)

          env.response.status_code = 201
          {
            message: "User registered successfully",
            user: {
              id: user.id,
              email: user.email,
              username: user.username,
              role: user.role
            }
          }.to_json
        rescue ex : JSON::ParseException
          env.response.status_code = 400
          {error: "Invalid JSON: #{ex.message}"}.to_json
        end
      rescue ex
        env.response.status_code = 500
        {error: "Internal server error: #{ex.message}"}.to_json
      end
    end

    # Login and generate JWT
    post "/api/auth/login" do |env|
      begin
        # Parse request body
        request_json = env.request.body.try(&.gets_to_end)
        if request_json.nil? || request_json.empty?
          env.response.status_code = 400
          next {error: "Invalid request body"}.to_json
        end

        body = JSON.parse(request_json)

        # Fix JSON parsing
        identifier = body["identifier"]?.try(&.as_s)
        password = body["password"]?.try(&.as_s)

        # Validate required fields
        if identifier.nil? || password.nil?
          env.response.status_code = 400
          next {error: "Identifier and password are required"}.to_json
        end

        # Find user by email or username
        user = User.find_by_email(identifier) || User.find_by_username(identifier)

        if user.nil? || !user.authenticate(password)
          env.response.status_code = 401
          next {error: "Invalid credentials"}.to_json
        end

        # Generate JWT token
        token = user.generate_jwt

        {
          message: "Login successful",
          token: token,
          user: {
            id: user.id,
            email: user.email,
            username: user.username,
            role: user.role
          }
        }.to_json
      rescue ex : JSON::ParseException
        env.response.status_code = 400
        {error: "Invalid JSON: #{ex.message}"}.to_json
      rescue ex
        env.response.status_code = 500
        {error: "Internal server error: #{ex.message}"}.to_json
      end
    end

    # Get current user info (requires auth)
    get "/api/auth/me" do |env|
      # Get user ID from context and look up the user
      user_id = env.get("current_user_id").as(Int64)
      user = User.find(user_id)

      if user.nil?
        env.response.status_code = 401
        next {error: "User not found"}.to_json
      end

      {
        id: user.id,
        email: user.email,
        username: user.username,
        role: user.role,
        created_at: user.created_at
      }.to_json
    end
  end
end
