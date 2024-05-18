function get_screen_data()
    local gui = GuiCreate()
    GuiStartFrame( gui )

    local w, h = GuiGetScreenDimensions( gui )
    local real_w, real_h = 1280, 720 -- literally no way to get it properly
    
    GuiDestroy( gui )

    return w, h, real_w, real_h
end

function world2gui( x, y, is_raw )
    is_raw = is_raw or false
    
    local w, h, real_w, real_h = get_screen_data()
    local view_x = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_X" ) + MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_X" )
    local view_y = MagicNumbersGetValue( "VIRTUAL_RESOLUTION_Y" ) + MagicNumbersGetValue( "VIRTUAL_RESOLUTION_OFFSET_Y" )
    local massive_balls_x, massive_balls_y = w/view_x, h/view_y
    
    if( not( is_raw )) then
        local cam_x, cam_y = GameGetCameraPos()
        x, y = ( x - ( cam_x - view_x/2 )), ( y - ( cam_y - view_y/2 ))
    end
    x, y = massive_balls_x*x, massive_balls_y*y
    
    return x, y, {massive_balls_x,massive_balls_y}
end
