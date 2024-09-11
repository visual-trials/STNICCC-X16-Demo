import os

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
    if is_indexed_frame:
        nr_of_indexed_verices = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        current_byte_index += nr_of_indexed_verices * 2
        
        # Now reading the polygons
        
        color_and_nr_of_vertices = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        while (color_and_nr_of_vertices != 255 and color_and_nr_of_vertices != 254 and color_and_nr_of_vertices != 253):
            nr_of_vertices = color_and_nr_of_vertices & 15
            current_byte_index += nr_of_vertices # one vertex-index per vertex
            
            color_and_nr_of_vertices = sf_bytes[current_byte_index]
            current_byte_index += 1
            
    else:
        
        # Now reading the polygons
        
        color_and_nr_of_vertices = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        while (color_and_nr_of_vertices != 255 and color_and_nr_of_vertices != 254 and color_and_nr_of_vertices != 253):
            nr_of_vertices = color_and_nr_of_vertices & 15
            current_byte_index += nr_of_vertices * 2 # x and y per vertex
            
            color_and_nr_of_vertices = sf_bytes[current_byte_index]
            current_byte_index += 1
            
    print('{0:4.0f} '.format(frame_index)+ clear_screen_str + contains_palette_str + is_indexed_frame_str + " : "+str(nr_of_vertices))
    
    return current_byte_index, color_and_nr_of_vertices
    
def parse_scene_file():
    sf = open("scene1.bin", "rb")

    byte = True
    sf_bytes = bytearray()
    while byte:
        byte = sf.read(1)
        sf_bytes += byte
        
    frame_index = 0
    current_byte_index = 0
    
    mask_byte = 0
    while (mask_byte != 253):
        
        #print("Start of frame " + str(frame_index))
        end_byte_index, mask_byte = read_frame(frame_index, sf_bytes, current_byte_index);
        
        if mask_byte == 254:
            # When we are at the original block marker (64kb blocks) we have to skip to the beginning of the next 64kb block
            current_byte_index = ((end_byte_index // 65536) + 1) * 65536 # start of new 64kb block
        else:
            current_byte_index = end_byte_index
        frame_index += 1

    print(frame_index)

parse_scene_file()