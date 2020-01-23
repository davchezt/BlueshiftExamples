local blueshift = require "blueshift"
local Point = blueshift.Point
local Vec2 = blueshift.Vec2
local Plane = blueshift.Plane
local Input = blueshift.Input

properties = {
	knob_radius = { label = "Knob Radius", type = "float", value = 96 },
}

property_names = {
    "knob_radius"
}

m = {
    knob_delta = Vec2(0, 0),
    clicked_id = -1
}

function start()
    local canvas_entity = owner.entity:parent()
    m.canvas = canvas_entity:canvas()
    m.canvas_transform = canvas_entity:transform()
    m.knob_transform = owner.entity:find_child("knob"):transform()
end

function update()
    local touch_count = Input.touch_count()

    if touch_count > 0 then
        local knob_center = owner.transform:origin()
        -- knob center position in screen coordinates
        local knob_screen_center = m.canvas:world_to_screen(knob_center) 
        local knob_screen_radius = properties.knob_radius.value

        for i = 0, touch_count do
            local touch = Input.touch(i)
            if touch:phase() == Input.Touch.Started then
                -- Check if touch screen coordinates are within knob radius.
                if touch:position():distance_squared(knob_screen_center) <= knob_screen_radius * knob_screen_radius then
                    m.clicked_id = touch:id()
                end
            elseif touch:phase() == Input.Touch.Ended or touch:phase() == Input.Touch.Canceled then
                if touch:id() == m.clicked_id then
                    m.clicked_id = -1

                    -- Move knob to center.
                    local knob_local_pos = m.knob_transform:local_origin()
                    knob_local_pos:set(0, 0, 0)
                   
                    m.knob_transform:set_local_origin(knob_local_pos)
                    m.knob_delta:set(0, 0)
                end
            elseif touch:phase() == Input.Touch.Moved then
                if touch:id() == m.clicked_id then
                    m.knob_delta:set_x(touch:position():x() - knob_screen_center:x())
                    m.knob_delta:set_y(touch:position():y() - knob_screen_center:y())

                    if m.knob_delta:length_squared() >= knob_screen_radius * knob_screen_radius then
                        m.knob_delta:normalize()
                        m.knob_delta = m.knob_delta:mul(knob_screen_radius)
                    end

                    local ray = m.canvas:screen_to_ray(knob_screen_center + Point(m.knob_delta:x(), m.knob_delta:y()))

                    local knob_plane = Plane(-m.canvas_transform:axis():at(2), 0)
                    knob_plane:fit_through_point(knob_center)

                    local s = knob_plane:intersect_ray(ray)
                    m.knob_transform:set_origin(ray:origin() + ray:direction():mul(s))

                    -- Normalize.
                    m.knob_delta = m.knob_delta:div(knob_screen_radius)
                end
            end
        end
    end
end