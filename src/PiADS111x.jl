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


const ADS_CONVERSION_REGISTER = 0                       # [1, 9.6.1, p27]
const ADS_CONFIG_REGISTER     = 1                       # [1, 9.6.3, p28]
const ADS_CONFIG_DEFAULT      = 0x8583                  # [1, 9.6.3, p28]
const ADS_PGA_4V096           = 0x0001 <<  9            # [1, Table 8, p28]
const ADS_OS                  = 0x0000 << 15            # [1, Table 8, p28]
const ADS_COMP_QUE_DISABLE    = 0x0003 <<  0            # [1, Table 8, p28]


struct ADS1115 <: AbstractChannel{UInt16}
    i2c::Cint
end

"""
    ads_open(;bus=1, address=0x480)::ADS1115

Connect to ADS1115 at `address` on i2c `bus`.
"""
function ads_open(;bus=1, address=0x48)

    @assert bus >= 0

    res = gpioInitialise()
    @assert(res != PiGPIOC.PI_INIT_FAILED)

    i2c = i2cOpen(bus, address, 0)
    @assert i2c >= 0

    ads = ADS1115(i2c)
    ads_config(ads)
    ads
end


"""
    ads_config(::ADS1115 , [mux = 0])

Configure using `mux` bits. See MUX in [1, Table 8, p28].
"""
function ads_config(ads::ADS1115, mux=UInt16(0))
    conf = ADS_OS |
           ADS_PGA_4V096 |
           ADS_COMP_QUE_DISABLE |
           mux
    ads_write(ads, ADS_CONFIG_REGISTER, conf)
    x = ads_read(ads, ADS_CONFIG_REGISTER)
    @assert x == conf
    nothing
end


"""
    getindex(::ADS1115, i)

Run single Analog to Digital Conversion for pin `i` (0:3)
"""
function Base.getindex(ads::ADS1115, i)

    @assert i in 0:3 "ADS1115 input `i` must be in range 0:3"
    mux = UInt16(0x4000 | (i << 12)) # [1, Table 8, p28]
    ads_config(ads, mux)
    sleep(1/8) # 8 SPS [1, Table 8, p28]
    while ads_is_busy(ads)
        yield()
    end
    ads[]
end


"""
    getindex(::ADS1115)

Read latest value from ADS_CONVERSION_REGISTER.
"""
function Base.getindex(ads::ADS1115)
    n = signed(ads_read(ads, ADS_CONVERSION_REGISTER))
    V = (n * 125) / 1000000 # [1, Table 3, p17]
end


"""
    ads_write(::ADS1115, register, value)

Write 16-bit `value` to `register` on ADS1115 ADC.
"""
function ads_write(ads, register, v)
    @assert register in 0:3
    err = i2cWriteWordData(ads.i2c, register, bswap(UInt16(v)))
    @assert err == 0
    nothing
end


"""
    ads_read(::ADS1115, register))

Read 16-bit value from `register` on ADS1115 ADC.
"""
function ads_read(ads, register)
    @assert register in 0:3
    n = i2cReadWordData(ads.i2c, register)
    @assert n >= 0
    bswap(UInt16(n))
end


"""
    ads_is_busy(::ADS1115)

Is the ADS1115 ADC currently performing a conversion?
"""
ads_is_busy(ads) = (ads_read(ads, ADS_CONFIG_REGISTER) & ADS_OS) == 0


function ads_demo()
    ads = ads_open()
    while true
        @show [ads[n] for n in 0:3]
    end
end


end # module

