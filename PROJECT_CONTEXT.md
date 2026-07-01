# PlanTH — 项目上下文

> 本文件供 WorkBuddy 在新设备上快速了解项目已完成的工作和当前状态。  
> 最后更新：2026-07-01

---

## 项目概况

- **引擎**：Godot 4.7（桌面 Vulkan 时用 d3d12），渲染兼容模式 `gl_compatibility`
- **语言**：GDScript
- **窗口**：1280×720，Canvas Items 拉伸
- **物理**：Jolt Physics（3D）
- **启动场景**：`Scenes/BeginPlay/boundary_logo.tscn`（uid://bnq4eutdrcu2h）
- **Autoload**：`ConfigManager`（`Scenes/Config/config_manager.gd`）

---

## 场景流程

```
BoundaryLogo（闪屏） → MainMenu（主菜单） → CharacterSelect（角色选择） → Dialogue（对话） → Battle（战斗）
                                                ↓
                                           Settings（设置）
```

### 1. 闪屏 `Scenes/BeginPlay/`

| 文件 | 说明 |
|------|------|
| `boundary_logo.tscn` | `SplashContent` 包裹正中团队标识 + 右下角 Godot 品牌 |
| `boundary_logo.gd` | `modulate.a=0` 起 → 0.5s 淡入 → 停 1s → 1s 淡出 → 切主菜单 |

- 布局：正中上方 Godot logo 占位（160×160）+ 下方 "Team Boundary"，右下角竖排 Godot 图标 + "GODOT"
- 背景由 `project.godot` 的 `rendering/environment/defaults/default_clear_color` 提供深蓝色 `(0.02, 0.02, 0.08, 1)`，无独立 ColorRect
- 引擎启动画面已禁（`boot_splash/show_image=false`）

### 2. 主菜单 `Scenes/MainMenu/`

- 壁纸 `Arts/Background/MainMenu/Wallpaper.jpg` + 半透明深蓝遮罩
- 按钮：开始游戏、继续游戏、设置、退出游戏
- BGM `Audios/Background/momiji no korankei.mp3`，0.5s 淡入淡出
- ESC 弹出退出确认弹窗（带 0.2s 冷却防连按）
- “开始游戏” → 角色选择；“退出/继续/退出确认” → quit；“设置” → 设置场景

### 3. 角色选择 `Scenes/CharacterSelect/`

- 数据驱动：从 `data/tables/角色表.json` 加载角色（工具 `tools/convert_characters.py` 从 xlsx 转换）
- 底部缩略图切换角色，中央显示大图背景
- 难度选择：简单 / 普通 / 困难 / 地狱（按钮禁用=当前选中）
- “出发” → 对话场景，“返回” → 主菜单
- 待办：角色立绘占位、实际属性读取、难度传递到后续场景

### 4. 对话场景 `Scenes/Dialogue/`

- 底部对话面板（说话人 + 文本 + 三选项）
- 齿轮菜单（继续/背包/设置/返回/退出），触发按钮在左上角
- 待办：接入实际对话系统、背包逻辑

### 5. 设置 `Scenes/Settings/`

- `settings_menu.tscn`：分辨率/窗口模式/VSync
- `keybind_menu.tscn`：按键绑定
- 配置持久化：`ConfigManager` 读写 `res://config.ini`

## 战斗关卡 `Scenes/Battle/`

完全程序化绘制，无场景图节点。

### 核心参数

| 参数 | 值 |
|------|-----|
| 玩家速度 | 300 px/s（WASD 八向） |
| 玩家 hitbox | 半径 20px |
| 子弹速度 | 250 px/s |
| 子弹半径 | 10px |
| 发射间隔 | 1s |
| 发射位置 | 四角 10% 边距处 |

### 擦弹（Graze）

| 参数 | 值 |
|------|-----|
| 擦弹半径 | hitbox × 1.6 = 32px |
| 冷却 | 1s/发子弹 |
| 判定方式 | 子弹**穿出**擦弹圈才 +1 分（不是进入就计分） |

判定逻辑（`_check_graze`）：
1. 每帧记录每颗子弹是否在擦弹圈内（`_projectile_was_in_graze` 数组）
2. `was_in_graze && !in_graze && cooldown <= 0` → 计分
3. 命中优先于擦弹（碰撞检查在擦弹之前），命中后直接死亡，不会误计擦弹

### GM 菜单（右上角）

- `GMButton`（右上角 "GM" 按钮）→ 切换 `GMPanel` 显示
- `GMPanel`：全屏半透明黑遮罩
  - ✕ 关闭按钮（右上角）
  - "开启玩家无敌" / "关闭玩家无敌" 切换按钮（居中）
- 无敌时 `_check_player_collision()` 直接 return，子弹穿身不死

### UI 元素

- 左上角 `ScoreLabel`：实时积分（字体 28）
- 中央顶部 `Instructions`：`"WASD — 移动 | 躲避 ⚡"`
- 四角 `EmitterTL/TR/BL/BR`：⚡ 发射器标记
- 玩家 `PlayerIndicator`：★ 标记（字体 48）

---

## 输入系统

由 `ConfigManager._setup_default_input_actions()` 在启动时注册：
- `move_up/down/left/right`：WASD + 方向键 + 手柄

---

## 资源文件

| 路径 | 说明 |
|------|------|
| `Arts/Icon/BeginPlay/icon.svg` | 项目图标 + 闪屏占位 logo |
| `Arts/Background/MainMenu/Wallpaper.jpg` | 主菜单壁纸 |
| `Audios/Background/momiji no korankei.mp3` | 主菜单 BGM |

---

## 工具

| 文件 | 说明 |
|------|------|
| `tools/convert_characters.py` | Excel 角色表 → JSON |
| `tools/read_xlsx.py` | Excel 读取辅助 |

运行：`python3 tools/convert_characters.py`

---

## 已完成 & 待办

### ✅ 已完成
- [x] 闪屏穿帮修复（清屏色对齐 + 无独立背景 + 仅 logo 淡出）
- [x] 闪屏布局重排（参考 Blobfish Games）
- [x] 闪屏 0.5s 淡入
- [x] 擦弹机制（穿过计分 + 1s 冷却 + 可视化擦弹圈）
- [x] GM 菜单 + 玩家无敌开关
- [x] Git 远程切换为 SSH（git@github.com:tomoliu/PlanTH.git）

### ⏳ 待办
- [ ] 角色立绘替换闪屏占位 logo
- [ ] SaveManager + GameManager 正式化
- [ ] 对话系统 + 背包逻辑
- [ ] 角色难度选择传递到战斗
- [ ] 战斗系统正式化（当前仅弹幕躲避 demo）
- [ ] 擦弹视觉反馈增强
- [ ] Excel 变更后需重新运行 `convert_characters.py`
