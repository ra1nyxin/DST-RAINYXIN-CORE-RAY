这是一个偏向纯客户端辅助增强的实用小模组喵。

当前功能：
- 纯客户端生效，服务器和房主不需要安装。
- 会在你人物附近显示一些文字指引，当前包括 `花`、`蝶`、`人` 和 `试金石`。
- 每条指引都会按方向分散显示，并附带大致距离。
- 现在统一按 `100` 范围探测，并且把提示文字圈重新放远了一点，避免太贴近玩家自身。
- 多个目标现在允许直接重叠显示，不再因为优先级或角度过滤而隐藏一部分目标。
- 额外提供本地预测的 `1.2x` 移速增强，只影响你自己客户端上的移动预测观感。

说明：
- 这个项目后续会继续加更多实用辅助功能，目前先把“附近花朵指引”这个基础功能做稳。
- 当前只在本地 HUD 上显示指引，不改服务器实体，不影响其他玩家。
- 目前会指引附近常见地面花：`flower`、`flower_evil`、`flower_rose`，附近蝴蝶：`butterfly`，附近存活玩家：`人`，以及 `resurrectionstone` 试金石。
- 已修正首版 clientOnly 子脚本直接依赖 `GLOBAL` 导致严格模式报错、游戏启动时坏加载的问题。
- 当前这档移速增强走的是客户端预测，不是服务端真实移速改写；如果某些服务器环境下出现轻微回拉，这是 clientOnly 的天然边界。
- 现在没有做外部配置文件开关。

实现记录：
- `modmain.lua` 通过 `AddClassPostConstruct("screens/playerhud", ...)` 把本地 HUD 挂件接到玩家界面上。
- 目标显示逻辑集中在 `scripts/widgets/flowerraywidget.lua`。
- 本地预测移速逻辑集中在 `scripts/widgets/clientspeedwidget.lua`。
- 附近目标查询主要用 `TheSim:FindEntities(...)`，当前分成花、蝴蝶、玩家、试金石四组查询，避免半径 `100` 时裸扫太多无关实体。
- 花走 `pickable` 标签，蝴蝶走 `butterfly` 标签，玩家走 `player` 标签并排除 `playerghost`，试金石走 `resurrector` 标签。
- 查询结果目前只按距离做稳定排序，不再做角度过滤，也不再限制固定显示名额。
- 屏幕位置优先用 `TheSim:GetScreenPos(...)`；如果当前帧拿不到屏幕坐标，就回退到 `TheCamera:GetHeadingTarget()` / `GetHeading()` 加世界坐标差值做方向近似。
- HUD 文本本身用 `widgets/text` 的 `Text` 绘制，内容格式是“标签 + 距离”，颜色则按目标类型区分。
- 当前文字圈半径由 `RING_RADIUS` 控制，玩家头顶偏移由 `PLAYER_SCREEN_Y_OFFSET` 控制，字体大小由 `LABEL_FONT_SIZE` 控制，标签实例数量则按实际目标数动态创建。
- 本地移速增强通过玩家身上的 `playerspeedmult:SetPredictedSpeedMult(...)` 挂一个固定来源键，仅对本机玩家生效，不会改服务器上的真实同步移速。

Current features:
- This is a client-only helper mod, so the server and host do not need to install it.
- It shows local text markers around your character for nearby flowers, butterflies, players, and Touch Stones.
- Each marker spreads by direction and includes rough distance text.
- The scan radius is uniformly set to `100`, and the marker ring is pushed a bit farther away from the player again.
- Multiple targets are now allowed to overlap directly instead of being hidden by angle-based priority filtering.
- It also adds a local predicted `1.2x` movement speed boost for your own client-side movement.

Notes:
- This project will keep growing with more practical helper features later, but the first step is making nearby flower guidance stable.
- The current feature only draws local HUD indicators and does not modify server-side entities or affect other players.
- The current guidance tracks nearby `flower`, `flower_evil`, `flower_rose`, `butterfly`, living players, and `resurrectionstone`.
- The first client-only loading crash caused by directly relying on `GLOBAL` inside a required widget script has been fixed.
- The current speed boost is prediction-only on the client rather than a true server-side movement rewrite, so minor rubber-banding can still happen on some servers.
- There are no external configuration options in this version.

Implementation notes:
- `modmain.lua` injects the local HUD widget through `AddClassPostConstruct("screens/playerhud", ...)`.
- The guidance widget lives in `scripts/widgets/flowerraywidget.lua`.
- The local predicted speed logic lives in `scripts/widgets/clientspeedwidget.lua`.
- Nearby target lookup mainly uses `TheSim:FindEntities(...)`, split into flowers, butterflies, players, and Touch Stones to avoid a broad unfiltered radius-100 scan.
- Flowers use the `pickable` tag, butterflies use `butterfly`, players use `player` while excluding `playerghost`, and Touch Stones use `resurrector`.
- Query results now keep only a stable distance-based order; there is no angle filter and no fixed display cap anymore.
- Screen-space placement prefers `TheSim:GetScreenPos(...)`, with camera-heading fallback through `TheCamera:GetHeadingTarget()` / `GetHeading()` plus world delta approximation when direct screen coordinates are unavailable.
- The HUD labels themselves are rendered with `widgets/text` `Text`, using a simple “label + distance” format and per-target colors.
- The current marker ring distance is controlled by `RING_RADIUS`, the root vertical offset by `PLAYER_SCREEN_Y_OFFSET`, the font size by `LABEL_FONT_SIZE`, and the label pool grows dynamically to match the detected target count.
- The speed boost uses `playerspeedmult:SetPredictedSpeedMult(...)` with a fixed local source key, so it only affects the local player prediction and does not rewrite server-authoritative speed.
