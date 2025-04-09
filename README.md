# Crystal API

API backend dengan Crystal dan Kemal, mendukung autentikasi JWT, akses berbasis peran, dan CRUD dengan pagination/filtering.

## Fitur

- Autentikasi dengan JWT
- Role-based access control (admin/user)
- CRUD operasi untuk multiple model
- Pagination dan filtering
- Export data ke CSV
- RESTful API

## Penggunaan

### Install dependensi

```
shards install
```

### Jalankan server

```
crystal run src/crystal-lang-crud.cr
```

Server akan berjalan di http://localhost:3000

## API Endpoints

### Autentikasi

- `POST /api/auth/register` - Mendaftarkan user baru
  - Body: `{ "email": "user@example.com", "username": "user", "password": "password" }`

- `POST /api/auth/login` - Login dan mendapatkan token JWT
  - Body: `{ "identifier": "user@example.com", "password": "password" }`
  - Response: `{ "token": "jwt_token", "user": {...} }`

- `GET /api/auth/me` - Mendapatkan informasi user yang sedang login

### Invoice

- `GET /api/invoices` - Mendapatkan semua invoice dengan pagination dan filtering
  - Query params: `page`, `limit`, `status`

- `GET /api/invoices/:id` - Mendapatkan detail sebuah invoice

- `POST /api/invoices` - Membuat invoice baru
  - Body: `{ "invoice_number": "INV001", "amount": 100.0, "issue_date": "2024-04-09", "due_date": "2024-05-09", "client_name": "Client", "status": "pending", "description": "Description" }`

- `PUT /api/invoices/:id` - Memperbarui invoice

- `DELETE /api/invoices/:id` - Menghapus invoice

- `GET /api/invoices/export/csv` - Mengexport invoice ke CSV

### Report

- `GET /api/reports` - Mendapatkan semua report dengan pagination dan filtering
  - Query params: `page`, `limit`, `type`

- `GET /api/reports/:id` - Mendapatkan detail sebuah report

- `POST /api/reports` - Membuat report baru
  - Body: `{ "title": "Report Title", "content": "Report content", "report_type": "monthly" }`

- `PUT /api/reports/:id` - Memperbarui report

- `DELETE /api/reports/:id` - Menghapus report

- `GET /api/reports/export/csv` - Mengexport report ke CSV

### Admin Only

- `GET /api/admin/users` - Mendapatkan semua users (admin only)

- `PUT /api/admin/users/:id` - Memperbarui informasi user (admin only)

- `DELETE /api/admin/users/:id` - Menghapus user (admin only)

- `GET /api/admin/stats` - Mendapatkan statistik dashboard (admin only)

- `GET /api/admin/export/all` - Mengexport semua data (admin only)

## Autentikasi

Semua endpoints kecuali `/api/auth/login` dan `/api/auth/register` memerlukan header autentikasi:

```
Authorization: Bearer your_jwt_token
```

## Paginasi

Endpoints yang mendukung pagination menerima query parameters:
- `page` (default: 1)
- `limit` (default: 20)

Dan mengembalikan response dengan format:

```json
{
  "items": [...],
  "pagination": {
    "total": 100, 
    "per_page": 20,
    "current_page": 1,
    "total_pages": 5
  }
}
```

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/crystal-lang-crud/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Krisna Firdaus](https://github.com/your-github-user) - creator and maintainer
