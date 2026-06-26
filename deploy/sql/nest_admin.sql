-- ========== 全局设置 ==========
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
-- 临时禁用外键与触发器，用于批量导入（双重保险，顺序正确后可移除）
SET session_replication_role = replica;

-- ========== 通用：自动更新 updated_at 的触发器函数 ==========
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP(6);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ==================================================
-- 第一阶段：无外键依赖的基础表（被其他表引用的父表）
-- ==================================================

-- ========== 1. 验证码日志表 sys_captcha_log ==========
DROP TABLE IF EXISTS sys_captcha_log CASCADE;
CREATE TABLE sys_captcha_log (
    id serial PRIMARY KEY,
    user_id integer,
    account varchar(255),
    code varchar(255),
    provider varchar(255),
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
);
CREATE TRIGGER trigger_sys_captcha_log_updated_at
BEFORE UPDATE ON sys_captcha_log
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========== 2. 系统配置表 sys_config ==========
DROP TABLE IF EXISTS sys_config CASCADE;
CREATE TABLE sys_config (
    id serial PRIMARY KEY,
    "key" varchar(50) NOT NULL,
    name varchar(50) NOT NULL,
    value varchar(255),
    remark varchar(255),
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT idx_sys_config_key UNIQUE ("key")
);
CREATE TRIGGER trigger_sys_config_updated_at
BEFORE UPDATE ON sys_config
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_config_id_seq RESTART WITH 11;

-- 初始化数据
BEGIN;
INSERT INTO sys_config (id, "key", name, value, remark, created_at, updated_at) VALUES
(1, 'sys_user_initPassword', '初始密码', '123456', '创建管理员账号的初始密码', '2023-11-10 00:31:44.154921', '2023-11-10 00:31:44.161263'),
(2, 'sys_api_token', 'API Token', 'nest-admin', '用于请求 @ApiToken 的控制器', '2023-11-10 00:31:44.154921', '2024-01-29 09:52:27.000000');
COMMIT;

-- ========== 3. 字典类型表 sys_dict_type（被 sys_dict_item 引用，必须提前） ==========
DROP TABLE IF EXISTS sys_dict_type CASCADE;
CREATE TABLE sys_dict_type (
    id serial PRIMARY KEY,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    create_by integer NOT NULL,
    update_by integer NOT NULL,
    name varchar(50) NOT NULL,
    status smallint NOT NULL DEFAULT 1,
    remark varchar(255),
    code varchar(50) NOT NULL,
    CONSTRAINT idx_sys_dict_type_code UNIQUE (code)
);
COMMENT ON COLUMN sys_dict_type.create_by IS '创建者';
COMMENT ON COLUMN sys_dict_type.update_by IS '更新者';
CREATE TRIGGER trigger_sys_dict_type_updated_at
BEFORE UPDATE ON sys_dict_type
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_dict_type_id_seq RESTART WITH 3;

-- 初始化数据
BEGIN;
INSERT INTO sys_dict_type (id, created_at, updated_at, create_by, update_by, name, status, remark, code) VALUES
(1, '2024-01-28 08:19:12.777447', '2024-02-08 13:05:10.000000', 1, 1, '性别', 1, '性别单选', 'sys_user_gender'),
(2, '2024-01-28 08:38:41.235185', '2024-01-29 02:11:33.000000', 1, 1, '菜单显示状态', 1, '菜单显示状态', 'sys_show_hide');
COMMIT;

-- ========== 4. 字典表 sys_dict ==========
DROP TABLE IF EXISTS sys_dict CASCADE;
CREATE TABLE sys_dict (
    id serial PRIMARY KEY,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    create_by integer NOT NULL,
    update_by integer NOT NULL,
    name varchar(50) NOT NULL,
    status smallint NOT NULL DEFAULT 1,
    remark varchar(255),
    CONSTRAINT idx_sys_dict_name UNIQUE (name)
);
COMMENT ON COLUMN sys_dict.create_by IS '创建者';
COMMENT ON COLUMN sys_dict.update_by IS '更新者';
CREATE TRIGGER trigger_sys_dict_updated_at
BEFORE UPDATE ON sys_dict
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========== 5. 部门表 sys_dept（自引用，可直接创建） ==========
DROP TABLE IF EXISTS sys_dept CASCADE;
CREATE TABLE sys_dept (
    id serial PRIMARY KEY,
    name varchar(255) NOT NULL,
    "orderNo" integer DEFAULT 0,
    mpath varchar(255) DEFAULT '',
    "parentId" integer,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_sys_dept_parent_id FOREIGN KEY ("parentId") REFERENCES sys_dept(id) ON DELETE SET NULL
);
CREATE INDEX idx_sys_dept_parent_id ON sys_dept ("parentId");
CREATE TRIGGER trigger_sys_dept_updated_at
BEFORE UPDATE ON sys_dept
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_dept_id_seq RESTART WITH 18;

