dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_SAM.lua')
dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_Airplane.lua')
dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_Ship.lua')
dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_Missile.lua')

copy_recursive = function(child, parent)
    local k,v
    for k,v in pairs(parent) do
        if type(v)=="table" then
            if not child[k] then child[k]={} end
            copy_recursive(child[k], parent[k])
        else
            child[k] = parent[k]
        end
    end
end

DefaultType          = 100
DEFAULT_TYPE_ = {DefaultType, DefaultType, DefaultType, DefaultType}

RWREmitterMode = {
    NULL = 0,
    Scan = 1,
    TWS = 2,
    Lock = 3,
    CR = 4,
    M1 = tonumber('001000',2),
    M2 = tonumber('010000',2),
    M3 = tonumber('011000',2),
    M4 = tonumber('100000',2),
    M5 = tonumber('101000',2),
    M6 = tonumber('110000',2),
    M7 = tonumber('111000',2),
    CWillum = tonumber('1000000',2),
}

RWRPatternType = {
    SincPattern = 1,
    AiryPattern = 2,
    SincWeighed = 3,
    AiryWeighed = 4,
    CosecantSquared = 5
}

RWRScanPatternType = {
    raster = 1,
    circular = 2,
    spiral = 3,
    --_3d = 2,
    --cscsq = 3,
    ESA = 4,
    Bore = 5,
    Conical = 6,
    Cue = 7,
    Acquisition = 8,
    NoScan = 9,
    AcquisitionCross = 10,
}

RWRFreqAgility = {
    Const = 1,
    Stagger = 2,
    Smooth = 3,
    Random = 4
}

RWR_templates = {}

RWR_templates.fighter_gen_1 = { --AN/APG-30
    freq={9.335,9.415},
    prf = {600},
    pulse_width = {0.55,0.3},
    P_max = 5,
    G = 21,
    ftbr = 24,
    hpbw = 18,
    antenna_pattern_type = RWRPatternType.AiryPattern,
    freq_agility = RWRFreqAgility.Const,
    scan_pattern_type = RWRScanPatternType.Bore,
    always_emulate_scan_pattern = true,
}

RWR_templates.fighter_gen_2 = { --RP-22SMA
    freq = {12.75,13.05},
    prf = {1593.75,1789.47},
    pluse_width = {0.7},
    P_max = 220,
    scan_azimuth_volume = 56,
    scan_elevation_volume = 20,
    gimbal_limit = 30,
    elevation = 7,
    hpbw = 2.8,
    G = 33.42,  --x2200
    ftbr = 36,
    antenna_pattern_type = RWRPatternType.AiryPattern,
    freq_agility = RWRFreqAgility.Const,
    scan_pattern_type = RWRScanPatternType.raster,
    scan_pattern = 10,
    scan_rate = 187,
    prf_agility = RWRFreqAgility.Const,
    always_emulate_scan_pattern = true,
    always_center_pattern = true,
    emulate_if_human = true,        --special setting for radars which don't transmit realistically even with full simulation
}

RWR_templates.fighter_gen_3 = {--AN/APG-120
    freq = {9.4,9.47},                              --GHz
    G = 35,                                         --dBi
    side_lobe_level = 23,                           --dB, only used by weighed patterns
    ftbr = 25,                                      --dB, front to back ratio for main and back lobes
    antenna_pattern_type = RWRPatternType.AiryWeighed, --antenna power directiviyy pattern type, defaults to 0 (standard sinc^2) if side_lobe_level is NOT present or SincWeighed (sinc^2 with arbitrary side lobe level) otherwise
    hpbw = 3.7,                                     --deg
    hpbw_vert = 3.7,
    full_power_vert = 3.,                           --full power area in the middle before the pattern starts, used to simulate fast beam movement that would otherwise be aliased away like nutation or electronic scanning (simulating Palmer scan here)
    scan_rate = 120,                                --deg/s
    P_max = 165,                                    --kW (peak power)
    scan_pattern_type = RWRScanPatternType.raster,   --scan pattern type, defaults to raster
    scan_pattern = 2,                               --"bars" in scan pattern, integer, 0 means stationary beam (range search only, beam fixed to boresight, e.g. F-86), 1 is default for ground objects, 4 for aircraft
    scan_azimuth_volume = 120,                       --angle (total) in degrees, covered horizontally by the scan pattern, only used for emulated mode. Defaults to 60 for aircraft, 360 for ground
    scan_elevation_volume = 3.7,
    always_emulate_scan_pattern = false,            --defaults to false, ignore RWR events and from the moment first event arrives only reference the emulated scan pattern.
    emulate_if_human = false,

    -- conditions for "deduced modes", those are a placeholder for data that should arrive through the messaging system, as they REALLY SHOULDN'T BE "ASSUMED" FOR HUMAN CONTROLLED AIRCRAFT
    -- possible conditions:
        -- default - if set to true, this will be used by default when other modes don't meet conditions, all conditions used here will be ignored
        -- interleve - will replace default every other RWR event or scan line, as long as all conditions are met
        -- loadout - carried missile names or wsTypes that trigger this mode
        -- missile - launched missile names or wsTypes that trigger this mode
        -- range_lt - range less than, m
        -- range_gt - range greater than, m
        -- azimuth_lt - less than angle off-boresight in degrees
        -- azimuth_gt - greater than angle off-boresight in degrees
        -- elevation_lt - relative elevation less than
        -- elevation_gt - relative elevation greater than
        -- modes - specific standard modes that use this mode
    
    modes = {
        [RWREmitterMode.M1] = {
            conditions = {
                range_gt = 50000,
                modes = {RWREmitterMode.Scan}
            },
            prf = {370},    --Hz
            pulse_width = {2.0}      --microseconds, if not listed it's assumed to be 2us. DISCREET - the brackets don't contain a range but discreet pulse width options
            
        },
        [RWREmitterMode.M2] = {
            conditions = {
                default = true
            },
            prf = {1060},
            pulse_width = {0.4},
        },
        [RWREmitterMode.CWillum] = {
            conditions = {
                missile = {
                    "weapons.missiles.AIM-7E",
                    "weapons.missiles.AIM-7F",
                }
            },
            --CW is enabled _alongside_ the main pulse mode, unless pulse mode is set up as CW by default (main prf set to -1) - in that case this doesn't need to be used, see Hawk
            prf = {-1},
            P_max = 70
        }
    }
}

