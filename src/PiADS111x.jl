# References:
# [1] ADS111x Ultra-Small, Low-Power, I2C-Compatible, 860-SPS, 16-Bit ADCs
#     SBAS444D –MAY 2009–REVISED JANUARY 2018

module PiADS111x

export ads_open



using PiGPIOC
import PiGPIOC.gpioInitialise
import PiGPIOC.i2cOpen
import PiGPIOC.i2cReadWordData
import PiGPIOC.i2cWriteWordData
# See http://abyz.me.uk/rpi/pigpio/cif.html


const ADS_CONVERSION_REGISTER = 0       # [1, 9.6.1, p27]
const ADS_CONFIG_REGISTER     = 1       # [1, 9.6.3, p28]
const ADS_CONFIG_DEFAULT      = 0x8583  # [1, 9.6.3, p28]
const ADS_OS                  = 0x8000  # [1, Table 8, p28]

struct ADS1115x <: AbstractChannel{UInt16}
    i2c::Cint
end

"""
    ads_open(;bus=1, address=0x480)::ADS1115x

Connect to ADS111x at `address` on i2c `bus`.
"""
function ads_open(;bus=1, address=0x48)

    @assert bus >= 0

    res = gpioInitialise()
    @assert(res != PiGPIOC.PI_INIT_FAILED)

    i2c = i2cOpen(bus, address, 0)
    @assert i2c >= 0

    ADS1115x(i2c)
end


"""
    getindex(::ADS1115x, i)

Run single Analog to Digital Conversion for pin `i` (0:3)
"""
function Base.getindex(ads::ADS1115x, i)

    @assert i in 0:3 "ADS1115x input `i` must be in range 0:3"
    @assert !ads_is_busy(ads)

    ads_write(ads, ADS_CONFIG_REGISTER,
                   ADS_CONFIG_DEFAULT | 
                   UInt16(0x4000 | (i << 12))) # [1, Table 8, p28]

    sleep(1/128) # 128 SPS [1, Table 8, p28]
    while ads_is_busy(ads)
        yield()
    end

    n = ads_read(ads)
    V = (n * 63.5) / 1000000 # [1, Table 3, p17]
end


"""
    ads_write(::ADS1115x, register, value)

Write 16-bit `value` to `register` on ADS111x ADC.
"""
function ads_write(ads, register, v)
    @assert register in 0:3
    err = i2cWriteWordData(ads.i2c, register, bswap(UInt16(v)))
    @assert err == 0
    nothing
end


"""
    ads_read(::ADS1115x, register=ADS_CONVERSION_REGISTER))

Read 16-bit value from `register` on ADS111x ADC.
"""
function ads_read(ads, register=ADS_CONVERSION_REGISTER)
    @assert register in 0:3
    n = i2cReadWordData(ads.i2c, register)
    @assert n >= 0
    bswap(UInt16(n))
end


"""
    ads_is_busy(::ADS1115x)

Is the ADS111x ADC currently performing a conversion?
"""
ads_is_busy(ads) = (ads_read(ads, ADS_CONFIG_REGISTER) & ADS_OS) == 0


function ads_demo()
    ads = ads_open()
    while true
        @show [ads[n] for n in 0:3]
    end
end


end # module

