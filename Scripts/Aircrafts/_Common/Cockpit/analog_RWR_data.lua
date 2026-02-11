dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_SAM.lua')
dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_Airplane.lua')
dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_Ship.lua')
dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_Missile.lua')

dofile("Scripts/Aircrafts/_Common/Cockpit/analog_RWR_templates.lua")

--local function appended_list(t1, val)
--    local tout = {}
--    for k, v in pairs(t1) do
--        table.insert(tout,v)
--    end
--    table.insert(tout,val)
--    return tout
--end

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
    AcquisitionCross = 10,  --special for SNR-75V
}

RWRFreqAgility = {
    Const = 1,
    Stagger = 2,
    Smooth = 3,
    Random = 4
}

--RWR_templates = {
--    fighter_mid = {
--        G = 28,                                         --dBi
--        side_lobe_level = 21,                           --dB, only used by weighed patterns
--        ftbr = 25,                                      --dB, front to back ratio for main and back lobes
--        antenna_pattern_type = RWRPatternType.AiryWeighed, --antenna power directiviyy pattern type, defaults to 0 (standard sinc^2)
--        hpbw = 5,                                     --deg
--        hpbw_vert = 8,                                --simulating Palmer scan here
--        scan_rate = 85,                                --deg/s
--        P_max = 80,                                    --kW (peak power)
--        scan_pattern_type = RWRScanPatternType.raster,  --scan pattern type, defaults to raster
--        scan_pattern = 2,                               --"bars" in scan pattern, integer, 0 means stationary beam (range search only, beam fixed to boresight, e.g. F-86), 1 is default for ground objects, 4 for aircraft
--        scan_azimuth_volume = 90,                       --angle (total) in degrees, covered horizontally by the scan pattern, only used for emulated mode. Defaults to 60 for aircraft, 360 for ground
--        scan_elevation_volume = 10,                     --angle (total) in degrees, covered vertically 
--        always_emulate_scan_pattern = false,            --defaults to false, ignore RWR events and from the moment first event arrives only reference the emulated scan pattern. This exists pretty much exclusively for the borked radar of MiG-21bis
--
--        -- conditions for "deduced modes", those are a placeholder for data that should arrive through the messaging system, as they REALLY SHOULDN'T BE "ASSUMED" FOR HUMAN CONTROLLED AIRCRAFT
--        -- possible conditions:
--            -- default - if set to true, this will be used by default when other modes don't meet conditions, all conditions used here will be ignored
--            -- loadout - table of CLSIDs that trigger this mode
--            -- missile - actual missile wsTypes that are guided by this mode
--            -- range_lt - range less than, m
--            -- range_gt - range greater than, m
--            -- azimuth_lt - less than angle off-boresight in degrees
--            -- azimuth_gt - greater than angle off-boresight in degrees
--            -- elevation_lt - relative elevation less than
--            -- elevation_gt - relative elevation greater than
--            -- modes - specific standard modes that use this mode
--        conditions = {
--            [RWREmitterMode.CWillum] = 
--            {
--                modes = {RWREmitterMode.CR}
--            }
--        },
--        
--        modes = {
--            [RWREmitterMode.Scan] = {
--                prf = {200,1000},    --Hz
--                pulse_width = {2.0}      --microseconds, if not listed it's assumed to be 2us. DISCREET - the brackets don't contain a range but discreet pulse width options
--            },
--            [RWREmitterMode.CWillum] = {
--                --CW is enabled _alongside_ the main pulse mode, unless pulse mode is set up as CW by default (prf set to -1) - in that case this doesn't need to be used, see Hawk
--                P_max = 20
--            }
--        }
--        
--    }
--}


wstype_emission_data = {
    --{
    --    E_2C_,       --AN/APS-145
    --    params = {
    --        freq = {4e8,4.5e8},                     -- frequency range, Hz - note, SPO-10 won't see this radar so the rest of data is filled in just for completeness
    --        prf = {300,300},                        -- pulse repetition frequency range, Hz - this is out of range of SPO-10
    --        --MDS = 10^(-110/10),                   -- minimum discernible signal, W, default is -110 dBm
    --        P_max = 1e6,                            -- peak power, W, can be used instead of MDS together with R_max
    --        R_max = 6.5e5,                          -- maximum detection range against a 100m^2 RCS target, can be used instead of MDS together with P_max
    --        G = 10.^(20./10.),                      -- antenna gain (20dBi - array of yagi antennas), non-dim
    --        hpbw = math.rad(7),                     -- half power beamwidth, rad
    --        scan_rate = 0.523,                      -- antenna sweep rate, rad/s
    --        -- scan_period = 12                     -- full scan cycle period. For 2d radars/ 1-bar pattern leave this out or set to 0
    --        side_lobe_attenuation = 10.^(-15./10.), -- first sidelobe level
    --        side_lobe_level = 10.^(-40./10.)        -- average side lobe level
    --    }
    --},
    --{
    --    Gepard,
    --    params = {
    --        freq = {2e9,3e9},
    --        prf = {300,1000},
    --        MDS = 0.001*10.^(-105./10.),
    --        G = 10.^(25./10.),
    --        hpbw = math.rad(10),
    --        scan_rate = 6.28,
    --        side_lobe_attenuation = 10.^(-15./10.),
    --        side_lobe_level = 10.^(-40./10.),
--
    --    }
    --},
    --{
    --    Tunguska_2S6,
    --    params = {
    --        freq = {2e9, 3e9},
    --        prf = {100,6000},
    --        MDS = 0.001*10.^(-105./10),
    --        G = 10.^(25./10.),
    --        hpbw = math.rad(5),
    --        scan_rate = 6.28,
    --        side_lobe_attenuation = 10.^(-15./10.),
    --        side_lobe_level = 10.^(-40./10.),
--
    --    }
    --},
    --{
    --    Osa_9A33,
    --    params = {
    --        freq = { 6e9,8e9 },
    --        G = 10.^(25. / 10.),
    --        MDS = 0.001 * 10.^(-107. / 10.),
    --        hpbw = math.rad(5),
    --        prf = { 100,6000 },
    --        scan_rate = 6.28,
    --        side_lobe_attenuation = 10.^(-20. / 10.),
    --        side_lobe_level = 10.^ (-50. / 10.)
    --    }
    --},
    --{
    --    ALBATROS_,
    --    params = {  --Osa
    --        freq = { 6.0e9,8.0e9 },
    --        G = 10.^(25. / 10.),
    --        MDS = 0.001 * 10.^(-107. / 10.),
    --        hpbw = math.rad(5),
    --        prf = { 100,6000 },
    --        scan_rate = 6.28,
    --        side_lobe_attenuation = 10.^(-20. / 10.),
    --        side_lobe_level = 10.^ (-50. / 10.)
    --    }
    --},
    --{
    --    REZKY_,
    --    params = {  --Osa
    --        freq = { 6.0e9,8.0e9 },
    --        G = 10.^(25. / 10.),
    --        MDS = 0.001 * 10.^(-107. / 10.),
    --        hpbw = math.rad(5),
    --        prf = { 100,6000 },
    --        scan_rate = 6.28,
    --        side_lobe_attenuation = 10.^(-20. / 10.),
    --        side_lobe_level = 10.^ (-50. / 10.)
    --    }
    --},
    --{
    --    Tor_9A331,
    --    params = 
    --    {
    --        freq = {4.0e9, 8.0e9},
    --        prf = { 100,6000 },
    --        G = 10.^(30./10.),
    --        MDS = 0.001* 10.^(-116/10.),
    --        hpbw = math.rad(1.5),
    --        scan_rate = 0.558,
    --        side_lobe_attenuation = 10.^(-20. / 10.),
    --        side_lobe_level = 10.^ (-50. / 10.)
    --    }
    --},
    --multiple radars example
    --{
    --    type = Kuznecow_, --Kinzhal
    --    params = {
    --            freq = {4.0, 8.0},
    --            G = 38.,
    --            prf = { 100,6000 },
    --            P_max=150,
    --            hpbw = 4,
    --            scan_rate = 32,
    --            side_lobe_level = 40,
--
    --            modes = { --list ALL modes
    --                [RWREmitterMode.Scan] = {},
    --                [RWREmitterMode.Lock] = {
    --                    P_max=60,
    --                }, 
    --                [RWREmitterMode.CR] = {}
    --            },
    --        },
    --    params1 = {
    --            freq = {2.,3.},
    --            G = 38.,
    --            prf = { 100,6000 },
    --            P_max=150,
    --            hpbw = 4,
    --            scan_rate = 32,
    --            side_lobe_level = 40,
    --            modes = {[RWREmitterMode.Scan] = {}, [RWREmitterMode.Lock] = {}},
    --        }
    --},
    --{
    --    NEUSTRASH_,
    --    params =    --Kinzhal
    --    {
    --        freq = {4.0e9, 8.0e9},
    --        G = 10.^(30./10.),
    --        prf = { 100,6000 },
    --        MDS = 0.001* 10.^(-116/10.),
    --        hpbw = math.rad(1.5),
    --        scan_rate = 0.558,
    --        side_lobe_attenuation = 10.^(-20. / 10.),
    --        side_lobe_level = 10.^ (-50. / 10.)
    --    }
    --},
    {
        type = Hawk_CWAR_ANMPQ_55,
        params = {
            freq = {10,20},
            prf = {-1},     -- -1 marks CW
            G = 36,     --calculated from exposure warning data
            P_max = 0.4,
            antenna_pattern_type = RWRPatternType.SincWeighed,
            scan_pattern_type = RWRScanPatternType.circular,
            scan_rate = 120,
            hpbw = 0.6,
            hpbw_vert = 8,
            elevation = 1,  -- elevation angle for pattern center, 0 by default
            side_lobe_level = 35,
            ftbr = 40,
        }
    },
    {
        type = Hawk_TR_ANMPQ_46,
        params = {
            freq = {8,12},
            prf = {-1},
            antenna_pattern_type = RWRPatternType.AiryWeighed,
            scan_pattern_type = RWRScanPatternType.NoScan,
            scan_pattern = 2,
            G = 37,
            P_max = 3,
            hpbw = 2,
            side_lobe_level = 40,
            ftbr = 40,

            modes = {
                [RWREmitterMode.Lock] = {},
                [RWREmitterMode.CR] = {},
            }
        }
    },
    {
        type = Hawk_SR_ANMPQ_50,
        params = {
            freq = {0.5,1},
            G = 26,
            P_max = 450,
            hpbw = 2.5,
            hpbw_vert = 45,
            antenna_pattern_type = RWRPatternType.SincWeighed,
            scan_pattern_type = RWRScanPatternType.circular,
            scan_rate = 120,
            elevation = 25,
            side_lobe_level = 24,
            ftbr = 35,
            prf = {800},   --unknown
            pulse_width = {50},
            prf_agility = RWRFreqAgility.Stagger,
            prf_agility_interval = 0.00125
        }
    },
    --Patriot is a black box that is really difficult to describe properly.
    --What is here is based on anecdotes from operators and information about how SPO-15 reacted to it (coming up as Н, Х and F)
    {
        type = Patriot_STR_ANMPQ_53,
        params = {
            freq = {4.48, 5.45},    --should be raised to 5.25-5.925 at some point, need to consult with ground team
            G = 41,
            P_max = 5,
            prf = {100000,200000},
            pulse_width = {2.7,2.0,1.3,0.4},
            scan_pattern_type = RWRScanPatternType.ESA,
            scan_cycle = 0.3,
            scan_period = 5,
            antenna_pattern_type = RWRPatternType.SincWeighed,
            scan_azimuth_volume = 110,
            scan_rate = 300,
            scan_elevation_volume = 85,
            hpbw = 1.4,
            side_lobe_level = 45,
            ftbr = 50,
            freq_agility = RWRFreqAgility.Random,
            freq_agility_interval = 0.005,
            prf_agility = RWRFreqAgility.Random,
            prf_agility_interval = 0.02,
            always_scan = true,
            always_emulate_scan_pattern = true,
            scan_only = true,   --TVM
            gimbal_limit = 60,
            gimbal_limit_vert = 85,
            random_scan_rate = true,

            modes = {
                [RWREmitterMode.Scan] = {},
                [RWREmitterMode.TWS] = {},
                [RWREmitterMode.Lock] = {
                    scan_azimuth_volume = 120,
                },
                [RWREmitterMode.CR] = {
                    scan_azimuth_volume = 120,
                    scan_period = 1.,
                },
                [RWREmitterMode.M1] = {
                    conditions = {
                        modes = {RWREmitterMode.Scan, RWREmitterMode.TWS, RWREmitterMode.Lock},
                        elevation_lt = -500,
                        azimuth_lt = 95,
                        azimuth_gt = 85,
                    },
                    prf = {500,680},     --unambiguous range at 170-187km
                    pulse_width = {50,0.4},
                    scan_cycle = 0.5,
                    prf_agility_interval = 0.05
                },
            }
        }
    },

    {
        type = PERRY_,
        --AN/SPS-49
        params = {
            freq = {0.85, 0.942},
            freq_agility = RWRFreqAgility.Const,
            prf = {280, 1000},
            pulse_width = {120.,2.0},
            scan_rate = 72,
            hpbw = 3.3,
            hpbw_vert = 22.0,
            P_max = 360,    --this is powerful enough that it might bleed through despite being out of range
            G = 28.5,
            antenna_pattern_type = RWRPatternType.CosecantSquared,
            side_lobe_level = 25,
            ftbr = 30,
            scan_pattern_type = RWRScanPatternType.circular,
            elevation = 5.,
            --always_scan = true, --continue scanning when vehicle is in track mode with another radar
            always_emulate_scan_pattern = true,
            always_center_pattern = true,
            modes = {
                [RWREmitterMode.Scan] = {},
            }
        },
        --AN/SPS-55
        params1 = {
            freq = {9.05,10.},
            prf = {750},
            pulse_width = {1.0},
            hpbw = 1.5,
            hpbw_vert = 20,
            elevation = 0,
            P_max = 130,
            G = 31,
            ftbr = 0, --backscan
            scan_rate = 96,
            antenna_pattern_type = RWRPatternType.SincWeighed,
            side_lobe_level = 30,
            scan_pattern_type = RWRScanPatternType.circular,
            --always_scan = true,
            always_emulate_scan_pattern = true,
            always_center_pattern = true,
            modes = {
                [RWREmitterMode.Scan] = {}
            }
        },
        --Mark 92 CAS Scan
        params2 = {
            freq = {8,10},
            P_max = 200,
            ftbr = 40,
            always_emulate_scan_pattern = true,
            always_center_pattern = true,
            always_scan = true,
            freq_agility = RWRFreqAgility.Const,

            modes = {}
        },
        --Upgraded Mark 92 STIR - MISSING FROM 3D MODEL
        params3 = {
            freq= {8.1,10.1},
            P_max = 20,
            ftbr = 30,
            freq_agility = RWRFreqAgility.Const,
            prf = {25000,35000},
            pulse_width = {8,4,2,1}, --only the range is realistic here but it shouldn't matter
            scan_pattern_type = RWRPatternType.NoScan,
            antenna_pattern_type = RWRPatternType.AiryPattern,
            hpbw = 0.6,
            G = 48,
            modes = {
                [RWREmitterMode.Lock] = {},
                [RWREmitterMode.CR] = {},
                [RWREmitterMode.CWillum] = {
                    conditions = {
                        modes = {RWREmitterMode.Lock, RWREmitterMode.CR},
                        missile = {"weapons.missiles.SM_1"}
                    },
                    prf = {-1}
                }
            }
        },

        params4 = RWR_templates.Phalanx
    },

    {
        type = Vulcan_M163,
        params = {
            --MIL-R-50668A
            --this is now consistent with SPO-15 docs
            freq = {9.195, 9.257},
            prf = {19900,20100},
            pulse_width = {0.3},

            G = 33,
            P_max = 1.4,
            scan_pattern_type = RWRScanPatternType.NoScan,
            antenna_pattern_type = RWRPatternType.AiryWeighed,
            hpbw = 4.1,
            hpbw_vert = 4.3,
            side_lobe_level = 24,
            ftbr = 25,
        }
    }
}

