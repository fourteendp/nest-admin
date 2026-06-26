# nest-admin

![](https://img.shields.io/github/commit-activity/m/buqiyuan/nest-admin) ![](https://img.shields.io/github/license/buqiyuan/nest-admin) ![](https://img.shields.io/github/repo-size/buqiyuan/nest-admin) ![](https://img.shields.io/github/languages/top/buqiyuan/nest-admin)

**基于 NestJs + TypeScript + TypeORM + Redis + PostgreSQL + Vue3 + Ant Design Vue 编写的一款简单高效的前后端分离的权限管理系统。希望这个项目在全栈的路上能够帮助到你。**

- 前端项目地址：[传送门](https://github.com/buqiyuan/vue3-antdv-admin)

## 演示地址

<ul>
  <li>
    <details>
      <summary>
        <a href="https://vue3-antdv-admin.pages.dev/" target="_blank">
        https://vue3-antdv-admin.pages.dev/
        </a>（墙内）
      </summary>
      只读，可以完整地预览项目的初始效果
    </details>
  </li>

  <li>
   <a href="https://nest-admin.buqiyuan.top/api-docs/" target="_blank">
      Swagger 文档
   </a>
  </li>
</ul>

## 项目启动前的准备工作

- sql 文件：[/deploy/sql/nest_admin.sql](https://github.com/buqiyuan/nest-admin/tree/main/deploy/sql/nest_admin.sql) 用于数据库初始化
- 项目相关配置，如：配置 postgresql 和 redis 连接
  - 公共配置: [.env](https://github.com/buqiyuan/nest-admin/blob/main/.env)
  - 开发环境: [.env.development](https://github.com/buqiyuan/nest-admin/blob/main/.env.development)
  - 生产环境: [.env.production](https://github.com/buqiyuan/nest-admin/blob/main/.env.production)

## 环境要求

- `nodejs` `20`+
- `postgresql` `14`+
- 使用 [`pnpm`](https://pnpm.io/zh/) 包管理器安装项目依赖

演示环境账号密码：

|   账号    |  密码  |    权限    |
| :-------: | :----: | :--------: |
| admin | a123456 | 超级管理员 |

> 所有新建的用户初始密码都为 a123456

本地部署账号密码：

|   账号    |  密码  |    权限    |
| :-------: | :----: | :--------: |
| admin | a123456 | 超级管理员 |

## 本地开发

- 获取项目代码

```bash
git clone https://github.com/buqiyuan/nest-admin
```

- 安装依赖

```bash
cd nest-admin

pnpm install

```

- 运行
  启动成功后，通过 <http://localhost:7001/api-docs/> 访问。

```bash
pnpm dev
```

- 打包

```bash
pnpm build
```

## 数据库迁移

1. 更新数据库(或初始化数据)

```bash
pnpm migration:run
```

2. 生成迁移

```bash
pnpm migration:generate
```

3. 回滚到最后一次更新

```bash
pnpm migration:revert
```

更多细节，请移步至[官方文档](https://typeorm.io/migrations)

> [!TIP]
> 如果你的`实体类`或`数据库配置`有更新，请执行`npm run build`后再进行数据库迁移相关操作。

## 系统截图

![](https://s1.ax1x.com/2021/12/11/oTi1nf.png)

![](https://s1.ax1x.com/2021/12/11/oTithj.png)

![](https://s1.ax1x.com/2021/12/11/oTirHU.png)

![](https://s1.ax1x.com/2021/12/11/oTia3n.png)

### 欢迎 Star && PR

**如果项目有帮助到你可以点个 Star 支持下。有更好的实现欢迎 PR。**

### 致谢

- [sf-nest-admin](https://github.com/hackycy/sf-nest-admin)

### LICENSE

[MIT](LICENSE)