RWR_templates.fighter_gen_4 = --AN/APG-68
{
    freq = {9.695,9.905},
    prf = {28000,32000}, --MPRF, assumed
    pulse_width = {1},
    G = 34,
    scan_rate = 65,
    hpbw = 3.3,
    hpbw_vert = 4.6,
    P_max = 17.5,

    scan_pattern = 4,
    scan_azimuth_volume = 120,
    scan_pattern_type = RWRScanPatternType.raster,
    antenna_pattern_type = RWRPatternType.SincWeighed,
    side_lobe_level = 30,
    ftbr = 30,
    freq_agility = RWRFreqAgility.Const,
    prf_agility = RWRFreqAgility.Const,
    always_emulate_scan_pattern = true,
    always_center_pattern = true,
    do_not_center_elevation = true,

    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.TWS] = {
            always_center_pattern = false,
            scan_azimuth_volume = 60,
        },
        [RWREmitterMode.Lock] = {},
        [RWREmitterMode.CR] = {},
        [RWREmitterMode.M1] = {
            conditions = {
                modes = {
                    RWREmitterMode.Scan,
                },
                interleved = true,
                azimuth_lt = 30,
                range_gt = 60000,
            },
            prf = {300000,310000},
            pulse_width = {1.4},
            P_max = 1.75,
        }
    }
}

RWR_templates.AAA = {   --AN/VPS-2
    freq = {9.225, 9.225},
    G = 33,
    P_max = 1.4,
    scan_pattern_type = RWRScanPatternType.NoScan,
    antenna_pattern_type = RWRPatternType.AiryWeighed,
    hpbw = 4.1,
    hpbw_vert = 4.3,
    side_lobe_level = 24,
    ftbr = 25,
    --MIL-B-50653
    prf = {19000,21000},
    pulse_width = {1.4}
}

RWR_templates.SHORAD = {    --Tor
    params = {         --scan
        freq = {3.0, 4.0},
        prf = {6000},       --almost certainly wrong, based on unambiguous range to 25km
        pulse_width = {20},  --around 12% duty cycle - high duty cycle MPRF (i.e. quasi-continuous)
        P_max = 12.5/3., --1.5kW average
        G = 35,
        hpbw = 1.5,
        hpbw_vert = 4,
        full_power_vert = 8,   --stacked beam 3x4
        scan_rate = 360,
        scan_pattern = 6,       --one scan in upper and one in lower sector
        scan_pattern_type = RWRScanPatternType.spiral,
        scan_elevation_volume = 60, --64 total, 2x32 sectors
        elevation = 6,
        scan_azimuth_volume = 360,
        antenna_pattern_type = RWRPatternType.SincWeighed,
        side_lobe_level = 31,
        ftbr = 30,
        always_scan = true,
        always_emulate_scan_pattern = true,
        always_center_pattern = true,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {},
        }
    },
    params1 = { --track radar
        freq = {4.0,8.0},
        prf = {6000},
        pulse_width = {20},
        P_max = 5,  --0.6kW average
        G = 43,
        hpbw = 1,
        antenna_pattern_type = RWRPatternType.SincWeighed,
        scan_pattern_type = RWRScanPatternType.NoScan,
        ftbr = 40,
        side_lobe_level = 35,

        modes = {
            [RWREmitterMode.Lock] = {},
            [RWREmitterMode.CR] = {}
        }
    }
}

RWR_templates.LORAD_SR = {  --64N6E S-300 RLO
    freq = {2.9, 3.3},
    prf = {28000},
    pulse_width = {10},
    P_max = 100,
    G = 44,
    hpbw = 1.3,
    full_power_vert = 14,   --AESA vertical scan, mechanical horizontal (anti-fighter mode, we're not interested in anti-balistic here)
    elevation = 8,
    antenna_pattern_type = RWRPatternType.SincWeighed,
    ftbr = 0, --backscan
    side_lobe_level = 40,
    scan_pattern_type = RWRScanPatternType.circular,
    scan_rate = 30,
    always_emulate_scan_pattern = true,

}

RWR_templates.LORAD_TR = {  --5N63 S-300 RPN
    freq = {8,20},
    prf = {27000,29000},
    pulse_width = {10},
    P_max = 80,
    G = 46,
    hpbw = 1,
    prf_agility = RWRFreqAgility.Random,
    prf_agility_interval = 0.000035714,  --staggered with multiple prfs
    antenna_pattern_type = RWRPatternType.SincWeighed,
    ftbr = 40,
    side_lobe_level = 40,
    scan_pattern_type = RWRPatternType.ESA,
    scan_cycle = 1,
    scan_period = 3,
    scan_only = true,   --TVM
    always_emulate_scan_pattern = true,
    always_center_pattern = false,
    always_scan = true,
    scan_elevation_volume = 50,
    scan_azimuth_volume = 50,
    elevation = 25,

    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.TWS] = {},
        [RWREmitterMode.Lock] = {},
        [RWREmitterMode.CR] = {}
    }
}

RWR_templates.LORAD_HOR = { --5N66M S-300 NVO
    freq = {2.9, 3.3},
    prf = {-1},  --CW
    G = 38,
    P_max = 1.4,
    hpbw = 6,
    hpbw_vert = 1,
    elevation = 0,
    side_lobe_level = 30,
    ftbr = 30,
    antenna_pattern_type = RWRPatternType.SincWeighed,
    scan_pattern_type = RWRPatternType.circular,
    scan_rate = 120,
}