perry_CAS_scan = {
    hpbw = 1,
    hpbw_vert = 8,
    G = 36,
    prf = {3600},
    pulse_width = {0.22},
    antenna_pattern_type = RWRPatternType.CosecantSquared,
    side_lobe_level = 30,
    scan_pattern_type = RWRScanPatternType.spiral,
    scan_azimuth_volume = 360,
    scan_elevation_volume = 40,
    elevation = 4,
    scan_pattern = 6,
    scan_rate = 360,
    
}

perry_CAS_track = {
    hpbw = 2.7,
    hpbw_vert = 2.7,
    G = 36,
    prf = {3600},
    pulse_width = {0.22},
    antenna_pattern_type = RWRPatternType.AiryPattern,
}

perry_CAS_CW = {}
copy_recursive(perry_CAS_CW, perry_CAS_track)
perry_CAS_CW.prf = {-1}
perry_CAS_CW.pulse_width = {}
perry_CAS_CW.P_max = 100
perry_CAS_CW.conditions = {
    modes = {RWREmitterMode.Lock, RWREmitterMode.CR},
    missile = {"weapons.missiles.SM_1"}
}

perry_modes = {
    [RWREmitterMode.Scan] = perry_CAS_scan,
    [RWREmitterMode.Lock] = perry_CAS_track,
    [RWREmitterMode.CR] = {},
    [RWREmitterMode.M1] = {},
    [RWREmitterMode.M2] = {},
    [RWREmitterMode.CWillum] = perry_CAS_CW,
}
copy_recursive(perry_modes[RWREmitterMode.CR],perry_modes[RWREmitterMode.Lock])
copy_recursive(perry_modes[RWREmitterMode.M1],perry_modes[RWREmitterMode.Scan])
perry_modes[RWREmitterMode.M1].prf = {1800}
perry_modes[RWREmitterMode.M1].pulse_width = {0.45}
perry_modes[RWREmitterMode.M1].conditions = {
    modes = {RWREmitterMode.Scan},
    range_gt = 40000,
}
copy_recursive(perry_modes[RWREmitterMode.M2],perry_modes[RWREmitterMode.Lock])
perry_modes[RWREmitterMode.M2].prf = {1800}
perry_modes[RWREmitterMode.M2].pulse_width = {0.45}
perry_modes[RWREmitterMode.M2].conditions = {
    modes = {RWREmitterMode.Lock,RWREmitterMode.CR},
    range_gt = 40000,
}

for i,v in ipairs(wstype_emission_data) do
    if v.type[1] == PERRY_[1] and v.type[2] == PERRY_[2] and v.type[3] == PERRY_[3] and v.type[4] == PERRY_[4] then
        copy_recursive(wstype_emission_data[i].params2.modes,perry_modes)
        break
    end
end

--copy_recursive(wstype_emission_data[6].params2.modes,perry_modes)
print("loaded perry")

