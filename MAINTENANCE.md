# 维护记录

中文 | [English](docs/MAINTENANCE.en.md) | [日本語](docs/MAINTENANCE.ja.md) 

## 2026-10-12

- **撤下 gh-proxy 首页磁贴，换上自我介绍磁贴 `tile_kitsunome`**（维护者要求）：
  - `tile_gh-proxy` 删除 `tile.json` + `i18n/`，`depends` 由 `home, nginx` 收窄为 `nginx`；
    **只撤磁贴、不撤服务**——`/gr/` 反代照常。目录名不动（改名会一并改掉已部署的片段名与
    `G41_KITS` 记账），已在 AGENTS.md 记作「已知例外」，并写明新模块别照抄这个形状
  - 新磁贴 `tile_kitsunome`（🐾 / 短名 `kitsunome` / `guide` 三段）介绍维护者是谁、怎么干活；
    三语 i18n 一次写齐。文案**只写门面部分**（G41KiTS 是公开仓库且 CD 自动上线），
    部署细节与本机私有记录不入此仓——边界写进 `docs/*/tile_kitsunome.md`
  - 部署：`kits add tile_kitsunome` + 手工删除两处历史遗留（`.rd/data/tiles/tile_gh-proxy.json`、
    `.rd/data/i18n/tile_gh-proxy/` —— 收窄 depends 后 `kits del` 不再发现它们）+ 热重载
  - 实测：`/data/tiles` 12 项、含 `tile_kitsunome`、不含 `tile_gh-proxy`；三语 `kitsunome_*`
    就位、`ghp_*` 消失；三语排序一致（kitsunome 紧随 kihara777）；首页与 `/gr/` 均 200
  - 磁贴补上**门面链接**（维护者提醒）：<https://grg41.github.io/>（3 页 × 3 语）。
    链接文本三语相同，**href 跟随首页语言**（zh → `/`、ja → `/ja/`、en → `/en/`）；
    段落值走 i18n 键而非内联 HTML，好让 L1b 的键覆盖检查强制三语都写
- **修掉 `kits verify` 的静默失效**：`local m="$1" md="kits/$m"` 中 `$m` 在赋值**前**展开，
  `md` 恒为 `kits/`，于是 L1/L3/L4 与「模块不存在」的报错全落空——实测
  `kits verify no-such-module` 返回 PASS/exit 0，而 `kits add` 正拿它当闸门。
  拆开后 31 个模块重新全过（无假阳性），四种反例（缺键 / 坏 JSON / 空 i18n 目录 /
  compose=file 无 Dockerfile）各翻一次脸
- **L1 补磁贴 i18n 键覆盖检查**：缺键、i18n 不是合法 JSON、`i18n/` 下无 `*.json` 各报 ERR。
  缺键在页面上**不报错**（`t()` 原样渲染键名），i18n 解析失败 server.js 也只 `console.error`
- **`kits reload` 两处修正 + 一条记账修正**：k8s 分支原写 `deploy/api`，而 api 是
  **redis Deployment 的第二个容器**，该 exec 在本部署里永远失败；compose 分支失败时改成
  按 pod 标签报出真诊断（backend 漂移）；`kits add --dry-run` 不再写 `G41_KITS`
- **实机发现（未修，留维护者定夺）**：
  - VPS `.env` 原无 `G41_BACKEND=k8s`（部署早就是 k3s），`kits reload` 必走 compose 分支；
    本次已 `./g41.sh backend k8s` 补上。**注意 `deploy-local.sh` 整份推 `.env`，本地 `.env`
    没有该键，下次推送会再抹掉**
  - VPS `.env` 无 `RELOAD_SECRET`（容器内为空），而 server.js 在 expected 为空时**不校验**；
    当前 `/admin/` 未被 nginx 代理故未暴露，但仓库里的 `kits/redis/site/location.conf` 带着
    `/admin/`，一旦重装 redis 就会把这个不校验的 reload 端点挂上公网
  - `.gx/conf.d/locations/999-redis.conf` 与仓库源**不同 inode、内容更旧**（仅 `/data/`）——
    硬链接被 rsync 换掉后未重装的典型形态，现场与仓库不一致
  - 三语维护日志本身有历史分歧（zh 独有 2026-08-24 / 06-24 / 06-22，en·ja 独有 2026-07-14），
    本次条目三语同步，历史分歧未动