RWR_templates.EWR = {   --AN/FPS-117
    freq = {1.215,1.4},
    prf = {250},
    pulse_width = {100,800},
    P_max = 20,
    prf_agility = RWRFreqAgility.Stagger,
    prf_agility_interval = 0.000004,
    antenna_pattern_type = RWRPatternType.SincWeighed,
    G = 37,
    hpbw = 3.4,
    hpbw_vert = 2.7,
    ftbr = 30,
    side_lobe_level = 30,
    full_power_vert = 26, --vertical ESA,
    elevation = 7,
    scan_pattern_type = RWRScanPatternType.circular,
    scan_rate = 36,
    always_emulate_scan_pattern = true,

    modes = {
        [RWREmitterMode.M1] = {
            concitions = {
                modes = {
                    RWREmitterMode.Scan
                },
                range_lt = 120000
            },
            prf = {1100},
            pulse_width = {100},
            prf_agility = RWRFreqAgility.Const
        }
    }
}


RWR_helpers = {}

RWR_helpers.create_generic = function(base, efficiency, duty_cycle)
    local base = base or {}
    local ret = {}
    copy_recursive(ret,base)
    
    ret.freq = base.freq or {8,12}
    ret.hpbw = base.hpbw or 1
    ret.hpbw_vert = base.hpbw_vert or ret.hpbw
    ret.G = base.G or (10*math.log10(41253/(ret.hpbw*ret.hpbw_vert) * (efficiency or 0.5)))
    ret.prf = base.prf or {1000}
    ret.pulse_width = base.pulse_width
    if (ret.pulse_width == nil) then
        ret.pulse_width = {}
        local dc = duty_cycle or 0.1
        for i,v in ipairs(ret.prf) do
            table.insert(ret.pulse_width,dc/v*1000000)
        end
    end
    ret.P_max = base.P_max or 10
    if base.ftbr == nil then
        ret.ftbr = ret.G-5
    else
        ret.ftbr = base.ftbr
    end
    if base.ftbr == 0. and base.G == nil then
        ret.G = ret.G - 3
    end
    ret.antenna_pattern_type = base.antenna_pattern_type or RWRPatternType.SincWeighed
    ret.side_lobe_level = ret.G-3
    ret.scan_pattern_type = base.scan_pattern_type or RWRScanPatternType.raster
    ret.scan_pattern = base.scan_pattern or 4
    ret.scan_rate = base.scan_rate or 120
    ret.scan_azimuth_volume = base.scan_azimuth_volume
    if ret.scan_azimuth_volume == nil then
        if ret.scan_pattern_type == RWRScanPatternType.spiral or ret.scan_pattern_type == RWRScanPatternType.circular then
            ret.scan_azimuth_volume = 360
        else
            ret.scan_azimuth_volume = 120
        end
    end

    if ret.modes ~= nil and type(ret.modes) == "table" then
        for mode,tab in pairs(ret.modes) do
            if ret.modes[mode].prf ~= nil then
                ret.modes[mode].pulse_width = base.modes[mode].pulse_width or base.pulse_width
                if (ret.modes[mode].pulse_width == nil) then
                    ret.modes[mode].pulse_width = {}
                    local dc = duty_cycle or 0.1
                    for i,v in ipairs(ret.modes[mode].prf) do
                        table.insert(ret.modes[mode].pulse_width,dc/v*1000000)
                    end
                end
            end
        end
    end
    
    return ret
    
end

print("loading helper functions")

RWR_helpers.create_generic_cw = function(base, efficiency)
    local interm = {}
    local base = base or {}
    copy_recursive(interm,base)
    
    interm.prf = {-1}
    interm.pulse_width = {}
    
    return RWR_helpers.create_generic(interm,efficiency)
end
RWR_helpers.create_surveilence = function(base, efficiency, pulsed, duty_cycle)
    local base = base or {}
    local interm = {}
    copy_recursive(interm,base)

    interm.scan_pattern_type = base.scan_pattern_type or RWRScanPatternType.circular
    if base.elevation == nil then
        interm.elevation = base.hpbw_vert or base.hpbw or 1
        interm.elevation = base.full_power_vert or interm.elevation
        interm.elevation = interm.elevation/2.
    else
        interm.elevation = base.elevation
    end

    interm.modes = base.modes or {
        [RWREmitterMode.Scan] = {}
    }

    if base.always_emulate_scan_pattern == nil then
        interm.always_emulate_scan_pattern = true
    else
        interm.always_emulate_scan_pattern = base.always_emulate_scan_pattern
    end

    if base.always_center_pattern == nil then
        interm.always_center_pattern = true
    else
        interm.always_center_pattern = base.always_center_pattern
    end

    if pulsed or (base.prf and base.prf[1] > 0) then
        return RWR_helpers.create_generic(interm,efficiency,duty_cycle)
    else
        return RWR_helpers.create_generic_cw(interm,efficiency)
    end

end

RWR_helpers.create_tracking = function(base, efficiency, pulsed, duty_cycle)
    local base = base or {}
    local interm = {}
    copy_recursive(interm,base)

    interm.scan_pattern_type = base.scan_pattern_type or RWRScanPatternType.NoScan
    interm.scan_azimuth_volume = base.scan_azimuth_volume or 360
    interm.scan_elevation_volume = base.scan_elevation_volume or 180
    interm.gimbal_limit = base.gimbal_limit or 181
    interm.gimbal_limit_vert = base.gimbal_limit_vert or 90

    interm.modes = base.modes or {
        [RWREmitterMode.Lock] = {},
        [RWREmitterMode.CR] = {}
    }

    if pulsed then
        return RWR_helpers.create_generic(interm,efficiency,duty_cycle)
    else
        return RWR_helpers.create_generic_cw(interm,efficiency)
    end

