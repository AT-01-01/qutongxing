-- 在 psql 中执行本脚本，创建 qutongxing 独立数据库。
-- 推荐连接 postgres 默认库后执行：
-- psql -U postgres -d postgres -f scripts/create_qutongxing_db.sql

DROP DATABASE IF EXISTS qutongxing;
CREATE DATABASE qutongxing
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    TEMPLATE template0;
