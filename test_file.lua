require "constants"
require "brain"

INPUT_NODES = 1
OUTPUT_NODES = 1


b = Brain:new()

b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddNode(b)
emu.print(b.connections)
emu.print("")
--[[
b.mutateAddNode(b)
emu.print(b.connections)
emu.print("")
b.mutateAddNode(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)
emu.print("")
b.mutateAddConnection(b)
emu.print(b.connections)--]]