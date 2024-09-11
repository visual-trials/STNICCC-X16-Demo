import pygame
import os


USE_FX_POLY_FILLER_SIM = True
ALLOW_PAUSING_AND_REVERSE_PLAYBACK = True


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



# =================== VERA FX SIM ===============

def top_vertices_are_at_the_start(top_vertex_indices, vertex_indices):
    
    # We check of all of the top vertex indices are in the first vertex indices
    for vertex_nr in range(len(top_vertex_indices)):
        if (top_vertex_indices[vertex_nr] not in vertex_indices[0:len(top_vertex_indices)]):
            return False
            
    return True
'''
    if len(top_vertex_indices) == 1:
        if top_vertex_indices[0] in vertex_indices[0:1]:
            return True
        else:
            return False
    elif len(top_vertex_indices) == 2:
        if (top_vertex_indices[0] in vertex_indices[0:2]) and (top_vertex_indices[1] in vertex_indices[0:2]):
            return True
        else:
            return False
        
    else:
        print("ERROR: we have more than TWO top vertices!!")
        return None
'''

def reset_fx_state(fx_state):
    fx_state = {
        'x1_pos' : int(256),  # This is a 11.9 fixed point value (so you should divide by 512 to get the real value)
        'x2_pos' : int(256),  # This is a 11.9 fixed point value (so you should divide by 512 to get the real value)
        'x1_incr' : int(0),   # This is a 6.9 fixed point value (so you should divide by 512 to get the real value)
        'x2_incr' : int(0),   # This is a 6.9 fixed point value (so you should divide by 512 to get the real value)
    }

def draw_fx_polygon_part(fx_state, frame_buffer, line_color, y_start, nr_of_lines_to_draw):

    for y_in_part in range(nr_of_lines_to_draw):
        y_screen = y_start + y_in_part

        # This is 'equivalent' of what happens when reading from DATA1
        fx_state['x1_pos'] += fx_state['x1_incr']
        fx_state['x2_pos'] += fx_state['x2_incr']
        
        x1 = int(fx_state['x1_pos'] / 512)
        x2 = int(fx_state['x2_pos'] / 512)
        
        if (x2-x1 < 0):
            print("ERROR: NEGATIVE fill length!")
            return False
        
# FIXME: what if x2 and x1 are the same? Wont that result in a draw -of one pixel- IN REVERSE?
        pygame.draw.line(frame_buffer, line_color, (x1, y_screen), (x2-1, y_screen), 1)
        
        # This is 'equivalent' of what happens when reading from DATA0 (this (effectively) also increments y_in_part)
        fx_state['x1_pos'] += fx_state['x1_incr']
        fx_state['x2_pos'] += fx_state['x2_incr']
        
    return True


def print_vertices(vertex_indices, screen_vertices):
    to_print = []
    str_vertex_indices = []
    for vertex_index in vertex_indices:
        screen_vertex = screen_vertices[vertex_index]
        to_print.append(str(screen_vertex))
        str_vertex_indices.append(str(vertex_index))
    print(', '.join(to_print)+' - ('+','.join(str_vertex_indices)+')')



