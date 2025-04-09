require "kemal"
require "./db/database"
require "./middleware/auth_handler"
require "./controllers/auth_controller"
require "./controllers/invoice_controller"
require "./controllers/report_controller"
require "./controllers/admin_controller"

# Setup database
Database.setup

# Add CORS support for API
before_all do |env|
  env.response.headers.add("Access-Control-Allow-Origin", "*")
  env.response.headers.add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  env.response.headers.add("Access-Control-Allow-Headers", "Content-Type, Authorization")
end

options "/*" do |env|
  env.response.headers.add("Access-Control-Allow-Origin", "*")
  env.response.headers.add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
  env.response.headers.add("Access-Control-Allow-Headers", "Content-Type, Authorization")
  env.response.status_code = 200
end

# Default JSON response type for API
before_all do |env|
  env.response.content_type = "application/json"
end

# Add middleware for authentication
add_handler AuthHandler.new

# Add root route
get "/" do |env|
  {message: "Welcome to Crystal API", version: "1.0.0"}.to_json
end

# Register all controllers
AuthController.register_routes
InvoiceController.register_routes
ReportController.register_routes
AdminController.register_routes

# Error handling
error 404 do |env|
  env.response.content_type = "application/json"
  {error: "Not found"}.to_json
end

error 500 do |env, exception|
  env.response.content_type = "application/json"
  {error: "Internal server error", message: exception.message}.to_json
end

# Show welcome message
puts "API Server is running at http://localhost:3000"

# Start Kemal server
Kemal.run