- **磁贴文案修正（她指出的）**：名字那行原写「キツのめ 即『狐の目』」——那是**我的读法**，不是
  名字的来处。维护者指出 `kitsunome` 当初是考虑到 **つめ**（爪）而取的，「小爪」正由此而来；
  三语 i18n 与三语文档已改写（キツ（狐）・の・め + 我读作「狐の目」+ 里头的 つめ（爪）→ 小爪）
- **首屏空白期补上 WP8 启动环，并顺手抓出冷启动白屏的根因**（维护者观测「磁贴载入花了更多时间」）：
  - 先量：服务端不是瓶颈（容器内直连 API `/data/tiles` **2.6ms**、`/data/i18n_zh` **2.7ms**，
    首屏负载约 45KB）；代价在**结构**——六个请求全到齐才 `init()`，`#g41-app` 在那之前一直 `opacity:0`
  - 加 `#g41-loading`（纯 CSS 的 5 点环，JS 到达前第一帧就显示；`prefers-reduced-motion` 下退化为静止 5 点），
    `endLoading()` 收在 `applyStatus()` 里（成功页与状态码页共用）；`bootFailed()` 把环换成
    「読み込みに失敗しました / Failed to load」+ 错误原文——**环一直转等于在说「还在读」，比白屏更坏**
  - 失败态上线后**当场抓到它自己**：无缓存冷启动 **5/5** 报 `closeDetail is not defined`、整页 `opacity:0`。
    根因是 `tiles.js` 排在 `G41.js` **之后**，而 `G41.js` 一执行就发起数据请求，回调 `init()`
    要用 `tiles.js` 的函数 → 数据先回来就抛 ReferenceError（旧版没有失败态，所以它的表现是
    「白屏 + console 一行」，维护者感觉到的「更慢」很可能就是它）
  - 修法：`tiles.js` 挪到 `G41.js` 之前（顶层只有函数声明、不依赖 G41.js）；线上无缓存冷启动 **5/5 通过**
  - 判据：本地桩把 `tiles.js` 延迟 3 秒 → 修复前 `is-failed`+ReferenceError+appOpacity 0，
    修复后同条件环已移除、appOpacity 1、无错误；线上用无头 chromium（CDP 同一会话先读状态再取像素）
    拍下启动环、失败态、已加载三种状态
- **启动环第二版（放大 + 可见文案 + 暗幕）与静态资源的 `Cache-Control`**（维护者发来手机截图：
  「加载动画没有出现或者不够明显」）：
  - 量出环确实太弱：412×915 手机视口下第一版是 64px 环 + 6px 点（直径占屏宽 15%、点占 1.4%）。
    现在按 `vmin` 缩放（手机约 99px / 9px）、环下加**可见**的「読み込み中 / Loading」、
    整体压一层 `rgba(0,0,0,.55)` 暗幕；失败态不变，`.g41-sr` 随文案转可见而删除
  - 判据：本地桩 + 手机视口（412×915 @2.6）截图前后对比；CDP 量到 overlay 铺满 (0,0,412,915)、
    环与文案组成的列正好居中（跨度 384–530，中心 457 = 915/2）
  - **顺带修掉「她可能拿到旧文件」的结构性原因**：站点原先一个 `Cache-Control` 都没有，
    浏览器按 `Last-Modified` 走启发式缓存（10%）→ 部署后可能是「旧 HTML 配新 JS/CSS」的混合体。
    `kits/nginx/store/nginx.conf` 的 server 块加 `add_header Cache-Control "no-cache" always`；
    实测 `no-cache` 生效、`If-None-Match` 返回 304（再验证很便宜）
  - **发现（未修，修它要重启 pod，留维护者定夺）**：`kits/nginx/k8s/deployment.yaml` 的
    `reloader` 容器①**没有任何 volumeMounts**，`find` 的是自己镜像里的目录，永远看不到
    挂载的 ConfigMap/Secret（`/tmp/.last` 停在 2026-09-26）②即使挂上了，`kill -HUP 1` 也打错进程：
    pod 开了 `shareProcessNamespace`，PID 1 是 **pause** 容器。后果是 `k8s conf` / CD 重渲染
    ConfigMap 之后 **nginx 仍跑旧配置**，只有 pod 重启才生效——本次是靠手工
    `kubectl exec … nginx -s reload` 才让 `Cache-Control` 上线的。
    `k8s/host/g41-cert-reload.sh` 里「交由 reloader sidecar 热加载」的说法因此不成立