end

RWR_helpers.create_parabolic = function(base, efficiency, freq, diameter, pulsed, duty_cycle)
    local interm = {}
    local base = base or {}
    copy_recursive(interm,base)

    if freq == nil and base.freq ~= nil and type(base) == "table" then
        freq = (base[1]+base[2])/2.
    end

    local wavelength = 0.3/(freq or 10.)
    
    if base.G then
        interm.G = base.G
    elseif base.hpbw then
        interm.G = 10*math.log10((math.pi*70./base.hpbw)^2.*(efficiency or 0.55))
    else
        interm.G = 10*math.log10((math.pi*(diameter or 4.)/wavelength)^2.*(efficiency or 0.55))
    end

    if base.hpbw then
        interm.hpbw = base.hpbw
    elseif base.G then
        interm.hpbw = math.pi*70./math.sqrt(10.^(base.G/10.))*math.sqrt(efficiency or 0.55)
    else
        interm.hpbw = 70.*wavelength/(diameter or 4.)
    end

    interm.antenna_pattern_type = base.antenna_pattern_type or RWRPatternType.AiryPattern

    if pulsed then
        return RWR_helpers.create_generic(interm,efficiency,duty_cycle)
    else
        return RWR_helpers.create_generic_cw(interm,efficiency)
    end

end

print("loaded helper functions")

RWR_templates.AN_SPG_62 = RWR_helpers.create_parabolic({
    freq = {8,12},
    prf = {-1},
    P_max = 10,
    scan_pattern_type = RWRScanPatternType.NoScan,
    always_scan = false,
    always_emulate_scan_pattern = false,
    modes = {
        [RWREmitterMode.Lock] = {
            P_max = 0.001
        },
        [RWREmitterMode.CR] = {}
    }
},0.7,10,2.29)

RWR_templates.AN_SPY_1 = RWR_helpers.create_surveilence({
    freq = {3.1,3.5},
    prf = {196,1562},       --prf calculated from pulsewidth and known 1% duty cycle
    pulse_width = {6.4,12.8,25,51},          --there's probably more
    P_max = 6000/36,
    antenna_pattern_type = RWRPatternType.SincWeighed,
    G = 42,
    side_lobe_level = 45,
    hpbw = 1.7,
    scan_pattern_type = RWRScanPatternType.ESA,
    scan_period = 5,
    scan_cycle = 1,
    always_emulate_scan_pattern = true,
    always_center_pattern = false,
    scan_azimuth_volume = 10,   --single beam
    scan_elevation_volume = 90,
    gimbal_limit = 180,
    always_scan = true,
    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.TWS] = {},
        [RWREmitterMode.Lock] = {
            P_max = 4000,
        },
        [RWREmitterMode.CR] = {
            P_max = 4000,
        },
        [RWREmitterMode.CWillum] = {
            conditions = {
                modes = {
                    RWREmitterMode.CR
                },
            }
        }
    }
},0.7,true)

--We copy AN/SPG-62 over here as a CWillum channel
--This should allow for proper type P indication
copy_recursive(RWR_templates.AN_SPY_1.modes[RWREmitterMode.CWillum],RWR_templates.AN_SPG_62)
RWR_templates.AN_SPY_1.modes[RWREmitterMode.CWillum].modes = nil

RWR_templates.Don = RWR_helpers.create_generic({
    freq = {9.28,9.48},
    P_max = 80,
    prf = {756,876},
    pulse_width = {1.3,1.,0.7},
    hpbw = 1,
    hpbw_vert = 20,
    scan_rate = 120,
    scan_pattern_type = RWRScanPatternType.circular,
    always_emulate_scan_pattern = true,
    prf_agility = RWRFreqAgility.Random,
    prf_agility_interval = 10,

    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.M2] = {
            conditions = {
                modes = {RWREmitterMode.Scan},
                interleved = true,
            },
            prf = {1572,1656},
            pulse_width = {1.7,1.3,1.0,0.7,0.1}
        }
    }
})

RWR_templates.MR_302 = RWR_helpers.create_surveilence({
    freq = {3.825,3.98},
    P_max = 500,
    prf = {490,510},
    hpbw = 1.4,
    hpbw_vert = 5.7,
    scan_pattern_type = RWRScanPatternType.circular,
    scan_rate = 36,
    elevation = 0,
},0.5,true,0.02)

print("Loaded to Fregat")

RWR_templates.MR_320 = {}
copy_recursive(RWR_templates.MR_320,RWR_templates.MR_302)
RWR_templates.MR_320.ftbr = 0 --2 back to back antennas
print("Loaded Fregat")

RWR_templates.MR_300 = RWR_helpers.create_surveilence({
    freq = {1.0, 1.2},
    prf = {625,750},
    scan_rate = 72,
    P_max = 1000,
    hpbw = 1.2,
    hpbw_vert = 40,
    full_power_vert = 40,
    elevation = 0,
    ftbr = 0,
},0.5,true,0.02)

RWR_templates.Osa_M = {
    search = RWR_helpers.create_surveilence({
        freq = {6,8},
        prf = {2700,2900},
        hpbw = 1.4,
        hpbw_vert = 19,
        P_max = 250,
        freq_agility = RWRFreqAgility.Random,
        freq_agility_interval = 0.005,
        prf_agility = RWRFreqAgility.Random,
        prf_agility_interval = 0.005,
    },0.4,true,0.01),
    
    track = RWR_helpers.create_tracking({
        freq = {14.2,14.8},
        prf = {2700,2900},
        hpbw = 1,
        P_max = 180,
        freq_agility = RWRFreqAgility.Random,
        freq_agility_interval = 30,
        prf_agility = RWRFreqAgility.Random,
        prf_agility_interval = 30,
    },0.4,true,0.01)
}

