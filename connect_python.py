import mysql.connector

# Thông tin kết nối đến cơ sở dữ liệu hiện có
old_db_config = {
'host': 'localhost',
'user': 'root ',
'password': '1111',
'database': 'airportdb'
}
# Thông tin kết nối đến cơ sở dữ liệu mới
new_db_config = {
'host': 'localhost',
'user': 'root',
'password': '1111',
'database': 'new_airportdb'
}
# Kết nối đến cơ sở dữ liệu cũ và mới
old_db = mysql.connector.connect( ** old_db_config)
new_db = mysql.connector.connect( ** new_db_config)

# Tạo một con trỏ để thực thi các câu Lệnh SQL
old_cursor = old_db.cursor()
new_cursor = new_db. cursor()
try:
# Tạo cơ sở dữ liệu mới
new_cursor.execute("CREATE DATABASE IF NOT EXISTS new_airportdb")
new_db. commit()

# Truy vấn tất cả các bảng trong cơ sở dữ liệu cũ
old_cursor.execute("SHOW TABLES")
tables = old_cursor. fetchall()

# Sao chép dữ liệu từ cac bang trong cơ sở dữ liệu cũ sang cơ sở dữ liệu mới
for table in tables:
table_name = table[0]
create_table_query = f"CREATE TABLE IF NOT EXISTS new_airportdb.{table_name}
LIKE airportdb.{table_name}"
new_cursor.execute(create_table_query)
copy_data_query = f"INSERT INTO new_airportdb.{table_name}
[SELECT * FROM airportdb.{table_name]"
new_cursor.execute(copy_data_query)

# Commit các thay đổi
new_db.commit()
print("Dữ liệu đa được sao chep thanh cong!")

except mysql.connector.Error as error:
print("Loi:", error)

finally:
# Đóng các kết nối
if old_db.is_connected():
old_cursor.close()
old_db.close()
if new_db.is_connected():
new_cursor.close()
new_db.close()