- **启动环第三版：五点成链、就绪顺序、加载期不显示背景**（维护者同日再反馈，附三张截图）：
  - **成链**：旧实现每个点各自跑完整条 keyframes（含各自的停顿），相位只保证分布不保证顺序——
    实测同一时刻相邻间隔 **96°/282°/81°/147°/114°**（两颗几乎重叠），「各自为政」是准确的描述。
    现在五点共用同一条旋转曲线（2.4s / `cubic-bezier(.5,.08,.5,.92)`），只用负延迟错开相位：
    顺序永不乱、缓动让弧长呼吸；点径 100/85/70/55/42% 成彗尾。实测内部间隔 **38–44°**、单调有序
  - **收环时机**：`main-entry` 原先在 `init()` 里就加上 → 入场动画在 `opacity:0` 幕后播完。
    移到 `revealApp()`：先收环，再在 rAF 里加入场动画并淡入。线上实测时序
    `ring 1 →（0.28 且 entry:true、tiles:12）→ app 1 → 环移除`
  - **加载期不显示背景**：覆盖层由半透明暗幕改为**不透明黑**（WP8 启动画面本是纯色），
    立绘抢视线的问题一并消失
  - 判据：本地桩 + CDP 量化采样（角度间隔、就绪时序）；`--reduced` 下 `animationName=none`（静止环）
- **首屏「像 splashscreen 一样优先」：样式全部内联 + 开启 gzip**（维护者：别让用户在看到加载动画前也等很久）：
  - 量到根因：head 里 3 个 `<link rel="stylesheet">`（共 15.4KB）是**渲染阻塞**的——HTML 到了也只是
    白屏。用桩把样式表延迟 3 秒实测 **FCP = 3024 / 6908ms**（正好等于样式表到达的时刻）
  - 三份 CSS 全部**内联进 `G41.html` 的 `<style>`**（脚本搬运并自证逐字节一致），`.css` 源文件随之
    删除（单一来源）；同条件实测 **FCP = 36 / 928ms**、`performance` 里 `/css/` 请求 **0** 个。
    CSP 已有 `style-src 'self' 'unsafe-inline'`，内联 `<style>` 不需要改策略
  - **站点此前完全没有压缩**（nginx 默认 off，本仓 nginx.conf 一个 `gzip` 指令都没有）：
    加 `gzip on` / `gzip_vary on` 等；线上实测首页 HTML **19728 → 6873 字节**
  - 部署：`kits add home -C` + 手工删除遗留的 `.wr/G41/css/`（重装不会删「源文件已移除」的旧硬链接）
    + `kits add nginx -C` + `k8s conf` + `nginx -t` + 手工 `nginx -s reload`（reloader 仍未修）
  - 线上实测：导航后 600ms 启动环已在画（`bg=rgb(0,0,0)`、`css:[]`、FCP 568ms）
  - 仪器坑记一笔：`curl -H 'Accept-Encoding: gzip'` **不会解压**，管道给 grep 读到的是二进制——
    那条「页面里还有没有外部样式表」的检查一度是无效的，用 `--compressed` 重做后才算数
- **启动环 v4（固定点径 + 进场/旋转/退场）与入口文档 `no-store`**（维护者同日第三轮反馈）：
  - **动画结构**：去掉上一版的彗尾（点径不再分级），五点同径；整环旋转 + 每点只做透明度的进出、
    五点错开 0.12s → 依次亮起（进场）/ 全部可见并旋转 / 依次熄灭（退场），周期末尾留一段空档。
    判据（一个周期采样）：可见点数序列 `5×11 4 2 1 0 0 0 1 2 3 4 5`；点径 `[9,9,9,9,9]` 全等；
    整环角度单调推进；`--reduced` 下两个动画都关掉、五点静止全亮
  - **手机刷新拿不到新版**（她的原话：必须清理本地缓存后才看到新的加载环）：`no-cache` 只要求
    「再验证」，而移动端浏览器的刷新并不保证再验证 → 入口文档改成 **`no-store`**（根本不让落盘）。
    实现用 `map $uri $g41_cache_control` + **服务器级** `add_header`，而不是新开 location ——
    location 级的 `add_header` 会**取消继承**服务器级的全部安全头（CSP/HSTS 会静默消失）。
    实测：开着缓存连开两次导航，两次都 `fromCache:false`、`transferSize 7501`；CSP 与 HSTS 仍在

