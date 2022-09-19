def read_frame(sf_bytes, current_byte_index):

    frame_flags = sf_bytes[current_byte_index]
    current_byte_index += 1
    
    contains_palette = frame_flags & 2
    is_indexed_frame = frame_flags & 4

    # print("contains_palette: " + str(contains_palette))
    # print("is_indexed_frame: " + str(is_indexed_frame))
    
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
    
    if is_indexed_frame:
        nr_of_indexed_verices = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        current_byte_index += nr_of_indexed_verices * 2
        
        # Now reading the polygons
        
        color_and_nr_of_polygons = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        while (color_and_nr_of_polygons != 255 and color_and_nr_of_polygons != 254 and color_and_nr_of_polygons != 253):
            nr_of_polygons = color_and_nr_of_polygons & 15
            current_byte_index += nr_of_polygons # one vertex-index per polygon
            
            color_and_nr_of_polygons = sf_bytes[current_byte_index]
            current_byte_index += 1
            
        return current_byte_index, color_and_nr_of_polygons
        
    else:
        
        # Now reading the polygons
        
        color_and_nr_of_polygons = sf_bytes[current_byte_index]
        current_byte_index += 1
        
        while (color_and_nr_of_polygons != 255 and color_and_nr_of_polygons != 254 and color_and_nr_of_polygons != 253):
            nr_of_polygons = color_and_nr_of_polygons & 15
            current_byte_index += nr_of_polygons * 2 # x and y per polygon
            
            color_and_nr_of_polygons = sf_bytes[current_byte_index]
            current_byte_index += 1
            
        return current_byte_index, color_and_nr_of_polygons

#    return current_byte_index
    

def split_audio_file():
    sf = open("audio.raw", "rb")
    
    byte = True
    sf_bytes = bytearray()
    while byte:
        byte = sf.read(1)
        sf_bytes += byte
    
    file_number = 0  # we start at file number 0
    desired_file_size = 2 * 1024  # 8 * 1024
    current_byte_index = 0
    end_byte_index = current_byte_index + desired_file_size
    
    current_output_data = bytearray()
    done_with_8k_files = False
    while(len(sf_bytes) > end_byte_index):
        current_output_data = sf_bytes[current_byte_index:end_byte_index]
        
        # print ("file_number: " + str(file_number))
        #print (current_output_data.hex(' '))
        output_file = open("AUDIO/" + '{:03X}'.format(file_number) +  ".BIN", "wb")
        output_file.write(bytes(2) + current_output_data) # TODO: we add two bytes because the LOAD syscall in the x16 cuts them off
        output_file.close()
        
        file_number += 1
        current_byte_index += desired_file_size
        end_byte_index += desired_file_size
        
    # FIXME: 
    # Storing the left-over part
    current_output_data = sf_bytes[current_byte_index:]
    # print ("file_number: " + str(file_number))
    # print (current_output_data.hex(' '))
    output_file = open("AUDIO/" + '{:03X}'.format(file_number) +  ".BIN", "wb")
    output_file.write(bytes(2) + current_output_data) # TODO: we add two bytes because the LOAD syscall in the x16 cuts them off
    output_file.close()
    
    # Creating a "volume-file" for a certain frame-segment (use to move 2 sprites on the volume of the music)
    
    from_frame = 676
    to_frame = 1800 # TODO: maybe a little less
    
    volume_output_data = []
    current_frame = from_frame
    while current_frame <= to_frame:
        start_sample_index = int(current_frame * 24414 / 60)
        end_sample_index = int((current_frame+1) * 24414 / 60)
        sample_index = start_sample_index
        frame_volume = 0
        while sample_index < end_sample_index:
            sample_volume = sf_bytes[sample_index]
            if sample_volume > 128:
                sample_volume = 256 - sample_volume  # We are dealing with signed bytes, so we take that into account
            frame_volume += sample_volume
            sample_index += 1
        frame_volume = frame_volume // ((end_sample_index - start_sample_index) - 1)
        frame_volume = (frame_volume // 6) - 1
        if frame_volume < 2:
            frame_volume = 0
        volume_output_data.append(frame_volume)
    
        current_frame += 1
    # print(volume_output_data)
    
    output_file = open("INTRO/VOLUME.BIN", "wb")
    output_file.write(bytes(2) + bytearray(volume_output_data)) # TODO: we add two bytes because the LOAD syscall in the x16 cuts them off
    output_file.close()       
        
    
def split_scene_file():
    sf = open("scene1.bin", "rb")

    byte = True
    sf_bytes = bytearray()
    while byte:
        byte = sf.read(1)
        sf_bytes += byte
        
    frame_index = 0
    current_byte_index = 0
    
    mask_byte = 0
    current_output_data = bytearray()
    file_number = 1  # we start at file number 1, since the X16 starts with ram bank number 1 (bank 0 is used by kernal)
    while (mask_byte != 253):
        
        # print("Start of frame " + str(frame_index))
        end_byte_index, mask_byte = read_frame(sf_bytes, current_byte_index);
        # print("start_byte_index: " + str(current_byte_index))
        # print("end_byte_index: " + str(end_byte_index))
        # print("mask_byte: " + str(mask_byte))
        
        # we ignore the old block markers and create our own (at 8kb instead of 64kb)
        if mask_byte == 254:
            # TODO: we now do -1 here, is there a nicer way?
            sf_bytes[end_byte_index-1] = 255
        
        # print(sf_bytes[current_byte_index:end_byte_index].hex(' '))

        if ((len(current_output_data) + (end_byte_index - current_byte_index)) <= 8 * 1024):
            current_output_data += sf_bytes[current_byte_index:end_byte_index]
        else:
            # We create a new block marker at the end of this 8kb block
            current_output_data[-1] = 254
            # print ("file_number: " + str(file_number))
            #print (current_output_data.hex(' '))
            output_file = open("SCENE/" + '{:02X}'.format(file_number) +  ".BIN", "wb")
            output_file.write(bytes(2) + current_output_data) # TODO: we add two bytes because the LOAD syscall in the x16 cuts them off
            output_file.close()
            file_number += 1
            # print (current_output_data.hex(' '))
            current_output_data = sf_bytes[current_byte_index:end_byte_index]
            
        if mask_byte == 254:
            # When we are at the original block marker (64kb blocks) we have to skip to the beginning of the next 64kb block
            current_byte_index = ((end_byte_index // 65536) + 1) * 65536 # start of new 64kb block
        else:
            current_byte_index = end_byte_index
        frame_index += 1

    # Storing the left-over part
    output_file = open("SCENE/" + '{:02X}'.format(file_number) +  ".BIN", "wb")
    output_file.write(bytes(2) + current_output_data) # TODO: we add two bytes because the LOAD syscall in the x16 cuts them off
    output_file.close()

split_audio_file()
split_scene_file()

