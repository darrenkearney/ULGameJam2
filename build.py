"""
    Usage: Run this (quick and dirty) file with python3 to compile the src carts to the build cart.
    Project: UL Gamejam 2 - Simplicity - Game
    Description: Pico-8 file merger for our gamejam team.
    Author: Darren Kearney
    Author URI: https://darrenk.net
"""
def main():

    includes = get_includes()
    chunks = get_chunks_from_includes( includes )
    output = prepare_output( chunks )
    write_output_to_file( output, 'bin/jamthegame.p8' )

def write_output_to_file( output, filepath = 'bin/build.p8' ):
    # Write output to file
    with open( filepath , 'w' ) as build:
        build.write( output )

    print("Done.")


def get_includes():
    print("Reading includes file")
    with open('includes', 'r') as f:
        read_data = f.read()

    includes = {}

    for i in read_data.split():
        k=i.split('=')[0]
        v=i.split('=')[1]
        includes[k] = v

    return includes


def get_chunks_from_includes( includes = {} ):
    chunks = {
        '__pre__': '',
        '__gfx__': '',
        '__gff__': '',
        '__lua__': '',
        '__map__': '',
        '__sfx__': '',
        '__music__': ''
    }

    # Go into each include file
    for filepath in includes.values():
        print(" + {}".format( filepath ))

        if filepath == includes['__pre__']: 
            # Read peamble
            with open(filepath, 'r') as p:
                preamble_data = p.read()
            chunks['__pre__'] = "{}".format(preamble_data)

        if filepath == includes['__lua__']:
            chunks['__lua__'] = pico8_get_chunk_from_file( "__lua__", filepath ) 

        if filepath == includes['__gfx__']:
            chunks['__gfx__'] = pico8_get_chunk_from_file( "__gfx__", filepath )
            chunks['__gff__'] = pico8_get_chunk_from_file( "__gff__", filepath )
            chunks['__map__'] = pico8_get_chunk_from_file( "__map__", filepath )
     
        if filepath == includes['__sfx__']:
            chunks['__sfx__'] = pico8_get_chunk_from_file( "__sfx__", filepath )
            chunks['__music__'] = pico8_get_chunk_from_file( "__music__", filepath )

    return chunks


def prepare_output(chunks):
    output = ""
    
    def stitch_chunks(output, label):
        return output + "\n{}\n{}".format(label, chunks[label])
    
    output += chunks['__pre__']                  #  Preamble / file header
    output = stitch_chunks(output, '__lua__')    #  Lua code
    output = stitch_chunks(output, '__gfx__')    #  Sprites
    output = stitch_chunks(output, '__gff__')    #
    output = stitch_chunks(output, '__map__')    #  Map data
    output = stitch_chunks(output, '__sfx__')    #  Audio data
    output = stitch_chunks(output, '__music__')  #  Music data
    
    return output




def pico8_get_chunk_from_file( label, filepath ):
    
    # Vars
    chunk = ""
    is_in_chunk = False

    # Open target file for reading
    with open( filepath, 'r' ) as h:
        haystack = h.readlines()

    # Detect chunk by label and append lines to output variable
    for line in haystack:
        if line == label or line[:-1:] == label:
            is_in_chunk = True
            print("    + Found chunk '{}'".format(label))
            continue

        if is_in_chunk:
            
            # Detect out of chunk
            if line[0:2] == "__" and line[-3:-1] == "__":
                is_in_chunk = False
                print("      Detected chunk '{}', Leaving '{}'".format(line[:-1],label))
                break

            chunk += "{}".format(line)

    if chunk == "":
        print("    - No chunk found for '{}' in '{}'".format(label, filepath))

    return chunk

main()