--Fregat-MA, two antennas diametrally opposed
RWR_templates.MR_750 = {
    params = RWR_helpers.create_surveilence({
        freq = {2.0,3.0},
        prf = {500},
        scan_rate = 72,
        hpbw = 1.8,
        hpbw_vert = 2.4,
        full_power_vert = 50,
        P_max = 60,
        elevation = 25,
},0.6,true,0.002),
    params1 = RWR_helpers.create_surveilence({
        freq = {1.0,2.0},
        prf = {500},
        scan_rate = 72,
        hpbw = 2.9,
        hpbw_vert = 3.7,
        full_power_vert = 50,
        P_max = 60,
        elevation = 155,    --pointing backwards
},0.6,true,0.002)}

--Fregat, same deal
RWR_templates.MR_700 = {
    params = RWR_helpers.create_surveilence({
        freq = {2.25,2.5},
        prf = {500},
        scan_rate = 90,
        hpbw = 1.5,
        hpbw_vert = 40,
        elevation = 20,
        P_max = 300,
},0.5,true,0.002),
    params1 = RWR_helpers.create_surveilence({
        freq = {2.0,2.25},
        prf = {500},
        scan_rate = 90,
        hpbw = 1.5,
        hpbw_vert = 20,
        elevation = 170,    --pointing backwards
        P_max = 300,
},0.5,true,0.002)}

RWR_templates.MR_800 = {
    params = RWR_helpers.create_surveilence({
        --MR-600
        freq = {1,1.2},
        prf = {300},
        scan_rate = 36,
        hpbw = 2.3,
        hpbw_vert = 1.9,
        elevation = 20,
        full_power_vert = 40,
        P_max = 600,
},0.5,true,0.02),
    params1 = RWR_helpers.create_surveilence({
        --MR-500
        freq = {0.8,0.875},
        prf = {210,863},
        scan_rate = 36,
        hpbw = 3.4,
        hpbw_vert = 15,
        elevation = 180-7.5,
        P_max = 1000,
},0.5,true,0.02),
}

RWR_templates.MR_212 = RWR_helpers.create_surveilence({
    freq = {9.4,9.46},
    prf = {700},        --taken from MR-231 as similar params suspected
    pulse_width = {0.8}, --from radartutorial
    P_max = 20,          --can go as low as 12
    hpbw = 1.1,
    hpbw_vert = 5,       --estimated
    elevation = 0,
    scan_rate = 18,
},0.6,true)

RWR_templates.MR_231 = RWR_helpers.create_surveilence({
    freq = {9.38,9.44},
    prf = {1400},
    pulse_width = {0.35},
    P_max = 10,
    hpbw = 1.1,
    hpbw_vert = 5,
    elevation = 0,
    scan_rate = 90
},0.6,true)

RWR_templates.MR_352 = RWR_helpers.create_surveilence({
    --Positiv radar, most is guesswork
    freq = {8.0,12.0},
    prf = {9000},
    P_max = 45,       --from govt brochure
    hpbw = 1,         --guesswork
    full_power_vert = 40,    --from Friedman
    elevation = 20.,
    scan_pattern_type = RWRScanPatternType.circular,
    always_emulate_scan_pattern = true,
    scan_rate = 180,    --govt brochure
},0.6,0.01)

print("Loaded to MR-352")

--RWR_templates.MR_352_2 = {}--full Xband, for ships that don't have Vympel
--copy_recursive(RWR_templates.MR_352_2,RWR_templates.MR_352)
--RWR_templates.MR_352_2.freq = {8,12}
print("Loaded MR-352")

RWR_templates.MR_123 = RWR_helpers.create_generic({
    freq = {7.0,9.0},
    --data from Friedman
    P_max = 200,
    prf = {3600},
    pulse_width = {0.5},
    hpbw = 3.0,
    G = 30,
    scan_pattern_type = RWRScanPatternType.spiral,
    antenna_pattern_type = RWRPatternType.AiryPattern,
    always_emulate_scan_pattern = true,
    scan_rate = 90,
    elevation = 0,
    scan_elevation_volume = 36,
    scan_pattern = 10,

    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.TWS] = {},
        [RWREmitterMode.Lock] = {}
    }
})

print("loaded to Volna")

RWR_templates.Volna = RWR_helpers.create_generic(RWR_templates.LORAD_TR)
RWR_templates.Volna_2 = {}
copy_recursive(RWR_templates.Volna_2,RWR_templates.Volna)
RWR_templates.Volna.freq = {8.0,12.05}

RWR_templates.Phalanx = RWR_helpers.create_tracking({
    freq = {12,18},
    prf = {10000,20000},
    pulse_width = {2.0,1.4},
    P_max = 30,
    hpbw = 2,
},0.6,true)

--range limitted phalanx for workaround
RWR_templates.Phalanx_range_limit = {}
copy_recursive(RWR_templates.Phalanx_range_limit, RWR_templates.Phalanx)
RWR_templates.Phalanx_range_limit.scan_pattern_type = RWRScanPatternType.NoScan
RWR_templates.Phalanx_range_limit.scan_only = true
RWR_templates.Phalanx_range_limit.modes = {
    [RWREmitterMode.Scan] = {},
    [RWREmitterMode.Lock] = {},
    [RWREmitterMode.CR] = {},
    [RWREmitterMode.M1] = {
        conditions = {
            modes = {RWREmitterMode.Lock, RWREmitterMode.CR},
            range_lt = 5000
        },
        scan_only = false
    }
}

RWR_templates.AN_SPQ_9B = RWR_helpers.create_surveilence({
    freq = {8,10},
    prf = {3000},
    P_max = 1.2,
    hpbw = 1.4,
    hpbw_vert = 3.0,
    scan_rate = 180,
    ftbr = 0,
    full_power_vert = 25,
    elevation = -12.5
},0.6,true,0.02)

