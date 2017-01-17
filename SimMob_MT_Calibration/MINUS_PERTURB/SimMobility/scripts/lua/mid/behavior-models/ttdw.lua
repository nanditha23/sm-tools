--[[
Model - Tour time of day for work tour
Type - MNL
Authors - Siyu Li, Harish Loganathan
]]

-- all require statements do not work with C++. They need to be commented. The order in which lua files are loaded must be explicitly controlled in C++. 
--require "Logit"

--Estimated values for all betas
--Note: the betas that not estimated are fixed to zero.

local beta_DEP_4_3 = -0.10403299153680656
local beta_DEP_4_2 = 1.4840329915368091 
local beta_DEP_4_1 = -0.27696700846319189
local beta_DEP_4_7 = -1.5190329915368075 
local beta_DEP_4_6 = 2.1630329915368094 
local beta_DEP_4_5 = 0.7930329915368084 
local beta_DEP_4_4 = 0.71103299153680943 
local beta_DEP_4_8 = -1.5870329915368071 
local beta_ARR_4_3 = 1.4130329915368094 
local beta_DEP_1_6 = -1.1169670084631917 
local beta_DEP_1_7 = 1.5550329915368089 
local beta_DEP_1_4 = 0.90473299153680919
local beta_DEP_1_5 = -3.0369670084631917 
local beta_DEP_1_2 = -3.0830329915368075 
local beta_DEP_1_3 = -0.086967008463190609 
local beta_DEP_1_1 = 0.40696700846319267 
local beta_DEP_1_8 = 1.9930329915368095 
local beta_ARR_2_8 = 1.6870329915368085 
local beta_TT2 =  0.0 
local beta_ARR_4_8 = -1.225032991536807 
local beta_ARR_2_7 = 1.6550329915368085 
local beta_ARR_4_1 = -1.022632991536808 
local beta_ARR_3_8 = -1.4050329915368067 
local beta_ARR_4_2 = -0.25703299153680703 
local beta_ARR_4_5 = -1.7869670084631917
local beta_ARR_4_4 = -0.92103299153680673 
local beta_ARR_4_7 = -0.31696700846319104 
local beta_ARR_4_6 = -2.4630329915368065 
local beta_ARR_3_2 = 1.2110329915368094 
local beta_ARR_3_3 = -0.47203299153680689 
local beta_ARR_3_1 = 0.41103299153680872 
local beta_ARR_3_6 = -0.9569670084631916 
local beta_ARR_3_7 = -0.33696700846319061 
local beta_ARR_3_4 = -0.55303299153680641 
local beta_ARR_3_5 = -1.7069670084631916 
local beta_ARR_2_3 = 0.54803299153680918 
local beta_ARR_2_2 = 0.18803299153680975 
local beta_ARR_2_1 = -0.87696700846319153 
local beta_ARR_1_8 = -1.2050329915368074 
local beta_ARR_2_6 = 2.183032991536809 
local beta_ARR_2_5 = 2.5430329915368084 
local beta_ARR_2_4 = 0.4030329915368096 
local beta_ARR_1_4 = -0.80303299153680641 
local beta_ARR_1_5 = 0.50003299153680913 
local beta_ARR_1_6 = -0.94693299153680677 
local beta_ARR_1_7 = 1.856032991536809
local beta_ARR_1_1 = -2.6869670084631903 
local beta_ARR_1_2 = -3.3730329915368067 
local beta_ARR_1_3 = 0.32103299153680886 
local beta_DEP_3_8 = 1.3200329915368094 
local beta_DUR_2 = -0.85053299153680761
local beta_DUR_3 = 0.92651299153680888 
local beta_DUR_1 = 1.8800329915368081 
local beta_DEP_3_1 = 0.08303299153680932 
local beta_DEP_3_2 = -1.6660329915368077 
local beta_DEP_3_3 = -1.5170329915368068 
local beta_DEP_3_4 = -0.8240329915368072 
local beta_DEP_3_5 = -2.2530329915368075 
local beta_DEP_3_6 = -0.87233299153680655
local beta_DEP_3_7 = 1.3090329915368084 
local beta_DEP_2_1 = -1.0069670084631905 
local beta_TT1 = 0.0 
local beta_DEP_2_3 = 1.4520329915368091 
local beta_DEP_2_2 = -0.11696700846319175 
local beta_DEP_2_5 = -1.2669670084631903 
local beta_DEP_2_4 = -0.65103299153680716 
local beta_DEP_2_7 = -0.26303299153680726 
local beta_DEP_2_6 = 0.77696700846319366
local beta_DEP_2_8 = -1.3880329915368073 
local beta_C = 0.0

