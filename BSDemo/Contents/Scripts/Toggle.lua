local blueshift = require "blueshift"
local Color3 = blueshift.Color3
local ComScript = blueshift.ComScript
local EntityPtrArray = blueshift.EntityPtrArray

--[properties]--
properties = {
	target = { label = "Target", type = "object", classname = "Entity", value = nil },
	normal_color = { label = "Normal Color", type = "color3", value = Color3(1.0, 1.0, 1.0) },
	hover_color = { label = "Hover Color", type = "color3", value = Color3(0.8, 0.8, 0.8) },
	press_color = { label = "Press Color", type = "color3", value = Color3(0.5, 0.5, 0.5) },
    disable_color = { label = "Disable Color", type = "color3", value = Color3(0.3, 0.3, 0.3) },
    background = { label = "Background", type = "object", classname = "ComImage", value = nil },
    checkmark = { label = "Check Mark", type = "object", classname = "ComImage", value = nil },
    is_on = { label = "Is On", type = "bool", value = false },
	click_sound = { label = "Click Sound", type = "object", classname = "SoundResource", value = nil },
}

m = {
	pressed = false,
	hover = false,
    enabled = true,
	target_script_states = {},
}

function awake()
    m.checked = properties.is_on.value

    if properties.click_sound.value then
		m.click_sound = properties.click_sound.value:cast_asset():sound()
	end

    -- List up target script states
    m.target_script_states = {}
    local target_entity = properties.target.value and properties.target.value:cast_entity()
    if target_entity then
        local script_components = target_entity:components(ComScript.meta_object)
        for i = 0, script_components:count() - 1 do
            local script = script_components:at(i):cast_script()
            local script_state = _G[script:sandbox_name()]
            
            if script_state.on_checked then
               table.insert(m.target_script_states, script_state)
            end
        end
    end

    -- Background
    m.background_image = properties.background.value and properties.background.value:cast_image()

    -- Checkmark    
    m.checkmark_image = properties.checkmark.value and properties.checkmark.value:cast_image()
    if m.checkmark_image then
        m.checkmark_image:set_alpha(m.checked and 1.0 or 0.0)
    end
end

function on_enable()
    if m.background_image then
        m.background_image:set_color(properties.normal_color.value)
    end

    if m.checkmark_image then
        m.checkmark_image:set_alpha(m.checked and 1.0 or 0.0)
    end
end

function on_disable()
    m.background_color_tweener = nil

    m.checkmark_alpha_tweener = nil
end

function update()
    if m.background_color_tweener then
        if not tween.update(m.background_color_tweener, owner.game_world:unscaled_delta_time()) then
            m.background_color_tweener = nil
        end
    end

    if m.checkmark_alpha_tweener then
        if not tween.update(m.checkmark_alpha_tweener, owner.game_world:unscaled_delta_time()) then
            m.checkmark_alpha_tweener = nil
        end
    end
end

function set_enable(enable)
    m.enabled = enable
end

function set_disable(disable)
    set_enable(not disable)
end

function is_checked()
    return m.checked
end

function set_checked(checked) 
    m.checked = checked
    
    local target_alpha = m.checked and 1.0 or 0.0

    if m.checkmark_image then
        m.checkmark_alpha_tweener = tween.create(tween.EaseOutQuadratic, 150, m.checkmark_image:alpha(), target_alpha, function(alpha)
            m.checkmark_image:set_alpha(alpha)
        end)
    end

    for i = 1, #m.target_script_states do
        m.target_script_states[i].on_checked(owner.name, checked)
    end
end

function on_pointer_down()
    if not m.enabled then
        return
    end
    
    if m.background_image then
        m.background_color_tweener = tween.create(tween.EaseOutQuadratic, 100, m.background_image:color(), properties.press_color.value, function(color)
            m.background_image:set_color(color)
        end)
    end
    
    m.pressed = true
end

function on_pointer_up()
    if not m.enabled then
        return
    end
    
	local color
	if m.hover then
		color = properties.hover_color.value
	else
		color = properties.normal_color.value
	end
    
    if m.background_image then
        m.background_color_tweener = tween.create(tween.EaseOutQuadratic, 100, m.background_image:color(), color, function(color)
            m.background_image:set_color(color)
        end)
    end

	m.pressed = false
end

function on_pointer_enter()
    if not m.enabled then
        return
    end
        
    local color
	if m.pressed then
        color = properties.press_color.value
    else
        color = properties.hover_color.value
    end

    if m.background_image then
        m.background_color_tweener = tween.create(tween.EaseOutQuadratic, 150, m.background_image:color(), color, function(color)
            m.background_image:set_color(color)
        end)
    end

	m.hover = true
end

function on_pointer_exit()
    if not m.enabled then
        return
    end
    
    if background_image then
    	m.background_color_tweener = tween.create(tween.EaseOutQuadratic, 150, m.background_image:color(), properties.normal_color.value, function(color)
            m.background_image:set_color(color)
        end)
    end

	m.hover = false
end

function on_pointer_click()
    if not m.enabled then
        return
    end

    set_checked(not m.checked)

    if m.click_sound then
        m.click_sound:instantiate():play2d(1.0, false)
    end
end

