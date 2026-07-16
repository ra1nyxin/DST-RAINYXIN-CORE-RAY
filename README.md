这是一个偏向纯客户端辅助增强的实用小模组喵。

当前功能：
- 纯客户端生效，服务器和房主不需要安装。
- 会在你人物附近显示一些文字指引，当前包括 `花`、`蝶`、`人` 和 `试金石`。
- 每条指引都会按方向分散显示，并附带大致距离。
- 现在统一按 `100` 范围探测，并且把提示文字圈重新放远了一点，避免太贴近玩家自身。
- 多个目标现在允许直接重叠显示，不再因为优先级或角度过滤而隐藏一部分目标。
- 会在屏幕左上角显示房间在线玩家列表，并显示每个玩家的延迟文本和颜色区分。
- 额外提供一档实验性的本地交互距离微调，尝试让捡物、采集、收获、挖矿、铲挖、砍树能在稍远一点的位置开始动作。
- 额外提供一档实验性的本地快打增强，尝试让普通攻击更早进入下一次真实攻击输入循环。

说明：
- 这个项目后续会继续加更多实用辅助功能，目前先把“附近花朵指引”这个基础功能做稳。
- 当前只在本地 HUD 上显示指引，不改服务器实体，不影响其他玩家。
- 目前会指引附近常见地面花：`flower`、`flower_evil`、`flower_rose`，附近蝴蝶：`butterfly`，附近存活玩家：`人`，以及 `resurrectionstone` 试金石。
- 已修正首版 clientOnly 子脚本直接依赖 `GLOBAL` 导致严格模式报错、游戏启动时坏加载的问题。
- 现在左上角新增房间在线玩家列表，会给延迟低、中、高分别上不同颜色，方便快速看状态。
- 玩家名显示前会先做清洗，专门处理控制字符、零宽字符、双向控制符、过长名字和部分容易搞坏 UI 的符号。
- 已记录：之前试过 `1.1x` 和 `1.05x` 两档 clientOnly 移速增强，实测都会有概率出现走着走着被拉回回弹，所以这一档移速增强已经删掉。
- 当前这档交互距离增强同样是 clientOnly 试验项，主要用来实测客户端动作到达距离变化在局域网或联机环境里能被服务端接受到什么程度。
- 当前这档实验值已经继续上调一档，优先让“手变长”的体感更明显，再观察是否开始碰到服务端回拉或拒绝执行的边界。
- 当前这档快打增强也是 clientOnly 边界试验，目标是尝试更早发出下一次攻击请求，看看服务端会接受到什么程度。
- 已记录：`scripts/clientattackspeed.lua` 曾因在 strict 环境里裸用 `AddStategraphPostInit` 这个全局名，导致 modmain 加载阶段直接报“variable is not declared”并中断启动。
- 已记录：即使改成 `_G.AddStategraphPostInit` 这种顶层字段访问，仍然可能在 strict 环境入口阶段触发同类报错；更稳的写法是 `rawget(_G, "AddStategraphPostInit")` 后再落局部别名。
- 现在没有做外部配置文件开关。

实现记录：
- `modmain.lua` 通过 `AddClassPostConstruct("screens/playerhud", ...)` 把本地 HUD 挂件接到玩家界面上。
- `modmain.lua` 也会先加载 `scripts/clientactionreach.lua`，在客户端直接微调部分 `ACTIONS` 的到达距离参数。
- `modmain.lua` 还会加载 `scripts/clientattackspeed.lua`，在客户端本地微调攻击节奏相关的几个入口。
- 目标显示逻辑集中在 `scripts/widgets/flowerraywidget.lua`。
- 左上角在线玩家延迟列表逻辑集中在 `scripts/widgets/playerlatencywidget.lua`。
- 当前交互距离实验集中在 `scripts/clientactionreach.lua`，其中对 `PICKUP`、`PICK`、`HARVEST`、`MINE`、`DIG` 统一追加少量 `extra_arrive_dist`，并把 `CHOP.distance` 从原版基础上略微抬高。
- 当前这一版里，`PICKUP`、`PICK`、`HARVEST`、`MINE`、`DIG` 统一追加 `0.9` 的额外到达距离，`CHOP.distance` 则在原版基础上额外加 `0.6`。
- 当前快打实验集中在 `scripts/clientattackspeed.lua`，分别对 `combat_replica` 的本地最小攻击周期判断、`playercontroller` 的攻击按钮重复节流，以及 `wilson_client.attack` 的本地状态超时做了同步边界试探。
- 左上角玩家列表通过 `TheNet:GetClientTable()` 拉当前房间在线玩家，当前玩家自己的延迟则直接读 `TheNet:GetAveragePing()`。
- 玩家名字会先做字符串清洗，再做 UTF-8 安全截断，避免控制字符、零宽字符、双向控制符和超长输入把 HUD 搞乱。
- 当前快打实验值仍然保持把本地最小攻击周期和本地攻击状态超时压到原值的 `70%`，并把攻击按钮重复冷却压到 `0.08` 秒。
- 现在对 `AddStategraphPostInit` 的处理已经进一步收紧为 `rawget(_G, "AddStategraphPostInit")` 加局部别名，再调用时不直接碰顶层全局名。
- 附近目标查询主要用 `TheSim:FindEntities(...)`，当前分成花、蝴蝶、玩家、试金石四组查询，避免半径 `100` 时裸扫太多无关实体。
- 花走 `pickable` 标签，蝴蝶走 `butterfly` 标签，玩家走 `player` 标签并排除 `playerghost`，试金石走 `resurrector` 标签。
- 查询结果目前只按距离做稳定排序，不再做角度过滤，也不再限制固定显示名额。
- 屏幕位置优先用 `TheSim:GetScreenPos(...)`；如果当前帧拿不到屏幕坐标，就回退到 `TheCamera:GetHeadingTarget()` / `GetHeading()` 加世界坐标差值做方向近似。
- HUD 文本本身用 `widgets/text` 的 `Text` 绘制，内容格式是“标签 + 距离”，颜色则按目标类型区分。
- 当前文字圈半径由 `RING_RADIUS` 控制，玩家头顶偏移由 `PLAYER_SCREEN_Y_OFFSET` 控制，字体大小由 `LABEL_FONT_SIZE` 控制，标签实例数量则按实际目标数动态创建。

