import images.intro_logo_left as intro_logo_left
import images.intro_text as intro_text

# Used this to create pixelBytes and paletteBytes: https://lvgl.io/tools/imageconverter  (full color bmp to c-array, 256 colors indexed)
# First scale X16.png to 70% (paint)
# Then use this: https://online-converting.com/image/convert2bmp/#  FIRST DO THESE SETTINGS: -> "8 (Indexed)" and "Quantization = 4" and "Using dithering : no", THEN LOAD THE FILE!
# Then load into: https://pinetools.com/split-image -> create c array (256 colors indexed)

# Analysis website: http://mkweb.bcgsc.ca/color-summarizer/?home
# Replacing a color: https://www2.lunapic.com/editor/   (somehow replaces multiple colors?!)
# Converting to 2-bits grayscale: https://stackoverflow.com/questions/35797988/converting-images-to-indexed-2-bit-grayscale-bmp
#  convert "X16_70percent - black trial2 - nice_1.png" -depth 2  -colorspace gray test.png
# maybe use this in combination with: https://imagemagick.org/script/color-thresholding.php  --> DOESNT WORK!



# IDEA:   *** DID NOT THIS!! ***
# - We create an image of 640x480
#     - We add text to it (this gets some non-gray colors around the text)
# - We remove the colored "wings" and save it as _1
# - We remove all but the colored "wings" and save it as _2
# - We convert _1 to a gray scale image using:
#     - convert "X16_70percent - black trial2 - nice_1.png" -colorspace gray test.png
# - We convert the resulting image into a 256-indexed-color .c file (https://lvgl.io/tools/imageconverter)
# - We use search-and-replace to make it a .py file and import it
# - We use the python code below to change the 256 gray colors into 4 gray colors

# BETTER: *** DID THIS!! ***
# - replace colors maybe this way: https://onlinepngtools.com/change-png-color
#   - Open "X16_70percent - black trial2 - nice_1.png"
#   - replace 'white' with 'white' with 20% similarity -> save as "test6.png"
#   - replace 'black' with 'black' with 20% similarity -> save as "test7.png"
#   - replace 'rgb(85, 85, 85)' with 'rgb(85, 85, 85)' with 30% similarity -> save as "test8.png"
#   - replace 'rgb(171, 171, 171)' with 'rgb(171, 171, 171)' with 30% similarity -> save as "test9.png"
# Create a 256-index-color .c file (using: https://lvgl.io/tools/imageconverter )  -> save as introtext.c

# We have to change black into 0,0,0 and white into 255,255,255 (and change the greys too)

# - We crop the _2a image to a 64x64 pixel image (containing only 1 colored wing)
# - We convert the _2 image to a 256-indexed-color c file
# - We somehow find black, white and 2 gray colors in it (or create them by replacing hardly used colors
#   - NOTE: we seem to have move than enough colors left!!
#   - NOTE: we can move colors 0x01, 0x02 and 0x03 to a higher index (in _2) and use those for light-grey, dark-grey and white resp.
# - We combine the pallete (e.g. change the colors in the _1 image to the 4 gray colors indexes)

# - We create 2 files: INTROTEXT.BIN (640x480, 4 gray colors) INTROLOGO.BIN (64x64 pixels, 256 colors, for 2 sprite)

# - We could also use the python code (in the anwser) here: https://stackoverflow.com/questions/35797988/converting-images-to-indexed-2-bit-grayscale-bmp

# WARNING: RIGHT NOW WE HAVE TO ADD TWO BYTES!!!
header = [0x00, 0x00]

# Creating a pixel file for the logo (64x64 pixels, 8 bpp)
logoList = header + intro_logo_left.pixelBytes
logoFile = open("INTRO/" + intro_logo_left.filename_basename + ".BIN", "wb")
logoFile.write(bytearray(logoList))

