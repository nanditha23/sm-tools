--[[
Model - intermediate stop time of day
Type - MNL
Authors - Siyu Li, Harish Loganathan
]]

-- all require statements do not work with C++. They need to be commented. The order in which lua files are loaded must be explicitly controlled in C++. 
--require "Logit"

--Estimated values for all betas
--Note= the betas that not estimated are fixed to zero.

local beta_C_1 = -0.16505793561075699
local beta_DUR_1_shopping= 0
local beta_DUR_2_shopping= 0 
local beta_DUR_1_edu= 0
local beta_DUR_3_work= 0 
local beta_DUR_2_work= 0 
local beta_DUR_1_other= 0
local beta_DUR_1_work= 0 
local beta_TT = -2.02171554268797
local beta_C_2 = -0.55771257450968903 
local beta_DEP_1_1 = 2.8569670084631928 
local beta_DEP_1_3 = -4.0730329915368078 
local beta_DEP_1_2 = -1.2169670084631914 
local beta_DEP_1_5 = -4.9330329915368072 
local beta_DEP_1_4 = 0.76803299153680982 
local beta_DEP_1_7 = -0.57903299153680798 
local beta_DEP_1_6 = -5.3830329915368065 
local beta_DEP_1_8 = 2.5730329915368095
local beta_DUR_2_other= 0 
local beta_DUR_3_shopping= 0 
local beta_DUR_2_edu= 0 
local beta_DUR_3_edu= 0 
local beta_ARR_1_8 = -0.24503299153680658
local beta_ARR_1_7 = 3.8130329915368089 
local beta_ARR_1_6 = 1.726967008463193 
local beta_ARR_1_5 = -2.943032991536807 
local beta_ARR_1_4 = -0.5480329915368074 
local beta_ARR_1_3 = 0.20603299153680865 
local beta_ARR_1_2 = -6.8430329915368073 
local beta_ARR_1_1 = -8.5369670084631935 
local beta_DUR_3_other= 0


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

for i = 1,48 do
	choiceset[i] = i
end

