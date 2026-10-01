#!/usr/bin/env bash
# ==============================================================================
# Script Triển Khai Bài 3: Bảo mật tài nguyên bằng HTTP Basic Authentication
# ==============================================================================

set -euo pipefail

echo "==> [1/5] Cài đặt công cụ apache2-utils và nginx (nếu chưa có)..."
sudo apt update -y
sudo apt install -y nginx apache2-utils

echo "==> [2/5] Tạo tài khoản admin_user trong file /etc/nginx/.htpasswd..."
# Bạn có thể đổi mật khẩu 'admin123' thành mật khẩu mong muốn
# Tham số -b cho phép truyền trực tiếp mật khẩu qua dòng lệnh, -c để tạo file mới
sudo htpasswd -b -c /etc/nginx/.htpasswd admin_user admin123
sudo chmod 640 /etc/nginx/.htpasswd
sudo chown root:www-data /etc/nginx/.htpasswd

echo "==> [3/5] Tạo thư mục và trang web quản trị /var/www/html/admin/..."
sudo mkdir -p /var/www/html/admin
sudo cp ./admin/index.html /var/www/html/admin/index.html 2>/dev/null || cat << 'EOF' | sudo tee /var/www/html/admin/index.html
<!DOCTYPE html>
<html>
<head><title>Admin Area</title></head>
<body><h1>200 OK - Welcome admin_user to Restricted Area!</h1></body>
</html>
EOF

echo "==> [4/5] Áp dụng cấu hình Nginx Server Block..."
sudo cp ./default /etc/nginx/sites-available/default
sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

echo "==> [5/5] Kiểm tra cú pháp và khởi động lại Nginx..."
sudo nginx -t
sudo systemctl reload nginx

echo "=============================================================================="
echo "Triển khai hoàn tất! Hãy kiểm tra bằng curl:"
echo "1. Không kèm tài khoản (Mong đợi: HTTP 401 Unauthorized):"
echo "   curl -I http://localhost/admin"
echo ""
echo "2. Kèm tài khoản admin_user (Mong đợi: HTTP 200 OK):"
echo "   curl -u admin_user:admin123 http://localhost/admin"
echo "=============================================================================="
