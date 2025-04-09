require "kemal"
require "json"
require "../models/user"
require "../models/invoice"
require "../models/report"

module AdminController
  def self.register_routes
    # Middleware untuk validasi admin di semua route admin
    before_all "/api/admin/*" do |env|
      # Skip jika bukan route admin
      next env unless env.request.path.starts_with?("/api/admin")

      # Get user ID from context and look up the user (safely)
      user_id = env.get?("current_user_id").as(Int64?)
      if user_id.nil?
        env.response.status_code = 401
        env.response.print({error: "Authentication required"}.to_json)
        halt env
      end

      user = User.find(user_id)
      if user.nil?
        env.response.status_code = 401
        env.response.print({error: "User not found"}.to_json)
        halt env
      end

      # Verify admin role
      if user.role != "admin"
        env.response.status_code = 403
        env.response.print({error: "Forbidden: Admin access required"}.to_json)
        halt env
      end
    end

    # Get all users (admin only)
    get "/api/admin/users" do |env|
      # Get query parameters for pagination
      limit = (env.params.query["limit"]? || "20").to_i
      page = (env.params.query["page"]? || "1").to_i
      offset = (page - 1) * limit

      # Get users with pagination
      users = User.all(limit, offset)
      total = User.count

      # Calculate pagination metadata
      total_pages = (total / limit).ceil.to_i
      total_pages = 1 if total_pages == 0

      # Build response
      {
        users: users,
        pagination: {
          total: total,
          per_page: limit,
          current_page: page,
          total_pages: total_pages
        }
      }.to_json
    end

    # Update user (admin only)
    put "/api/admin/users/:id" do |env|
      begin
        id = env.params.url["id"].to_i64

        user = User.find(id)

        if user.nil?
          env.response.status_code = 404
          next {error: "User not found"}.to_json
        end

        # Parse request body
        request_json = env.request.body.try(&.gets_to_end)
        if request_json.nil? || request_json.empty?
          env.response.status_code = 400
          next {error: "Invalid request body"}.to_json
        end

        body = JSON.parse(request_json)

        # Update fields with safe access
        if email = body["email"]?.try(&.as_s)
          user.email = email
        end

        if username = body["username"]?.try(&.as_s)
          user.username = username
        end

        # Update role if provided
        if role = body["role"]?.try(&.as_s)
          user.role = role
        end

        # Update password if provided
        if password = body["password"]?.try(&.as_s)
          user.password_hash = Crypto::Bcrypt::Password.create(password).to_s
        end

        user.save

        user.to_json
      rescue ex : JSON::ParseException
        env.response.status_code = 400
        {error: "Invalid JSON: #{ex.message}"}.to_json
      rescue ex
        env.response.status_code = 400
        {error: ex.message}.to_json
      end
    end

    # Delete user (admin only)
    delete "/api/admin/users/:id" do |env|
      id = env.params.url["id"].to_i64

      user = User.find(id)

      if user.nil?
        env.response.status_code = 404
        next {error: "User not found"}.to_json
      end

      user.delete

      env.response.status_code = 204
      nil
    end

    # Dashboard statistics (admin only)
    get "/api/admin/stats" do |env|
      # Get user count
      user_count = User.count

      # Get invoice statistics
      total_invoices = Invoice.count
      pending_invoices = Database.connection.scalar("SELECT COUNT(*) FROM invoices WHERE status = ?", "pending").as(Int64)
      paid_invoices = Database.connection.scalar("SELECT COUNT(*) FROM invoices WHERE status = ?", "paid").as(Int64)
      total_revenue = Database.connection.scalar("SELECT SUM(amount) FROM invoices WHERE status = ?", "paid")
      total_revenue = total_revenue.as(Float64?) || 0.0

      # Get report statistics
      total_reports = Report.count

      # Get recent users
      recent_users = User.all(5, 0)

      # Build response
      {
        users: {
          total: user_count,
          recent: recent_users
        },
        invoices: {
          total: total_invoices,
          pending: pending_invoices,
          paid: paid_invoices,
          total_revenue: total_revenue
        },
        reports: {
          total: total_reports
        }
      }.to_json
    end

    # Export all data for admin (to CSV)
    get "/api/admin/export/all" do |env|
      # Get all users
      users = User.all(1000, 0)

      # Get all invoices
      invoices = Invoice.all(1000, 0)

      # Get all reports
      reports = Report.all(1000, 0)

      # Generate CSV content for users
      users_csv = ["id,email,username,role,created_at"]
      users.each do |user|
        users_csv << "#{user.id},#{user.email},#{user.username},#{user.role},#{user.created_at.try &.to_s("%Y-%m-%d %H:%M")}"
      end

      # Generate CSV content for invoices
      invoices_csv = [Invoice.csv_header]
      invoices.each do |invoice|
        invoices_csv << invoice.to_csv
      end

      # Generate CSV content for reports
      reports_csv = [Report.csv_header]
      reports.each do |report|
        reports_csv << report.to_csv
      end

      # Build combined CSV content
      csv_content = [
        "# USERS",
        users_csv.join("\n"),
        "",
        "# INVOICES",
        invoices_csv.join("\n"),
        "",
        "# REPORTS",
        reports_csv.join("\n")
      ]

      # Set response headers
      env.response.content_type = "text/csv"
      env.response.headers["Content-Disposition"] = "attachment; filename=\"full_export_#{Time.utc.to_s("%Y%m%d")}.csv\""

      # Return CSV content
      csv_content.join("\n")
    end
  end
end