string_emission_data = {
    
    --["F-5E-3"] = { --AN/APQ-159
    --    freq = {8e9,12e9},        
    --    prf = {1000,1000},        
    --    MDS = 0.001*10^(-105/10), 
    --    G = 10.^(28./10.),        
    --    hpbw = math.rad(4),       
    --    scan_rate = 2.5,              
    --    -- scan_period = 12         --1 bar           
    --    side_lobe_attenuation = 10.^(-20./10.),
    --    side_lobe_level = 10.^(-40./10.)       
    --},
    --["CV_1143_5"] = {  --Kinzhal
    --    freq = {4.0e9, 8.0e9},
    --    G = 10.^(30./10.),
    --    prf = { 100,6000 },
    --    MDS = 0.001* 10.^(-116/10.),
    --    hpbw = math.rad(1.5),
    --    scan_rate = 6.28,
    --    side_lobe_attenuation = 10.^(-20. / 10.),
    --    side_lobe_level = 10.^ (-50. / 10.)
    --},
 
    --new database, using HB aircraft as examples due to well documented radar params from HB

    ["F-4E-45MC"] = {
        freq = {9.4,9.4},                              --GHz
        G = 35,                                         --dBi
        --side_lobe_level = 23,                           --dB, only used by weighed patterns
        ftbr = 25,                                      --dB, front to back ratio for main and back lobes
        antenna_pattern_type = RWRPatternType.AiryPattern, --antenna power directiviyy pattern type, defaults to 0 (standard sinc^2) if side_lobe_level is NOT present or SincWeighed (sinc^2 with arbitrary side lobe level) otherwise
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
                prf = {370},    --Hz    --from HB manual, though other sources claim 330
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
                freq = {10.05,10.25},
                conditions = {
                    modes = {RWREmitterMode.CR}
                },
                --CW is enabled _alongside_ the main pulse mode, unless pulse mode is set up as CW by default (main prf set to -1) - in that case this doesn't need to be used, see Hawk
                prf = {-1},
                P_max = 0.2, --70
            }
        }
        
    },
    
    ["F-14A-135-GR"] = {
        freq = {9.,9.8},
        G = 37,
        side_lobe_level = 35,
        ftbr = 35,
        antenna_pattern_type = RWRPatternType.SincWeighed,
        hpbw = 2.3,
        scan_rate = 80,
        P_max = 10.2,
        scan_pattern = 8,
        scan_pattern_type = RWRScanPatternType.raster,
        scan_azimuth_volume = 130,
        scan_elevation_volume = 10.4,
        always_emulate_scan_pattern = true,
        always_center_pattern = true,
        do_not_center_elevation = true,
        gimbal_limit = 74,

        modes = {
            [RWREmitterMode.M1] = {
                conditions = {
                    range_lt = 55560,
                    range_gt = 40000,
                    azimuth_lt = 95,
                    azimuth_gt = 85,
                    elevation_gt = 500,
                    modes = {
                        RWREmitterMode.Scan,
                    }
                },
                prf = {360},
                pulse_width = {0.4},    --Airborne Electronics Forecast
            },
            [RWREmitterMode.M2] = {
                conditions = {
                    range_lt = 40000,
                    range_gt = 18520,
                    azimuth_lt = 95,
                    azimuth_gt = 85,
                    elevation_gt = 500,
                    modes = {
                        RWREmitterMode.Scan,
                        RWREmitterMode.Lock,
                        RWREmitterMode.CR
                    }
                },
                prf = {1000},
                pulse_width = {50},
            },
            [RWREmitterMode.M3] = {
                conditions = {
                    range_lt = 18520,
                    azimuth_lt = 95,
                    azimuth_gt = 85,
                    elevation_gt = 500,
                    modes = {
                        RWREmitterMode.Scan,
                        RWREmitterMode.Lock,
                        RWREmitterMode.CR
                    }
                },
                prf = {1000},
                pulse_width = {0.4},
            },
            [RWREmitterMode.M5] = {
                conditions = {
                    default = true,
                },
                prf = {250e3},
                pulse_width = {2.7,2.0},
            },
            [RWREmitterMode.M6] = {
                conditions = {
                    modes = {
                        RWREmitterMode.CR
                    },
                    missile = {
                        {4, 4,  7,  21},
                        "weapons.missiles.AIM-7MH",
                        "weapons.missiles.AIM-7P"
                    },
                },
                prf = {307e3},
                pulse_width = {1.3, 0.4}
            },
            [RWREmitterMode.CWillum] = {
                conditions = {
                    modes = {
                        RWREmitterMode.CR
                    },
                    missile = {
                        "weapons.missiles.AIM-7E",
                        "weapons.missiles.AIM-7F",
                    }
                },
                freq = {10.05,10.2},
                prf = {-1},
                P_max = 3.3
            }
        }

    },

    ["AIM_54A_Mk47"] = 
    {
        freq = {9.2,9.4},
        G = 31,
        side_lobe_level = 25,
        ftbr = 25,
        antenna_pattern_type = RWRPatternType.AiryWeighed,
        hpbw = 6,
        scan_rate = 80,
        P_max = 0.075,
        scan_pattern_type = RWRScanPatternType.Cue,
        scan_time = 5,
        prf = {250e3},
        pulse_width = {2.},
        gimbal_limit = 60,
    },

    --Nike-Hercules
    --THIS DOES NOT EXIST IN GAME
    --writing it down just because those params are publicly known
    --["MIM_14_MTR"] = 
    --{
    --    freq = {8.5, 9.6},
    --    P_max = 158.9,
    --    G = 44.1, --this thing would light up the indicator from accross the map
    --    --vertical polarization - if we ever add that into consideration
    --    side_lobe_level = 30,
    --    pulse_width = {0.25},
    --    prf = {500},
    --    hpbw = 1,
    --    scan_pattern_type = RWRScanPatternType.NoScan,
    --    antenna_pattern_type = RWRPatternType.AiryWeighed
    --},
    --["MIM_14_TTR"] = 
    --{
    --    freq = {8.5, 9.6},
    --    P_max = 250,
    --    G = 44.1,
    --    --vertical polarization - if we ever add that into consideration
    --    side_lobe_level = 30,
    --    pulse_width = {0.25},
    --    prf = {500},
    --    hpbw = 1,
    --    scan_pattern_type = RWRScanPatternType.NoScan,
    --    antenna_pattern_type = RWRPatternType.AiryWeighed
    --}
}

string_emission_data["AIM_54A_Mk60"] = string_emission_data["AIM_54A_Mk47"]
string_emission_data["AIM_54C_Mk47"] = string_emission_data["AIM_54A_Mk47"]
string_emission_data["AIM_54C_Mk60"] = string_emission_data["AIM_54A_Mk47"]

local function emission_entry(index, target,...)
    local arg = {...}
    if(type(index) == "table") then
        local ret = {}
        ret.type = index
        ret.params = {}
        copy_recursive(ret.params, target)
        if arg and #arg > 0 then
            for i,a in ipairs(arg) do
                local s = "params"..tostring(i)
                ret[s] = {}
                copy_recursive(ret[s],a)
            end
        end
        table.insert(wstype_emission_data,ret)
    elseif(type(index) == "string") then
        string_emission_data[index] = target
        if arg and #arg > 0 then
            for i,a in ipairs(arg) do
                string_emission_data[index.."___"..tostring(i)] = a
            end
        end
    end
end

local function find_wstype(wstype)
    for i,v in ipairs(wstype_emission_data) do
        if v.type[1] == wstype[1] and v.type[2] == wstype[2] and v.type[3] == wstype[3] and v.type[4] == wstype[4] then
            return wstype_emission_data[i], i
        end
    end
end

local function clone(index, original_index)
    if (type(index) == "table") then
        local ret = {}
        if (type(original_index) == "table") then
            local data = find_wstype(original_index)
            copy_recursive(ret,data)
            ret.type = {}
            copy_recursive(ret.type,index)
        elseif(type(original_index) == "string") then
            ret.type = {}
            copy_recursive(ret.type,index)
            ret.params = {}
            copy_recursive(ret.params,string_emission_data[original_index])
            local add = 1
            while(string_emission_data[original_index.."___"..tostring(add)] ~= nil) do
                ret["params"..tostring(add)] = {}
                copy_recursive(ret["params"..tostring(add)],string_emission_data[original_index.."___"..tostring(add)])
                add = add+1
            end
        else return end
        table.insert(wstype_emission_data,ret)
    elseif(type(index) == "string") then
        if (type(original_index) == "table") then
            local data = find_wstype(original_index)
            string_emission_data[index] = {}
            copy_recursive(string_emission_data[index],data.params)
            local add = 1
            while (data["params"..tostring(add)] ~= nil) do
                string_emission_data[index.."___"..tostring(add)] = {}
                copy_recursive(string_emission_data[index.."___"..tostring(add)], data["params"..tostring(add)])
                add = add + 1
            end
        elseif(type(original_index) == "string") then
            string_emission_data[index] = {}
            copy_recursive(string_emission_data[index],string_emission_data[original_index])
            local add = 1
            while (string_emission_data[original_index.."___"..tostring(add)] ~= nil) do
                string_emission_data[index.."___"..tostring(add)] = {}
                copy_recursive(string_emission_data[index.."___"..tostring(add)], string_emission_data[original_index.."___"..tostring(add)])
                add = add + 1
            end
        end
    end
end

--------------------------------
---NAVY
--------------------------------

local AN_SPS_49 = {}
copy_recursive(AN_SPS_49, find_wstype(PERRY_).params)

emission_entry(TICONDEROGA_,
    AN_SPS_49,
    RWR_templates.AN_SPY_1,
    --RWR_templates.AN_SPG_62,
    RWR_templates.Phalanx,
    RWR_templates.AN_SPQ_9B
)

emission_entry(ALBATROS_,
    RWR_templates.Osa_M.search,
    RWR_templates.MR_320,
    RWR_templates.Don,
    RWR_templates.Osa_M.track,
    RWR_templates.MR_123
)

emission_entry(Kuznecow_,
    RWR_templates.MR_750.params,
    RWR_templates.MR_750.params1,
    RWR_templates.SHORAD.params,     --Tor
    RWR_templates.SHORAD.params1,     --Tor
    RWR_templates.MR_212,
    RWR_templates.MR_320       --stand in for MR-350
)

emission_entry("CV_1143_5",
    RWR_templates.MR_750.params,
    RWR_templates.MR_750.params1,
    RWR_templates.SHORAD.params,     --Tor
    RWR_templates.SHORAD.params1,     --Tor
    RWR_templates.MR_212,
    RWR_templates.MR_320       --stand in for MR-350
)

emission_entry(MOLNIYA_,
    RWR_templates.MR_352,
    RWR_templates.MR_123,
    RWR_templates.MR_212
)

emission_entry(MOSCOW_,
    RWR_templates.MR_800.params,
    RWR_templates.MR_800.params1,
    RWR_templates.MR_700.params,
    RWR_templates.MR_700.params1,
    RWR_templates.MR_123,
    RWR_templates.MR_212,
    RWR_templates.Osa_M.search,
    RWR_templates.Osa_M.track,
    RWR_templates.Volna
)

