#!/usr/bin/env bash
# Собирает игровые спрайты из картинок GPT (raw/) и кладёт их в проект Godot (art/gpt/).
# Размеры в игровых пикселях; экран игры 640×360, Геннадий ростом 48.
set -euo pipefail
cd "$(dirname "$0")"
T=../tools
OUT=out
rm -rf "$OUT" split
mkdir -p "$OUT"
px() { python3 -I $T/pixelize.py "$@"; }

px raw/01_sky.png            $OUT/sky.png          --size 640x360                  --godot gpt/sky.png
px raw/02_distant_city.png   $OUT/far_city.png     --size 640x0 --key --crop       --godot gpt/far_city.png
px raw/03_bridge_train.png   $OUT/bridge.png       --size 640x0 --key --crop       --godot gpt/bridge.png
px raw/04_sidewalk.png       $OUT/sidewalk.png     --size 640x0 --key --crop       --godot gpt/sidewalk.png
px raw/05_office_tower.png   $OUT/office.png       --size 0x520 --key --crop       --godot gpt/office.png
px raw/06_shawarma_truck.png $OUT/truck.png        --size 180x0 --key --crop       --godot gpt/truck.png

python3 -I $T/split_sheet.py raw/07_tigran.png split/tigran --grid 3x1 --names happy,shock,grumpy
for n in happy shock grumpy; do px split/tigran/$n.png $OUT/tigran_$n.png --size 0x64 --key --crop --godot gpt/tigran_$n.png; done
# Тигран в окошке фургона: те же три эмоции высотой 30 точек
python3 -I $T/small_sprite.py raw/07_tigran.png $OUT --cols 3 --names happy,shock,grumpy --height 30 --prefix tigran_small --godot gpt

python3 -I $T/split_sheet.py raw/08_basic_food.png split/food --grid 3x2 --names lavash,chicken,cabbage,onion,garlic,soda
python3 -I $T/split_sheet.py raw/09_tigran_dishes.png split/food --grid 4x3 --names salad,glavash,tchicken,filling,shawarma,combo,fizz,tears,sauer,double,lunch,mush
for f in split/food/*.png; do n=$(basename "$f" .png); px "$f" $OUT/food_$n.png --size 0x28 --key --crop --godot gpt/food_$n.png; done

# Геннадий: полоски 12_…17_gennady_*.png → лист анимаций 64×64 (если полосок ещё нет, ряд пустой)
if ls raw/1[2-7]_gennady_*.png >/dev/null 2>&1; then
  python3 -I $T/hero_sheet.py raw $OUT/gennady --godot gennady_sheet.png
fi

# Интерфейс (10a–10c): свои цвета картинки и ровные края для растяжения, в art/ui/
python3 -I $T/ui_kit.py raw $OUT/ui --godot

# Небо (11a–11c): облака на 1000 м, ориентиры высоты, голубь (5 кадров одного размера)
if [ -f raw/11a_clouds.png ]; then
  python3 -I $T/split_sheet.py raw/11a_clouds.png split/clouds --names wide,tall,two,small,strip1,strip2
  for n in wide tall two small strip1 strip2; do
    w=$(python3 -c "import sys;sys.path.insert(0,'$T');import pixelize;from PIL import Image;b=pixelize.content_bbox(Image.open('split/clouds/$n.png'),90);print(round((b[2]-b[0])/6))")
    px split/clouds/$n.png $OUT/cloud_$n.png --size ${w}x0 --key --crop --godot gpt/cloud_$n.png
  done
fi
if [ -f raw/11c_landmarks.png ]; then
  python3 -I $T/split_sheet.py raw/11c_landmarks.png split/marks --names balloon,plane,kite,probe
  for n in balloon plane kite probe; do
    w=$(python3 -c "import sys;sys.path.insert(0,'$T');import pixelize;from PIL import Image;b=pixelize.content_bbox(Image.open('split/marks/$n.png'),90);print(round((b[2]-b[0])/7))")
    px split/marks/$n.png $OUT/mark_$n.png --size ${w}x0 --key --crop --godot gpt/mark_$n.png
  done
fi
if [ -f raw/11b_pigeon.png ]; then
  python3 -I $T/split_sheet.py raw/11b_pigeon.png split/pigeon --grid 5x1 --names f1,f2,f3,f4,daze
  for n in f1 f2 f3 f4 daze; do px split/pigeon/$n.png $OUT/pigeon_$n.png --size 38x38 --key --godot gpt/pigeon_$n.png; done
fi

# Пышечная (19–22). Ларёк включается в игре сам, когда есть все её картинки (GameData.kiosk_ready).
[ -f raw/19_pyshki_stall.png ] && px raw/19_pyshki_stall.png $OUT/stall_pyshki.png --size 182x0 --key --crop --godot gpt/stall_pyshki.png
if [ -f raw/20_valya.png ]; then
  python3 -I $T/split_sheet.py raw/20_valya.png split/valya --grid 3x1 --main --names happy,shock,grumpy
  for n in happy shock grumpy; do px split/valya/$n.png $OUT/valya_$n.png --size 0x64 --key --crop --godot gpt/valya_$n.png; done
  python3 -I $T/small_sprite.py raw/20_valya.png $OUT --cols 3 --names happy,shock,grumpy --height 30 --prefix valya_small --godot gpt
fi
if [ -f raw/21_pyshki_food.png ]; then
  python3 -I $T/split_sheet.py raw/21_pyshki_food.png split/pfood --names pyshka,sugar,condensed,coffee,kefir,jam
fi
if [ -f raw/22_pyshki_dishes.png ]; then
  python3 -I $T/split_sheet.py raw/22_pyshki_dishes.png split/pfood --names psugar,pcond,pjam,ccoffee,tea,sweetfizz,gkefir,shpyshka,klunch
fi
if [ -d split/pfood ]; then
  for f in split/pfood/*.png; do n=$(basename "$f" .png); px "$f" $OUT/food_$n.png --size 0x28 --key --crop --godot gpt/food_$n.png; done
fi
