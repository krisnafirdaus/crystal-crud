require "kemal"
require "./db/database"
require "./controllers/task_controller"

# Setup database
Database.setup

# Add root route
get "/" do |env|
  env.redirect "/tasks"
end

# Register task routes
TaskController.register_routes

# Show welcome message
puts "Server is running at http://localhost:3000"

# Start Kemal server
Kemal.run
