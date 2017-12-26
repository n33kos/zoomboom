pico-8 cartridge // http://www.pico-8.com
version 15
__lua__

-- utility --------------
function rnd_normal()
  test = rnd(100)
  if test < 49 then
    return -1
  else
    return 1
  end
end

function reverse(arr)
  local i, j = 1, #arr
  while i < j do
    arr[i], arr[j] = arr[j], arr[i]
    i = i + 1
    j = j - 1
  end
  return arr
end

function copy(o)
  local c
  if type(o) == 'table' then
    c = {}
    for k, v in pairs(o) do
    c[k] = copy(v)
    end
  else
    c = o
  end
  return c
end


-- gameplay --------------
function init_everything()
  air_particles = init_air_particles()
  enemies = init_enemies()
  layer_count = 4
  layers = init_layers()
  player = init_player()
  player_score = 0
  restart_counter = 0
  speed = 400
  speed_multiplier = 1
  rings = init_rings()
end

function init_player()
  return {
    pos = { x = 64, y = 64 },
    size = 5,
    col = 3,
    speed = 2,
    is_alive = true,
  }
end

function init_layers()
  local layers = {}

  for i = layer_count, 1, -1 do
    layer = {
      amplitude = 1,
      max_height = 6*(i*i),
      min_height = 6*((i-1)*(i-1)),
      slices = {},
      speed = i*i*200,
      update_counter = 0,
      first_sprite = 56+rnd(7)
    }

    local current = (6*i)
    for j = 1,128 do
      current = rand_height(
        current,
        layer.min_height,
        layer.max_height,
        layer.amplitude
      )
      slice = {
        height = current,
        sprite = layer.first_sprite
      }
      add(layer.slices, slice)
    end

    add(layers, layer)
  end

  return layers
end

function init_air_particles()
  local particles = {}
  for i = 1, 10 do
    local part = {
      col = 7,
      is_visible = true,
      speed = rnd(5),
      pos = { x = rnd(128), y = rnd(128) },
    }
    add(particles, part)
  end
  return particles
end

function init_enemies()
  local enemies = {}
  for i = 1, 3 do
    local enemy = {
      speed = 4+rnd(2),
      pos = { x = rnd(128), y = rnd(128) },
    }
    add(enemies, enemy)
  end
  return enemies
end

function init_rings()
  local rings = {}
  for i = 1, 1 do
    local ring = {
      speed = 3,
      pos = { x = rnd(128)+128, y = rnd(128) },
      is_scored = true,
    }
    add(rings, ring)
  end
  return rings
end

function rand_height(current, min_height, max_height, amplitude)
  return max(
    min_height,
    min(
      max_height,
      current+(rnd(amplitude)*rnd_normal())
    )
  )
end

function draw_layer(layer)
  local cnt = 0
  for slice in all(layer.slices) do
    sspr(layer.first_sprite, 0, 1, 8, cnt, 128-slice.height, 1, slice.height)
    cnt = cnt + 1
  end
end

function get_first_slice(layer)
  for slice in all(layer.slices) do
    return slice
  end
end

function get_last_slice(layer)
  cnt=0
  for slice in all(layer.slices) do
    cnt = cnt+1
    if cnt == 127 then
      return slice
    end
  end
end

function update_slice(layer)
  del(layer.slices, get_first_slice(layer))

  last_slice = copy(get_last_slice(layer))
  last_slice.height = rand_height(
    last_slice.height,
    layer.min_height,
    layer.max_height,
    layer.amplitude
  )
  last_slice.sprite = layer.first_sprite
  add(layer.slices, last_slice)

  return layer
end

function reset_counter(layer)
  if layer.update_counter > layer.speed then
    layer.update_counter = 1
  end
end

function increment_counter(layer)
  layer.update_counter = layer.update_counter+(speed*speed_multiplier)
end

function draw_background()
  rectfill(0, 0, 128, 128, 12)
  for layer in all(layers) do
    increment_counter(layer)
    if layer.update_counter >= layer.speed then
      update_slice(layer)
    end
    reset_counter(layer)
    draw_layer(layer)
  end
end

function draw_air_particles()
  for part in all(air_particles) do
    if part.is_visible then
      rectfill(part.pos.x, part.pos.y, part.pos.x, part.pos.y, part.col)
      part.is_visible = false
    else
      part.is_visible = true
    end
    part.pos.x = part.pos.x-(part.speed*speed_multiplier)
    if (part.pos.x < 0) then
      part.pos.x = 130
      part.pos.y = rnd(128)
    end
  end
end

function draw_player()
  if player.is_alive then
    if (btn(2)) then
      spr(5, player.pos.x, player.pos.y, 2, 2)
      return
    end
    if (btn(3)) then
      spr(1, player.pos.x, player.pos.y, 2, 2)
      return
    end
    spr(3, player.pos.x, player.pos.y, 2, 2)
  else
    spr(8, player.pos.x, player.pos.y, 1, 1)
  end
end

