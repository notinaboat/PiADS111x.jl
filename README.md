# PiADXL345.jl

Julia interface for the [ADS1115](https://www.ti.com/product/ADS1115)
ADC on Raspberry Pi.

In the example below the ADS1115 is connected to the Raspberry Pi's GPIO header
as follows: SDA = GPIO2, SCL = GPIO3.

```julia
julia> using PiADS111x

julia> ads = ads_open(;bus=1, address=0x48)
PiADS111x.ADS1115x(0)

julia> ads[0]
2.0807045

julia> for i in 0:3 println("Pin AIN", i, ": ", ads[i], "V") ; end
Pin AIN0: 2.0807045V
Pin AIN1: 1.65989V
Pin AIN2: 0.2891155V
Pin AIN3: 0.2888615V

julia> versioninfo()

Julia Version 1.5.2
Commit 539f3ce* (2020-09-23 23:17 UTC)
Platform Info:
  OS: Linux (arm-linux-gnueabihf)
  CPU: ARMv6-compatible processor rev 7 (v6l)
  WORD_SIZE: 32
  LIBM: libm
  LLVM: libLLVM-9.0.1 (ORCJIT, arm1176jz-s)
```

![ADS1115 Module](https://i.ebayimg.com/images/g/01YAAOSwu1VW5BXc/s-l1600.jpg)
