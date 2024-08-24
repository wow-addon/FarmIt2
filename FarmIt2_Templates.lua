--------------------------------------------------------------------------------
--  ITEM BAR TEMPLATES
--[[

These are the default item templates that FarmIt includes.
Items are grouped by the part of the game in which they are obtained.
To add your own: set up a bar in-game, then use the following commands:
  
  /farmit tpl list
  /farmit tpl save {bar#} name
  /farmit tpl load {bar#} name
  /farmit tpl delete name
  /farmit tpl rename name newname
  
Note: To simplify input parsing, spaces are not allowed in custom template names.

--------------------------------------------------------------------------------

-- primary professions
Alchemy
Blacksmithing
Enchanting
Engineering
Herbalism
Inscription
Jewelcrafting
Leatherworking
Mining
Skinning
Tailoring

-- secondary professions
Archaeology
Cooking
FirstAid
Fishing

-- other
Elemental
Lockboxes

]]
--------------------------------------------------------------------------------

FI_TPL = {};

-- categories
FI_TPL.Templates = {
  ["WOW"] = {},
  ["TBC"] = {},
  ["WOTLK"] = {},
  ["CATA"] = {},
  ["WOD"] = {},
  ["PANDA"] = {},
  ["LEGION"] = {},
  ["BFA"] = {},
  ["SL"] = {},
  ["DF"] = {},
  ["TWW"] = {},
}

-- list order
FI_TPL.Order = {
  [1] = "WOW",
  [2] = "TBC",
  [3] = "WOTLK",
  [4] = "CATA",
  [5] = "WOD",
  [6] = "PANDA",
  [7] = "LEGION",
  [8] = "BFA",
  [9] = "SL",
  [10] = "DF",
  [11] = "TWW"
}

--------------------------------------------------------------------------------
--  GATHERING
--------------------------------------------------------------------------------

-- Mining
FI_TPL.Templates.WOW.Ore = {2770,2771,2775,2772,2776,3858,7911,11370,10620}
FI_TPL.Templates.TBC.Ore = {23424,23425,23426,23427}
FI_TPL.Templates.WOTLK.Ore = {36909,36912,36910}
FI_TPL.Templates.CATA.Ore = {53038,52185,52183}
-- Missing Templates since Patch 5.0 @med0rian
FI_TPL.Templates.PANDA.Ore = {72092,72093,72094,72103}
FI_TPL.Templates.WOD.Ore = {109118,109119,115508}
FI_TPL.Templates.LEGION.Ore = {123918,123919,124444,151564}
FI_TPL.Templates.BFA.Ore = {152512,152513,152579,168185}
FI_TPL.Templates.SL.Ore = {171828,171829,171830,171831,171832,171833,187700}
FI_TPL.Templates.DF.OreTier1 = {190395,190312,189143} -- Tier 1 Ores
FI_TPL.Templates.DF.OreTier2 = {190396,190313,188658} -- Tier 2 Ores
FI_TPL.Templates.DF.OreTier3 = {190394,190314,190311} -- Tier 3 Ores
FI_TPL.Templates.DF.Elements = {190315,190320,190322,190326,190328,190330} --Elements

-- Herbalism
FI_TPL.Templates.WOW.Herbs = {2447,765,785,2449,2450,2452,2453,3820,3369,3355,3356,3357,3818,3821,3358,3819}
FI_TPL.Templates.WOW.Herbs2 = {8153,4625,8831,8836,8838,8839,8845,8846,13464,13463,13465,13466,13467,13468,19726}
FI_TPL.Templates.TBC.Herbs = {22785,22786,22789,22787,22790,22791,22792,22793,22794}
FI_TPL.Templates.WOTLK.Herbs = {36901,37921,36904,36907,36903,36905,36906,36908}
FI_TPL.Templates.CATA.Herbs = {52983,52984,52985,52986,52988,52987,52989}
-- Missing Templates since Patch 5.0 @med0rian
FI_TPL.Templates.PANDA.Herbs = {79010,79011,72234,72235,72237,72238}
FI_TPL.Templates.WOD.Herbs = {109124,109125,109126,109127,109128,109129,116053}
FI_TPL.Templates.LEGION.Herbs = {124101,124102,124103,124104,124105,124106,128304,151565}
FI_TPL.Templates.BFA.Herbs = {152505,152506,152507,152508,152509,152510,152511,168487}
FI_TPL.Templates.SL.Herbs = {168583,168586,168589,169701,170554,171315,187699}
FI_TPL.Templates.DF.HerbsTier1 = {191460,191464,191467,191470} -- Tier 1 Herbs
FI_TPL.Templates.DF.HerbsTier2 = {191461,191465,191468,191471} -- Tier 2 Herbs
FI_TPL.Templates.DF.HerbsTier3 = {191462,191466,191469,191472} -- Tier 3 Herbs

-- Skinning
FI_TPL.Templates.WOW.Skin = {2934,2318,783,5082,2319,4232,4234,4235,8167,4304,8169,8154,8165,15415,15412,15416,8170,8171}
FI_TPL.Templates.WOW.Skin2 = {15419,15417,15408,20500,20501,20498,15414,29547,29539,25700,19767,19768,25699,17012,15410}
FI_TPL.Templates.TBC.Skin = {25649,21887,25708,25707}
FI_TPL.Templates.WOTLK.Skin = {33567,33568,38557,38561,38558,44128}
FI_TPL.Templates.CATA.Skin = {52977,52976,52979,52982,52980}
-- Missing Templates since Patch 5.0 @med0rian
FI_TPL.Templates.PANDA.Skin = {72120,72163,79101}
FI_TPL.Templates.WOD.Skin = {110609}
FI_TPL.Templates.LEGION.Skin = {124113,124115,124116,151566}
FI_TPL.Templates.BFA.Skin = {152541,154722,153050,153051,154164,155465,168649,168650}
FI_TPL.Templates.SL.Skin = {172089,172092,172094,172096,172097,177279,187701}
FI_TPL.Templates.DF.SkinTier1 = {193208,193213,193216,193222} -- Tier 1 Lether
FI_TPL.Templates.DF.SkinTier2 = {193210,193214,193217,193223} -- Tier 2 Lether
FI_TPL.Templates.DF.SkinTier3 = {193211,193215,193218,193224} -- Tier 3 Lether

-- Fishing
FI_TPL.Templates.WOW.Fish = {4603,6289,6291,6303,6308,6317,6361}
FI_TPL.Templates.WOW.Fish2 = {6362,6522,8365,13754,13755,13756,13758}
FI_TPL.Templates.WOW.Fish3 = {13760,13888,13889,13893,21071,21153}
FI_TPL.Templates.TBC.Fish = {27422,27425,27429,27435,27437,27438}
FI_TPL.Templates.TBC.Fish2 = {27439,27515,27516,33823,33824}
FI_TPL.Templates.WOTLK.Fish = {41801,41802,41803,41805,41806,41807}
FI_TPL.Templates.WOTLK.Fish2 = {41808,41809,41810,41812,41813}
FI_TPL.Templates.CATA.Fish = {53062,53063,53064,53065,53066,53067,53068,53069,53070,53071,53072}
-- Missing Templates since Patch 5.0 @med0rian
FI_TPL.Templates.PANDA.Fish = {74856,74857,74859,74860,74861,74863,74864,74865,74866}
FI_TPL.Templates.WOD.Fish = {111671,111676,111647,111664,111673,111669,111668,111667,111675,111672,111670,111666,111665,111663,111595,111601}
FI_TPL.Templates.WOD.Fish2 = {111650,111651,111652,111656,111658,111659,111662,111589,124669}
FI_TPL.Templates.LEGION.Fish = {124107,124109,124112,124111,124110,124108,133607}
FI_TPL.Templates.BFA.Fish = {152543,152544,152545,152546,152547,152548,152549,168302,168646,174327,174328}
FI_TPL.Templates.SL.Fish = {173032,173033,173034,173035,173036,173037,187702}
FI_TPL.Templates.DF.Fish = {200061,194730,194967,194966,194968,194969,194970}

-- Archaeology
FI_TPL.Templates.WOW.Arch = {52843,63127,63128,64392,64394,64395,64396,64397}

--------------------------------------------------------------------------------
--  CRAFTING
--------------------------------------------------------------------------------

-- Alchemy
--FI_TPL.Templates.WOW.Alch = {}
--FI_TPL.Templates.TBC.Alch = {}
--FI_TPL.Templates.WOTLK.Alch = {}
--FI_TPL.Templates.CATA.Alch = {}

-- Blacksmithing
FI_TPL.Templates.WOW.BS = {2840,3576,2841,2842,3859,3575}
FI_TPL.Templates.WOW.BS2 = {3577,2860,6037,12359,12655,11371}
FI_TPL.Templates.TBC.BS = {23445,22967,23446,23447,23448,23449,46353,23573}
FI_TPL.Templates.WOTLK.BS = {36916,36913,41163,37663}
FI_TPL.Templates.CATA.BS = {54849,52186,53039,51950,58480}

-- Cooking
--FI_TPL.Templates.WOW.Cook = {}
--FI_TPL.Templates.TBC.Cook = {}
--FI_TPL.Templates.WOTLK.Cook = {}
--FI_TPL.Templates.CATA.Cook = {}

-- Enchanting
FI_TPL.Templates.WOW.Ench = {10940,10938,10998,10978,10939,11083,11082}
FI_TPL.Templates.WOW.Ench2 = {11084,11138,11134,11135,11137,11139,11174}
FI_TPL.Templates.WOW.Ench3 = {11177,11175,11176,11178,16202,16204,16203,14344,20725}
FI_TPL.Templates.TBC.Ench = {22445,22447,22446,22449,22448,22450}
FI_TPL.Templates.WOTLK.Ench = {34054,34056,34055,34052,34053,34057}
FI_TPL.Templates.CATA.Ench = {52722,52721,52720,52719,52718,52555}

-- Engineering
--FI_TPL.Templates.WOW.Engi = {}
--FI_TPL.Templates.TBC.Engi = {}
--FI_TPL.Templates.WOTLK.Engi = {}
--FI_TPL.Templates.CATA.Engi = {}

-- Inscription
FI_TPL.Templates.WOW.Ink = {39151,37101,39469,39334,39774,43103,43115,39338,43116,43104,43117}
FI_TPL.Templates.WOW.Ink2 = {39339,43118,43105,43119,39340,43120,43106,43121,39341,43122,43107,43123}
FI_TPL.Templates.TBC.Ink = {39342,43124,43108,43125}
FI_TPL.Templates.WOTLK.Ink = {39343,43126,43109,43127}
FI_TPL.Templates.CATA.Ink = {61979,61978,61980,61981}

-- Jewelcrafting
FI_TPL.Templates.WOW.JC = {774,818,1210,1206,1705,1529,3864}
FI_TPL.Templates.WOW.JC2 = {7910,7909,12799,12800,12361,12364,12363}
FI_TPL.Templates.WOW.JC3 = {25868,25867,41266,41334,52303,42225,52196}
FI_TPL.Templates.TBC.JC = {23117,23079,21929,23107,23077,23112}
FI_TPL.Templates.TBC.JC2 = {23438,23437,23439,23441,23436,23440}
FI_TPL.Templates.TBC.JC3 = {32228,32249,32231,32230,32227,32229}
FI_TPL.Templates.WOTLK.JC = {36923,36932,36929,36926,36917,36920}
FI_TPL.Templates.WOTLK.JC2 = {36924,36933,36930,36927,36918,36921}
FI_TPL.Templates.WOTLK.JC3 = {36925,36934,36931,36928,36929,36922}
FI_TPL.Templates.CATA.JC = {52177,52178,52179,52180,52181,52182}
FI_TPL.Templates.CATA.JC2 = {52190,52191,52192,52193,52194,52195}
FI_TPL.Templates.CATA.JC3 = {71805,71806,71807,71808,71809,71810}

-- Leatherworking
-- (see Skinning)

-- Tailoring
FI_TPL.Templates.WOW.Cloth = {2589,2996,2592,2997,4306,4305,4338,4339,14047,14048,14256,14342}
FI_TPL.Templates.TBC.Cloth = {21877,21840,21842,21844,24271,24272,21845}
FI_TPL.Templates.WOTLK.Cloth = {33470,41510,41511,41595,41593,41594}
FI_TPL.Templates.CATA.Cloth = {53010,53643,54440}

--------------------------------------------------------------------------------
--  MISC
--------------------------------------------------------------------------------

-- Elemental
FI_TPL.Templates.WOW.Ele = {7078,7076,12803,7080,12808,7082}
FI_TPL.Templates.TBC.Ele = {22572,22573,22574,22575,22576,22577,22578}
FI_TPL.Templates.TBC.Ele2 = {22452,21884,21885,22451,22457,22456,21886,23571,23572}
FI_TPL.Templates.WOTLK.Ele = {37700,37701,37702,37703,37704,37705}
FI_TPL.Templates.WOTLK.Ele2 = {35624,36860,35622,35623,35627,35625,40248}
FI_TPL.Templates.CATA.Ele = {52327,52328,52325,52326,52329}

-- Lockboxes
FI_TPL.Templates.WOW.Lockbox = {4632,4633,4634,4636,4637}
FI_TPL.Templates.WOW.Lockbox2 = {4638,5758,5759,5760,31952}
FI_TPL.Templates.WOW.Lockbox3 = {43622,45986,43624,68729}

-- Pickpocket
FI_TPL.Templates.WOW.Pickpocket = {16882,16883,16884,16885,29569,43575,63349}
