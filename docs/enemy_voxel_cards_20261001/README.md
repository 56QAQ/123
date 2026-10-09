# 敌人体素多视角分拆角色卡

为 D:\voxel 自走棋游戏制作的敌人建模参考图，延续上一批 46 张单位角色卡的版式和体素风格。

## 覆盖范围

源目录：G:\auto_battler\auto_battler\rebuild_auto_battler\assets\enemies

已完成全部 12 个非 _battle 敌人单位：dummy、rangeddummy、ember_dragon、ember_envy、ember_gluttony、ember_greed、ember_lust、ember_melancholy、ember_pride、ember_sloth、ember_vanity、ember_wrath。排除 _battle PNG 和 Godot .import 文件。

## 浏览与文件

- index.html：本地图库，按文件名搜索，点击卡片查看原尺寸。
- cards/：每个敌人一张独立 PNG 参考卡。
- prompts/：逐张实际提交的完整绘图提示词。
- manifest.json：源图路径与校验值、输出对应关系、像素尺寸、提示词和参考图路径。
- verification.json：整套交付核验记录。

每张卡包含左上主视图、右上独立装备或结构模块、左下正面/背面/侧面转面、右下三处特写。非人形敌人保留原有生物或物件结构：眼球、魔书、水母、触须团、熔岩软泥与盘踞龙身均按自身形体制作。

## 风格与生成

全部使用 Codex 内置 image_gen 工具，每个敌人单独绘制。源敌人 PNG 决定身份和配色；上一批 archer_voxel_card.png 决定版式、背景和展示方式；D:\voxel\docs\character_sheet.png 决定游戏体素造型语言。保留清晰立方体网格、阶梯轮廓和可读的连接结构，将熔岩裂纹、火焰与装饰简化为可建模的体素块。

PNG 使用工具原始输出尺寸。图片属于建模设计参考，非 .vox 文件或三维网格；原图未展示的背面、内侧与装配结构根据已有设计补全，建模时需进一步统一网格与关节。

## 交付核验

12 张已逐张目视检查并成功解码，12 张为 1122 × 1402 像素。全部源敌人已覆盖，输出校验值各不重复，源图校验值保持不变。

魔书 ember_greed 的正面内页视角经单独修正，修订提示词保存在 prompts/ember_greed_revision.txt，生成过程对应关系见 manifest.json。

