--[[
Model - Tour time of day for other tour
Type - MNL
Authors - Siyu Li, Harish Loganathan, Olga Petrik
]]

-- require statements do not work with C++. They need to be commented. The order in which lua files are loaded must be explicitly controlled in C++. 
-- require "Logit"

--Estimated values for all betas
--Note: the betas that not estimated are fixed to zero.

-- ARR_1_sin2pi:
local beta_ARR_1_1 = -6.193032991536807
-- ARR_1_cos2pi:
local beta_ARR_1_3 = 10.633032991536808
-- ARR_1_sin4pi:
local beta_ARR_1_2 = 0.53696700846319345
-- ARR 1_cos4pi:
local beta_ARR_1_4 = 5.8930329915368089
 

local beta_DEP_1_1 = -24.76696700846319
local beta_DEP_1_3 = -15.566967008463191
local beta_DEP_1_2 = -6.5869670084631906
local beta_DEP_1_4 = 8.686967008463192


local beta_DUR_1 = 0.95696700846319338
local beta_DUR_2 = 0.77403299153680827
local beta_DUR_3 = -0.92313299153680717

local pi = math.pi
local pow = math.pow
local sin = math.sin
local cos = math.cos

local choiceset={}
local arrmidpoint = {}
local depmidpoint = {}

for i =1,48 do
	arrmidpoint[i] = i * 0.5 + 2.75
	depmidpoint[i] = i * 0.5 + 2.75
end

for i = 1,1176 do
	choiceset[i] = i
end

local comb = {}
local count = 0

for i=1,48 do
	for j=i,48 do
		count=count+1
		comb[count]={i,j}
	end
end

local function sarr_1(t)
	return beta_ARR_1_1 * sin(2*pi*t/24) + beta_ARR_1_3 * cos(2*pi*t/24)+beta_ARR_1_2 * sin(4*pi*t/24) + beta_ARR_1_4 * cos(4*pi*t/24)
end

local function sdep_1(t)
	return beta_DEP_1_1 * sin(2*pi*t/24) + beta_DEP_1_3 * cos(2*pi*t/24)+beta_DEP_1_2 * sin(4*pi*t/24) + beta_DEP_1_4 * cos(4*pi*t/24)
end


local utility = {}
local function computeUtilities(params,dbparams)
	local female_dummy = params.female_dummy
	local activity_type = dbparams.activity_type
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
		utility[i] = sarr_1(arr) + sdep_1(dep) + beta_DUR_1 * dur + beta_DUR_2 * pow(dur,2) + beta_DUR_3 * pow(dur,3)
	end
end

--availability
local availability = {}
local function computeAvailabilities(dbparams)
	for i = 1,1176 do 
		availability[i] = dbparams:time_window_availability(i)
	end
end

--scale
local scale = 1 -- for all choices

function choose_sttd(params,dbparams)
	computeUtilities(params,dbparams) 
	computeAvailabilities(dbparams)
	local probability = calculate_probability("mnl", choiceset, utility, availability, scale)
	return make_final_choice(probability)
end
