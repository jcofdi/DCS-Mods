dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_SAM.lua')
dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_Airplane.lua')
dofile('Scripts/Aircrafts/_Common/Cockpit/wsTypes_Ship.lua')

DefaultType          = 100
DEFAULT_TYPE_ = {DefaultType, DefaultType, DefaultType, DefaultType}

local SPO_15_types = 
{
    P = 1,
    Z = 2,
    H = 3,
    N = 4,
    F = 5,
    S = 6
}

local RWREmitterMode = {
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

--The order of this list determines the priority when generating threat memory for SPO-15
--In case two or more threats have overlapping signal paramenter bins, the signal that appears first on this list is recorded into database, and remaining ones will be omitted
--this allows for accurate simulation of mis-identification of types due to low signal parameter measurement resolution while still ensuring the most serious threats are accurately identified
--it is imperative that this list is sorted in a logical manner, with more important threats above the less important ones
--this DOES NOT correspond to SPO-15's internal priority logic - as that takes into account factors like radar range, azimuth etc., while this list only takes into account presence in mission
--this DOES NOT affect manually prepared threat databases
--general rule of thumb: newer systems first, within same generation priority is aircraft > LORAD > SHORAD, then adjust based on feedback - if an important threat is often omitted from database in typical DCS scenarios, move it up this list
--ONLY RADAR SETS EXPLICITLY INCLUDED BOTH IN THIS LIST AND IN analgog_RWR_data WILL BE INCLUDED IN THE DATABASE, radar sets using generic params will not be included and will either be unclassified by SPO-15 or falsely classified as another type (which is usually going to be a reasonable ID anyway due to how the types are group, as long as this list makes sense)

--each entry in this list contains either name ("name" field) or wsType ("type" field) of the threat (only the one it was listed under in analog_RWR_data is needed) and the SPO-15 threat type ("symbol" field) to be recorded as.
--optionally it can also include a "mode" field containing a table of modes to be included in this entry (see analog_RWR_data) or "freq" field in case of units with multiple radar systems - in either case, only the radars and modes included will be used while other modes and radars will be omitted if their parameters are different, otherwise the sum of parameters from ALL modes and radars will be used to generate the entry
--The general logic for type assignment is:
--P - all SARH fire control radars with a CWI channel ACTIVE
--In particular, this type is _automatically_ assigned to colocated CW illuminator and S-type radar.
--It should not be assigned manually in this list except for exceptional cases - just make sure the corresponding PD radar is high enough in this list to be recorded
--Z - Anything below or equal 15km effective range and 8km effective altitude, or otherwise classified as SHORAD or MERAD, that uses PD radar set. This type is, in principle, dedicated to all AD types other than Hawk and Nike
--H - continuous wave search and track radars. This type is primarily reserved for Hawk, and again should not really be used for any other purposes, un
--N - LORAD. This type is, in principle, dedicated to Nike-Hercules, which is not modelled in game. It was also used for Patriot, however Patriot might be easily misidentified due to HPRF signal. As a rule of thumb, all radar sytems with performance compareable to or exceeding Nike-Hercules and Patriot should be included here - this includes S-300 and S-200 if automatic DB is used
--F - HPRF fighter radars. This type is, in principle, dedicated to "F-type" 4th generation US fighters, in particular F-14 and F-15, but any HPRF signal will usually be caught in here unless it simultanously has a long pulsewidth to be differentiated by, or a carrier frequency lower than ~7GHz, otherwise it will be mis-IDed as type F. All 4th gen fighters should thus be included in here
--S - LPRF fighter radars and all SARH fire control radars with a CWI channel disabled. Most 3rd gen and older fighters go in here, together with radar sets that are deemed necessary to include here, but cannot be classified as anything else (such as search radars that fall within SPO-15's detection params)
--In principle, this type and P type should correspond to the same threats depending on wheather or not they are running in a mode that allows SARH missile support, and aren't classified under any other type already
--For some threats, a sudden type switch from S to P can be treated as a launch warning

spo_15_symbols = 
{
    --CW
    {
        type = Hawk_CWAR_ANMPQ_55,
        symbol = SPO_15_types.H
    },

    {
        type = Hawk_TR_ANMPQ_46,
        symbol = SPO_15_types.H
    },

    {
        name = "RPC_5N62V",
        symbol = SPO_15_types.H
    },
    --

    {
        name = "F-4E-45MC",
        symbol = SPO_15_types.P
    },
    {
        type = F_4E_,
        symbol = SPO_15_types.P
    },
    {
        type = F_14_,
        modes = {RWREmitterMode.M1, RWREmitterMode.M2, RWREmitterMode.M3},
        symbol = SPO_15_types.P
    },
    {
        name = "F-14A-135-GR",
        modes = {RWREmitterMode.M1, RWREmitterMode.M2, RWREmitterMode.M3},
        symbol = SPO_15_types.P
    },
    {
        name = "F-14B",
        modes = {RWREmitterMode.M1, RWREmitterMode.M2, RWREmitterMode.M3},
        symbol = SPO_15_types.P
    },
    {
        name = "Mirage-F1C",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1AZ",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1AD",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1B",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1BE",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1BD",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1BQ",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1C-200",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CE",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CG",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CH",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CJ",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CK",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CR",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CR",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CT",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1CZ",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1DDA",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1ED",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1EDA",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1EE",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1EH",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1EQ",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1JA",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1M-CE",
        symbol = SPO_15_types.S
    },
    {
        name = "Mirage-F1M-EE",
        symbol = SPO_15_types.S
    },
    {
        type = F_5E_,
        symbol = SPO_15_types.S
    },
    {
        name = "F-5E-3",
        symbol = SPO_15_types.S
    },
    {
        name = "F-5E-3_FC",
        symbol = SPO_15_types.S
    },
    {
        name = "AJS37",
        symbol = SPO_15_types.S
    },
    {
        name = "MiG-21Bis",
        symbol = SPO_15_types.S
    },
    {
        name = "F-100D",
        symbol = SPO_15_types.S
    },
    {
        name = "MiG-19P",
        symbol = SPO_15_types.S
    },
    {
        name = "F-86F Sabre",
        symbol = SPO_15_types.S
    },
    {
        name = "F-86F_FC",
        symbol = SPO_15_types.S
    },
    --deliberately putting here so m/lprf modes don't occlude anything above (as the HPRF mode will be detected anyway)
    {
        type = F_15_,
        symbol = SPO_15_types.F
    },
    {
        type = F_15E_,
        symbol = SPO_15_types.F
    },
    {
        name = "F-15ESE",
        symbol = SPO_15_types.F
    },
    {
        type = F_16_,
        symbol = SPO_15_types.F
    },
    {
        name = "F-16C bl.52d",
        symbol = SPO_15_types.F
    },
    {
        name = "F-16C bl.50d",
        symbol = SPO_15_types.F
    },
    {
        name = "F-16C_50",
        symbol = SPO_15_types.F
    },
    {
        type = F_16A_,
        symbol = SPO_15_types.F
    },
    {
        type = FA_18C_,
        symbol = SPO_15_types.F
    },
    {
        name = "FA-18C_hornet",
        symbol = SPO_15_types.F
    },
    {
        type = FA_18_,
        symbol = SPO_15_types.F
    },
    {
        name = "F-14A-135-GR",
        modes = {RWREmitterMode.M5,RWREmitterMode.M6},
        symbol = SPO_15_types.F
    },
    {
        name = "F-14B",
        modes = {RWREmitterMode.M5,RWREmitterMode.M6},
        symbol = SPO_15_types.F
    },
    {
        type = F_14_,
        modes = {RWREmitterMode.M5,RWREmitterMode.M6},
        symbol = SPO_15_types.F
    },
    {
        name = "JF-17",
        symbol = SPO_15_types.F
    },
    {
        name = "M-2000C",
        symbol = SPO_15_types.F
    },
    --yes, these belong in type F
    {
        type = Su_27_,
        symbol = SPO_15_types.F
    },
    {
        type = Su_33_,
        symbol = SPO_15_types.F
    },
    {
        type = Su_34_,
        symbol = SPO_15_types.F
    },
    {
        type = Su_30_,
        symbol = SPO_15_types.F
    },
    {
        name = "J-11A",
        symbol = SPO_15_types.F
    },
    {
        name = "MiG-29 Fulcrum",
        symbol = SPO_15_types.F
    },
    {
        type = MiG_29_,
        symbol = SPO_15_types.F
    },
    {
        type = MiG_29C_,
        symbol = SPO_15_types.F
    },
    {
        type = MiG_29G_,
        symbol = SPO_15_types.F
    },
    {
        type = MIG_29K_,
        symbol = SPO_15_types.F
    },
    --putting all the way down here because of quasi-continous SARH illimunation
    --it would probably be differentiated by pulse width but keeping it here just in case
    --also unlikely to be detected due to Ku band
    {
        type = MiG_23_,
        symbol = SPO_15_types.S
    },
    {
        type = MiG_25P_,
        symbol = SPO_15_types.S
    },
    {
        type = Patriot_STR_ANMPQ_53,
        symbol = SPO_15_types.N
    },
    {
        type = S300PS_TR_30N6,
        symbol = SPO_15_types.N,
    },
    {
        name = "S-300PS 5H63C 30H6_tr",
        symbol = SPO_15_types.N
    },
    {
        type = S300PS_SR_64H6E,
        symbol = SPO_15_types.N,
        range = 120000,
        max_alt = 120000,
    },
    --this is also at the bottom as S type
    --we differentiate based on whether or not these are expected as a part of SAM site
    {
        name = "S-300PS 40B6MD sr_19J6",
        symbol = SPO_15_types.N,
        range = 120000,
        max_alt = 120000,
    },
    {
        name = "SNR_75V",
        symbol = SPO_15_types.N
    },
    {
        type = Roland_rdr,
        symbol = SPO_15_types.Z,
        range = 12000,
        max_alt = 6000
    },
    {
        type = Roland_ADS,
        symbol = SPO_15_types.Z
    },
    {
        name = "rapier_fsa_blindfire_radar",
        symbol = SPO_15_types.Z
    },
    {
        name = "rapier_fsa_launcher",
        symbol = SPO_15_types.Z
    },
    {
        type = Kub_STR_9S91,
        symbol = SPO_15_types.P
    },
    {
        type = Buk_LN_9A310M1,
        symbol = SPO_15_types.P
    },
    {
        type = Buk_SR_9S18M1,
        symbol = SPO_15_types.S,
        range = 50000,
        max_alt = 22000
    },
    {
        name = "NASAMS_Radar_MPQ64F1",
        symbol = SPO_15_types.Z,
        range = 15000,
        max_alt = 15000
    },
    {
        type = Tor_9A331,
        symbol = SPO_15_types.Z
    },
    {
        name = "CHAP_TorM2",
        symbol = SPO_15_types.Z
    },
    {
        type = S125_TR_SNR,
        symbol = SPO_15_types.Z
    },
    {
        type = Osa_9A33,
        symbol = SPO_15_types.Z
    },
    {
        name = "HQ-7_LN_P",
        symbol = SPO_15_types.Z
    },
    {
        name = "HQ-7_STR_SP",
        symbol = SPO_15_types.Z
    },
    {
        type = Vulcan_M163,
        symbol = SPO_15_types.Z
    },
    {
        type = Gepard,
        symbol = SPO_15_types.Z
    },
    {
        name = "CHAP_IRISTSLM_STR",
        symbol = SPO_15_types.N
    },
    {
        name = "HEMTT_C-RAM_Phalanx",
        symbol = SPO_15_types.Z
    },
    {
        name = "SON_9",
        symbol = SPO_15_types.Z,
        range = 15000,
        max_alt = 15000
    },
    {
        type = Tunguska_2S6,
        symbol = SPO_15_types.Z
    },    
    {
        name = "CHAP_PantsirS1",
        symbol = SPO_15_types.Z
    },
    {
        type = ZSU_23_4_Shilka,
        symbol = SPO_15_types.Z
    },
    {
        type = Dog_Ear,
        symbol = SPO_15_types.Z,
        range = 8000,
        max_alt = 3500
    },
    {
        type = Kuznecow_,
        symbol = SPO_15_types.Z
    },
    {
        type = PERRY_,
        symbol = SPO_15_types.P
    },
    {
        type = TICONDEROGA_,
        symbol = SPO_15_types.P
    },
    {
        name = "USS_Arleigh_Burke_IIa",
        symbol = SPO_15_types.P
    },
    {
        type = ALBATROS_,
        symbol = SPO_15_types.Z
    },
    {
        name = "ALBATROS",
        symbol = SPO_15_types.Z
    },
    {
        name = "CVN_71",
        symbol = SPO_15_types.S
    },
    {
        name = "CVN_72",
        symbol = SPO_15_types.S
    },
    {
        name = "CVN_73",
        symbol = SPO_15_types.S
    },
    {
        name = "CVN_74",
        symbol = SPO_15_types.S
    },
    {
        name = "CVN_75",
        symbol = SPO_15_types.S
    },
    {
        type = SKORY_,
        symbol = SPO_15_types.N
    },
    {
        type = MOSCOW_,
        symbol = SPO_15_types.N        
    },
    {
        name = "Type_052C",
        symbol = SPO_15_types.N
    },
    {
        type = Kuznecow_,
        symbol = SPO_15_types.Z
    },    
    {
        name = "CV_1143_5",
        symbol = SPO_15_types.Z
    },
    {
        type = MOLNIYA_,
        symbol = SPO_15_types.S
    },
    {
        type = NEUSTRASH_,
        symbol = SPO_15_types.Z
    },
    {
        type = REZKY_,
        symbol = SPO_15_types.Z
    },
    {
        name = "BDK-775",
        symbol = SPO_15_types.Z
    },
	{
        name = "La_Combattante_II",
        symbol = SPO_15_types.Z
    },
    {
        name = "Type_052B",
        symbol = SPO_15_types.S
    },
    {
        name = "Type_052A",
        symbol = SPO_15_types.S
    },
    {
        name = "Forrestal",
        symbol = SPO_15_types.P
    },
    {
        name = "LHA_Tarawa",
        symbol = SPO_15_types.S
    },
    {
        name = "leander-gun-achilles",
        symbol = SPO_15_types.S
    },
    {
        name = "leander-gun-ariadne",
        symbol = SPO_15_types.S
    },
    {
        name = "leander-gun-andromeda",
        symbol = SPO_15_types.S
    },
    {
        name = "leander-gun-condell",
        symbol = SPO_15_types.S
    },
    {
        name = "leander-gun-lynch",
        symbol = SPO_15_types.S
    },
    {
        name = "ara_vdm",
        symbol = SPO_15_types.S
    },
    {
        name = "hms_invincible",
        symbol = SPO_15_types.S
    },
    {
        name = "Type_071",
        symbol = SPO_15_types.Z
    },
    {
        name = "CHAP_Project22160_TorM2KM",
        symbol = SPO_15_types.Z
    },
	{
        name = "CHAP_Project22160",
        symbol = SPO_15_types.Z
    },
    {
        name = "AH-64D_BLK_II",
        symbol = SPO_15_types.S
    },
    {
        type = E_2C_,
        symbol = SPO_15_types.S
    },
    {
        type = E_3_,
        symbol = SPO_15_types.S
    },
    {
        type = A_50_,
        symbol = SPO_15_types.S
    },
    {
        name = "Tu-95MS",
        symbol = SPO_15_types.S
    },
    {
        name = "KJ-2000",
        symbol = SPO_15_types.S
    },
    {
        type = EWR_1L13_,
        symbol = SPO_15_types.S
    },
    {
        type = EWR_55G6_,
        symbol = SPO_15_types.S
    },
    {
        type = S125_SR_P_19,
        symbol = SPO_15_types.S
    },
    {
        name = "FPS-117",
        symbol = SPO_15_types.S
    },
    {
        name = "FPS-117 Dome",
        symbol = SPO_15_types.S
    },
    {
        name = "RLS_19J6",
        symbol = SPO_15_types.S
    },

}