emission_entry(NEUSTRASH_,
    RWR_templates.MR_750.params,
    RWR_templates.MR_750.params1,
    RWR_templates.MR_212,
    RWR_templates.MR_352,
    RWR_templates.SHORAD.params,    --Klinok search
    RWR_templates.SHORAD.params1    --Klinok track
)

emission_entry(SKORY_,              --Piotr Vieliky/Kirov class
    RWR_templates.MR_800.params,
    RWR_templates.MR_800.params1,
    RWR_templates.MR_750.params,
    RWR_templates.MR_750.params1,
    RWR_templates.MR_320,
    RWR_templates.MR_212,
    RWR_templates.Volna,
    RWR_templates.Osa_M.search,
    RWR_templates.Osa_M.track
)

emission_entry(REZKY_,
    RWR_templates.MR_300,
    RWR_templates.MR_231,
    RWR_templates.Osa_M.search,
    RWR_templates.Osa_M.track
)

emission_entry("USS_Arleigh_Burke_IIa",
    AN_SPS_49,
    RWR_templates.AN_SPY_1,
    --RWR_templates.AN_SPG_62,
    RWR_templates.Phalanx,
    RWR_templates.AN_SPQ_9B
)

emission_entry("CVN_71",
    AN_SPS_49,
    RWR_templates.AN_SPS_48E,
    RWR_templates.AN_SPN_43,
    RWR_templates.AN_SPQ_9B,
    RWR_templates.Mark_95,
    RWR_templates.Phalanx
)

clone("CVN_72","CVN_71")
clone("CVN_73","CVN_71")
clone("Stennis","CVN_71")
clone("CVN_75","CVN_71")

emission_entry("BDK-775",
    RWR_templates.MR_302,
    RWR_templates.Don)

--BROKEN 3RD PARTY FREQ DEFS

--workaround
local function add_ignore_wsm_flag(table, scan_track_flags)
    if type(table) == "table" then
        local ret = {}
        copy_recursive(ret,table)
        ret.ignore_wsm_frequencies = true
        if scan_track_flags then
            if scan_track_flags == 1 then
                ret.always_scan = true
            elseif scan_track_flags == 2 then
                ret.scan_pattern_type = RWRScanPatternType.NoScan
            end
        end
        return ret
    end
end

--placeholder for proper illuminator freqs
--local Mark_95_mod = {}
--copy_recursive(Mark_95_mod,RWR_templates.Mark_95)
--Mark_95_mod.freq = {0.5, 0.58}  --this is wrong, but was also wrong in our def

emission_entry("Forrestal",
    add_ignore_wsm_flag(RWR_templates.AN_SPS_67,1),
    add_ignore_wsm_flag(RWR_templates.AN_SPS_48C,1),
    add_ignore_wsm_flag(AN_SPS_49,1),
    add_ignore_wsm_flag(RWR_templates.AN_SPS_10E,1),
    add_ignore_wsm_flag(RWR_templates.AN_SPN_43,1),
    add_ignore_wsm_flag(RWR_templates.Phalanx_range_limit,2),
    add_ignore_wsm_flag(RWR_templates.Mark_95,2)
)

--same deal with Tarawa
emission_entry("LHA_Tarawa",
    add_ignore_wsm_flag(RWR_templates.AN_SPS_67,1),
    add_ignore_wsm_flag(RWR_templates.AN_SPS_48E,1),
    add_ignore_wsm_flag(AN_SPS_49,1),
    add_ignore_wsm_flag(RWR_templates.AN_SPN_43,1),
    add_ignore_wsm_flag(RWR_templates.Mark_23,1),
    --add_ignore_wsm_flag(RWR_templates.Mark_95,2),
    add_ignore_wsm_flag(RWR_templates.Phalanx_range_limit,2)
)

--they listed search radar frequencies but then they delete them a few lines later in what looks like debug code that was not commented out
--also they copypasted Mk 95 trackers without any care, so I'm gonna do the same
emission_entry("leander-gun-achilles",
    --listing Type 992 as the most likely thing to be detected
    add_ignore_wsm_flag(RWR_templates.Type_993,1),
    add_ignore_wsm_flag(RWR_templates.Type_978,1),
    add_ignore_wsm_flag(RWR_templates.Type_965M,1),
    add_ignore_wsm_flag(RWR_templates.AN_SPG_35,2)  --Type 903    
)

clone("leander-gun-andromeda","leander-gun-achilles")  --Andromeda is supposed to have Sea Wolf but doesn't
clone("leander-gun-ariadne","leander-gun-achilles")
clone("leander-gun-condell","leander-gun-achilles")
clone("leander-gun-lynch","leander-gun-achilles")

emission_entry("CastleClass_01",
    add_ignore_wsm_flag(RWR_templates.Type_1006,1)
)

--Argentine carrier
--Dutch sensors
--this one is even worse, cause the listed radar freqs are clearly placeholder, but in this case they are actually loaded
--the ship does not have a tracking radar, yet Sea Sparrow radars are listed for some reason
emission_entry("ara_vdm",
    --state after 1983 refit
    add_ignore_wsm_flag(RWR_templates.DA_02,1),
    add_ignore_wsm_flag(RWR_templates.DA_05,1), --missing from model, but supposed to be there
    add_ignore_wsm_flag(RWR_templates.LW_01,1), --the antenna corresponding to LW-01 looks like a chimera of 01 and 02 on the model
    add_ignore_wsm_flag(RWR_templates.LW_02,1),
    add_ignore_wsm_flag(RWR_templates.ZW_01,1),
    add_ignore_wsm_flag(RWR_templates.VI_01,2)
)

emission_entry("hms_invincible",
    --Type 1006
    add_ignore_wsm_flag(RWR_templates.Type_1006,1),
    add_ignore_wsm_flag(RWR_templates.Type_1022,1),
    add_ignore_wsm_flag(RWR_templates.Type_992,1),
    add_ignore_wsm_flag(RWR_templates.Type_909,2)
)

print("Loaded ships")

-----------------------------
---GROUND
-----------------------------

emission_entry(EWR_1L13_,
    RWR_helpers.create_surveilence({
        freq = {0.180, 0.220},
        prf = {300},
        scan_rate = 18,
        P_max = 140,
        hpbw = 6,
        hpbw_vert = 30,
    },0.4,true,0.01)
)

emission_entry(Kub_STR_9S91,
    RWR_helpers.create_surveilence({
        freq = {8.0,9.0},   --needs correction in def
        prf = {2000},
        pulse_width = {0.5},
        P_max = 600,
        scan_rate = 90,
        hpbw = 1,
        hpbw_vert = 20,
        elevation = 10,
    },0.6,true),
    RWR_helpers.create_tracking({
        freq = {8.0,10.0},
        prf = {2000},
        pulse_width = {0.45},
        P_max = 270,
        hpbw = 1,
        
        modes = {
            [RWREmitterMode.Lock] = {},
            [RWREmitterMode.CR] = {},
            [RWREmitterMode.CWillum] = {
                conditions = {
                    modes = {RWREmitterMode.CR},
                    --missiles = {{4,4,34,84}}
                },
                prf = {-1}
            }
        }
    },0.6,true)
)

emission_entry(Buk_SR_9S18M1,
    RWR_helpers.create_surveilence({
        freq = {3,4},
        prf = {1600},       --from HB
        pulse_width = {50},
        P_max = 40, --estimated for 50us pulse
        hpbw = 3,
        hpbw_vert = 4.5,
        full_power_vert = 60, --ESA
        elevation = 30,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.M1] = {
                conditions = {
                    range_gt = 90000,
                },
                prf = {800},
            },
            [RWREmitterMode.M2] = {
                conditions = {
                    range_lt = 60000,
                },
                prf = {2401},
            }
        }

    },0.6,true)
)

emission_entry(Buk_LN_9A310M1,
    RWR_helpers.create_generic({
        freq = {6,9},
        prf = {9000,25000},
        pulse_width = {2},
        P_max = 40,
        hpbw = 2.5,
        hpbw_vert = 1.3,
        G = 40,
        scan_pattern_type = RWRScanPatternType.ESA,
        scan_elevation_volume = 7,
        scan_azimuth_volume = 90,
        gimbal_limit = 180,
        scan_cycle = 4,
        scan_period = 4,
        always_emulate_scan_pattern = true,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {    --not used by WS currently AFAIK
                scan_azimuth_volume = 10,
                scan_elevation_volume = 7,
                scan_cycle = 2,
                scan_period = 2
            },
            [RWREmitterMode.Lock] = {},
            [RWREmitterMode.CR] = {},
            [RWREmitterMode.CWillum] = {
                conditions = {
                    modes = {RWREmitterMode.CR}
                },
                P_max = 2,
                prf = {-1},
                hpbw = 1.4,
                hpbw_vert = 2.7,
                G = 41
            }
        }
    })
)

emission_entry(Dog_Ear,
    RWR_helpers.create_surveilence({
        freq = {3,6},
        prf = {3000},    --unambiguous at 50km, otherwise unknown
        P_max = 200,
        scan_rate = 180,
        hpbw = 5.5,
        hpbw_vert = 30,
        elevation = 15
    },0.6,true,0.05)
)

emission_entry(EWR_55G6_,
    RWR_helpers.create_surveilence({
        freq = {0.03,0.3},
        prf = {200,220},    --unknown, based on instrumented range for unambiguous range, likely staggered
        freq_agility = RWRFreqAgility.Stagger,
        freq_agility_interval = 0.005,
        P_max = 500,
        scan_rate = 36,
        hpbw = 5,
        full_power_vert = 30,
        elevation = 15,
    },0.5,true,0.01)    --duty cycle known - average power 5kW
)

emission_entry(S125_SR_P_19,
    RWR_helpers.create_surveilence({
        freq = {0.83,0.875},
        prf = {500,600},
        pulse_width = {2.1},
        P_max = 300,
        hpbw = 4.5,
        hpbw_vert = 13,
        full_power_vert = 13,
        elevation = 13,
        scan_rate = 72,
    },0.4,true)
)

emission_entry(Roland_rdr,
    RWR_helpers.create_surveilence({
        freq = {1,2},
        prf = {5000},
        scan_rate = 120,
        hpbw = 1.5,
        hpbw_vert = 45,
        P_max = 10,
    },0.6,true,0.02)
)