-- 初始化数据
BEGIN;
INSERT INTO sys_dept (id, name, "orderNo", mpath, "parentId", created_at, updated_at) VALUES
(1, '华东分部', 1, '1.', NULL, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709'),
(2, '研发部', 1, '1.2.', 1, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709'),
(3, '市场部', 2, '1.3.', 1, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709'),
(4, '商务部', 3, '1.4.', 1, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709'),
(5, '财务部', 4, '1.5.', 1, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709'),
(6, '华南分部', 2, '6.', NULL, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709'),
(7, '西北分部', 3, '7.', NULL, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709'),
(8, '研发部', 1, '6.8.', 6, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709'),
(9, '市场部', 1, '6.9.', 6, '2023-11-10 00:31:43.996025', '2023-11-10 00:31:44.008709');
COMMIT;

-- ========== 6. 菜单表 sys_menu ==========
DROP TABLE IF EXISTS sys_menu CASCADE;
CREATE TABLE sys_menu (
    id serial PRIMARY KEY,
    parent_id integer,
    path varchar(255),
    name varchar(255) NOT NULL,
    permission varchar(255),
    type smallint NOT NULL DEFAULT 0,
    icon varchar(255) DEFAULT '',
    order_no integer DEFAULT 0,
    component varchar(255),
    keep_alive smallint NOT NULL DEFAULT 1,
    show smallint NOT NULL DEFAULT 1,
    status smallint NOT NULL DEFAULT 1,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    is_ext smallint NOT NULL DEFAULT 0,
    ext_open_mode smallint NOT NULL DEFAULT 1,
    active_menu varchar(255)
);
CREATE TRIGGER trigger_sys_menu_updated_at
BEFORE UPDATE ON sys_menu
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_menu_id_seq RESTART WITH 128;

-- 初始化数据
BEGIN;
INSERT INTO sys_menu (id, parent_id, path, name, permission, type, icon, order_no, component, keep_alive, show, status, created_at, updated_at, is_ext, ext_open_mode, active_menu) VALUES
(1, NULL, '/system', '系统管理', '', 0, 'ant-design:setting-outlined', 254, '', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(2, 1, '/system/user', '用户管理', 'system:user:list', 1, 'ant-design:user-outlined', 0, 'system/user/index', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(3, 1, '/system/role', '角色管理', 'system:role:list', 1, 'ep:user', 1, 'system/role/index', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(4, 1, '/system/menu', '菜单管理', 'system:menu:list', 1, 'ep:menu', 2, 'system/menu/index', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(5, 1, '/system/monitor', '系统监控', '', 0, 'ep:monitor', 5, '', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(6, 5, '/system/monitor/online', '在线用户', 'system:online:list', 1, '', 0, 'system/monitor/online/index', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(7, 5, '/sys/monitor/login-log', '登录日志', 'system:log:login:list', 1, '', 0, 'system/monitor/log/login/index', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(8, 5, '/system/monitor/serve', '服务监控', 'system:serve:stat', 1, '', 4, 'system/monitor/serve/index', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(9, 1, '/system/schedule', '任务调度', '', 0, 'ant-design:schedule-filled', 6, '', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(10, 9, '/system/task', '任务管理', '', 1, '', 0, 'system/schedule/task/index', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(11, 9, '/system/task/log', '任务日志', 'system:task:list', 1, '', 0, 'system/schedule/log/index', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(12, NULL, '/document', '文档', '', 0, 'ion:tv-outline', 2, '', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(14, 12, 'https://www.typeorm.org/', 'Typeorm中文文档(外链)', NULL, 1, '', 3, NULL, 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 1, 1, NULL),
(15, 12, 'https://docs.nestjs.cn/', 'Nest.js中文文档(内嵌)', '', 1, '', 4, NULL, 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 1, 2, NULL),
(20, 2, NULL, '新增', 'system:user:create', 2, '', 0, NULL, 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(21, 2, '', '删除', 'system:user:delete', 2, '', 0, '', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(22, 2, '', '更新', 'system:user:update', 2, '', 0, '', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL),
(23, 2, '', '查询', 'system:user:read', 2, '', 0, '', 0, 1, 1, '2023-11-10 00:31:44.023393', '2024-02-28 22:05:52.102649', 0, 1, NULL);
COMMIT;

-- ========== 7. 角色表 sys_role ==========
DROP TABLE IF EXISTS sys_role CASCADE;
CREATE TABLE sys_role (
    id serial PRIMARY KEY,
    value varchar(255) NOT NULL,
    name varchar(50) NOT NULL,
    remark varchar(255),
    status smallint DEFAULT 1,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    "default" smallint,
    CONSTRAINT idx_sys_role_name UNIQUE (name),
    CONSTRAINT idx_sys_role_value UNIQUE (value)
);
CREATE TRIGGER trigger_sys_role_updated_at
BEFORE UPDATE ON sys_role
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_role_id_seq RESTART WITH 11;

-- 初始化数据
BEGIN;
INSERT INTO sys_role (id, value, name, remark, status, created_at, updated_at, "default") VALUES
(1, 'admin', '管理员', '超级管理员', 1, '2023-11-10 00:31:44.058463', '2024-01-28 21:08:39.000000', NULL),
(2, 'user', '用户', '', 1, '2023-11-10 00:31:44.058463', '2024-01-30 18:44:45.000000', 1),
(9, 'test', '测试', NULL, 1, '2024-01-23 22:46:52.408827', '2024-01-30 01:04:52.000000', NULL);
COMMIT;

-- ========== 8. 定时任务表 sys_task ==========
DROP TABLE IF EXISTS sys_task CASCADE;
CREATE TABLE sys_task (
    id serial PRIMARY KEY,
    name varchar(50) NOT NULL,
    service varchar(255) NOT NULL,
    type smallint NOT NULL DEFAULT 0,
    status smallint NOT NULL DEFAULT 1,
    start_time timestamp,
    end_time timestamp,
    "limit" integer DEFAULT 0,
    cron varchar(255),
    every integer,
    data text,
    job_opts text,
    remark varchar(255),
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT idx_sys_task_name UNIQUE (name)
);
CREATE TRIGGER trigger_sys_task_updated_at
BEFORE UPDATE ON sys_task
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_task_id_seq RESTART WITH 6;

-- 初始化数据
BEGIN;
INSERT INTO sys_task (id, name, service, type, status, start_time, end_time, "limit", cron, every, data, job_opts, remark, created_at, updated_at) VALUES
(2, '定时清空登录日志', 'LogClearJob.clearLoginLog', 0, 1, NULL, NULL, 0, '0 0 3 ? * 1', 0, '', '{"count":1,"key":"__default__:2:::0 0 3 ? * 1","cron":"0 0 3 ? * 1","jobId":2}', '定时清空登录日志', '2023-11-10 00:31:44.197779', '2024-02-28 22:34:53.000000'),
(3, '定时清空任务日志', 'LogClearJob.clearTaskLog', 0, 1, NULL, NULL, 0, '0 0 3 ? * 1', 0, '', '{"count":1,"key":"__default__:3:::0 0 3 ? * 1","cron":"0 0 3 ? * 1","jobId":3}', '定时清空任务日志', '2023-11-10 00:31:44.197779', '2024-02-28 22:34:53.000000'),
(4, '访问百度首页', 'HttpRequestJob.handle', 0, 0, NULL, NULL, 1, '* * * * * ?', NULL, '{"url":"https://www.baidu.com","method":"get"}', NULL, '访问百度首页', '2023-11-10 00:31:44.197779', '2023-11-10 00:31:44.206935'),
(5, '发送邮箱', 'EmailJob.send', 0, 0, NULL, NULL, -1, '0 0 0 1 * ?', NULL, '{"subject":"这是标题","to":"zeyu57@163.com","content":"这是正文"}', NULL, '每月发送邮箱', '2023-11-10 00:31:44.197779', '2023-11-10 00:31:44.206935');
COMMIT;

-- ==================================================
-- 第二阶段：一级依赖表（仅引用基础表）
-- ==================================================

-- ========== 9. 字典项表 sys_dict_item（依赖 sys_dict_type） ==========
DROP TABLE IF EXISTS sys_dict_item CASCADE;
CREATE TABLE sys_dict_item (
    id serial PRIMARY KEY,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    create_by integer NOT NULL,
    update_by integer NOT NULL,
    label varchar(50) NOT NULL,
    value varchar(50) NOT NULL,
    "order" integer,
    status smallint NOT NULL DEFAULT 1,
    remark varchar(255),
    type_id integer,
    "orderNo" integer,
    CONSTRAINT fk_sys_dict_item_type_id FOREIGN KEY (type_id) REFERENCES sys_dict_type(id) ON DELETE CASCADE
);
CREATE INDEX idx_sys_dict_item_type_id ON sys_dict_item (type_id);
COMMENT ON COLUMN sys_dict_item.create_by IS '创建者';
COMMENT ON COLUMN sys_dict_item.update_by IS '更新者';
COMMENT ON COLUMN sys_dict_item."order" IS '字典项排序';
COMMENT ON COLUMN sys_dict_item."orderNo" IS '字典项排序';
CREATE TRIGGER trigger_sys_dict_item_updated_at
BEFORE UPDATE ON sys_dict_item
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_dict_item_id_seq RESTART WITH 10;

-- 初始化数据
BEGIN;
INSERT INTO sys_dict_item (id, created_at, updated_at, create_by, update_by, label, value, "order", status, remark, type_id, "orderNo") VALUES
(1, '2024-01-29 01:24:51.846135', '2024-01-29 02:23:19.000000', 1, 1, '男', '1', 0, 1, '性别男', 1, 3),
(2, '2024-01-29 01:32:58.458741', '2024-01-29 01:58:20.000000', 1, 1, '女', '0', 1, 1, '性别女', 1, 2),
(3, '2024-01-29 01:59:17.805394', '2024-01-29 14:37:18.000000', 1, 1, '人妖王', '3', NULL, 1, '安布里奥·伊万科夫', 1, 0),
(5, '2024-01-29 02:13:01.782466', '2024-01-29 02:13:01.782466', 1, 1, '显示', '1', NULL, 1, '显示菜单', 2, 0),
(6, '2024-01-29 02:13:31.134721', '2024-01-29 02:13:31.134721', 1, 1, '隐藏', '0', NULL, 1, '隐藏菜单', 2, 0);
COMMIT;

-- ========== 10. 用户表 sys_user（依赖 sys_dept） ==========
DROP TABLE IF EXISTS sys_user CASCADE;
CREATE TABLE sys_user (
    id serial PRIMARY KEY,
    username varchar(255) NOT NULL,
    password varchar(255) NOT NULL,
    avatar varchar(255),
    email varchar(255),
    phone varchar(255),
    remark varchar(255),
    psalt varchar(32) NOT NULL,
    status smallint DEFAULT 1,
    qq varchar(255),
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    nickname varchar(255),
    dept_id integer,
    CONSTRAINT idx_sys_user_username UNIQUE (username),
    CONSTRAINT fk_sys_user_dept_id FOREIGN KEY (dept_id) REFERENCES sys_dept(id)
);
CREATE INDEX idx_sys_user_dept_id ON sys_user (dept_id);
CREATE TRIGGER trigger_sys_user_updated_at
BEFORE UPDATE ON sys_user
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_user_id_seq RESTART WITH 27;

-- 初始化数据
BEGIN;
INSERT INTO sys_user (id, username, password, avatar, email, phone, remark, psalt, status, qq, created_at, updated_at, nickname, dept_id) VALUES
(1, 'admin', 'a11571e778ee85e82caae2d980952546', 'https://thirdqq.qlogo.cn/g?b=qq&s=100&nk=1743369777', '1743369777@qq.com', '10086', '管理员', 'xQYCspvFb8cAW6GG1pOoUGTLqsuUSO3d', 1, '1743369777', '2023-11-10 00:31:44.104382', '2024-01-29 09:49:43.000000', 'bqy', 1),
(2, 'user', 'dbd89546dec743f82bb9073d6ac39361', 'https://thirdqq.qlogo.cn/g?b=qq&s=100&nk=1743369777', 'luffy@qq.com', '10010', '王路飞', 'qlovDV7pL5dPYPI3QgFFo1HH74nP6sJe', 1, '1743369777', '2023-11-10 00:31:44.104382', '2024-01-29 09:49:57.000000', 'luffy', 8),
(8, 'developer', 'f03fa2a99595127b9a39587421d471f6', '/upload/cfd0d14459bc1a47-202402032141838.jpeg', 'nami@qq.com', '10000', '小贼猫', 'NbGM1z9Vhgo7f4dd2I7JGaGP12RidZdE', 1, '1743369777', '2023-11-10 00:31:44.104382', '2024-02-03 21:41:18.000000', '娜美', 7);
COMMIT;

-- ========== 11. 任务日志表 sys_task_log（依赖 sys_task） ==========
DROP TABLE IF EXISTS sys_task_log CASCADE;
CREATE TABLE sys_task_log (
    id serial PRIMARY KEY,
    task_id integer,
    status smallint NOT NULL DEFAULT 0,
    detail text,
    consume_time integer DEFAULT 0,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_sys_task_log_task_id FOREIGN KEY (task_id) REFERENCES sys_task(id)
);
CREATE INDEX idx_sys_task_log_task_id ON sys_task_log (task_id);
CREATE TRIGGER trigger_sys_task_log_updated_at
BEFORE UPDATE ON sys_task_log
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE sys_task_log_id_seq RESTART WITH 3;

-- 初始化数据
BEGIN;
INSERT INTO sys_task_log (id, task_id, status, detail, consume_time, created_at, updated_at) VALUES
(1, 3, 1, NULL, 0, '2024-02-05 03:06:22.037448', '2024-02-05 03:06:22.037448'),
(2, 2, 1, NULL, 0, '2024-02-10 09:42:21.738712', '2024-02-10 09:42:21.738712');
COMMIT;

-- ========== 12. 访问令牌表 user_access_tokens（依赖 sys_user） ==========
DROP TABLE IF EXISTS user_access_tokens CASCADE;
CREATE TABLE user_access_tokens (
    id varchar(36) PRIMARY KEY,
    value varchar(500) NOT NULL,
    expired_at timestamp NOT NULL,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    user_id integer,
    CONSTRAINT fk_user_access_tokens_user_id FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE
);
CREATE INDEX idx_user_access_tokens_user_id ON user_access_tokens (user_id);
COMMENT ON COLUMN user_access_tokens.expired_at IS '令牌过期时间';
COMMENT ON COLUMN user_access_tokens.created_at IS '令牌创建时间';

-- 初始化数据
BEGIN;
INSERT INTO user_access_tokens (id, value, expired_at, created_at, user_id) VALUES
('09cf7b0a-62e0-45ee-96b0-e31de32361e0', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOjEsInB2IjoxLCJyb2xlcyI6WyJhZG1pbiJdLCJpYXQiOjE3MDc1MDkxNTd9.0gtKlcxrxQ-TarEai2lsBnfMc852ZDYHeSjjhpo5Fn8', '2024-02-11 04:05:58', '2024-02-10 04:05:57.696509', 1),
('3f7dffae-db1f-47dc-9677-5c956c3de39e', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOjEsInB2IjoxLCJyb2xlcyI6WyJhZG1pbiJdLCJpYXQiOjE3MDczMTEzMDJ9.D5Qpht1RquKor8WtgfGAcCp8LwG7z3FZhIwbyQzhDmE', '2024-02-08 21:08:22', '2024-02-07 21:08:22.130066', 1),
('40342c3e-194c-42eb-adee-189389839195', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOjEsInB2IjoxLCJyb2xlcyI6WyJhZG1pbiJdLCJpYXQiOjE3MDczNzIxNjF9.tRQOxhB-01Pcut5MXm4L5D1OrbMJfS4LfUys0XB4kWs', '2024-02-09 14:02:41', '2024-02-08 14:02:41.081164', 1),
('9d1ba8e9-dffc-4b15-b21f-4a90f196e39c', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOjEsInB2IjoxLCJyb2xlcyI6WyJhZG1pbiJdLCJpYXQiOjE3MDc1Mjc5MDV9.7LeiS3LBBdiAc7YrULWpmnI1oNSvR79K-qjEOlBYOnI', '2024-02-11 09:18:26', '2024-02-10 09:18:25.656695', 1),
('edbed8fb-bfc7-4fc7-a012-e9fca8ef93fb', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOjEsInB2IjoxLCJyb2xlcyI6WyJhZG1pbiJdLCJpYXQiOjE3MDczNzIxMjd9.VRuJHGca2IPrdfTyW09wfhht4x8JX207pKG-0aZyF60', '2024-02-09 14:02:07', '2024-02-08 14:02:07.390658', 1);
COMMIT;

-- ==================================================
-- 第三阶段：二级依赖表（引用一级/基础表）
-- ==================================================

-- ========== 13. 登录日志表 sys_login_log（依赖 sys_user） ==========
DROP TABLE IF EXISTS sys_login_log CASCADE;
CREATE TABLE sys_login_log (
    id serial PRIMARY KEY,
    ip varchar(255),
    ua varchar(500),
    address varchar(255),
    provider varchar(255),
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    user_id integer,
    CONSTRAINT fk_sys_login_log_user_id FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE
);
CREATE INDEX idx_sys_login_log_user_id ON sys_login_log (user_id);
CREATE TRIGGER trigger_sys_login_log_updated_at
BEFORE UPDATE ON sys_login_log
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========== 14. 角色菜单关联表 sys_role_menus（依赖 sys_role + sys_menu） ==========
DROP TABLE IF EXISTS sys_role_menus CASCADE;
CREATE TABLE sys_role_menus (
    role_id integer NOT NULL,
    menu_id integer NOT NULL,
    PRIMARY KEY (role_id, menu_id),
    CONSTRAINT fk_sys_role_menus_menu_id FOREIGN KEY (menu_id) REFERENCES sys_menu(id) ON DELETE CASCADE,
    CONSTRAINT fk_sys_role_menus_role_id FOREIGN KEY (role_id) REFERENCES sys_role(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX idx_sys_role_menus_role_id ON sys_role_menus (role_id);
CREATE INDEX idx_sys_role_menus_menu_id ON sys_role_menus (menu_id);

-- ========== 15. 用户角色关联表 sys_user_roles（依赖 sys_user + sys_role） ==========
DROP TABLE IF EXISTS sys_user_roles CASCADE;
CREATE TABLE sys_user_roles (
    user_id integer NOT NULL,
    role_id integer NOT NULL,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_sys_user_roles_role_id FOREIGN KEY (role_id) REFERENCES sys_role(id),
    CONSTRAINT fk_sys_user_roles_user_id FOREIGN KEY (user_id) REFERENCES sys_user(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX idx_sys_user_roles_user_id ON sys_user_roles (user_id);
CREATE INDEX idx_sys_user_roles_role_id ON sys_user_roles (role_id);

-- 初始化数据
BEGIN;
INSERT INTO sys_user_roles (user_id, role_id) VALUES
(1, 1),
(2, 2),
(8, 2);
COMMIT;

-- ========== 16. 待办表 todo（依赖 sys_user） ==========
DROP TABLE IF EXISTS todo CASCADE;
CREATE TABLE todo (
    id serial PRIMARY KEY,
    value varchar(255) NOT NULL,
    user_id integer,
    status smallint NOT NULL DEFAULT 0,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    CONSTRAINT fk_todo_user_id FOREIGN KEY (user_id) REFERENCES sys_user(id)
);
CREATE INDEX idx_todo_user_id ON todo (user_id);
CREATE TRIGGER trigger_todo_updated_at
BEFORE UPDATE ON todo
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE todo_id_seq RESTART WITH 2;

-- 初始化数据
BEGIN;
INSERT INTO todo (id, value, user_id, status, created_at, updated_at) VALUES
(1, 'nest.js', NULL, 0, '2023-11-10 00:31:44.139730', '2023-11-10 00:31:44.147629');
COMMIT;

-- ========== 17. 文件存储表 tool_storage（依赖 sys_user） ==========
DROP TABLE IF EXISTS tool_storage CASCADE;
CREATE TABLE tool_storage (
    id serial PRIMARY KEY,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    updated_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    name varchar(200) NOT NULL,
    "fileName" varchar(200),
    ext_name varchar(255),
    path varchar(255) NOT NULL,
    type varchar(255),
    size varchar(255),
    user_id integer
);
COMMENT ON COLUMN tool_storage.name IS '文件名';
COMMENT ON COLUMN tool_storage."fileName" IS '真实文件名';
CREATE TRIGGER trigger_tool_storage_updated_at
BEFORE UPDATE ON tool_storage
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
ALTER SEQUENCE tool_storage_id_seq RESTART WITH 79;

-- 初始化数据
BEGIN;
INSERT INTO tool_storage (id, created_at, updated_at, name, "fileName", ext_name, path, type, size, user_id) VALUES
(78, '2024-02-03 21:41:16.851178', '2024-02-03 21:41:16.851178', 'cfd0d14459bc1a47-202402032141838.jpeg', 'cfd0d14459bc1a47.jpeg', 'jpeg', '/upload/cfd0d14459bc1a47-202402032141838.jpeg', '图片', '33.92 KB', 1);
COMMIT;

-- ========== 18. 刷新令牌表 user_refresh_tokens（依赖 user_access_tokens） ==========
DROP TABLE IF EXISTS user_refresh_tokens CASCADE;
CREATE TABLE user_refresh_tokens (
    id varchar(36) PRIMARY KEY,
    value varchar(500) NOT NULL,
    expired_at timestamp NOT NULL,
    created_at timestamp(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
    "accessTokenId" varchar(36),
    CONSTRAINT rel_user_refresh_tokens_access_token_id UNIQUE ("accessTokenId"),
    CONSTRAINT fk_user_refresh_tokens_access_token_id FOREIGN KEY ("accessTokenId") REFERENCES user_access_tokens(id) ON DELETE CASCADE
);
COMMENT ON COLUMN user_refresh_tokens.expired_at IS '令牌过期时间';
COMMENT ON COLUMN user_refresh_tokens.created_at IS '令牌创建时间';

-- 初始化数据
BEGIN;
INSERT INTO user_refresh_tokens (id, value, expired_at, created_at, "accessTokenId") VALUES
('202d0969-6721-4f6f-bf34-f0d1931d4d01', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoiRTRpOXVYei1TdldjdWRnclFXVmFXIiwiaWF0IjoxNzA3MzcyMTYxfQ.NOQufR5EAPE2uZoyenmAj9H7S7qo4d6W1aW2ojDxZQc', '2024-03-09 14:02:41', '2024-02-08 14:02:41.091492', '40342c3e-194c-42eb-adee-189389839195'),
('461f9b7c-e500-4762-a6d9-f9ea47163064', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoicXJvTWNYMnhNRW5uRmZGWkQtaUx0IiwiaWF0IjoxNzA3MzExMzAyfQ.dFIWCePZnn2z2Qv1D5PKBKXUwVDI0Gp091MIOi9jiIo', '2024-03-08 21:08:22', '2024-02-07 21:08:22.145464', '3f7dffae-db1f-47dc-9677-5c956c3de39e'),
('b375e623-2d82-48f0-9b7a-9058e3850cc6', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoicDhUMzdGNFFaUDJHLU5yNGVha21wIiwiaWF0IjoxNzA3MzcyMTI3fQ.fn3It6RKIxXlKmqixg0BMmY_YsQmAxtetueqW-0y1IM', '2024-03-09 14:02:07', '2024-02-08 14:02:07.410008', 'edbed8fb-bfc7-4fc7-a012-e9fca8ef93fb'),
('e620ccc1-9e40-4387-9f21-f0722e535a63', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoiNE5WdmFIc2hWaU05ZFh0QnVBaHNsIiwiaWF0IjoxNzA3NTI3OTA1fQ.zzyGX0mOJe6KWpTzIi7We9d9c0MRuDeGC86DMB0Vubs', '2024-03-11 09:18:26', '2024-02-10 09:18:25.664251', '9d1ba8e9-dffc-4b15-b21f-4a90f196e39c'),
('f9a003e8-91b7-41ee-979e-e39cca3534ec', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1dWlkIjoiWGJQdl9SVjFtUl80N0o0TGF0QlV5IiwiaWF0IjoxNzA3NTA5MTU3fQ.oEVdWSigTpAQY7F8MlwBnedldH0sJT1YF1Mt0ZUbIw4', '2024-03-11 04:05:58', '2024-02-10 04:05:57.706763', '09cf7b0a-62e0-45ee-96b0-e31de32361e0');
COMMIT;

-- ========== 恢复外键与触发器 ==========
SET session_replication_role = default;
