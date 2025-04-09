require "kemal"
require "json"
require "../models/task"

module TaskController
  def self.register_routes
    # Index - Get all tasks
    get "/tasks" do |env|
      tasks = Task.all
      if env.request.headers["Accept"]? == "application/json"
        env.response.content_type = "application/json"
        tasks.to_json
      else
        render "src/views/tasks/index.ecr", "src/views/layouts/layout.ecr"
      end
    end

    # Show - Get a single task
    get "/tasks/:id" do |env|
      id = env.params.url["id"].to_i64
      task = Task.find(id)
      if task.nil?
        env.response.status_code = 404
        "Task not found"
      else
        if env.request.headers["Accept"]? == "application/json"
          env.response.content_type = "application/json"
          task.to_json
        else
          render "src/views/tasks/show.ecr", "src/views/layouts/layout.ecr"
        end
      end
    end

    # New - Form to create a new task
    get "/tasks/new" do |env|
      render "src/views/tasks/new.ecr", "src/views/layouts/layout.ecr"
    end

    # Create - Create a new task
    post "/tasks" do |env|
      title = env.params.body["title"]
      description = env.params.body["description"]?
      task = Task.new(title, description)
      task.save

      if env.request.headers["Accept"]? == "application/json"
        env.response.content_type = "application/json"
        env.response.status_code = 201
        task.to_json
      else
        env.redirect "/tasks"
      end
    end

    # Edit - Form to edit a task
    get "/tasks/:id/edit" do |env|
      id = env.params.url["id"].to_i64
      task = Task.find(id)
      if task.nil?
        env.response.status_code = 404
        "Task not found"
      else
        render "src/views/tasks/edit.ecr", "src/views/layouts/layout.ecr"
      end
    end

    # Update - Update a task
    put "/tasks/:id" do |env|
      id = env.params.url["id"].to_i64
      task = Task.find(id)
      if task.nil?
        env.response.status_code = 404
        "Task not found"
      else
        task.title = env.params.body["title"]
        task.description = env.params.body["description"]?
        task.completed = env.params.body["completed"]? == "on"
        task.save

        if env.request.headers["Accept"]? == "application/json"
          env.response.content_type = "application/json"
          task.to_json
        else
          env.redirect "/tasks"
        end
      end
    end

    # Delete - Delete a task
    delete "/tasks/:id" do |env|
      id = env.params.url["id"].to_i64
      task = Task.find(id)
      if task.nil?
        env.response.status_code = 404
        "Task not found"
      else
        task.delete

        if env.request.headers["Accept"]? == "application/json"
          env.response.status_code = 204
        else
          env.redirect "/tasks"
        end
      end
    end
  end
end
