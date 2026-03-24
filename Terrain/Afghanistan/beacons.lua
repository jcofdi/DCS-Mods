dofile('Scripts/Database/wsTypes.lua')
dofile('Scripts/World/Radio/BeaconTypes.lua')
dofile('Scripts/World/Radio/BeaconSites.lua')

local disableNauticalBeacons = true

local gettext = require("i_18n")
local       _ = gettext.translate

--WORLD BEACONS

beaconsTableFormat = 2
beacons = {
	{
		display_name = _('Gilgit');
		beaconId = 'world_0';
		type = BEACON_TYPE_HOMER;
		callsign = 'GT';
		frequency = 324000.000000;
		position = { 275356.375000, 1501.198279, 724554.375000 };
		direction = 0.000000;
		positionGeo = { latitude = 35.920161, longitude = 74.335056 };
		sceneObjects = {'t:198565888'};
	};
	{
		display_name = _('Peshawar');
		beaconId = 'world_1';
		type = BEACON_TYPE_HOMER;
		callsign = 'PS';
		frequency = 308000.000000;
		position = { 34247.132813, 362.502071, 486223.156250 };
		direction = 0.000000;
		positionGeo = { latitude = 33.990832, longitude = 71.502676 };
		sceneObjects = {'t:152207360'};
	};
	{
		display_name = _('Dushanbe');
		beaconId = 'world_2';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'DNB';
		frequency = 113600000.000000;
		channel = 83;
		position = { 522297.000000, 783.979178, 206445.625000 };
		direction = 0.000000;
		positionGeo = { latitude = 38.541666, longitude = 68.810835 };
		sceneObjects = {'t:75579392'};
	};
	{
		display_name = _('Dangara');
		beaconId = 'world_3';
		type = BEACON_TYPE_DME;
		callsign = 'DNR';
		frequency = 114100000.000000;
		channel = 88;
		position = { 493697.375000, 2240.370893, 244412.796875 };
		direction = 0.000000;
		positionGeo = { latitude = 38.263064, longitude = 69.221936 };
		sceneObjects = {'t:198598656'};
	};
	{
		display_name = _('Zahedan');
		beaconId = 'world_4';
		type = BEACON_TYPE_TACAN;
		callsign = 'ZAH';
		channel = 76;
		position = { -498489.875000, 1380.413734, -503357.687500 };
		direction = 0.000000;
		positionGeo = { latitude = 29.463496, longitude = 60.904502 };
		sceneObjects = {'t:75792384'};
	};
	{
		display_name = _('Muzaffarabad');
		beaconId = 'world_5';
		type = BEACON_TYPE_HOMER;
		callsign = 'MF';
		frequency = 207000.000000;
		position = { 90862.835938, 857.354983, 668182.875000 };
		direction = 0.000000;
		positionGeo = { latitude = 34.342169, longitude = 73.506678 };
		sceneObjects = {'t:176324608'};
	};
	{
		display_name = _('Quetta');
		beaconId = 'world_6';
		type = BEACON_TYPE_HOMER;
		callsign = 'QT';
		frequency = 348000.000000;
		position = { -408321.937500, 1622.380162, 79958.632813 };
		direction = 0.000000;
		positionGeo = { latitude = 30.234162, longitude = 66.948841 };
		sceneObjects = {'t:76587008'};
	};
	{
		display_name = _('Zhob');
		beaconId = 'world_7';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'ZB';
		frequency = 115700000.000000;
		channel = 104;
		position = { -272512.875000, 1424.894491, 314842.875000 };
		direction = 0.000000;
		positionGeo = { latitude = 31.355997, longitude = 69.459835 };
		sceneObjects = {'t:20054016'};
	};
	{
		display_name = _('Zhob');
		beaconId = 'world_8';
		type = BEACON_TYPE_HOMER;
		callsign = 'ZB';
		frequency = 245000.000000;
		position = { -272558.437500, 1418.343581, 314382.843750 };
		direction = 0.000000;
		positionGeo = { latitude = 31.355832, longitude = 69.455001 };
		sceneObjects = {'t:87760896'};
	};
	{
		display_name = _('Fayzobod');
		beaconId = 'world_9';
		type = BEACON_TYPE_HOMER;
		callsign = 'JD';
		frequency = 475000.000000;
		position = { 525448.812500, 1240.024311, 250323.937500 };
		direction = 0.000000;
		positionGeo = { latitude = 38.543889, longitude = 69.313893 };
		sceneObjects = {'t:75587584'};
	};
	{
		display_name = _('Multan');
		beaconId = 'world_10';
		type = BEACON_TYPE_HOMER;
		callsign = 'MT';
		frequency = 387000.000000;
		position = { -389283.937500, 116.827853, 511112.875000 };
		direction = 0.000000;
		positionGeo = { latitude = 30.194000, longitude = 71.412838 };
		sceneObjects = {'t:76742656'};
	};
	{
		display_name = _('Murgab');
		beaconId = 'world_11';
		type = BEACON_TYPE_DME;
		callsign = 'MRB';
		frequency = 114700000.000000;
		channel = 94;
		position = { 515444.437500, 3731.097725, 711176.250000 };
		direction = 0.000000;
		positionGeo = { latitude = 38.055823, longitude = 74.509189 };
		sceneObjects = {'t:198606848'};
	};
	{
		display_name = _('DeraGhaziKhan');
		beaconId = 'world_12';
		type = BEACON_TYPE_HOMER;
		callsign = 'DG';
		frequency = 322000.000000;
		position = { -421351.843750, 143.595419, 423588.031250 };
		direction = 0.000000;
		positionGeo = { latitude = 29.962166, longitude = 70.490336 };
		sceneObjects = {'t:76316672'};
	};
	{
		display_name = _('Zahedan');
		beaconId = 'world_13';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'ZDN';
		frequency = 116000000.000000;
		channel = 107;
		position = { -495900.593750, 1380.387245, -503582.625000 };
		direction = 0.000000;
		positionGeo = { latitude = 29.486813, longitude = 60.901703 };
		sceneObjects = {'t:12664832'};
	};
	{
		display_name = _('Sheikhupura');
		beaconId = 'world_14';
		type = BEACON_TYPE_HOMER;
		callsign = 'SP';
		frequency = 317000.000000;
		position = { -199279.515625, 200.821704, 745003.187500 };
		direction = 0.000000;
		positionGeo = { latitude = 31.700671, longitude = 73.999003 };
		sceneObjects = {'t:107577344'};
	};
	{
		display_name = _('DIKhan');
		beaconId = 'world_15';
		type = BEACON_TYPE_HOMER;
		callsign = 'DI';
		frequency = 286000.000000;
		position = { -202061.671875, 180.598081, 446745.093750 };
		direction = 0.000000;
		positionGeo = { latitude = 31.908665, longitude = 70.888507 };
		sceneObjects = {'t:106340352'};
	};
	{
		display_name = _('Bahawalpur');
		beaconId = 'world_16';
		type = BEACON_TYPE_HOMER;
		callsign = 'BW';
		frequency = 332000.000000;
		position = { -481199.687500, 120.571097, 546989.250000 };
		direction = 0.000000;
		positionGeo = { latitude = 29.349814, longitude = 71.709538 };
		sceneObjects = {'t:75907072'};
	};
	{
		display_name = _('DIKhan');
		beaconId = 'world_17';
		type = BEACON_TYPE_VOR;
		callsign = 'DI';
		frequency = 113100000.000000;
		position = { -201636.328125, 181.405485, 446443.875000 };
		direction = 0.000000;
		positionGeo = { latitude = 31.912663, longitude = 70.885678 };
		sceneObjects = {'t:239738880'};
	};
	{
		display_name = _('Parachinar');
		beaconId = 'world_18';
		type = BEACON_TYPE_HOMER;
		callsign = 'PC';
		frequency = 273000.000000;
		position = { 14604.761719, 1753.387984, 354334.093750 };
		direction = 0.000000;
		positionGeo = { latitude = 33.905337, longitude = 70.072498 };
		sceneObjects = {'t:147685376'};
	};
	{
		display_name = _('Sarakhs');
		beaconId = 'world_19';
		type = BEACON_TYPE_DME;
		callsign = 'SRS';
		frequency = 334000000.000000;
		channel = 108;
		position = { 280958.343750, 282.276070, -472632.406250 };
		direction = 0.000000;
		positionGeo = { latitude = 36.495338, longitude = 61.074234 };
		sceneObjects = {'t:75554816'};
	};
	{
		display_name = _('Peshawar');
		beaconId = 'world_20';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'PS';
		frequency = 114300000.000000;
		channel = 90;
		position = { 32948.062500, 367.733827, 487670.312500 };
		direction = 0.000000;
		positionGeo = { latitude = 33.978165, longitude = 71.517007 };
		sceneObjects = {'t:53854208'};
	};
	{
		display_name = _('Termez');
		beaconId = 'world_21';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'TRZ';
		frequency = 113400000.000000;
		channel = 81;
		position = { 375763.125000, 303.455565, 82670.476563 };
		direction = 0.000000;
		positionGeo = { latitude = 37.286652, longitude = 67.317681 };
		sceneObjects = {'t:198574080'};
	};
	{
		display_name = _('Faisalabad');
		beaconId = 'world_22';
		type = BEACON_TYPE_HOMER;
		callsign = 'FA';
		frequency = 212000.000000;
		position = { -245498.062500, 176.809961, 652547.375000 };
		direction = 0.000000;
		positionGeo = { latitude = 31.370168, longitude = 72.995010 };
		sceneObjects = {'t:98574336'};
	};
	{
		display_name = _('Multan');
		beaconId = 'world_23';
		type = BEACON_TYPE_VOR;
		callsign = 'MT';
		frequency = 116700000.000000;
		position = { -389260.187500, 117.147097, 511435.625000 };
		direction = 0.000000;
		positionGeo = { latitude = 30.193997, longitude = 71.416173 };
		sceneObjects = {'t:13279232'};
	};
	{
		display_name = _('Islamabad');
		beaconId = 'world_24';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'BTR';
		frequency = 114600000.000000;
		channel = 93;
		position = { -4186.831055, 517.477996, 616622.625000 };
		direction = 0.000000;
		positionGeo = { latitude = 33.544359, longitude = 72.855992 };
		sceneObjects = {'t:50061312'};
	};
	{
		display_name = _('Rawalakot');
		beaconId = 'world_25';
		type = BEACON_TYPE_HOMER;
		callsign = 'RT';
		frequency = 295000.000000;
		position = { 38526.230469, 1667.292195, 701158.187500 };
		direction = 0.000000;
		positionGeo = { latitude = 33.847499, longitude = 73.799178 };
		sceneObjects = {'t:153862144'};
	};
	{
		display_name = _('Bokhtar');
		beaconId = 'world_26';
		type = BEACON_TYPE_DME;
		callsign = 'KTB';
		frequency = 114500000.000000;
		channel = 92;
		position = { 446822.250000, 444.872576, 215714.968750 };
		direction = 0.000000;
		positionGeo = { latitude = 37.859725, longitude = 68.861943 };
		sceneObjects = {'t:198582272'};
	};
	{
		display_name = _('Islamabad');
		beaconId = 'world_27';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'RN';
		frequency = 112100000.000000;
		channel = 58;
		position = { 5143.359375, 481.959772, 641159.562500 };
		direction = 0.000000;
		positionGeo = { latitude = 33.605998, longitude = 73.126008 };
		sceneObjects = {'t:50069504'};
	};
	{
		display_name = _('Oktyabrskiy');
		beaconId = 'world_28';
		type = BEACON_TYPE_HOMER;
		callsign = 'PR';
		frequency = 310000.000000;
		position = { 519644.593750, 814.739950, 170145.734375 };
		direction = 0.000000;
		positionGeo = { latitude = 38.537777, longitude = 68.394456 };
		sceneObjects = {'t:75571200'};
	};
	{
		display_name = _('Kulob');
		beaconId = 'world_29';
		type = BEACON_TYPE_DME;
		callsign = 'KLB';
		frequency = 114400000.000000;
		channel = 91;
		position = { 466323.687500, 666.079890, 297485.437500 };
		direction = 0.000000;
		positionGeo = { latitude = 37.984459, longitude = 69.801663 };
		sceneObjects = {'t:198590464'};
	};
	{
		display_name = _('Zahedan');
		beaconId = 'world_30';
		type = BEACON_TYPE_HOMER;
		callsign = 'ZD';
		frequency = 224000.000000;
		position = { -497645.250000, 1382.203042, -504145.875000 };
		direction = 0.000000;
		positionGeo = { latitude = 29.470986, longitude = 60.896222 };
		sceneObjects = {'t:1089536'};
	};
	{
		display_name = _('SaiduSharif');
		beaconId = 'world_31';
		type = BEACON_TYPE_HOMER;
		callsign = 'SS';
		frequency = 357000.000000;
		position = { 131308.703125, 924.486337, 556450.937500 };
		direction = 0.000000;
		positionGeo = { latitude = 34.800011, longitude = 72.350008 };
		sceneObjects = {'t:186531840'};
	};
	{
		display_name = _('Islamabad');
		beaconId = 'world_32';
		type = BEACON_TYPE_HOMER;
		callsign = 'RN';
		frequency = 344000.000000;
		position = { 5563.279785, 494.703009, 639449.875000 };
		direction = 0.000000;
		positionGeo = { latitude = 33.611225, longitude = 73.108306 };
		sceneObjects = {'t:146767872'};
	};
	{
		display_name = _('Quetta');
		beaconId = 'world_33';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'QT';
		frequency = 114700000.000000;
		channel = 94;
		position = { -405738.843750, 1577.186147, 78631.234375 };
		direction = 0.000000;
		positionGeo = { latitude = 30.257832, longitude = 66.936007 };
		sceneObjects = {'t:13164544'};
	};
	{
		display_name = _('Kerki');
		beaconId = 'world_34';
		type = BEACON_TYPE_HOMER;
		callsign = 'FK';
		frequency = 469000.000000;
		position = { 430757.906250, 241.243237, -112873.062500 };
		direction = 0.000000;
		positionGeo = { latitude = 37.841960, longitude = 65.128378 };
		sceneObjects = {'t:12566528'};
	};
	{
		display_name = _('Zabol');
		beaconId = 'world_35';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'ZAL';
		frequency = 113000000.000000;
		channel = 78;
		position = { -318556.968750, 481.838922, -439222.500000 };
		direction = 0.000000;
		positionGeo = { latitude = 31.095501, longitude = 61.541844 };
		sceneObjects = {'t:14868480'};
	};
	{
		display_name = _('Kerki');
		beaconId = 'world_36';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'LBK';
		frequency = 109400000.000000;
		position = { 426136.312500, 242.258375, -111459.382813 };
		direction = 0.000000;
		positionGeo = { latitude = 37.800043, longitude = 65.143229 };
		sceneObjects = {'t:75563008'};
	};
	{
		display_name = _('Bastion');
		beaconId = 'airfield10_0';
		type = BEACON_TYPE_HOMER;
		callsign = 'BS';
		frequency = 423000.000000;
		position = { -236424.949032, 881.606350, -184781.809115 };
		direction = 91.745389;
		positionGeo = { latitude = 31.838947, longitude = 64.219237 };
		sceneObjects = {'t:27463212'};
	};
	{
		display_name = _('Bastion');
		beaconId = 'airfield10_1';
		type = BEACON_TYPE_TACAN;
		callsign = 'BAS';
		frequency = 115100000.000000;
		channel = 98;
		position = { -237491.296875, 878.830835, -184979.390625 };
		direction = 80.602872;
		positionGeo = { latitude = 31.829349, longitude = 64.217023 };
		sceneObjects = {'t:99504243'};
	};
	{
		display_name = _('Dwyer');
		beaconId = 'airfield11_0';
		type = BEACON_TYPE_TACAN;
		callsign = 'ADY';
		channel = 46;
		position = { -319576.807674, 733.406434, -198382.794916 };
		direction = 0.000000;
		positionGeo = { latitude = 31.090132, longitude = 64.066980 };
		sceneObjects = {'t:79763134'};
	};
	{
		display_name = _('Herat');
		beaconId = 'airfield1_0';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'AHR';
		frequency = 116200000.000000;
		channel = 109;
		position = { 25702.060547, 981.070561, -370818.312500 };
		direction = -82.043522;
		positionGeo = { latitude = 34.206865, longitude = 62.232903 };
		sceneObjects = {'t:51445955'};
	};
	{
		display_name = _('Herat');
		beaconId = 'airfield1_1';
		type = BEACON_TYPE_HOMER;
		callsign = 'HRT';
		frequency = 412000.000000;
		position = { 26196.265625, 979.957523, -370938.437500 };
		direction = 3.518190;
		positionGeo = { latitude = 34.211313, longitude = 62.231559 };
		sceneObjects = {'t:149046385'};
	};
	{
		display_name = _('Herat');
		beaconId = 'airfield1_2';
		type = BEACON_TYPE_TACAN;
		callsign = 'HRT';
		channel = 54;
		position = { 25756.282565, 987.023692, -371485.461879 };
		direction = 0.000000;
		positionGeo = { latitude = 34.207308, longitude = 62.225658 };
		sceneObjects = {'t:149022741'};
	};
	{
		display_name = _('Kandahar');
		beaconId = 'airfield7_0';
		type = BEACON_TYPE_TACAN;
		callsign = 'KAF';
		channel = 75;
		position = { -270488.187500, 1013.227759, -29608.345703 };
		direction = 0.000000;
		positionGeo = { latitude = 31.505738, longitude = 65.848514 };
		sceneObjects = {'t:87393804'};
	};
	{
		display_name = _('Kandahar');
		beaconId = 'airfield7_1';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'KDR';
		frequency = 116000000.000000;
		channel = 107;
		position = { -271821.750000, 1004.766203, -31793.058594 };
		direction = 0.000000;
		positionGeo = { latitude = 31.494230, longitude = 65.825174 };
		sceneObjects = {'t:19851063'};
	};
	{
		display_name = _('Shindand');
		beaconId = 'airfield3_0';
		type = BEACON_TYPE_TACAN;
		callsign = 'ASD';
		frequency = 111100000.000000;
		channel = 48;
		position = { -64795.556518, 1141.461713, -368775.301799 };
		direction = 1.076984;
		positionGeo = { latitude = 33.390852, longitude = 62.262116 };
		sceneObjects = {'t:132633549'};
	};
	{
		display_name = _('Bagram');
		beaconId = 'airfield16_0';
		type = BEACON_TYPE_VORTAC;
		callsign = 'BGM';
		frequency = 112700000.000000;
		channel = 74;
		position = { 125892.367188, 1492.001248, 272874.718750 };
		direction = 93.105642;
		positionGeo = { latitude = 34.950386, longitude = 69.271494 };
		sceneObjects = {'t:342394105'};
	};
	{
		display_name = _('Kabul');
		beaconId = 'airfield17_0';
		type = BEACON_TYPE_VOR_DME;
		callsign = 'KBL';
		frequency = 112000000.000000;
		channel = 57;
		position = { 81018.583527, 1780.179881, 277427.106402 };
		direction = -72.150241;
		positionGeo = { latitude = 34.545599, longitude = 69.290360 };
		sceneObjects = {'t:60525328'};
	};
	{
		display_name = _('Kabul');
		beaconId = 'airfield17_1';
		type = BEACON_TYPE_TACAN;
		callsign = 'OKB';
		frequency = 133800000.000000;
		channel = 65;
		position = { 82799.523338, 1789.001911, 269528.308446 };
		direction = -158.829562;
		positionGeo = { latitude = 34.565961, longitude = 69.205973 };
		sceneObjects = {'t:173082663'};
	};
}
