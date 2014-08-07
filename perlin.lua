rand = { mySeed = 1, lastN = -1 }

function rand:get(seed, n)
  if n <= 0 then n = -2 * n
  else n = 2 * n - 1
  end

  if seed ~= self.mySeed or self.lastN < 0 or n <= self.lastN then
    self.mySeed = seed
    math.randomseed(seed)
    self.lastN = -1
  end
  while self.lastN < n do
    num = math.random()
    self.lastN = self.lastN + 1
  end
  return num - 0.5
end

function rand:num()
  rand.lastN = -1
  return math.random() - 0.5
end

-- takes table of L values and returns N*(L-3) interpolated values
function interpolate1D(values, N)
  newData = {}
  for i = 1, #values - 3 do
    P = (values[i+3] - values[i+2]) - (values[i] - values[i+1])
    Q = (values[i] - values[i+1]) - P
    R = (values[i+2] - values[i])
    S = values[i+1]
    for j = 0, N-1 do
      x = j/N
      table.insert(newData, P*x^3 + Q*x^2 + R*x + S)
    end
  end
  return newData
end

function perlinComponent1D(seed, length, N, amplitude)
  rawData = {}
  finalData = {}
  for i = 1, math.ceil(length/N) + 3 do
    rawData[i] = amplitude * rand:get(seed, i)
  end
  interpData = interpolate1D(rawData, N)
  assert(#interpData >= length)
  for i = 1, length do
    finalData[i] = interpData[i]
  end
  return finalData
end

function perlin1D(seed, length, persistence, N, amplitude)
  data = {}
  for i = 1, length do
    data[i] = 0
  end
  for i = N, 1, -1 do
    compInterp = 2^(i-1)
    compAmplitude = amplitude * persistence^(N-i)
    comp = perlinComponent1D(seed+i, length, i, compAmplitude)
    for i = 1, length do
      data[i] = data[i] + comp[i]
    end
  end
  return data
end

function interpolate2D(values, N)
  newData1 = {}
  for r = 1, #values do
    newData1[r] = {}
    for c = 1, #values[r] - 3 do
      P = (values[r][c+3] - values[r][c+2]) - (values[r][c] - values[r][c+1])
      Q = (values[r][c] - values[r][c+1]) - P
      R = (values[r][c+2] - values[r][c])
      S = values[r][c+1]
      for j = 0, N-1 do
        x = j/N
        table.insert(newData1[r], P*x^3 + Q*x^2 + R*x + S)
      end
    end
  end
  
  newData2 = {}
  for r = 1, (#newData1-3) * N do
    newData2[r] = {}
  end
  for c = 1, #newData1[1] do
    for r = 1, #newData1 - 3 do
      P = (newData1[r+3][c] - newData1[r+2][c]) - (newData1[r][c] - newData1[r+1][c])
      Q = (newData1[r][c] - newData1[r+1][c]) - P
      R = (newData1[r+2][c] - newData1[r][c])
      S = newData1[r+1][c]
      for j = 0, N-1 do
        x = j/N
        newData2[(r-1)*N+j+1][c] = P*x^3 + Q*x^2 + R*x + S
      end
    end
  end
  
  return newData2
end

function perlinComponent2D(seed, width, height, N, amplitude)
  rawData = {}
  finalData = {}
  for r = 1, math.ceil(height/N) + 3 do
    rawData[r] = {}
    for c = 1, math.ceil(width/N) + 3 do
      rawData[r][c] = amplitude * rand:get(seed+r, c)
    end
  end
  interpData = interpolate2D(rawData, N)
  assert(#interpData >= height and #interpData[1] >= width)
  for r = 1, height do
    finalData[r] = {}
    for c = 1, width do
      finalData[r][c] = interpData[r][c]
    end
  end
  return finalData
end

function perlin2D(seed, width, height, persistence, N, amplitude)
  local min, max = 0, 0
  data = {}
  for r = 1, height do
    data[r] = {}
    for c = 1, width do
      data[r][c] = 0
    end
  end
  for i = N, 1, -1 do
    compInterp = 2^(i-1)
    compAmplitude = amplitude * persistence^(N-i)
    comp = perlinComponent2D(seed+i*1000, width, height, compInterp, compAmplitude)
    for r = 1, height do
      for c = 1, width do
        data[r][c] = (data[r][c] + comp[r][c]) * 100
        if(data[r][c] < min) then
          min = data[r][c]
        end
        if(data[r][c] > max) then
          max = data[r][c]
        end
      end
    end
  end
  return data, min, max
end

function plot1D(values)
  love.graphics.line(0, love.graphics.getHeight()/2 - 200, love.graphics.getWidth(), love.graphics.getHeight()/2 - 200)
  love.graphics.line(0, love.graphics.getHeight()/2 + 200, love.graphics.getWidth(), love.graphics.getHeight()/2 + 200)
  for i = 1, #values - 1 do
    love.graphics.line((i-1)/(#values-1)*love.graphics.getWidth(), love.graphics.getHeight()/2 - values[i] * 400, (i)/(#values-1)*love.graphics.getWidth(), love.graphics.getHeight()/2 - values[i+1] * 400)
  end
end

function plot2D(values)
  for r = 1, #values do
    for c = 1, #(values[1]) do
      love.graphics.setColor(128 + 80 * values[r][c], 128 + 80 * values[r][c], 128 + 80 * values[r][c], 255)
      love.graphics.rectangle("fill", (c-1)/(#(values[1]))*love.graphics.getWidth(), (r-1)/(#values)*love.graphics.getHeight(), love.graphics.getWidth()/#(values[1]), love.graphics.getHeight()/#values)
    end
  end
end

local ansicolors = require 'ansicolors'

local seed = 101010101
local height = 1000
local width = 1000
local N = 50
local persistance = 9
local amplitude = 1

local map, min, max = perlin2D(seed, height, width, N, persistance, amplitude)

local colors = {
  '%{whitebg}',
  '%{magentabg}',
  '%{bluebg}',
  '%{cyanbg}',
  '%{greenbg}',
  '%{yellowbg}',
  '%{redbg}',
  '%{blackbg}',
}

local lookup = function(min, max, value, normal, flatness)
  local flatness = flatness or 1
  local range = max - min

  local adjustedValue = (value - min) / flatness

  local height = math.max(math.ceil((adjustedValue / range) * normal), 1)

  return height
end

function terminalMap()
  local val = 0

  for _, y in pairs(map) do
    for _, height in pairs(y) do
      local val = lookup(min, max, height, #colors, 1)
      local color = colors[val]
      io.write(ansicolors(color .. val))
    end
    io.write('\n')
    io.flush()
  end
end

function htmlMap()
  local file = io.open("world.js", "w")
  local mapIndex, y, x, i, height, val
  local normal = 16

  file:write(string.format('window.min = %d;', min))
  file:write(string.format('window.max = %d;', max))
  file:write('window.heightmap = [\n')

  for mapIndex, y in pairs(map) do
    file:write('\n  [')

    for i, height in pairs(y) do
      local val = lookup(min, max, height, normal, 1)
      file:write(val .. ',')
    end

    file:write('  ],')
    file:flush()
  end

  file:write('];')

  file:close()
end

--terminalMap()
htmlMap()
