# 评估：用 nginx 原生 ACME 替代 cert-manager 的可行性

## 结论

**当前不可行** —— 被两个硬性阻塞点挡住，其中第一个是决定性的：

1. **nginx 原生 ACME 只支持 HTTP-01，而我们必需 DNS-01**（因为要签发
   `*.g41.moe` 通配符）。
2. 附加域名 `maidkihara.moe` / `kitsunori.moe` 解析到 **Cloudflare**，
   不指向本 VPS —— HTTP-01 对它们也无法完成验证。

第二个阻塞点可以通过调整消除，**第一个不能**（除非上游实现 DNS-01）。

---

## 一、nginx 原生 ACME 是什么

F5 在 nginx 1.29.0 引入了 `ngx_http_acme_module`，用 nginx 自身完成
ACMEv2 签发/续期，不再需要 certbot/cert-manager 这类外部客户端。

- 官方文档（**OSS 版**）：<https://nginx.org/en/docs/http/ngx_http_acme_module.html>
- 源码：<https://github.com/nginx/nginx-acme>
- Plus 文档：<https://docs.nginx.com/nginx/admin-guide/dynamic-modules/acme/>
- Let's Encrypt 公告：<https://letsencrypt.org/2025/09/11/native-acme-for-nginx.html>
- 发布博客：<https://blog.nginx.org/blog/native-support-for-acme-protocol>

**重要区分**：该模块同时以 `nginx-module-acme`（开源）与
`nginx-plus-module-acme`（商业订阅）分发。**OSS 版可用**，
不强制 Plus —— 这点我实测确认过（见第三节）。

### 配置形态

```nginx
resolver 127.0.0.1:53;

acme_issuer example {
    uri https://acme-v02.api.letsencrypt.org/directory;
    contact admin@example.test;
    state_path /var/cache/nginx/acme-example;
    accept_terms_of_service;
}

acme_shared_zone zone=ngx_acme_shared:1M;

server {
    listen 443 ssl;
    server_name .example.test;
    acme_certificate example;
    ssl_certificate     $acme_certificate;
    ssl_certificate_key $acme_certificate_key;
    ssl_certificate_cache max=2;   # 避免每请求解析证书
}

server {
    listen 80;                     # 必需：处理 HTTP-01 challenge
    location / { return 404; }
}
```

关键指令：

| 指令 | 作用 |
|---|---|
| `acme_issuer name { ... }` | 定义签发者（`uri` 必填，指向 ACME directory） |
| `challenge type` | **仅 `http-01` 与 `tls-alpn-01`** |
| `state_path path\|off` | 持久化 account key / 证书 / 私钥（**跨重启必需**） |
| `acme_certificate issuer [identifiers] [key=alg]` | 在 server 块内签发证书 |
| `$acme_certificate` / `$acme_certificate_key` | 供 `ssl_certificate*` 使用 |

---

## 二、决定性阻塞点：只有 HTTP-01，没有 DNS-01

模块 README 明确写着（我直接读了源码仓库的 main 分支与 v0.3.1 tag）：

> **- Only HTTP-01 challenge type is supported**

`challenge` 指令接受的值为：

- `http-01`（`http`）
- `tls-alpn-01`（`tls-alpn`）

**没有 `dns-01`。**

### 为什么这对我们是致命的

我们当前的证书 SAN（实测 `kubectl get secret g41-tls`）：

```
DNS:*.g41.moe, DNS:g41.moe, DNS:kitsunori.moe, DNS:maidkihara.moe
```

**`*.g41.moe` 是通配符**。而 ACME 规范（RFC 8555）规定：
**通配符标识只能通过 DNS-01 验证**。这不是实现选择，是协议要求 ——
HTTP-01 需要把 token 放在 `<domain>/.well-known/acme-challenge/`，
对 `*.g41.moe` 这种「不代表任何具体主机」的名字根本无从放置。

所以我们**必须**用 DNS-01，而 nginx 原生模块不提供。

### 现有架构为何能工作

我们当前用 cert-manager 的 **Cloudflare DNS01 solver**：

```yaml
solvers:
- dns01:
    cloudflare:
      apiKeySecretRef: { key: CF_Key, name: g41-env }
    cnameStrategy: Follow
```

它通过 Cloudflare API 写 `_acme-challenge` TXT 记录 —— 这正是 nginx 模块
缺失的能力。

---

## 三、次要阻塞点：附加域名不在本机

`maidkihara.moe` / `kitsunori.moe` 的解析（实测）：

| 域名 | 解析到 |
|---|---|
| `g41.moe` | 本 VPS（`160.251.214.39` / IPv6） |
| `maidkihara.moe` | **Cloudflare**（`2606:4700:3032::6815:2a64`） |
| `kitsunori.moe` | **Cloudflare**（`2606:4700:3031::6815:2bd6`） |

HTTP-01 要求 CA 能直接访问 `http://<domain>/.well-known/acme-challenge/<token>`。
这两个域名由 Cloudflare 代理，落到我们的 nginx 上的是 CF 的请求，且
`g41.moe` 的 80 端口现在**直接 301 跳转到 https**：

