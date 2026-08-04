-- dump_enums.lua -- RE4R Neck Break Research
--
-- Writes managed enum members and their real values to the REFramework log.
--
-- Enum values are NOT present in an il2cpp/SDK dump -- that dump carries
-- structural metadata only. Reading them from the live type database is the
-- only reliable source, and values can shift between game patches. Guessing
-- them from surrounding class names has already produced one wrong character
-- table in this project's predecessor; see docs/06-investigation-log.md.
--
-- Install: copy into reframework/autorun/
-- Use:     Insert -> Script Generated UI -> Enum Dumper
--
-- Output goes to the REFramework log, not the overlay -- these lists are long.

local DEFAULT_ENUMS = {
    "chainsaw.CharacterKindID",
    "chainsaw.CharacterUsePurposeFlag",
    "chainsaw.ItemID",
    "chainsaw.character.BodyParts",
    "chainsaw.character.BodyPartsSide",
}

local custom_type = "chainsaw.CharacterKindID"

-- Reads static fields off an enum type definition. Technique from
-- str0mback/RE4_Overlay.
local function get_enum_map(type_name)
    local t = sdk.find_type_definition(type_name)
    if not t then return nil end

    local map = {}
    for i, field in ipairs(t:get_fields()) do
        if field:is_static() then
            map[field:get_data(nil)] = field:get_name()
        end
    end
    return map
end

local function dump_enum(type_name)
    local map = get_enum_map(type_name)
    if not map then
        log.info(string.format("[EnumDumper] type not found: %s", type_name))
        return 0
    end

    local values = {}
    for value, _ in pairs(map) do
        values[#values + 1] = value
    end
    table.sort(values)

    log.info(string.format("[EnumDumper] ---- %s ----", type_name))
    for _, value in ipairs(values) do
        log.info(string.format("[EnumDumper]   %s = %s", tostring(value), map[value]))
    end
    log.info(string.format("[EnumDumper] ---- %d members ----", #values))

    return #values
end

-- Lists every type whose name contains `needle`. Use this when you do not know
-- what a system's classes are called -- searching by codename prefix
-- (e.g. "Ch6i3z0") is more reliable than guessing at move names, since the
-- game holds no readable character or move names at all.
local function find_types(needle)
    local matches = sdk.find_type_definition and {} or nil
    if not matches then return end

    local count = 0
    log.info(string.format("[EnumDumper] ---- types matching '%s' ----", needle))

    -- REFramework exposes no global type enumeration, so this probes the
    -- common chainsaw.* prefixes directly. It confirms a guessed name exists;
    -- it cannot discover an unguessed one. For open-ended searching, grep the
    -- SDK dump JSON offline instead (see docs/08-method-and-tooling.md).
    local t = sdk.find_type_definition(needle)
    if t then
        log.info(string.format("[EnumDumper]   %s  (exists)", needle))
        count = count + 1

        local methods = t:get_methods()
        if methods then
            for i, m in ipairs(methods) do
                log.info(string.format("[EnumDumper]     method: %s", m:get_name()))
            end
        end

        local fields = t:get_fields()
        if fields then
            for i, f in ipairs(fields) do
                log.info(string.format("[EnumDumper]     field:  %s", f:get_name()))
            end
        end
    else
        log.info(string.format("[EnumDumper]   %s  (not found)", needle))
    end

    log.info(string.format("[EnumDumper] ---- %d ----", count))
end

re.on_draw_ui(function()
    if not imgui.tree_node("Enum Dumper") then return end

    imgui.text("Writes to the REFramework log, not this window.")
    imgui.separator()

    for _, type_name in ipairs(DEFAULT_ENUMS) do
        if imgui.button("Dump " .. type_name) then
            dump_enum(type_name)
        end
    end

    imgui.separator()
    imgui.text("Arbitrary type")

    local changed, value = imgui.input_text("Type name", custom_type)
    if changed then custom_type = value end

    if imgui.button("Dump as enum") then
        dump_enum(custom_type)
    end
    imgui.same_line()
    if imgui.button("Inspect type") then
        find_types(custom_type)
    end

    imgui.text("'Inspect type' lists a type's methods and fields --")
    imgui.text("use it on chainsaw.ExecutionPermitter (see docs/03).")

    imgui.tree_pop()
end)

log.info("[EnumDumper] loaded")