| 提交 | 说明 |
|------|------|
| `ba86aba` | fix(g41.sh): kits verify 的 L1/L3/L4 从不执行；补磁贴 i18n 键覆盖检查 |
| `4435b12` | feat(home): 新增自我介绍磁贴 tile_kitsunome（小爪 / キツのめ） |
| `8451fe9` | refactor(tile_gh-proxy): 撤下首页磁贴，依赖收窄为 nginx |
| `26afe10` | docs: 三语同步 tile_kitsunome / gh-proxy / kits-spec / AGENTS.md |
| `45b16f0` | fix(g41.sh): kits reload 的 k8s 目标写错 —— api 不是独立 Deployment |
| `b324278` | fix(tile_kitsunome): 名字那行把 つめ（爪）还回去 —— 狐の目 是我的读法，不是名字的来处 |
| `e95ac78` | feat(tile_kitsunome): 磁贴补上到门面的链接（三语各指自己那一份） |
| `8b35b39` | feat(home): 首屏空白期补上 WP8 启动环，并让启动失败变成可见状态 |
| `7d3b7b8` | fix(home): 冷启动白屏的根因是 G41.js 与 tiles.js 的加载顺序 |
| `f2d7197` | fix(home): 启动环放大 + 可见文案 + 暗幕；补 `Cache-Control: no-cache` |
| `e243c0c` | fix(home): 启动环第三版 —— 五点成一条链、收环时机、加载期不显示背景 |
| `cb8cd28` | perf: 首屏不再等 —— 样式全部内联 + nginx 开启 gzip |
| `923a306` | feat(home): 启动环 v4 —— 固定点径 + 进场/旋转/退场三阶段；入口文档 `no-store` |

## 2026-09-13

- **新增两个运维定时任务**（k8s/host/），补齐 k8s 模式下的自动化缺口：
  - `g41-cert-reload.timer`（每 15 分钟）：cert-manager 续期后把证书分发到各消费 Pod。
    按能力区分处理 —— nginx 自带 reloader sidecar 走 SIGHUP 热加载**不重启**；
    hy2/dns 无热加载机制须滚动重启。以 `tls.crt` 的 sha256 作指纹实现幂等，
    分发前用 `openssl -checkend 0` 拒绝已过期证书。
  - `g41-image-update.timer`（每周日 04:30）：比对浮动 tag 的上游 digest，有新版本则滚动更新
  - `g41-notify.py`：无第三方依赖的 SMTP 通知，未配置 `G41_SMTP_*` 时静默跳过
- **修正三处单节点部署缺陷**（均实测踩坑，已内置护栏与文档）：
  - `kits/nginx/k8s/deployment.yaml` 补 `imagePullPolicy: Always` —— `nginx:alpine` 为浮动 tag，
    未声明时默认 `IfNotPresent`，`rollout restart` 只复用本地缓存镜像，
    上游新版**永远拉不到**（此前两次"更新成功"实际 digest 纹丝不动）
  - `dns`(53/853)、`download`(51413) 的 `maxSurge` 归零 —— 与 nginx(80/443) 同理，
    使用 `hostPort` 且单节点时 `maxSurge>0` 会让新 Pod 因端口被占而永久 Pending，rollout 卡死
  - `k3s-standalone.service` 增加 `Conflicts=k3s.service`，定时任务改依赖 `k3s-standalone`
    —— 遗留的 `k3s.service`（disabled 但文件仍在、`Restart=always`）被依赖拉起后
    与 standalone 抢占 `127.0.0.1:6444`，导致 apiserver crash-loop（restart counter 涨到 41）
- 文档更正：`k8s/README.md` 澄清本部署**并未安装** stakater/reloader，
  hy2/dns 上的 `reloader.stakater.com/auto` 注解是失效的；新增「证书轮换」「定时任务」两节
