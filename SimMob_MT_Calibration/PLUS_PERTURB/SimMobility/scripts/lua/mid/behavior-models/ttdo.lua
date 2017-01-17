--[[
Model - Tour time of day for other tour
Type - MNL
Authors - Siyu Li, Harish Loganathan
]]

-- require statements do not work with C++. They need to be commented. The order in which lua files are loaded must be explicitly controlled in C++. 
-- require "Logit"

--Estimated values for all betas
--Note: the betas that not estimated are fixed to zero.

local beta_ARR_2_3 = 0.93681299153680975 
local beta_ARR_2_2 = 1.0810329915368087
local beta_ARR_2_1 = 0.82203299153680831 
local beta_ARR_2_7 = 0.95873299153680946 
local beta_ARR_2_6 = -0.98393299153680758 
local beta_ARR_2_5 = 0.71703299153680966 
local beta_ARR_2_4 = -0.86503299153680757 
local beta_DEP_2_8 = 0.95243299153680816 
local beta_C = -0.20705492514485491
local beta_ARR_2_8 = 0.92669299153680917 
local beta_DEP_2_1 = 0.81503299153680864 
local beta_DEP_2_3 = 0.90213299153680815 
local beta_DEP_2_2 = -1.111032991536808 
local beta_DEP_2_5 = -1.3220329915368065 
local beta_DEP_1_8 = 1.1500329915368095
local beta_DEP_2_7 = 0.93052299153680984 
local beta_DEP_2_6 = -0.92561299153680743 
local beta_DEP_1_2 = -1.4050329915368067 
local beta_TT1 = -2.617486789567034
local beta_TT2 = -1.3098570557291778
local beta_DEP_1_6 = -1.3760329915368068
local beta_DEP_1_7 = -0.92965299153680725 
local beta_DEP_1_4 = 0.71203299153680888
local beta_DEP_1_5 = 1.7060329915368087
local beta_ARR_1_8 = -0.93618299153680695 
local beta_DEP_1_3 = -1.5000329915368074
local beta_DEP_1_1 = 0.61503299153680935 
local beta_ARR_1_4 = 1.0880329915368083
local beta_ARR_1_5 = -3.7030329915368068 
local beta_ARR_1_6 = -1.0990329915368076
local beta_ARR_1_7 = 1.1850329915368096
local beta_ARR_1_1 = -1.8760329915368068 
local beta_ARR_1_2 = -2.7430329915368077 
local beta_ARR_1_3 = -1.2060329915368069 
local beta_DUR_1 = -0.92685299153680667
local beta_DUR_2 = -1.0161329915368071 
local beta_DUR_3 = 0.93693299153680876 
local beta_DEP_2_4 = -0.92409299153680635

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
	-- work time flexibility 1 for fixed hour, 2 for flexible hour
	--local worktime = params.worktime	
	
	local pow = math.pow

	local cost_HT1_am = dbparams.cost_HT1_am
	local cost_HT1_pm = dbparams.cost_HT1_pm
	local cost_HT1_op = dbparams.cost_HT1_op
	local cost_HT2_am = dbparams.cost_HT2_am
	local cost_HT2_pm = dbparams.cost_HT2_pm
	local cost_HT2_op = dbparams.cost_HT2_op

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
	local mode = dbparams.mode
	for i = 1, 1176 do 
		availability[i] = params:getTimeWindowAvailabilityTour(i,mode)
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

