class_name UITheme
extends RefCounted
## 章节 UI 配色主题(接口)。每个章节在数据里写 "ui_theme": "<名字>"(tools/author_chapters.py)，
## 进入章节时 GameRoot 调 UIKit.apply_theme(名字)，HUD 按新配色重建；标题/结算等界面每次打开时读取当前配色。
## 不同底色的章节(雪白的遗迹 / 红黑的燃烧废墟 / 以后可能的浅色或蓝色场景)各自挑一套对比足够鲜明的配色。
## 缺的键从 DEFAULT 补齐，所以新主题只需要写和默认不同的颜色。
##
## 键：
##   panel / panel_soft / panel_deep   面板底色(常规 / 按钮与次级块 / 最深的底，如编号牌、遮罩)
##   line / line_strong                细线描边 / 强调描边与角标
##   text / text_soft / text_dim / text_mute   正文 / 次要 / 说明 / 最弱
##   accent        主题强调色：选中、标题条、英文标注、进度
##   action        主要行动按钮(开始作战 / 出发 / 继续)的底色；action_text 为其上的文字色
##   danger / good / gold              危险(出售、失败) / 正向数值 / 金币
##   keyword                           描述文字里的关键词(蓝色，悬停看详情)
##   player / enemy                    我方 / 敌方
##   fade          场景切换(大地图 ⇄ 战斗)淡入淡出的颜色
##   overlay       全屏界面(结算/暂停)的遮罩底色

const DEFAULT := "white"

const PALETTES := {
	# 第零章·白之章：世界是亮白的大理石 → 深石墨色面板 + 冷青色强调 + 明黄行动按钮，白底上对比最强
	"white": {
		"panel": Color(0.105, 0.11, 0.125, 0.94),
		"panel_soft": Color(0.17, 0.175, 0.195, 0.94),
		"panel_deep": Color(0.055, 0.058, 0.066, 0.97),
		"line": Color(1, 1, 1, 0.13),
		"line_strong": Color(1, 1, 1, 0.42),
		"text": Color("#f2f3f5"),
		"text_soft": Color("#c9ced8"),
		"text_dim": Color("#8d94a1"),
		"text_mute": Color("#5d636e"),
		"accent": Color("#23c1f2"),
		"action": Color("#ffc61a"),
		"action_text": Color("#17140b"),
		"danger": Color("#ff4b4b"),
		"good": Color("#62e295"),
		"gold": Color("#ffd24a"),
		"player": Color("#3fb2ff"),
		"enemy": Color("#ff5a52"),
		"keyword": Color("#4d8bff"),
		"fade": Color(0.965, 0.96, 0.95),
		"overlay": Color(0.02, 0.022, 0.03),
	},
	# 第一章·红之章(黑夜里燃烧的城市)：深红 / 火红 / 黑——红黑色的面板 + 火红强调 + 火橙行动按钮，淡入淡出用暗红
	"ember": {
		"panel": Color(0.085, 0.045, 0.042, 0.94),
		"panel_soft": Color(0.17, 0.075, 0.068, 0.94),
		"panel_deep": Color(0.045, 0.02, 0.02, 0.97),
		"line": Color(1.0, 0.55, 0.45, 0.14),
		"line_strong": Color(1.0, 0.45, 0.35, 0.45),
		"text_soft": Color("#d9c6c2"),
		"text_dim": Color("#a08c88"),
		"text_mute": Color("#6e5a56"),
		"accent": Color("#ff3d24"),
		"action": Color("#ff8a1c"),
		"action_text": Color("#1a0805"),
		"keyword": Color("#6a9bff"),
		"fade": Color(0.06, 0.015, 0.01),
		"overlay": Color(0.05, 0.012, 0.008),
	},
	# 第二章-A·紫之章(云海上的和风空岛，紫色的夜)：深紫面板 + 淡紫强调 + 冰青色的行动按钮，淡入淡出用深紫
	"frost": {
		"panel": Color(0.07, 0.05, 0.13, 0.94),
		"panel_soft": Color(0.14, 0.1, 0.24, 0.94),
		"panel_deep": Color(0.04, 0.025, 0.08, 0.97),
		"line": Color(0.75, 0.6, 1.0, 0.16),
		"line_strong": Color(0.75, 0.6, 1.0, 0.48),
		"text_soft": Color("#d6ccec"),
		"text_dim": Color("#9a8db8"),
		"text_mute": Color("#665a80"),
		"accent": Color("#b48cff"),
		"action": Color("#7fe3ff"),
		"action_text": Color("#0a1420"),
		"keyword": Color("#8fb4ff"),
		"fade": Color(0.06, 0.03, 0.12),
		"overlay": Color(0.04, 0.02, 0.08),
	},
	# 第一章-B·蓝之章(蓝色穹顶下的未来都市)：深海军蓝的面板 + 青色强调 + 白青的行动按钮
	"dome": {
		"panel": Color(0.05, 0.08, 0.15, 0.94),
		"panel_soft": Color(0.1, 0.16, 0.28, 0.94),
		"panel_deep": Color(0.03, 0.05, 0.1, 0.97),
		"line": Color(0.55, 0.8, 1.0, 0.16),
		"line_strong": Color(0.55, 0.8, 1.0, 0.5),
		"text_soft": Color("#c8dcf2"),
		"text_dim": Color("#8aa6c8"),
		"text_mute": Color("#58708c"),
		"accent": Color("#4fd2ff"),
		"action": Color("#eaf6ff"),
		"action_text": Color("#0a1a2e"),
		"keyword": Color("#8fb4ff"),
		"fade": Color(0.03, 0.07, 0.16),
		"overlay": Color(0.02, 0.04, 0.09),
	},
	# 预留：暗底章节可以反过来用浅色面板(纸白底 + 深色字 + 钴蓝强调)
	"paper": {
		"panel": Color(0.93, 0.925, 0.91, 0.95),
		"panel_soft": Color(0.86, 0.855, 0.84, 0.95),
		"panel_deep": Color(0.84, 0.835, 0.82, 0.97),
		"line": Color(0, 0, 0, 0.14),
		"line_strong": Color(0, 0, 0, 0.45),
		"text": Color("#17191e"),
		"text_soft": Color("#3a3e47"),
		"text_dim": Color("#636974"),
		"text_mute": Color("#8a9099"),
		"accent": Color("#0a7fc2"),
		"action": Color("#17191e"),
		"keyword": Color("#1558c0"),
		"action_text": Color("#f4f2ec"),
		"gold": Color("#b8860b"),
		"good": Color("#1f9d55"),
		"fade": Color(0.1, 0.1, 0.12),
		"overlay": Color(0.08, 0.08, 0.1),
	},
}


static func has(name: String) -> bool:
	return PALETTES.has(name)


## 取一套配色(缺的键用默认主题补齐)；未知名字 = 默认主题
static func palette(name: String) -> Dictionary:
	var base: Dictionary = (PALETTES[DEFAULT] as Dictionary).duplicate()
	if PALETTES.has(name):
		base.merge(PALETTES[name], true)
	return base
