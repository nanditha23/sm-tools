--[[
Model - Tour time of day for other tour
Type - MNL
Authors - Siyu Li, Harish Loganathan
]]

-- require statements do not work with C++. They need to be commented. The order in which lua files are loaded must be explicitly controlled in C++. 
-- require "Logit"

--Estimated values for all betas
--Note: the betas that not estimated are fixed to zero.

local beta_ARR_2_3 = -0.92925299153680641 
local beta_ARR_2_2 = -0.7850329915368075
local beta_ARR_2_1 = -1.0440329915368078 
local beta_ARR_2_7 = -0.90733299153680669 
local beta_ARR_2_6 = 0.88213299153680858 
local beta_ARR_2_5 = -1.1490329915368065 
local beta_ARR_2_4 = 1.0010329915368086 
local beta_DEP_2_8 = -0.91363299153680799 
local beta_C = -0.21694507485514508
local beta_ARR_2_8 = -0.93937299153680698 
local beta_DEP_2_1 = -1.0510329915368075 
local beta_DEP_2_3 = -0.963932991536808 
local beta_DEP_2_2 = 0.75503299153680814 
local beta_DEP_2_5 = 0.54403299153680962 
local beta_DEP_1_8 = -0.71603299153680666
local beta_DEP_2_7 = -0.93554299153680631 
local beta_DEP_2_6 = 0.94045299153680872 
local beta_DEP_1_2 = 0.46103299153680943 
local beta_TT1 = -2.7425132104329664
local beta_TT2 = -1.2501429442708221
local beta_DEP_1_6 = 0.49003299153680935
local beta_DEP_1_7 = 0.9364129915368089 
local beta_DEP_1_4 = -1.1540329915368073
local beta_DEP_1_5 = -0.1600329915368075
local beta_ARR_1_8 = 0.9298829915368092 
local beta_DEP_1_3 = 0.36603299153680879
local beta_DEP_1_1 = -1.2510329915368068 
local beta_ARR_1_4 = -0.77803299153680783
local beta_ARR_1_5 = -1.8369670084631906 
local beta_ARR_1_6 = 0.76703299153680859
local beta_ARR_1_7 = -0.68103299153680652
local beta_ARR_1_1 = -0.0099670084631906519 
local beta_ARR_1_2 = -0.87696700846319153 
local beta_ARR_1_3 = 0.66003299153680928 
local beta_DUR_1 = 0.93921299153680948
local beta_DUR_2 = 0.84993299153680901 
local beta_DUR_3 = -0.9291329915368074 
local beta_DEP_2_4 = 0.9419729915368098

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

