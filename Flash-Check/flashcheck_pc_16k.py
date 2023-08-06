#! /usr/bin/env python3

import sys

SLICE_SIZE = 16384


def bytes_from_file( filename, chunksize = 8192):
    with open( filename, "rb") as f:
        while True:
            chunk = f.read( chunksize)
            if chunk:
                for b in chunk:
                    yield b
            else:
                break


def ror(n, rotations, width = 8):
    return (2**width-1)&(n>>rotations|n<<(width-rotations))

def calc_sum( data):
    sum = 0
    for d in data:
        sum += int( d)
    sum %= 65536
    return sum


def calc_crc( data):
    d = 0xff
    e = 0xff
    for by in data:
        a = d = d ^ by  # xor
        a = ror( a, 4) & 0x0F
        a = d = d ^ a

        a = ror( a, 3)
        e = (a & 0x1f) ^ e
        e = ror( a, 1) & 0xf0 ^ e

        a = a & 0xe0
        a = a ^ d
        d = e
        e = a
        #print( "%02X %02X" % ( d, e))

    return (d << 8) + e


filename = sys.argv[ 1]

chunk_nr = 0
file = open( filename, "rb")
while True:

    chunk = file.read( SLICE_SIZE)
    if not chunk:
        break
    
    # letzten Block ggf. mit 0xFF auffüllen
    l = len( chunk)
    if( l < SLICE_SIZE):
        chunk += (bytes.fromhex('ff') * (SLICE_SIZE-l))

    chunk_sum = calc_sum( chunk)
    chunk_crc = calc_crc( chunk)

    print( "chunk #%02d:  sum: %04X  crc: %04X" % ( chunk_nr, chunk_sum, chunk_crc))
    chunk_nr += 1

# zurück auf 'Los!'
file.seek( 0)
data = file.read()
print( "all:\nsum: %04X\ncrc: %04X" % ( calc_sum( data), calc_crc( data)))
file.close()

