#! /usr/bin/env python3

import sys



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
    for index, d in enumerate( data):
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
    chunk = file.read( 8192)
    if not chunk:
        break
    l = len( chunk)
    if( l < 8192):
        chunk += (bytes.fromhex('ff') * (8192-l))
    print( "chunk #%02d:  sum: %04X  crc: %04X" % ( chunk_nr, calc_sum( chunk), calc_crc( chunk)))
    chunk_nr += 1

file.seek( 0)
data = file.read()
print( "all:  sum: %04X  crc: %04X" % ( calc_sum( data), calc_crc( data)))
file.close()

#for part in range( 16):
#    print( "part #%02d:  sum: %04X  crc: %04X" % ( part, calc_sum( data[0:8192*(part+1)]), calc_crc( data[0:8192*(part+1)])))