def convert_increment_to_incr_components(increment):
    # The incoming increment is a signed integer number 
    
    # We can only store 15 bit signed numbers. BUT we can multiply by 32 if it doesnt fit.
    
    # In other words: 
    # if the incremnt is smaller than -16384 or larger than +16383, we should divide the number by 32
    x32_or = 0x00
    incr_less_accurate = increment
    if (increment < -16384 or increment > 16383):
        increment = increment // 32
        x32_or = 0x80
        # The resulting (less accurate) signed number should be returned as incr_less_accurate
        incr_less_accurate = increment * 32

    incr_16bit = increment # this value has (potentially) been divided by 32
    if incr_16bit < 0:
        incr_16bit = 256*256 + incr_16bit
    incr_packed_low = incr_16bit % 256
    incr_packed_high = ((incr_16bit // 256) & 0x7f) | x32_or

    return (incr_less_accurate, incr_packed_low, incr_packed_high)



def get_left_and_right_vertices(vertex_indices, screen_vertices):

    # == Setup left and right lists ==
    # - Get top vertex (index)
    # - Get bottom vertex (index)
    # - Create left and right list
    #   - If there is one top vertex both lists share it, if not they have a separate one
    #   - If there is one bottom vertex both lists share it, if not they have a separate one
    
    top_y = None
    bottom_y = None
    
    # There can be 1-2 top and bottom vertices. We keep a record of them.
    top_vertex_indices = None
    bottom_vertex_indices = None
    
    for vertex_index in vertex_indices:
        screen_vertex = screen_vertices[vertex_index]
        
        vertex_y = screen_vertex[1]
        
        if (top_y is None or vertex_y < top_y):
            top_y = vertex_y
            top_vertex_indices = []  # We create a new list (removing any old candidates)
            top_vertex_indices.append(vertex_index)
        elif (vertex_y == top_y):
            top_vertex_indices.append(vertex_index)
            
        if (bottom_y is None or vertex_y > bottom_y):
            bottom_y = vertex_y
            bottom_vertex_indices = []  # We create a new list (removing any old candidates)
            bottom_vertex_indices.append(vertex_index)
        elif (vertex_y == bottom_y):
            bottom_vertex_indices.append(vertex_index)
            
    # We rotate the list of vertex indices until the top vertice(s) are at the start of the list
    done_rotating = top_vertices_are_at_the_start(top_vertex_indices, vertex_indices)
    while (not done_rotating):
        vertex_indices = vertex_indices[1:] + vertex_indices[:1]
        done_rotating = top_vertices_are_at_the_start(top_vertex_indices, vertex_indices)
        
    if (len(top_vertex_indices) > 2):
    
        #print_vertices(vertex_indices, screen_vertices)
            
        nr_of_vertices_to_remove = len(top_vertex_indices) - 2
        #print(str(vertex_indices)+'>>'+str(top_vertex_indices))
        while nr_of_vertices_to_remove > 0:
            print("WARNING: removing redundant top vertice!")
            vertex_indices.pop(1)
            nr_of_vertices_to_remove -= 1
            
        #print_vertices(vertex_indices, screen_vertices)
            
        if len(vertex_indices) < 3:
            print("ERROR: less than 3 vertices left over.")
# FIXME: can we fix/prevent this?
            return None

    # If we have 2 top vertices we rotate once more (if we had more, we removed them), so the two top vertices are at either end of the list
    if (len(top_vertex_indices) >= 2):
        vertex_indices = vertex_indices[1:] + vertex_indices[:1]

    # print_vertices(vertex_indices, screen_vertices)
        
    # We create a left list and a right list of vertices (that contain the vertices that are that side of the polygon)
    left_vertices = []
    for vertex_index in vertex_indices:
        screen_vertex = screen_vertices[vertex_index]
        left_vertices.append(screen_vertex)
        # We keep adding vertices until we reach the (first) bottom vertex
        if (vertex_index in bottom_vertex_indices):
            break

    # If we have 1 top vertex we rotate once more, so the top vertex it at the end of the list
    if (len(top_vertex_indices) == 1):
        vertex_indices = vertex_indices[1:] + vertex_indices[:1]
        
    right_vertices = []
    vertex_indices.reverse()
    for vertex_index in vertex_indices:
        screen_vertex = screen_vertices[vertex_index]
        right_vertices.append(screen_vertex)
        # We keep adding vertices until we reach the (first) bottom vertex
        if (vertex_index in bottom_vertex_indices):
            break
            
    is_single_top = (len(top_vertex_indices) == 1)

    return (left_vertices, right_vertices, top_y, bottom_y, is_single_top)
    
    

def fx_sim_draw_polygon(draw_buffer, line_color_index, vertex_indices, screen_vertices, polygon_type_stats, colors):

    # FIXME: this is a bit of an ugly workaround!
    line_color = None
    if (colors is not None):
        line_color = colors[line_color_index]
    else:
        line_color = line_color_index
        
    (left_vertices, right_vertices, top_y, bottom_y, is_single_top) = get_left_and_right_vertices(vertex_indices, screen_vertices)
    
    polygon_bytes = []
    
    # == Drawing algo ==
    #  - Set x1 and x2 according to first in left/right list (NOTE: if the same we only have to export ONE in the data!)
    #  - set left and right indexes to 0 (n and m)
    #  - Calculate x1/x2 slopes by left[n+1]-left[n] and right[m+1]-right[m]
    #  - Calculate how many lines have to be drawn (is left[n+1] or right[n+1] top?)
    #  - draw the polygon part
    #  - increment n or m
    #  - set x1 or x2 position accordingly
    #  - set x1 incr or x2 incr accordingly
    #  - Calculate how many lines have to be drawn (is left[n+1] or right[n+1] top?)
    #  - Stop until left and right reach the end
    
    current_left_index = 0
    current_right_index = 0

    next_side_to_change_slope = None
    left_half_slope = None
    right_half_slope = None
    
    next_left_vertex = left_vertices[current_left_index+1]
    next_right_vertex = right_vertices[current_right_index+1]
    current_left_vertex = left_vertices[current_left_index]
    current_right_vertex = right_vertices[current_right_index]
    
    left_half_slope = int((next_left_vertex[0] - current_left_vertex[0]) / (next_left_vertex[1] - current_left_vertex[1]) * 256)
    right_half_slope = int((next_right_vertex[0] - current_right_vertex[0]) / (next_right_vertex[1] - current_right_vertex[1]) * 256)
    
    
    SINGLE_TOP_FREE_FORM_TYPE = 0x00
    DOUBLE_TOP_FREE_FORM_TYPE = 0x80
    
    # We take the top y as starting y position
    current_y_position = top_y

    left_pos = current_left_vertex[0]
    right_pos = current_right_vertex[0]
    
    fx_state['x1_pos'] = int(left_pos) * 512 + 256
    fx_state['x2_pos'] = int(right_pos) * 512 + 256
    
    polygon_type_identifier = ''
    if (is_single_top):
        polygon_type_identifier += 'SINGLE_TOP'
        
# FIXME: for now we are ONLY doing free form types!
        polygon_bytes.append(SINGLE_TOP_FREE_FORM_TYPE)
        polygon_bytes.append(line_color_index)
        polygon_bytes.append(current_y_position)
        x1_pos_int = int(left_pos)
        polygon_bytes.append(x1_pos_int % 256)
        polygon_bytes.append(x1_pos_int // 256)
    else:
        polygon_type_identifier += 'DOUBLE_TOP'
        
# FIXME: for now we are ONLY doing free form types!
        polygon_bytes.append(DOUBLE_TOP_FREE_FORM_TYPE)
        polygon_bytes.append(line_color_index)
        polygon_bytes.append(current_y_position)
        x1_pos_int = int(left_pos)
        polygon_bytes.append(x1_pos_int % 256)
        polygon_bytes.append(x1_pos_int // 256)
        x2_pos_int = int(right_pos)
        polygon_bytes.append(x2_pos_int % 256)
        polygon_bytes.append(x2_pos_int // 256)

    (x1_incr, x1_incr_low, x1_incr_high) = convert_increment_to_incr_components(left_half_slope)
    fx_state['x1_incr'] = x1_incr
    polygon_bytes.append(x1_incr_low)
    polygon_bytes.append(x1_incr_high)
    
    (x2_incr, x2_incr_low, x2_incr_high) = convert_increment_to_incr_components(right_half_slope)
    fx_state['x2_incr'] = x2_incr
    polygon_bytes.append(x2_incr_low)
    polygon_bytes.append(x2_incr_high)
    
    nr_of_lines_to_draw_larger_than_63 = False
    
# FIXME!
#    do_print = False
#    if (line_color_index == 197 and current_y_position == 108):
#        do_print = True
        
# FIXME!
#    if (do_print):
#        return None
    
    #if (do_print):
    #    print("This is the one!")
    #    #print_vertices(vertex_indices, screen_vertices)
    #    print(left_vertices)
    #    print(right_vertices)
    
    while (True):
    
        # Check which vertex is next in line to change (looking at the y-coordinate): we have to draw until that y-line
        if (next_left_vertex[1] < next_right_vertex[1]):
            next_side_to_change_slope = 'left'
            nr_of_lines_to_draw = next_left_vertex[1] - current_y_position
        elif (next_left_vertex[1] > next_right_vertex[1]):
            next_side_to_change_slope = 'right'
            nr_of_lines_to_draw = next_right_vertex[1] - current_y_position
        else:
            # Both are at the same y, so they both have to change
            next_side_to_change_slope = 'both'
            nr_of_lines_to_draw = next_left_vertex[1] - current_y_position
            
        if (nr_of_lines_to_draw > 63):
            nr_of_lines_to_draw_larger_than_63 = True

        polygon_bytes.append(nr_of_lines_to_draw)

        if (not draw_fx_polygon_part(fx_state, draw_buffer, line_color, current_y_position, nr_of_lines_to_draw)):
            print("ERROR: not adding polygon to polygon stream since it encountered an error during drawing!")
# FIXME: can we fix/prevent this?
            return None
        current_y_position += nr_of_lines_to_draw
        
        if ((current_right_index+1 == len(right_vertices)-1) and (current_left_index+1 == len(left_vertices)-1)):
            polygon_bytes.append(0x00)
            break

        if next_side_to_change_slope == 'right':
            polygon_type_identifier += '-CHANGE_RIGHT'
            polygon_bytes.append(0x02)
            
            # Change *right* slope
            current_right_index += 1
            
            next_right_vertex = right_vertices[current_right_index+1]
            current_right_vertex = right_vertices[current_right_index]
            
            #print(current_right_vertex)
            #print(next_right_vertex)

            polygon_part_height = next_right_vertex[1] - current_right_vertex[1]
            if (polygon_part_height <= 0):
                print("ERROR: not adding polygon to polygon stream since has a part with a zero or negative height!")
# FIXME: can we fix/prevent this?
                return None
            
            right_half_slope = int((next_right_vertex[0] - current_right_vertex[0]) / (polygon_part_height) * 256)
            
            (x2_incr, x2_incr_low, x2_incr_high) = convert_increment_to_incr_components(right_half_slope)
            fx_state['x2_incr'] = x2_incr
            polygon_bytes.append(x2_incr_low)
            polygon_bytes.append(x2_incr_high)
    
            # This is equivalent of what happens when setting the new x2_incr
            fx_state['x2_pos'] = int(fx_state['x2_pos'] / 512) * 512 + 256
            
        elif next_side_to_change_slope == 'left':
            polygon_type_identifier += '-CHANGE_LEFT'
            polygon_bytes.append(0x01)
            
            # Change *left* slope
            current_left_index += 1
            
            next_left_vertex = left_vertices[current_left_index+1]
            current_left_vertex = left_vertices[current_left_index]
            
            polygon_part_height = next_left_vertex[1] - current_left_vertex[1]
            if (polygon_part_height <= 0):
                print("ERROR: not adding polygon to polygon stream since has a part with a zero or negative height!")
# FIXME: can we fix/prevent this?
                return None
                
            left_half_slope = int((next_left_vertex[0] - current_left_vertex[0]) / (polygon_part_height) * 256)
            
            (x1_incr, x1_incr_low, x1_incr_high) = convert_increment_to_incr_components(left_half_slope)
            fx_state['x1_incr'] = x1_incr
            polygon_bytes.append(x1_incr_low)
            polygon_bytes.append(x1_incr_high)
            
            # This is equivalent of what happens when setting the new x1_incr
            fx_state['x1_pos'] = int(fx_state['x1_pos'] / 512) * 512 + 256
                        
        else:  # both
            polygon_type_identifier += '-CHANGE_BOTH'
            polygon_bytes.append(0x03)
            
            # -- Change *left* slope --
            current_left_index += 1
            
            next_left_vertex = left_vertices[current_left_index+1]
            current_left_vertex = left_vertices[current_left_index]

            polygon_part_height = next_left_vertex[1] - current_left_vertex[1]
            if (polygon_part_height <= 0):
                print("ERROR: not adding polygon to polygon stream since has a part with a zero or negative height!")
# FIXME: can we fix/prevent this?
                return None
                
            left_half_slope = int((next_left_vertex[0] - current_left_vertex[0]) / (polygon_part_height) * 256)
            
            (x1_incr, x1_incr_low, x1_incr_high) = convert_increment_to_incr_components(left_half_slope)
            fx_state['x1_incr'] = x1_incr
            polygon_bytes.append(x1_incr_low)
            polygon_bytes.append(x1_incr_high)
            
            # This is equivalent of what happens when setting the new x1_incr
            fx_state['x1_pos'] = int(fx_state['x1_pos'] / 512) * 512 + 256

            
            # -- Change *right* slope --
            current_right_index += 1
            
            next_right_vertex = right_vertices[current_right_index+1]
            current_right_vertex = right_vertices[current_right_index]
            
            polygon_part_height = next_right_vertex[1] - current_right_vertex[1]
            if (polygon_part_height <= 0):
                print("ERROR: not adding polygon to polygon stream since has a part with a zero or negative height!")
# FIXME: can we fix/prevent this?
                return None
                
            right_half_slope = int((next_right_vertex[0] - current_right_vertex[0]) / (polygon_part_height) * 256)
            
            (x2_incr, x2_incr_low, x2_incr_high) = convert_increment_to_incr_components(right_half_slope)
            fx_state['x2_incr'] = x2_incr
            polygon_bytes.append(x2_incr_low)
            polygon_bytes.append(x2_incr_high)
            
            # This is equivalent of what happens when setting the new x2_incr
            fx_state['x2_pos'] = int(fx_state['x2_pos'] / 512) * 512 + 256

#        print(str(fx_state['x1_incr'])+'..'+str(fx_state['x2_incr']))
            
    # -- TODO: This MAY beinteresting --
    # If all nr_of_lines_to_draw in the polygon are below 64, we can use the two higest bits (of the nr_of_lines_to_draw) to mark whether we should do L/R/Both/None for the next polygon part
    # So we want to know how many times it happens that we need more than 6 bit (>=64 lines to draw)
    #if (nr_of_lines_to_draw_larger_than_63):
    #    polygon_type_identifier += '-64+'
            
    if (polygon_type_identifier not in polygon_type_stats):
        polygon_type_stats[polygon_type_identifier] = 0
        
    polygon_type_stats[polygon_type_identifier] += 1
    
    return polygon_bytes

# / ============ VERA FX SIM ==================
















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

fx_state = {}


def run():

    running = True
    
    frames = parse_scene_file()
    
    max_frame_nr = len(frames)-1
    increment_frame_by = 1
        
    frame_nr = 0
    
    screen.fill(background_color)
    
    while running:
        # TODO: We might want to set this to max?
        clock.tick(60)

        for event in pygame.event.get():

            if event.type == pygame.QUIT: 
                running = False

            if event.type == pygame.KEYDOWN:
                if ALLOW_PAUSING_AND_REVERSE_PLAYBACK:
                    if event.key == pygame.K_RIGHT:
                        increment_frame_by = 1
                    if event.key == pygame.K_LEFT:
                        increment_frame_by = -1
                    if event.key == pygame.K_SPACE:
                        increment_frame_by = 0
                    if event.key == pygame.K_PERIOD:
                        frame_nr += 100
                    if event.key == pygame.K_COMMA:
                        frame_nr -= 100
                    if event.key == pygame.K_PERIOD:
                        frame_nr += 100
                    if event.key == pygame.K_COMMA:
                        frame_nr -= 100
                    if event.key == pygame.K_RIGHTBRACKET:
                        frame_nr += 1
                    if event.key == pygame.K_LEFTBRACKET:
                        frame_nr -= 1
                        
                    if frame_nr < 0:
                        frame_nr = 0
                    if frame_nr > max_frame_nr:
                        frame_nr = max_frame_nr

            #if event.type == pygame.MOUSEMOTION: 
                # newrect.center = event.pos
                
        frame_data = frames[frame_nr]
        
        polygons = frame_data['polygons'] 

        if (frame_data['clear_screen']):
            screen.fill(background_color)
        
    # FIXME: do we need to this this for each frame?
        reset_fx_state(fx_state)
        
        for polygon in polygons:
            #print(polygon)
            polygon_vertices = polygon['polygon_vertices']
            color_index = polygon['color_index']
            
            # FIXME!
            color = debug_colors[color_index]
            scaled_polygon_vertices = [(polygon_vertices[i][0]*scale, polygon_vertices[i][1]*scale) for i in range(len(polygon_vertices))]
            polygon_vertex_indices = list(range(len(scaled_polygon_vertices)))
            if (USE_FX_POLY_FILLER_SIM):
                fx_sim_draw_polygon(screen, color, polygon_vertex_indices, scaled_polygon_vertices, {}, None)
            else:
                pygame.draw.polygon(screen, color, scaled_polygon_vertices, 0)

        pygame.display.update()
        
        frame_nr += increment_frame_by
        
        if ALLOW_PAUSING_AND_REVERSE_PLAYBACK:
            if frame_nr > max_frame_nr:
                frame_nr = max_frame_nr
            if frame_nr < 1:
                frame_nr = 1
        else:
            if frame_nr > max_frame_nr:
                running = False
        

        #time.sleep(0.01)
   
        
    pygame.quit()


run()