Current features:
- This is a client-only helper mod, so the server and host do not need to install it.
- It shows local text markers around your character for nearby flowers, butterflies, players, and Touch Stones.
- Each marker spreads by direction and includes rough distance text.
- The scan radius is uniformly set to `100`, and the marker ring is pushed a bit farther away from the player again.
- Multiple targets are now allowed to overlap directly instead of being hidden by angle-based priority filtering.
- It also adds a top-left room player list with per-player latency text and color bands.
- It also adds an experimental local interaction reach tweak for pickup, pick, harvest, mine, dig, and chop actions.
- It also adds an experimental local faster-attack tweak that tries to enter the next real attack input earlier.

Notes:
- This project will keep growing with more practical helper features later, but the first step is making nearby flower guidance stable.
- The current feature only draws local HUD indicators and does not modify server-side entities or affect other players.
- The current guidance tracks nearby `flower`, `flower_evil`, `flower_rose`, `butterfly`, living players, and `resurrectionstone`.
- The first client-only loading crash caused by directly relying on `GLOBAL` inside a required widget script has been fixed.
- The top-left player list now colors low, medium, and high latency differently so room status is easier to read at a glance.
- Player names are sanitized before drawing to handle control characters, zero-width characters, bidi controls, overlong names, and a few UI-hostile symbols.
- Recorded issue: earlier `1.1x` and `1.05x` client-only move-speed experiments both produced rubber-banding during real play, so the movement-speed boost has been removed.
- The current interaction reach tweak is another client-only experiment meant to probe how far local action distance changes can still be accepted by the server.
- The current experiment values have been pushed a bit farther so the reach increase is easier to feel before checking where server-side rejection or rubber-banding starts.
- The current faster-attack tweak is another client-only boundary experiment focused on sending the next attack request earlier.
- Recorded issue: `scripts/clientattackspeed.lua` previously used the global name `AddStategraphPostInit` directly under strict mode, which caused mod loading to abort before startup finished.
- Recorded issue: even changing that top-level access to `_G.AddStategraphPostInit` can still be too brittle during strict client-only startup, so `rawget(_G, "AddStategraphPostInit")` is the safer pattern.
- There are no external configuration options in this version.

Implementation notes:
- `modmain.lua` injects the local HUD widget through `AddClassPostConstruct("screens/playerhud", ...)`.
- `modmain.lua` also loads `scripts/clientactionreach.lua` first so a few client-side `ACTIONS` can be adjusted locally.
- `modmain.lua` also loads `scripts/clientattackspeed.lua` so the client can locally probe attack-timing boundaries.
- The guidance widget lives in `scripts/widgets/flowerraywidget.lua`.
- The top-left room player list lives in `scripts/widgets/playerlatencywidget.lua`.
- The current interaction reach experiment lives in `scripts/clientactionreach.lua`, adding a small `extra_arrive_dist` bump to `PICKUP`, `PICK`, `HARVEST`, `MINE`, and `DIG`, while nudging `CHOP.distance` slightly above vanilla.
- In the current build, `PICKUP`, `PICK`, `HARVEST`, `MINE`, and `DIG` each get an extra `0.9` arrive-distance bump, while `CHOP.distance` is increased by `0.6` over vanilla.
- The current faster-attack experiment lives in `scripts/clientattackspeed.lua`, patching local `combat_replica` cooldown checks, `playercontroller` attack-button repeat throttling, and `wilson_client.attack` timeout length.
- The top-left player list is built from `TheNet:GetClientTable()`, while the local player's own latency is read directly from `TheNet:GetAveragePing()`.
- Player names are sanitized and then UTF-8-safe truncated before drawing so hostile or malformed input does not blow up the HUD.
- The faster-attack experiment still keeps local attack cooldown and local attack-state timeout at `70%` and lowers attack-button repeat cooldown to `0.08` seconds.
- This has now been hardened further by resolving `AddStategraphPostInit` through `rawget(_G, "AddStategraphPostInit")` before binding a local alias, avoiding another undeclared-global crash during strict client-only loading.
- Nearby target lookup mainly uses `TheSim:FindEntities(...)`, split into flowers, butterflies, players, and Touch Stones to avoid a broad unfiltered radius-100 scan.
- Flowers use the `pickable` tag, butterflies use `butterfly`, players use `player` while excluding `playerghost`, and Touch Stones use `resurrector`.
- Query results now keep only a stable distance-based order; there is no angle filter and no fixed display cap anymore.
- Screen-space placement prefers `TheSim:GetScreenPos(...)`, with camera-heading fallback through `TheCamera:GetHeadingTarget()` / `GetHeading()` plus world delta approximation when direct screen coordinates are unavailable.
- The HUD labels themselves are rendered with `widgets/text` `Text`, using a simple “label + distance” format and per-target colors.
- The current marker ring distance is controlled by `RING_RADIUS`, the root vertical offset by `PLAYER_SCREEN_Y_OFFSET`, the font size by `LABEL_FONT_SIZE`, and the label pool grows dynamically to match the detected target count.