local utility = {}
local function computeUtilities(params,dbparams)

	local work_stop_dummy = dbparams.stop_type == 1 and 1 or 0
	local edu_stop_dummy = dbparams.stop_type == 2 and 1 or 0
	local shop_stop_dummy = dbparams.stop_type == 3 and 1 or 0
	local other_stop_dummy = dbparams.stop_type ==4 and 1 or 0 

	local income_id = params.income_id
	local income_cat = {500,1250,1750,2250,2750,3500,4500,5500,6500,7500,8500,0,99999,99999}
	local income_mid = income_cat[income_id]
	local missing_income = params.missing_income
	--whether stop is on first half tour or second half tour
	local first_bound = dbparams.first_bound
	local second_bound = dbparams.second_bound 

	local high_tod = dbparams.high_tod
	local low_tod = dbparams.low_tod

	local pi = math.pi
	local sin = math.sin
	local cos = math.cos
	local pow = math.pow

	local function sarr_1(t)
		return first_bound*beta_ARR_1_1 * sin(2*pi*t/24) + first_bound*beta_ARR_1_5 * cos(2*pi*t/24)+first_bound*beta_ARR_1_2 * sin(4*pi*t/24) + first_bound*beta_ARR_1_6 * cos(4*pi*t/24)+first_bound*beta_ARR_1_3 * sin(6*pi*t/24) + first_bound*beta_ARR_1_7 * cos(6*pi*t/24)+first_bound*beta_ARR_1_4 * sin(8*pi*t/24) + first_bound*beta_ARR_1_8 * cos(8*pi*t/24)
	end

	local function sdep_1(t)
		return second_bound*beta_DEP_1_1 * sin(2*pi*t/24) + second_bound*beta_DEP_1_5 * cos(2*pi*t/24)+second_bound*beta_DEP_1_2 * sin(4*pi*t/24) + second_bound*beta_DEP_1_6 * cos(4*pi*t/24)+second_bound*beta_DEP_1_3 * sin(6*pi*t/24) + second_bound*beta_DEP_1_7 * cos(6*pi*t/24)+second_bound*beta_DEP_1_4 * sin(8*pi*t/24) + second_bound*beta_DEP_1_8 * cos(8*pi*t/24)
	end

	local function sarr_2(t)
		return first_bound*beta_ARR_2_1 * sin(2*pi*t/24) + first_bound*beta_ARR_2_5 * cos(2*pi*t/24)+first_bound*beta_ARR_2_2 * sin(4*pi*t/24) + first_bound*beta_ARR_2_6 * cos(4*pi*t/24)+first_bound*beta_ARR_2_3 * sin(6*pi*t/24) + first_bound*beta_ARR_2_7 * cos(6*pi*t/24)+first_bound*beta_ARR_2_4 * sin(8*pi*t/24) + first_bound*beta_ARR_2_8 * cos(8*pi*t/24)
	end

	local function sdep_2(t)
		return second_bound*beta_DEP_2_1 * sin(2*pi*t/24) + second_bound*beta_DEP_2_5 * cos(2*pi*t/24)+second_bound*beta_DEP_2_2 * sin(4*pi*t/24) + second_bound*beta_DEP_2_6 * cos(4*pi*t/24)+second_bound*beta_DEP_2_3 * sin(6*pi*t/24) + second_bound*beta_DEP_2_7 * cos(6*pi*t/24)+second_bound*beta_DEP_2_4 * sin(8*pi*t/24) + second_bound*beta_DEP_2_8 * cos(8*pi*t/24)
	end

	local function sarr_3(t)
		return first_bound*beta_ARR_3_1 * sin(2*pi*t/24) + first_bound*beta_ARR_3_5 * cos(2*pi*t/24)+first_bound*beta_ARR_3_2 * sin(4*pi*t/24) + first_bound*beta_ARR_3_6 * cos(4*pi*t/24)+first_bound*beta_ARR_3_3 * sin(6*pi*t/24) + first_bound*beta_ARR_3_7 * cos(6*pi*t/24)+first_bound*beta_ARR_3_4 * sin(8*pi*t/24) + first_bound*beta_ARR_3_8 * cos(8*pi*t/24)
	end

	local function sdep_3(t)
		return second_bound*beta_DEP_3_1 * sin(2*pi*t/24) + second_bound*beta_DEP_3_5 * cos(2*pi*t/24)+second_bound*beta_DEP_3_2 * sin(4*pi*t/24) + second_bound*beta_DEP_3_6 * cos(4*pi*t/24)+second_bound*beta_DEP_3_3 * sin(6*pi*t/24) + second_bound*beta_DEP_3_7 * cos(6*pi*t/24)+second_bound*beta_DEP_3_4 * sin(8*pi*t/24) + second_bound*beta_DEP_3_8 * cos(8*pi*t/24)
	end

	local function sarr_4(t)
		return first_bound*beta_ARR_4_1 * sin(2*pi*t/24) + first_bound*beta_ARR_4_5 * cos(2*pi*t/24)+first_bound*beta_ARR_4_2 * sin(4*pi*t/24) + first_bound*beta_ARR_4_6 * cos(4*pi*t/24)+first_bound*beta_ARR_4_3 * sin(6*pi*t/24) + first_bound*beta_ARR_4_7 * cos(6*pi*t/24)+first_bound*beta_ARR_4_4 * sin(8*pi*t/24) + first_bound*beta_ARR_4_8 * cos(8*pi*t/24)
	end

	local function sdep_4(t)
		return second_bound*beta_DEP_4_1 * sin(2*pi*t/24) + second_bound*beta_DEP_4_5 * cos(2*pi*t/24)+second_bound*beta_DEP_4_2 * sin(4*pi*t/24) + second_bound*beta_DEP_4_6 * cos(4*pi*t/24)+second_bound*beta_DEP_4_3 * sin(6*pi*t/24) + second_bound*beta_DEP_4_7 * cos(6*pi*t/24)+second_bound*beta_DEP_4_4 * sin(8*pi*t/24) + second_bound*beta_DEP_4_8 * cos(8*pi*t/24)
	end

	for i =1,48 do
		local arr = arrmidpoint[i]
		local dep = depmidpoint[i]
		local dur = first_bound*(high_tod-i+1)+second_bound*(i-low_tod+1)
		dur = 0.25 + (dur-1)/2
		
		utility[i] = sarr_1(arr) + sdep_1(dep) + work_stop_dummy * (beta_DUR_1_work * dur + beta_DUR_2_work * pow(dur,2) + beta_DUR_3_work * pow(dur,3)) + edu_stop_dummy * (beta_DUR_1_work * dur + beta_DUR_2_work * pow(dur,2) + beta_DUR_3_work * pow(dur,3)) + shop_stop_dummy * (beta_DUR_1_work * dur + beta_DUR_2_work * pow(dur,2) + beta_DUR_3_work * pow(dur,3)) + other_stop_dummy * (beta_DUR_1_work * dur + beta_DUR_2_work * pow(dur,2) + beta_DUR_3_work * pow(dur,3)) + beta_TT * dbparams:TT(i) + (1-missing_income) * beta_C_1 * dbparams:cost(i)/(0.5+income_mid) + missing_income * beta_C_2 * dbparams:cost(i)

	end

end

--availability
--the logic to determine availability is the same with current implementation
local availability = {}
local function computeAvailabilities(params,dbparams)
	for i = 1, 48 do 
		availability[i] = dbparams:availability(i)
	end
end

--scale
local scale= 1 -- for all choices

-- function to call from C++ preday simulator
-- params and dbparams tables contain data passed from C++
-- to check variable bindings in params or dbparams, refer PredayLuaModel::mapClasses() function in dev/Basic/medium/behavioral/lua/PredayLuaModel.cpp
function choose_itd(params,dbparams)
	computeUtilities(params,dbparams) 
	computeAvailabilities(params,dbparams)
	local probability = calculate_probability("mnl", choiceset, utility, availability, scale)
	return make_final_choice(probability)
end

