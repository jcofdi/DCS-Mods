dofile('Scripts/World/Radio/ModulationTypes.lua')
dofile('Scripts/World/Radio/FrequencyBands.lua')

local gettext = require("i_18n")
local       _ = gettext.translate

--WORLD RADIO

radioTableFormat = 3
radio = {
	{
		-- Bost
		radioId = 'airfield8_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OABT"), "OABT"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4050000.000000}, [UHF] = {MODULATIONTYPE_AM, 243000000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 131250000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39000000.000000}};
		sceneObjects = {'t:2498799'};
	};
	{
		-- Camp_Bastion
		radioId = 'airfield10_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAZI"), "OAZI"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3900000.000000}, [UHF] = {MODULATIONTYPE_AM, 250100000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 123300000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38700000.000000}};
		sceneObjects = {'t:99504519'};
	};
	{
		-- Camp_Bastion_Heli
		radioId = 'airfield13_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAZI Heli"), "OAZI Heli"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4100000.000000}, [UHF] = {MODULATIONTYPE_AM, 250200000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118200000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39100000.000000}};
		sceneObjects = {'t:228549114'};
	};
	{
		-- Chaghcharan
		radioId = 'airfield5_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("CTAF"), "CTAF"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3825000.000000}, [UHF] = {MODULATIONTYPE_AM, 250050000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118000000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38550000.000000}};
		sceneObjects = {'t:8668532'};
	};
	{
		-- Dwyer
		radioId = 'airfield11_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("YARDBIRD"), "YARDBIRD"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3775000.000000}, [UHF] = {MODULATIONTYPE_AM, 343000000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 121750000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38450000.000000}};
		sceneObjects = {'t:1515632'};
	};
	{
		-- Farah
		radioId = 'airfield2_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAFR"), "OAFR"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3975000.000000}, [UHF] = {MODULATIONTYPE_AM, 250300000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118100000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38850000.000000}};
		sceneObjects = {'t:4770825'};
	};
	{
		-- Herat
		radioId = 'airfield1_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAHR"), "OAHR"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3750000.000000}, [UHF] = {MODULATIONTYPE_AM, 240300000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 123350000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38400000.000000}};
		sceneObjects = {'t:7882204'};
	};
	{
		-- Kandahar
		radioId = 'airfield7_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAKN"), "OAKN"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4025000.000000}, [UHF] = {MODULATIONTYPE_AM, 360200000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 125500000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38950000.000000}};
		sceneObjects = {'t:3004269'};
	};
	{
		-- Kandahar_Heli
		radioId = 'airfield15_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAKN Heli"), "OAKN Heli"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3950000.000000}, [UHF] = {MODULATIONTYPE_AM, 300200000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 119500000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38800000.000000}};
		sceneObjects = {'t:89599269'};
	};
	{
		-- Maymana_Zahiraddin_Faryabi
		radioId = 'airfield4_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAMN"), "OAMN"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3875000.000000}, [UHF] = {MODULATIONTYPE_AM, 250150000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118150000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38650000.000000}};
		sceneObjects = {'t:12250030'};
	};
	{
		-- Nimroz
		radioId = 'airfield12_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OANZ"), "OANZ"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3850000.000000}, [UHF] = {MODULATIONTYPE_AM, 250000000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118050000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38600000.000000}};
		sceneObjects = {'t:1409034'};
	};
	{
		-- Qala_i_Naw
		radioId = 'airfield6_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAQN"), "OAQN"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4000000.000000}, [UHF] = {MODULATIONTYPE_AM, 250350000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118350000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38900000.000000}};
		sceneObjects = {'t:10005909'};
	};
	{
		-- Shindand
		radioId = 'airfield3_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OASD"), "OASD"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3800000.000000}, [UHF] = {MODULATIONTYPE_AM, 265650000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 134750000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38500000.000000}};
		sceneObjects = {'t:42533259'};
	};
	{
		-- Shindand_Heli
		radioId = 'airfield14_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OASD Heliport"), "OASD Heliport"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 3925000.000000}, [UHF] = {MODULATIONTYPE_AM, 344000000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 121500000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 38750000.000000}};
		sceneObjects = {'t:132743746'};
	};
	{
		-- Tarinkot
		radioId = 'airfield9_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OATN"), "OATN"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4075000.000000}, [UHF] = {MODULATIONTYPE_AM, 250400000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 128000000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39050000.000000}};
		sceneObjects = {'t:118051597'};
	};
	{
		-- Bagram
		radioId = 'airfield16_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAIX"), "OAIX"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4125000.000000}, [UHF] = {MODULATIONTYPE_AM, 325750000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 120100000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39150000.000000}};
		sceneObjects = {'t:10677363'};
	};
	{
		-- Bamyan
		radioId = 'airfield18_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OABN"), "OABN"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4325000.000000}, [UHF] = {MODULATIONTYPE_AM, 250650000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118550000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39550000.000000}};
		sceneObjects = {'t:10147285'};
	};
	{
		-- FOB_Salerno
		radioId = 'airfield23_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OASL Salerno"), "OASL Salerno"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4275000.000000}, [UHF] = {MODULATIONTYPE_AM, 243000000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 121500000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39450000.000000}};
		sceneObjects = {'t:7242178'};
	};
	{
		-- Gardez
		radioId = 'airfield20_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAGZ"), "OAGZ"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4350000.000000}, [UHF] = {MODULATIONTYPE_AM, 250700000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118600000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39600000.000000}};
		sceneObjects = {'t:7472921'};
	};
	{
		-- Ghazni_Heliport
		radioId = 'airfield21_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAGN"), "OAGN"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4300000.000000}, [UHF] = {MODULATIONTYPE_AM, 250550000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118450000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39500000.000000}};
		sceneObjects = {'t:139545100'};
	};
	{
		-- Jalalabad
		radioId = 'airfield19_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAJL"), "OAJL"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4250000.000000}, [UHF] = {MODULATIONTYPE_AM, 231000000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 129700000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39400000.000000}};
		sceneObjects = {'t:9373703'};
	};
	{
		-- Kabul
		radioId = 'airfield17_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OAKB"), "OAKB"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4200000.000000}, [UHF] = {MODULATIONTYPE_AM, 284250000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 120600000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39300000.000000}};
		sceneObjects = {'t:173068259'};
	};
	{
		-- Khost_Dirt_Airfield
		radioId = 'airfield25_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("KHTD"), "KHTD"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4225000.000000}, [UHF] = {MODULATIONTYPE_AM, 250500000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118400000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39350000.000000}};
		sceneObjects = {'t:6792195'};
	};
	{
		-- Sharana
		radioId = 'airfield22_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("OASA"), "OASA"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4175000.000000}, [UHF] = {MODULATIONTYPE_AM, 250450000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118300000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39250000.000000}};
		sceneObjects = {'t:273457232'};
	};
	{
		-- Urgoon_Heliport
		radioId = 'airfield24_0';
		role = {"ground", "tower", "approach"};
		callsign = {{["common"] = {_("URGHelli"), "URGHelli"}}};
		frequency = {[HF] = {MODULATIONTYPE_AM, 4150000.000000}, [UHF] = {MODULATIONTYPE_AM, 250250000.000000}, [VHF_HI] = {MODULATIONTYPE_AM, 118250000.000000}, [VHF_LOW] = {MODULATIONTYPE_AM, 39200000.000000}};
		sceneObjects = {'t:5985224'};
	};
}
