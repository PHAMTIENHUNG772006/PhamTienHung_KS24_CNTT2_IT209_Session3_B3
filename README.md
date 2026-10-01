# Bài 3: Bảo mật tài nguyên bằng HTTP Basic Authentication

## 1. Giới thiệu & Mục tiêu
Bài thực hành hướng dẫn cấu hình cơ chế **HTTP Basic Authentication** trên Web Server Nginx để bảo vệ các tài nguyên nhạy cảm (đường dẫn `/admin`).

- **Công cụ băm mật khẩu:** `apache2-utils` (tiện ích `htpasswd`).
- **Tệp mật khẩu:** `/etc/nginx/.htpasswd` (đặt ngoài thư mục public `/var/www/` để đảm bảo an toàn, tránh rò rỉ).
- **Tài khoản quản trị:** `admin_user`.
- **Thư mục bảo vệ:** Location `/admin`.

---

## 2. Cấu trúc thư mục nộp bài
```text
homework/session_03/ex3/  (hoặc thư mục Session3_B3)
├── default               # File cấu hình Nginx Server Block (/etc/nginx/sites-available/default)
├── admin_auth.conf       # File cấu hình dạng standalone (.conf)
├── .htpasswd             # File chứa tài khoản admin_user đã được mã hóa mẫu (password: admin123)
├── admin/
│   └── index.html        # Trang HTML nội bộ của khu vực /admin (trả về 200 OK sau khi xác thực)
├── setup.sh              # Script tự động hóa cài đặt và triển khai trên Ubuntu Server
└── README.md             # Hướng dẫn chi tiết triển khai và kiểm tra
```

---

## 3. Các bước triển khai chi tiết trên Droplet / VPS

### Bước 1: Cài đặt công cụ băm mật khẩu `apache2-utils`
```bash
sudo apt update -y
sudo apt install apache2-utils -y
```

### Bước 2: Tạo tệp mật khẩu ẩn `.htpasswd` và tài khoản `admin_user`
Tạo file `.htpasswd` lưu tại thư mục cấu hình Nginx `/etc/nginx/`:
```bash
# Tham số -c để tạo file mới
sudo htpasswd -c /etc/nginx/.htpasswd admin_user
```
Hệ thống sẽ yêu cầu nhập và xác nhận mật khẩu (ví dụ: `admin123`).

Phân quyền an toàn cho file mật khẩu:
```bash
# Cho phép Nginx (user www-data) đọc file nhưng không cho user khác đọc/ghi
sudo chown root:www-data /etc/nginx/.htpasswd
sudo chmod 640 /etc/nginx/.htpasswd
```

> **Lưu ý bảo mật:** Tuyệt đối không đặt file `.htpasswd` trong `/var/www/html/` vì nếu cấu hình sai, người ngoài có thể tải trực tiếp file mật khẩu về máy.

### Bước 3: Chuẩn bị nội dung cho thư mục `/admin`
Tạo thư mục `/var/www/html/admin` và file `index.html` mẫu để khi xác thực thành công sẽ nhận được phản hồi `200 OK`:
```bash
sudo mkdir -p /var/www/html/admin
cat << 'EOF' | sudo tee /var/www/html/admin/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Admin Dashboard</title>
</head>
<body>
    <h1>Restricted Admin Area</h1>
    <p>Dang nhap thanh cong voi tai khoan admin_user!</p>
</body>
</html>
EOF
```

### Bước 4: Cấu hình Nginx Server Block
Chỉnh sửa cấu hình Nginx (`/etc/nginx/sites-available/default`):
```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Cấu hình bảo mật HTTP Basic Authentication cho khu vực /admin
    location /admin {
        auth_basic "Restricted Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        try_files $uri $uri/ =404;
    }
}
```

**Giải thích các chỉ thị:**
- `auth_basic "Restricted Admin Area";`: Kích hoạt cơ chế HTTP Basic Auth và thiết lập Realm Name (tiêu đề xuất hiện trên hộp thoại đăng nhập của trình duyệt).
- `auth_basic_user_file /etc/nginx/.htpasswd;`: Đường dẫn tuyệt đối tới tệp chứa danh sách username/password hash.
- `try_files $uri $uri/ =404;`: Phục vụ các file trong thư mục `/admin`, nếu không thấy file trả về mã lỗi 404.

### Bước 5: Kiểm tra cú pháp và tải lại Nginx
```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

## 4. Kiểm tra và Đánh giá kết quả

### Trường hợp 1: Truy cập thông thường không có thông tin xác thực
Chạy lệnh curl:
```bash
curl -I http://<IP_ADDRESS_DROPLET>/admin
```
**Kết quả mong đợi:** Mã trạng thái `HTTP/1.1 401 Unauthorized` kèm header `WWW-Authenticate: Basic realm="Restricted Admin Area"`.
```http
HTTP/1.1 401 Unauthorized
Server: nginx/1.18.0 (Ubuntu)
Date: ...
Content-Type: text/html
Content-Length: 179
Connection: keep-alive
WWW-Authenticate: Basic realm="Restricted Admin Area"
```

### Trường hợp 2: Truy cập với tài khoản và mật khẩu hợp lệ
Chạy lệnh curl:
```bash
curl -u admin_user:admin123 http://<IP_ADDRESS_DROPLET>/admin
# Hoặc xem header:
curl -I -u admin_user:admin123 http://<IP_ADDRESS_DROPLET>/admin
```
**Kết quả mong đợi:** Mã trạng thái `HTTP/1.1 200 OK` (hoặc `301 Moved Permanently` chuyển hướng sang `/admin/` rồi trả về `200 OK`):
```http
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: ...
Content-Type: text/html
Content-Length: ...
Connection: keep-alive
```

### Trường hợp 3: Truy cập với sai mật khẩu
```bash
curl -I -u admin_user:wrongpass http://<IP_ADDRESS_DROPLET>/admin
```
**Kết quả mong đợi:** Trả về `HTTP/1.1 401 Unauthorized`.

---

## 5. Triển khai nhanh bằng Script tự động
Nếu muốn tự động hóa toàn bộ các bước trên droplet:
```bash
chmod +x setup.sh
./setup.sh
```

---

## 6. Hướng dẫn nộp bài lên GitHub
Tạo thư mục nộp bài theo đúng quy định:
```bash
mkdir -p homework/session_03/ex3
cp default homework/session_03/ex3/
cp .htpasswd homework/session_03/ex3/
# (Tùy chọn) Copy thêm admin/ và README.md nếu cần
git add homework/session_03/ex3/
git commit -m "feat(session_03): implement HTTP Basic Authentication for /admin (ex3)"
git push origin main
```
