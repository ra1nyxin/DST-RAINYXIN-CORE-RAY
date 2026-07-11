这是一个偏向纯客户端辅助增强的实用小模组喵。

当前功能：
- 纯客户端生效，服务器和房主不需要安装。
- 会在你人物附近显示一些文字指引，当前包括 `花`、`蝶` 和 `试金石`。
- 每条指引都会按方向分散显示，并附带大致距离。
- 现在统一按 `100` 范围探测，并且把提示文字圈重新放远了一点，避免太贴近玩家自身。

说明：
- 这个项目后续会继续加更多实用辅助功能，目前先把“附近花朵指引”这个基础功能做稳。
- 当前只在本地 HUD 上显示指引，不改服务器实体，不影响其他玩家。
- 目前会指引附近常见地面花：`flower`、`flower_evil`、`flower_rose`，附近蝴蝶：`butterfly`，以及 `resurrectionstone` 试金石。
- 已修正首版 clientOnly 子脚本直接依赖 `GLOBAL` 导致严格模式报错、游戏启动时坏加载的问题。
- 现在没有做外部配置文件开关。

实现记录：
- `modmain.lua` 通过 `AddClassPostConstruct("screens/playerhud", ...)` 把本地 HUD 挂件接到玩家界面上。
- 目标显示逻辑集中在 `scripts/widgets/flowerraywidget.lua`。
- 附近目标查询主要用 `TheSim:FindEntities(...)`，当前分成花、蝴蝶、试金石三组查询，避免半径 `100` 时裸扫太多无关实体。
- 屏幕位置优先用 `TheSim:GetScreenPos(...)`，拿不到时再用 `TheCamera:GetHeadingTarget()` / `GetHeading()` 做方向近似。
- HUD 文本本身用 `widgets/text` 的 `Text`，显示格式是“标签 + 距离”。

Current features:
- This is a client-only helper mod, so the server and host do not need to install it.
- It shows local text markers around your character for nearby flowers, butterflies, and Touch Stones.
- Each marker spreads by direction and includes rough distance text.
- The scan radius is uniformly set to `100`, and the marker ring is pushed a bit farther away from the player again.

Notes:
- This project will keep growing with more practical helper features later, but the first step is making nearby flower guidance stable.
- The current feature only draws local HUD indicators and does not modify server-side entities or affect other players.
- The current guidance tracks nearby `flower`, `flower_evil`, `flower_rose`, `butterfly`, and `resurrectionstone`.
- The first client-only loading crash caused by directly relying on `GLOBAL` inside a required widget script has been fixed.
- There are no external configuration options in this version.

Implementation notes:
- `modmain.lua` injects the local HUD widget through `AddClassPostConstruct("screens/playerhud", ...)`.
- The guidance widget lives in `scripts/widgets/flowerraywidget.lua`.
- Nearby target lookup mainly uses `TheSim:FindEntities(...)`, split into flowers, butterflies, and Touch Stones to avoid a broad unfiltered radius-100 scan.
- Screen-space placement prefers `TheSim:GetScreenPos(...)`, with camera-heading fallback through `TheCamera:GetHeadingTarget()` / `GetHeading()`.
- The HUD labels themselves are rendered with `widgets/text` `Text`, using a simple “label + distance” format.
