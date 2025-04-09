require "kemal"
require "json"
require "../models/report"
require "../models/user"

module ReportController
  def self.register_routes
    # Get all reports (with pagination and filtering)
    get "/api/reports" do |env|
      # Get user ID from context and look up the user
      user_id = env.get("current_user_id").as(Int64)
      user = User.find(user_id)

      if user.nil?
        env.response.status_code = 401
        next {error: "User not found"}.to_json
      end

      # Get query parameters for pagination and filtering
      limit = (env.params.query["limit"]? || "20").to_i
      page = (env.params.query["page"]? || "1").to_i
      offset = (page - 1) * limit

      # Get type filter if provided
      report_type = env.params.query["type"]?

      # For non-admin users, only show their own reports
      filter_user_id = user.role == "admin" && env.params.query["user_id"]? ? env.params.query["user_id"].to_i64 : user.id

      # Get reports with filters
      reports = Report.all(limit, offset, filter_user_id, report_type)
      total = Report.count(filter_user_id, report_type)

      # Calculate pagination metadata
      total_pages = (total / limit).ceil.to_i
      total_pages = 1 if total_pages == 0

      # Build response
      {
        reports: reports,
        pagination: {
          total: total,
          per_page: limit,
          current_page: page,
          total_pages: total_pages
        }
      }.to_json
    end

    # Get a single report
    get "/api/reports/:id" do |env|
      # Get user ID from context and look up the user
      user_id = env.get("current_user_id").as(Int64)
      user = User.find(user_id)

      if user.nil?
        env.response.status_code = 401
        next {error: "User not found"}.to_json
      end

      id = env.params.url["id"].to_i64

      report = Report.find(id)

      if report.nil?
        env.response.status_code = 404
        next {error: "Report not found"}.to_json
      end

      # Verify ownership or admin
      if report.user_id != user.id && user.role != "admin"
        env.response.status_code = 403
        next {error: "Forbidden: You don't have access to this report"}.to_json
      end

      report.to_json
    end

    # Create a new report
    post "/api/reports" do |env|
      begin
        # Get user ID from context and look up the user
        user_id = env.get("current_user_id").as(Int64)
        user = User.find(user_id)

        if user.nil?
          env.response.status_code = 401
          next {error: "User not found"}.to_json
        end

        # Parse request body
        request_json = env.request.body.try(&.gets_to_end)
        if request_json.nil? || request_json.empty?
          env.response.status_code = 400
          next {error: "Invalid request body"}.to_json
        end

        body = JSON.parse(request_json)

        # Fix JSON parsing with safe access
        title = body["title"]?.try(&.as_s)
        content = body["content"]?.try(&.as_s)
        report_type = body["report_type"]?.try(&.as_s)

        # Validate required fields
        if title.nil? || content.nil? || report_type.nil?
          env.response.status_code = 400
          next {error: "Title, content, and report_type are required"}.to_json
        end

        # Create new report
        report = Report.new(
          title,
          content,
          report_type,
          user.id.not_nil!
        )

        report.save

        env.response.status_code = 201
        report.to_json
      rescue ex : JSON::ParseException
        env.response.status_code = 400
        {error: "Invalid JSON: #{ex.message}"}.to_json
      rescue ex
        env.response.status_code = 400
        {error: ex.message}.to_json
      end
    end

    # Update a report
    put "/api/reports/:id" do |env|
      begin
        # Get user ID from context and look up the user
        user_id = env.get("current_user_id").as(Int64)
        user = User.find(user_id)

        if user.nil?
          env.response.status_code = 401
          next {error: "User not found"}.to_json
        end

        id = env.params.url["id"].to_i64

        report = Report.find(id)

        if report.nil?
          env.response.status_code = 404
          next {error: "Report not found"}.to_json
        end

        # Verify ownership or admin
        if report.user_id != user.id && user.role != "admin"
          env.response.status_code = 403
          next {error: "Forbidden: You don't have permission to update this report"}.to_json
        end

        # Parse request body
        request_json = env.request.body.try(&.gets_to_end)
        if request_json.nil? || request_json.empty?
          env.response.status_code = 400
          next {error: "Invalid request body"}.to_json
        end

        body = JSON.parse(request_json)

        # Update fields with safe access
        if title = body["title"]?.try(&.as_s)
          report.title = title
        end

        if content = body["content"]?.try(&.as_s)
          report.content = content
        end

        if report_type = body["report_type"]?.try(&.as_s)
          report.report_type = report_type
        end

        report.save

        report.to_json
      rescue ex : JSON::ParseException
        env.response.status_code = 400
        {error: "Invalid JSON: #{ex.message}"}.to_json
      rescue ex
        env.response.status_code = 400
        {error: ex.message}.to_json
      end
    end

    # Delete a report
    delete "/api/reports/:id" do |env|
      # Get user ID from context and look up the user
      user_id = env.get("current_user_id").as(Int64)
      user = User.find(user_id)

      if user.nil?
        env.response.status_code = 401
        next {error: "User not found"}.to_json
      end

      id = env.params.url["id"].to_i64

      report = Report.find(id)

      if report.nil?
        env.response.status_code = 404
        next {error: "Report not found"}.to_json
      end

      # Verify ownership or admin
      if report.user_id != user.id && user.role != "admin"
        env.response.status_code = 403
        next {error: "Forbidden: You don't have permission to delete this report"}.to_json
      end

      report.delete

      env.response.status_code = 204
      nil
    end

    # Export reports to CSV
    get "/api/reports/export/csv" do |env|
      # Get user ID from context and look up the user
      user_id = env.get("current_user_id").as(Int64)
      user = User.find(user_id)

      if user.nil?
        env.response.status_code = 401
        next {error: "User not found"}.to_json
      end

      # Get type filter if provided
      report_type = env.params.query["type"]?

      # For non-admin users, only export their own reports
      filter_user_id = user.role == "admin" && env.params.query["user_id"]? ? env.params.query["user_id"].to_i64 : user.id

      # Get all reports without pagination
      reports = Report.all(1000, 0, filter_user_id, report_type)

      # Generate CSV content
      csv_content = [Report.csv_header]
      reports.each do |report|
        csv_content << report.to_csv
      end

      # Set response headers
      env.response.content_type = "text/csv"
      env.response.headers["Content-Disposition"] = "attachment; filename=\"reports_export_#{Time.utc.to_s("%Y%m%d")}.csv\""

      # Return CSV content
      csv_content.join("\n")
    end
  end
end
