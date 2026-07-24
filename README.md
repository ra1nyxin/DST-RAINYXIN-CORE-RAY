这是一个偏向纯客户端辅助增强的实用小模组喵。

当前功能：
- 纯客户端生效，服务器和房主不需要安装。
- 会在你人物附近显示一些文字指引，当前包括 `蝶`、`人`、`试金石`，以及远距离 `猪王`。
- 每条指引都会按方向分散显示，并附带大致距离；试金石和猪王还支持当前会话内的内存缓存。
- 现在统一按 `100` 范围探测附近目标，并且把提示文字圈重新放远了一点，避免太贴近玩家自身。
- 多个目标允许直接重叠显示，不再因为优先级或角度过滤而隐藏一部分目标。
- 会在屏幕左上角显示房间在线玩家列表，并显示每个玩家的延迟文本或网络等级文本以及颜色区分。
- 额外提供一档实验性的本地交互距离微调，尝试让捡物、采集、收获、挖矿、铲挖、砍树能在稍远一点的位置开始动作。
- 额外提供一档实验性的本地快打增强，尝试让普通攻击更早进入下一次真实攻击输入循环。

说明：
- 这个项目后续会继续加更多实用辅助功能，现在先把这套 HUD 指引、延迟列表和客户端实验项做稳。
- 当前只在本地 HUD 上显示指引，不改服务器实体，不影响其他玩家。
- 花朵指引已经移除，因为附近有蝴蝶时基本就能判断附近有花，继续同时显示只会让列表更乱。
- 目前会指引附近蝴蝶：`butterfly`，附近存活玩家：`人`，以及 `resurrectionstone` 试金石；猪王则支持远距离指引。
- 已修正首版 clientOnly 子脚本直接依赖 `GLOBAL` 导致严格模式报错、游戏启动时坏加载的问题。
- 现在左上角新增房间在线玩家列表，会给延迟低、中、高分别上不同颜色，方便快速看状态。
- 当前玩家自己的真实延迟会直接显示为 `xx ms`；其他玩家如果 Lua 侧拿不到真实毫秒值，就会退化显示为 `50± ms / 200± ms / 999± ms` 这种近似档位文本，避免继续空着 `-- ms`。
- 玩家名显示前会先做清洗，专门处理控制字符、零宽字符、双向控制符、过长名字和部分容易搞坏 UI 的符号。
- 已记录：之前试过 `1.1x` 和 `1.05x` 两档 clientOnly 移速增强，实测都会有概率出现走着走着被拉回回弹，所以这一档移速增强已经删掉。
- 当前这档交互距离增强同样是 clientOnly 试验项，主要用来实测客户端动作到达距离变化在局域网或联机环境里能被服务端接受到什么程度。
- 当前这档实验值已经继续上调一档，优先让“手变长”的体感更明显，再观察是否开始碰到服务端回拉或拒绝执行的边界。
- 当前这档快打增强也是 clientOnly 边界试验，目标是尝试更早发出下一次攻击请求，看看服务端会接受到什么程度。
- 已记录：`scripts/clientattackspeed.lua` 曾因在 strict 环境里裸用 `AddStategraphPostInit` 这个全局名，导致 modmain 加载阶段直接报“variable is not declared”并中断启动。
- 已记录：即使改成 `_G.AddStategraphPostInit` 这种顶层字段访问，仍然可能在 strict 环境入口阶段触发同类报错；更稳的写法是 `rawget(_G, "AddStategraphPostInit")` 后再落局部别名。
- 已记录：猪王远距离指引一开始只靠 `TheSim:FindEntities(...)` 根本不够，因为客户端拿不到同步半径外的猪王实体。
- 已记录：猪王后来改成“近处真实实体优先，远处世界拓扑兜底”后才可用；而远距离方向近似如果只靠相机 heading，超过 `GetScreenPos(...)` 可用范围后很容易歪，最后换成 `TheCamera:GetRightVec()` / `GetDownVec()` 的向量近似才稳定。
- 已记录：2026-07-24 这版可拖拽菜单第一次接世界前鼠标移动就崩，是因为 `widgets/widget:GetWorldPosition()` 返回的是 `Vector3`，不能直接写成 `local x, y = self:GetWorldPosition()` 后把 `x` / `y` 当纯数字参与面板命中判断；正确做法是先取返回对象，再读 `.x` / `.y`。
- 已记录：2026-07-24 这版菜单的列表命中区第一次又出现“鼠标在右边外面也能选中、第一项和第二项错位”的问题，根因是 `TEMPLATES.InvisibleButton(...)` 更偏向小型控件用途，它内部按图片缩放语义处理尺寸，不适合直接拿来铺大列表点击层；大面板列表项应改成自建 `ImageButton(blank.tex)` 并配 `ForceImageSize(...)`。
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
- 对其他玩家会先尝试从 `GetClientTable()` / `GetClientTableForUser()` 里找可用延迟字段；如果 Lua 侧没有暴露真实毫秒值，就退化为基于 `netscore` 的网络等级文本。
- 玩家名字会先做字符串清洗，再做 UTF-8 安全截断，避免控制字符、零宽字符、双向控制符和超长输入把 HUD 搞乱。
- 当前快打实验值仍然保持把本地最小攻击周期和本地攻击状态超时压到原值的 `70%`，并把攻击按钮重复冷却压到 `0.08` 秒。
- 现在对 `AddStategraphPostInit` 的处理已经进一步收紧为 `rawget(_G, "AddStategraphPostInit")` 加局部别名，再调用时不直接碰顶层全局名。
- 附近目标查询主要用 `TheSim:FindEntities(...)`，当前分成蝴蝶、玩家、试金石、猪王几组查询，避免半径 `100` 时裸扫太多无关实体。
- 蝴蝶走 `butterfly` 标签，玩家走 `player` 标签并排除 `playerghost`，试金石走 `resurrector` 标签，猪王则同时配合 `TheWorld.topology` 做远距离兜底。
- 查询结果目前只按距离做稳定排序，不再做角度过滤，也不再限制固定显示名额。
- 屏幕位置优先用 `TheSim:GetScreenPos(...)`；如果当前帧拿不到屏幕坐标，就优先用 `TheCamera:GetRightVec()` / `GetDownVec()` 做方向近似，再保留旧的 heading 方式作为兜底。
- HUD 文本本身用 `widgets/text` 的 `Text` 绘制，内容格式是“标签 + 距离”，颜色则按目标类型区分。
- 当前文字圈半径由 `RING_RADIUS` 控制，玩家头顶偏移由 `PLAYER_SCREEN_Y_OFFSET` 控制，字体大小由 `LABEL_FONT_SIZE` 控制，标签实例数量则按实际目标数动态创建。
