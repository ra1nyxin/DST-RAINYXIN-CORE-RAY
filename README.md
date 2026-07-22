DST-RAINYXIN-CORE-RAY

Client-only helper utilities focused on guidance, convenience, and smoother survival.

中文

当前功能：
- 纯客户端生效，服务器和房主不需要安装。
- 当前会指引附近蝴蝶、存活玩家、试金石，以及远距离猪王。
- 试金石一旦被发现就会把坐标缓存在内存里，之后无论你走多远都还能继续显示方向和距离。
- 猪王会优先使用近处真实实体位置；如果还没同步到客户端，就退回客户端世界拓扑推断位置，并在当前会话内持续使用。
- 左上角会显示当前房间在线玩家列表，并显示每个玩家的延迟文本或网络等级文本以及颜色区分。
- 额外提供实验性的本地交互距离微调，尝试让捡物、采集、收获、挖矿、铲挖、砍树能在稍远一点的位置开始动作。
- 额外提供实验性的本地快打增强，尝试让普通攻击更早进入下一次真实攻击输入循环。

这次更新：
- 删除了花朵指引。附近有蝴蝶时基本就已经能推知附近有花，继续单独显示花只会让列表更乱。
- 保留蝴蝶指引，继续作为“附近有花”的轻量替代提示。
- README 和创意工坊描述同步更新到当前功能集。

踩过的坑：
- 首版 clientOnly 子脚本在 strict 环境里直接碰顶层全局，导致坏加载和启动时报错。
- `scripts/clientattackspeed.lua` 里直接用 `AddStategraphPostInit` 会触发 “variable is not declared”；改成 `rawget(_G, "AddStategraphPostInit")` 后再落局部别名才稳。
- 之前做猪王远距离指引时，单靠 `TheSim:FindEntities(...)` 只能拿到客户端同步半径内的目标，远处猪王根本查不到。
- 猪王这条后来改成“近处真实实体优先，远处世界拓扑兜底”的双通道后才真正能用。
- 远距离指引刚开始还踩到一个方向问题：`TheSim:GetScreenPos(...)` 超出可用范围后，简单用相机 heading 手搓投影很容易偏；现在改成优先用 `TheCamera:GetRightVec()` 和 `GetDownVec()` 做方向近似，表现才稳定。
- 试过 `1.1x` 和 `1.05x` 两档 clientOnly 移速增强，实测都会有概率走着走着被拉回，所以移速增强已经删掉。

实现记录：
- `modmain.lua` 通过 `AddClassPostConstruct("screens/playerhud", ...)` 把本地 HUD 挂件接到玩家界面上。
- 目标显示逻辑集中在 `scripts/widgets/flowerraywidget.lua`。
- 玩家延迟列表逻辑集中在 `scripts/widgets/playerlatencywidget.lua`。
- 附近目标查询主要用 `TheSim:FindEntities(...)` 分组扫描蝴蝶、玩家、试金石和猪王。
- 远距离猪王指引会读取 `TheWorld.topology` 里猪王房间节点，并把结果只缓存在内存，不写配置文件、不写磁盘。
- 屏幕位置优先用 `TheSim:GetScreenPos(...)`；拿不到时再回退到相机向量近似。
- 左上角玩家列表通过 `TheNet:GetClientTable()` 拉当前房间在线玩家，当前玩家自己的延迟则直接读 `TheNet:GetAveragePing()`。
- 本地交互距离实验会给 `PICKUP`、`PICK`、`HARVEST`、`MINE`、`DIG` 追加 `0.9` 的 `extra_arrive_dist`，并把 `CHOP.distance` 在原版基础上额外加 `0.6`。
- 当前快打实验仍然把本地最小攻击周期和本地攻击状态超时压到原值的 `70%`，并把攻击按钮重复冷却压到 `0.08` 秒。

English

Current features:
- This is a client-only mod, so the server and host do not need to install it.
- It currently shows guidance for nearby butterflies, living players, Touch Stones, and long-range Pig King tracking.
- Once a Touch Stone has been seen, its position is cached in memory for the current session so its direction and distance can keep showing anywhere on the map.
- Pig King guidance prefers the real nearby entity position; if the Pig King has not synced to the client yet, it falls back to a client-side world-topology estimate and keeps using that during the current session.
- It also adds a top-left room player list with per-player latency text or approximate latency-band fallback plus color bands.
- It also adds an experimental local interaction reach tweak for pickup, pick, harvest, mine, dig, and chop actions.
- It also adds an experimental local faster-attack tweak that tries to enter the next real attack input earlier.

This update:
- Flower tracking has been removed. Nearby butterflies are already a good lightweight proxy for nearby flowers, and showing both mostly added clutter.
- Butterfly guidance remains as the simpler nearby-flower hint.
- The README and workshop description now match the current feature set.

Pitfalls already hit:
- Early client-only scripts touched strict-mode globals too directly and caused bad-load startup failures.
- `scripts/clientattackspeed.lua` previously used `AddStategraphPostInit` directly and hit “variable is not declared”; resolving it through `rawget(_G, "AddStategraphPostInit")` before binding a local alias is the safer pattern.
- Long-range Pig King guidance could not rely on `TheSim:FindEntities(...)` alone because the client only knows about synced entities inside a limited radius.
- Pig King guidance only became practical after switching to a dual path: real nearby entity first, world-topology fallback for long range.
- The first long-range direction attempts also ran into off-screen direction errors; using `TheCamera:GetRightVec()` and `GetDownVec()` for approximation turned out to be more stable than a simple heading-only projection.
- Earlier `1.1x` and `1.05x` client-only move-speed experiments both produced rubber-banding during real play, so the movement-speed boost was removed.

Implementation notes:
- `modmain.lua` injects the local HUD widget through `AddClassPostConstruct("screens/playerhud", ...)`.
- The guidance widget lives in `scripts/widgets/flowerraywidget.lua`.
- The top-left room player list lives in `scripts/widgets/playerlatencywidget.lua`.
- Nearby target lookup mainly uses grouped `TheSim:FindEntities(...)` scans for butterflies, players, Touch Stones, and Pig King.
- Long-range Pig King guidance reads matching Pig King nodes from `TheWorld.topology` and keeps that data in memory only, without writing config or disk files.
- Screen-space placement prefers `TheSim:GetScreenPos(...)`, with camera-vector fallback when direct screen coordinates are unavailable.
- The top-left player list is built from `TheNet:GetClientTable()`, while the local player's own latency is read directly from `TheNet:GetAveragePing()`.
- The interaction reach experiment adds `0.9` of `extra_arrive_dist` to `PICKUP`, `PICK`, `HARVEST`, `MINE`, and `DIG`, while increasing `CHOP.distance` by `0.6` over vanilla.
- The faster-attack experiment still keeps local attack cooldown and local attack-state timeout at `70%` and lowers attack-button repeat cooldown to `0.08` seconds.