```
HTTP/1.1 301 Moved Permanently
Location: https://g41.moe/.well-known/acme-challenge/x
```

虽然 ACME 允许重定向，但 nginx 模块需要一个**能返回 200 的 80 端口 location**，
且附加域名的流量路径要能到达本机。

> 这一项**可以通过调整消除**：把附加域名改为 DNS-only（去掉 CF 代理）
> 并让它们指向 VPS。但它与第一个阻塞点独立 —— 即便解决了这个，
> 通配符仍然签不出来。

---

## 四、其他可行性因素（实测）

### 4.1 OSS 包确实存在（非 Plus 专属）

担心「必须有商业订阅」是多余的。nginx.org 官方 Alpine 仓库实测包含：

```
P:nginx-module-acme
V:1.29.8.0.3.1-r1
A:x86_64
```

包版本号形如 `<nginx 版本>.<模块版本>`，即**模块与 nginx 主版本绑定编译**。

### 4.2 版本错配

| | 版本 |
|---|---|
| 本机 nginx | **1.31.5** |
| 仓库中 nginx-module-acme 最高 | **1.29.8**（配 nginx 1.29.8） |

nginx 动态模块必须与主程序**同版本且同编译选项**（ABI 绑定），
不能把 1.29 的模块加载进 1.31。要采用就得：

- 把 nginx 镜像降级固定到 1.29.8，或
- 自行从源码编译匹配 1.31.5 的模块

这与项目「浮动 tag，跟随上游最新」的镜像策略冲突，且引入一个需随
nginx 升级同步重建的构建链。

### 4.3 Alpine 官方仓库没有它

实测 `edge/community` 的 APKINDEX 中 **`nginx-module` 条目数为 0** ——
Alpine 自身不打包该模块。必须加 nginx.org 的私有仓库
（`https://nginx.org/packages/mainline/alpine/...`）并处理其签名密钥，
或自建镜像。

### 4.4 与 k8s 声明式模型的契合度：偏差

- `acme_certificate` 是 **server 块级指令**，签发与 vhost 配置耦合；
  而当前 cert-manager 是**独立的 `Certificate` CR**，与 nginx 解耦。
- 证书状态（有效期、续期时间）目前可用
  `kubectl get certificate` / `describe` 查询；模块方案下只能看
  `state_path` 目录与 nginx error log。
- 模块的 `state_path` 需持久化（**否则 account key 与证书重启即丢**），
  在 k8s 下要挂 PVC 或 hostPath —— 而我们当前**刻意不用 PVC**
  （`local-storage` 已禁用），这会破坏既有设计。

### 4.5 与现有 `g41-cert-reload.timer` 的关系

若改用 nginx 原生 ACME，证书由 nginx 自己持有（`$acme_certificate`），
那么：

- `hy2` 与 `dns` 这两个**非 nginx 消费者**怎么办？它们当前直接挂载
  `g41-tls` Secret。nginx 原生 ACME 把私钥留在 nginx 的 `state_path`，
  **不产出 k8s Secret** —— 这两个服务将失去证书来源。
- 除非再加一层「从 nginx state_path 导出证书到 Secret」的同步器，
  这反而比现在更绕。

---

## 五、总评

| 维度 | 评价 |
|---|---|
| OSS 可用性 | ✅ 存在，非 Plus 专属 |
| **通配符支持** | ❌ **不支持（仅 HTTP-01）—— 决定性** |
| 附加域名 | ⚠️ 可调整消除 |
| 版本匹配 | ⚠️ 需降级 nginx 或自建编译链 |
| Alpine 打包 | ⚠️ 需第三方仓库或自建 |
| k8s 契合度 | ⚠️ 与声明式模型及「无 PVC」设计冲突 |
| 多消费者支持 | ❌ 不产出 Secret，hy2/dns 失去来源 |

**结论：不迁移。** 保留 cert-manager + Cloudflare DNS01。

主因是通配符 + DNS-01 的协议约束（不可绕过），外加它不产出 k8s Secret
这一点会直接破坏 hy2/dns 的证书供给。

---

## 六、什么情况下值得重新评估

1. **上游实现 DNS-01**（可关注 nginx-acme 仓库；届时通配符可用）。
2. **放弃通配符** —— 若改为显式列出所有子域，HTTP-01 即可行。
   代价：每加一个子域都要改证书配置并重签；且附加域名仍需 DNS-only 指向本机。
3. **放弃 cert-manager 的 3 个 Pod**（约 64MB）成为刚需时 ——
   但即便如此，仍需先解决 hy2/dns 的证书供给问题。

## 七、当前方案的实际成本（作为对比基线）

保留 cert-manager 的成本并不高：

| 项 | 成本 |
|---|---|
| cert-manager（controller+cainjector+webhook） | ~64 MB / 3 Pod |
| 磁盘 | 4 个镜像（含 startupapicheck 可清理） |
| 运维 | 已有 `g41-cert-reload.timer` 处理分发，全自动 |

相比之下，迁移到 nginx 原生 ACME 需要：降级 nginx、自建模块编译链、
改造 hy2/dns 的证书来源、引入持久化存储 —— **成本远高于收益，
且核心功能（通配符）无法实现。**
