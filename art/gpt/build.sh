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

# Чебуречная (23–26). Тоже включается сама, когда есть все картинки.
[ -f raw/23_chebureki_stall.png ] && px raw/23_chebureki_stall.png $OUT/stall_chebureki.png --size 190x0 --key --crop --extra 173a29,1f4d35,2b5a37,3a6b45 --godot gpt/stall_chebureki.png
if [ -f raw/24_mihalych.png ]; then
  python3 -I $T/split_sheet.py raw/24_mihalych.png split/mihalych --grid 3x1 --main --names happy,shock,grumpy
  for n in happy shock grumpy; do px split/mihalych/$n.png $OUT/mihalych_$n.png --size 0x64 --key --crop --extra f0a060,f7b77a,c8603c,e07850 --godot gpt/mihalych_$n.png; done
  python3 -I $T/small_sprite.py raw/24_mihalych.png $OUT --cols 3 --names happy,shock,grumpy --height 30 --prefix mihalych_small --godot gpt
fi
if [ -f raw/25_chebureki_food.png ]; then
  python3 -I $T/split_sheet.py raw/25_chebureki_food.png split/cfood --names dough,mince,oil,cheese,adjika,kvass
fi
if [ -f raw/26_chebureki_dishes.png ]; then
  python3 -I $T/split_sheet.py raw/26_chebureki_dishes.png split/cfood --names cheburek,chcheese,belyash,fire,firekvass,okroshka,donut,fshawarma,station
fi
if [ -d split/cfood ]; then
  for f in split/cfood/*.png; do n=$(basename "$f" .png); px "$f" $OUT/food_$n.png --size 0x28 --key --crop --godot gpt/food_$n.png; done
fi
# корзина фритюра из 25 в 28 точках превращается в кашу из сетки: масло рисуем по точкам
[ -f raw/25_chebureki_food.png ] && python3 -I $T/draw_oil.py $OUT/food_oil.png --godot gpt/food_oil.png

# Хот-доги у стадиона (29–32). Включаются сами, когда есть все картинки. Цвета --extra подобрать по факту.
[ -f raw/29_hotdogs_stall.png ] && px raw/29_hotdogs_stall.png $OUT/stall_hotdogs.png --size 190x0 --key --crop --godot gpt/stall_hotdogs.png
if [ -f raw/30_zhora.png ]; then
  python3 -I $T/split_sheet.py raw/30_zhora.png split/zhora --grid 3x1 --main --names happy,shock,grumpy
  for n in happy shock grumpy; do px split/zhora/$n.png $OUT/zhora_$n.png --size 0x64 --key --crop --godot gpt/zhora_$n.png; done
  python3 -I $T/small_sprite.py raw/30_zhora.png $OUT --cols 3 --names happy,shock,grumpy --height 30 --prefix zhora_small --godot gpt
fi
if [ -f raw/31_hotdogs_food.png ]; then
  python3 -I $T/split_sheet.py raw/31_hotdogs_food.png split/hfood --names sausage,bun,mustard,ketchup,pickle,fries
fi
if [ -f raw/32_hotdogs_dishes.png ]; then
  python3 -I $T/split_sheet.py raw/32_hotdogs_dishes.png split/hfood --names hotdog,mdog,kdog,kfries,zakuska,lavashdog,sdough,cfries,final
fi
if [ -d split/hfood ]; then
  for f in split/hfood/*.png; do n=$(basename "$f" .png); px "$f" $OUT/food_$n.png --size 0x28 --key --crop --godot gpt/food_$n.png; done
fi

# Космос (33–34): край Земли на всю ширину экрана и четыре предмета над 2000 м. Каждая включается сама.
[ -f raw/33_space_earth.png ] && px raw/33_space_earth.png $OUT/space_earth.png --size 640x0 --key --crop --godot gpt/space_earth.png
if [ -f raw/34_space_objects.png ]; then
  python3 -I $T/split_sheet.py raw/34_space_objects.png split/space --grid 4x1 --main --names sputnik,cosmonaut,station,dog
  px split/space/sputnik.png $OUT/space_sputnik.png --size 44x0 --key --crop --godot gpt/space_sputnik.png
  px split/space/cosmonaut.png $OUT/space_cosmonaut.png --size 0x44 --key --crop --godot gpt/space_cosmonaut.png
  px split/space/station.png $OUT/space_station.png --size 120x0 --key --crop --godot gpt/space_station.png
  px split/space/dog.png $OUT/space_dog.png --size 0x50 --key --crop --godot gpt/space_dog.png
fi

# За границей (35–40): море, островок с пограничным столбом, Париж и Китай. Страна включается, когда есть её картинки и 35–36.
if [ -f raw/35_sea.png ]; then px raw/35_sea.png $OUT/sea.png --size 640x0 --key --crop --godot gpt/sea.png; fi
if [ -f raw/36_border.png ]; then px raw/36_border.png $OUT/border.png --size 150x0 --key --crop --godot gpt/border.png; fi
for f in raw/3[79]_*_far.png raw/38_*_street.png raw/40_*_street.png; do
  if [ -f "$f" ]; then n=$(basename "$f" .png); n=${n#*_}; px "$f" $OUT/$n.png --size 640x0 --key --crop --godot gpt/$n.png; fi
done

# Значки интерфейса (10d): газ и пузо у шкал, кубок достижений, медали итогов. В art/ui/.
# Книга из 10d в маленьком размере не читается, на кнопке книги осталась шаурма.
if [ -f raw/10d_ui_icons.png ]; then
  python3 -I $T/split_sheet.py raw/10d_ui_icons.png split/icons --grid 4x2 --names gas,belly,cup,cup_off,book,medal_gold,medal_silver,medal_bronze
  px split/icons/gas.png $OUT/icon_gas.png --size 0x16 --key --crop --godot ui/icon_gas.png
  px split/icons/belly.png $OUT/icon_belly.png --size 0x22 --key --crop --godot ui/icon_belly.png
  for n in cup cup_off; do px split/icons/$n.png $OUT/icon_$n.png --size 0x14 --key --crop --godot ui/icon_$n.png; done
  for n in medal_gold medal_silver; do px split/icons/$n.png $OUT/icon_$n.png --size 0x26 --key --crop --godot ui/icon_$n.png; done
  px split/icons/medal_bronze.png $OUT/icon_medal_bronze.png --size 0x26 --key --crop --extra c87a4a,a65a32,e09a6a --godot ui/icon_medal_bronze.png
fi
