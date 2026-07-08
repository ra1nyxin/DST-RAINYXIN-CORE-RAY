这是一个偏向纯客户端辅助增强的实用小模组喵。

当前功能：
- 纯客户端生效，服务器和房主不需要安装。
- 会在你人物附近显示一些文字箭头，指向附近地面上的花。
- 箭头会按方向分散显示，并附带大致距离，方便赶路时顺手找花。
- 现在探测范围已经提高到更远距离，刷新调整为更稳一点的节奏，并且整套指引显示缩小了一档。

说明：
- 这个项目后续会继续加更多实用辅助功能，目前先把“附近花朵指引”这个基础功能做稳。
- 当前只在本地 HUD 上显示指引，不改服务器实体，不影响其他玩家。
- 目前主要指引附近常见地面花：`flower`、`flower_evil`、`flower_rose`。
- 已修正首版 clientOnly 子脚本直接依赖 `GLOBAL` 导致严格模式报错、游戏启动时坏加载的问题。
- 现在没有做外部配置文件开关。

Current features:
- This is a client-only helper mod, so the server and host do not need to install it.
- It shows local text arrows around your character that point toward nearby flowers on the ground.
- The arrows spread by direction and include rough distance so flowers are easier to spot while moving around.
- The scan radius is now much larger, the refresh is slightly calmer, and the whole indicator set is scaled down a bit.

Notes:
- This project will keep growing with more practical helper features later, but the first step is making nearby flower guidance stable.
- The current feature only draws local HUD indicators and does not modify server-side entities or affect other players.
- The current flower guidance mainly tracks nearby `flower`, `flower_evil`, and `flower_rose` prefabs.
- The first client-only loading crash caused by directly relying on `GLOBAL` inside a required widget script has been fixed.
- There are no external configuration options in this version.
