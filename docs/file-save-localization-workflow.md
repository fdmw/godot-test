# 文件、配置、存档与多语言资源工作流

本文说明运行时文件与项目资源的边界，覆盖 `FileAccess`、JSON、`ConfigFile`、`ResourceSaver/Loader` 和 `Translation` 的基本用法。当前验证入口是 `tests/file_config/` 与 `tests/localization/`。

## 1. `res://` 和 `user://`

- `res://` 指向项目资源目录。它适合读取随项目发布的场景、脚本、图片、`.tres` 和只读初始数据；导出后它可能位于只读 PCK 中，不应把用户存档写回这里。
- `user://` 指向当前用户/应用的数据目录，适合设置、键位、存档和用户生成数据。它的实际物理位置由平台和项目标识决定，不应在业务代码中硬编码操作系统路径。

路径应使用 Godot 虚拟路径，并在打开、读取、解析后检查错误。需要把虚拟路径转换为系统路径时，使用 `ProjectSettings.globalize_path()`，只在确实需要 `DirAccess` 或平台 API 时这样做。

## 2. JSON 与 ConfigFile

JSON 适合跨语言、结构相对自由的存档或交换数据：

```gdscript
var file := FileAccess.open("user://save.json", FileAccess.WRITE)
if file != null:
	file.store_string(JSON.stringify({"version": 1, "gold": 20}))
	file.close()
```

读取 JSON 得到 `Variant`，必须先判断解析结果的类型、版本和字段，再转换为核心逻辑需要的类型；不能直接把未验证的 Dictionary 当成可信运行时状态。

`ConfigFile` 是 INI 风格的节/键配置，适合音量、窗口模式和用户选项：

```gdscript
var config := ConfigFile.new()
config.set_value("audio", "master_db", -6.0)
var error := config.save("user://settings.cfg")
```

读取时检查 `load()` 返回的 Error，并为缺失键提供默认值。无论使用 JSON 还是 ConfigFile，都应考虑存档版本、字段缺失、损坏文件和清理策略。

## 3. Resource 文件与运行时存档

`ResourceSaver`/`ResourceLoader` 适合保存和加载 Godot Resource，尤其是需要 Inspector 类型信息、嵌套资源或引擎数据类型的内容。它们不自动解决存档版本迁移，也不应把共享内容 Resource 直接当作某个实例的可变状态。

静态内容放 `res://`，用户产生的 Resource 放 `user://`。若保存 JSON、CSV 等非 Resource 文件，导出时要确认 Export Preset 的非资源文件过滤器包含这些扩展名；否则编辑器中能读、导出包中却可能不存在。

`tests/file_config/` 会在 `user://` 写入 JSON 和 ConfigFile，读取后再删除本测试生成的文件。该测试不使用项目目录作为写入目标，避免污染源文件。

## 4. 多语言资源

翻译内容可以保存为 `Translation` Resource（例如 `zh_CN.tres`、`en.tres`），再由 `TranslationServer` 注册。文本显示时使用稳定的翻译键，例如 `demo_greeting`，不要在多个脚本中复制语言判断：

```gdscript
var translated := TranslationServer.translate("demo_message")
```

编辑器中也可以通过 Project Settings 的国际化配置管理翻译资源；运行时切换语言后，动态文本需要重新取得翻译结果。进入测试时保存原 locale，退出时移除测试注册的 Translation 并恢复原语言，避免进程级 TranslationServer 状态污染其他场景。

当前 `tests/localization/` 用 ResourcePreloader 提供中英文 Translation，切换 OptionButton 并刷新带用户名字的动态文本，验证资源注册、locale 切换和动态格式化。

## 5. 排错顺序

先确认虚拟路径、文件是否存在和 `FileAccess.get_open_error()`；然后检查读写 Error；再检查 JSON 顶层类型、ConfigFile 节/键和存档版本；最后才检查 UI 没有刷新或 TranslationServer 没有恢复等表现问题。

参考：[FileAccess](https://docs.godotengine.org/en/4.7/classes/class_fileaccess.html)、[JSON](https://docs.godotengine.org/en/4.7/classes/class_json.html)、[ConfigFile](https://docs.godotengine.org/en/4.7/classes/class_configfile.html)、[Internationalizing games](https://docs.godotengine.org/en/4.7/tutorials/i18n/internationalizing_games.html)、[ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html)。
