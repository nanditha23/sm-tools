--[[
Model - Tour time of day for other tour
Type - MNL
Authors - Siyu Li, Harish Loganathan
]]

-- require statements do not work with C++. They need to be commented. The order in which lua files are loaded must be explicitly controlled in C++. 
-- require "Logit"

--Estimated values for all betas
--Note: the betas that not estimated are fixed to zero.

local beta_ARR_2_3 = 0.00378 
local beta_ARR_2_2 = 0.148
local beta_ARR_2_1 = -0.111 
local beta_ARR_2_7 = 0.0257 
local beta_ARR_2_6 = -0.0509 
local beta_ARR_2_5 = -0.216 
local beta_ARR_2_4 = 0.0680 
local beta_DEP_2_8 = 0.0194 
local beta_C = -0.212
local beta_ARR_2_8 = -0.00634 
local beta_DEP_2_1 = -0.118 
local beta_DEP_2_3 = -0.0309 
local beta_DEP_2_2 = -0.178 
local beta_DEP_2_5 = -0.389 
local beta_DEP_1_8 = 0.217
local beta_DEP_2_7 = -0.00251 
local beta_DEP_2_6 = 0.00742 
local beta_DEP_1_2 = -0.472 
local beta_TT1 = -2.68
local beta_TT2 = -1.28
local beta_DEP_1_6 = -0.443
local beta_DEP_1_7 = 0.00338 
local beta_DEP_1_4 = -0.221
local beta_DEP_1_5 = 0.773
local beta_ARR_1_8 = -0.00315 
local beta_DEP_1_3 = -0.567
local beta_DEP_1_1 = -0.318 
local beta_ARR_1_4 = 0.155
local beta_ARR_1_5 = -2.77 
local beta_ARR_1_6 = -0.166
local beta_ARR_1_7 = 0.252
local beta_ARR_1_1 = -0.943 
local beta_ARR_1_2 = -1.81 
local beta_ARR_1_3 = -0.273 
local beta_DUR_1 = 0.00618
local beta_DUR_2 = -0.0831 
local beta_DUR_3 = 0.00390 
local beta_DEP_2_4 = 0.00894

local k = 3
local n = 4
local ps = 3
local pi = math.pi

local Begin={}
local End={}
local choiceset={}
local arrmidpoint = {}
local depmidpoint = {}

for i =1,48 do
	Begin[i] = i
	End[i] = i
	arrmidpoint[i] = i * 0.5 + 2.75
	depmidpoint[i] = i * 0.5 + 2.75
end

for i = 1,1176 do
	choiceset[i] = i
end

local comb = {}
local count = 0

for i=1,48 do
	for j=1,48 do
		if j>=i then
			count=count+1
			comb[count]={i,j}
		end
	end
end

local function sarr_1(t)
	return beta_ARR_1_1 * math.sin(2*pi*t/24.) + beta_ARR_1_5 * math.cos(2*pi*t/24.) + beta_ARR_1_2 * math.sin(4*pi*t/24.) + beta_ARR_1_6 * math.cos(4*pi*t/24.) + beta_ARR_1_3 * math.sin(6*pi*t/24.) + beta_ARR_1_7 * math.cos(6*pi*t/24.) + beta_ARR_1_4 * math.sin(8*pi*t/24.) + beta_ARR_1_8 * math.cos(8*pi*t/24.)
end

local function sdep_1(t)
	return beta_DEP_1_1 * math.sin(2*pi*t/24.) + beta_DEP_1_5 * math.cos(2*pi*t/24.) + beta_DEP_1_2 * math.sin(4*pi*t/24.) + beta_DEP_1_6 * math.cos(4*pi*t/24.) + beta_DEP_1_3 * math.sin(6*pi*t/24.) + beta_DEP_1_7 * math.cos(6*pi*t/24.) + beta_DEP_1_4 * math.sin(8*pi*t/24.) + beta_DEP_1_8 * math.cos(8*pi*t/24.)
end

local function sarr_2(t)
	return beta_ARR_2_1 * math.sin(2*pi*t/24.) + beta_ARR_2_5 * math.cos(2*pi*t/24.) + beta_ARR_2_2 * math.sin(4*pi*t/24.) + beta_ARR_2_6 * math.cos(4*pi*t/24.) + beta_ARR_2_3 * math.sin(6*pi*t/24.) + beta_ARR_2_7 * math.cos(6*pi*t/24.) + beta_ARR_2_4 * math.sin(8*pi*t/24.) + beta_ARR_2_8 * math.cos(8*pi*t/24.)
end

