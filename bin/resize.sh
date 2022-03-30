INPUT=$1
OUTPUT=$2

magick "$INPUT" -resize 20x20 "${OUTPUT}_20x20@1x.png"
magick "$INPUT" -resize 40x40 "${OUTPUT}_20x20@2x.png"

magick "$INPUT" -resize 29x29 "${OUTPUT}_29x29@1x.png"
magick "$INPUT" -resize 58x58 "${OUTPUT}_29x29@2x.png"

magick "$INPUT" -resize 40x40 "${OUTPUT}_40x40@1x.png"
magick "$INPUT" -resize 80x80 "${OUTPUT}_40x40@2x.png"

magick "$INPUT" -resize 76x76 "${OUTPUT}_76x76@1x.png"
magick "$INPUT" -resize 152x152 "${OUTPUT}_76x76@2x.png"

magick "$INPUT" -resize 167x167 "${OUTPUT}_83.5@2x.png"

echo "Done"