emission_entry(Roland_ADS,
    RWR_helpers.create_surveilence({
        freq = {1,2},
        prf = {5000},           --unknown if this is for search or track
        pulse_width = {0.4},    --unknown if this is for search or track
        scan_rate = 360,
        hpbw = 4.8,
        hpbw_vert = 30,
        P_max = 20,    --no source
    },0.6,true),
    RWR_helpers.create_tracking({
        freq = {8,12}, --this should be in J (10-20) band based on public source, HB claims 15.35 - 17.35 GHz but no idea where they have it from (it would be in range of SPO-10 but out of range of SPO-15, need to investigate)
        prf = {5000},           --unknown if this is for search or track
        pulse_width = {0.4},    --unknown if this is for search or track
        P_max = 10,
        hpbw = 2.6,             --pattern taken from HB who have it from who knows where but do have it
        hpbw_vert = 1.1
    },0.6,true)
)

--S-125
--This covers ONLY the UV-10 antenna, based on what info I could find this design ALWAYS functions like the SNR-75 in LORO mode, with UV-10 antenna transmitting and the 45 degree angled UV-11 antennas only receiving
emission_entry(S125_TR_SNR,
    RWR_helpers.create_generic({
        freq = {9,9.4},
        prf = {1750},
        pulse_width = {0.5},
        scan_pattern_type = RWRScanPatternType.Acquisition, --vertical scan
        always_emulate_scan_pattern = true,
        antenna_pattern_type = RWRPatternType.SincPattern,
        scan_elevation_volume = 15,
        scan_azimuth_volume = 0,
        gimbal_limit = 180,
        scan_rate = 480,
        hpbw = 1,
        P_max = 210,
        G = 44,
                
        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {},
            [RWREmitterMode.Lock] = {
                hpbw = 10.0,
                hpbw_vert = 10.0,
                scan_pattern_type = RWRScanPatternType.Cue, --doesn't really matter, this is proper track
                G = 24,
                prf = {3560,3585},
                pulse_width = {0.26}
            },
            [RWREmitterMode.CR] = {
                hpbw = 10.0,
                hpbw_vert = 10.0,
                scan_pattern_type = RWRScanPatternType.Cue, --doesn't really matter, this is proper track
                G = 24,
                prf = {3560,3585},
                pulse_width = {0.26}
            }
        }
    },0.5)
)

emission_entry(Tunguska_2S6,
    RWR_helpers.create_surveilence({
        freq = {2,3},
        prf = {7500},
        P_max = 10/3, --3x 5 deg beams simulatanously
        hpbw = 4.5,
        hpbw_vert = 5,
        full_power_vert = 10,
        elevation = 7.5,
        scan_rate = 360,
        always_scan = true,
        always_emulate_scan_pattern = true,
        always_center_pattern = true,
    },0.5,true,0.1),
    RWR_helpers.create_tracking(RWR_helpers.create_parabolic({
        freq = {10,20},
        prf = {8300},
        hpbw = 2.6,
        P_max = 150
    },0.3,15.,1,true,0.1),0.5,true,0.1)
)

emission_entry(Osa_9A33,
    RWR_templates.Osa_M.search,
    RWR_templates.Osa_M.track
)

emission_entry(Tor_9A331,
    RWR_templates.SHORAD.params,
    RWR_templates.SHORAD.params1
)

emission_entry(Gepard,
    RWR_helpers.create_surveilence({
        freq = {2,3},
        prf = {5000},
        P_max = 25,
        hpbw = 4.8,
        hpbw_vert = 30,
        elevation = 15,
        scan_rate = 360,
        always_emulate_scan_pattern = true,
        always_center_pattern = true,
        always_scan = true,
    },0.6,true,0.05),
    RWR_helpers.create_tracking({
        freq = {10,20},
        prf = {10000},
        hpbw = 2.4,
        P_max = 100
    },0.6,true,0.1)
)

emission_entry(ZSU_23_4_Shilka,
    RWR_helpers.create_tracking({
        freq = {14.6,15.6},
        prf = {2500},
        P_max = 110,
        hpbw = 2,
        antenna_pattern_type = RWRPatternType.AiryWeighed
    },0.5,true,0.02)
)

emission_entry("FPS-117 Dome",
    RWR_templates.EWR
)

emission_entry("FPS-117",
    RWR_templates.EWR
)

--there's extremely good information on this radar, to the point where exact frequency vs beam elevation could be potentially extracted,
emission_entry("RLS_19J6",
    RWR_helpers.create_surveilence({
        freq = {2.85,3.2},
        prf = {1500},               --unambiguous range 100 km
        pulse_width = {6},
        P_max = 350,
        hpbw = 0.5,
        hpbw_vert = 6.5,
        scan_rate = 36,
        full_power_vert = 19.5,     --4 beams at 4 freqs
        elevation = 13,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.M2] = {
                conditions = {
                    range_gt = 75000,   --based on instrumentation range
                },
                prf = {750},
                pulse_width = {12}
            }
        }
    },0.6,true)
)

--this one's the opposite
emission_entry("NASAMS_Radar_MPQ64F1",
    RWR_helpers.create_surveilence({
        freq = {8,12},
        prf = {40000},      --assuming HPRF
        P_max = 25,         --assuming 40% duty cycle with a known 10 kW power supply
        hpbw = 1,           --pencil beam
        full_power_vert = 110,   -- -10 to 55 with backscan, we don't care about what happens underground so we just make it symmetric for backscan to work
        scan_rate = 180,
        ftbr = 0,       --backscan
        elevation = 0,
    },0.65,true,0.4)
)

--Our old friend Volkhov
--There's enouigh data to closely replicate its functionality, but most of it will be lost on SPO-15
--The scan rate is so high that we basically have to use same trick as for phased array: we pretend it's continous constant gain beam within scan zone

local P_11_13 = RWR_helpers.create_generic({
    --wide beam mode - P-11 and 12 "fanning"
    freq = {4.91,4.99},
    prf = {1766,1915},     --the prf on radartutorial is NOT for the one specific to Volkhov, they are typically listed for general SNR-75, while I found 2 sources listing this for SNR-75V, one Czech and one Russian - I trust those over western sources
    pulse_width = {0.4},
    hpbw = 1.1,
    scan_azimuth_volume = 18.9, --20
    gimbal_limit = 180,
    scan_rate = 604,    --16Hz
    scan_elevation_volume = 0,
    always_emulate_scan_pattern = true,
    always_scan = true,
    scan_only = true,   --special for this: continue normal scan pattern when tracking
    hpbw_vert = 7,
    scan_pattern_type = RWRScanPatternType.Acquisition,
    antenna_pattern_type = RWRPatternType.SincPattern,
    P_max = 500,
    G = 35,

    modes = {
        --narrow beam mode - P-11 and 12 disabled, P-13 and 14 used for scanning instead
        [RWREmitterMode.M1] = {
            conditions = {
                range_gt = 75000
            },
            prf = {883,957},
            pulse_width = {0.8},
            hpbw = 1.7,
            hpbw_vert = 1.7,
            scan_azimuth_volume = 5.8,  --7.5
            scan_rate = 185,    --16Hz
            antenna_pattern_type = RWRPatternType.AiryPattern,
            G = 39
        },
        --LORO  -- P-13/14 centered at boresight and emitting, P-11/12 only receiving
        [RWREmitterMode.M2] = {
            conditions = {
                range_lt = 75000,
                elevation_lt = -5000,
            },
            hpbw = 1.7,
            hpbw_vert = 1.7,
            scan_pattern_type = RWRScanPatternType.Cue,
            scan_time = 5,
            antenna_pattern_type = RWRPatternType.AiryPattern,
            G = 39
        }
    }
})

local P_12_14 = {}
copy_recursive(P_12_14,P_11_13)
P_12_14.freq = {5.01,5.09}
--P_12_14.full_power_vert = P_11_13.full_power_width
--P_12_14.full_power_width = nil
P_12_14.scan_elevation_volume = P_11_13.scan_azimuth_volume
P_12_14.scan_azimuth_volume = 0
P_12_14.hpbw = P_11_13.hpbw_vert
P_12_14.hpbw_vert = P_11_13.hpbw
P_12_14.modes[RWREmitterMode.M1].scan_elevation_volume = P_11_13.modes[RWREmitterMode.M1].scan_azimuth_volume
P_12_14.modes[RWREmitterMode.M1].scan_azimuth_volume = 0
--special parameter for SPO-15 - pulses synchronous from 2 sources, therefore system should see it as a single radar and measure PRF correctly
P_12_14.synced = true

--since the above doesn't really work now (except for missile seekers I guess), here's a workaround for track mode
SNR_75_track = {}
copy_recursive(SNR_75_track,P_11_13)
SNR_75_track.freq = {4.91, 5.09}
SNR_75_track.scan_pattern_type = RWRScanPatternType.AcquisitionCross
SNR_75_track.P_max = 500    --half, it will be doubled in calc if they cross

emission_entry("SNR_75V",
    --azimuth
    P_11_13,
    --elevation
    P_12_14,
    --for track let's just use the horizontal scan
    SNR_75_track
)

--Vega
--surprisingly little data on it despite being obsolete
emission_entry("RPC_5N62V",
    RWR_helpers.create_generic({
        freq = {6.4, 6.8},
        prf = {-1},
        P_max = 3,
        scan_pattern_type = RWRScanPatternType.Cue,
        scan_time = 5,
        antenna_pattern_type = RWRPatternType.SincPattern,
        hpbw = 1.4,
        G = 41,

        modes = {
            --this is actually still CW, but CWillum has a different purpose,
            --narrow beam, long range
            [RWREmitterMode.M1] = {
                conditions = {
                    range_gt = 50000,
                },
                hpbw = 0.7,
                G = 47
            }
        }
    })
)

emission_entry("rapier_fsa_blindfire_radar",
    RWR_helpers.create_tracking({
        freq = {20,40},           
        freq_agility = RWRFreqAgility.Random,   --frequency agile
        freq_agility_interval = 0.001,
        prf = {8000},           --bogus, no data
        P_max = 40,             --bogus, no data
        hpbw = 0.5,             --cassegrain
        hpbw_vert = 1.1
    },0.6,true,0.05)
)