local k = 4
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

local function sarr_3(t)
	return beta_ARR_3_1 * math.sin(2*pi*t/24.) + beta_ARR_3_5 * math.cos(2*pi*t/24.) + beta_ARR_3_2 * math.sin(4*pi*t/24.) + beta_ARR_3_6 * math.cos(4*pi*t/24.) + beta_ARR_3_3 * math.sin(6*pi*t/24.) + beta_ARR_3_7 * math.cos(6*pi*t/24.) + beta_ARR_3_4 * math.sin(8*pi*t/24.) + beta_ARR_3_8 * math.cos(8*pi*t/24.)
end

local function sdep_3(t)
	return beta_DEP_3_1 * math.sin(2*pi*t/24.) + beta_DEP_3_5 * math.cos(2*pi*t/24.) + beta_DEP_3_2 * math.sin(4*pi*t/24.) + beta_DEP_3_6 * math.cos(4*pi*t/24.) + beta_DEP_3_3 * math.sin(6*pi*t/24.) + beta_DEP_3_7 * math.cos(6*pi*t/24.) + beta_DEP_3_4 * math.sin(8*pi*t/24.) + beta_DEP_3_8 * math.cos(8*pi*t/24.)
end

local function sarr_4(t)
	return beta_ARR_4_1 * math.sin(2*pi*t/24.) + beta_ARR_4_5 * math.cos(2*pi*t/24.) + beta_ARR_4_2 * math.sin(4*pi*t/24.) + beta_ARR_4_6 * math.cos(4*pi*t/24.) + beta_ARR_4_3 * math.sin(6*pi*t/24.) + beta_ARR_4_7 * math.cos(6*pi*t/24.) + beta_ARR_4_4 * math.sin(8*pi*t/24.) + beta_ARR_4_8 * math.cos(8*pi*t/24.)
end

local function sdep_4(t)
	return beta_DEP_4_1 * math.sin(2*pi*t/24.) + beta_DEP_4_5 * math.cos(2*pi*t/24.) + beta_DEP_4_2 * math.sin(4*pi*t/24.) + beta_DEP_4_6 * math.cos(4*pi*t/24.) + beta_DEP_4_3 * math.sin(6*pi*t/24.) + beta_DEP_4_7 * math.cos(6*pi*t/24.) + beta_DEP_4_4 * math.sin(8*pi*t/24.) + beta_DEP_4_8 * math.cos(8*pi*t/24.)
end


local utility = {}
local function computeUtilities(params,dbparams) 

	local person_type_id = params.person_type_id 
	-- gender in this model is the same as female_dummy
	local gender = params.female_dummy
	-- work time flexibility 1 for fixed hour, 2 for flexible hour
	local worktime = params.fixed_work_hour

	local cost_HT1_am = dbparams.cost_HT1_am
	local cost_HT1_pm = dbparams.cost_HT1_pm
	local cost_HT1_op = dbparams.cost_HT1_op
	local cost_HT2_am = dbparams.cost_HT2_am
	local cost_HT2_pm = dbparams.cost_HT2_pm
	local cost_HT2_op = dbparams.cost_HT2_op

	local pow = math.pow

	for i =1,1176 do
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
		utility[i] = sarr_1(arr) + sdep_1(dep) + (person_type_id ~= 1 and 1 or 0) * (sarr_2(arr) + sdep_2(dep)) + gender * (sarr_3(arr) + sdep_3(dep)) + (worktime == 2 and 1 or 0) * (sarr_4(arr) + sdep_4(dep)) + beta_DUR_1 * dur + beta_DUR_2 * pow(dur,2) + beta_DUR_3 * pow(dur,3) + beta_TT1 * dbparams:TT_HT1(arrid) + beta_TT2 * dbparams:TT_HT2(depid) + beta_C * (cost_HT1_am * arr_am + cost_HT1_pm * arr_pm + cost_HT1_op * arr_op + cost_HT2_am * dep_am + cost_HT2_pm * dep_pm + cost_HT2_op * dep_op)
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
function choose_ttdw(params,dbparams)
	computeUtilities(params,dbparams) 
	computeAvailabilities(params,dbparams)
	local probability = calculate_probability("mnl", choiceset, utility, availability, scale)
	return make_final_choice(probability)
end

