--[[
Model - Tour time of day for work tour
Type - MNL
Authors - Siyu Li, Harish Loganathan
]]

-- all require statements do not work with C++. They need to be commented. The order in which lua files are loaded must be explicitly controlled in C++. 
--require "Logit"

--Estimated values for all betas
--Note: the betas that not estimated are fixed to zero.

local beta_DEP_4_3 = 1.7620329915368096
local beta_DEP_4_2 = -0.38203299153680703 
local beta_DEP_4_1 = -2.143032991536808
local beta_DEP_4_7 = 0.34703299153680867 
local beta_DEP_4_6 = 0.29696700846319324 
local beta_DEP_4_5 = -1.0730329915368078 
local beta_DEP_4_4 = -1.1550329915368067 
local beta_DEP_4_8 = 0.27903299153680905 
local beta_ARR_4_3 = -0.45303299153680676 
local beta_DEP_1_6 = -2.9830329915368079 
local beta_DEP_1_7 = -0.3110329915368073 
local beta_DEP_1_4 = -0.96133299153680696
local beta_DEP_1_5 = -4.9030329915368078 
local beta_DEP_1_2 = -1.2169670084631914 
local beta_DEP_1_3 = -1.9530329915368068 
local beta_DEP_1_1 = 2.2730329915368088 
local beta_DEP_1_8 = 0.12696700846319331 
local beta_ARR_2_8 = -0.17903299153680763 
local beta_TT2 =  0.0 
local beta_ARR_4_8 = 0.64103299153680915 
local beta_ARR_2_7 = -0.21103299153680766 
local beta_ARR_4_1 = 0.84343299153680817 
local beta_ARR_3_8 = 0.46103299153680943 
local beta_ARR_4_2 = 1.6090329915368091 
local beta_ARR_4_5 = -3.6530329915368078
local beta_ARR_4_4 = 0.94503299153680942 
local beta_ARR_4_7 = -2.1830329915368072 
local beta_ARR_4_6 = -0.5969670084631904 
local beta_ARR_3_2 = -0.65503299153680672 
local beta_ARR_3_3 = 1.3940329915368093 
local beta_ARR_3_1 = -1.4550329915368074 
local beta_ARR_3_6 = -2.8230329915368078 
local beta_ARR_3_7 = -2.2030329915368068 
local beta_ARR_3_4 = 1.3130329915368097 
local beta_ARR_3_5 = -3.5730329915368078 
local beta_ARR_2_3 = -1.318032991536807 
local beta_ARR_2_2 = -1.6780329915368064 
local beta_ARR_2_1 = -2.7430329915368077 
local beta_ARR_1_8 = 0.66103299153680872 
local beta_ARR_2_6 = 0.31696700846319281 
local beta_ARR_2_5 = 0.67696700846319224 
local beta_ARR_2_4 = -1.4630329915368065 
local beta_ARR_1_4 = 1.0630329915368097 
local beta_ARR_1_5 = -1.366032991536807 
local beta_ARR_1_6 = 0.91913299153680939 
local beta_ARR_1_7 = -0.010032991536807145
local beta_ARR_1_1 = -4.5530329915368064 
local beta_ARR_1_2 = -1.5069670084631905 
local beta_ARR_1_3 = -1.5450329915368073 
local beta_DEP_3_8 = -0.54603299153680673 
local beta_DUR_2 = 1.0155329915368085
local beta_DUR_3 = -0.93955299153680727 
local beta_DUR_1 = 0.013967008463191988 
local beta_DEP_3_1 = -1.7830329915368068 
local beta_DEP_3_2 = 0.20003299153680842 
local beta_DEP_3_3 = 0.34903299153680933 
local beta_DEP_3_4 = 1.042032991536809 
local beta_DEP_3_5 = -0.38696700846319132 
local beta_DEP_3_6 = 0.99373299153680961
local beta_DEP_3_7 = -0.55703299153680774 
local beta_DEP_2_1 = -2.8730329915368067 
local beta_TT1 = 0.0 
local beta_DEP_2_3 = -0.41403299153680706 
local beta_DEP_2_2 = -1.9830329915368079 
local beta_DEP_2_5 = -3.1330329915368065 
local beta_DEP_2_4 = 1.215032991536809 
local beta_DEP_2_7 = 1.6030329915368089 
local beta_DEP_2_6 = 2.6430329915368098
local beta_DEP_2_8 = 0.47803299153680889 
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