--only optical tracker and search radar on launcher, tracking radar seperate (blindfire)
--without blindfire present there's nothing to suggest lock and launch
emission_entry("rapier_fsa_launcher",
    RWR_helpers.create_surveilence({
        freq = {1,4},
        prf = {4500},           --bogus
        P_max = 10,             --bogus
        hpbw = 3,               --no picture of antenna anywhere even
        full_power_vert = 30,   --3d radar
        scan_rate = 360
    },0.6,true,0.05)
)

local CRAM = {}
copy_recursive(CRAM,RWR_templates.Phalanx)
CRAM.scan_pattern_type = RWRScanPatternType.circular
CRAM.scan_rate = 540
CRAM.always_emulate_scan_pattern = true
CRAM.always_scan = true
CRAM.always_center_pattern = true
CRAM.modes[RWREmitterMode.Scan] = {
    hpbw = 2.5,
    hpbw_vert = 10,
    full_power_vert = 60,
    elevation = 35
}

emission_entry("HEMTT_C-RAM_Phalanx",
    CRAM
)

--S-300 NVO
emission_entry(S300PS_SR_5N66M,
    RWR_templates.LORAD_HOR
)

--S-300 RLO
emission_entry(S300PS_SR_64H6E,
    RWR_templates.LORAD_SR
)

--same radar
clone("S-300PS 40B6MD sr_19J6","RLS_19J6")

--S-300 RPN
emission_entry(S300PS_TR_30N6,
    RWR_templates.LORAD_TR
)

--the other flap lid, not enough data to make it different
clone("S-300PS 5H63C 30H6_tr",S300PS_TR_30N6)

--

emission_entry("SON_9",
    RWR_helpers.create_generic({
        freq = {2.7,2.9},
        prf = {1875},
        pulse_width = {0.5},
        P_max = 250,
        antenna_pattern_type = RWRPatternType.AiryPattern,
        G=30,
        hpbw = 4.9,
        scan_rate = 144,
        scan_pattern_type = RWRScanPatternType.spiral,
        scan_pattern = 10,
        scan_elevation_volume = 45,
        elevation = 2.0,
        always_emulate_scan_pattern = true,
        always_scan = false,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.Lock] = {
                --conscan track
                full_power_vert = 5,
                full_power_width = 5,
            }
        }
    })
)

print("loaded ground")

-------------------------------------
---AIRCRAFT
-------------------------------------

--Viggen
emission_entry("AJS37",
    RWR_helpers.create_generic({
        freq = {8.6,9.5},
        prf = {455,495},
        pulse_width = {2.1},
        prf_agility = RWRFreqAgility.Smooth, --jitter
        prf_agility_interval = 0.1,      --10Hz
        scan_rate = 110,
        hpbw = 8,
        P_max = 200,
        scan_pattern = 1,
        scan_pattern_type = RWRScanPatternType.raster,
        scan_azimuth_volume = 110,
        always_emulate_scan_pattern = true,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {},
            [RWREmitterMode.Lock] = {
                prf = {1880,1920},
                pulse_width = {0.5}
            }
        }

    },0.55)
)

emission_entry("Mirage-F1C",
    RWR_helpers.create_generic({
        freq = {9,9.6},
        prf = {660},
        pulse_width = {2.5},
        antenna_pattern_type = RWRPatternType.AiryWeighed,
        hpbw = 4,
        P_max = 300,
        scan_pattern_type = RWRScanPatternType.raster,
        scan_pattern = 4,
        scan_rate = 95,
        scan_azimuth_volume = 110,
        always_emulate_scan_pattern = true,

        modes = {
            [RWREmitterMode.M2] = {
                conditions = {
                    elevation_gt = 3000 --low alt mode
                },
                prf = {2000},
                pulse_width = {0.5}
            }
        }

    },0.55)
)

emission_entry("Mirage-F1AZ",
    RWR_helpers.create_generic({
        freq = {9,9.6},
        prf = {1200},
        hpbw = 16,
        P_max = 90,
        scan_pattern_type = RWRScanPatternType.Conical,
        antenna_pattern_type = RWRPatternType.AiryPattern,
        scan_rate = 100,
        G = 18,
        always_center_pattern = true,
        always_emulates_scan_pattern = true,
    })
)

clone("Mirage-F1AD","Mirage-F1AZ")
clone("Mirage-F1B","Mirage-F1C")
clone("Mirage-F1BE","Mirage-F1C")
clone("Mirage-F1BD","Mirage-F1C")
clone("Mirage-F1BQ","Mirage-F1C")
clone("Mirage-F1C-200","Mirage-F1C")
clone("Mirage-F1CE","Mirage-F1C")
clone("Mirage-F1CG","Mirage-F1C")
clone("Mirage-F1CH","Mirage-F1C")
clone("Mirage-F1CJ","Mirage-F1C")
clone("Mirage-F1CK","Mirage-F1C")
clone("Mirage-F1CR","Mirage-F1C")
clone("Mirage-F1CT","Mirage-F1C")
clone("Mirage-F1CZ","Mirage-F1C")
clone("Mirage-F1DDA","Mirage-F1C")
clone("Mirage-F1ED","Mirage-F1C")
clone("Mirage-F1EDA","Mirage-F1C")
clone("Mirage-F1EE","Mirage-F1C")
clone("Mirage-F1EH","Mirage-F1C")
clone("Mirage-F1EQ","Mirage-F1C")
clone("Mirage-F1JA","Mirage-F1C")
clone("Mirage-F1M-CE","Mirage-F1C")
clone("Mirage-F1M-EE","Mirage-F1C")

emission_entry("MiG-19P",
    RWR_helpers.create_generic({
        freq = {9.318, 9.41},
        prf = {1985,2125},
        antenna_pattern_type = RWRPatternType.SincPattern,
        hpbw = 4.5,
        hpbw_vert = 11.2,
        scan_rate = 360,
        scan_pattern_type = RWRScanPatternType.raster,
        scan_pattern = 8,
        scan_azimuth_volume = 60,
        scan_elevation_volume = 42,
        elevation = 5,
        always_center_pattern = true,
        always_emulate_scan_pattern = true,
        always_scan = true,
        P_max = 100,
        G = 27,
        
        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {},
            [RWREmitterMode.Lock] = {
                hpbw = 10,
                hpbw_vert = 10,
                antenna_pattern_type = RWRPatternType.AiryPattern,
                G = 23
            },
            [RWREmitterMode.CR] = {
                hpbw = 10,
                hpbw_vert = 10,
                antenna_pattern_type = RWRPatternType.AiryPattern,
                G = 23
            }
        }
    })
)

emission_entry("MiG-21Bis",
    RWR_templates.fighter_gen_2 --this is specifically modelled after MiG-21
)

--AN/APS-145, absolutely impossible to handle for SPO-15 but adding for completeness
emission_entry(E_2C_, 
    RWR_helpers.create_surveilence({
        freq = {0.4,0.45},
        prf = {290,310},      --listed PRF 300, 3 different PRFs simulatenously
        pulse_width = {13},
        prf_agility = RWRFreqAgility.Stagger,
        prf_agility_interval = 0.00333333,
        P_max = 1000,
        hpbw = 7,
        scan_rate = 30,
        hpbw_vert = 20,
        elevation = 0,
        antenna_patter_type = RWRPatternType.SincPattern,       --Yagi antenna array
        ftbr = 20,
        G = 20,
    })    
)  

emission_entry(E_3_,
    RWR_helpers.create_surveilence({
        freq = {2,3},
        prf = {300},    --unknown,
        scan_rate = 36,
        hpbw = 0.9,
        full_power_vert = 30,   --vertical ESA
        elevation = 0,
        P_max = 1000,
    },0.6,true,0.01)
)

--Longbow is definitely undetectable
emission_entry("AH-64D_BLK_II",
    RWR_helpers.create_generic({
        freq = {27,40},
        prf = {9999},
        P_max = 0.2,
        scan_rate = 68.5,
        scan_pattern_type = RWRScanPatternType.raster,
        scan_pattern = 2,
        scan_azimuth_volume = 92.5
    },0.6,0.1)
)

emission_entry("F-86F Sabre",
    RWR_templates.fighter_gen_1
)

clone("F-86F_FC","F-86F Sabre")

local AN_APG_30A = {}
copy_recursive(AN_APG_30A,RWR_templates.fighter_gen_1)
AN_APG_30A.freq = {9.0,9.6}
AN_APG_30A.prf = {800}
AN_APG_30A.P_max = 4

emission_entry("F-100D",
    AN_APG_30A
)

local AN_APQ_153 = RWR_helpers.create_generic({
    freq = {9.15,9.45},
    prf = {2400,2600},
    pulse_width = {0.4},
    prf_agility = RWRFreqAgility.Smooth,
    prf_agility_interval = 0.02,
    antenna_pattern_type = RWRPatternType.AiryWeighed,
    G = 28,
    side_lobe_level = 21,
    ftbr = 23,
    P_max = 60,
    hpbw = 5.2,
    hbbw_vert = 7,
    scan_pattern_type = RWRPatternType.raster,
    scan_elevation_volume = 3,
    scan_azimuth_volume = 85,
    scan_rate = 85,    
})

emission_entry(F_5E_,
    AN_APQ_153
)

local AN_APQ_159 = {}
copy_recursive(AN_APQ_159,AN_APQ_153)
AN_APQ_159.freq = {9.297,9.303}
AN_APQ_159.freq_agility = RWRFreqAgility.Smooth
AN_APQ_159.freq_agility_interval = 0.01
AN_APQ_159.G = 29

emission_entry("F-5E-3",
    AN_APQ_159
)

clone("F-5E-3_FC","F-5E-3")

