import smbus
import sys

# usage, pass the i2c bus as the first argument, e.g. python3 serial_number 0

i2c_ch = int(sys.argv[1]) 

# address on the I2C bus
i2c_address = 0x58

# Register address
serial_num = 0x80

# Read serial number register
def read_serial():

    # Read the serial register, a 16 byte block
    val = bus.read_i2c_block_data(i2c_address, serial_num, 16)    
    return val

# Initialize I2C (SMBus)
bus = smbus.SMBus(i2c_ch)

try:
    # Print out the serial number
    print(bytes(read_serial()).hex())

except:
    pass
    