RWR_templates.Mark_23 = RWR_helpers.create_surveilence({
    freq = {1.215,1.4},
    prf = {4000},
    P_max = 200,
    scan_rate = 180,
    antenna_pattern_type = RWRPatternType.CosecantSquared,
    hpbw = 3.3,
    hpbw_vert = 75,
    elevation = 1.5    
},0.5,true,0.01)

RWR_templates.Mark_95 = RWR_helpers.create_tracking({
    freq = {8,12},
    P_max = 2,
    prf = {-1},
    hpbw = 2.4
},0.5,false)

RWR_templates.AN_SPS_48E = RWR_helpers.create_surveilence({
    freq = {2.9,3.1},
    prf = {330,2250},
    pulse_width = {27.,9.},
    P_max = 2200,
    scan_rate = 90,
    hpbw = 1.5,
    hpbw_vert = 1.6,
    full_power_vert = 65     --coverage of a single vertical electronically scanned sweep
},0.6,true)

RWR_templates.AN_SPS_48C = {}
copy_recursive(RWR_templates.AN_SPS_48C,RWR_templates.AN_SPS_48E)
RWR_templates.AN_SPS_48C.P_max = 1000

RWR_templates.AN_SPN_43 = RWR_helpers.create_surveilence({
    freq = {3.5, 3.7},
    prf = {1000},
    pulse_width = {0.95},
    P_max = 1000,
    G = 32,
    scan_rate = 90,
    hpbw = 1.75,
    elevation = 4.4,
    antenna_pattern_type = RWRPatternType.CosecantSquared,
    hpbw_vert = 30,
},0.5,true)

RWR_templates.  AN_SPS_10E = RWR_helpers.create_surveilence({
    freq = {5.5,5.825}, --5.45 actual, for separation
    prf = {625,650},
    pulse_width = {0.25},
    P_max = 500,
    hpbw = 1.9,
    hpbw_vert = 16,
    elevation = 0,
    scan_rate = 90,
},0.5,true)

RWR_templates.AN_SPS_502 = RWR_helpers.create_surveilence({
    --AN/SPS-10 antenna
    freq = {5.5, 5.825},   --5.45 actual, for separation
    prf = {2250},
    pulse_width = {0.12},
    P_max = 130,
    hpbw = 1.9,
    hpbw_vert = 16,
    elevation = 0,
    scan_rate = 96,
},0.5, true)

RWR_templates.AN_SPS_55 = RWR_helpers.create_surveilence({
    --version of AN/SPS-502 with its own antenna
    freq = {9.05, 10.},
    prf = {750},
    pulse_width = {1},
    P_max = 130,
    G = 31,
    hpbw = 1.4,
    hpbw_vert = 20,
    elevation = 0,
    scan_rate = 96,
    ftbr = 0.000000001,
})

RWR_templates.AN_SPS_67 = RWR_helpers.create_surveilence({
    freq = {5.45,5.825},
    prf = {750,1200},
    pulse_width = {1,0.25},
    P_max = 280,
    hpbw = 1.6,
    hpbw_vert = 12,
    elevation = 0,
    scan_rate = 12
},0.5,true)

RWR_templates.Type_965M = RWR_helpers.create_surveilence({
    freq = {0.216,0.224}, --this will sooner be detected by com/nav receivers, in fact it might be a good idea to implement sth like this
    prf = {200},    --or 400
    pulse_width = {10},     --or 3.8
    P_max = 450,
    scan_rate = 48,
    hpbw = 12,
    hpbw_vert = 30,
    elevation = 0,
},0.4,true)

RWR_templates.AN_SPG_35 = RWR_helpers.create_tracking({
    --AKA Type 903
    freq = {8.5,9.6},
    prf = {3000},
    pulse_width = {0.15,0.1},
    P_max = 50,
    hpbw = 2,
    G = 37.5
},0.5,true)

RWR_templates.Type_909 = RWR_helpers.create_tracking(RWR_helpers.create_parabolic({
    freq = {5.25,5.275}, --C-band, cross-referenced with freq allocation table (but it's maritime so this could be wrong)
    prf = {-1}, --CW
    P_max = 50,  --unknown
},0.55,5.25,2.44,false),0.55,false)

RWR_templates.Type_992 = RWR_helpers.create_surveilence({
    freq = {2.94,3.06},
    prf = {833},
    pulse_width = {2},
    P_max = 2000,
    hpbw = 1.4,
    hpbw_vert = 32,
    G = 30,
    scan_rate = 90,
    always_scan = true,
    scan_only = true,

    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.TWS] = {
            scan_rate = 270,
        },
        [RWREmitterMode.Lock] = {
            scan_rate = 270,
        },
        [RWREmitterMode.CR] = {
            scan_rate = 270
        }
    }

},0.4,true)

RWR_templates.Type_978 = RWR_helpers.create_surveilence({
    --from BR333 and Friedman
    freq = {9.36,9.46},
    prf = {500},
    pulse_width = {1},
    scan_rate = 144,
    P_max = 40,
    hpbw = 1.2,
    hpbw_vert = 21,
    elevation = 10
},0.4,true)

RWR_templates.Type_993 = RWR_helpers.create_surveilence({
    --from Friedman
    freq = {2,4}, --exact unknown
    prf = {400,500},
    pulse_width = {2,0.5},
    P_max = 750,
    hpbw = 2,
    hpbw_vert = 30,
    elevation = 15,
    scan_rate = 144,
},0.5,true)

RWR_templates.Type_1006 = RWR_helpers.create_surveilence({
    --Friedman
    freq = {9.445},
    prf = {800},
    pulse_width = {0.75},
    P_max = 25,
    scan_rate = 144,
    hpbw = 0.75,
    hpbw_vert = 18,
    elevation = 9,
    G = 34,

},0.5,true)

