import pygame
import os


# Quick and dirty (debug) colors here (somewhat akin to VERA's first 16 colors0
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED  = (255, 64, 64)
CYAN = (64, 255, 255)
MAGENTA = (255, 64, 255)
GREEN = (64, 255, 64)
BLUE  = (64, 64, 255)
YELLOW = (255, 255, 64)

ORANGE = (255, 224, 0)
BROWN = (165, 42, 42)
PINK = (255, 224, 224)
DARKGRAY = (64, 64, 64)
GRAY = (128, 128, 128)
LIME = (224, 255, 224)
SKYBLUE = (224, 224, 255)
LIGHTGRAY = (192, 192, 192)

debug_colors = [
    BLACK,
    WHITE,
    RED,
    CYAN,
    MAGENTA,
    GREEN,
    BLUE,
    YELLOW,

    ORANGE,
    BROWN,
    PINK,
    DARKGRAY,
    GRAY,
    LIME,
    SKYBLUE,
    LIGHTGRAY,
]



def read_frame(frame_index, sf_bytes, current_byte_index):

    frame_flags = sf_bytes[current_byte_index]
    current_byte_index += 1
    
    clear_screen = frame_flags & 1
    contains_palette = frame_flags & 2
    is_indexed_frame = frame_flags & 4

    clear_screen_str = " "
    contains_palette_str = " "
    is_indexed_frame_str = " "
    if clear_screen:
        clear_screen_str = "C"
        #print("clear_screen: " + str(clear_screen))
    if contains_palette:
        contains_palette_str = "P"
        #print("contains_palette: " + str(contains_palette))
    if is_indexed_frame:
        is_indexed_frame_str = "I"
        #print("is_indexed_frame: " + str(is_indexed_frame))
    
    if contains_palette:
        nr_of_palette_entries = 0
        
        palette_mask_low = sf_bytes[current_byte_index]
        current_byte_index += 1
        while palette_mask_low:
            if (palette_mask_low & 1):
                nr_of_palette_entries += 1    
            palette_mask_low = palette_mask_low >> 1
        
        palette_mask_high = sf_bytes[current_byte_index]
        current_byte_index += 1
        while palette_mask_high:
            if (palette_mask_high & 1):
                nr_of_palette_entries += 1    
            palette_mask_high = palette_mask_high >> 1
            
        current_byte_index += nr_of_palette_entries * 2
        
        # print("nr_of_palette_entries: " + str(nr_of_palette_entries))
    
    color_and_nr_of_vertices = None
    nr_of_polygons = 0
    polygons = []
    if is_indexed_frame:
        nr_of_indexed_verices = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        vertices = []
        for vertex_index in range(nr_of_indexed_verices):
            x = sf_bytes[current_byte_index]
            y = sf_bytes[current_byte_index+1]
            current_byte_index += 2
            vertices.append((x,y))
        
        # Now reading the polygons
        
        color_and_nr_of_vertices = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        while (color_and_nr_of_vertices != 255 and color_and_nr_of_vertices != 254 and color_and_nr_of_vertices != 253):
            nr_of_vertices = color_and_nr_of_vertices & 15
            nr_of_polygons += 1
            color_index = (color_and_nr_of_vertices & 0xF0) >> 4
            
            polygon_vertices = []
            for vertex_in_polygon_index in range(nr_of_vertices):
                vertex_index = sf_bytes[current_byte_index]
                current_byte_index += 1 # one vertex-index per vertex
                
                polygon_vertices.append(vertices[vertex_index])
            
            polygon = {
                'polygon_vertices' : polygon_vertices,
                'color_index' : color_index
            }
            polygons.append(polygon)
            
            color_and_nr_of_vertices = sf_bytes[current_byte_index]
            current_byte_index += 1
            
    else:
        
        # Now reading the polygons
        
        color_and_nr_of_vertices = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        while (color_and_nr_of_vertices != 255 and color_and_nr_of_vertices != 254 and color_and_nr_of_vertices != 253):
            nr_of_vertices = color_and_nr_of_vertices & 15
            nr_of_polygons += 1
            color_index = (color_and_nr_of_vertices & 0xF0) >> 4
            
            polygon_vertices = []
            for vertex_in_polygon_index in range(nr_of_vertices):
                x = sf_bytes[current_byte_index]
                y = sf_bytes[current_byte_index+1]
                current_byte_index += 2 # x and y per vertex
                
                polygon_vertices.append((x,y))
            
            polygon = {
                'polygon_vertices' : polygon_vertices,
                'color_index' : color_index
            }
            
            polygons.append(polygon)
            
            color_and_nr_of_vertices = sf_bytes[current_byte_index]
            current_byte_index += 1
            
        #print(polygons)
        
    #print('{0:4.0f} '.format(frame_index)+ clear_screen_str + contains_palette_str + is_indexed_frame_str + " : "+str(nr_of_polygons))
    
    frame_data = {
        'polygons' : polygons,
        'clear_screen' : (clear_screen != 0)
    }
    
    return current_byte_index, color_and_nr_of_vertices, frame_data
    