- `install-1gb.sh` 补装两个定时任务；`.env.example` 补 `G41_SMTP_*` 说明；`.gitignore` 忽略 `__pycache__`
- **本地镜像构建改走 containerd 原生路径**：k8s 模式下 dockerd 停用，原
  `docker build` + `save | ctr import` 无法运行。改用 nerdctl + BuildKit 的
  containerd worker（`buildkitd.service`），镜像直接构建进 k3s 的 k8s.io namespace
  与 overlayfs snapshotter，省去 save/import 两步
  - 新增 `g41-image-build.sh`：自动发现 k8s 下部署的 `compose=file` 模块
    （跳过 autoheal/dsock/acme 等退役模块），按 COPY 路径风格自动判定构建上下文
  - `g41.sh k8s build` 优先路由到该路径，nerdctl 不可用时回退 docker
  - 每周任务改为「Dockerfile + 被 COPY 文件」内容哈希判定，未变化则跳过重建，
    重建后自动滚动重启对应 Deployment
  - 实测 bt/aria2/hexo/redis 全部重建成功，二次运行全部跳过，幂等成立
- **移除 hexo 博客模块与 attic 服务**（维护者要求）：
  - 删除 `kits/hexo`（含 `.hx` 数据与 `.wr/hexo` 静态输出，移除前已备份至
    VPS `/root/g41-removed-backup/`）、`kits/attic`、以及硬依赖 attic 的磁贴
    `kits/tile_attic`；连带 9 篇模块文档
  - k8s 侧：删除 attic Deployment/Service、hx Service、hexo-build Job；
    清除 `.gx` 残留 site 片段后重渲染 nginx ConfigMap（否则 upstream
    `attic:8080` 因 Service 消失会导致 **nginx 启动失败**）；
    清除 Redis `data:tiles/tile_attic` 并置空 `data:loaded` 触发重导入
  - 同步 compose.yaml / G41_KITS / g41.sh（移除 `k8s hexo` 子命令）/
    两个运维脚本的模块列表 / AGENTS.md、README（三语）、k8s/README.md、
    kits-spec.md、1gb-stability.md
  - 保留 attic 持久化目录 `.attic`（数据未删，便于日后恢复）；
    `docs/*/k8s-migration.md` 作为历史记录保留
  - 实测：7 个 Deployment 全部 Running，站点 200，`/attic/` → 404，
    `/data/tiles` 返回 11 项且不含 tile_attic，两个定时任务 exit 0
- **新增 `tile_friends` 友情链接磁贴**（第 12 块磁贴，补齐首页网格）：
  - `list` 型磁贴，点击展开友链列表；首个条目为「汐雾の雾星面包房」
    （`https://shiogiri.com`，互为友链）
  - 三语 i18n + 三语文档 + README 展示表条目
  - 11 → 12 块：4 列网格正好 3 行、6 色 METRO 循环正好 2 轮，无空缺
- **修复一处静默半失效缺陷**（新增磁贴触发 reload 时暴露）：
  - `kits/redis/k8s/deployment.yaml`：`REDIS_PASSWORD` 的 secretKeyRef 由
    `optional: true` 改为**必需**。optional 时若 `g41-env` 缺该键，Kubernetes 会
    注入**空字符串**而不报错 → redis 以 `--requirepass ""` 启动、api 无法认证
    （`NOAUTH HELLO`），表现为 `/data/*` 全部 **502** 而 Pod 仍显示 Running。
    实测就是这个原因导致数据端点中断，改为必需后缺键会让 Pod 直接 Pending。
  - `g41.sh k8s_apply_base`：前置校验 `.env` 是否含 `REDIS_PASSWORD`，缺失即
    失败退出，避免再次生成缺键的 Secret。（`RELOAD_SECRET` 不在此列 —— 仅影响
    热重载端点且已有独立报错。）
  - 附带：VPS `.env` 补上 `REDIS_PASSWORD`（原缺失，属已知易错点）
- 新增模块后测：7 Pod 全部 Running 且新 redis pod **0 重启**，
  `/data/tiles` 返回 **12** 项且含 tile_friends，三语 i18n 解析正常