RWR_templates.Type_1022 = RWR_helpers.create_surveilence({
    --Friedman + radartutorial
    --Same transceiver as DW-08
    freq = {1.215,1.4},
    P_max = 150,
    prf = {500},
    antenna_pattern_type = RWRPatternType.CosecantSquared,
    hpbw = 2.3,
    elevation = 1,
    hpbw_vert = 30,
    scan_rate = 48,
},0.6,true,0.033)

RWR_templates.DA_02 = RWR_helpers.create_surveilence({
    --Friedman
    freq = {2.9,3.1},
    prf = {500},
    pulse_width = {1.3},
    hpbw = 1.7,
    antenna_pattern_type = RWRPatternType.CosecantSquared,
    hpbw_vert = 30,
    elevation = 1.7,
    P_max = 500,
    G = 32,
    scan_only = true,
    always_scan = true,
    scan_rate = 36,

    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.M1] = {
            conditions = {
                range_lt = 30000
            },
            prf = {1000},
            pulse_width = {0.5},
            scan_rate = 360,
        }
    }
})

RWR_templates.DA_05 = RWR_helpers.create_surveilence({
    freq = {2.95,3.1},  --2.9 acutal, for separation
    P_max = 1200,
    G = 32.2,
    prf = {500},
    pulse_width = {2.6},
    hpbw = 1.5,
    antenna_pattern_type = RWRPatternType.CosecantSquared,
    hpbw_vert = 40,
    elevation = 1,
    scan_rate = 60,

    mode = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.M1] = {
            conditions = {
                range_lt = 30000
            },
            prf = {1000},
            pulse_width = {1.3},
            scan_rate = 120,
        }
    }
})

RWR_templates.LW_01 = RWR_helpers.create_surveilence({
    --radartutorial
    freq = {1.22,1.35},
    prf = {900},
    pulse_width = {3},
    P_max = 600,
    hpbw = 1.5, --conjecture
    hpbw_vert = 30,
    elevation = 1,
    antenna_pattern_type = RWRPatternType.CosecantSquared,
    scan_rate = 48,

},0.6,true)

RWR_templates.LW_02 = RWR_helpers.create_surveilence({
    --Friedman
    freq = {1.26,1.35}, --1.22 actual, for separation
    hpbw = 2.2,
    hpbw_vert = 22,
    elevation = 1,
    antenna_pattern_type = RWRPatternType.CosecantSquared,
    P_max = 500,
    G = 31,
    pulse_width = {5},
    prf = {250},
    scan_rate = 3.6,

    mode = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.M1] = {
            conditions = {
                range_lt = 100000
            },
            prf = {500},
            pulse_width = {2},
            scan_rate = 36,
        }
    }

})

RWR_templates.ZW_01 = RWR_helpers.create_surveilence({
    freq = {8.5,9.6},
    hpbw = 1,
    hpbw_vert = 3.5,
    elevation = 1.75,
    P_max = 180,
    G = 39,
    pulse_width = {0.3},
    prf = {1000},
    scan_rate = 45,

    mode = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.M1] = {
            conditions = {
                range_lt = 20000
            },
            prf = {2000},
            pulse_width = {0.1},
            scan_rate = 90,
        }
    }
})

--almost everything is conjecture here
--signals params taken from DA-01
--antenna and scan pattern are assumed
RWR_templates.VI_01 = RWR_helpers.create_tracking({
    freq = {2.9,3.05},  --3.1 actual, for separation
    hpbw = 30,
    hpbw_vert = 1,
    prf = {1000},
    pulse_width = {0.5},
    P_max = 400,
    always_emulate_scan_pattern = true,
    scan_elevation_volume = 80,
    scan_azimuth_volume = 0,
    scan_pattern_type = RWRScanPatternType.NoScan,
    always_scan = true,
    scan_rate = 100,
    gimbal_limit = 180,

    --TODO need to test this
    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.Lock] = {
            scan_pattern_type = RWRScanPatternType.Acquisition,
            scan_only = true
        }
    }

},0.6,true)

--Vega WCS Search
RWR_templates.Triton_G = RWR_helpers.create_surveilence({
    --Friedman
    freq = {5.2,6},
    hpbw = 2,
    hpbw_vert = 22,
    elevation = 10,
    G = 38,
    P_max = 8,
    pulse_width = {12,6.5},
    prf = {1000,8000},
    freq_agility = RWRFreqAgility.Random,
    prf_agility = RWRFreqAgility.Random,
    freq_agility_interval = 0.1,
    prf_agility_interval = 0.1,
    scan_rate = 240,
})

--Vega WCS Track
RWR_templates.Pollux = RWR_helpers.create_tracking({
    freq = {9.305,9.335}, --French freq allocation chart for X-band, might be wider than this in reality
    --Friedman
    antenna_pattern_type = RWRPatternType.AiryPattern,
    prf = {1500},
    pulse_width = {0.3},
    G = 30,
    P_max = 200,
    hpbw = 2
})