# Creating a palette file for the logo and text (+ number of palette entries)
paletteBytesPacked = [len(intro_logo_left.paletteBytes)//3]
paletteBytesIndex = 0
while paletteBytesIndex < len(intro_logo_left.paletteBytes):
    # Green nibble + Blue nibble
    paletteBytesPacked.append((intro_logo_left.paletteBytes[paletteBytesIndex+1]//16)*16 + (intro_logo_left.paletteBytes[paletteBytesIndex]//16))
    #            0 + Red nibble
    paletteBytesPacked.append(intro_logo_left.paletteBytes[paletteBytesIndex+2]//16)
    paletteBytesIndex = paletteBytesIndex + 3
palleteList = header + paletteBytesPacked
paletteFile = open("INTRO/PALETTE.BIN", "wb")
paletteFile.write(bytearray(palleteList))

# Creating a pixel file for the text (640x480 pixels, 2 bpp)
pixelBytesPacked = []

# NOTE: current_tile_index cannot be higher than 1024, so we do 40*24 tiles (960 tiles). So we start at y = 3 and go until 27-1
tile_y = 3
while tile_y < 27:
    tile_x = 0
    while tile_x < 40:
        pixel_y = 0
        while pixel_y < 16:
            pixel_x = 0
            while pixel_x < 16:
                pixelBytesIndex = (tile_y * 16 + pixel_y) * 640 + (tile_x * 16 + pixel_x)
                pixelBytesPacked.append(intro_text.pixelBytes[pixelBytesIndex]*64 + intro_text.pixelBytes[pixelBytesIndex+1]*16 + intro_text.pixelBytes[pixelBytesIndex+2]*4 + intro_text.pixelBytes[pixelBytesIndex+3]*1)
                pixel_x += 4
            pixel_y += 1
        tile_x += 1
    tile_y += 1


#pixelBytesIndex = 0
#while pixelBytesIndex < len(intro_text.pixelBytes):
#    pixelBytesPacked.append(intro_text.pixelBytes[pixelBytesIndex]*64 + intro_text.pixelBytes[pixelBytesIndex+1]*16 + intro_text.pixelBytes[pixelBytesIndex+2]*4 + intro_text.pixelBytes[pixelBytesIndex+3]*1)
#    pixelBytesIndex = pixelBytesIndex + 4
textList = header + pixelBytesPacked
textFile = open("INTRO/" + intro_text.filename_basename + ".BIN", "wb")
textFile.write(bytearray(textList))


# ------ Zoom scroll values ------

def add_padding(some_list, target_len):
    return some_list[:target_len] + [0]*(target_len - len(some_list))

target_x = 338
target_y = 236
time_index = 0
zoom_index = 128

scroll_x_list_LO = []
scroll_x_list_HI = []
scroll_y_list_LO = []
zoom_scale = []

# FIXME: returned back to old way of only zooming in!
while time_index < 126:
# while time_index < 254:
    zoom_fraction = zoom_index / 128
    
    scroll_x = int(target_x - target_x * zoom_fraction)
    scroll_y = int(target_y - target_y * zoom_fraction)
    
    # FIXME: HACK!
    if scroll_x < 0:
        scroll_x_list_LO.append(0)
        scroll_x_list_HI.append(0)
    else:
        scroll_x_list_LO.append(scroll_x % 256)
        scroll_x_list_HI.append(scroll_x // 256)
        
    # FIXME: HACK!
    if scroll_y < 0:
        scroll_y_list_LO.append(0)
    else:
        scroll_y_list_LO.append(scroll_y % 256)
    zoom_scale.append(zoom_index)
    
    # FIXME: returned back to old way of only zooming in!
    zoom_index -= 1
    
#    if time_index < 127:
#        zoom_index += 1
#    else:
#        zoom_index -= 2
    
    time_index += 1


zoomList = header + add_padding(scroll_x_list_LO, 256) + add_padding(scroll_x_list_HI,256) + add_padding(scroll_y_list_LO,256) + add_padding(zoom_scale,256)
zoomFile = open("INTRO/ZOOM.BIN", "wb")
zoomFile.write(bytearray(zoomList))
