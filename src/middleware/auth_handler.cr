require "kemal"
require "../models/user"

class AuthHandler < Kemal::Handler
  def call(context)
    # Skip for these paths
    if ["/", "/api/auth/login", "/api/auth/register"].includes?(context.request.path) || context.request.method == "OPTIONS"
      return call_next(context)
    end

    # Check for Authorization header
    auth_header = context.request.headers["Authorization"]?
    if auth_header.nil? || !auth_header.starts_with?("Bearer ")
      context.response.status_code = 401
      context.response.content_type = "application/json"
      context.response.print("{\"error\":\"Unauthorized: Missing or invalid token\"}")
      return context
    end

    # Extract and validate token
    token = auth_header.gsub("Bearer ", "")
    user = User.from_jwt(token)

    if user.nil?
      context.response.status_code = 401
      context.response.content_type = "application/json"
      context.response.print("{\"error\":\"Unauthorized: Invalid or expired token\"}")
      return context
    end

    # Set current user ID in context env for controllers (not the user object)
    context.set("current_user_id", user.id)
    call_next(context)
  end
end