local AN_APG_63 = RWR_helpers.create_generic({
    freq = {8.5,10.5},
    prf = {300000,310000},
    pulse_width = {1.4},
    --P_max = 12.975,
    P_max = 5,        --estimated based on prime power
    hpbw = 3,
    scan_pattern_type = RWRScanPatternType.raster,
    scan_pattern = 8,
    scan_azimuth_volume = 120,
    scan_rate = 70,
    always_emulate_scan_pattern = true,
    always_center_pattern = true,
    do_not_center_elevation = true,
    
    modes = {
        [RWREmitterMode.Scan] = {},
        [RWREmitterMode.TWS] = {
            scan_pattern = 4,
            scan_azimuth_volume = 60,
            always_center_pattern = false,
        },
        [RWREmitterMode.Lock] = {},
        [RWREmitterMode.CR] = {
            prf = {307000},
        },
        [RWREmitterMode.M1] = {
            conditions = {
                interleved = true,
                modes = {
                    RWREmitterMode.Scan,
                }
            },
            --changed based on SPO-15 docs - they recorded F-15 MPRF mode to be between 10000 and 26000 Hz with pulse width > 5us
            prf = {15000,16000},
            pulse_width = {10.0}
        },
        [RWREmitterMode.M2] = {
            conditions = {
                interleved = true,
                modes = {
                    RWREmitterMode.TWS
                }
            },
            prf = {15000,16000},
            pulse_width = {10.0},
            scan_azimuth_volume = 60,
            scan_pattern = 4,
            always_center_pattern = false
        },
        [RWREmitterMode.M3] = {
            conditions = {
                modes = {RWREmitterMode.Lock},
                range_lt = 84000,
            },
            prf = {15000,16000},
            pulse_width = {10.0},
        },
    }

},0.55)

emission_entry(F_15_,
    AN_APG_63
)

emission_entry(F_15E_,
    AN_APG_63   --actually APG-70, but no data available differentiating the two    
)

clone("F-15ESE",F_15E_)

emission_entry(F_16_,
    RWR_templates.fighter_gen_4     --F-16C radar
)

--both somehow have same wsType?????
clone("F-16C bl.52d", F_16_)
clone("F-16C bl.50d", F_16_)
clone(F_16A_, F_16_)        --obsolete AI unit, used as placeholder for AN/APG-66
clone("F-16C_50", F_16_)

emission_entry("FA-18C_hornet",
    RWR_helpers.create_generic({
        freq = {8.5,10.5},
        prf = {300000,310000},  --same as F-15
        pulse_width = {1.4},
        P_max = 4.5,
        hpbw = 3.3,
        scan_rate = 62.5,
        scan_pattern = 6,
        scan_azimuth_volume = 140,
        always_emulate_scan_pattern = true,
        always_center_pattern = true,
        do_not_center_elevation = true,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {
                always_center_pattern = false,
                scan_pattern = 4,
                scan_azimuth_volume = 60
            },
            [RWREmitterMode.Lock] = {},
            [RWREmitterMode.CR] = {},
            [RWREmitterMode.M1] = {
                conditions = {
                    modes = {RWREmitterMode.CR},
                },
                prf = {307000},
            },
            [RWREmitterMode.M2] = {
                conditions = {
                    modes = {RWREmitterMode.Lock},
                    range_lt = 84000,
                },
                prf = {27000},
                pulse_width = {10},
            },
            [RWREmitterMode.M3] = {
                conditions = {
                    interleved = true,
                    modes = {
                        RWREmitterMode.Scan,
                    },
                },
                prf = {27000},
                pulse_width = {10}
            },
            [RWREmitterMode.M4] = {
                conditions = {
                    interleved = true,
                    modes = {
                        RWREmitterMode.TWS
                    },
                },
                prf = {27000},
                pulse_width = {10},
                scan_azimuth_volume = 60,
                scan_pattern = 4,
                always_center_pattern = false
            },
            [RWREmitterMode.M5] = {
                conditions = {
                    modes = {
                        RWREmitterMode.Scan,
                    },
                    range_gt = 100000,
                    azimuth_lt = 30,
                },
                prf = {300000,310000},
                pulse_width = {1.4},
            },
            [RWREmitterMode.M6] = {
                conditions = {
                    modes = {
                        RWREmitterMode.TWS
                    },
                    range_gt = 100000,
                    azimuth_lt = 30,
                },
                prf = {300000,310000},
                pulse_width = {1.4},
                scan_azimuth_volume = 60,
                scan_pattern = 4,
                always_center_pattern = false
            }
        }
        
    },0.55,0.5)
)

clone(FA_18C_,"FA-18C_hornet")
clone(FA_18_,"FA-18C_hornet")   --stand in

clone("F-14B","F-14A-135-GR")
clone(F_14_,"F-14A-135-GR")

--Chinese cryptid radar
local KLJ_7 = {}
copy_recursive(KLJ_7,RWR_templates.fighter_gen_4)
KLJ_7.prf = {150000}
KLJ_7.pulse_width = {1.5}
KLJ_7.freq = {8,12}
KLJ_7.P_max = 5

emission_entry("JF-17",
    KLJ_7
)

emission_entry("M-2000C",
    --RDI
    RWR_helpers.create_generic({
        freq = {8,12},
        prf = {100000},
        pulse_width = {5},
        P_max = 8,  --assuming average 4
        scan_pattern = 4,
        scan_elevation_volume = 11,
        scan_azimuth_volume = 120,
        scan_rate = 100,
        always_emulate_scan_pattern = true,
        always_center_pattern = true,
        do_not_center_elevation = true,
        hpbw = 3.5,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {
                scan_pattern = 1,
                scan_azimuth_volume = 60,
                scan_rate = 50
            },
            [RWREmitterMode.Lock] = {},
            [RWREmitterMode.CR] = {},
            [RWREmitterMode.M1] = {
                conditions = {
                    interleved = true,
                    modes = {RWREmitterMode.Scan},
                    range_lt = 50000,
                },
                always_center_pattern = false,
                prf = {5000},
                pulse_width = {10},
            },
            [RWREmitterMode.CWillum] ={
                conditions = {
                    modes = {RWREmitterMode.CR}
                },
                prf = {-1}
            }
        }

    },0.7)
)

--Vega Shmel-B
--uncertain data
emission_entry(A_50_,
    RWR_helpers.create_surveilence({
        freq = {0.869, 0.887},
        prf = {224,325},
        prf_agility = RWRFreqAgility.Smooth,
        prf_agility_interval = 0.06,
        hpbw = 2.4,
        hpbw_vert = 30,
        elevation = 15,
        ftbr = 0,
        P_max = 1000,
        scan_rate = 36
        
    },0.5,true,0.001)
)

emission_entry("KJ-2000",
    RWR_helpers.create_surveilence({
        freq = {1,2,1.4},
        prf = {600},
        hpbw = 1.5,
        hpbw_vert = 5,
        scan_pattern_type = RWRScanPatternType.ESA,
        scan_cycle = 0.5,
        scan_period = 1.,
        scan_azimuth_volume = 360,
        scan_elevation_volume = 60,
        elevation = 0,
        P_max = 600,
        always_emulate_scan_pattern = false,
        always_center_pattern = false
    },0.6,true,0.001)
)

--RP-23
--need to collect more data cause it's out there
emission_entry(MiG_23_,
    RWR_helpers.create_generic({
        freq = {12,18},  --Ku band, doubtful as I've seen info suggesting 10GHz instead
        prf = {1000},       --real
        pulse_width = {5.0},    --not real
        hpbw = 2.4,
        antenna_pattern_type = RWRPatternType.AiryPattern,
        P_max = 40,
        G = 36,
        scan_pattern = 6,
        scan_azimuth_volume = 60,
        scan_rate = 60,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {},
            [RWREmitterMode.Lock] = {
                hpbw = 1.7,
                hpbw_vert = 1.7,
                G = 39
            },
            [RWREmitterMode.CR] = {
                prf = {100000},     --quasi continous wave
                hpbw = 1.7,
                hpbw_vert = 1.7,
                G = 39
            },

            [RWREmitterMode.M3] = {
                conditions = {
                    modes = {RWREmitterMode.Scan, RWREmitterMode.Lock},
                    range_lt = 30000,
                },
                prf = {5000},
            }
        }
    })
)

--N-005/Sapfir-25 radar - development of RP-23 radar, replaced the Smerch radar after it was compromised due to defection
--cloned from RP-23 with boosted params, larger antenna etc.

local N_005 = {}
copy_recursive(N_005,find_wstype(MiG_23_).params)
N_005.P_max = 600   --taken from Smerch-A
N_005.hpbw = 3
N_005.hpbw_vert = 3
N_005.G = 35
N_005.scan_azimuth_volume = 120

emission_entry(MiG_25P_,
    N_005
)