- **清理过时内容并修复 GC 缺失**（评估 k3s 设施时发现）：
  - **根因**：kubelet 的 image GC 只在**磁盘使用率超过 85%** 时触发（默认阈值），
    本机长期在 30% 上下 → GC 从不运行 → 孤儿快照无限累积
  - 实测镜像库堆积到 **8.6GB**，实际在用仅 2.7GB，**5.9GB 是已删除/已切版本
    镜像的孤儿快照**
  - 修复：`g41-image-update.sh` 收尾增加主动回收（`nerdctl system prune`，
    按「是否被容器引用」判定，保留在用镜像；比 `ctr images prune --all`
    安全，后者会连 tag 一起删并逼出重新拉取）
  - 显式删除 7 个已验证无引用的镜像：`tracker:local` 440MB、
    `local-path-provisioner` 85MB、`attic` 83MB、`hexo:local` 79MB、
    `acme:local` 36MB、`stakater/reloader` 15MB、
    `cert-manager-startupapicheck` 14MB，及其孤儿 digest 引用
  - 清理残留数据：`.rd/data/i18n/tile_attic/`、`.rd/data/tile_apps/hexo.json`
  - **实测**：containerd 8.6GB → **2.7GB**（释放 5.9GB），磁盘 32G → 26G，
    7 Pod 全程 Running；GC 幂等（二次运行报「无可回收空间」）
- **评估 nginx 原生 ACME 替代 cert-manager：结论不可行**，维持现有机制。
  决定性阻塞：`ngx_http_acme_module` 官方文档与源码 README 均声明
  **仅支持 HTTP-01**，而我们的证书含 `*.g41.moe` 通配符 —— ACME 规范
  （RFC 8555）规定通配符**只能**用 DNS-01 验证。次要问题：附加域名
  `maidkihara.moe`/`kitsunori.moe` 解析到 Cloudflare 而非本机；模块不产出
  k8s Secret，会使 hy2/dns 失去证书来源；包版本与 nginx 主版本绑定
  （需要 1.29.8，本机 1.31.5）。详见 `docs/zh/nginx-native-acme-assessment.md`
- **首页磁贴改为按正面短名排序**：服务端按 `id` 字典序返回（`tile_apps`、
  `tile_friends`…），与用户看到的文字无关，顺序无规律可循。改为在
  `buildTiles()` 渲染前按 `label[0]`（磁贴正面短名）排序，缺失时退回
  `label[1]`、再退回 `id`；排序在 `METRO[idx%6]` 配色**之前**执行，
  以保证每块磁贴配色不随返回顺序漂移
  - 实测三语顺序完全一致：apps → bilibili → dns → flake → friends →
    github → homete → kihara777 → links → mail → nix → tracker
  - 顺带修正两条不规范英文描述：`proxy`→`Reverse Proxy`、`resolve`→`DNS Resolver`
  - ⚠️ **踩坑**：改动必须经 `g41.sh kits add -C` 安装。直接 rsync 覆盖
    `kits/` 源文件会换掉 inode，**断开与 `.wr/G41/`（nginx 实际提供路径）
    的硬链接**，表现为「改了但站点没变」——本次即因此一度误判已生效
  - 附带清理 6 个陈旧 i18n 目录（`apps`/`flake`/`gh-proxy`/`links`/
    `nix-cache`/`tile_homete`，均为旧模块名残留）；它们与现行目录内容
    **不同**，而加载器用 `Object.assign` 合并，陈旧值会与之竞争

| 提交 | 说明 |
|------|------|
| `8fdb78c` | feat(k8s): 新增证书分发与每周镜像更新定时任务 |
| `031a146` | fix(k8s): 修正单节点滚动更新的三处缺陷并补文档 |
| `5a8ff40` | feat(k8s): 本地镜像构建改走 containerd 原生路径（无需 dockerd） |
| `1e164a3` | feat: 移除 hexo 博客模块与 attic 服务 |
| `8e87063` | feat: 新增 tile_friends 友情链接磁贴，补齐第 12 块磁贴 |
| `ba4126e` | docs: 评估 nginx 原生 ACME 替代 cert-manager 的可行性（结论：不可行） |
| `c8aa095` | docs: 新增 k3s 设施评估 — 资源优化空间与全量迁移可行性 |
| `f4fdbc3` | feat(k8s): 每周镜像任务增加 GC，回收孤儿快照 |
| `98b6441` | feat(home): 磁贴按正面短名排序 |

