"""对照图：角色卡的正/背/侧三视图 vs 模型的 A 字姿势正/背/左侧渲染(run_char.sh 产物)。
用法: python tools/char_compare.py <模型> <角色卡.png> [out=<文件名>]   → out/chars/<模型>_cmp.png(或 out= 指定)
上排 = 角色卡下半部的三视图(FRONT/BACK/SIDE)，下排 = 模型(同顺序，按身高对齐)；右侧 = 头部特写对照。"""
import sys
from PIL import Image

mid, card = sys.argv[1], sys.argv[2]
out_name = f"out/chars/{mid}_cmp.png"
for a in sys.argv[3:]:
    if a.startswith("out="):
        out_name = a[4:]
c = Image.open(card).convert("RGB")
W, H = c.size
# 三视图面板(卡片版式统一：左下 70% 宽)
panel = c.crop((int(W * 0.012), int(H * 0.59), int(W * 0.705), int(H * 0.99)))
head = c.crop((int(W * 0.718), int(H * 0.552), int(W * 0.985), int(H * 0.685)))
ap = Image.open(f"out/chars/{mid}_turn_apose.png").convert("RGB")
cw = ap.width // 4
cells = [ap.crop((i * cw, 0, (i + 1) * cw, ap.height)) for i in (0, 3, 2)]   # front, back, left
row = Image.new("RGB", (cw * 3, ap.height), (220, 216, 210))
for i, im in enumerate(cells):
    row.paste(im, (i * cw, 0))
# 模型行裁掉上下空白，按卡片人物的高度比例缩放
row = row.crop((0, int(ap.height * 0.06), row.width, int(ap.height * 0.97)))
th = 560
panel = panel.resize((int(panel.width * th / panel.height), th))
row = row.resize((int(row.width * th / row.height), th))
face = Image.open(f"out/chars/{mid}_face.png").convert("RGB").resize((280, 280))
head = head.resize((int(head.width * 280 / head.height), 280))
out = Image.new("RGB", (max(panel.width, row.width) + max(face.width, head.width) + 20, th * 2 + 10), (40, 40, 44))
out.paste(panel, (0, 0))
out.paste(row, (0, th + 10))
x2 = max(panel.width, row.width) + 20
out.paste(head, (x2, 0))
out.paste(face, (x2, th + 10))
out.save(out_name)
print("saved", out_name, out.size)