--N-019
--radar devs please correct mistakes without asking
emission_entry(MiG_29_,
    RWR_helpers.create_generic({
        freq = {8,12},
        prf = {16393,33333},  --DRB
        pulse_width = {2.1,3.4},
        P_max = 6.5,
        hpbw = 3.5,
        G = 33,
        ftbr = 35,
        scan_pattern = 4,
        scan_azimuth_volume = 57,   --3 60 degree zones, one at a time
        antenna_pattern_type = RWRPatternType.AiryPattern,
        scan_pattern_type = RWRScanPatternType.raster,
        prf_agility = RWRFreqAgility.Random,
        prf_agility_interval = 0.01,
        scan_rate = 57,
        gimbal_limit = 67,
        gimbal_elevation_limit = 60,
        always_emulate_scan_pattern = true,
        do_not_center_elevation = true,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.TWS] = {},
            [RWREmitterMode.Lock] = {
                prf_agility_interval = 0.02
            },
            [RWREmitterMode.CR] = {
                prf_agility_interval = 0.02
            },

            --PPS
            [RWREmitterMode.M1] = {
                conditions = {
                    modes = {
                        RWREmitterMode.Scan,
                        RWREmitterMode.TWS,
                    },
                    range_gt = 10000,     --below that use BMB
                    azimuth_lt = 90,    --forward hemisphere
                },
                prf = {153846,181818},
                pulse_width = {1.77},
                P_max = 6.5,
            },            
            [RWREmitterMode.M2] = {
                conditions = {
                    modes = {
                        RWREmitterMode.Lock,
                    },
                    range_gt = 10000,     --below that use BMB
                    azimuth_lt = 90,    --forward hemisphere
                },
                prf = {153846,181818},
                pulse_width = {1.77},
                prf_agility_interval = 0.02,
                P_max = 3,
            },

            --BMB
            --this only really functions correctly when wings level, which is why I'm not centering scan
            [RWREmitterMode.M3] = {
                conditions = {
                    modes = {
                        RWREmitterMode.Scan,
                        RWREmitterMode.TWS,
                    },
                    range_lt=10000
                },
                prf = {20222,32808},
                pulse_width = {1.7,2.1},
                P_max = 3,
                scan_pattern_type = RWRScanPatternType.Acquisition,
                scan_azimuth_volume = 6,
                scan_elevation_volume = 55,
                elevation = 22.5,
            },
            [RWREmitterMode.M4] = {
                conditions = {
                    modes = {
                        RWREmitterMode.Lock
                    },
                    range_lt=10000
                },
                prf = {20222,32808},
                pulse_width = {1.7,2.1},
                prf_agility_interval = 0.02,
                P_max = 3,
                scan_pattern_type = RWRScanPatternType.Acquisition,
                scan_azimuth_volume = 6,
                scan_elevation_volume = 45,
                elevation = 22.5,
            },
            [RWREmitterMode.M5] = {
                conditions = {
                    modes = {
                        RWREmitterMode.CR
                    },
                    range_lt=10000
                },
                prf = {20222,32808},
                pulse_width = {1.7,2.1},
                prf_agility_interval = 0.05,
                P_max = 3,
                scan_pattern_type = RWRScanPatternType.Acquisition,
                scan_azimuth_volume = 0,
                scan_elevation_volume = 60,
                elevation = 20,
                intermittent = true,                --ICW, 20ms track/30ms illumination
                intermittence_interval = 0.02,
                intermittence_period = 0.05
            },
            [RWREmitterMode.M6] = {
                conditions = {
                    modes = {
                        RWREmitterMode.CR
                    },
                    range_gt = 10000,     --below that use BMB
                    azimuth_lt = 90,    --forward hemisphere
                },
                prf = {153846,181818},
                pulse_width = {1.77},
                prf_agility_interval = 0.05,
                P_max = 3,
                intermittent = true,                --ICW, 20ms track/30ms illumination
                intermittence_interval = 0.02,
                intermittence_period = 0.05
            },
            [RWREmitterMode.M7] = {
                conditions = {
                    modes = {
                        RWREmitterMode.CR
                    },
                    range_gt = 10000,     --below that use BMB
                    azimuth_gt = 90,    --rear hemisphere
                },
                intermittent = true,                --ICW, 20ms track/30ms illumination
                intermittence_interval = 0.02,
                intermittence_period = 0.05
            },
            [RWREmitterMode.CWillum] = {
                conditions = {
                    modes = {
                        RWREmitterMode.CR
                    }
                },
                prf = {-1},
                P_max = 1.8,
                intermittent = true,                --ICW, 20ms track/30ms illumination
                intermittence_interval = 0.03,
                intermittence_offset = 0.02,
                intermittence_period = 0.05
            }
        }

    })
)

clone(MiG_29C_,MiG_29_)
clone(MiG_29G_,MiG_29_)
clone(MIG_29K_,MiG_29_)     --leftover from Flanker 2, leaving just in case
clone("MiG-29 Fulcrum", MiG_29_)

--N-001
--I don't have data at hand so cloning N-008 with increased power for now
--Also applying it to all Flankers, again no data

local N_001 = {}
copy_recursive(N_001,find_wstype(MiG_29_).params)
N_001.P_max = 8
N_001.modes[RWREmitterMode.M1].P_max = 4
N_001.modes[RWREmitterMode.M2].P_max = 4
N_001.modes[RWREmitterMode.M3].P_max = 4
N_001.modes[RWREmitterMode.M4].P_max = 4
N_001.modes[RWREmitterMode.M5].P_max = 4
N_001.modes[RWREmitterMode.M6].P_max = 4

emission_entry(Su_27_,
    N_001
)

clone(Su_33_,Su_27_)
clone(Su_34_,Su_27_)
clone(Su_30_,Su_27_)
clone("J-11A",Su_27_)

-- Obzor-MS, conjecture based on other known airborne maritime surveilence radars
emission_entry("Tu-95MS",
    RWR_helpers.create_generic({
        freq = {8,12},
        prf = {1000},
        pulse_width = {2},
        P_max = 150,
        hpbw = 2,
        elevation = -10,
        scan_rate = 7.5,
        scan_pattern = 10,
        scan_azimuth_volume = 60,
        scan_pattern_type = RWRScanPatternType.raster,
        antenna_pattern_type = RWRPatternType.SincPattern,
        always_emulate_scan_pattern = true,
        always_center_pattern = true,
        do_not_center_elevation = false        
    },0.5)
)

print("loaded aircraft")

--------------------------------------------
---WEAPONS
--------------------------------------------
--Phoenix is already done, everything else there's no data on
--clone HB phoenix into old phoenix
clone(AIM_54_,"AIM_54A_Mk47")

print("loaded phoenix")

emission_entry(AIM_120_,
    RWR_templates.AMRAAM
)

clone(AIM_120C_,AIM_120_)

local r_77 = {}
copy_recursive(r_77,RWR_templates.AMRAAM)
r_77.modes = nil

print("loading R77")
emission_entry(P_77_,r_77)
print("loaded R77")

emission_entry("SD-10",RWR_templates.AMRAAM)
emission_entry("PL-12",RWR_templates.AMRAAM)

print("loaded weapons")

--Chinese asset pack
--Search freqs from wrong Fregat (MR-700/710 instead of MR-750 that is actually installed)
--What is even that X band thing, I guess Buk search
--no freqs on tracking radars, no lock warning for Buk unless I create some special workarounds, and I shouldn't need to, they should just
--add the frequency for Buk track, listed as 6-9GHz in our database (or can just be set to same as search, 8-12) but not sure if that's right, not a problem either way as long as _something_ is there

--Fregat/Type 382, converted to a single radar
local MR_750_freq_change = {}
copy_recursive(MR_750_freq_change,RWR_templates.MR_750.params)
MR_750_freq_change.freq = {2.0,2.5}
MR_750_freq_change.elevation = 0
MR_750_freq_change.full_power_vert = 100
MR_750_freq_change.ftbr = 0

local Buk_mod = {}
copy_recursive(Buk_mod,find_wstype(Buk_LN_9A310M1).params)
Buk_mod.freq = {8.,12.}
Buk_mod.scan_azimuth_volume = 360
Buk_mod.always_emulate_scan_pattern = false

emission_entry("Type_052B",
    MR_750_freq_change,
    Buk_mod
)

emission_entry("Type_052A",
    MR_750_freq_change,
    Buk_mod
)

--Type 346 (Dragon's eyes)
--wrong freqs
--should be 3-3.4GHz scan, 5.25-5.95 track
--there should be track to begin with
--also different SAM so X band is also wrong
--there's the UHF frequency error from Sea Sparrow defs listed as HQ-9 track
--absolutely no data on Mineral/Type 366 radar whatsoever, treating as generic track
local Type_346 = {}
copy_recursive(Type_346,RWR_templates.AN_SPY_1)
Type_346.freq = {2,3}

emission_entry("Type_052C",
    Type_346,
    Buk_mod,
    RWR_helpers.create_tracking({
        freq = {0.5,0.58},
        prf = {60000},
        P_max = 20
    },0.6,true,0.25)
)

--Search radar wasn't listed for this one
--Tracking is cloned from Bass Tilt
emission_entry("Type_071",
    RWR_templates.MR_123
)

--HQ-7
--Chinese copy of Crotale, which is a French copy of Osa :)
--there's good data on Type 345/Castor
--not much info on the acquisition radar

emission_entry("HQ-7_STR_SP",
    RWR_helpers.create_surveilence({
        freq = {6,10},
        prf = {1600},
        P_max = 40,
        hpbw = 2,
        full_power_vert = 30,
        elevation = 15,
        scan_rate = 360,
        always_emulate_scan_pattern = true
    },0.6,true,0.01)
)

emission_entry("HQ-7_LN_P",
    RWR_helpers.create_tracking({
        freq = {10,20},
        prf = {3600},
        pulse_width = {7.5},
        P_max = 30,
        hpbw = 1.1,

        modes = {
            [RWREmitterMode.Lock] = {},
            [RWREmitterMode.CR] = {},

            [RWREmitterMode.M3] = {
                conditions = {
                    range_lt = 20000,
                },
                prf = {7200}
            }
        }
    },0.6,true)
)

--Silkworm MYS-M1/MR-10M1
--Based on the original MR-10/MYS, which MYS-M1 is a development of, as no data on the latter

emission_entry("Silkworm_SR",
    RWR_helpers.create_surveilence({
        freq = {8.945,9.775},    --should be gap at 9.450-9.540
        prf = {520,590},
        pulse_width = {0.2,0.45,0.7},
        P_max = 150,
        G = 42,
        hpbw = 0.8,
        elevation = 0,
        scan_rate = 36,

        modes = {
            [RWREmitterMode.Scan] = {},
            [RWREmitterMode.M1] = {
                conditions = {interleved = true},
                prf = {1024,1584}   --should skip 1415-1456
            }
        }
    })
)

--CurrentHill

--Pantsir
emission_entry("CHAP_PantsirS1",
    RWR_templates._2RL80,
    RWR_templates._1RS2_1
)

--Tor M2
emission_entry("CHAP_TorM2",
    RWR_templates.Tor_M2.params,
    RWR_templates.Tor_M2.params1
)

--Project 22160
emission_entry("CHAP_Project22160",
    RWR_templates.Positiv_ME1
)

emission_entry("CHAP_Project22160_TorM2KM",
    RWR_templates.Positiv_ME1,
    RWR_templates.Tor_M2.params,
    RWR_templates.Tor_M2.params1
)

--Iris-T SLM
emission_entry("CHAP_IRISTSLM_STR",
    RWR_templates.TRML_4D
)

--Grisha
emission_entry("ALBATROS",
    RWR_templates.Osa_M.search,
    RWR_templates.MR_320,
    RWR_templates.Don,
    RWR_templates.Osa_M.track,
    RWR_templates.MR_123
)

print("loaded database")