## 2026-08-27

- **内存扩容落地**：VPS 由 958MB 升至 1.6GB（目标 2GB），cert-manager 由"每月开窗续期"改为**常态驻留**（replicas=1），crontab 中的开窗条目已移除（仅保留 apt 升级任务）
- **CD 管道验证闭环**：GitHub Actions `deploy.yml`（ssh-deploy@v6 + ssh-action@v1）端到端跑通（~28s），secrets 配置完成；rsync 追加 `--exclude=.env --exclude=.local.sh` 防止覆盖 VPS 私有内容
- 新增 `docs/zh/1gb-stability.md`：1GB 稳定运行研究结论（tmpfs kine + swap 分层 + 组件精简）
- 附加域名结论：多域名共用同一 `_acme-challenge` CNAME 目标时，cert-manager 并发签发存在清理竞态，暂缓附加域名；恢复需在各自 DNS 配置独立 CNAME 目标后重新签发
- git 全量推送至 GitHub（ee62381）；镜像策略统一为浮动标签

## 2026-08-26

- **完成 k3s 迁移**：Docker Compose → Kubernetes (k3s v1.36.3)，12 Pod 整合为 8 Pod
  （hexo 静态化、tracker 并入 api 进程、api 并入 redis Pod、aria2+bt 合 Pod）
- 控制面：tmpfs kine（状态备份/恢复 systemd 单元）、k3s-standalone（文件日志解耦 journald、
  MemoryMin 400M、OOM 保护）；cert-manager 签发证书（g41.moe + *.g41.moe）
- g41.sh：`init k8s`、`k8s stage|conf|hexo` 子命令、include 生成式重写
- 1GB 主机调优脚本化：journald volatile / zram / swappiness / snapd 停用 / fail2ban 白名单
- CD 管道：GitHub Actions（共有内容）+ deploy-local.sh（私有内容本地 SSH 推送）
- i18n 全量检查通过；home 描述更新为 k3s、tile_flake 对齐 NixKits 现状
- 修复根因：journald 冻结（apiserver 卡死元凶）、k3s.service 单元、bittorrent-tracker
  ESM 解析、REDIS_HOST 硬编码、redis 认证不一致等

## 2026-08-24

