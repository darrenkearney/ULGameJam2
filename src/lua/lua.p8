pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

--------------------------------------------------------------
-- global parameters
--------------------------------------------------------------
mode = "menu"
lasttime = time()
deltatime = 0
before_menu_setup = true -- action hook
after_menu_setup = false -- action hook
game_started = false
ended_game = false

textlabels = {}
textlabels['menu'] = {'~ ul gamejam 2 ~','theme: simplicity','press z/x/n/m to start','++ credits ++','dave\ndarren\nbrian\njono', ' e\ns f\n d','  \148\n\139  \145\n  \131'}
textlabels['game'] = {'score: ','player1 ','player2 '}
textlabels['end'] = {"game over","wins!","score ","press button for menu"}
textlabels['symbols'] = {'~','#','@','-','+','^','!','|','='}

function update_delta_time()
    local time = time()
    deltatime = time - lasttime
    lasttime = time
end

--------------------------------------------------------------
-- sfx parameters
--------------------------------------------------------------
eating =
{
    1, 2, 3, 4, 5, 6, 7, 8
}


rate_limiters = {}
buttonPress = 0
--------------------------------------------------------------
-- global functions
--------------------------------------------------------------
function play_sound(sound, channel)
    if type(sound) == "table" then
        local soundindex = flr(rnd(#sound) + 1)
        sfx(sound[soundindex], channel)
    else
        sfx(sound, channel)
    end
end

function play_rate_limited_sound(sound, channel, length)
    if not (rate_limiters[channel] and rate_limiters[channel] > 0) then
        rate_limiters[channel] = length
        play_sound(sound, channel)
    end
end

function update_rate_limited_audio()
    for i = 1, #rate_limiters do
        if rate_limiters[i] > 0 then
            rate_limiters[i] -= deltatime
        end
    end
    if buttonPress > 0 then
        buttonPress -= deltatime
    end
end

--------------------------------------------------------------
-- main game jam parameters
--------------------------------------------------------------
jam = {}

jam_width = 100
jam_height = 72
jam_block_size = 8
jam_populated = false
jam_offset_y = 24
jam_offset_x = 8
jam_sprites = {16, 17, 18, 19}
jam_score = 100

function jam_hash_func(vector)
    return flr((vector.x - jam_offset_x) / jam_block_size), flr((vector.y - jam_offset_y) / jam_block_size)
end

function populate_jam()
    if jam_populated then return end
    for y = 1, flr(jam_height/jam_block_size) do
        for x = 1, flr(jam_width/jam_block_size) do
            jam[x] = jam[x] or {}
            jam[x][y] = flr(rnd(4)) + 1
        end
    end
    jam_populated = true
end

function draw_jam()
    local no_jam_left = true
    for y = 1, flr(jam_height/jam_block_size) do
        for x = 1, flr(jam_width/jam_block_size) do
            if jam[x][y] ~= "empty" then
                no_jam_left = false
                spr(jam_sprites[jam[x][y]], x * jam_block_size + jam_offset_x, y * jam_block_size + jam_offset_y)
            end
        end
    end
    if no_jam_left then
        ended_game = true
        mode = "end"
    end
end

--------------------------------------------------------------
-- main menu screen setup
--------------------------------------------------------------
function menu_setup()
    player1.x=24
    player1.y=60
    player2.x=100
    player2.y=60
    -- update global hooks
    before_menu_setup = false
    after_menu_setup = true
end

--------------------------------------------------------------
-- main menu loop
--------------------------------------------------------------
function menuloop()

    if (before_menu_setup) then
        menu_setup()
    end
    if not jam_populated then
        music(5, 300, 3)
        populate_jam()
    end
    if btn(4) or btn(5) and buttonPress <= 0 then
        mode = "game"
        game_started = false
    end
    player_movement(player1)
    player_movement(player2)
end

function menudrawloop()
    cls()
    -- player sprites for onboarding
    spr(player1.sprite,player1.x - 4,player1.y - 4)
    spr(player2.sprite,player2.x - 4,player2.y - 4)
    -- game logo
    spr(64, 36, 36, 56, 28)
    color(2)
    -- decor = textlabels['symbols'][flr(rnd(#textlabels['symbols']))+1] -- fun little doodad
    decor = ""
    print(decor..textlabels['menu'][1]..decor,hcenter(decor..textlabels['menu'][1]..decor), 8, 3)
    print(decor..textlabels['menu'][2]..decor,hcenter(decor..textlabels['menu'][2]..decor), 16, 3)
    print(textlabels['menu'][3],hcenter(textlabels['menu'][3]), 78, 2)
    print(textlabels['menu'][4],hcenter(textlabels['menu'][4]), 84, 2)
    print(textlabels['menu'][5],hcenter(textlabels['menu'][4]), 92, 2)
    print(textlabels['menu'][6],4,100,12)
    print(textlabels['menu'][7],102,100,10)
    color(0)
end

--------------------------------------------------------------
-- main game functions
--------------------------------------------------------------
player1 = {} 
player1.speed = 5
player1.x = 1
player1.y = 1
player1.sprite = 1
player1.score = 0
player1.movesprites={}
player1.movesprites['left']=4
player1.movesprites['right']=2
player1.movesprites['up']=1
player1.movesprites['down']=3

player2 = {} 
player2.speed = 5
player2.x = 10
player2.y = 10
player2.sprite = 5
player2.score = 0
player2.movesprites={}
player2.movesprites['left']=8
player2.movesprites['right']=6
player2.movesprites['up']=5
player2.movesprites['down']=7

top_parameter = 36
bottom_parameter = 100
right_parameter = 108
left_parameter = 20 

--------------------------------------------------------------
-- game start
--------------------------------------------------------------

function game_start()
    sfx(9)
    music(0, 300, 3)
    jam_populated = false
    populate_jam()
    player1.score = 0
    player2.score = 0
    player1.x = flr(rnd(right_parameter - left_parameter) + left_parameter)
    player1.y = flr(rnd (bottom_parameter - top_parameter) + top_parameter)
    player2.x = flr(rnd(right_parameter - left_parameter) + left_parameter)
    player2.y = flr(rnd (bottom_parameter - top_parameter) + top_parameter)
    game_started = true
end

--------------------------------------------------------------
-- main game loop
--------------------------------------------------------------

function clamp_move(pos, speed, param)
    pos += speed
    if(param == left_parameter or param == top_parameter) then
        if(pos < param ) then
            pos = param
        end
    else
        if(pos > param) then
            pos = param
        end
    end
    return pos
end

function player_movement(player)
    local movesprites={}
    if (player == player1) then
        controller = 0
    elseif (player == player2) then
        controller = 1
    end
    --generic player movement
    if (btn(0,controller) and player.x > left_parameter) then
        player.x = clamp_move(player.x, -player.speed,left_parameter)
        player.sprite = player.movesprites['left']
    end
    if (btn(1,controller) and player.x < right_parameter) then
        player.x = clamp_move(player.x, player.speed, right_parameter)
        player.sprite = player.movesprites['right']
    end
    if (btn(2,controller) and player.y > top_parameter) then
        player.y = clamp_move(player.y, -player.speed, top_parameter)
        player.sprite = player.movesprites['up']
    end
    if (btn(3,controller) and player.y < bottom_parameter) then
        player.y = clamp_move(player.y, player.speed, bottom_parameter)
        player.sprite = player.movesprites['down']
    end

end

function gameloop()
    if not game_started then
        game_start()
    end
    player_movement(player1)
    -- player 1 movement

    local x, y = jam_hash_func(player1)
    if jam[x] and jam[x][y] ~= "empty" then
        play_rate_limited_sound(eating, 1, 0.3)
        player1.score += jam_score
        jam[x][y] = "empty"
    end
    
    -- player 2 movement
    player_movement(player2)

    x, y = jam_hash_func(player2)
    if jam[x] and jam[x][y] ~= "empty" then
        play_rate_limited_sound(eating, 2, 0.3)
        player2.score += jam_score
        jam[x][y] = "empty"
    end
end

function gamedrawloop()
    cls()
    draw_jam()
    spr(player1.sprite,player1.x - 4,player1.y - 4)
    spr(player2.sprite,player2.x - 4,player2.y - 4)
    map(0,0,0,0,16,14)
    print(textlabels['game'][1], 2, 2, 9)
    print(player1.score, 32, 2, 10)
    print(player2.score, 62, 2, 12)
end

--------------------------------------------------------------
-- main end screen loop
--------------------------------------------------------------
function endloop()
    if ended_game then
        ended_game = false
        music(-1)
    end
    if btn(4) or btn(5) then
        jam_populated = false
        mode = "menu"
        buttonPress = 300
    end
end

function enddrawloop()
    cls()
    winner={}
    winner.score="great"
    if player1.score > player2.score then
        winner = player1
    else
        winner = player2
    end
    print(textlabels['end'][1],hcenter(textlabels['end'][1]),vcenter(textlabels['end'][1])-12,rnd(3)+7)
    spr(winner.sprite,hcenter(textlabels['end'][2])-6,vcenter(textlabels['end'][2]))
    print(textlabels['end'][2],hcenter(textlabels['end'][2])+6,vcenter(textlabels['end'][2]),rnd(3)+7)
    print(textlabels['end'][3]..winner.score,hcenter(textlabels['end'][3]..winner.score),vcenter(textlabels['end'][3]..winner.score)+12,11)
    print(textlabels['end'][4],hcenter(textlabels['end'][4]),vcenter(textlabels['end'][3])+24,12)
    color(7) -- reset color to white
    print(textlabels['game'][1], 2, 2, 9)
    print(player1.score, 32, 2, 10)
    print(player2.score, 62, 2, 12)
end

--------------------------------------------------------------
-- main update loops
--------------------------------------------------------------
function _update()
    update_rate_limited_audio()
    update_delta_time()
    if mode == "menu" then
        menuloop()
    elseif mode == "game" then
        gameloop()
    elseif mode == "end" then
        endloop()
    end
end


function _draw()
    if mode == "menu" then
        menudrawloop()
    elseif mode == "game" then
        gamedrawloop()
    elseif mode == "end" then
        enddrawloop()
    end
end

--------------------------------------------------------------
-- helper functions
--------------------------------------------------------------

function hcenter(s)
  -- screen center minus the
  -- string length times the 
  -- pixels in a char's width,
  -- cut in half
  return 64-#s*2
end
 
function vcenter(s)
  -- screen center minus the
  -- string height in pixels,
  -- cut in half
  return 61
end
