--[[
Model - Mode/destination choice for shopping tour
Type - logit
Authors - Siyu Li, Harish Loganathan
]]

-- all require statements do not work with C++. They need to be commented. The order in which lua files are loaded must be explicitly controlled in C++. 
--require "Logit"

--Estimated values for all betas
--Note: the betas that not estimated are fixed to zero.

--!! see the documentation on the definition of AM,PM and OP table!!

local beta_cost_bus_mrt_1= 0
local beta_cost_private_bus_1 = 0
local beta_cost_drive1_1 = 0
local beta_cost_share2_1= 0
local beta_cost_share3_1= 0
local beta_cost_motor_1 = 0
local beta_cost_taxi_1 = 0

local beta_cost_bus_mrt_2 = -0.294
local beta_cost_private_bus_2 = -1.29
local beta_cost_drive1_2 = -0.371
local beta_cost_share2_2 = -0.233
local beta_cost_share3_2 = 0
local beta_cost_motor_2 = -0.150
local beta_cost_taxi_2 = -0.113

local AMOD_cost = 3
local AMOD_wtc = -1.10
local AMOD_wt = 0.167

local beta_tt_bus_mrt = -2.78
local beta_tt_private_bus = 0 
local beta_tt_drive1 = -4.65
local beta_tt_share2= -3.59
local beta_tt_share3= -2.14
local beta_tt_motor = 0
local beta_tt_walk = -5.05
local beta_tt_taxi = -3.33

local beta_log = 1.14
local beta_area = 3.41
local beta_population = -7.24

local beta_central_bus_mrt = -0.178
local beta_central_private_bus= -1.13
local beta_central_drive1 = 0 
local beta_central_share2 = 0.325
local beta_central_share3 = 0.103
local beta_central_motor = 0.0738
local beta_central_walk = 1.12
local beta_central_taxi = 1.92

local beta_distance_bus_mrt = 0.00911
local beta_distance_private_bus = 0.0808
local beta_distance_drive1 = 0
local beta_distance_share2 = -0.0413
local beta_distance_share3 = -0.0220
local beta_distance_motor = -0.0635
local beta_distance_walk = 0
local beta_distance_taxi = 0


local beta_cons_bus = -1.204
local beta_cons_mrt = -2.146
local beta_cons_private_bus = -3.649
local beta_cons_drive1 = 4.399
local beta_cons_share2 = -3.28
local beta_cons_share3 = -4.28
local beta_cons_motor = -2.538
local beta_cons_walk = -6.77
local beta_cons_taxi = -5.16

local beta_zero_bus = 0
local beta_oneplus_bus = 0
local beta_twoplus_bus = -0.512
local beta_threeplus_bus = 0

local beta_zero_mrt= 0
local beta_oneplus_mrt = 0.648
local beta_twoplus_mrt = -2.55
local beta_threeplus_mrt = 0

local beta_zero_privatebus = 0
local beta_oneplus_privatebus = 0.0862
local beta_twoplus_privatebus = 0
local beta_threeplus_privatebus = 0

local beta_zero_drive1 = 0
local beta_oneplus_drive1 = 0
local beta_twoplus_drive1 = 0.476
local beta_threeplus_drive1 = 0

local beta_zero_share2 = 0
local beta_oneplus_share2 = 3.65
local beta_twoplus_share2 = 0
local beta_threeplus_share2 = 0

local beta_zero_share3 = 0
local beta_oneplus_share3 = 2.82
local beta_twoplus_share3 = -0.735
local beta_threeplus_share3 = 0

local beta_zero_car_motor = 0
local beta_oneplus_car_motor = 0
local beta_twoplus_car_motor = 0
local beta_threeplus_car_motor = 0

local beta_zero_walk = 0
local beta_oneplus_walk = -0.0563
local beta_twoplus_walk = 0
local beta_threeplus_walk = 0

local beta_zero_taxi = 0
local beta_oneplus_taxi = -0.0655
local beta_twoplus_taxi = 0
local beta_threeplus_taxi = 0