function draw_enemies()
  for enemy in all(enemies) do
    spr(9, enemy.pos.x, enemy.pos.y, 1, 1)
    enemy.pos.x = enemy.pos.x-(enemy.speed*speed_multiplier)
    if (enemy.pos.x < -8) then
      enemy.pos.x = 500+rnd(130)
      enemy.pos.y = rnd(128)
    end
  end
end

function draw_rings()
  for ring in all(rings) do
    if ring.is_scored then
      spr(10, ring.pos.x, ring.pos.y, 1, 2)
    else
      spr(11, ring.pos.x, ring.pos.y, 1, 2)
    end

    ring.pos.x = ring.pos.x-(ring.speed*speed_multiplier)
    if (ring.pos.x < -8) then
      ring.pos.x = 500+rnd(130)
      ring.pos.y = rnd(128)
      ring.is_scored = true
    end
  end
end

function draw_score()
  print(flr(player_score), 1, 1, 7)
  rectfill(0, 7, 30, 7)
  rectfill(30, 0, 30, 7)
end

function player_bounds()
  if player.is_alive then
    local dimensions = { x = 128-16, y = 128-8 }
    if (player.pos.x < 0) player.pos.x = 0
    if (player.pos.x > dimensions.x) player.pos.x = dimensions.x
    if (player.pos.y < 0) player.pos.y = 0
    if (player.pos.y > dimensions.y) player.pos.y = dimensions.y
  end
end

function handle_collisions()
  for enemy in all(enemies) do
    local test = detect_collisions(enemy, 8, 6)
    if test then
      player.is_alive = false
    end
  end

  for ring in all(rings) do
    local test = detect_collisions(ring, 8, 16)
    if (test and ring.is_scored) then
      player_score += 100
      ring.is_scored = false
    end
  end
end

function detect_collisions(entity, scaleX, scaleY)
  c = entity.pos.x;
  d = entity.pos.y;
  a = c+scaleX;
  b = d+scaleY;

  y = player.pos.x;
  z = player.pos.y;
  w = y+16;
  x = z+8;

  local intersect = true
  if(a<w and c<w and a<y and c<y) intersect = false
  if(a>w and c>w and a>y and c>y) intersect = false
  if(b<x and d<x and b<z and d<z) intersect = false
  if(b>x and d>x and b>z and d>z) intersect = false

  return intersect
end

function draw_game_over()
  if player.is_alive == false then
    print("game over", 45, 60, 8)
    restart_counter += 1
    if restart_counter > 50 then
      print("press any key to restart", 18, 70, 8)
      if (btn(0) or btn(1) or btn(2) or btn(3) or btn(4)) then
        init_everything()
      end
    end
  end
end

-- lifecycle --------------
function _init()
  init_everything()
end

function _draw()
  cls()
  draw_background()
  draw_score()
  draw_air_particles()
  draw_player()
  draw_enemies()
  draw_rings()
  draw_game_over()
end

function _update()
  if player.is_alive then
    player.pos.x = player.pos.x - 1
    if (btn(0)) player.pos.x = player.pos.x-player.speed*speed_multiplier
    if (btn(1)) player.pos.x = player.pos.x+player.speed*speed_multiplier
    if (btn(2)) player.pos.y = player.pos.y-player.speed*max(1, speed_multiplier/2)
    if (btn(3)) player.pos.y = player.pos.y+player.speed*max(1, speed_multiplier/2)
    player_bounds()

    speed_multiplier = 1
    if (btn(4)) speed_multiplier = 2
    if (btn(5)) speed_multiplier = 2
    player_score += 0.1*speed_multiplier
  else
    player.pos.x = player.pos.x - 5
  end
  handle_collisions()
end

__gfx__
000000007770000000000000777000000000000000000000000000007777777799a0000000000060000a9000000b300000000000000000000000000000000000
000000000667006670000000066700000000000007770000000000006766766600999a000000666000a9a90000b3b30000000000000000000000000000000000
0070070000667006670000000066700000000000006670000000000066666666099aaaa0e777777a0a900a900b300b3000000000000000000000000000000000
000770000966677777777dd00966677777777dd00966677777777dd066666666009999aa86666669a90000a9b30000b300000000000000000000000000000000
00077000aa66666666666667aa66666666666667aa66666666666667c66666669999aaaa00005550a90000a9b30000b300000000000000000000000000000000
00700700095555566667555509555556666755550955555566675555c6c66cc6009999aa00000050a90000a9b30000b300000000000000000000000000000000
00000000000000066670000000000006667000000000006666700000c6c66ccc099aaaa000000000a90000a9b30000b300000000000000000000000000000000
00000000000000666700000000000066670000000000000000000000cccccccc9a00000000000000a90000a9b30000b300000000000000000000000000000000
00000000000006667000000000000000000000000000000000000000000000000000000000000000a90000a9b30000b300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000a90000a9b30000b300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000a90000a9b30000b300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000a90000a9b30000b300000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000a90000a9b30000b300000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000a900a900b300b3000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000a9a90000b3b30000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000a9000000b300000000000000000000000000000000000