- 新增 k8s/k3s 部署层：12 个容器模块的 Deployment/Service manifest（kits/*/k8s/）
- g41.sh 双后端支持：`backend compose|k8s` + `k8s apply|build|status` 子命令
- compose include 改为生成式重写（compose_include_regenerate），废除 sed 行编辑
- 证书方案：acme.sh 标签钩子 → cert-manager（Cloudflare DNS01）+ Reloader
- autoheal/dsock/acme 三模块在 k8s 下退役（原生探针/cert-manager 替代）
- 新增 docs/zh/k8s-migration.md 迁移 runbook 与 k8s/README.md 架构说明
- 发现并记录：VPS 上 G41_KITS 曾遗漏 attic 记账；内存 1GB 需先升级才能迁移

## 2026-06-24

- tile_mail / tile_kihara777 三语文档补全（zh/en/ja，共 6 篇）
- README 三语展示区补充 mail + kihara777 条目
- MAINTENANCE.md 去重整理：合并摘要区块至时间线
- AGENTS.md 新增访问控制、初次启动审计、云端部署规则

## 2026-06-22

- 新增 attic 模块：自托管 Nix 二进制缓存服务器（atticd）
- 新增 tile_attic 磁贴：Attic 使用指南（三语 i18n + 密钥生成说明）
- tile_attic 全量本地化：代码块转为 i18n 键（attic_pre1/attic_pre2/attic_note）
- 新增 attic / tile_attic 三语文档（zh/en/ja，共 6 篇）
- README 三语同步：站点服务 + 展示表添加 attic 条目
- 新增 tile_mail / tile_homete / tile_kihara777 磁贴（GitHub 项目与主页展示，三语 i18n）
- 新增 Redis API 热重载端点 POST /admin/reload（RELOAD_SECRET 认证，零停机）
- 新增 g41.sh kits reload 命令：一键刷新磁贴/i18n/链接数据（容器内 Node.js HTTP 请求）
- 修复 tile_attic 硬编码中文链接文本 → i18n 键 attic_link
- 修复新磁贴标题格式：统一为小写无 emoji（attic/homete/kihara777/mail）
- home 模块合并 tile_homete：直接提供 homete 磁贴，移除冗余模块
- Redis API 磁贴列表按 id 字母序排列
- home 三语文档更新：补充 homete 磁贴与模块提供内容详情
- 修复 g41.sh kits reload 容器内 wget 不可用问题
- 修复 rsync 后硬链接断裂 → 追加 g41.sh kits add -C 重建链接
- tile_mail 链接修正（Ma8lKits → MailKits）+ 详情页重构（架构/功能章节）
- tile_attic i18n 增强：多租户/S3 后端描述、客户端配置标题、完整密钥生成路径
- AGENTS.md 新增访问控制、初次启动审计、云端部署规则、Section 重排序

## 2026-06-20

- 开源推送 `main` 分支至 GitHub
- 三语文档上线（27 模块 + 模块规范）：zh:29 / en:29 / ja:29
- AGENTS.md 完整重写为中文（292 行），涵盖架构、开发工作流、常见问题
- README 补充 `.local/` 本地初始化章节
- 三语维护记录（MAINTENANCE.md / en / ja）
- 三语 NOTICE.md（第三方资产声明）

## 2026-06-18

- 移除全部 Docker 版本锁定：Dockerfile FROM 行、compose image 标签、npm 包版本、ADD --checksum 均改为浮动版本
- 修复 `g41.sh kits pack` 因 `skills/` 目录缺失导致的 `set -e` 退出
- 全栈容器强制重建，14/14 healthy

## 2026-06-16

- 两轮全面安全审计（4 子代理并行）：发现 24 项问题，全部修复或接受
- g41.sh 安全加固：`set -o pipefail`、`sed -i` 改为原子写入（`sed > tmp && mv`）、compose include 改用行号精确插入
- autoheal 崩溃修复：从 willfarrell/autoheal Hub 镜像改为自定义 Dockerfile（基于 master 版 entrypoint，支持 TCP socket）
- CSP 安全头分层配置：主站严格 + aria2/nix-cache/gh-proxy 代理路径宽松
- tiles.js tracker embed 防 XSS：`innerHTML` → `createElement` + `textContent`
- G41.js fetch 添加 5s 超时（`AbortSignal.timeout(5000)`）
- server.js 所有 `catch(e){}` 静默异常添加 `console.error` 日志
- 开源可行性审计通过：硬编码域名、密钥全部清零，敏感文件全部 `.gitignore` 排除
- tile_bilibili 模块新建：Bilibili 虚拟主播磁贴（三语 i18n）
- tile_flake 磁贴填充：13 个 NixKits 软件包/补丁/技能条目
- tile_gh-proxy i18n 硬编码 `g41.moe` → `__HOST__` 占位符
- g41.sh TUI 交互界面改为 ANSI 转义序列增量渲染（消除闪烁）
- GitHub 仓库创建及 topics 设置

## 2026-06-11 ~ 2026-06-12

- 数据与功能分离（A/B/C 层）：compose 变量化、nginx site 配置泛化、server.js 环境变量注入
- 安全加固：dsock 新模块（Docker API 代理）、BT 供应链锁定、Redis 密码认证
- 健康检查标准化（HTTP 端点 > 端口探测 > kill -0 1）
- 模块重命名：纯磁贴 → `tile_*` 前缀（5 个），纯短链接 → `link_*` 前缀（6 个）
- 前端修复：错误码页面、加载闪烁、404 生效
- hy2 模块私密化：`.local/` 隐藏订阅文件和 nginx 配置
- g41.sh 扩展：自动发现 `.local/site/` 和 `.local/webroot/`
- server.js 重构：原始 TCP socket → `redis` npm 包持久连接 + pipeline 批量写入

## 2026-06-10

- 初始审计：compose.yaml、g41.sh、所有 kits/ 模块
- 基础设施搭建：Metro/WP8.1 风格首页、Redis 配置 API、多语言 i18n、KITS 模块系统