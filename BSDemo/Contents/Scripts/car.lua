local blueshift = require "blueshift"
local ComVehicleWheel = blueshift.ComVehicleWheel
local Input = blueshift.Input

--[properties]--
properties = {
    torque = { label = "Torque", type = "float", value = 160 },
    brakingTorque = { label = "Braking Torque", type = "float", value = 2.5 },
    steering_wheel = { label = "Steering Wheel", type = "object", classname = "ComScript", value = nil },
    clunk_sound = { label = "Sounds/Clunk", type = "object", classname = "SoundResource", value = nil },
    accel_sound = { label = "Sounds/Accel", type = "object", classname = "SoundResource", value = nil },
    skid_sound = { label = "Sounds/Skid", type = "object", classname = "SoundResource", value = nil },
}

m = {
    drive = true,
	front_wheels = {},
	wheels = {},
	steering_angle = 0,
	torque = 0,
	brakingTorque = 0,
    skid_time = 0
}

function start()
    -- Get steering wheel script state
    local steering_wheel_script = properties.steering_wheel.value:cast_script()
    m.steering_wheel_state = _G[steering_wheel_script:sandbox_name()]

	local components = owner.entity:components_in_children(ComVehicleWheel.meta_object)

	for i = 0, components:count() - 1 do 
		 local vehicle_wheel = components:at(i):cast_vehicle_wheel()
		 if vehicle_wheel then
		 	m.wheels[#m.wheels + 1] = vehicle_wheel

			 if vehicle_wheel:entity():transform():local_origin():x() > 0 then
			 	m.front_wheels[#m.front_wheels + 1] = vehicle_wheel
			 end
		end
	end

    if properties.accel_sound.value then
        m.accel_sound = properties.accel_sound.value:cast_asset():sound():instantiate()
    end

    if properties.skid_sound.value then
        m.skid_sound = properties.skid_sound.value:cast_asset():sound():instantiate()
    end
end

function update()
    m.torque = 0
    m.brakingTorque = 0

    if m.steering_wheel_state then
        m.steering_angle = 40 * m.steering_wheel_state.m.wheel_angle / m.steering_wheel_state.properties.wheel_max_angle.value
    end

    if m.brake_pedal or Input.is_key_pressed(Input.KeyCode.Space) then
        m.brakingTorque = properties.brakingTorque.value
    end

    if m.drive then -- drive
        if m.accel_pedal or Input.is_key_pressed(Input.KeyCode.UpArrow) then
            m.torque = properties.torque.value
        end
    else -- reverse
        if m.accel_pedal or Input.is_key_pressed(Input.KeyCode.UpArrow) then
            m.torque = -properties.torque.value
        end
    end    

	for i = 1, #m.front_wheels do
    	m.front_wheels[i]:set_steering_angle(m.steering_angle)
        m.front_wheels[i]:set_torque(m.torque)
    end

    for i = 1, #m.wheels do
    	m.wheels[i]:set_braking_torque(m.brakingTorque)
    end

    local velocity = owner.entity:rigid_body():linear_velocity()
    local speed_km = blueshift.unit_to_meter(velocity:length()) * 3.6

    if speed_km > 40 then
        for i = 1, #m.wheels do
            local skid_info = m.wheels[i]:skid_info()

            if skid_info > 0 and skid_info < 0.2 then
                m.skid_time = owner.game_world:time()
            end
        end
    end

    if m.skid_sound then
        if owner.game_world:time() - m.skid_time < 200 then
            local volume = math.max(math.min((speed_km - 40) / 100, 1.0), 0.1)
            if m.skid_sound:is_playing() then
                m.skid_sound:set_volume(volume)
            else
                m.skid_sound:play2d(volume, true)
            end
        elseif m.skid_sound:is_playing() then
            m.skid_sound:stop()
        end
    end
end

function on_button(name, pressed)
    if name == "Accel Pedal" then
        m.accel_pedal = pressed
    elseif name == "Brake Pedal" then
        m.brake_pedal = pressed
    end
end

function on_clicked(name)
    m.drive = not m.drive

    local button = owner.game_world:find_entity(name)
    button:find_child("Text"):text():set_text(m.drive and "D" or "R")
end