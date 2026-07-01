# PlanTH — 项目状态（2026-07-01）

## 场景流
```
BoundaryLogo → MainMenu → CharacterSelect → Dialogue → Battle
                          ↔ Settings / Keybind
```

## 关键系统
- **存档**：`%Documents%/PlanTH/Saves/savedata1~3.json`，`SaveManager` Autoload 管理
- **设置**：`ConfigManager` Autoload，`res://config.ini` 持久化
- **输入**：WASD/方向键/手柄 → `move_up/down/left/right`，`\` 全局 GM
- **数据表**：`data/tables/*.xlsx` → `xls2json/convert_*.py` → `data/json/*.json`

## UI 约定
- GDScript 强制静态类型，`@onready` 引用节点，`snake_case` 信号
- 场景独立可运行的 `F6` 测试，无父级上下文依赖
- `queue_free()` 安全删除

## 待办
- 对话系统接入实际逻辑
- Excel 更新后运行 `python3 xls2json/convert_*.py`
- Mac/Win 跨机 Git 协作 （`.uid` 文件需手动修复）
