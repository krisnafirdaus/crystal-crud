require "kemal"
require "json"
require "../models/invoice"
require "../models/user"

module InvoiceController
  def self.register_routes
    # Get all invoices (with pagination and filtering)
    get "/api/invoices" do |env|
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

      # Get status filter if provided
      status = env.params.query["status"]?

      # For non-admin users, only show their own invoices
      filter_user_id = user.role == "admin" && env.params.query["user_id"]? ? env.params.query["user_id"].to_i64 : user.id

      # Get invoices with filters
      invoices = Invoice.all(limit, offset, filter_user_id, status)
      total = Invoice.count(filter_user_id, status)

      # Calculate pagination metadata
      total_pages = (total / limit).ceil.to_i
      total_pages = 1 if total_pages == 0

      # Build response
      {
        invoices: invoices,
        pagination: {
          total: total,
          per_page: limit,
          current_page: page,
          total_pages: total_pages
        }
      }.to_json
    end

    # Get a single invoice
    get "/api/invoices/:id" do |env|
      # Get user ID from context and look up the user
      user_id = env.get("current_user_id").as(Int64)
      user = User.find(user_id)

      if user.nil?
        env.response.status_code = 401
        next {error: "User not found"}.to_json
      end

      id = env.params.url["id"].to_i64

      invoice = Invoice.find(id)

      if invoice.nil?
        env.response.status_code = 404
        next {error: "Invoice not found"}.to_json
      end

      # Verify ownership or admin
      if invoice.user_id != user.id && user.role != "admin"
        env.response.status_code = 403
        next {error: "Forbidden: You don't have access to this invoice"}.to_json
      end

      invoice.to_json
    end

    # Create a new invoice
    post "/api/invoices" do |env|
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
        invoice_number = body["invoice_number"]?.try(&.as_s)
        amount = body["amount"]?.try(&.as_f)
        issue_date = body["issue_date"]?.try(&.as_s)
        due_date = body["due_date"]?.try(&.as_s)
        client_name = body["client_name"]?.try(&.as_s)
        status = body["status"]?.try(&.as_s) || "pending"
        description = body["description"]?.try(&.as_s)

        # Validate required fields
        if invoice_number.nil? || amount.nil? || issue_date.nil? || due_date.nil? || client_name.nil?
          env.response.status_code = 400
          next {error: "Missing required invoice fields"}.to_json
        end

        # Check if invoice number already exists
        if Invoice.find_by_invoice_number(invoice_number)
          env.response.status_code = 400
          next {error: "Invoice number already exists"}.to_json
        end

        # Create new invoice
        invoice = Invoice.new(
          invoice_number,
          amount,
          issue_date,
          due_date,
          client_name,
          user.id.not_nil!,
          status,
          description
        )

        invoice.save

        env.response.status_code = 201
        invoice.to_json
      rescue ex : JSON::ParseException
        env.response.status_code = 400
        {error: "Invalid JSON: #{ex.message}"}.to_json
      rescue ex
        env.response.status_code = 400
        {error: ex.message}.to_json
      end
    end

    # Update an invoice
    put "/api/invoices/:id" do |env|
      begin
        # Get user ID from context and look up the user
        user_id = env.get("current_user_id").as(Int64)
        user = User.find(user_id)

        if user.nil?
          env.response.status_code = 401
          next {error: "User not found"}.to_json
        end

        id = env.params.url["id"].to_i64

        invoice = Invoice.find(id)

        if invoice.nil?
          env.response.status_code = 404
          next {error: "Invoice not found"}.to_json
        end

        # Verify ownership or admin
        if invoice.user_id != user.id && user.role != "admin"
          env.response.status_code = 403
          next {error: "Forbidden: You don't have permission to update this invoice"}.to_json
        end

        # Parse request body
        request_json = env.request.body.try(&.gets_to_end)
        if request_json.nil? || request_json.empty?
          env.response.status_code = 400
          next {error: "Invalid request body"}.to_json
        end

        body = JSON.parse(request_json)

        # Update fields with safe access
        if invoice_number = body["invoice_number"]?.try(&.as_s)
          invoice.invoice_number = invoice_number
        end

        if amount = body["amount"]?.try(&.as_f)
          invoice.amount = amount
        end

        if status = body["status"]?.try(&.as_s)
          invoice.status = status
        end

        if issue_date = body["issue_date"]?.try(&.as_s)
          invoice.issue_date = issue_date
        end

        if due_date = body["due_date"]?.try(&.as_s)
          invoice.due_date = due_date
        end

        if client_name = body["client_name"]?.try(&.as_s)
          invoice.client_name = client_name
        end

        invoice.description = body["description"]?.try(&.as_s)

        invoice.save

        invoice.to_json
      rescue ex : JSON::ParseException
        env.response.status_code = 400
        {error: "Invalid JSON: #{ex.message}"}.to_json
      rescue ex
        env.response.status_code = 400
        {error: ex.message}.to_json
      end
    end

    # Delete an invoice
    delete "/api/invoices/:id" do |env|
      # Get user ID from context and look up the user
      user_id = env.get("current_user_id").as(Int64)
      user = User.find(user_id)

      if user.nil?
        env.response.status_code = 401
        next {error: "User not found"}.to_json
      end

      id = env.params.url["id"].to_i64

      invoice = Invoice.find(id)

      if invoice.nil?
        env.response.status_code = 404
        next {error: "Invoice not found"}.to_json
      end

      # Verify ownership or admin
      if invoice.user_id != user.id && user.role != "admin"
        env.response.status_code = 403
        next {error: "Forbidden: You don't have permission to delete this invoice"}.to_json
      end

      invoice.delete

      env.response.status_code = 204
      nil
    end

    # Export invoices to CSV
    get "/api/invoices/export/csv" do |env|
      # Get user ID from context and look up the user
      user_id = env.get("current_user_id").as(Int64)
      user = User.find(user_id)

      if user.nil?
        env.response.status_code = 401
        next {error: "User not found"}.to_json
      end

      # Get status filter if provided
      status = env.params.query["status"]?

      # For non-admin users, only export their own invoices
      filter_user_id = user.role == "admin" && env.params.query["user_id"]? ? env.params.query["user_id"].to_i64 : user.id

      # Get all invoices without pagination
      invoices = Invoice.all(1000, 0, filter_user_id, status)

      # Generate CSV content
      csv_content = [Invoice.csv_header]
      invoices.each do |invoice|
        csv_content << invoice.to_csv
      end

      # Set response headers
      env.response.content_type = "text/csv"
      env.response.headers["Content-Disposition"] = "attachment; filename=\"invoices_export_#{Time.utc.to_s("%Y%m%d")}.csv\""

      # Return CSV content
      csv_content.join("\n")
    end
  end
end