local function sdep_2(t)
	return beta_DEP_2_1 * math.sin(2*pi*t/24.) + beta_DEP_2_5 * math.cos(2*pi*t/24.) + beta_DEP_2_2 * math.sin(4*pi*t/24.) + beta_DEP_2_6 * math.cos(4*pi*t/24.) + beta_DEP_2_3 * math.sin(6*pi*t/24.) + beta_DEP_2_7 * math.cos(6*pi*t/24.) + beta_DEP_2_4 * math.sin(8*pi*t/24.) + beta_DEP_2_8 * math.cos(8*pi*t/24.)
end

local utility = {}
local function computeUtilities(params,dbparams) 
	--local person_type_id = params.person_type_id 
	-- gender in this model is the same as female_dummy
	local gender = params.female_dummy
	local cbd_dummy =dbparams.cbd_dummy
	local cbd_dummy_origin = dbparams.cbd_dummy_origin
	-- work time flexibility 1 for fixed hour, 2 for flexible hour
	--local worktime = params.worktime	
	local AMOD_cost = 3
	local pow = math.pow

	local cost_HT1_am = dbparams.cost_HT1_am + (cbd_dummy * AMOD_cost + cbd_dummy_origin * (1-cbd_dummy)* AMOD_cost)*0.5
	local cost_HT1_pm = dbparams.cost_HT1_pm + (cbd_dummy * AMOD_cost + cbd_dummy_origin * (1-cbd_dummy)* AMOD_cost)*0.5
	local cost_HT1_op = dbparams.cost_HT1_op + (cbd_dummy * AMOD_cost + cbd_dummy_origin * (1-cbd_dummy)* AMOD_cost)*0.5
	local cost_HT2_am = dbparams.cost_HT2_am + (cbd_dummy * AMOD_cost + cbd_dummy_origin * (1-cbd_dummy)* AMOD_cost)*0.5
	local cost_HT2_pm = dbparams.cost_HT2_pm + (cbd_dummy * AMOD_cost + cbd_dummy_origin * (1-cbd_dummy)* AMOD_cost)*0.5
	local cost_HT2_op = dbparams.cost_HT2_op + (cbd_dummy * AMOD_cost + cbd_dummy_origin * (1-cbd_dummy)* AMOD_cost)*0.5

	for i = 1,1176 do
		local arrid = comb[i][1]
		local depid = comb[i][2]
		local arr = arrmidpoint[arrid]
		local dep = depmidpoint[depid]
		local dur = dep - arr
		local arr_am = 0
		local arr_pm = 0
		local arr_op = 0
		local dep_am = 0
		local dep_pm = 0
		local dep_op = 0

		if arr<9.5 and arr>7.5 then
			arr_am, arr_pm, arr_op = 1, 0, 0
		elseif arr < 19.5 and arr > 17.5 then
			arr_am, arr_pm, arr_op = 0, 1, 0
		else
			arr_am, arr_pm, arr_op = 0, 0, 1
		end

		if dep <9.5 and dep >7.5 then 
			dep_am, dep_pm, dep_op = 1, 0, 0
		elseif dep<19.5 and dep > 17.5 then 
			dep_am, dep_pm, dep_op = 0, 1, 0
		else
			dep_am, dep_pm, dep_op = 0, 0, 1
		end
		utility[i] = sarr_1(arr) + sdep_1(dep) + gender * (sarr_2(arr) + sdep_2(dep)) + beta_DUR_1 * dur + beta_DUR_2 * pow(dur,2) + beta_DUR_3 * pow(dur,3) + beta_TT1 * dbparams:TT_HT1(arrid) + beta_TT2 * dbparams:TT_HT2(depid) + beta_C * (cost_HT1_am * arr_am + cost_HT1_pm * arr_pm + cost_HT1_op * arr_op + cost_HT2_am * dep_am + cost_HT2_pm * dep_pm + cost_HT2_op * dep_op)
	end
end

--availability
--the logic to determine availability is the same with current implementation
local availability = {}
local function computeAvailabilities(params,dbparams)
	for i = 1, 1176 do 
		availability[i] = params:getTimeWindowAvailabilityTour(i)
	end
end

--scale
local scale = 1 --for all choices

-- function to call from C++ preday simulator
-- params and dbparams tables contain data passed from C++
-- to check variable bindings in params or dbparams, refer PredayLuaModel::mapClasses() function in dev/Basic/medium/behavioral/lua/PredayLuaModel.cpp
function choose_ttdo(params,dbparams)
	computeUtilities(params,dbparams) 
	computeAvailabilities(params,dbparams)
	local probability = calculate_probability("mnl", choiceset, utility, availability, scale)
	return make_final_choice(probability)
end