--CurrentHill radars
--Iris-T SLM, AN/SPS-80 on LCS ships
RWR_templates.TRML_4D = RWR_helpers.create_generic({
    freq = {4,6},
    --everything here is estimated, no data on this radar except coverage
    prf = {60000,80000},
    P_max = 10,
    hpbw = 1.5,
    full_power_vert = 80, -- 70 to -10 stacked beam/AESA
    elevation = 30,
    freq_agility = RWRFreqAgility.Random,
    freq_agility_interval = 0.0000125,  
    prf_agility = RWRFreqAgility.Random,
    prf_agility_interval = 0.0000125, --we assume that for a 21st century system they would at least ensure SPO-15 can't recognize it
    always_scan = true, --AESA TWS
    always_emulate_scan_pattern = true,
    scan_pattern_type = RWRScanPatternType.circular,
    scan_rate = 90,
    antenna_pattern_type = RWRPatternType.SincWeighed,

    --power reduction with range
    modes = {
        [RWREmitterMode.M1] = {
            conditions = {
                modes = {RWREmitterMode.Scan},
                range_lt = 125000,
            },
            P_max = 10/16
        },
        [RWREmitterMode.M2] = {
            conditions = {
                modes = {RWREmitterMode.Scan},
                range_lt = 62500,
            },
            P_max = 10/(16^2),
            scan_rate = 180
        },
        [RWREmitterMode.M3] = {
            conditions = {
                modes = {RWREmitterMode.Scan},
                range_lt = 31250,
            },
            P_max = 10/(16^3),
            scan_rate = 180
        },
        [RWREmitterMode.M4] = {
            conditions = {
                modes = {RWREmitterMode.Lock,RWREmitterMode.CR},
                range_gt = 125000,
            },
            full_power_vert = 0
        },
        [RWREmitterMode.M5] = {
            conditions = {
                modes = {RWREmitterMode.Lock,RWREmitterMode.CR},
                range_lt = 125000,
            },
            full_power_vert = 0,
            P_max = 10/16
        },
        [RWREmitterMode.M6] = {
            conditions = {
                modes = {RWREmitterMode.Lock,RWREmitterMode.CR},
                range_lt = 62500,
            },
            P_max = 10/(16^2),
            full_power_vert = 0,
        },
        [RWREmitterMode.M7] = {
            conditions = {
                modes = {RWREmitterMode.Lock,RWREmitterMode.CR},
                range_lt = 31250,
            },
            P_max = 10/(16^3),
            full_power_vert = 0,
        },
    }
},0.7,0.25)

--Tor
RWR_templates.Tor_M2 = {}
copy_recursive(RWR_templates.Tor_M2, RWR_templates.SHORAD)
RWR_templates.Tor_M2.params.freq = {2,4}
RWR_templates.Tor_M2.params.full_power_vert = 70
RWR_templates.Tor_M2.params.elevation = 25
RWR_templates.Tor_M2.params.scan_pattern_type = RWRScanPatternType.circular
RWR_templates.Tor_M2.params.P_max = 3
RWR_templates.Tor_M2.params.hpbw = 1.5
RWR_templates.Tor_M2.params.hpbw_vert = 1.5
RWR_templates.Tor_M2.params.G = 39
RWR_templates.Tor_M2.params.side_lobe_level = 40

--couldn't find anything on this radar that would make it distinct from M1 version other than frequency
RWR_templates.Tor_M2.params1.freq = {18,27}

--Pantsir
RWR_templates._2RL80 = RWR_helpers.create_surveilence({
    freq = {2.0, 4.0},
    prf = {28000,30000},
    P_max = 20,
    hpbw = 3,
    full_power_vert = 70,
    elevation = 35,
    scan_rate = 90,

    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.M1] = {
            conditions = {
                range_lt = 25000
            },
            P_max = 1.25,
            scan_rate = 180,
        },
        [RWREmitterMode.M2] = {
            conditions = {
                range_lt = 12500
            },
            P_max = 0.078125,
            scan_rate = 180
        },
        [RWREmitterMode.M3] = {
            conditions = {
                range_lt = 6250
            },
            P_max = 0.0048828125,
            scan_rate = 180
        }
    }
},0.8,true,0.5)

RWR_templates._1RS2_1 = RWR_helpers.create_tracking({
    freq = {8,18},
    prf = {28000,30000},
    P_max = 2,
    hpbw = 1,

    modes = {
        [RWREmitterMode.Lock] = {},
        [RWREmitterMode.CR] = {},
        [RWREmitterMode.M1] = {
            conditions = {
                range_lt = 5000
            },
            freq = {16,18}  --stick to high Ku band when target is tracked by optics (conjecture)
        }
    }

},0.8,true,0.5)

--Positiv-ME1
RWR_templates.Positiv_ME1 = {}
copy_recursive(RWR_templates.Positiv_ME1, RWR_templates.MR_352)
RWR_templates.Positiv_ME1.prf = {40000,45000}
RWR_templates.Positiv_ME1.pulse_width = {10}
RWR_templates.Positiv_ME1.full_power_vert = 90
RWR_templates.Positiv_ME1.elevation = 40
RWR_templates.Positiv_ME1.P_max = 4.5 --multibeam, power split between multiple beams, unclear how many
RWR_templates.Positiv_ME1.freq_agility = RWRFreqAgility.Random
RWR_templates.Positiv_ME1.freq_agility_interval = 0.0001
RWR_templates.Positiv_ME1.prf_agility = RWRFreqAgility.Random
RWR_templates.Positiv_ME1.prf_agility_interval = 0.0001
RWR_templates.Positiv_ME1.always_scan = true
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock] = {}

--merge Vympel into Positiv track
copy_recursive(RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock],RWR_templates.MR_123)
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].freq = nil
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].scan_pattern_type = nil
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].modes = nil
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].scan_rate = nil
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].always_emulate_scan_pattern = nil
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].elevation = nil
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].scan_elevation_volume = nil
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].scan_pattern = nil
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].prf_agility = RWRFreqAgility.Const
RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock].freq_agility = RWRFreqAgility.Const
RWR_templates.Positiv_ME1.modes[RWREmitterMode.CR] = {}
copy_recursive(RWR_templates.Positiv_ME1.modes[RWREmitterMode.CR], RWR_templates.Positiv_ME1.modes[RWREmitterMode.Lock])

----------------
--weapon seekers

RWR_templates.AMRAAM = RWR_helpers.create_generic({
    freq = {8,12},
    prf = {300000},
    P_max = 0.5,
    scan_pattern_type = RWRScanPatternType.Cue,
    scan_time = 5,
    hpbw = 12.6,
    gimbal_limit = 60,

    modes = {
        [RWREmitterMode.M3] = {
            conditions = {
                elevation_gt = 10,
                range_lt = 5000
            },
            prf = {30000},
            pulse_width = {3},
        }
    }

},0.7,0.5)

print("loaded templates")