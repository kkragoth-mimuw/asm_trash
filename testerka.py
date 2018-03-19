sequence = [1, 2, 0, 2, 1, 0]
newFile = open("test_asm.in", "wb")
bytesFileArray  = bytearray(sequence)
newFile.write(bytesFileArray)