def parse_scene_file():
    sf = open("scene1.bin", "rb")

    byte = True
    sf_bytes = bytearray()
    while byte:
        byte = sf.read(1)
        sf_bytes += byte
        
    frame_index = 0
    current_byte_index = 0
    
    frames = []
    mask_byte = 0
    while (mask_byte != 253):
        
        #print("Start of frame " + str(frame_index))
        end_byte_index, mask_byte, frame_data = read_frame(frame_index, sf_bytes, current_byte_index);
        
        frames.append(frame_data)
        
        if mask_byte == 254:
            # When we are at the original block marker (64kb blocks) we have to skip to the beginning of the next 64kb block
            current_byte_index = ((end_byte_index // 65536) + 1) * 65536 # start of new 64kb block
        else:
            current_byte_index = end_byte_index
        frame_index += 1

    #print(frame_index)
    
    return frames


# ====

screen_width = 256
screen_height = 200
scale = 3


background_color = (0,0,0)

pygame.init()

pygame.display.set_caption('X16 STNICCC sim')
screen = pygame.display.set_mode((screen_width*scale, screen_height*scale))
clock = pygame.time.Clock()


def run():

    running = True
    
    frames = parse_scene_file()
    
    #print(frames)
        
    frame_nr = 0
    
    screen.fill(background_color)
    
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)

        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False

            #if event.type == pygame.KEYDOWN:
                    
                #if event.key == pygame.K_LEFT:
                #if event.key == pygame.K_RIGHT:
                #    do_animate = True
                #if event.key == pygame.K_COMMA:
                #if event.key == pygame.K_PERIOD:
                #if event.key == pygame.K_UP:
                #if event.key == pygame.K_DOWN:
                    
            #if event.type == pygame.MOUSEMOTION: 
                # newrect.center = event.pos
        frame_data = frames[frame_nr]
        
        polygons = frame_data['polygons'] 

        if (frame_data['clear_screen']):
            screen.fill(background_color)
        
        for polygon in polygons:
            #print(polygon)
            polygon_vertices = polygon['polygon_vertices']
            color_index = polygon['color_index']
            
            # FIXME!
            color = debug_colors[color_index]
            #if (USE_FX_POLY_FILLER_SIM):
                # fx_sim_draw_polygon(screen, color, face['vertex_indices'], screen_vertices, {}, None)
            #else:
            scaled_polygon_vertices = [(polygon_vertices[i][0]*scale, polygon_vertices[i][1]*scale) for i in range(len(polygon_vertices))]
            pygame.draw.polygon(screen, color, scaled_polygon_vertices, 0)

        pygame.display.update()
        
        frame_nr += 1
        if (frame_nr >= len(frames)):
            running = False
        
        #time.sleep(0.01)
   
        
    pygame.quit()


run()