local beta_zero_motor = 0
local beta_oneplus_motor = 0
local beta_twoplus_motor= 4.89
local beta_threeplus_motor= 0 

local beta_female_bus = 0.0894
local beta_female_mrt = 0
local beta_female_private_bus = -0.437
local beta_female_drive1 = 0
local beta_female_share2 = -0.669
local beta_female_share3 = -0.690
local beta_female_motor = -2.60
local beta_female_taxi = 0.404
local beta_female_walk = 1.83


--choice set
local choice = {}
for i = 1, 1169*9 do 
	choice[i] = i
end

--utility
-- 1 for public bus; 2 for MRT/LRT; 3 for private bus; 4 for drive1;
-- 5 for shared2; 6 for shared3+; 7 for motor; 8 for walk; 9 for taxi
local utility = {}
local function computeUtilities(params,dbparams)
	local cost_increase = dbparams.cost_increase
	local cbd_dummy_origin= dbparams.cbd_dummy_origin
	local female_dummy = params.female_dummy
	local income_id = params.income_id
	local income_cat = {500,1250,1750,2250,2750,3500,4500,5500,6500,7500,8500,0,99999,99999}
	local income_mid = income_cat[income_id]
	local missing_income = (params.income_id >= 13) and 1 or 0

	--params.car_own_normal is from household table
	local zero_car = params.car_own_normal == 0 and 1 or 0
	local one_plus_car = params.car_own_normal >= 1 and 1 or 0
	local two_plus_car = params.car_own_normal >= 2 and 1 or 0
	local three_plus_car = params.car_own_normal >= 3 and 1 or 0

	--params.motor_own is from household table
	local zero_motor = params.motor_own == 0 and 1 or 0
	local one_plus_motor = params.motor_own >=1 and 1 or 0
	local two_plus_motor = params.motor_own >=2 and 1 or 0
	local three_plus_motor = params.motor_own >= 3 and 1 or 0

	local cost_public_first = {}
	local cost_public_second = {}
	local cost_bus = {}
	local cost_mrt = {}
	local cost_private_bus = {}

	local cost_car_OP_first = {}
	local cost_car_OP_second = {}
	local cost_car_ERP_first = {}
	local cost_car_ERP_second = {}
	local cost_car_parking = {}
	local cost_drive1 = {}
	local cost_share2 = {}
	local cost_share3 = {}
	local cost_motor = {}
	
	local cost_taxi_1 = {}
	local cost_taxi_2 = {}
	local cost_taxi={}

	local d1={}
	local d2={}
	local central_dummy={}
	local cbd_dummy={}

	local cost_over_income_bus = {}
	local cost_over_income_mrt = {}
	local cost_over_income_private_bus = {}
	local cost_over_income_drive1 = {}
	local cost_over_income_share2 = {}
	local cost_over_income_share3 = {}
	local cost_over_income_motor = {}
	local cost_over_income_taxi = {}

	local tt_public_ivt_first = {}
	local tt_public_ivt_second = {}
	local tt_public_out_first = {}
	local tt_public_out_second = {}
	local tt_car_ivt_first = {}
	local tt_car_ivt_second = {}

	local tt_bus = {}
	local tt_mrt = {}
	local tt_private_bus = {}
	local tt_drive1 = {}
	local tt_share2 = {}
	local tt_share3 = {}
	local tt_motor = {}
	local tt_walk = {}
	local tt_taxi = {}

	local average_transfer_number = {}

	local employment = {}
	local population = {}
	local area = {}
	local shop = {}

	for i =1,1169 do
		--dbparams:cost_public_first(i) = AM[(origin,destination[i])]['pub_cost']
		--dbparams:cost_public_second(i) = PM[(destination[i],origin)]['pub_cost']
		--origin is home, destination[i] is zone from 1 to 1169
		--0 if origin == destination
		cbd_dummy[i] = dbparams:cbd_dummy(i)
		cost_public_first[i] = dbparams:cost_public_first(i)
		cost_public_second[i] = dbparams:cost_public_second(i)
		cost_bus[i] = cost_public_first[i] + cost_public_second[i] + cost_increase
		cost_mrt[i] = cost_public_first[i] + cost_public_second[i] + cost_increase
		cost_private_bus[i] = cost_public_first[i] + cost_public_second[i] + cost_increase + cbd_dummy[i]*AMOD_cost + cbd_dummy_origin *(1-cbd_dummy[i])*AMOD_cost

		--dbparams:cost_car_ERP_first(i) = AM[(origin,destination[i])]['car_cost_erp']
		--dbparams:cost_car_ERP_second(i) = PM[(destination[i],origin)]['car_cost_erp']
		--dbparams:cost_car_OP_first(i) = AM[(origin,destination[i])]['distance']*0.147
		--dbparams:cost_car_OP_second(i) = PM[(destination[i],origin)]['distance']*0.147
		--dbparams:cost_car_parking(i) = 8 * ZONE[destination[i]]['parking_rate']
		--for the above 5 variables, origin is home, destination[i] is tour destination from 1 to 1169
		--0 if origin == destination
		cost_drive1[i] = dbparams:cost_car_ERP_first(i)+dbparams:cost_car_ERP_second(i)+dbparams:cost_car_OP_first(i)+dbparams:cost_car_OP_second(i)+dbparams:cost_car_parking(i)+cost_increase + cbd_dummy[i]*AMOD_cost + cbd_dummy_origin *(1-cbd_dummy[i])*AMOD_cost
		cost_share2[i] = (dbparams:cost_car_ERP_first(i)+dbparams:cost_car_ERP_second(i)+dbparams:cost_car_OP_first(i)+dbparams:cost_car_OP_second(i)+dbparams:cost_car_parking(i)+cost_increase)/2 + cbd_dummy[i]*AMOD_cost + cbd_dummy_origin *(1-cbd_dummy[i])*AMOD_cost
		cost_share3[i] = (dbparams:cost_car_ERP_first(i)+dbparams:cost_car_ERP_second(i)+dbparams:cost_car_OP_first(i)+dbparams:cost_car_OP_second(i)+dbparams:cost_car_parking(i)+cost_increase)/3 + cbd_dummy[i]*AMOD_cost + cbd_dummy_origin *(1-cbd_dummy[i])*AMOD_cost
		cost_motor[i] = 0.5*(dbparams:cost_car_ERP_first(i)+dbparams:cost_car_ERP_second(i)+dbparams:cost_car_OP_first(i)+dbparams:cost_car_OP_second(i))+0.65*dbparams:cost_car_parking(i)+cost_increase + cbd_dummy[i]*AMOD_cost + cbd_dummy_origin *(1-cbd_dummy[i])*AMOD_cost

		--dbparams:walk_distance1(i)= AM[(origin,destination[i])]['AM2dis']
		--dbparams:walk_distance2(i)= PM[(destination[i],origin)]['PM2dis']
		--dbparams:central_dummy(i)=ZONE[destination[i]]['central_dummy']
		--origin is home mtz, destination[i] is zone from 1 to 1169
		--0 if origin == destination
		d1[i] = dbparams:walk_distance1(i)
		d2[i] = dbparams:walk_distance2(i)
		central_dummy[i] = dbparams:central_dummy(i)

		cost_taxi_1[i] = 3.4+((d1[i]*(d1[i]>10 and 1 or 0)-10*(d1[i]>10 and 1 or 0))/0.35+(d1[i]*(d1[i]<=10 and 1 or 0)+10*(d1[i]>10 and 1 or 0))/0.4)*0.22+ dbparams:cost_car_ERP_first(i) + central_dummy[i]*3
		cost_taxi_2[i] = 3.4+((d2[i]*(d2[i]>10 and 1 or 0)-10*(d2[i]>10 and 1 or 0))/0.35+(d2[i]*(d2[i]<=10 and 1 or 0)+10*(d2[i]>10 and 1 or 0))/0.4)*0.22+ dbparams:cost_car_ERP_second(i) + central_dummy[i]*3
		cost_taxi[i] = cost_taxi_1[i] + cost_taxi_2[i] + cost_increase

		cost_over_income_bus[i]=30*cost_bus[i]/(0.5+income_mid)
		cost_over_income_mrt[i]=30*cost_mrt[i]/(0.5+income_mid)
		cost_over_income_private_bus[i]=30*cost_private_bus[i]/(0.5+income_mid)
		cost_over_income_drive1[i] = 30 * cost_drive1[i]/(0.5+income_mid)
		cost_over_income_share2[i] = 30 * cost_share2[i]/(0.5+income_mid)
		cost_over_income_share3[i] = 30 * cost_share3[i]/(0.5+income_mid)
		cost_over_income_motor[i]=30*cost_motor[i]/(0.5+income_mid)
		cost_over_income_taxi[i]=30*cost_taxi[i]/(0.5+income_mid)

		--dbparams:tt_public_ivt_first(i) = AM[(origin,destination[i])]['pub_ivt']
		--dbparams:tt_public_ivt_second(i) = PM[(destination[i],origin)]['pub_ivt']
		--dbparams:tt_public_out_first(i) = AM[(origin,destination[i])]['pub_out']
		--dbparams:tt_public_out_second(i) = PM[(destination[i],origin)]['pub_out']
		--for the above 4 variables, origin is home, destination[i] is zone from 1 to 1169
		--0 if origin == destination
		tt_public_ivt_first[i] = dbparams:tt_public_ivt_first(i)
		tt_public_ivt_second[i] = dbparams:tt_public_ivt_second(i)
		tt_public_out_first[i] = dbparams:tt_public_out_first(i)
		tt_public_out_second[i] = dbparams:tt_public_out_second(i)

		--dbparams:tt_car_ivt_first(i) = AM[(origin,destination[i])]['car_ivt']
		--dbparams:tt_car_ivt_second(i) = PM[(destination[i],origin)]['car_ivt']
		tt_car_ivt_first[i] = dbparams:tt_car_ivt_first(i)
		tt_car_ivt_second[i] = dbparams:tt_car_ivt_second(i)

		tt_bus[i] = tt_public_ivt_first[i]+ tt_public_ivt_second[i]+tt_public_out_first[i]+tt_public_out_second[i]
		tt_mrt[i] = tt_public_ivt_first[i]+ tt_public_ivt_second[i]+tt_public_out_first[i]+tt_public_out_second[i]
		tt_private_bus[i] = tt_car_ivt_first[i] + tt_car_ivt_second[i]
		tt_drive1[i] = tt_car_ivt_first[i] + tt_car_ivt_second[i] + 1.0/6
		tt_share2[i] = tt_car_ivt_first[i] + tt_car_ivt_second[i] + 1.0/6
		tt_share3[i] = tt_car_ivt_first[i] + tt_car_ivt_second[i] + 1.0/6
		tt_motor[i] = tt_car_ivt_first[i] + tt_car_ivt_second[i] + 1.0/6
		tt_walk[i] = (d1[i]+d2[i])/5
		tt_taxi[i] = tt_car_ivt_first[i] + tt_car_ivt_second[i] + 1.0/6

		--dbparams:average_transfer_number(i) = (AM[(origin,destination[i])]['avg_transfer'] + PM[(destination[i],origin)]['avg_transfer'])/2
		--origin is home, destination[i] is zone from 1 to 1169
		-- 0 if origin == destination
		average_transfer_number[i] = dbparams:average_transfer_number(i)

		--dbparams:employment(i) = ZONE[i]['employment']
		--dbparams:population(i) = ZONE[i]['population']
		--dbparams:area(i) = ZONE[i]['area']
		--dbparams:shop(i) = ZONE[i]['shop']
		employment[i] = dbparams:employment(i)
		population[i] = dbparams:population(i)
		area[i] = dbparams:area(i)
		shop[i] = dbparams:shop(i)
	end

	local V_counter = 0

	--utility function for bus 1-1169
	for i =1,1169 do
		V_counter = V_counter + 1
		utility[V_counter] = beta_cons_bus + cost_over_income_bus[i] * (1- missing_income) * beta_cost_bus_mrt_1 + cost_bus[i] * beta_cost_bus_mrt_2 + tt_bus[i] * beta_tt_bus_mrt + beta_central_bus_mrt * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i]) + (d1[i]+d2[i]) * beta_distance_bus_mrt + beta_female_bus * female_dummy + beta_zero_bus* zero_car + beta_oneplus_bus* one_plus_car+ beta_twoplus_bus* two_plus_car
	end

	--utility function for mrt 1-1169
	for i=1,1169 do
		V_counter = V_counter +1
		utility[V_counter] = beta_cons_mrt + cost_over_income_mrt[i] * (1- missing_income) * beta_cost_bus_mrt_1 + cost_mrt[i] * beta_cost_bus_mrt_2 + tt_mrt[i] * beta_tt_bus_mrt + beta_central_bus_mrt * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i]) + (d1[i]+d2[i]) * beta_distance_bus_mrt + beta_female_mrt * female_dummy + beta_zero_mrt*zero_car+ beta_oneplus_mrt*one_plus_car+beta_twoplus_mrt*two_plus_car
	end

	--utility function for private bus 1-1169
	for i=1,1169 do
		V_counter = V_counter +1
		utility[V_counter] = beta_cons_private_bus + cost_over_income_private_bus[i] * (1- missing_income) * beta_cost_private_bus_2 + cost_private_bus[i] * beta_cost_private_bus_2 + tt_private_bus[i] * beta_tt_bus_mrt + beta_central_private_bus * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i]) + (d1[i]+d2[i]) * beta_distance_private_bus + beta_female_private_bus * female_dummy + beta_zero_privatebus*zero_car+beta_oneplus_privatebus*one_plus_car+beta_twoplus_privatebus*two_plus_car + AMOD_wtc * cbd_dummy[i] * AMOD_wt + AMOD_wtc * cbd_dummy_origin * (1-cbd_dummy[i]) * AMOD_wt
	end

	--utility function for drive1 1-1169
	for i=1,1169 do
		V_counter = V_counter +1
		utility[V_counter] = beta_cons_drive1 + cost_over_income_drive1[i] * (1 - missing_income) * beta_cost_drive1_1 + cost_drive1[i] * beta_cost_drive1_2 + tt_drive1[i] * beta_tt_drive1 + beta_central_drive1 * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i]) + (d1[i]+d2[i]) * beta_distance_drive1 + beta_zero_drive1 *zero_car + beta_oneplus_drive1 * one_plus_car + beta_twoplus_drive1 * two_plus_car + beta_threeplus_drive1 * three_plus_car + beta_female_drive1 * female_dummy + AMOD_wtc * cbd_dummy[i] * AMOD_wt + AMOD_wtc * cbd_dummy_origin * (1-cbd_dummy[i]) * AMOD_wt
	end

	--utility function for share2 1-1169
	for i=1,1169 do
		V_counter = V_counter +1
		utility[V_counter] = beta_cons_share2 + cost_over_income_share2[i] * (1 - missing_income) * beta_cost_share2_1 + cost_share2[i] * beta_cost_share2_2 + tt_share2[i] * beta_tt_share2 + beta_central_share2 * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i]) + (d1[i]+d2[i]) * beta_distance_share2 + beta_zero_share2 *zero_car + beta_oneplus_share2 * one_plus_car + beta_twoplus_share2 * two_plus_car + beta_threeplus_share2 * three_plus_car + beta_female_share2 * female_dummy + AMOD_wtc * cbd_dummy[i] * AMOD_wt + AMOD_wtc * cbd_dummy_origin * (1-cbd_dummy[i]) * AMOD_wt
	end

	--utility function for share3 1-1169
	for i=1,1169 do
		V_counter = V_counter +1
		utility[V_counter] = beta_cons_share3 + cost_over_income_share3[i] * (1 - missing_income) * beta_cost_share3_1 + cost_share3[i] * beta_cost_share2_2 + tt_share3[i] * beta_tt_share3 + beta_central_share3 * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i]) + (d1[i]+d2[i]) * beta_distance_share3 + beta_zero_share3 *zero_car + beta_oneplus_share3 * one_plus_car + beta_twoplus_share3 * two_plus_car + beta_threeplus_share3 * three_plus_car + beta_female_share3 * female_dummy + AMOD_wtc * cbd_dummy[i] * AMOD_wt + AMOD_wtc * cbd_dummy_origin * (1-cbd_dummy[i]) * AMOD_wt
	end

	--utility function for motor 1-1169
	for i=1,1169 do
		V_counter = V_counter +1
		utility[V_counter] = beta_cons_motor + cost_over_income_motor[i] * (1 - missing_income) * beta_cost_motor_1 + cost_motor[i] * beta_cost_motor_2 + tt_motor[i] * beta_tt_drive1 + beta_central_motor * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i]) + (d1[i]+d2[i]) * beta_distance_motor + beta_zero_motor *zero_motor + beta_oneplus_motor * one_plus_motor + beta_twoplus_motor * two_plus_motor + beta_threeplus_motor * three_plus_motor + beta_female_motor * female_dummy + beta_zero_car_motor*zero_car+beta_oneplus_car_motor*one_plus_car+ beta_twoplus_car_motor*two_plus_car + AMOD_wtc * cbd_dummy[i] * AMOD_wt + AMOD_wtc * cbd_dummy_origin * (1-cbd_dummy[i]) * AMOD_wt
	end

	--utility function for walk 1-1169
	for i=1,1169 do
		V_counter = V_counter +1
		utility[V_counter] = beta_cons_walk + tt_walk[i] * beta_tt_walk + beta_central_walk * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i] + 1) + (d1[i]+d2[i]) * beta_distance_walk + beta_female_walk * female_dummy + beta_zero_walk*zero_car + beta_oneplus_walk*one_plus_car+beta_twoplus_walk*two_plus_car
	end

	--utility function for taxi 1-1169
	for i=1,1169 do
		V_counter = V_counter +1
		utility[V_counter] = beta_cons_taxi + cost_over_income_taxi[i] * (1-missing_income)* beta_cost_taxi_1 + cost_taxi[i]* beta_cost_taxi_2 + tt_taxi[i] * beta_tt_taxi + beta_central_taxi * central_dummy[i] + beta_log * math.log(shop[i]+math.exp(beta_area)*area[i]+math.exp(beta_population)*population[i]) + (d1[i]+d2[i]) * beta_distance_taxi + beta_female_taxi * female_dummy + beta_zero_taxi*zero_car+beta_oneplus_taxi*one_plus_car+beta_twoplus_taxi*two_plus_car
	end

end


--availability
--the logic to determine availability is the same with current implementation
local availability = {}
local function computeAvailabilities(params,dbparams)
	for i = 1, 1169*9 do 
		availability[i] = dbparams:availability(i)
	end
end

--scale
local scale = 1 --for all choices

-- function to call from C++ preday simulator
-- params and dbparams tables contain data passed from C++
-- to check variable bindings in params or dbparams, refer PredayLuaModel::mapClasses() function in dev/Basic/medium/behavioral/lua/PredayLuaModel.cpp
function choose_tmds(params,dbparams)
	computeUtilities(params,dbparams) 
	computeAvailabilities(params,dbparams)
	local probability = calculate_probability("mnl", choice, utility, availability, scale)
	return make_final_choice(probability)
end

-- function to call from C++ preday simulator for logsums computation
-- params and dbparams tables contain data passed from C++
-- to check variable bindings in params or dbparams, refer PredayLuaModel::mapClasses() function in dev/Basic/medium/behavioral/lua/PredayLuaModel.cpp
function compute_logsum_tmds(params,dbparams)
	computeUtilities(params,dbparams) 
	computeAvailabilities(params,dbparams)
	return compute_mnl_logsum(utility, availability)
end

