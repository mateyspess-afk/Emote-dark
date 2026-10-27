-- isso server pra funcionar o emote freeze e emote speed nada de exploit o script nunca mexe nos sistema do jogo apenas mexe no próprio script 100% safe

if type(getfenv) == "function" and type(setfenv) == "function" and type(setmetatable) == "function" then
    setfenv(1, setmetatable({}, { __index = getfenv() }))
end

--[[ 
    Source script taken from: https://github.com/Roblox/creator-docs/blob/main/content/en-us/characters/emotes.md

    scriptblox: https://scriptblox.com/script/Universal-Script-7yd7-I-Emote-Script-48024
]]


STARTUP_WEBHOOK_URL = "https://discord.com/api/webhooks/1553781884646072331/S7Xh-v41IIWjvrH276HI6y9j-roatP6Zk_dDx3dWEUUaRDNsc-lA-8RDlALxR4Z0XYdS"
BUG_REPORT_WEBHOOK_URL = "https://discord.com/api/webhooks/1553853076841168936/VqGX1gg4l2oPGa5rEL83y7sQNRGGgdjeiIHqr9HzfUYBagG0ML1_Sh08EZ9liAagDpoz"
BUG_REPORT_WEBHOOK_ENV_NAME = "EMOTES_DARK_BUG_WEBHOOK"
SUGGESTION_WEBHOOK_URL = "https://discord.com/api/webhooks/1555403046375137340/KW7qSObHz1TEQect1ugSwAenlly-tIR5fBzqYhswXlQt9_OAtc-s836NAPrRf4V3KbtS"
SUGGESTION_WEBHOOK_ENV_NAME = "EMOTES_DARK_SUGGESTION_WEBHOOK"
BUG_REPORT_COOLDOWN_SECONDS = 15 * 60 * 60 -- 15 horas por usuário
SUGGESTION_COOLDOWN_SECONDS = 5 * 60 * 60 -- 5 horas, separado dos reports de bug
BUG_REPORT_MIN_LENGTH = 20
BUG_REPORT_MESSAGE_LIMIT = 3800
BUG_REPORT_COOLDOWN_PATH = "dark/EmotesBugReportCooldown.json"
SUGGESTION_COOLDOWN_PATH = "dark/EmotesSuggestionCooldown.json"
FAVORITE_STAR_RGB_SPEED = 0.45
BUG_REPORT_COOLDOWN_API_ENV_NAME = "EMOTES_DARK_BUG_COOLDOWN_API"
BUG_REPORT_LINK_KICK_SECONDS = 5 * 60
BUG_REPORT_LINK_KICK_PATH = "dark/EmotesBugReportLinkKick.json"

-- Donos nunca recebem kick por causa de links no report bug.
OWNER_USER_IDS = {
    [10956940752] = true,
}

-- Usuários impedidos de usar este script: [UserId] = "motivo".
SCRIPT_BLACKLIST = {
    -- [123456789] = "Motivo do banimento",
    [4327643079] = "Submitting a bug report containing insults and sexually explicit language.",
}

local blacklistedPlayer = game:GetService("Players").LocalPlayer
if blacklistedPlayer then
    local blacklistReason = SCRIPT_BLACKLIST[blacklistedPlayer.UserId]
        or SCRIPT_BLACKLIST[tostring(blacklistedPlayer.UserId)]
    if blacklistReason then
        pcall(function()
            blacklistedPlayer:Kick("Você está banido do nosso script\nMotivo: " .. tostring(blacklistReason))
        end)
        return
    end
end

function emotesDarkIsLinkKickExempt(player)
    if not player then return false end
    if OWNER_USER_IDS[player.UserId] then return true end

    local creatorType = game.CreatorType
    if creatorType == Enum.CreatorType.User then
        return tonumber(game.CreatorId) == player.UserId
    end

    if creatorType == Enum.CreatorType.Group then
        local ok, groupInfo = pcall(function()
            return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
        end)
        return ok and groupInfo and groupInfo.Owner and tonumber(groupInfo.Owner.Id) == player.UserId
    end

    return false
end

function emotesDarkReadLinkKickData()
    local data = {}
    if type(isfile) == "function" and type(readfile) == "function" and isfile(BUG_REPORT_LINK_KICK_PATH) then
        local ok, raw = pcall(readfile, BUG_REPORT_LINK_KICK_PATH)
        if ok and raw and raw ~= "" then
            local decodedOk, decoded = pcall(function()
                return game:GetService("HttpService"):JSONDecode(raw)
            end)
            if decodedOk and type(decoded) == "table" then
                data = decoded
            end
        end
    end
    return data
end

function emotesDarkWriteLinkKickData(data)
    if type(writefile) ~= "function" then return end
    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("dark") then
            makefolder("dark")
        end
        writefile(BUG_REPORT_LINK_KICK_PATH, game:GetService("HttpService"):JSONEncode(data))
    end)
end

emotesDarkLanguageCache = nil

function emotesDarkDetectLanguage()
    if emotesDarkLanguageCache then return emotesDarkLanguageCache end

    local localeId = ""
    pcall(function()
        localeId = tostring(game:GetService("LocalizationService").RobloxLocaleId or ""):lower()
    end)
    emotesDarkLanguageCache = localeId:match("^([a-z]+)") or "en"
    return emotesDarkLanguageCache
end

emotesDarkTranslateText = nil
emotesDarkTranslateNotificationPayload = nil

BUG_REPORT_TRANSLATIONS = {
    en = {
        title = "REPORT A BUG", hint = "Explain what happened and how to reproduce it. Minimum: 20 characters.",
        placeholder = "E.g.: opening emote X freezes the animation and the button stops responding...", send = "SEND REPORT",
        suggestionsTab = "SUGGESTIONS", bugsTab = "BUG REPORTS", suggestionTitle = "SUGGESTION",
        suggestionHint = "Describe your suggestion. Minimum: 20 characters.", suggestionPlaceholder = "E.g.: add a way to save more favorite emotes...", suggestionSend = "SEND SUGGESTION",
        suggestionSent = "Suggestion sent: %s", suggestionSentNotify = "Suggestion sent successfully",
        links = "Links are not allowed in reports.", kicked = "Links are not allowed in reports. You are kicked for 5 minutes.",
        activeKick = "You are temporarily kicked for 5 minutes because of a link in a report.", minLength = "Write a report with at least 20 characters.",
        cooldown = "Cooldown active: %s", wait = "Wait %s.", sending = "Sending report...", sent = "Report sent: %s", sentNotify = "Report sent successfully",
        ownerLinks = "Links are not allowed.", webhook = "Configure EMOTES_DARK_BUG_WEBHOOK before sending.", suggestionWebhook = "Configure EMOTES_DARK_SUGGESTION_WEBHOOK before sending suggestions.", player = "Local player not found.",
        globalConfig = "Global cooldown server is not configured.", globalUnavailable = "Global cooldown server is unavailable.", globalRejected = "Global cooldown server rejected the report.", globalInvalid = "Could not validate the global cooldown.",
    },
    pt = {
        title = "REPORTAR BUG", hint = "Explique o que aconteceu e como reproduzir. Mínimo: 20 caracteres.",
        placeholder = "Ex.: abrir o emote X congela a animação e o botão para de responder...", send = "ENVIAR REPORT",
        suggestionsTab = "SUGESTÕES", bugsTab = "REPORTAR BUGS", suggestionTitle = "SUGESTÃO",
        suggestionHint = "Descreva sua sugestão. Mínimo: 20 caracteres.", suggestionPlaceholder = "Ex.: adicionar uma forma de salvar mais emotes favoritos...", suggestionSend = "ENVIAR SUGESTÃO",
        suggestionSent = "Sugestão enviada: %s", suggestionSentNotify = "Sugestão enviada com sucesso",
        links = "Links não são permitidos em sugestões ou reports.", kicked = "Links não são permitidos em sugestões ou reports. Você levou kick por 5 minutos.",
        activeKick = "Você está temporariamente expulso por 5 minutos por enviar um link no report.", minLength = "Escreva um report com pelo menos 20 caracteres.",
        cooldown = "Cooldown ativo: %s", wait = "Aguarde %s.", sending = "Enviando report...", sent = "Report enviado: %s", sentNotify = "Report enviado com sucesso",
        ownerLinks = "Links não são permitidos.", webhook = "Configure EMOTES_DARK_BUG_WEBHOOK antes de enviar.", suggestionWebhook = "Configure EMOTES_DARK_SUGGESTION_WEBHOOK antes de enviar sugestões.", player = "Jogador local não encontrado.",
        globalConfig = "O servidor de cooldown global não está configurado.", globalUnavailable = "O servidor de cooldown global está indisponível.", globalRejected = "O servidor de cooldown global rejeitou o report.", globalInvalid = "Não foi possível validar o cooldown global.",
    },
    es = {
        title = "REPORTAR BUG", hint = "Explica qué ocurrió y cómo reproducirlo. Mínimo: 20 caracteres.",
        placeholder = "Ej.: abrir el emote X congela la animación y el botón deja de responder...", send = "ENVIAR REPORTE",
        suggestionsTab = "SUGERENCIAS", bugsTab = "REPORTAR BUGS", suggestionTitle = "SUGERENCIA",
        suggestionHint = "Describe tu sugerencia. Mínimo: 20 caracteres.", suggestionPlaceholder = "Ej.: agregar una forma de guardar más emotes favoritos...", suggestionSend = "ENVIAR SUGERENCIA",
        suggestionSent = "Sugerencia enviada: %s", suggestionSentNotify = "Sugerencia enviada correctamente",
        links = "No se permiten enlaces en sugerencias o reportes.", kicked = "No se permiten enlaces en sugerencias o reportes. Recibiste un kick de 5 minutos.",
        activeKick = "Estás expulsado temporalmente durante 5 minutos por enviar un enlace en el reporte.", minLength = "Escribe un reporte con al menos 20 caracteres.",
        cooldown = "Cooldown activo: %s", wait = "Espera %s.", sending = "Enviando reporte...", sent = "Reporte enviado: %s", sentNotify = "Reporte enviado correctamente",
        ownerLinks = "No se permiten enlaces.", webhook = "Configura EMOTES_DARK_BUG_WEBHOOK antes de enviar.", suggestionWebhook = "Configura EMOTES_DARK_SUGGESTION_WEBHOOK antes de enviar sugerencias.", player = "No se encontró al jugador local.",
        globalConfig = "El servidor de cooldown global no está configurado.", globalUnavailable = "El servidor de cooldown global no está disponible.", globalRejected = "El servidor de cooldown global rechazó el reporte.", globalInvalid = "No se pudo validar el cooldown global.",
    },
}

emotesDarkBugTranslationCache = {}

function getBugReportTranslation(language)
    if emotesDarkBugTranslationCache[language] then
        return emotesDarkBugTranslationCache[language]
    end

    local known = BUG_REPORT_TRANSLATIONS[language]
    if known then
        emotesDarkBugTranslationCache[language] = known
        return known
    end

    local source = BUG_REPORT_TRANSLATIONS.en
    if type(emotesDarkTranslateText) ~= "function" then
        return source
    end

    local translated = {}
    for key, value in pairs(source) do
        if type(value) == "string" then
            translated[key] = emotesDarkTranslateText(value, language)
        elseif type(value) == "table" then
            translated[key] = {}
            for nestedKey, nestedValue in pairs(value) do
                translated[key][nestedKey] = type(nestedValue) == "string" and emotesDarkTranslateText(nestedValue, language) or nestedValue
            end
        else
            translated[key] = value
        end
    end
    emotesDarkBugTranslationCache[language] = translated
    return translated
end

function emotesDarkBugText(key, ...)
    local translations = getBugReportTranslation(emotesDarkDetectLanguage()) or BUG_REPORT_TRANSLATIONS.en
    local value = translations[key] or BUG_REPORT_TRANSLATIONS.en[key] or key
    if select("#", ...) > 0 then return string.format(value, ...) end
    return value
end

function emotesDarkContainsLink(value)
    local text = tostring(value or ""):lower()
    if text:find("http://", 1, true) or text:find("https://", 1, true) then
        return true
    end
    if text:find("www%.") then
        return true
    end
    return text:find("%f[%w][%w%-]+%.[a-z][a-z]+%f[^%w]") ~= nil
end

function emotesDarkRegisterLinkKick(player)
    if not player or emotesDarkIsLinkKickExempt(player) then return false end
    local data = emotesDarkReadLinkKickData()
    data[tostring(player.UserId)] = os.time() + BUG_REPORT_LINK_KICK_SECONDS
    emotesDarkWriteLinkKickData(data)
    pcall(function()
        player:Kick(emotesDarkBugText("kicked"))
    end)
    return true
end

function emotesDarkEnforceLinkKick()
    local player = game:GetService("Players").LocalPlayer
    if not player then return false end

    local data = emotesDarkReadLinkKickData()
    local key = tostring(player.UserId)
    if emotesDarkIsLinkKickExempt(player) then
        if data[key] ~= nil then
            data[key] = nil
            emotesDarkWriteLinkKickData(data)
        end
        return false
    end

    local expiresAt = tonumber(data[key]) or 0
    if expiresAt > os.time() then
        pcall(function()
            player:Kick(emotesDarkBugText("activeKick"))
        end)
        return true
    end

    if data[key] ~= nil then
        data[key] = nil
        emotesDarkWriteLinkKickData(data)
    end
    return false
end

if emotesDarkEnforceLinkKick() then
    return
end

MAX_FIELD_LENGTH = 1024
MAX_BIO_LENGTH = 150

function emotesDarkExecutorEnv()
    if type(getgenv) == "function" then
        local ok, env = pcall(getgenv)
        if ok and type(env) == "table" then return env end
    end
    return _G
end

function emotesDarkReadField(object, key)
    if object == nil then return nil end
    local ok, value = pcall(function() return object[key] end)
    return ok and value or nil
end

function emotesDarkGetRequest()
    local env = emotesDarkExecutorEnv()
    local candidates = {
        http_request,
        emotesDarkReadField(syn, "request"),
        emotesDarkReadField(http, "request"),
        emotesDarkReadField(fluxus, "request"),
        emotesDarkReadField(env, "request"),
        emotesDarkReadField(_G, "request"),
    }
    for _, candidate in ipairs(candidates) do
        if type(candidate) == "function" then return candidate end
    end
    return nil
end

function emotesDarkNotify(payload)
    local notify = emotesDarkReadField(emotesDarkExecutorEnv(), "Notify")
    local outgoing = emotesDarkTranslateNotificationPayload(payload)
    if type(notify) == "function" then
        pcall(notify, outgoing)
    elseif outgoing and outgoing.Content then
        warn("[EmotesDark] " .. tostring(outgoing.Content))
    end
end

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
TweenService = game:GetService("TweenService")

function emotesDarkResponseBody(response)
    if type(response) == "string" then return response end
    if type(response) ~= "table" then return nil end
    return response.Body or response.body or response.Data or response.data
end

function emotesDarkUsableBody(body)
    if type(body) ~= "string" or body == "" then return nil end
    local prefix = body:sub(1, 256):lower()
    if prefix:find("<!doctype") or prefix:find("<html") or prefix:find("<head") then return nil end
    return body
end

function emotesDarkDownload(url)
    if type(url) ~= "string" or url == "" then return nil end

    local client = emotesDarkGetRequest()
    if client then
        local ok, response = pcall(client, {
            Url = url,
            Method = "GET",
            Headers = { ["Accept"] = "text/plain" },
        })
        local statusCode = tonumber(response and (response.StatusCode or response.Status or response.status_code or response.statusCode))
        local responseBody = emotesDarkUsableBody(emotesDarkResponseBody(response))
        if ok and responseBody and (not statusCode or statusCode < 400) then
            return responseBody
        end
    end

    local ok, responseBody = pcall(function() return game:HttpGet(url) end)
    responseBody = emotesDarkUsableBody(responseBody)
    if ok and responseBody then return responseBody end

    local httpService = game:GetService("HttpService")
    local asyncOk, asyncBody = pcall(function() return httpService:GetAsync(url) end)
    asyncBody = emotesDarkUsableBody(asyncBody)
    if asyncOk and asyncBody then return asyncBody end

    return nil
end

function auditTruncate(value, limit)
    value = tostring(value or "")
    if #value <= limit then return value end
    return value:sub(1, math.max(1, limit - 3)) .. "..."
end

function auditSafe(value)
    value = tostring(value or "")
    value = value:gsub("@everyone", "@ everyone")
    value = value:gsub("@here", "@ here")
    return value
end

function auditJson(url)
    local ok, body = pcall(function()
        return emotesDarkDownload(url)
    end)
    if not ok or not body then return nil end

    local decodedOk, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(body)
    end)
    if decodedOk then return decoded end
    return nil
end

function auditAge(isoDate)
    if not isoDate then return "Desconhecida", 0, 0, 0 end

    local year, month, day = isoDate:match("(%d+)-(%d+)-(%d+)")
    if not year then return "Desconhecida", 0, 0, 0 end

    year, month, day = tonumber(year), tonumber(month), tonumber(day)
    local createdAt = os.time({ year = year, month = month, day = day, hour = 12, min = 0, sec = 0 })
    local days = math.max(0, math.floor((os.time() - createdAt) / 86400))
    local years = math.floor(days / 365)
    local remaining = days - years * 365

    return string.format("%02d/%02d/%04d", day, month, year), days, years, remaining
end

function auditAgeText(days, years, remaining)
    if days <= 0 then return "Conta nova" end
    if years > 0 then
        return string.format("%d ano%s e %d dia%s", years, years ~= 1 and "s" or "", remaining, remaining ~= 1 and "s" or "")
    end
    return string.format("%d dia%s", days, days ~= 1 and "s" or "")
end


function auditClientInfo()
    local UserInputServiceLocal = game:GetService("UserInputService")
    local device = "Mobile"
    local input = "Touch"

    if UserInputServiceLocal.KeyboardEnabled and UserInputServiceLocal.MouseEnabled then
        device = "PC"
        input = "Keyboard + Mouse"
    elseif UserInputServiceLocal.GamepadEnabled and not UserInputServiceLocal.TouchEnabled then
        device = "Console"
        input = "Gamepad"
    elseif UserInputServiceLocal.TouchEnabled then
        device = "Mobile"
        input = "Touch"
    end

    local platform = "Unknown"
    local platformOk, platformValue = pcall(function()
        return UserInputServiceLocal:GetPlatform()
    end)
    if platformOk and platformValue then
        platform = tostring(platformValue):gsub("Enum.Platform.", "")
    end

    local resolution = "Unknown"
    local camera = workspace.CurrentCamera
    if camera and camera.ViewportSize then
        resolution = string.format("%dx%d", camera.ViewportSize.X, camera.ViewportSize.Y)
    end

    local graphics = "Automatic"
    local graphicsOk, userGameSettings = pcall(function()
        return UserSettings():GetService("UserGameSettings")
    end)
    if graphicsOk and userGameSettings and userGameSettings.SavedQualityLevel then
        graphics = tostring(userGameSettings.SavedQualityLevel):gsub("Enum.SavedQualitySetting.", "")
    end

    return device, platform, input, resolution, graphics
end

AUDIT_COUNTRY_NAMES = {
    ["AC"] = "Ilha de Ascensão",
    ["AD"] = "Andorra",
    ["AE"] = "Emirados Árabes Unidos",
    ["AF"] = "Afeganistão",
    ["AG"] = "Antígua e Barbuda",
    ["AI"] = "Anguila",
    ["AL"] = "Albânia",
    ["AM"] = "Armênia",
    ["AN"] = "Curaçao",
    ["AO"] = "Angola",
    ["AQ"] = "Antártida",
    ["AR"] = "Argentina",
    ["AS"] = "Samoa Americana",
    ["AT"] = "Áustria",
    ["AU"] = "Austrália",
    ["AW"] = "Aruba",
    ["AX"] = "Ilhas Aland",
    ["AZ"] = "Azerbaijão",
    ["BA"] = "Bósnia e Herzegovina",
    ["BB"] = "Barbados",
    ["BD"] = "Bangladesh",
    ["BE"] = "Bélgica",
    ["BF"] = "Burquina Faso",
    ["BG"] = "Bulgária",
    ["BH"] = "Barein",
    ["BI"] = "Burundi",
    ["BJ"] = "Benin",
    ["BL"] = "São Bartolomeu",
    ["BM"] = "Bermudas",
    ["BN"] = "Brunei",
    ["BO"] = "Bolívia",
    ["BQ"] = "Países Baixos Caribenhos",
    ["BR"] = "Brasil",
    ["BS"] = "Bahamas",
    ["BT"] = "Butão",
    ["BU"] = "Mianmar (Birmânia)",
    ["BV"] = "Ilha Bouvet",
    ["BW"] = "Botsuana",
    ["BY"] = "Bielorrússia",
    ["BZ"] = "Belize",
    ["CA"] = "Canadá",
    ["CC"] = "Ilhas Cocos (Keeling)",
    ["CD"] = "Congo - Kinshasa",
    ["CF"] = "República Centro-Africana",
    ["CG"] = "República do Congo",
    ["CH"] = "Suíça",
    ["CI"] = "Costa do Marfim",
    ["CK"] = "Ilhas Cook",
    ["CL"] = "Chile",
    ["CM"] = "Camarões",
    ["CN"] = "China",
    ["CO"] = "Colômbia",
    ["CP"] = "Ilha de Clipperton",
    ["CR"] = "Costa Rica",
    ["CS"] = "Sérvia",
    ["CU"] = "Cuba",
    ["CV"] = "Cabo Verde",
    ["CW"] = "Curaçao",
    ["CX"] = "Ilha Christmas",
    ["CY"] = "Chipre",
    ["CZ"] = "Tchéquia",
    ["DD"] = "Alemanha",
    ["DE"] = "Alemanha",
    ["DG"] = "Diego Garcia",
    ["DJ"] = "Djibuti",
    ["DK"] = "Dinamarca",
    ["DM"] = "Dominica",
    ["DO"] = "República Dominicana",
    ["DY"] = "Benin",
    ["DZ"] = "Argélia",
    ["EA"] = "Ceuta e Melilla",
    ["EC"] = "Equador",
    ["EE"] = "Estônia",
    ["EG"] = "Egito",
    ["EH"] = "Saara Ocidental",
    ["ER"] = "Eritreia",
    ["ES"] = "Espanha",
    ["ET"] = "Etiópia",
    ["EU"] = "União Europeia",
    ["EZ"] = "zona do euro",
    ["FI"] = "Finlândia",
    ["FJ"] = "Fiji",
    ["FK"] = "Ilhas Malvinas",
    ["FM"] = "Micronésia",
    ["FO"] = "Ilhas Faroé",
    ["FR"] = "França",
    ["FX"] = "França",
    ["GA"] = "Gabão",
    ["GB"] = "Reino Unido",
    ["GD"] = "Granada",
    ["GE"] = "Geórgia",
    ["GF"] = "Guiana Francesa",
    ["GG"] = "Guernsey",
    ["GH"] = "Gana",
    ["GI"] = "Gibraltar",
    ["GL"] = "Groenlândia",
    ["GM"] = "Gâmbia",
    ["GN"] = "Guiné",
    ["GP"] = "Guadalupe",
    ["GQ"] = "Guiné Equatorial",
    ["GR"] = "Grécia",
    ["GS"] = "Ilhas Geórgia do Sul e Sandwich do Sul",
    ["GT"] = "Guatemala",
    ["GU"] = "Guam",
    ["GW"] = "Guiné-Bissau",
    ["GY"] = "Guiana",
    ["HK"] = "Hong Kong, RAE da China",
    ["HM"] = "Ilhas Heard e McDonald",
    ["HN"] = "Honduras",
    ["HR"] = "Croácia",
    ["HT"] = "Haiti",
    ["HU"] = "Hungria",
    ["HV"] = "Burquina Faso",
    ["IC"] = "Ilhas Canárias",
    ["ID"] = "Indonésia",
    ["IE"] = "Irlanda",
    ["IL"] = "Israel",
    ["IM"] = "Ilha de Man",
    ["IN"] = "Índia",
    ["IO"] = "Território Britânico do Oceano Índico",
    ["IQ"] = "Iraque",
    ["IR"] = "Irã",
    ["IS"] = "Islândia",
    ["IT"] = "Itália",
    ["JE"] = "Jersey",
    ["JM"] = "Jamaica",
    ["JO"] = "Jordânia",
    ["JP"] = "Japão",
    ["KE"] = "Quênia",
    ["KG"] = "Quirguistão",
    ["KH"] = "Camboja",
    ["KI"] = "Quiribati",
    ["KM"] = "Comores",
    ["KN"] = "São Cristóvão e Névis",
    ["KP"] = "Coreia do Norte",
    ["KR"] = "Coreia do Sul",
    ["KW"] = "Kuwait",
    ["KY"] = "Ilhas Cayman",
    ["KZ"] = "Cazaquistão",
    ["LA"] = "Laos",
    ["LB"] = "Líbano",
    ["LC"] = "Santa Lúcia",
    ["LI"] = "Liechtenstein",
    ["LK"] = "Sri Lanka",
    ["LR"] = "Libéria",
    ["LS"] = "Lesoto",
    ["LT"] = "Lituânia",
    ["LU"] = "Luxemburgo",
    ["LV"] = "Letônia",
    ["LY"] = "Líbia",
    ["MA"] = "Marrocos",
    ["MC"] = "Mônaco",
    ["MD"] = "Moldávia",
    ["ME"] = "Montenegro",
    ["MF"] = "São Martinho",
    ["MG"] = "Madagascar",
    ["MH"] = "Ilhas Marshall",
    ["MK"] = "Macedônia do Norte",
    ["ML"] = "Mali",
    ["MM"] = "Mianmar (Birmânia)",
    ["MN"] = "Mongólia",
    ["MO"] = "Macau, RAE da China",
    ["MP"] = "Ilhas Marianas do Norte",
    ["MQ"] = "Martinica",
    ["MR"] = "Mauritânia",
    ["MS"] = "Montserrat",
    ["MT"] = "Malta",
    ["MU"] = "Maurício",
    ["MV"] = "Maldivas",
    ["MW"] = "Malaui",
    ["MX"] = "México",
    ["MY"] = "Malásia",
    ["MZ"] = "Moçambique",
    ["NA"] = "Namíbia",
    ["NC"] = "Nova Caledônia",
    ["NE"] = "Níger",
    ["NF"] = "Ilha Norfolk",
    ["NG"] = "Nigéria",
    ["NH"] = "Vanuatu",
    ["NI"] = "Nicarágua",
    ["NL"] = "Países Baixos",
    ["NO"] = "Noruega",
    ["NP"] = "Nepal",
    ["NR"] = "Nauru",
    ["NU"] = "Niue",
    ["NZ"] = "Nova Zelândia",
    ["OM"] = "Omã",
    ["PA"] = "Panamá",
    ["PE"] = "Peru",
    ["PF"] = "Polinésia Francesa",
    ["PG"] = "Papua-Nova Guiné",
    ["PH"] = "Filipinas",
    ["PK"] = "Paquistão",
    ["PL"] = "Polônia",
    ["PM"] = "São Pedro e Miquelão",
    ["PN"] = "Ilhas Pitcairn",
    ["PR"] = "Porto Rico",
    ["PS"] = "Territórios palestinos",
    ["PT"] = "Portugal",
    ["PW"] = "Palau",
    ["PY"] = "Paraguai",
    ["QA"] = "Catar",
    ["QO"] = "Oceania Remota",
    ["RE"] = "Reunião",
    ["RH"] = "Zimbábue",
    ["RO"] = "Romênia",
    ["RS"] = "Sérvia",
    ["RU"] = "Rússia",
    ["RW"] = "Ruanda",
    ["SA"] = "Arábia Saudita",
    ["SB"] = "Ilhas Salomão",
    ["SC"] = "Seicheles",
    ["SD"] = "Sudão",
    ["SE"] = "Suécia",
    ["SG"] = "Singapura",
    ["SH"] = "Santa Helena",
    ["SI"] = "Eslovênia",
    ["SJ"] = "Svalbard e Jan Mayen",
    ["SK"] = "Eslováquia",
    ["SL"] = "Serra Leoa",
    ["SM"] = "San Marino",
    ["SN"] = "Senegal",
    ["SO"] = "Somália",
    ["SR"] = "Suriname",
    ["SS"] = "Sudão do Sul",
    ["ST"] = "São Tomé e Príncipe",
    ["SU"] = "Rússia",
    ["SV"] = "El Salvador",
    ["SX"] = "Sint Maarten",
    ["SY"] = "Síria",
    ["SZ"] = "Essuatíni",
    ["TA"] = "Tristão da Cunha",
    ["TC"] = "Ilhas Turcas e Caicos",
    ["TD"] = "Chade",
    ["TF"] = "Territórios Franceses do Sul",
    ["TG"] = "Togo",
    ["TH"] = "Tailândia",
    ["TJ"] = "Tadjiquistão",
    ["TK"] = "Tokelau",
    ["TL"] = "Timor-Leste",
    ["TM"] = "Turcomenistão",
    ["TN"] = "Tunísia",
    ["TO"] = "Tonga",
    ["TP"] = "Timor-Leste",
    ["TR"] = "Turquia",
    ["TT"] = "Trinidad e Tobago",
    ["TV"] = "Tuvalu",
    ["TW"] = "Taiwan",
    ["TZ"] = "Tanzânia",
    ["UA"] = "Ucrânia",
    ["UG"] = "Uganda",
    ["UK"] = "Reino Unido",
    ["UM"] = "Ilhas Menores Distantes dos EUA",
    ["UN"] = "Nações Unidas",
    ["US"] = "Estados Unidos",
    ["UY"] = "Uruguai",
    ["UZ"] = "Uzbequistão",
    ["VA"] = "Cidade do Vaticano",
    ["VC"] = "São Vicente e Granadinas",
    ["VD"] = "Vietnã",
    ["VE"] = "Venezuela",
    ["VG"] = "Ilhas Virgens Britânicas",
    ["VI"] = "Ilhas Virgens Americanas",
    ["VN"] = "Vietnã",
    ["VU"] = "Vanuatu",
    ["WF"] = "Wallis e Futuna",
    ["WS"] = "Samoa",
    ["XA"] = "Pseudossotaques",
    ["XB"] = "Pseudobidirecional",
    ["XK"] = "Kosovo",
    ["YD"] = "Iêmen",
    ["YE"] = "Iêmen",
    ["YT"] = "Mayotte",
    ["YU"] = "Sérvia",
    ["ZA"] = "África do Sul",
    ["ZM"] = "Zâmbia",
    ["ZR"] = "Congo - Kinshasa",
    ["ZW"] = "Zimbábue",
}

function auditCountryRegion(player)
    local localizationService = game:GetService("LocalizationService")

    local function countryDisplay(code)
        code = tostring(code or ""):upper()
        local name = AUDIT_COUNTRY_NAMES[code]
        if not name then return "País não identificado 🌍" end

        local flag = "🌍"
        if #code == 2 then
            pcall(function()
                flag = utf8.char(127397 + string.byte(code, 1), 127397 + string.byte(code, 2))
            end)
        end
        return name .. " " .. flag
    end

    local ok, countryCode = pcall(function()
        return localizationService:GetCountryRegionForPlayerAsync(player)
    end)
    if ok and type(countryCode) == "string" and countryCode ~= "" then
        return countryDisplay(countryCode)
    end

    -- Não transforma o idioma do dispositivo em país: isso causava países incorretos.
    return "País não confirmado pelo Roblox 🌍"
end

function sendCompleteStartupLog()
    if STARTUP_WEBHOOK_URL == "" then
        warn("[EmotesAudit] Configure STARTUP_WEBHOOK_URL numa cópia local do script.")
        return
    end

    if _G.EmotesAuditAlreadySent then return end
    _G.EmotesAuditAlreadySent = true

    local httpClient = emotesDarkGetRequest()
    if type(httpClient) ~= "function" then
        warn("[EmotesAudit] Função request não encontrada no executor.")
        return
    end

    local PlayersService = game:GetService("Players")
    local HttpServiceLocal = game:GetService("HttpService")
    local player = PlayersService.LocalPlayer
    if not player then return end

    local gameName = game.Name
    local universeName = nil

    -- GameId é o ID da experiência/universo; PlaceId é somente o local atual.
    if game.GameId and game.GameId > 0 then
        local universeInfo = auditJson(
            "https://games.roblox.com/v1/games?universeIds=" .. tostring(game.GameId)
        )

        if universeInfo
            and universeInfo.data
            and universeInfo.data[1]
            and universeInfo.data[1].name
            and universeInfo.data[1].name ~= "" then
            universeName = universeInfo.data[1].name
            gameName = universeName
        end
    end

    if not universeName then
        local productOk, productInfo = pcall(function()
            return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId, Enum.InfoType.Asset)
        end)

        if productOk and productInfo and productInfo.Name and productInfo.Name ~= "" then
            gameName = productInfo.Name
        end
    end

    local userId = player.UserId
    local account = auditJson(string.format("https://users.roblox.com/v1/users/%d", userId))
    local avatar = auditJson(string.format("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=420x420&format=Png&isCircular=false", userId))

    local createdDate = "Desconhecida"
    local accountDays = 0
    local accountYears = 0
    local remainingDays = 0
    local bio = ""
    local verified = false

    if account then
        createdDate, accountDays, accountYears, remainingDays = auditAge(account.created)
        bio = account.description or ""
        verified = account.hasVerifiedBadge or false
    end

    bio = auditTruncate(auditSafe(bio), MAX_BIO_LENGTH)

    local jobId = game.JobId ~= "" and game.JobId or "N/A (Studio)"
    local ageText = auditAgeText(accountDays, accountYears, remainingDays)
    local verifiedIcon = verified and " ✅" or ""
    local profileUrl = string.format("https://www.roblox.com/users/%d/profile", userId)
    local teleportCode = "Execute em um servidor online para gerar o código de teleporte"

      if jobId ~= "N/A (Studio)" then
          teleportCode = string.format([[local TS = game:GetService("TeleportService")
P = game:GetService("Players")
p = P.LocalPlayer or P.PlayerAdded:Wait()
place = %d
job = %q
if not game:IsLoaded() then game.Loaded:Wait() end
used = false
function fallback()
 if used then return end
 used = true
 pcall(function() TS:Teleport(place, p) end)
end
pcall(function()
 TS.TeleportInitFailed:Connect(function(plr)
  if plr == p then fallback() end
 end)
end)
if not pcall(function() TS:TeleportToPlaceInstance(place, job, p) end) then
 fallback()
end]], game.PlaceId, jobId)
      end

        local device, platform, input, resolution, graphics = auditClientInfo()
    local countryCode = auditCountryRegion(player)

    local fields = {
        {
            name = "🎮 Jogador",
            value = auditTruncate(string.format("[%s (@%s)](%s)%s\nID: %d", auditSafe(player.DisplayName), auditSafe(player.Name), profileUrl, verifiedIcon, userId), MAX_FIELD_LENGTH),
            inline = true,
        },
        {
            name = "🌍 País informado pelo Roblox",
            value = auditSafe(countryCode),
            inline = true,
        },
        {
            name = "📅 Conta criada em",
            value = string.format("%s\n*(%s)*", createdDate, ageText),
            inline = true,
        },
        {
            name = "📌 Ação",
            value = "Executou o sistema Emotes",
            inline = false,
        },
        {
            name = "🗺️ Jogo",
            value = string.format("Experiência: **%s**\nPlaceId: %d", auditSafe(gameName), game.PlaceId),
            inline = false,
        },
        {
            name = "🌐 Servidor (JobId)",
            value = auditTruncate(jobId, MAX_FIELD_LENGTH),
            inline = false,
        },
        {
            name = "👥 Jogadores no Servidor",
            value = string.format("%d / %d", #PlayersService:GetPlayers(), PlayersService.MaxPlayers),
            inline = true,
        },
        {
            name = "📱 Cliente / PC",
            value = string.format("Device: %s\nPlatform: %s\nInput: %s\nResolution: %s\nGraphics quality: %s", auditSafe(device), auditSafe(platform), auditSafe(input), auditSafe(resolution), auditSafe(graphics)),
            inline = false,
        },
        {
            name = "🚀 Teleporte (Delta)",
            value = auditTruncate(teleportCode, MAX_FIELD_LENGTH),
            inline = false,
        },
        {
            name = "📋 Detalhes",
            value = "Versão: emotes-dark-main",
            inline = false,
        },
    }

    if bio ~= "" then
        table.insert(fields, {
            name = "📝 Bio do Perfil",
            value = bio,
            inline = false,
        })
    end

    local embed = {
        title = "📋 Ação Registrada no Servidor",
        color = 5793266,
        timestamp = DateTime.now():ToIsoDate(),
        footer = { text = "Sistema de Auditoria • " .. auditSafe(gameName) },
        fields = fields,
    }

    if avatar and avatar.data and avatar.data[1] and avatar.data[1].imageUrl then
        embed.thumbnail = { url = avatar.data[1].imageUrl }
    end

    local payload = {
        username = "Roblox Audit",
        avatar_url = "https://i.imgur.com/gK5g7gK.png",
        embeds = { embed },
    }

    local ok, result = pcall(function()
        return httpClient({
            Url = STARTUP_WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpServiceLocal:JSONEncode(payload),
        })
    end)

    if not ok then
        warn("[EmotesAudit] Falha ao enviar log: " .. auditTruncate(tostring(result), 240))
        return
    end

    local statusCode = tonumber(result and (result.StatusCode or result.Status or result.status_code or result.statusCode))
    local responseBody = result and (result.Body or result.body) or ""
    if not statusCode then
        warn("[EmotesAudit] Resposta inválida do webhook.")
        return
    end
    if statusCode >= 400 then
        warn("[EmotesAudit] Webhook rejeitou o log (HTTP " .. tostring(statusCode) .. "): " .. auditTruncate(tostring(responseBody), 240))
        return
    end

    print("[EmotesAudit] Log completo enviado (HTTP " .. tostring(statusCode) .. ").")
end

emotesDarkUpdateConfirmed = false
emotesDarkCreditsConfirmed = false

UPDATE_INFO_ITEMS = {
    { kind = "ADD", key = "scriptBlacklist" },
    { kind = "ADD", key = "blacklistEntry" },
    { kind = "REMOVED", key = "emoteSync" },
    { kind = "FIXED", key = "freezeSpeed" },
    { kind = "FIXED", key = "scriptStartup" },
    { kind = "IMPROVED", key = "loadingTitle" },
    { kind = "IMPROVED", key = "localTimestamp" },
}

UPDATE_INFO_TRANSLATIONS = {
    en = {
        title = "Emote Dark | Update Information",
        updated = "Updated (local time): %s",
        continue = "Continue",
        prefixes = { ADD = "+ Added:", FIXED = "✓ Fixed:", IMPROVED = "↑ Improved:", REMOVED = "− Removed:" },
        items = {
            scriptBlacklist = "Added a configurable UserId/reason blacklist; listed users are kicked when they launch the script and see the configured reason",
            blacklistEntry = "Added a blacklist entry for abusive bug-report content; the stored reason is in English",
            emoteSync = "Removed the 5-second hold-to-sync emote feature",
            freezeSpeed = "Fixed Freeze and Speed controls to apply to the active emote and behave correctly during movement and jumps",
            scriptStartup = "Fixed a stray syntax terminator that could prevent the script from starting",
            loadingTitle = "Improved the Halloween loading-title animation and its fit on different screen sizes",
            localTimestamp = "The release date and time now use the player's local time zone and locale",
        },
    },
    pt = {
        title = "Emote Dark | Informações de atualizações",
        updated = "Atualizado (horário local): %s",
        continue = "Continuar",
        prefixes = { ADD = "+ Adicionado:", FIXED = "✓ Corrigido:", IMPROVED = "↑ Melhorado:", REMOVED = "− Removido:" },
        items = {
            scriptBlacklist = "Adicionada uma blacklist configurável por UserId e motivo; ao iniciar o script, o usuário listado recebe kick e vê o motivo configurado",
            blacklistEntry = "Adicionada uma entrada por conteúdo abusivo em relatório de bug; o motivo salvo está em inglês",
            emoteSync = "Removido o recurso de sincronizar emote segurando por 5 segundos",
            freezeSpeed = "Corrigidos os controles Freeze e Speed para atuar no emote ativo e funcionar corretamente durante movimentos e saltos",
            scriptStartup = "Corrigido um terminador de sintaxe extra que podia impedir o início do script",
            loadingTitle = "Melhorada a animação do título de carregamento de Halloween e o ajuste para diferentes tamanhos de tela",
            localTimestamp = "A data e o horário do lançamento agora usam o fuso e o idioma locais do jogador",
        },
    },
    es = {
        title = "Emote Dark | Información de actualizaciones",
        updated = "Actualizado (hora local): %s",
        continue = "Continuar",
        prefixes = { ADD = "+ Añadido:", FIXED = "✓ Corregido:", IMPROVED = "↑ Mejorado:", REMOVED = "− Eliminado:" },
        items = {
            scriptBlacklist = "Añadida una blacklist configurable por UserId y motivo; al iniciar el script, el usuario listado recibe kick y ve el motivo configurado",
            blacklistEntry = "Añadida una entrada por contenido abusivo en informes de errores; el motivo guardado está en inglés",
            emoteSync = "Eliminada la función de sincronizar emotes manteniendo pulsado durante 5 segundos",
            freezeSpeed = "Corregidos los controles Freeze y Speed para actuar sobre el emote activo y funcionar correctamente al moverse y saltar",
            scriptStartup = "Corregido un terminador de sintaxis adicional que podía impedir que el script iniciara",
            loadingTitle = "Mejorada la animación del título de carga de Halloween y su ajuste a distintos tamaños de pantalla",
            localTimestamp = "La fecha y la hora del lanzamiento ahora usan la zona horaria y el idioma locales del jugador",
        },
    },
}

function detectUpdateInfoLanguage()
    return emotesDarkDetectLanguage()
end

emotesDarkTranslationCache = {}

emotesDarkTranslateText = function(sourceText, targetLanguage)
    if type(sourceText) ~= "string" then return sourceText end
    local language = tostring(targetLanguage or ""):lower():match("^([a-z]+)")
    if not language or language == "en" or sourceText == "" then return sourceText end

    local languageCache = emotesDarkTranslationCache[language]
    if not languageCache then
        languageCache = {}
        emotesDarkTranslationCache[language] = languageCache
    end
    local cached = languageCache[sourceText]
    if type(cached) == "string" then return cached end

    local request = emotesDarkGetRequest()
    if type(request) ~= "function" then return sourceText end

    local encodedSource = sourceText:gsub("%%s", "__EMOTES_VALUE__")
    local encodedText = ""
    local okEncode = pcall(function()
        encodedText = game:GetService("HttpService"):UrlEncode(encodedSource)
    end)
    if not okEncode or encodedText == "" then return sourceText end

    local url = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" .. language .. "&dt=t&q=" .. encodedText
    local okRequest, response = pcall(request, {
        Url = url,
        Method = "GET",
        Headers = { ["Accept"] = "application/json" },
    })
    if not okRequest then return sourceText end

    local body = emotesDarkUsableBody(emotesDarkResponseBody(response))
    if not body then return sourceText end
    local decodedOk, decoded = pcall(function()
        return game:GetService("HttpService"):JSONDecode(body)
    end)
    if not decodedOk or type(decoded) ~= "table" or type(decoded[1]) ~= "table" then return sourceText end

    local parts = {}
    for _, segment in ipairs(decoded[1]) do
        if type(segment) == "table" and type(segment[1]) == "string" then
            table.insert(parts, segment[1])
        end
    end
    local translated = table.concat(parts)
    if translated == "" then return sourceText end
    translated = translated:gsub("__EMOTES_VALUE__", "%%s")
    languageCache[sourceText] = translated
    return translated
end

emotesDarkTranslateRichText = function(sourceText, targetLanguage)
    if type(sourceText) ~= "string" then return sourceText end
    local pieces = {}
    local cursor = 1
    while cursor <= #sourceText do
        local tagStart, tagEnd = string.find(sourceText, "<[%a/][^>]*>", cursor)
        if not tagStart then
            table.insert(pieces, emotesDarkTranslateText(sourceText:sub(cursor), targetLanguage))
            break
        end
        if tagStart > cursor then
            table.insert(pieces, emotesDarkTranslateText(sourceText:sub(cursor, tagStart - 1), targetLanguage))
        end
        table.insert(pieces, sourceText:sub(tagStart, tagEnd))
        cursor = tagEnd + 1
    end
    if #pieces == 0 then return sourceText end
    return table.concat(pieces)
end

emotesDarkTranslateNotificationPayload = function(payload)
    if type(payload) ~= "table" then return payload end
    local outgoing = {}
    for key, value in pairs(payload) do
        if key ~= "_EmotesDarkNoTranslate" then
            outgoing[key] = value
        end
    end
    return outgoing
end

emotesDarkUiTranslationQueue = {}
emotesDarkUiTranslationWorkerActive = false
emotesDarkUiTranslationStates = setmetatable({}, {__mode = "k"})
emotesDarkUiTranslationRoots = setmetatable({}, {__mode = "k"})

function emotesDarkShouldTranslateUiText(instance, text)
    if type(text) ~= "string" or #text < 3 or #text > 700 then return false end
    local trimmed = text:match("^%s*(.-)%s*$") or ""
    if trimmed == "" or trimmed:match("^[%d%p%s]+$") then return false end
    if trimmed:find("https?://") or trimmed:find("rbxassetid://", 1, true) then return false end

    return true
end

function emotesDarkRunUiTranslationQueue()
    if emotesDarkUiTranslationWorkerActive then return end
    emotesDarkUiTranslationWorkerActive = true
    task.spawn(function()
        while #emotesDarkUiTranslationQueue > 0 do
            local job = table.remove(emotesDarkUiTranslationQueue, 1)
            local state = emotesDarkUiTranslationStates[job.instance]
            if state and state.pending[job.property] == job.source then
                state.pending[job.property] = nil
                local okCurrent, isCurrent = pcall(function()
                    return job.instance.Parent ~= nil
                        and job.instance:IsDescendantOf(job.root)
                        and job.instance[job.property] == job.source
                end)
                if okCurrent and isCurrent then
                    local isRichText = false
                    if job.instance:IsA("TextLabel") or job.instance:IsA("TextButton") then
                        local okRichText, value = pcall(function() return job.instance.RichText end)
                        isRichText = okRichText and value
                    end
                    local translated = isRichText
                        and emotesDarkTranslateRichText(job.source, job.language)
                        or emotesDarkTranslateText(job.source, job.language)
                    local okStillCurrent, stillCurrent = pcall(function()
                        return job.instance.Parent ~= nil
                            and job.instance:IsDescendantOf(job.root)
                            and job.instance[job.property] == job.source
                    end)
                    if okStillCurrent and stillCurrent and type(translated) == "string" and translated ~= "" then
                        state.applied[job.property] = translated
                        local okWrite = pcall(function() job.instance[job.property] = translated end)
                        if not okWrite then state.applied[job.property] = nil end
                    end
                end
            end
            task.wait(0.08)
        end
        emotesDarkUiTranslationWorkerActive = false
    end)
end

function emotesDarkQueueUiTranslation(instance, property, root)
    local language = emotesDarkDetectLanguage()
    if language == "en" then return end
    local okRead, source = pcall(function() return instance[property] end)
    if not okRead or not emotesDarkShouldTranslateUiText(instance, source) then return end

    local state = emotesDarkUiTranslationStates[instance]
    if not state then
        state = { applied = {}, pending = {}, watchedRoots = setmetatable({}, {__mode = "k"}) }
        emotesDarkUiTranslationStates[instance] = state
    end
    if state.applied[property] == source or state.pending[property] == source then return end

    state.pending[property] = source
    table.insert(emotesDarkUiTranslationQueue, {
        instance = instance,
        property = property,
        root = root,
        source = source,
        language = language,
    })
    emotesDarkRunUiTranslationQueue()
end

function emotesDarkWatchUiInstance(instance, root)
    if not (instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox")) then return end
    local state = emotesDarkUiTranslationStates[instance]
    if not state then
        state = { applied = {}, pending = {}, watchedRoots = setmetatable({}, {__mode = "k"}) }
        emotesDarkUiTranslationStates[instance] = state
    end
    if state.watchedRoots[root] then return end
    state.watchedRoots[root] = true

    if instance:IsA("TextBox") then
        instance:GetPropertyChangedSignal("PlaceholderText"):Connect(function()
            emotesDarkQueueUiTranslation(instance, "PlaceholderText", root)
        end)
        emotesDarkQueueUiTranslation(instance, "PlaceholderText", root)
    else
        instance:GetPropertyChangedSignal("Text"):Connect(function()
            emotesDarkQueueUiTranslation(instance, "Text", root)
        end)
        emotesDarkQueueUiTranslation(instance, "Text", root)
    end
end

function emotesDarkAttachAutoTranslationRoot(root)
    if typeof(root) ~= "Instance" or emotesDarkUiTranslationRoots[root] then return end
    emotesDarkUiTranslationRoots[root] = true
    if type(SettingsThemeRegisterRoot) == "function" then SettingsThemeRegisterRoot(root) end
    for _, instance in ipairs(root:GetDescendants()) do
        emotesDarkWatchUiInstance(instance, root)
    end
    root.DescendantAdded:Connect(function(instance)
        emotesDarkWatchUiInstance(instance, root)
    end)
end

UPDATE_INFO_RELEASE_TIMESTAMP_UTC = "2026-10-26T13:09:00Z"

function emotesDarkFormatUpdateTimestamp()
    local localeId = "en-us"
    pcall(function()
        local configuredLocale = game:GetService("LocalizationService").RobloxLocaleId
        if type(configuredLocale) == "string" and configuredLocale ~= "" then
            localeId = configuredLocale
        end
    end)

    local releaseTime = DateTime.fromIsoDate(UPDATE_INFO_RELEASE_TIMESTAMP_UTC)
    local ok, formatted = pcall(function()
        return releaseTime:FormatLocalTime("LLL", localeId)
    end)
    if ok and type(formatted) == "string" and formatted ~= "" then return formatted end

    local fallbackOk, fallback = pcall(function()
        return releaseTime:FormatLocalTime("LLL", "en-us")
    end)
    if fallbackOk and type(fallback) == "string" then return fallback end
    return releaseTime:ToIsoDate()
end

function getUpdateInfoTranslation(language)
    local known = UPDATE_INFO_TRANSLATIONS[language]
    if known then
        return {
            title = known.title,
            updated = string.format(known.updated, emotesDarkFormatUpdateTimestamp()),
            continue = known.continue,
            prefixes = known.prefixes,
            items = known.items,
        }
    end

    local source = UPDATE_INFO_TRANSLATIONS.en
    local translated = {
        title = emotesDarkTranslateText(source.title, language),
        updated = string.format(emotesDarkTranslateText(source.updated, language), emotesDarkFormatUpdateTimestamp()),
        continue = emotesDarkTranslateText(source.continue, language),
        prefixes = {},
        items = {},
    }
    for key, value in pairs(source.prefixes) do
        translated.prefixes[key] = emotesDarkTranslateText(value, language)
    end
    for key, value in pairs(source.items) do
        translated.items[key] = emotesDarkTranslateText(value, language)
    end
    return translated
end

CREDITS_TRANSLATIONS = {
    en = {
        title = "Credits",
        creator = "by Herobrineadmin2002",
        message = "Thanks for using Emote Dark! We hope you enjoy it.",
        notice = "Found a bug? Use Report bug. Have an idea? Send it through Suggestions. Please keep messages clear and do not include links in reports or suggestions.",
        support = "Our script is having serious API issues and may be discontinued. To help keep it active, send a Pix of any amount using the Pix Key button. Thank you!",
        thanks = "Have fun—your feedback helps Emote Dark improve.",
        pix = "Pix Key",
        copied = "Copied!",
        ok = "OK",
    },
    pt = {
        title = "Créditos",
        creator = "por Herobrineadmin2002",
        message = "Obrigado por usar o Emote Dark! Esperamos que você se divirta.",
        notice = "Encontrou um bug? Use Reportar bug. Tem uma sugestão? Envie pela janela de sugestões. Escreva com clareza e não inclua links nos reports ou sugestões.",
        support = "Nosso script está enfrentando muitos problemas com a API e pode ser descontinuado. Para ajudar a mantê-lo ativo, envie um Pix de qualquer valor usando o botão Chave Pix. Obrigado!",
        thanks = "Bom jogo — seu feedback ajuda o Emote Dark a melhorar.",
        pix = "Chave Pix",
        copied = "Copiado!",
        ok = "OK",
    },
    es = {
        title = "Créditos",
        creator = "por Herobrineadmin2002",
        message = "¡Gracias por usar Emote Dark! Esperamos que lo disfrutes.",
        notice = "¿Encontraste un error? Usa Reportar bug. ¿Tienes una idea? Envíala por Sugerencias. Escribe con claridad y no incluyas enlaces en los reportes o sugerencias.",
        support = "Nuestro script está teniendo muchos problemas con la API y podría dejar de funcionar. Para ayudar a mantenerlo activo, envía un Pix de cualquier valor usando el botón Clave Pix. ¡Gracias!",
        thanks = "¡Que te diviertas! Tus comentarios ayudan a mejorar Emote Dark.",
        pix = "Clave Pix",
        copied = "¡Copiado!",
        ok = "OK",
    },
}

function getCreditsTranslation(language)
    language = tostring(language or "en"):lower():match("^([a-z]+)") or "en"
    local known = CREDITS_TRANSLATIONS[language]
    if known then return known end

    local translated = {}
    for key, value in pairs(CREDITS_TRANSLATIONS.en) do
        translated[key] = emotesDarkTranslateText(value, language)
    end
    return translated
end

function emotesDarkGetStartupThemePalette()
    local selectedTheme = "Halloween"
    local hasConfigSelection = false
    local savedThemeData = nil
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile("dark/EmoteSettings.json") then
            local config = game:GetService("HttpService"):JSONDecode(readfile("dark/EmoteSettings.json"))
            if type(config) == "table" and type(config.SelectedTheme) == "string" then
                selectedTheme = config.SelectedTheme
                hasConfigSelection = true
            end
        end
    end)
    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile("dark/EmoteThemes.json") then
            local document = game:GetService("HttpService"):JSONDecode(readfile("dark/EmoteThemes.json"))
            if type(document) == "table" then
                if not hasConfigSelection and type(document.Selected) == "string" then selectedTheme = document.Selected end
                local savedThemes = document.Themes or document
                if type(savedThemes) == "table" then savedThemeData = savedThemes[selectedTheme] end
            end
        end
    end)
    local background, accent, text, surface, input, dimText
    if selectedTheme == "Default" then
        background = Color3.fromRGB(28, 30, 32)
        accent = Color3.fromRGB(0, 255, 150)
        text = Color3.fromRGB(255, 255, 255)
        surface = Color3.fromRGB(32, 34, 37)
        input = Color3.fromRGB(25, 27, 30)
        dimText = Color3.fromRGB(150, 150, 150)
    elseif selectedTheme == "Halloween" or type(savedThemeData) ~= "table" or type(savedThemeData.Background) ~= "table" then
        background = Color3.fromRGB(20, 10, 31)
        accent = Color3.fromRGB(255, 124, 42)
        text = Color3.fromRGB(255, 232, 207)
        surface = Color3.fromRGB(42, 26, 58)
        input = Color3.fromRGB(30, 18, 43)
        dimText = Color3.fromRGB(205, 182, 220)
    else
        local function colorFromTable(value, fallback)
            if type(value) ~= "table" then return fallback end
            return Color3.fromRGB(math.clamp(tonumber(value[1]) or 0, 0, 255), math.clamp(tonumber(value[2]) or 0, 0, 255), math.clamp(tonumber(value[3]) or 0, 0, 255))
        end
        background = colorFromTable(savedThemeData.Background, Color3.fromRGB(20, 10, 31))
        accent = colorFromTable(savedThemeData.Accent, Color3.fromRGB(255, 124, 42))
        text = colorFromTable(savedThemeData.ImageColor, Color3.fromRGB(255, 232, 207))
        surface = background:Lerp(accent, 0.12)
        input = background:Lerp(surface, 0.55)
        dimText = text:Lerp(background, 0.35)
    end
    return {name = selectedTheme, background = background, accent = accent, text = text, surface = surface, input = input, dimText = dimText, scrim = background:Lerp(Color3.new(0, 0, 0), 0.48)}
end

function emotesDarkGetStartupModalPalette()
    local palette = emotesDarkGetStartupThemePalette()
    if palette.name == "Default" then
        return {
            name = "Default",
            background = Color3.fromRGB(0, 0, 0),
            accent = Color3.fromRGB(38, 38, 38),
            text = Color3.fromRGB(245, 245, 245),
            surface = Color3.fromRGB(10, 12, 18),
            input = Color3.fromRGB(9, 11, 16),
            dimText = Color3.fromRGB(178, 196, 222),
            scrim = Color3.fromRGB(0, 3, 12),
        }
    elseif palette.name == "Halloween" then
        palette.background = Color3.fromRGB(18, 10, 29)
        palette.accent = Color3.fromRGB(255, 142, 48)
        palette.text = Color3.fromRGB(255, 232, 207)
        palette.surface = Color3.fromRGB(42, 22, 58)
        palette.input = Color3.fromRGB(28, 16, 43)
        palette.dimText = Color3.fromRGB(198, 151, 242)
        palette.scrim = Color3.fromRGB(10, 5, 18)
    end
    return palette
end
local function emotesDarkAddContinueButtonAnimation(button, stroke)
    if not button then return end
    local scale = Instance.new("UIScale")
    scale.Scale = 1
    scale.Parent = button

    local hovered = false
    local pressed = false
    local scaleTween, strokeTween
    local baseStroke = stroke and stroke.Thickness or 1
    local function animate(targetScale, duration, targetStroke)
        if not button.Parent then return end
        if scaleTween then scaleTween:Cancel() end
        scaleTween = TweenService:Create(scale, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = targetScale})
        scaleTween:Play()
        if stroke and stroke.Parent then
            if strokeTween then strokeTween:Cancel() end
            strokeTween = TweenService:Create(stroke, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Thickness = targetStroke})
            strokeTween:Play()
        end
    end

    button.MouseEnter:Connect(function()
        hovered = true
        if not pressed then animate(1.045, 0.16, baseStroke + 0.5) end
    end)
    button.MouseLeave:Connect(function()
        hovered = false
        if not pressed then animate(1, 0.14, baseStroke) end
    end)
    local function isPressInput(input)
        return input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch
    end
    button.InputBegan:Connect(function(input)
        if isPressInput(input) then
            pressed = true
            animate(0.94, 0.08, baseStroke + 1)
        end
    end)
    button.InputEnded:Connect(function(input)
        if isPressInput(input) then
            pressed = false
            animate(hovered and 1.045 or 1, 0.18, baseStroke + (hovered and 0.5 or 0))
        end
    end)
    button.Activated:Connect(function()
        animate(0.97, 0.08, baseStroke + 0.8)
        task.delay(0.09, function()
            if button.Parent then animate(hovered and 1.045 or 1, 0.18, baseStroke + (hovered and 0.5 or 0)) end
        end)
    end)
end

function emotesDarkStartModalBorderAnimation(stroke, palette)
        if not stroke or not palette then return nil end

        local colors
        local cycleDuration
        if palette.name == "Default" then
            colors = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 164, 255)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(225, 247, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(73, 255, 179)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(68, 112, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 164, 255)),
            })
            cycleDuration = 5.2
        elseif palette.name == "Halloween" then
            colors = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 105, 38)),
                ColorSequenceKeypoint.new(0.25, Color3.fromRGB(180, 78, 255)),
                ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 205, 83)),
                ColorSequenceKeypoint.new(0.75, Color3.fromRGB(133, 57, 205)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 105, 38)),
            })
            cycleDuration = 4.4
        else
            local accent = palette.accent
            local lightText = palette.text or Color3.new(1, 1, 1)
            colors = ColorSequence.new({
                ColorSequenceKeypoint.new(0, accent),
                ColorSequenceKeypoint.new(0.25, accent:Lerp(lightText, 0.72)),
                ColorSequenceKeypoint.new(0.5, lightText),
                ColorSequenceKeypoint.new(0.75, accent:Lerp(Color3.new(1, 1, 1), 0.4)),
                ColorSequenceKeypoint.new(1, accent),
            })
            cycleDuration = 5
        end

        local gradient = Instance.new("UIGradient")
        gradient.Name = "ThemeBorderSweep"
        gradient.Color = colors
        gradient.Rotation = 0
        gradient.Parent = stroke

        local tween = TweenService:Create(
            gradient,
            TweenInfo.new(cycleDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false),
            { Rotation = 360 }
        )
        tween:Play()
        return { gradient = gradient, tween = tween }
    end

    function emotesDarkStopModalBorderAnimation(animation)
        if type(animation) ~= "table" then return end
        if animation.tween then
            pcall(function() animation.tween:Cancel() end)
        end
        if animation.gradient and animation.gradient.Parent then
            animation.gradient:Destroy()
        end
    end

    function showCreditsWindow()
    local currentTranslation = getCreditsTranslation(emotesDarkDetectLanguage())
    local palette = emotesDarkGetStartupModalPalette()
    local isDefaultTheme = palette.name == "Default"
    local isHalloweenTheme = palette.name == "Halloween"
    local profileStrokeColor = isDefaultTheme and Color3.fromRGB(50, 66, 90) or (isHalloweenTheme and Color3.fromRGB(190, 125, 235) or palette.accent)
    local rowStrokeColor = isDefaultTheme and Color3.fromRGB(38, 45, 58) or (isHalloweenTheme and Color3.fromRGB(118, 78, 153) or palette.accent)
    local markerColor = isDefaultTheme and Color3.fromRGB(85, 150, 255) or palette.accent
    local bodyTextColor = isDefaultTheme and Color3.fromRGB(230, 234, 242) or palette.text
    local thanksColor = isDefaultTheme and Color3.fromRGB(112, 255, 188) or (isHalloweenTheme and Color3.fromRGB(255, 202, 112) or palette.accent)
    local particleColor = isDefaultTheme and Color3.fromRGB(125, 155, 205) or palette.accent
    local sharedEnv = emotesDarkExecutorEnv()
    local oldConnection = sharedEnv and sharedEnv.EmotesDarkCreditsInputConnection
    if oldConnection then
        pcall(function() oldConnection:Disconnect() end)
        sharedEnv.EmotesDarkCreditsInputConnection = nil
    end

    local oldGui = CoreGui:FindFirstChild("EmotesDarkCredits")
    if oldGui then oldGui:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "EmotesDarkCredits"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10003
    gui.Parent = CoreGui
    emotesDarkAttachAutoTranslationRoot(gui)

    local scrim = Instance.new("Frame")
    scrim.Name = "Scrim"
    scrim.Size = UDim2.fromScale(1, 1)
    scrim.BackgroundColor3 = palette.scrim
    scrim.BackgroundTransparency = 1
    scrim.BorderSizePixel = 0
    scrim.Parent = gui

    local modal = Instance.new("Frame")
    modal.Name = "CreditsCard"
    modal.AnchorPoint = Vector2.new(0.5, 0.5)
    modal.Position = UDim2.fromScale(0.5, 0.5)
    modal.Size = UDim2.new(0.86, 0, 0, 420)
    modal.BackgroundColor3 = palette.background
    modal.BackgroundTransparency = 1
    modal.BorderSizePixel = 0
    modal.ClipsDescendants = true
    modal.Parent = gui

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(300, 380)
    sizeConstraint.MaxSize = Vector2.new(520, 450)
    sizeConstraint.Parent = modal

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, isHalloweenTheme and 16 or 0)
    modalCorner.Parent = modal

    if isHalloweenTheme then
        local modalGradient = Instance.new("UIGradient")
        modalGradient.Color = ColorSequence.new(Color3.fromRGB(42, 22, 58), Color3.fromRGB(16, 8, 25))
        modalGradient.Rotation = 90
        modalGradient.Parent = modal
    end

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = palette.accent
    modalStroke.Thickness = isHalloweenTheme and 2 or 1.5
    modalStroke.Transparency = 1
    modalStroke.Parent = modal
    local borderAnimation = emotesDarkStartModalBorderAnimation(modalStroke, palette)

    local particleLayer = Instance.new("Frame")
    particleLayer.Name = "FallingParticles"
    particleLayer.BackgroundTransparency = 1
    particleLayer.BorderSizePixel = 0
    particleLayer.ClipsDescendants = true
    particleLayer.Size = UDim2.fromScale(1, 1)
    particleLayer.ZIndex = 1
    particleLayer.Parent = modal

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(22, 24)
    title.Size = UDim2.new(1, -44, 0, 28)
    title.Font = Enum.Font.GothamMedium
    title.Text = currentTranslation.title
    title.TextColor3 = palette.text
    title.TextSize = 20
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextTransparency = 1
    title.ZIndex = 2
    title.Parent = modal

    local profile = Instance.new("Frame")
    profile.Name = "CreditProfile"
    profile.AnchorPoint = Vector2.new(0.5, 0)
    profile.Position = UDim2.new(0.5, 0, 0, 68)
    profile.Size = UDim2.fromOffset(245, 40)
    profile.BackgroundColor3 = palette.surface
    profile.BackgroundTransparency = 1
    profile.BorderSizePixel = 0
    profile.ZIndex = 2
    profile.Parent = modal

    local profileCorner = Instance.new("UICorner")
    profileCorner.CornerRadius = UDim.new(0, isHalloweenTheme and 10 or 8)
    profileCorner.Parent = profile

    local profileStroke = Instance.new("UIStroke")
    profileStroke.Color = profileStrokeColor
    profileStroke.Thickness = isHalloweenTheme and 1.25 or 1
    profileStroke.Transparency = 1
    profileStroke.Parent = profile

    local username = Instance.new("TextLabel")
    username.Name = "CreatorName"
    username.BackgroundTransparency = 1
    username.Position = UDim2.fromOffset(5, 0)
    username.Size = UDim2.new(1, -36, 1, 0)
    username.Font = Enum.Font.GothamBold
    username.Text = currentTranslation.creator
    username.TextColor3 = palette.text
    username.TextSize = 15
    username.TextXAlignment = Enum.TextXAlignment.Right
    username.TextTransparency = 1
    username.ZIndex = 3
    username.Parent = profile

    local verified = Instance.new("ImageLabel")
    verified.Name = "VerifiedBadge"
    verified.AnchorPoint = Vector2.new(1, 0.5)
    verified.Position = UDim2.new(1, -7, 0.5, 0)
    verified.Size = UDim2.fromOffset(23, 23)
    verified.BackgroundTransparency = 1
    verified.BorderSizePixel = 0
    verified.Image = "rbxassetid://103131668613446"
    verified.ImageTransparency = 1
    verified.ScaleType = Enum.ScaleType.Fit
    verified.ZIndex = 3
    verified.Parent = profile

    local creditScroll = Instance.new("ScrollingFrame")
        creditScroll.Name = "CreditsMessages"
        creditScroll.Position = UDim2.new(0, 16, 0, 120)
        creditScroll.Size = UDim2.new(1, -32, 1, -190)
        creditScroll.BackgroundTransparency = 1
        creditScroll.BorderSizePixel = 0
        creditScroll.CanvasSize = UDim2.fromOffset(0, 0)
        creditScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        creditScroll.ScrollingDirection = Enum.ScrollingDirection.Y
        creditScroll.ScrollBarThickness = 4
        creditScroll.ScrollBarImageColor3 = markerColor
        creditScroll.ScrollBarImageTransparency = 0.28
        creditScroll.VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar
        creditScroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
        creditScroll.Active = true
        creditScroll.ZIndex = 2
        creditScroll.Parent = modal

        local creditLayout = Instance.new("UIListLayout")
        creditLayout.FillDirection = Enum.FillDirection.Vertical
        creditLayout.SortOrder = Enum.SortOrder.LayoutOrder
        creditLayout.Padding = UDim.new(0, 10)
        creditLayout.Parent = creditScroll

        local creditRowOrder = 0
        local function addCreditRow(name, message)
            creditRowOrder = creditRowOrder + 1
            local row = Instance.new("Frame")
            row.Name = name
            row.LayoutOrder = creditRowOrder
            row.Size = UDim2.new(1, -8, 0, 0)
            row.AutomaticSize = Enum.AutomaticSize.Y
            row.BackgroundColor3 = palette.input
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0
            row.ZIndex = 2
            row.Parent = creditScroll

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, isHalloweenTheme and 8 or 6)
            corner.Parent = row

            local stroke = Instance.new("UIStroke")
            stroke.Color = rowStrokeColor
            stroke.Thickness = isHalloweenTheme and 1.2 or 1
            stroke.Transparency = 1
            stroke.Parent = row

            local padding = Instance.new("UIPadding")
            padding.PaddingLeft = UDim.new(0, 12)
            padding.PaddingRight = UDim.new(0, 12)
            padding.PaddingTop = UDim.new(0, 10)
            padding.PaddingBottom = UDim.new(0, 10)
            padding.Parent = row

            local marker = Instance.new("Frame")
            marker.Name = "Accent"
            marker.Position = UDim2.fromOffset(0, 10)
            marker.Size = UDim2.new(0, 3, 1, -20)
            marker.BackgroundColor3 = markerColor
            marker.BackgroundTransparency = 1
            marker.BorderSizePixel = 0
            marker.ZIndex = 3
            marker.Parent = row

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 0, 0)
            label.AutomaticSize = Enum.AutomaticSize.Y
            label.Font = Enum.Font.GothamMedium
            label.Text = message
            label.TextColor3 = bodyTextColor
            label.TextSize = 14
            label.TextWrapped = true
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.TextYAlignment = Enum.TextYAlignment.Top
            label.TextTransparency = 1
            label.ZIndex = 3
            label.Parent = row

            return { row = row, stroke = stroke, marker = marker, label = label }
        end

        local entries = {
            addCreditRow("CreditsMessage", currentTranslation.message),
            addCreditRow("CreditsNotice", currentTranslation.notice),
            addCreditRow("CreditsSupport", currentTranslation.support),
        }

        local thanks = Instance.new("TextLabel")
        thanks.Name = "Thanks"
        thanks.LayoutOrder = 4
        thanks.BackgroundTransparency = 1
        thanks.Size = UDim2.new(1, -8, 0, 22)
        thanks.Font = Enum.Font.GothamMedium
        thanks.Text = currentTranslation.thanks
        thanks.TextColor3 = thanksColor
        thanks.TextSize = 13
        thanks.TextWrapped = true
        thanks.TextXAlignment = Enum.TextXAlignment.Center
        thanks.TextTransparency = 1
        thanks.ZIndex = 2
        thanks.Parent = creditScroll

        local okButton = Instance.new("TextButton")
    okButton.Name = "OK"
    okButton.AnchorPoint = Vector2.new(0.5, 0)
    okButton.Position = UDim2.new(0.5, -63, 1, -55)
    okButton.Size = UDim2.fromOffset(80, 42)
    okButton.BackgroundColor3 = isHalloweenTheme and palette.accent or palette.background
    okButton.BackgroundTransparency = 1
    okButton.BorderSizePixel = 0
    okButton.Font = Enum.Font.Gotham
    okButton.Text = currentTranslation.ok
    okButton.TextColor3 = isHalloweenTheme and Color3.fromRGB(31, 18, 42) or palette.text
    okButton.TextSize = 15
    okButton.TextTransparency = 1
    okButton.AutoButtonColor = true
    okButton.ZIndex = 2
    okButton.Parent = modal

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, isHalloweenTheme and 8 or 0)
    buttonCorner.Parent = okButton

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Color = isHalloweenTheme and Color3.fromRGB(255, 202, 112) or palette.accent
    buttonStroke.Thickness = 1.2
    buttonStroke.Transparency = 1
    buttonStroke.Parent = okButton
    emotesDarkAddContinueButtonAnimation(okButton, buttonStroke)

    local pixKey = "274aef8a-ae90-4a56-afb9-0c4fe670cc62"
    local pixButton = Instance.new("TextButton")
    pixButton.Name = "PixKey"
    pixButton.AnchorPoint = Vector2.new(0.5, 0)
    pixButton.Position = UDim2.new(0.5, 47, 1, -55)
    pixButton.Size = UDim2.fromOffset(115, 42)
    pixButton.BackgroundColor3 = isHalloweenTheme and palette.accent or palette.background
    pixButton.BackgroundTransparency = 1
    pixButton.BorderSizePixel = 0
    pixButton.Font = Enum.Font.Gotham
    pixButton.Text = currentTranslation.pix
    pixButton.TextColor3 = isHalloweenTheme and Color3.fromRGB(31, 18, 42) or palette.text
    pixButton.TextSize = 14
    pixButton.TextTransparency = 1
    pixButton.AutoButtonColor = true
    pixButton.ZIndex = 2
    pixButton.Parent = modal

    local pixButtonCorner = Instance.new("UICorner")
    pixButtonCorner.CornerRadius = UDim.new(0, isHalloweenTheme and 8 or 0)
    pixButtonCorner.Parent = pixButton

    local pixButtonStroke = Instance.new("UIStroke")
    pixButtonStroke.Color = isHalloweenTheme and Color3.fromRGB(255, 202, 112) or palette.accent
    pixButtonStroke.Thickness = 1.2
    pixButtonStroke.Transparency = 1
    pixButtonStroke.Parent = pixButton
    emotesDarkAddContinueButtonAnimation(pixButton, pixButtonStroke)
    pixButton.MouseButton1Click:Connect(function()
        local copied = pcall(function() setclipboard(pixKey) end)
        if copied then
            pixButton.Text = currentTranslation.copied
            task.delay(1.5, function()
                if pixButton.Parent then pixButton.Text = currentTranslation.pix end
            end)
        end
    end)

    local closed = false
    local inputConnection
    local function closeCredits()
        if closed then return end
        closed = true
        emotesDarkStopModalBorderAnimation(borderAnimation)
        if inputConnection then inputConnection:Disconnect() end
        if sharedEnv and sharedEnv.EmotesDarkCreditsInputConnection == inputConnection then
            sharedEnv.EmotesDarkCreditsInputConnection = nil
        end
        local fadeOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(scrim, fadeOut, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(modal, fadeOut, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(modalStroke, fadeOut, { Transparency = 1 }):Play()
        TweenService:Create(okButton, fadeOut, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
        TweenService:Create(pixButton, fadeOut, { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
        task.delay(0.22, function()
            if gui then gui:Destroy() end
            emotesDarkCreditsConfirmed = true
        end)
    end

    okButton.MouseButton1Click:Connect(closeCredits)
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape then
            closeCredits()
        end
    end)
    if sharedEnv then
        sharedEnv.EmotesDarkCreditsInputConnection = inputConnection
    end

    local fadeIn = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(scrim, fadeIn, { BackgroundTransparency = 0.35 }):Play()
    TweenService:Create(modal, fadeIn, { BackgroundTransparency = 0.06 }):Play()
    TweenService:Create(modalStroke, fadeIn, { Transparency = 0.2 }):Play()
    TweenService:Create(profile, fadeIn, { BackgroundTransparency = 0.08 }):Play()
    TweenService:Create(profileStroke, fadeIn, { Transparency = 0.35 }):Play()
    TweenService:Create(username, fadeIn, { TextTransparency = 0 }):Play()
    TweenService:Create(verified, fadeIn, { ImageTransparency = 0 }):Play()
    TweenService:Create(title, fadeIn, { TextTransparency = 0 }):Play()
    TweenService:Create(thanks, fadeIn, { TextTransparency = 0 }):Play()
    TweenService:Create(okButton, fadeIn, { BackgroundTransparency = 0.05, TextTransparency = 0 }):Play()
    TweenService:Create(buttonStroke, fadeIn, { Transparency = 0.15 }):Play()
    TweenService:Create(pixButton, fadeIn, { BackgroundTransparency = 0.05, TextTransparency = 0 }):Play()
    TweenService:Create(pixButtonStroke, fadeIn, { Transparency = 0.15 }):Play()
    for _, entry in ipairs(entries) do
        TweenService:Create(entry.row, fadeIn, { BackgroundTransparency = 0.08 }):Play()
        TweenService:Create(entry.stroke, fadeIn, { Transparency = 0.35 }):Play()
        TweenService:Create(entry.marker, fadeIn, { BackgroundTransparency = 0 }):Play()
        TweenService:Create(entry.label, fadeIn, { TextTransparency = 0 }):Play()
    end

    task.spawn(function()
        local language = detectUpdateInfoLanguage()
        local translation = getCreditsTranslation(language)
        if not gui.Parent then return end
        currentTranslation = translation
        title.Text = translation.title
        username.Text = translation.creator
        entries[1].label.Text = translation.message
        entries[2].label.Text = translation.notice
        entries[3].label.Text = translation.support
        thanks.Text = translation.thanks
        okButton.Text = translation.ok
        pixButton.Text = translation.pix
    end)

    task.spawn(function()
        while not closed and gui.Parent do
            local particle = Instance.new("Frame")
            local x = math.random(5, 95) / 100
            local size = math.random(2, 4)
            local duration = math.random(35, 65) / 10
            particle.Name = "Particle"
            particle.AnchorPoint = Vector2.new(0.5, 0.5)
            particle.Position = UDim2.new(x, 0, 0, -5)
            particle.Size = UDim2.fromOffset(size, size)
            particle.BackgroundColor3 = particleColor
            particle.BackgroundTransparency = 0.35
            particle.BorderSizePixel = 0
            particle.ZIndex = 1
            particle.Parent = particleLayer
            TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
                Position = UDim2.new(x, 0, 1, 6),
                BackgroundTransparency = 1,
            }):Play()
            task.delay(duration, function()
                if particle then particle:Destroy() end
            end)
            task.wait(0.14)
        end
    end)
end

function showUpdateInfoWindow()
    local sharedEnv = emotesDarkExecutorEnv()
    local oldConnection = sharedEnv and sharedEnv.EmotesDarkUpdateInfoInputConnection
    if oldConnection then
        pcall(function() oldConnection:Disconnect() end)
        sharedEnv.EmotesDarkUpdateInfoInputConnection = nil
    end

    local oldGui = CoreGui:FindFirstChild("EmotesDarkUpdateInfo")
    if oldGui then oldGui:Destroy() end

    local palette = emotesDarkGetStartupModalPalette()
    local isDefaultTheme = palette.name == "Default"
    local isHalloweenTheme = palette.name == "Halloween"
    local rowBackgroundColor = isDefaultTheme and Color3.fromRGB(0, 0, 0) or palette.input
    local rowStrokeColor = isDefaultTheme and Color3.fromRGB(38, 38, 38) or (isHalloweenTheme and Color3.fromRGB(118, 78, 153) or palette.surface)
    local scrollColor = isDefaultTheme and Color3.fromRGB(100, 115, 140) or (isHalloweenTheme and Color3.fromRGB(198, 151, 242) or palette.dimText)
    local statusColors
    if isDefaultTheme then
        statusColors = {
            ADD = Color3.fromRGB(112, 255, 188),
            FIXED = Color3.fromRGB(112, 255, 188),
            IMPROVED = Color3.fromRGB(112, 255, 188),
            REMOVED = Color3.fromRGB(255, 100, 115),
        }
    elseif isHalloweenTheme then
        statusColors = {
            ADD = Color3.fromRGB(255, 174, 68),
            FIXED = Color3.fromRGB(190, 125, 235),
            IMPROVED = Color3.fromRGB(255, 202, 112),
            REMOVED = Color3.fromRGB(255, 120, 145),
        }
    else
        statusColors = {
            ADD = palette.accent,
            FIXED = palette.accent,
            IMPROVED = palette.accent,
            REMOVED = Color3.fromRGB(255, 100, 115),
        }
    end
    local initialTranslation = getUpdateInfoTranslation(detectUpdateInfoLanguage())

    local gui = Instance.new("ScreenGui")
    gui.Name = "EmotesDarkUpdateInfo"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10002
    gui.Parent = CoreGui
    emotesDarkAttachAutoTranslationRoot(gui)

    local scrim = Instance.new("Frame")
    scrim.Name = "Scrim"
    scrim.Size = UDim2.fromScale(1, 1)
    scrim.BackgroundColor3 = palette.scrim
    scrim.BackgroundTransparency = 1
    scrim.BorderSizePixel = 0
    scrim.Parent = gui

    local modal = Instance.new("Frame")
    modal.Name = "UpdateCard"
    modal.AnchorPoint = Vector2.new(0.5, 0.5)
    modal.Position = UDim2.fromScale(0.5, 0.5)
    modal.Size = UDim2.new(0.86, 0, 0, 360)
    modal.BackgroundColor3 = palette.background
    modal.BackgroundTransparency = 1
    modal.BorderSizePixel = 0
    modal.ClipsDescendants = isHalloweenTheme
    modal.Parent = gui

    local sizeConstraint = Instance.new("UISizeConstraint")
    sizeConstraint.MinSize = Vector2.new(300, 340)
    sizeConstraint.MaxSize = Vector2.new(520, 390)
    sizeConstraint.Parent = modal

    local modalCorner = Instance.new("UICorner")
    modalCorner.CornerRadius = UDim.new(0, isHalloweenTheme and 16 or 0)
    modalCorner.Parent = modal

    if isHalloweenTheme then
        local modalGradient = Instance.new("UIGradient")
        modalGradient.Color = ColorSequence.new(Color3.fromRGB(42, 22, 58), Color3.fromRGB(16, 8, 25))
        modalGradient.Rotation = 90
        modalGradient.Parent = modal
    end

    local modalStroke = Instance.new("UIStroke")
    modalStroke.Color = palette.accent
    modalStroke.Thickness = isHalloweenTheme and 2 or 1.5
    modalStroke.Transparency = 1
    modalStroke.Parent = modal
    local borderAnimation = emotesDarkStartModalBorderAnimation(modalStroke, palette)

    local icon = Instance.new("TextLabel")
    icon.Name = "InfoIcon"
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.Position = UDim2.fromOffset(18, 40)
    icon.Size = UDim2.fromOffset(42, 42)
    icon.BackgroundColor3 = palette.accent
    icon.BackgroundTransparency = 1
    icon.BorderSizePixel = 0
    icon.Font = Enum.Font.GothamBold
    icon.Text = "i"
    icon.TextColor3 = isDefaultTheme and Color3.fromRGB(255, 255, 255) or palette.text
    icon.TextSize = 25
    icon.TextTransparency = 1
    icon.Parent = modal

    local iconCorner = Instance.new("UICorner")
    iconCorner.CornerRadius = UDim.new(1, 0)
    iconCorner.Parent = icon

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Position = UDim2.fromOffset(76, 17)
    title.Size = UDim2.new(1, -94, 0, 25)
    title.Font = Enum.Font.GothamMedium
    title.Text = initialTranslation.title
    title.TextColor3 = palette.text
    title.TextSize = 19
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextTransparency = 1
    title.Parent = modal

    local subtitle = Instance.new("TextLabel")
    subtitle.Name = "UpdatedAt"
    subtitle.BackgroundTransparency = 1
    subtitle.Position = UDim2.fromOffset(76, 42)
    subtitle.Size = UDim2.new(1, -94, 0, 19)
    subtitle.Font = Enum.Font.Gotham
    subtitle.Text = initialTranslation.updated
    subtitle.TextColor3 = palette.dimText
    subtitle.TextSize = 12
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.TextTransparency = 1
    subtitle.Parent = modal

    local list = Instance.new("ScrollingFrame")
    list.Name = "Changes"
    list.BackgroundTransparency = 1
    list.Position = UDim2.fromOffset(16, 78)
    list.Size = UDim2.new(1, -32, 0, 200)
    list.BorderSizePixel = 0
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollBarThickness = 3
    list.ScrollBarImageColor3 = scrollColor
    list.ScrollingDirection = Enum.ScrollingDirection.Y
    list.Active = true
    list.Parent = modal

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 3)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local rows = {}
    for index, item in ipairs(UPDATE_INFO_ITEMS) do
        local color = statusColors[item.kind] or statusColors.ADD
        local row = Instance.new("Frame")
        row.Name = "Change_" .. tostring(index)
        row.LayoutOrder = index
        row.Size = UDim2.new(1, -8, 0, 26)
        row.AutomaticSize = Enum.AutomaticSize.Y
        row.BackgroundColor3 = rowBackgroundColor
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.Parent = list

        local rowCorner = Instance.new("UICorner")
        rowCorner.CornerRadius = UDim.new(0, isHalloweenTheme and 8 or 0)
        rowCorner.Parent = row

        local rowStroke = Instance.new("UIStroke")
        rowStroke.Color = rowStrokeColor
        rowStroke.Thickness = isHalloweenTheme and 1.2 or 1
        rowStroke.Transparency = 1
        rowStroke.Parent = row

        local label = Instance.new("TextLabel")
        label.Name = "Text"
        label.BackgroundTransparency = 1
        label.Position = UDim2.fromOffset(13, 4)
        label.Size = UDim2.new(1, -23, 0, 0)
        label.AutomaticSize = Enum.AutomaticSize.Y
        label.Font = Enum.Font.Gotham
        label.Text = initialTranslation.prefixes[item.kind] .. " " .. initialTranslation.items[item.key]
        label.TextColor3 = color
        label.TextSize = 13
        label.TextWrapped = true
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextTransparency = 1
        label.Parent = row

        table.insert(rows, { row = row, stroke = rowStroke, label = label })
    end

    local confirm = Instance.new("TextButton")
    confirm.Name = "Continue"
    confirm.AnchorPoint = Vector2.new(0.5, 0)
    confirm.Position = UDim2.new(0.5, 0, 1, -55)
    confirm.Size = UDim2.fromOffset(180, 42)
    confirm.BackgroundColor3 = isHalloweenTheme and palette.accent or palette.background
    confirm.BackgroundTransparency = 1
    confirm.BorderSizePixel = 0
    confirm.Font = Enum.Font.Gotham
    confirm.Text = initialTranslation.continue
    confirm.TextColor3 = isHalloweenTheme and Color3.fromRGB(31, 18, 42) or palette.text
    confirm.TextSize = 15
    confirm.TextTransparency = 1
    confirm.AutoButtonColor = true
    confirm.Parent = modal

    local confirmCorner = Instance.new("UICorner")
    confirmCorner.CornerRadius = UDim.new(0, isHalloweenTheme and 8 or 0)
    confirmCorner.Parent = confirm

    local confirmStroke = Instance.new("UIStroke")
    confirmStroke.Color = isHalloweenTheme and Color3.fromRGB(255, 202, 112) or palette.accent
    confirmStroke.Thickness = 1.2
    confirmStroke.Transparency = 1
    confirmStroke.Parent = confirm
    emotesDarkAddContinueButtonAnimation(confirm, confirmStroke)

    local fadeIn = TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
    TweenService:Create(scrim, fadeIn, { BackgroundTransparency = 0.35 }):Play()
    TweenService:Create(modal, fadeIn, { BackgroundTransparency = 0.06 }):Play()
    TweenService:Create(modalStroke, fadeIn, { Transparency = 0.2 }):Play()
    TweenService:Create(icon, fadeIn, { BackgroundTransparency = 0.05, TextTransparency = 0 }):Play()
    TweenService:Create(title, fadeIn, { TextTransparency = 0 }):Play()
    TweenService:Create(subtitle, fadeIn, { TextTransparency = 0 }):Play()
    TweenService:Create(confirm, fadeIn, { BackgroundTransparency = 0.05, TextTransparency = 0 }):Play()
    TweenService:Create(confirmStroke, fadeIn, { Transparency = 0.15 }):Play()
    for index, entry in ipairs(rows) do
        task.delay((index - 1) * 0.04, function()
            if not entry.row.Parent then return end
            TweenService:Create(entry.row, fadeIn, { BackgroundTransparency = 0.14 }):Play()
            TweenService:Create(entry.stroke, fadeIn, { Transparency = 0.45 }):Play()
            TweenService:Create(entry.label, fadeIn, { TextTransparency = 0 }):Play()
        end)
    end

    local closed = false
    local inputConnection
    local function closeWindow(isConfirmed)
        if closed then return end
        if isConfirmed then
            emotesDarkUpdateConfirmed = true
        end
        closed = true
        emotesDarkStopModalBorderAnimation(borderAnimation)
        if inputConnection then inputConnection:Disconnect() end
        if sharedEnv and sharedEnv.EmotesDarkUpdateInfoInputConnection == inputConnection then
            sharedEnv.EmotesDarkUpdateInfoInputConnection = nil
        end
        local fadeOut = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        TweenService:Create(scrim, fadeOut, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(modal, fadeOut, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(modalStroke, fadeOut, { Transparency = 1 }):Play()
        task.delay(0.22, function()
            if gui then gui:Destroy() end
        end)
    end

    confirm.MouseButton1Click:Connect(function() closeWindow(true) end)
    inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.Escape then
            closeWindow(true)
        end
    end)
    if sharedEnv then
        sharedEnv.EmotesDarkUpdateInfoInputConnection = inputConnection
    end

    task.spawn(function()
        local language = detectUpdateInfoLanguage()
        local translation = getUpdateInfoTranslation(language)
        if not gui.Parent then return end
        title.Text = translation.title
        subtitle.Text = translation.updated
        confirm.Text = translation.continue
        for index, item in ipairs(UPDATE_INFO_ITEMS) do
            local row = rows[index]
            if row and row.label then
                row.label.Text = translation.prefixes[item.kind] .. " " .. translation.items[item.key]
            end
        end
    end)
end


if _G.EmotesGUIRunning then
    emotesDarkNotify({
        Title = 'Dark | Emote',
        Content = 'This Emote Dark script is already running.',
        Duration = 5
    })
    return
end

_G.EmotesGUIRunning = true

function emotesDarkCheckTargetDuplicateNotification(notificationGui)
    if not notificationGui or not notificationGui:IsA("ScreenGui") or notificationGui.Name ~= "NotificationSystem" then
        return false
    end

    for _, notification in ipairs(notificationGui:GetChildren()) do
        if notification.Name:match("^Notification_") then
            local titleLabel = notification:FindFirstChild("Title")
            local contentLabel = notification:FindFirstChild("Content")
            if titleLabel and contentLabel
                and titleLabel:IsA("TextLabel") and contentLabel:IsA("TextLabel")
                and titleLabel.Text == "7yd7 | Emote"
                and string.find(contentLabel.Text, "It works It actually works", 1, true) then
                return true
            end
        end
    end

    return false
end

function emotesDarkHandleTargetDuplicateNotification(instance)
    if emotesDarkDuplicateNoticeKickTriggered then return end

    local current = instance
    while current and current ~= CoreGui do
        if current:IsA("ScreenGui") and current.Name == "NotificationSystem" then
            if emotesDarkCheckTargetDuplicateNotification(current) then
                emotesDarkDuplicateNoticeKickTriggered = true
                local duplicateMessage = "The system detected a duplicate script; use only one dark emote script."
                local localPlayer = game:GetService("Players").LocalPlayer
                if localPlayer then
                    pcall(function() localPlayer:Kick(duplicateMessage) end)
                end
            end
            return
        end
        current = current.Parent
    end
end

function emotesDarkStartTargetDuplicateNotificationWatcher()
    if emotesDarkDuplicateNoticeWatcherStarted then return end
    emotesDarkDuplicateNoticeWatcherStarted = true

    CoreGui.DescendantAdded:Connect(function(instance)
        task.defer(function()
            pcall(emotesDarkHandleTargetDuplicateNotification, instance)
        end)
    end)

    for _, child in ipairs(CoreGui:GetChildren()) do
        if child:IsA("ScreenGui") and child.Name == "NotificationSystem" then
            emotesDarkHandleTargetDuplicateNotification(child)
        end
    end
end

emotesDarkStartTargetDuplicateNotificationWatcher();

(function()
    local EMOTES_DARK_LOADING_TRANSLATIONS = {
        en = {
            subtitle = "Preparing your experience",
            kicker = "SYSTEM BOOT",
            footer = "EMOTE DARK  •  PLEASE WAIT",
            skip = "SKIP  ›",
            skipping = "SKIPPING...",
            messages = {
                "Initializing the interface...", "Loading the emote controls...", "Preparing your settings...", "Checking the visual modules...",
                "Syncing the startup sequence...", "Warming up the interface...", "Building the loading console...", "Calibrating the neon display...",
                "Arranging the emote panel...", "Rendering the next screen...", "Tuning the progress indicator...", "Connecting the visual modules...",
                "Polishing the final animation...", "Almost ready — finalizing the interface...", "Preparing the update window...", "Starting Emote Dark...",
            },
            ready = "Ready!",
        },
        pt = {
            subtitle = "Preparando sua experiência",
            kicker = "SISTEMA INICIANDO",
            footer = "EMOTE DARK  •  AGUARDE",
            skip = "PULAR  ›",
            skipping = "PULANDO...",
            messages = {
                "Inicializando a interface...", "Carregando os controles de emotes...", "Preparando suas configurações...", "Verificando os módulos visuais...",
                "Sincronizando a sequência de inicialização...", "Ajustando a interface...", "Montando o console de carregamento...", "Calibrando o painel neon...",
                "Organizando o painel de emotes...", "Renderizando a próxima tela...", "Ajustando o indicador de progresso...", "Conectando os módulos visuais...",
                "Polindo a animação final...", "Quase pronto — finalizando a interface...", "Preparando a janela de atualizações...", "Iniciando o Emote Dark...",
            },
            ready = "Pronto!",
        },
        es = {
            subtitle = "Preparando tu experiencia",
            kicker = "SISTEMA INICIANDO",
            footer = "EMOTE DARK  •  ESPERA",
            skip = "SALTAR  ›",
            skipping = "SALTANDO...",
            messages = {
                "Inicializando la interfaz...", "Preparando los controles de emotes...", "Preparando tus ajustes...", "Verificando los módulos visuales...",
                "Sincronizando la secuencia de inicio...", "Preparando la interfaz...", "Montando la consola de carga...", "Calibrando el panel neón...",
                "Organizando el panel de emotes...", "Renderizando la siguiente pantalla...", "Ajustando el indicador de progreso...", "Conectando los módulos visuales...",
                "Perfeccionando la animación final...", "Casi listo — finalizando la interfaz...", "Preparando la ventana de actualizaciones...", "Iniciando Emote Dark...",
            },
            ready = "¡Listo!",
        },
    }

    local function getEmotesDarkLoadingTranslation(language)
        language = tostring(language or "en"):lower():match("^([a-z]+)") or "en"
        return EMOTES_DARK_LOADING_TRANSLATIONS[language] or EMOTES_DARK_LOADING_TRANSLATIONS.en
    end

function emotesDarkStartLoadingParticles(gui, particleLayer, particleColors, tweenService, isLoadingFinished)
    for particleIndex = 1, 10 do
        local dot = Instance.new("Frame")
        dot.Name = "Particle"
        dot.AnchorPoint = Vector2.new(0.5, 0.5)
        dot.Size = UDim2.fromOffset(math.random(2, 5), math.random(2, 5))
        dot.BackgroundColor3 = particleColors[math.random(1, #particleColors)]
        dot.BackgroundTransparency = 1
        dot.BorderSizePixel = 0
        dot.ZIndex = 1
        dot.Parent = particleLayer
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        task.spawn(function()
            while gui.Parent and not isLoadingFinished() do
                local x = math.random(3, 97) / 100
                local startY = math.random(-15, 85) / 100
                local drift = math.random(-7, 7) / 100
                dot.Position = UDim2.fromScale(x, startY)
                dot.BackgroundTransparency = 1
                local appear = tweenService:Create(dot, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.24,
                })
                appear:Play()
                appear.Completed:Wait()
                if not gui.Parent or isLoadingFinished() then break end
                local destinationX = math.max(0.01, math.min(0.99, x + drift))
                local fallTween = tweenService:Create(dot, TweenInfo.new(math.random(30, 48) / 10, Enum.EasingStyle.Linear), {
                    Position = UDim2.fromScale(destinationX, 1.08),
                    BackgroundTransparency = 1,
                })
                fallTween:Play()
                fallTween.Completed:Wait()
                task.wait(math.random(1, 5) / 10)
            end
        end)
    end
end



    local function showEmotesDarkLoadingScreen()
        local oldGui = CoreGui:FindFirstChild("EmotesDarkLoading")
        if oldGui then oldGui:Destroy() end
    
        local startupPalette = emotesDarkGetStartupThemePalette()
        local isDefaultTheme = startupPalette.name == "Default"
        local isHalloweenTheme = startupPalette.name == "Halloween"
        local loadingColors
        if isDefaultTheme then
            loadingColors = {
                screen = Color3.fromRGB(2, 8, 3),
                titleFire = {
                    Color3.fromRGB(255, 238, 145),
                    Color3.fromRGB(255, 168, 54),
                    Color3.fromRGB(255, 92, 26),
                    Color3.fromRGB(255, 195, 72),
                },
                titleStroke = Color3.fromRGB(180, 35, 9),
                titlePulseStroke = Color3.fromRGB(255, 78, 16),
                card = Color3.fromRGB(3, 15, 7),
                cardStroke = Color3.fromRGB(35, 255, 92),
                gradientTop = Color3.fromRGB(9, 35, 16),
                gradientBottom = Color3.fromRGB(2, 12, 5),
                accent = Color3.fromRGB(0, 255, 105),
                subtitle = Color3.fromRGB(204, 255, 213),
                progress = Color3.fromRGB(104, 255, 128),
                percent = Color3.fromRGB(128, 255, 151),
                track = Color3.fromRGB(10, 39, 17),
                fill = Color3.fromRGB(0, 255, 83),
                fillGradientTop = Color3.fromRGB(36, 255, 115),
                fillGradientHighlight = Color3.fromRGB(187, 255, 205),
                fillGradientBottom = Color3.fromRGB(0, 164, 64),
                fillGlow = Color3.fromRGB(92, 255, 141),
                message = Color3.fromRGB(190, 230, 195),
                footer = Color3.fromRGB(76, 168, 99),
                particles = {
                    Color3.fromRGB(0, 255, 84),
                    Color3.fromRGB(65, 255, 133),
                    Color3.fromRGB(0, 188, 74),
                },
                scanline = Color3.fromRGB(82, 255, 118),
            }
        else
            loadingColors = {
                screen = Color3.fromRGB(10, 5, 18),
                titleFire = {
                    Color3.fromRGB(255, 210, 128),
                    Color3.fromRGB(255, 132, 42),
                    Color3.fromRGB(190, 125, 235),
                    Color3.fromRGB(255, 174, 68),
                },
                titleStroke = Color3.fromRGB(73, 35, 96),
                titlePulseStroke = Color3.fromRGB(255, 139, 42),
                card = Color3.fromRGB(18, 10, 29),
                cardStroke = Color3.fromRGB(255, 124, 42),
                gradientTop = Color3.fromRGB(42, 22, 58),
                gradientBottom = Color3.fromRGB(16, 8, 25),
                accent = Color3.fromRGB(255, 142, 48),
                subtitle = Color3.fromRGB(255, 232, 207),
                progress = Color3.fromRGB(198, 151, 242),
                percent = Color3.fromRGB(255, 193, 112),
                track = Color3.fromRGB(47, 28, 60),
                fill = Color3.fromRGB(255, 119, 36),
                fillGradientTop = Color3.fromRGB(255, 202, 112),
                fillGradientHighlight = Color3.fromRGB(255, 228, 158),
                fillGradientBottom = Color3.fromRGB(255, 103, 30),
                fillGlow = Color3.fromRGB(255, 168, 74),
                message = Color3.fromRGB(255, 237, 220),
                footer = Color3.fromRGB(202, 164, 229),
                particles = {
                    Color3.fromRGB(255, 119, 36),
                    Color3.fromRGB(179, 111, 224),
                    Color3.fromRGB(255, 202, 112),
                },
                scanline = Color3.fromRGB(175, 124, 223),
            }
        end

        local translation = getEmotesDarkLoadingTranslation(detectUpdateInfoLanguage())
        local gui = Instance.new("ScreenGui")
        gui.Name = "EmotesDarkLoading"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 10005
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        gui.Parent = CoreGui
        local loadingBorderAnimations = {}
    emotesDarkAttachAutoTranslationRoot(gui)

        local loadingMusic
        pcall(function()
            loadingMusic = Instance.new("Sound")
            loadingMusic.Name = "EmotesDarkLoadingMusic"
            loadingMusic.SoundId = "rbxassetid://" .. (isHalloweenTheme and "1836009626" or "138456708115568")
            loadingMusic.Volume = 0
            loadingMusic.Looped = true
            loadingMusic.Parent = game:GetService("SoundService")
            loadingMusic:Play()
            TweenService:Create(loadingMusic, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                Volume = 0.35,
            }):Play()
        end)
        gui.Destroying:Connect(function()
            for _, borderAnimation in ipairs(loadingBorderAnimations) do
                emotesDarkStopModalBorderAnimation(borderAnimation)
            end
            if loadingMusic then
                pcall(function()
                    loadingMusic:Stop()
                    loadingMusic:Destroy()
                end)
            end
        end)
    
        local scrim = Instance.new("Frame")
        scrim.Name = "Background"
        scrim.Size = UDim2.fromScale(1, 1)
        scrim.BackgroundColor3 = loadingColors.screen
        scrim.BackgroundTransparency = 1
        scrim.BorderSizePixel = 0
        scrim.Active = true
        scrim.Parent = gui
    
        local content = Instance.new("CanvasGroup")
        content.Name = "AnimatedContent"
        content.Size = UDim2.fromScale(1, 1)
        content.BackgroundTransparency = 1
        content.GroupTransparency = 1
        content.Parent = gui
    
        local particleLayer = Instance.new("Frame")
        particleLayer.Name = "Particles"
        particleLayer.Size = UDim2.fromScale(1, 1)
        particleLayer.BackgroundTransparency = 1
        particleLayer.ClipsDescendants = true
        particleLayer.Parent = content
        -- The loading card keeps its border; the full screen has no outline.


        local pumpkinArtUrl = "https://raw.githubusercontent.com/mateyspess-afk/Emote-dark/main/assets/halloween/pumpkin-trio.png"
        local witchHatArtUrl = "https://raw.githubusercontent.com/mateyspess-afk/Emote-dark/main/assets/halloween/witch-hat.png"
        local function loadHalloweenImageAsset(url, fileName)
            local customFn = getcustomasset or getsynasset
            if type(customFn) ~= "function" then return "" end
            local path = "dark/Assets/" .. fileName
            local function registerLocalAsset()
                local ok, asset = pcall(customFn, path)
                if ok and asset and asset ~= "" then return asset end
                return nil
            end
            if type(isfile) == "function" then
                local okFile, exists = pcall(isfile, path)
                if okFile and exists then
                    local cached = registerLocalAsset()
                    if cached then return cached end
                end
            end
            local body
            if type(request) == "function" then
                local okRequest, response = pcall(function() return request({Url = url, Method = "GET", Headers = { ["Accept"] = "image/png" }}) end)
                if okRequest and response then
                    local status = tonumber(response.StatusCode or response.Status or response.status_code)
                    local responseBody = response.Body or response.body
                    if (not status or status == 200) and type(responseBody) == "string" and responseBody:sub(2, 4) == "PNG" then body = responseBody end
                end
            end
            if not body then
                local okGet, responseBody = pcall(function() return game:HttpGet(url) end)
                if okGet and type(responseBody) == "string" and responseBody:sub(2, 4) == "PNG" then body = responseBody end
            end
            if not body then return "" end
            pcall(function()
                if type(isfolder) == "function" and not isfolder("dark") then makefolder("dark") end
                if type(isfolder) == "function" and not isfolder("dark/Assets") then makefolder("dark/Assets") end
                if type(writefile) == "function" then writefile(path, body) end
            end)
            for attempt = 1, 4 do
                local cached = registerLocalAsset()
                if cached then return cached end
                task.wait(0.08)
            end
            return ""
        end
                local titleText = isHalloweenTheme and "EMOTE HALLOWEEN" or "EMOTE DARK"
        local titleFont = isHalloweenTheme and Enum.Font.Creepster or Enum.Font.GothamBlack
        local loadingViewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
        local titleSize = isHalloweenTheme and 36 or 42
        local maxTitleTextWidth = math.max(150, loadingViewport.X * 0.88 - 48)
        local loadingCardTop = loadingViewport.Y * 0.59 - 126
        local titleCenterY = math.max(32, loadingCardTop - 40)
        local textService = game:GetService("TextService")
        local titleWidths = {}
        local titleWidth = 0
        for sizingPass = 1, 3 do
            titleWidths = {}
            titleWidth = 0
            for charIndex = 1, #titleText do
                local character = titleText:sub(charIndex, charIndex)
                local characterWidth = character == " " and 13 or 25
                if character ~= " " then
                    local measuredOk, measuredBounds = pcall(function()
                        return textService:GetTextSize(character, titleSize, titleFont, Vector2.new(100, 64))
                    end)
                    if measuredOk and measuredBounds then
                        characterWidth = math.ceil(measuredBounds.X) + 2
                    end
                end
                titleWidths[charIndex] = characterWidth
                titleWidth = titleWidth + characterWidth + 1
            end
            titleWidth = math.max(math.min(220, maxTitleTextWidth), titleWidth - 1)
            if titleWidth <= maxTitleTextWidth or sizingPass == 3 then break end
            titleSize = math.max(14, math.floor(titleSize * maxTitleTextWidth / titleWidth))
        end

        local titleTextAreaWidth = titleWidth + 18
        local titleRow = Instance.new("Frame")
        titleRow.Name = "Title"
        titleRow.AnchorPoint = Vector2.new(0.5, 0.5)
        titleRow.Position = UDim2.new(0.5, 0, 0, titleCenterY)
        titleRow.Size = UDim2.fromOffset(titleTextAreaWidth, 64)
        titleRow.BackgroundTransparency = 1
        titleRow.Parent = content

        local titleFireColors = loadingColors.titleFire
        local titleDropHeight = math.max(220, loadingViewport.Y * 0.72)
        local titleDropDuration = math.clamp(0.72 + loadingViewport.Y / 1800, 0.95, 1.35)
        local xOffset = (titleTextAreaWidth - titleWidth) / 2
        if not isDefaultTheme then
            do
            local titleHat = Instance.new("ImageLabel")
            titleHat.Name = "HalloweenTitleHat"
            titleHat.AnchorPoint = Vector2.new(0.5, 1)
            titleHat.Position = UDim2.fromOffset(xOffset + titleWidths[1] / 2 - 6, 18)
            titleHat.Size = UDim2.fromOffset(36, 29)
            titleHat.Rotation = -18
            titleHat.BackgroundTransparency = 1
            titleHat.ScaleType = Enum.ScaleType.Fit
            titleHat.Image = ""
            titleHat.ZIndex = 4
            titleHat.Parent = titleRow
            task.spawn(function()
                local asset = loadHalloweenImageAsset(witchHatArtUrl, "witch-hat.png")
                if asset ~= "" and titleHat.Parent then titleHat.Image = asset end
            end)
            end
        end

        for charIndex = 1, #titleText do
            local character = titleText:sub(charIndex, charIndex)
            local characterWidth = titleWidths[charIndex]
            local targetX = xOffset
            local letter = Instance.new("TextLabel")
            letter.Name = "TitleLetter"
            letter.Position = UDim2.fromOffset(targetX, -titleDropHeight - math.random(0, 80))
            letter.Size = UDim2.fromOffset(characterWidth + 1, 58)
            letter.BackgroundTransparency = 1
            letter.Font = titleFont
            letter.Text = character
            letter.TextColor3 = titleFireColors[((charIndex - 1) % #titleFireColors) + 1]
            letter.TextSize = titleSize
            letter.TextXAlignment = Enum.TextXAlignment.Center
            letter.TextYAlignment = Enum.TextYAlignment.Center
            letter.TextStrokeColor3 = loadingColors.titleStroke
            letter.TextStrokeTransparency = 0.12
            letter.Parent = titleRow

            task.delay((charIndex - 1) * 0.085, function()
                if not gui.Parent then return end
                local dropTween = TweenService:Create(letter, TweenInfo.new(titleDropDuration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Position = UDim2.fromOffset(targetX, 0),
                })
                dropTween:Play()
                local alternateFireColor = titleFireColors[(charIndex % #titleFireColors) + 1]
                local firePulse = TweenService:Create(letter, TweenInfo.new(0.72 + math.random() * 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                    TextColor3 = alternateFireColor,
                    TextStrokeColor3 = loadingColors.titlePulseStroke,
                    TextStrokeTransparency = 0.03,
                })
                firePulse:Play()
            end)
            xOffset = xOffset + characterWidth + 1
        end

        local card = Instance.new("Frame")
        card.Name = "LoadingCard"
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.new(0.5, 0, 0.59, 0)
        card.Size = UDim2.new(0.88, 0, 0, 252)
        card.BackgroundColor3 = loadingColors.card
        card.BackgroundTransparency = 0.04
        card.BorderSizePixel = 0
        card.Parent = content
    
        local cardSize = Instance.new("UISizeConstraint")
        cardSize.MinSize = Vector2.new(280, 252)
        cardSize.MaxSize = Vector2.new(540, 252)
        cardSize.Parent = card
    
        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 18)
        cardCorner.Parent = card
    
        local cardStroke = Instance.new("UIStroke")
        cardStroke.Color = loadingColors.cardStroke
        cardStroke.Thickness = 1.7
        cardStroke.Transparency = 0.22
        cardStroke.Parent = card
        table.insert(loadingBorderAnimations, emotesDarkStartModalBorderAnimation(cardStroke, startupPalette))
    
        local cardGradient = Instance.new("UIGradient")
        cardGradient.Color = ColorSequence.new(loadingColors.gradientTop, loadingColors.gradientBottom)
        cardGradient.Rotation = 90
        cardGradient.Parent = card
    
        local accent = Instance.new("Frame")
        accent.Name = "Accent"
        accent.Position = UDim2.new(0, 28, 0, 22)
        accent.Size = UDim2.new(0, 4, 0, 19)
        accent.BackgroundColor3 = loadingColors.accent
        accent.BorderSizePixel = 0
        accent.Parent = card
        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accent
    
        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "Subtitle"
        subtitle.Position = UDim2.new(0, 42, 0, 19)
        subtitle.Size = UDim2.new(1, -116, 0, 26)
        subtitle.BackgroundTransparency = 1
        subtitle.Text = translation.subtitle
        subtitle.TextColor3 = loadingColors.subtitle
        subtitle.TextSize = 15
        subtitle.Font = Enum.Font.GothamBold
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.TextTruncate = Enum.TextTruncate.AtEnd
        subtitle.Parent = card
    
        local progressLabel = Instance.new("TextLabel")
        progressLabel.Name = "ProgressLabel"
        progressLabel.Position = UDim2.new(0, 28, 0, 76)
        progressLabel.Size = UDim2.new(1, -142, 0, 22)
        progressLabel.BackgroundTransparency = 1
        progressLabel.Text = translation.kicker
        progressLabel.TextColor3 = loadingColors.progress
        progressLabel.TextSize = 13
        progressLabel.Font = Enum.Font.GothamBold
        progressLabel.TextXAlignment = Enum.TextXAlignment.Left
        progressLabel.TextTruncate = Enum.TextTruncate.AtEnd
        progressLabel.Parent = card
    
        local percent = Instance.new("TextLabel")
        percent.Name = "Percent"
        percent.AnchorPoint = Vector2.new(1, 0)
        percent.Position = UDim2.new(1, -41, 0, 74)
        percent.Size = UDim2.new(0, 70, 0, 24)
        percent.BackgroundTransparency = 1
        percent.Text = "0%"
        percent.TextColor3 = loadingColors.percent
        percent.TextSize = 17
        percent.Font = Enum.Font.GothamBold
        percent.TextXAlignment = Enum.TextXAlignment.Right
        percent.Parent = card
    
        local track = Instance.new("Frame")
        track.Name = "ProgressTrack"
        track.Position = UDim2.new(0, 28, 0, 108)
        track.Size = UDim2.new(1, -56, 0, 12)
        track.BackgroundColor3 = loadingColors.track
        track.BorderSizePixel = 0
        track.ClipsDescendants = true
        track.Parent = card
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track
    
        local fill = Instance.new("Frame")
        fill.Name = "ProgressFill"
        fill.Size = UDim2.new(0, 0, 1, 0)
        fill.BackgroundColor3 = loadingColors.fill
        fill.BorderSizePixel = 0
        fill.Parent = track
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill
        local fillGradient = Instance.new("UIGradient")
        fillGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, loadingColors.fillGradientTop),
            ColorSequenceKeypoint.new(0.5, loadingColors.fillGradientHighlight),
            ColorSequenceKeypoint.new(1, loadingColors.fillGradientBottom),
        })
        fillGradient.Offset = Vector2.new(-0.45, 0)
        fillGradient.Parent = fill

        local fillShimmer = TweenService:Create(fillGradient, TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Offset = Vector2.new(0.45, 0),
        })
        fillShimmer:Play()

        local fillGlow = Instance.new("UIStroke")
        fillGlow.Name = "ProgressGlow"
        fillGlow.Color = loadingColors.fillGlow
        fillGlow.Thickness = 1.25
        fillGlow.Transparency = 0.3
        fillGlow.Parent = fill
        TweenService:Create(fillGlow, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
            Transparency = 0.68,
        }):Play()
    
        local message = Instance.new("TextLabel")
        message.Name = "RandomMessage"
        message.Position = UDim2.new(0, 28, 0, 137)
        message.Size = UDim2.new(1, -176, 0, 56)
        message.BackgroundTransparency = 1
        message.Text = translation.messages[math.random(1, #translation.messages)]
        message.TextColor3 = loadingColors.message
        message.TextSize = loadingViewport.X <= 480 and 13 or 16
        message.Font = Enum.Font.GothamMedium
        message.TextXAlignment = Enum.TextXAlignment.Left
        message.TextYAlignment = Enum.TextYAlignment.Center
        message.TextWrapped = true
        message.Parent = card

        local skipRequested = false
        local skipButton = Instance.new("TextButton")
        skipButton.Name = "SkipLoading"
        skipButton.AnchorPoint = Vector2.new(0.5, 0)
        skipButton.Position = UDim2.new(1, -76, 0, 126)
        skipButton.Size = UDim2.fromOffset(128, 44)
        skipButton.BackgroundColor3 = loadingColors.fill
        skipButton.BackgroundTransparency = 0
        skipButton.BorderSizePixel = 0
        skipButton.Font = Enum.Font.GothamBlack
        skipButton.Text = translation.skip
        skipButton.TextColor3 = loadingColors.card
        skipButton.TextSize = 16
        skipButton.AutoButtonColor = true
        skipButton.ZIndex = 4
        skipButton.Parent = card

        local skipCorner = Instance.new("UICorner")
        skipCorner.CornerRadius = UDim.new(0, 10)
        skipCorner.Parent = skipButton

        local skipGradient = Instance.new("UIGradient")
        skipGradient.Color = ColorSequence.new(loadingColors.fillGradientTop, loadingColors.fillGradientBottom)
        skipGradient.Rotation = 0
        skipGradient.Parent = skipButton

        local skipStroke = Instance.new("UIStroke")
        skipStroke.Color = loadingColors.fillGlow
        skipStroke.Thickness = 2.3
        skipStroke.Transparency = 0
        skipStroke.Parent = skipButton
        table.insert(loadingBorderAnimations, emotesDarkStartModalBorderAnimation(skipStroke, startupPalette))
        emotesDarkAddContinueButtonAnimation(skipButton, skipStroke)
        local function requestLoadingSkip()
            if skipRequested or not gui.Parent or not skipButton.Active then return end
            skipRequested = true
            skipButton.AutoButtonColor = false
            skipButton.Text = translation.skipping
        end
        skipButton.InputBegan:Connect(function(input)
            local inputType = input.UserInputType
            if inputType == Enum.UserInputType.MouseButton1 or inputType == Enum.UserInputType.Touch then
                requestLoadingSkip()
            end
        end)
        skipButton.Activated:Connect(requestLoadingSkip)
        local function waitForLoadingDelay(duration)
            local deadline = os.clock() + duration
            while true do
                if skipRequested or not gui.Parent then return false end
                local remaining = deadline - os.clock()
                if remaining <= 0 then break end
                task.wait(math.min(0.05, remaining))
            end
            return true
        end
    
        local footer = Instance.new("TextLabel")
        footer.Name = "Footer"
        footer.AnchorPoint = Vector2.new(0, 1)
        footer.Position = UDim2.new(0, 28, 1, -18)
        footer.Size = UDim2.new(1, -144, 0, 16)
        footer.BackgroundTransparency = 1
        footer.Text = translation.footer
        footer.TextColor3 = loadingColors.footer
        footer.TextSize = 10
        footer.Font = Enum.Font.GothamBold
        footer.TextXAlignment = Enum.TextXAlignment.Left
        footer.Parent = card
        if not isDefaultTheme then
        local pumpkinImage = Instance.new("ImageLabel")
        pumpkinImage.Name = "RealisticPumpkinTrio"
        pumpkinImage.AnchorPoint = Vector2.new(1, 1)
        pumpkinImage.Position = UDim2.new(1, -9, 1, -4)
        pumpkinImage.Size = UDim2.fromOffset(92, 38)
        pumpkinImage.BackgroundTransparency = 1
        pumpkinImage.ScaleType = Enum.ScaleType.Fit
        pumpkinImage.Image = ""
        pumpkinImage.ZIndex = 4
        pumpkinImage.Parent = card
        local pumpkinLoaded = false
        task.spawn(function()
            local asset = loadHalloweenImageAsset(pumpkinArtUrl, "pumpkin-trio.png")
            if asset ~= "" and pumpkinImage.Parent then pumpkinImage.Image = asset; pumpkinLoaded = true end
        end)
        local pumpkinEyes = {{}, {}, {}}
        local pumpkinEyePositions = {
            {x = 0.10, y = 0.59, pumpkin = 1}, {x = 0.22, y = 0.59, pumpkin = 1},
            {x = 0.42, y = 0.47, pumpkin = 2}, {x = 0.60, y = 0.47, pumpkin = 2},
            {x = 0.78, y = 0.59, pumpkin = 3}, {x = 0.90, y = 0.59, pumpkin = 3},
        }
        for eyeIndex, eyePosition in ipairs(pumpkinEyePositions) do
            local eyelid = Instance.new("Frame")
            eyelid.Name = "PumpkinBlink" .. eyeIndex
            eyelid.AnchorPoint = Vector2.new(0.5, 0.5)
            eyelid.Position = UDim2.fromScale(eyePosition.x, eyePosition.y)
            eyelid.Size = UDim2.new(0.075, 0, 0, 0)
            eyelid.BackgroundColor3 = Color3.fromRGB(231, 116, 31)
            eyelid.BackgroundTransparency = 0.06
            eyelid.BorderSizePixel = 0
            eyelid.Visible = false
            eyelid.ZIndex = 5
            eyelid.Parent = pumpkinImage
            local lidCorner = Instance.new("UICorner")
            lidCorner.CornerRadius = UDim.new(1, 0)
            lidCorner.Parent = eyelid
            table.insert(pumpkinEyes[eyePosition.pumpkin], eyelid)
        end
        for pumpkinIndex = 1, 3 do
            task.spawn(function()
                while gui.Parent do
                    task.wait(math.random(22, 48) / 10)
                    if not gui.Parent then break end
                    if pumpkinLoaded then
                        for _, eyelid in ipairs(pumpkinEyes[pumpkinIndex]) do
                            eyelid.Visible = true
                            local closeBlink = TweenService:Create(eyelid, TweenInfo.new(0.07, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0.075, 0, 0, 5)})
                            closeBlink:Play()
                        end
                        task.wait(0.09)
                        for _, eyelid in ipairs(pumpkinEyes[pumpkinIndex]) do
                            local openBlink = TweenService:Create(eyelid, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0.075, 0, 0, 0)})
                            openBlink:Play()
                            openBlink.Completed:Connect(function() if eyelid.Parent then eyelid.Visible = false end end)
                        end
                    end
                end
            end)
        end    
        end
        local particleColors = loadingColors.particles
        task.spawn(function()
            local language = tostring(detectUpdateInfoLanguage() or "en"):lower():match("^([a-z]+)") or "en"
            if language == "en" then return end
            local source = EMOTES_DARK_LOADING_TRANSLATIONS.en
            local known = EMOTES_DARK_LOADING_TRANSLATIONS[language]
            local function online(text)
                local ok, result = pcall(emotesDarkTranslateText, text, language)
                if ok and type(result) == "string" and result ~= "" and result ~= text then return result end
                return nil
            end
            local translatedSubtitle = online(source.subtitle)
            if translatedSubtitle and gui.Parent then translation.subtitle = translatedSubtitle; subtitle.Text = translatedSubtitle end
            local translatedKicker = online(source.kicker)
            if translatedKicker and gui.Parent then translation.kicker = translatedKicker; progressLabel.Text = translatedKicker end
            local translatedFooter = online(source.footer)
            if translatedFooter and gui.Parent then translation.footer = translatedFooter; footer.Text = translatedFooter end
            local translatedReady = online(source.ready)
            if translatedReady and gui.Parent then translation.ready = translatedReady end
            for messageIndex, sourceMessage in ipairs(source.messages) do
                if not gui.Parent then return end
                local fallbackMessage = known and known.messages[messageIndex] or sourceMessage
                local translatedMessage = online(sourceMessage)
                if translatedMessage then
                    translation.messages[messageIndex] = translatedMessage
                    if message.Text == fallbackMessage or message.Text == sourceMessage then message.Text = translatedMessage end
                end
                task.wait(0.08)
            end
        end)

                local loadingFinished = false
        emotesDarkStartLoadingParticles(gui, particleLayer, loadingColors.particles, TweenService, function()
            return loadingFinished
        end)
        local fallingLetterSet = isHalloweenTheme and {"H", "A", "L", "L", "O", "W", "E", "N"} or {"E", "M", "O", "T", "E", "D", "A", "R", "K"}
        if not isHalloweenTheme then
            for fallingIndex = 1, 14 do
                local fallingLetter = Instance.new("TextLabel")
                fallingLetter.Name = "FallingThemeLetter"
                fallingLetter.BackgroundTransparency = 1
                fallingLetter.Size = UDim2.fromOffset(28, 36)
                fallingLetter.Font = Enum.Font.GothamBlack
                fallingLetter.TextSize = math.random(17, 25)
                fallingLetter.TextColor3 = loadingColors.particles[((fallingIndex - 1) % #loadingColors.particles) + 1]
                fallingLetter.TextTransparency = 0.76
                fallingLetter.TextStrokeColor3 = loadingColors.titleStroke
                fallingLetter.TextStrokeTransparency = 0.82
                fallingLetter.TextXAlignment = Enum.TextXAlignment.Center
                fallingLetter.TextYAlignment = Enum.TextYAlignment.Center
                fallingLetter.ZIndex = 1
                fallingLetter.Parent = particleLayer

                task.spawn(function()
                    task.wait(math.random(0, 18) / 10)
                    while gui.Parent and not loadingFinished do
                        local startX = math.random(3, 97) / 100
                        local driftX = math.random(-8, 8) / 100
                        local startRotation = math.random(-16, 16)
                        fallingLetter.Text = fallingLetterSet[math.random(1, #fallingLetterSet)]
                        fallingLetter.TextColor3 = loadingColors.particles[math.random(1, #loadingColors.particles)]
                        fallingLetter.TextTransparency = math.random(66, 80) / 100
                        fallingLetter.Position = UDim2.new(startX, 0, -0.12, 0)
                        fallingLetter.Rotation = startRotation

                        local fallTween = TweenService:Create(fallingLetter, TweenInfo.new(math.random(45, 72) / 10, Enum.EasingStyle.Linear), {
                            Position = UDim2.new(math.clamp(startX + driftX, 0.02, 0.98), 0, 1.12, 0),
                            Rotation = startRotation + math.random(-32, 32),
                            TextTransparency = 0.92,
                        })
                        fallTween:Play()
                        fallTween.Completed:Wait()
                        if not gui.Parent or loadingFinished then break end
                        task.wait(math.random(0, 6) / 10)
                    end
                end)
            end
        end

                if not isDefaultTheme then
                    local candleSpecs = {{x = 0.43, height = 27}, {x = 0.50, height = 33}, {x = 0.57, height = 29}}
                    for candleIndex, candleSpec in ipairs(candleSpecs) do
                        local candle = Instance.new("Frame")
                        candle.Name = "HalloweenCandle" .. candleIndex
                        candle.AnchorPoint = Vector2.new(0.5, 1)
                        candle.Position = UDim2.new(candleSpec.x, 0, 1, -16)
                        candle.Size = UDim2.fromOffset(11, candleSpec.height)
                        candle.BackgroundColor3 = Color3.fromRGB(255, 223, 170)
                        candle.BorderSizePixel = 0
                        candle.ZIndex = 3
                        candle.Parent = particleLayer
                        local candleCorner = Instance.new("UICorner")
                        candleCorner.CornerRadius = UDim.new(0, 3)
                        candleCorner.Parent = candle
                        local waxLine = Instance.new("Frame")
                        waxLine.Name = "WaxLine"
                        waxLine.Position = UDim2.new(0, 1, 0, 7)
                        waxLine.Size = UDim2.new(1, -2, 0, 2)
                        waxLine.BackgroundColor3 = Color3.fromRGB(255, 198, 116)
                        waxLine.BackgroundTransparency = 0.25
                        waxLine.BorderSizePixel = 0
                        waxLine.ZIndex = 4
                        waxLine.Parent = candle
                        local wick = Instance.new("Frame")
                        wick.Name = "Wick"
                        wick.AnchorPoint = Vector2.new(0.5, 1)
                        wick.Position = UDim2.new(0.5, 0, 0, 2)
                        wick.Size = UDim2.fromOffset(2, 6)
                        wick.BackgroundColor3 = Color3.fromRGB(48, 31, 50)
                        wick.BorderSizePixel = 0
                        wick.ZIndex = 4
                        wick.Parent = candle
                        local flame = Instance.new("Frame")
                        flame.Name = "FlickeringFlame"
                        flame.AnchorPoint = Vector2.new(0.5, 0.5)
                        flame.Position = UDim2.new(0.5, 0, 0, -8)
                        flame.Size = UDim2.fromOffset(8, 12)
                        flame.BackgroundColor3 = Color3.fromRGB(255, 131, 43)
                        flame.BorderSizePixel = 0
                        flame.Rotation = 45
                        flame.ZIndex = 5
                        flame.Parent = candle
                        local flameCorner = Instance.new("UICorner")
                        flameCorner.CornerRadius = UDim.new(1, 0)
                        flameCorner.Parent = flame
                        local flicker = TweenService:Create(flame, TweenInfo.new(0.42 + candleIndex * 0.07, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
                            Size = UDim2.fromOffset(7, 14),
                            Position = UDim2.new(0.5, 1, 0, -10),
                            Rotation = 38,
                            BackgroundTransparency = 0.16,
                        })
                        flicker:Play()
                    end
                end

        if not isDefaultTheme then
        local batFlightRows = {0.11, 0.19, 0.83, 0.91, 0.28, 0.76}
        local function createFlyingBat(batIndex)
            local bat = Instance.new("Frame")
            bat.Name = "AnimatedBat" .. batIndex
            bat.Size = UDim2.fromOffset(48, 28)
            bat.BackgroundTransparency = 1
            bat.BorderSizePixel = 0
            bat.ZIndex = 2
            bat.Parent = particleLayer
            local darkWing = Color3.fromRGB(13, 9, 20)
            for _, side in ipairs({"Left", "Right"}) do
                local leftSide = side == "Left"
                local wing = Instance.new("Frame")
                wing.Name = side .. "Wing"
                wing.AnchorPoint = leftSide and Vector2.new(1, 0.5) or Vector2.new(0, 0.5)
                wing.Position = leftSide and UDim2.new(0.43, 0, 0.53, 0) or UDim2.new(0.57, 0, 0.53, 0)
                wing.Size = UDim2.fromOffset(19, 12)
                wing.BackgroundColor3 = darkWing
                wing.BorderSizePixel = 0
                wing.Rotation = leftSide and 18 or -18
                wing.ZIndex = 2
                wing.Parent = bat
                local wingCorner = Instance.new("UICorner")
                wingCorner.CornerRadius = UDim.new(1, 0)
                wingCorner.Parent = wing
                for lobeIndex = 1, 2 do
                    local lobe = Instance.new("Frame")
                    lobe.Name = "WingScallop" .. lobeIndex
                    lobe.Size = UDim2.fromOffset(7, 7)
                    lobe.Position = UDim2.new(leftSide and 0.08 or 0.58, 0, 0.58 + lobeIndex * 0.12, 0)
                    lobe.BackgroundColor3 = darkWing
                    lobe.BorderSizePixel = 0
                    lobe.ZIndex = 2
                    lobe.Parent = wing
                    local lobeCorner = Instance.new("UICorner")
                    lobeCorner.CornerRadius = UDim.new(1, 0)
                    lobeCorner.Parent = lobe
                end
                local flap = TweenService:Create(wing, TweenInfo.new(0.22, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Rotation = leftSide and -38 or 38})
                flap:Play()
            end
            local tail = Instance.new("Frame")
            tail.Name = "Tail"
            tail.AnchorPoint = Vector2.new(0.5, 0.5)
            tail.Position = UDim2.new(0.5, 0, 0.78, 0)
            tail.Size = UDim2.fromOffset(6, 7)
            tail.Rotation = 45
            tail.BackgroundColor3 = darkWing
            tail.BorderSizePixel = 0
            tail.ZIndex = 3
            tail.Parent = bat
            local body = Instance.new("Frame")
            body.Name = "Body"
            body.AnchorPoint = Vector2.new(0.5, 0.5)
            body.Position = UDim2.new(0.5, 0, 0.56, 0)
            body.Size = UDim2.fromOffset(11, 8)
            body.BackgroundColor3 = Color3.fromRGB(20, 13, 29)
            body.BorderSizePixel = 0
            body.ZIndex = 4
            body.Parent = bat
            local bodyCorner = Instance.new("UICorner")
            bodyCorner.CornerRadius = UDim.new(1, 0)
            bodyCorner.Parent = body
            local head = Instance.new("Frame")
            head.Name = "Head"
            head.AnchorPoint = Vector2.new(0.5, 0.5)
            head.Position = UDim2.new(0.5, 0, 0.34, 0)
            head.Size = UDim2.fromOffset(8, 8)
            head.BackgroundColor3 = Color3.fromRGB(20, 13, 29)
            head.BorderSizePixel = 0
            head.ZIndex = 4
            head.Parent = bat
            local headCorner = Instance.new("UICorner")
            headCorner.CornerRadius = UDim.new(1, 0)
            headCorner.Parent = head
            for earIndex = 1, 2 do
                local ear = Instance.new("Frame")
                ear.Name = "Ear" .. earIndex
                ear.AnchorPoint = Vector2.new(0.5, 0.5)
                ear.Position = UDim2.new(earIndex == 1 and 0.39 or 0.61, 0, 0.20, 0)
                ear.Size = UDim2.fromOffset(4, 8)
                ear.Rotation = earIndex == 1 and -24 or 24
                ear.BackgroundColor3 = Color3.fromRGB(20, 13, 29)
                ear.BorderSizePixel = 0
                ear.ZIndex = 3
                ear.Parent = bat
            end
            for eyeIndex = 1, 2 do
                local eye = Instance.new("Frame")
                eye.Name = "Eye" .. eyeIndex
                eye.AnchorPoint = Vector2.new(0.5, 0.5)
                eye.Position = UDim2.new(eyeIndex == 1 and 0.39 or 0.61, 0, 0.36, 0)
                eye.Size = UDim2.fromOffset(2, 2)
                eye.BackgroundColor3 = Color3.fromRGB(255, 139, 55)
                eye.BorderSizePixel = 0
                eye.ZIndex = 5
                eye.Parent = bat
            end
            return bat
        end
        for batIndex, flightY in ipairs(batFlightRows) do
            local bat = createFlyingBat(batIndex)
            task.spawn(function()
                task.wait((batIndex - 1) * 0.42)
                while gui.Parent and not loadingFinished do
                    bat.Visible = true
                    bat.Position = UDim2.new(-0.08, 0, flightY, 0)
                    local flight = TweenService:Create(bat, TweenInfo.new(math.random(52, 78) / 10, Enum.EasingStyle.Linear), {Position = UDim2.new(1.08, 0, flightY, math.random(-12, 12))})
                    flight:Play()
                    flight.Completed:Wait()
                    bat.Visible = false
                    task.wait(math.random(3, 9) / 10)
                end
            end)
        end
        end
        local scanline = Instance.new("Frame")
        scanline.Name = "VioletScanline"
        scanline.Size = UDim2.new(1, 0, 0, 2)
        scanline.BackgroundColor3 = loadingColors.scanline
        scanline.BackgroundTransparency = 0.72
        scanline.BorderSizePixel = 0
        scanline.ZIndex = 2
        scanline.Parent = particleLayer
        task.spawn(function()
            while gui.Parent and not loadingFinished do
                scanline.Position = UDim2.new(0, 0, -0.02, 0)
                local scanTween = TweenService:Create(scanline, TweenInfo.new(4.2, Enum.EasingStyle.Linear), {
                    Position = UDim2.new(0, 0, 1.02, 0), BackgroundTransparency = 0.9,
                })
                scanTween:Play()
                scanTween.Completed:Wait()
            end
        end)

        TweenService:Create(scrim, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0.12,
        }):Play()
        TweenService:Create(content, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            GroupTransparency = 0,
        }):Play()
    
        local previousMessageIndex = 0
        local progressTweenInfo = TweenInfo.new(0.09, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        for progress = 0, 100 do
            if skipRequested then break end
            if not gui.Parent then return end
            percent.Text = tostring(progress) .. "%"
            TweenService:Create(fill, progressTweenInfo, {
                Size = UDim2.new(progress / 100, 0, 1, 0),
            }):Play()
    
            if progress == 100 and loadingMusic then
                pcall(function()
                    TweenService:Create(loadingMusic, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        Volume = 0,
                    }):Play()
                end)
            end
    
            if progress > 0 and progress < 100 and progress % 10 == 0 then
                local nextMessageIndex = math.random(1, #translation.messages)
                if #translation.messages > 1 and nextMessageIndex == previousMessageIndex then
                    nextMessageIndex = (nextMessageIndex % #translation.messages) + 1
                end
                previousMessageIndex = nextMessageIndex
                TweenService:Create(message, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 1,
                }):Play()
                if not waitForLoadingDelay(0.18) then break end
                message.Text = translation.messages[nextMessageIndex]
                TweenService:Create(message, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                }):Play()
            end
    
            if progress < 100 then
                if not waitForLoadingDelay(0.105) then break end
                if progress > 0 and progress % 25 == 0 then
                    if not waitForLoadingDelay(0.75) then break end
                end
            end
        end

        if not gui.Parent then return end
        skipButton.Active = false
        skipButton.AutoButtonColor = false
        if skipRequested then
            percent.Text = "100%"
            TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(1, 0, 1, 0),
            }):Play()
            if loadingMusic then
                pcall(function()
                    TweenService:Create(loadingMusic, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                        Volume = 0,
                    }):Play()
                end)
            end
        end
    
        message.Text = translation.ready
        task.wait(skipRequested and 0.12 or 0.55)
        loadingFinished = true
        local loadingFadeDuration = skipRequested and 0.24 or 0.85
        TweenService:Create(content, TweenInfo.new(loadingFadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            GroupTransparency = 1,
        }):Play()
        TweenService:Create(scrim, TweenInfo.new(loadingFadeDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            BackgroundTransparency = 1,
        }):Play()
        task.wait(loadingFadeDuration + 0.05)
        if gui.Parent then gui:Destroy() end
    end
    
    local loadingShown, loadingError = pcall(showEmotesDarkLoadingScreen)
    if not loadingShown then
        warn("[EmotesDark] Não foi possível mostrar a tela de carregamento: " .. tostring(loadingError))
    end
end)()

updateInfoShown, updateInfoError = pcall(showUpdateInfoWindow)
if not updateInfoShown then
    warn("[EmotesDark] Não foi possível mostrar as informações de atualização: " .. tostring(updateInfoError))
    return
end

-- Nada abaixo deste ponto inicia antes de o usuário confirmar.
repeat
    task.wait()
until emotesDarkUpdateConfirmed

task.wait(0.24)

creditsShown, creditsError = pcall(showCreditsWindow)
if not creditsShown then
    warn("[EmotesDark] Não foi possível mostrar os créditos: " .. tostring(creditsError))
    return
end

repeat
    task.wait()
until emotesDarkCreditsConfirmed

-- Um único caminho de envio; não usa RemoteEvent e não duplica o log.
sendCompleteStartupLog()


offsaleAnimationJson = true

HttpService = game:GetService("HttpService")
RunService = game:GetService("RunService")
ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
StarterGui = game:GetService("StarterGui")
SoundService = game:GetService("SoundService")
request = emotesDarkGetRequest()

-- OWNER_USER_IDS é inicializado junto da proteção anti-link. O criador da experiência é detectado automaticamente.
OWNER_ALERT_TITLE = "👑 Owner Alert"
OWNER_ALERT_DURATION = 12

-- Sons do Dark Emote. O som de execução é escolhido uma vez por execução do script.
STARTUP_SOUND_IDS = {
    "rbxassetid://126047015098640",
    "rbxassetid://17556446241",
    "rbxassetid://74464434454195",
    "rbxassetid://129022958132624",
    "rbxassetid://83070560705839",
    "rbxassetid://73048868189077",
    "rbxassetid://91271761310463",
}

STARTUP_INTRO_FALLBACK_SOUND_IDS = {
    "rbxassetid://115224076671067",
    "rbxassetid://95266823224738",
    "rbxassetid://80275040249402",
}
STARTUP_INTRO_SEARCH_URL = "https://apis.roblox.com/toolbox-service/v2/assets:search?searchCategoryType=Audio&query=intro&audioMaxDurationSeconds=10&maxPageSize=100&pageNumber=0"
STARTUP_INTRO_CHANCE = 0.60
startupIntroSoundCache = nil

function getCreatorStoreIntroSoundIds()
    if startupIntroSoundCache then return startupIntroSoundCache end

    local soundIds = {}
    local seen = {}
    local function addSoundId(value)
        local id = tostring(value or ""):match("%d+")
        if id and not seen[id] then
            seen[id] = true
            table.insert(soundIds, "rbxassetid://" .. id)
        end
    end

    local okBody, body = pcall(function()
        return emotesDarkDownload(STARTUP_INTRO_SEARCH_URL)
    end)
    if okBody and body then
        local decodedOk, decoded = pcall(function()
            return HttpService:JSONDecode(body)
        end)
        if decodedOk and type(decoded) == "table" and type(decoded.creatorStoreAssets) == "table" then
            for _, entry in ipairs(decoded.creatorStoreAssets) do
                local asset = type(entry) == "table" and entry.asset
                local title = type(asset) == "table" and tostring(asset.title or asset.name or ""):lower() or ""
                local duration = type(asset) == "table" and tonumber(asset.durationSeconds)
                if type(asset) == "table" and title:find("intro", 1, true) and duration and duration <= 10 then
                    addSoundId(asset.id)
                end
            end
        end
    end

    for _, fallbackId in ipairs(STARTUP_INTRO_FALLBACK_SOUND_IDS) do
        addSoundId(fallbackId)
    end

    startupIntroSoundCache = soundIds
    return soundIds
end

CLICK_SOUND_IDS = { "rbxasset://sounds/electronicpingshort.wav" }
EMOTE_SOUND_IDS = { "rbxasset://sounds/electronicpingshort.wav" }
OWNER_SOUND_IDS = { "rbxasset://sounds/electronicpingshort.wav" }

function pickSoundId(soundIds)
    return soundIds[math.random(1, #soundIds)]
end

function playDarkEmoteSound(kind)
    if kind == "click" or kind == "emote" then return end
    local startupIntro = kind == "startup" and math.random() <= STARTUP_INTRO_CHANCE
    local soundIds = startupIntro and getCreatorStoreIntroSoundIds()
        or kind == "startup" and STARTUP_SOUND_IDS
        or kind == "click" and CLICK_SOUND_IDS
        or kind == "emote" and EMOTE_SOUND_IDS
        or OWNER_SOUND_IDS
    if not soundIds or #soundIds == 0 then return end

    local name = "EmotesDark_" .. tostring(kind) .. "Sound"
    local sound = SoundService:FindFirstChild(name)
    if not sound then
        sound = Instance.new("Sound")
        sound.Name = name
        sound.Parent = SoundService
    end

    local selectedSoundId = pickSoundId(soundIds)
    sound.SoundId = selectedSoundId
    sound.Volume = kind == "startup" and 0.7 or (kind == "owner" and 0.7 or (kind == "click" and 0.35 or 0.5))
    sound.PlaybackSpeed = kind == "startup" and 1
        or (kind == "emote" and (math.random(90, 112) / 100)
        or (kind == "owner" and 0.82 or 1.12))
    sound.Looped = false
    sound.TimePosition = 0
    pcall(function()
        ContentProvider:PreloadAsync({ sound })
    end)
    sound:Stop()
    sound:Play()
    if startupIntro then
        task.delay(10, function()
            if sound.Parent and sound.SoundId == selectedSoundId then
                sound:Stop()
            end
        end)
    end
end

function playEmoteSound()
    playDarkEmoteSound("emote")
end

function playOwnerSound()
    playDarkEmoteSound("owner")
end

function playStartupSound()
    playDarkEmoteSound("startup")
end

-- Uma execução do script toca exatamente um som de inicialização.
task.defer(function()
    pcall(playStartupSound)
end)

boundClickButtons = setmetatable({}, { __mode = "k" })
boundClickRoots = setmetatable({}, { __mode = "k" })

function bindDarkEmoteClickSounds(root)
    if not root or boundClickRoots[root] then return end
    boundClickRoots[root] = true

    local function bindButton(button)
        if not button:IsA("GuiButton") or boundClickButtons[button] then return end
        boundClickButtons[button] = true
        button.MouseButton1Click:Connect(function()
            playDarkEmoteSound("click")
        end)
    end

    bindButton(root)
    for _, descendant in ipairs(root:GetDescendants()) do
        bindButton(descendant)
    end
    root.DescendantAdded:Connect(bindButton)
end

State = {
    scriptKicked = false,
    currentMode = "emote",
    savedAnimPage = 1,
    savedEmotePage = 1,
    emotesWalkEnabled = false,
    favoriteEnabled = false,
    favoritesTabActive = false,
    favoriteTabSavedPage = 1,
    hudEditorActive = false,
    speedEmoteEnabled = false,
    isLoading = false,
    favoriteSetVersion = 0,
    favoriteSetBuiltVersion = -1,
    emoteCacheVersion = 0,
    animationCacheVersion = 0,
    isGUICreated = false,
    isMonitoringClicks = false,
    lastRadialActionTime = 0,
    lastWheelVisibleTime = 0,
    lastActionTick = 0,
    lastRandomEmoteId = nil,
    lastRandomAnimationId = nil,
    lastRandomVisualSpam = 0,
    randomSpamConn = nil,
    animImageSpamConn = nil,
    animImageSpamMap = nil,
    animImageSpamTicks = nil,
    animImageSpamToken = 0,
    animImageRetry = 0,
    randomSlotBlockerConn = nil,
    totalEmotesLoaded = 0,
    currentPage = 1,
    totalPages = 1,
    itemsPerPage = 8,
    emoteSearchTerm = "",
    animationSearchTerm = "",
    currentEmoteTrack = nil,
    currentCharacter = nil,
    emoteClickConnections = {},
    guiConnections = {},
    animationsData = {},
    originalAnimationsData = {},
    filteredAnimations = {},
    favoriteAnimations = {},
    favoriteAnimationsFileName = "FavoriteAnimations.json",
    emotesData = {},
    originalEmotesData = {},
    filteredEmotes = {},
    scannedEmotes = {},
    favoriteEmotes = {},
    favoriteFileName = "FavoriteEmotes.json",
    speedEmoteConfigFile = "SpeedEmoteConfig.json",
    favoriteEmoteSet = {},
    favoriteAnimationSet = {},
    emotePageCache = { version = nil, normal = {}, favorites = {} },
    animationPageCache = { version = nil, normal = {}, favorites = {} },
    suppressSearch = false,
    emoteMonitorToken = 0,
    animationMonitorToken = 0,
    imageUpdateToken = 0,
    defaultButtonImage = "rbxassetid://71408678974152",
    enabledButtonImage = "rbxassetid://106798555684020",
    favoriteIconId = "rbxassetid://97307461910825",
    notFavoriteIconId = "rbxassetid://124025954365505",
    toolEquipped = false,
    EmoteTheme = nil,
    isApplyingTheme = false,
    pendingThemeData = nil,
    targetImages = {},
    AnimationCachePath = "dark/AnimationCache.json",
    AnimationCache = {},
    AnimationListCachePath = "dark/AnimationListCache.json",
    EmoteListCachePath = "dark/EmoteListCache.json",
    CustomAnimationPath = "dark/CustomAnimations.json",
    CustomAnimations = {},
    currentCustomAnimationName = "Default",
    customAnimationEditorActive = false,
    customAnimationEditingKey = nil,
    customAnimationEditingName = nil,
    EmotePagePath = "dark/EmotePages.json",
    EmotePages = {},
    currentEmotePageName = "Default",
    EmoteDataCachePath = "dark/EmoteDataCache.json"
}

Config = {
    NotifyEnabled = true,
    OwnerAlertEnabled = true,
    SearchVisible = true,
    FavVisible = true,
    ModeVisible = true,
    FreezeVisible = true,
    SpeedVisible = true,
    NavVisible = true,
    EmoteSpeed = 1,
    EmoteSpeedEnabled = false,
    SelectedTheme = "Halloween",
    ThemePresetVersion = 0,
    EmotePage = 1,
    AnimationPage = 1,
    RandomEnabled = true,
    RandomMode = "All",
    AuthenticFirstPage = false,
    HUDPositions = {},
    HUDSizes = {},
    HUDProperties = {},
    CustomFrames = {},
    AutoReloadEnabled = false,
    LastPlayedAnimationData = nil,
    DiscordVisible = true,
    BugReportVisible = true,
}

HUD = {
    Connections = {},
    IsUnlocked = false,
    DefaultPositions = {},
    DefaultSizes = {},
    DefaultTexts = {},
    DefaultPlaceholders = {},
    Layouts = {},
    LayoutsRemoved = {},
    SelectionGui = nil,
    SelectedElement = nil,
    ResizeHandles = {},
    ResizeConnections = {},
    FriendlyNames = {
        ["Under.1left"] = "PrevPage",
        ["Under.9right"] = "NextPage",
        ["Under.4pages"] = "TotalPages",
        ["Under.3TextLabel"] = "Divider",
        ["Under.2Route-number"] = "CurrentPage",
        ["Top.Search"] = "Search",
        ["EmoteWalkButton"] = "Freeze",
        ["Favorite"] = "Favorite",
        ["SpeedEmote"] = "SpeedEmote",
        ["SpeedBox"] = "SpeedBox",
        ["Changepage"] = "ChangePage",
        ["Reload"] = "AutoReload",
        ["Top"] = "Top",
        ["Under"] = "Under"
    }
}

local DEFAULT_IDLE_ICON_ID = "rbxassetid://106798555684020"
local DEFAULT_IDLE_ICON_COLOR = Color3.fromRGB(0, 255, 150)

function DeepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for k, v in pairs(original) do
        if type(v) == "table" then
            v = DeepCopy(v)
        end
        copy[k] = v
    end
    return copy
end

function ColorToTable(color)
    return {color.R, color.G, color.B}
end

function TableToColor(tbl)
    if not tbl or type(tbl) ~= "table" or #tbl < 3 then return Color3.new(1,1,1) end
    return Color3.new(tbl[1], tbl[2], tbl[3])
end

function loadAnimationCache()
    if isfile and isfile(State.AnimationCachePath) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(State.AnimationCachePath))
        end)
        if success and type(decoded) == "table" then
            State.AnimationCache = decoded
        end
    end
end

function saveAnimationCache()
    if writefile then
        pcall(function()
            if not isfolder("dark") then makefolder("dark") end
            writefile(State.AnimationCachePath, HttpService:JSONEncode(State.AnimationCache))
        end)
    end
end

function resolveAnimationMappings(bundledItems)
    local mappings = {}
    for _, assetIds in pairs(bundledItems) do
        for _, assetId in pairs(assetIds) do
            local success, objects = pcall(function()
                return game:GetObjects("rbxassetid://" .. assetId)
            end)
            if success and objects then
                local function searchTree(parent, parentPath)
                    for _, child in pairs(parent:GetChildren()) do
                        if child:IsA("Animation") then
                            local animationPath = parentPath .. "." .. child.Name
                            local pathParts = animationPath:split(".")
                            local weightVals = {}
                            for _, wChild in ipairs(child:GetChildren()) do
                                if wChild:IsA("NumberValue") and wChild.Name == "Weight" then
                                    table.insert(weightVals, wChild.Value)
                                end
                            end
                            table.insert(mappings, {
                                category = pathParts[#pathParts - 1],
                                name = pathParts[#pathParts],
                                animationId = child.AnimationId,
                                weights = weightVals
                            })
                        elseif #child:GetChildren() > 0 then
                            searchTree(child, parentPath .. "." .. child.Name)
                        end
                    end
                end
                for _, obj in pairs(objects) do
                    searchTree(obj, obj.Name)
                    obj.Parent = workspace
                    task.delay(1, function()
                        if obj then obj:Destroy() end
                    end)
                end
            end
        end
    end
    return mappings
end

function buildCustomSetMappings(setName)
    if type(setName) == "string" then
        setName = setName:gsub("%s*%-.*$", "")
    end
    local set = State.CustomAnimations and State.CustomAnimations.Sets and State.CustomAnimations.Sets[setName]
    if not set then return {} end
    local mappings = {}
    for cat, anims in pairs(set) do
        if cat ~= "__meta" then
            for name, id in pairs(anims) do
                if tostring(id) ~= "0" then
                    table.insert(mappings, {category = cat, name = name, animationId = "rbxassetid://" .. id})
                end
            end
        end
    end
    return mappings
end



loadAnimationCache()


UI = {
    CustomFrames = {},
    Under = nil, 
    _1left = nil, 
    _9right = nil, 
    _4pages = nil, 
    _3TextLabel = nil, 
    _2Routenumber = nil, 
    Top = nil, 
    EmoteWalkButton = nil,
    Search = nil, 
    Favorite = nil, 
    FavoritesTab = nil,
    SpeedEmote = nil, 
    SpeedBox = nil, 
    Changepage = nil,
    Reload = nil,
    Background = nil
}

HUD = { 
    Connections = {},
    Strokes = {},
    ResizeHandles = {},
    ResizeConnections = {},
    UndoStack = {},
    SelectedElement = nil,
    Overlay = nil,
    IsUnlocked = false,
    ForceVisibleConn = nil,
    Layouts = {},
    LayoutsRemoved = {},
    FriendlyNames = {
        ["Under.1left"] = "Left Arrow",
        ["Under.9right"] = "Right Arrow",
        ["Under.4pages"] = "Total Pages",
        ["Under.3TextLabel"] = "Separator Label",
        ["Under.2Route-number"] = "Page Number Box",
        ["Top.Search"] = "Search/ID Box",
    },
    DefaultPositions = {
        Top = UDim2.new(0.127499998, 0, -0.109999999, 0),
        Under = UDim2.new(0.129999995, 0, 1, 0),
        EmoteWalkButton = UDim2.new(0.889999986, 0, -0.107500002, 0),
        Favorite = UDim2.new(0.0189999994, 0, -0.108000003, 0),
        SpeedEmote = UDim2.new(0.888999999, 0, 0, 0),
        SpeedBox = UDim2.new(0.0189999398, 0, -0.000499992399, 0),
        Changepage = UDim2.new(0.019, 0, 1.021, 0),
        Reload = UDim2.new(0.888999999, 0, 1.02100003, 0),
        ["Left Arrow"] = UDim2.new(0, 0, 0.028, 0),
        ["Right Arrow"] = UDim2.new(0.169, 0, 0.028, 0),
        ["Total Pages"] = UDim2.new(0.339, 0, 0.094, 0), 
        ["Separator Label"] = UDim2.new(0.498, 0, 0.028, 0),
        ["Page Number Box"] = UDim2.new(0.837, 0, 0.094, 0),
        ["Search/ID Box"] = UDim2.new(0.01, 0, 0.092, 0),
    },
    DefaultSizes = {
        Top = UDim2.new(0.737500012, 0, 0.0949999914, 0),
        Under = UDim2.new(0.737500012, 0, 0.132499993, 0),
        EmoteWalkButton = UDim2.new(0.0874999985, 0, 0.0874999985, 0),
        Favorite = UDim2.new(0.0874999985, 0, 0.0874999985, 0),
        SpeedEmote = UDim2.new(0.0874999985, 0, 0.0874999985, 0),
        SpeedBox = UDim2.new(0.0874999985, 0, 0.0874999985, 0),
        Changepage = UDim2.new(0.087, 0, 0.087, 0),
        Reload = UDim2.new(0.0869999975, 0, 0.0869999975, 0),
        ["Left Arrow"] = UDim2.new(0.169491529, 0, 0.94339627, 0),
        ["Right Arrow"] = UDim2.new(0.169491529, 0, 0.94339627, 0),
        ["Total Pages"] = UDim2.new(0.159322038, 0, 0.811320841, 0),
        ["Separator Label"] = UDim2.new(0.338983059, 0, 0.94339627, 0),
        ["Page Number Box"] = UDim2.new(0.159322038, 0, 0.811320841, 0),
        ["Search/ID Box"] = UDim2.new(0.864406765, 0, 0.81578958, 0),
    },
    DefaultTexts = {
        ["Left Arrow"] = "",
        ["Right Arrow"] = "",
        ["Total Pages"] = "1",
        ["Separator Label"] = " ------ ",
        ["Page Number Box"] = "1",
        ["Search/ID Box"] = "",
        ["SpeedBox"] = "1",
    },
    DefaultPlaceholders = {
        ["Search/ID Box"] = "Search/ID",
    }
}

function getAllHUDObjects()
    local elems = {}
    if UI.Top then elems["Top"] = UI.Top end
    if UI.Under then elems["Under"] = UI.Under end
    if UI.EmoteWalkButton then elems["EmoteWalkButton"] = UI.EmoteWalkButton end
    if UI.Favorite then elems["Favorite"] = UI.Favorite end
    if UI.SpeedEmote then elems["SpeedEmote"] = UI.SpeedEmote end
    if UI.SpeedBox then elems["SpeedBox"] = UI.SpeedBox end
    if UI.Changepage then elems["Changepage"] = UI.Changepage end
    if UI.Reload then elems["Reload"] = UI.Reload end
    if UI.CustomFrames then
        for n, f in pairs(UI.CustomFrames) do
            elems[n] = f
        end
    end

    if UI.Top then
        for _, child in pairs(UI.Top:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UICorner") then
                local internalName = "Top." .. child.Name
                elems[HUD.FriendlyNames[internalName] or internalName] = child
            end
        end
    end
    if UI.Under then
        for _, child in pairs(UI.Under:GetChildren()) do
            if child:IsA("GuiObject") and not child:IsA("UIListLayout") and not child:IsA("UICorner") then
                local internalName = "Under." .. child.Name
                elems[HUD.FriendlyNames[internalName] or internalName] = child
            end
        end
    end
    return elems
end

function getMovableElements()
    local all = getAllHUDObjects()
    local movable = {}
    
    for name, el in pairs(all) do
        local isChild = false
        for _, friendly in pairs(HUD.FriendlyNames) do 
            if name == friendly then isChild = true; break end 
        end
        
        if not isChild or HUD.IsUnlocked then
            movable[name] = el
        end
    end
    return movable
end

function ColorToTable(c) return {math.round(c.R*255), math.round(c.G*255), math.round(c.B*255)} end
function TableToColor(t)
    if type(t) ~= "table" then
        return Color3.fromRGB(255, 255, 255)
    end
    local r = tonumber(t[1]) or 255
    local g = tonumber(t[2]) or 255
    local b = tonumber(t[3]) or 255
    return Color3.fromRGB(r, g, b)
end

function isThemeDefaultRGB(r, g, b)
    return r == 28 and g == 30 and b == 32
end

AnimationSystem = {
    Cache = {},
    currentThemeName = "Default"
}   

AnimationSystem.LooksLikeGif = function(url)
    if not url then return false end
    url = string.lower(tostring(url))
    return url:find(".gif") or url:find("gif") or url:find("format=gif") or url:find("image/gif")
end

AnimationSystem.NormalizeUrl = function(url)
    if not url or url == "" then return url end
    local targetUrl = tostring(url)
    
    targetUrl = targetUrl:gsub("%?raw=true", "")
    
    if targetUrl:find("github%.com/") and not targetUrl:find("raw.githubusercontent%.com") then
        targetUrl = targetUrl:gsub("github%.com/", "raw.githubusercontent.com/")
        targetUrl = targetUrl:gsub("/blob/", "/")
        targetUrl = targetUrl:gsub("/raw/", "/")
    end
    
    if targetUrl:find(" ") and not targetUrl:find("%%20") then
        targetUrl = targetUrl:gsub(" ", "%%20")
    end
    
    if not targetUrl:find("://") then
        local id = targetUrl:match("id=(%d+)") or targetUrl:match("^(%d+)$")
        if id then return "rbxassetid://" .. id end
    end
    return targetUrl
end

AnimationSystem.ParseGifInfo = function(bytes)
    if not bytes or #bytes < 13 then return nil end
    if bytes:sub(1, 3) ~= "GIF" then return nil end
    local function u16le(pos)
        local b1 = bytes:byte(pos) or 0
        local b2 = bytes:byte(pos + 1) or 0
        return b1 + b2 * 256
    end
    local width = u16le(7)
    local height = u16le(9)
    local packed = bytes:byte(11) or 0
    local gctFlag = bit32.band(packed, 0x80) ~= 0
    local gctSize = bit32.band(packed, 0x07)
    local offset = 13
    if gctFlag then
        offset = offset + (3 * (2 ^ (gctSize + 1)))
    end

    local frames = 0
    local delays = {}
    local pendingDelay = nil

    local function skipSubBlocks(pos)
        while pos <= #bytes do
            local size = bytes:byte(pos) or 0
            pos = pos + 1
            if size == 0 then break end
            pos = pos + size
        end
        return pos
    end

    while offset <= #bytes do
        local b = bytes:byte(offset)
        if not b then break end
        if b == 0x3B then
            break
        elseif b == 0x21 then
            local label = bytes:byte(offset + 1) or 0
            if label == 0xF9 then
                local delay = u16le(offset + 4)
                pendingDelay = delay
                offset = offset + 8
            else
                offset = skipSubBlocks(offset + 2)
            end
        elseif b == 0x2C then
            frames = frames + 1
            if pendingDelay then
                table.insert(delays, pendingDelay)
                pendingDelay = nil
            end
            local packedImg = bytes:byte(offset + 9) or 0
            local lctFlag = bit32.band(packedImg, 0x80) ~= 0
            local lctSize = bit32.band(packedImg, 0x07)
            offset = offset + 10
            if lctFlag then
                offset = offset + (3 * (2 ^ (lctSize + 1)))
            end
            offset = offset + 1
            offset = skipSubBlocks(offset)
        else
            offset = offset + 1
        end
    end

    local totalDelay = 0
    for _, d in ipairs(delays) do totalDelay = totalDelay + d end
    local avgDelay = (#delays > 0) and (totalDelay / #delays) or 10

    return {
        width = width,
        height = height,
        frames = frames > 0 and frames or #delays,
        totalDelayCs = totalDelay,
        avgDelayCs = avgDelay
    }
end

AnimationSystem.ParsePngInfo = function(bytes)
    if not bytes or #bytes < 24 then return nil end
    if bytes:sub(1, 8) ~= "\137PNG\r\n\26\n" then return nil end
    local function u32be(pos)
        local b1 = bytes:byte(pos) or 0
        local b2 = bytes:byte(pos + 1) or 0
        local b3 = bytes:byte(pos + 2) or 0
        local b4 = bytes:byte(pos + 3) or 0
        return ((b1 * 256 + b2) * 256 + b3) * 256 + b4
    end
    local width = u32be(17)
    local height = u32be(21)
    if width <= 0 or height <= 0 then return nil end
    return { width = width, height = height }
end

AnimationSystem.StopGif = function()
    if State.currentWheelAnimToken then
        State.currentWheelAnimToken = State.currentWheelAnimToken + 1
    end
end

AnimationSystem.SetImageMode = function(img, custom)
    if not img then return end
    if custom then
        img.ScaleType = Enum.ScaleType.Stretch
        img.SliceCenter = Rect.new(0, 0, 0, 0)
        img.SliceScale = 1
    else
        img.ScaleType = Enum.ScaleType.Fit
    end
end

AnimationSystem.StartGif = function(img, data)
    AnimationSystem.StopGif()
    if not img or not data or not data.sprite then return end
    
    State.currentWheelAnimToken = (State.currentWheelAnimToken or 0) + 1
    local token = State.currentWheelAnimToken
    
    local frames = data.frames or 1
    local frameW = data.frameW or 0
    local frameH = data.frameH or 0
    local cols = data.cols or 1
    local rows = data.rows or 1
    local delay = data.delay or 0.1
    if delay <= 0 then delay = 0.1 end
    local sheetW = data.sheetW or (cols * frameW)
    local sheetH = data.sheetH or (rows * frameH)
    
    img.Image = data.sprite
    img.ImageRectSize = Vector2.new(frameW, frameH)
    img.ImageRectOffset = Vector2.new(0, 0)
    task.spawn(function()
        pcall(function() ContentProvider:PreloadAsync({img}) end)
    end)
    
    local current = 0
    local acc = 0
    local connection
    connection = RunService.Heartbeat:Connect(function(dt)
        if token ~= State.currentWheelAnimToken then
            connection:Disconnect()
            return
        end
        if not img or not img.Parent then
            connection:Disconnect()
            return
        end
        acc = acc + dt
        if acc < delay then return end
        while acc >= delay do
            acc = acc - delay
            current = (current + 1) % frames
        end
        local col = current % cols
        local row = math.floor(current / cols)
        local offsetX = math.min(col * frameW, math.max(0, sheetW - frameW))
        local offsetY = math.min(row * frameH, math.max(0, sheetH - frameH))
        img.ImageRectOffset = Vector2.new(offsetX, offsetY)
    end)
end

AnimationSystem.AreMetaEqual = function(a, b)
    if not a or not b then return a == b end
    return a.GifUrl == b.GifUrl and a.SheetUrl == b.SheetUrl and a.Enabled == b.Enabled
end

AnimationSystem.MakeKey = function(gif, sheet)
    return tostring(gif) .. "|" .. tostring(sheet)
end

function ApplyFreezeButtonVisual()
    if not UI.EmoteWalkButton then return end
    UI.EmoteWalkButton.Image = State.emotesWalkEnabled and State.enabledButtonImage or State.defaultButtonImage
end

AnimationSystem.GetIconColor = function(key)
    if themes and themes[AnimationSystem.currentThemeName] then
        local theme = themes[AnimationSystem.currentThemeName]
        if theme.IconColors and theme.IconColors[key] then
            return TableToColor(theme.IconColors[key])
        end
        return TableToColor(theme.ImageColor or {255, 255, 255})
    elseif State.EmoteTheme then
        local theme = State.EmoteTheme
        if theme.IconColors and theme.IconColors[key] then
            return TableToColor(theme.IconColors[key])
        end
        return theme.ImageColor or Color3.new(1, 1, 1)
    end
    return Color3.fromRGB(255, 255, 255)
end

AnimationSystem.ResetRandomSlot = function(frontFrame)
    if not frontFrame then return end
    local slot = frontFrame:FindFirstChild("1")
    if slot and slot:IsA("ImageLabel") then
        slot.ImageColor3 = Color3.fromRGB(255, 255, 255)
        slot.Image = ""
        local idValue = slot:FindFirstChild("AnimationID")
        if idValue then idValue:Destroy() end
    end
end

function SafeLoad(url, name)
    local content
    for i = 1, 3 do
        content = emotesDarkDownload(url)
        if content and content ~= "" then break end
        task.wait(0.5)
    end

    if not content or content == "" then
        emotesDarkNotify({
            Title = "Dark | Error",
            Content = "Failed to download " .. (name or "script") .. " after 3 attempts.",
            Duration = 5,
        })
        return nil
    end

    if name == "Settings Library" then
        local function replaceOnce(text, oldText, newText)
            local startIndex, endIndex = text:find(oldText, 1, true)
            if not startIndex then return nil end
            return text:sub(1, startIndex - 1) .. newText .. text:sub(endIndex + 1)
        end

        local frameStart = content:find('Name = "MainFrame"', 1, true)
        local frameEnd = frameStart and content:find("MainFrame.Visible = false", frameStart, true)
        local dragStart = frameEnd and content:find("local Dragging, DragStart, StartPos", frameEnd, true)
        local headerStart = dragStart and content:find("local Header = Lib:Create", dragStart, true)
        if frameStart and frameEnd and dragStart and headerStart and headerStart > dragStart and headerStart - dragStart < 4096 then
            local frameBlock = content:sub(frameStart, frameEnd - 1)
            frameBlock = replaceOnce(frameBlock, "AnchorPoint = Vector2.new(0.5, 0.5),", "AnchorPoint = Vector2.new(1, 0.5),")
            frameBlock = frameBlock and replaceOnce(frameBlock, "Position = UDim2.fromScale(0.5, 0.5),", "Position = UDim2.new(0.92, 0, 0.5, 0),")
            if frameBlock then
                content = content:sub(1, frameStart - 1) .. frameBlock .. content:sub(frameEnd, dragStart - 1) .. content:sub(headerStart)
            else
                warn("Dark | SafeLoad: Settings Library position pattern not found; leaving source unchanged.")
            end
        else
            warn("Dark | SafeLoad: Settings Library drag block not found; leaving source unchanged.")
        end
    end
    local loader = loadstring or load
    if type(loader) ~= "function" then
        warn("Dark | SafeLoad: executor does not expose loadstring/load")
        return nil
    end

    local func, err = loader(content)
    if not func then
        warn("Dark | SafeLoad: Failed to parse " .. (name or "script") .. ": " .. tostring(err))
        return nil
    end

    local ok, res = pcall(func)
    if not ok then
        warn("Dark | SafeLoad: Error executing " .. (name or "script") .. ": " .. tostring(res))
        return nil
    end
    return res
end

SafeLoad("https://raw.githubusercontent.com/7yd7/Menu-7yd7/refs/heads/Script/GUIS/Off-site/Notify.lua", "Notify System")

function getAssetCustom(filePath)
    if not filePath or filePath == "" then return nil end
    local customFn = getcustomasset or getsynasset
    if customFn then
        local ok, res = pcall(customFn, filePath)
        if ok and res and res ~= "" then
            return res
        end
    end
    return nil
end

function fetchBinary(url)
    if not url or url == "" then return nil end
    local targetUrl = AnimationSystem.NormalizeUrl(url)
    
    if request then
        local ok, res = pcall(function()
            return request({
                Url = targetUrl,
                Method = "GET",
                Headers = {
                    ["User-Agent"] = "Roblox/WinInet"
                }
            })
        end)
        if ok and res and (res.StatusCode == 200 or res.Status == 200) and res.Body and #res.Body > 0 then
            local low = res.Body:sub(1, 100):lower()
            if not (low:find("<!doctype") or low:find("<html") or low:find("<head")) then
                return res.Body
            end
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(targetUrl)
    end)
    if ok and body and #body > 0 then
        local low = body:sub(1, 100):lower()
        if not (low:find("<!doctype") or low:find("<html") or low:find("<head")) then
            return body
        end
    end
    return nil
end

function GetAsset(asset, preloadedBytes)
    if not asset or asset == "" then return "" end
    local assetStr = tostring(asset)
    
    _G.AssetCache = _G.AssetCache or {}
    if _G.AssetCache[assetStr] then return _G.AssetCache[assetStr] end

    if not assetStr:find("://") and tonumber(assetStr) then
        local id = "rbxassetid://" .. assetStr
        _G.AssetCache[assetStr] = id
        return id
    end
    
    if assetStr:find("rbxassetid://") or assetStr:find("rbxasset://") or assetStr:find("rbxthumb://") then
        return assetStr
    end
    
    if assetStr:find("http") then
        local targetUrl = AnimationSystem.NormalizeUrl(assetStr)

        local filename = targetUrl:match("([^/]+)$") or "asset.png"
        filename = filename:match("([^%?]+)") or filename
        
        filename = filename:gsub("[%c%*%?%\"%<%>%|]", "_")
        
        if filename:lower():find("%.gif$") then
            filename = filename:gsub("%.[gG][iI][fF]$", ".png")
        end
        if not filename:find("%.") then filename = filename .. ".png" end
        
        local path = "dark/Assets/" .. filename
        
        if isfile and isfile(path) then
            local res = getAssetCustom(path)
            if res and res ~= "" then
                _G.AssetCache[assetStr] = res
                return res
            end
        end

        if not isfolder("dark/Assets") then 
            pcall(function()
                if not isfolder("dark") then makefolder("dark") end
                makefolder("dark/Assets") 
            end)
        end
        
        local content = preloadedBytes or fetchBinary(targetUrl)
        if content and #content > 0 then
            pcall(function() writefile(path, content) end)
            
            for attempt = 1, 4 do
                local res = getAssetCustom(path)
                if res and res ~= "" then
                    _G.AssetCache[assetStr] = res
                    return res
                end
                task.wait(0.08)
            end
        end
    end
    
    return assetStr
end

function estimateRobloxResizedSize(origW, origH)
    if origW <= 0 or origH <= 0 then return origW, origH end
    local longest = math.max(origW, origH)
    local scale = 1
    if longest > 1024 then
        scale = 1024 / longest
    end
    return origW * scale, origH * scale
end

function getExactImageSize(asset)
    local AssetService = game:GetService("AssetService")
    local ok, editImage = pcall(function()
        return AssetService:CreateEditableImageAsync(asset)
    end)
    if ok and editImage then
        local w = editImage.Size.X
        local h = editImage.Size.Y
        editImage:Destroy()
        if w > 0 and h > 0 then
            return w, h
        end
    end
    return nil
end

DEFAULT_WHEEL_BG = "rbxasset://textures/ui/Emotes/Large/SegmentedCircle.png"
RANDOM_SLOT_ICON = "rbxassetid://109283577128136"
RANDOM_SLOT_COLOR = Color3.fromRGB(188, 188, 188)
local DEFAULT_IDLE_ICON_ID = "98513150727403"
local DEFAULT_IDLE_ICON_COLOR = Color3.fromRGB(188, 188, 188)
wheelImgState = setmetatable({}, { __mode = "k" })
checkEmotesMenuExists = nil
playEmote = nil
playRandomEmote = nil
handleSectorAction = nil
calculateTotalPages = nil
updatePageDisplay = nil
updateEmotes = nil
isInFavorites = nil
toggleFavorite = nil
toggleFavoriteAnimation = nil
refreshCustomAnimationState = nil
findCustomAnimationDataByName = nil
applyAnimation = nil

ConfigPath = "dark/EmoteSettings.json"

function updateHUDLayouts()
    if not Config then return end
    local function toggleLayout(parent, unlocked)
        if not parent then return end
        local key = parent.Name
        local l = parent:FindFirstChildOfClass("UIListLayout") or HUD.Layouts[key]
        
        if l then
            HUD.Layouts[key] = l
            
            local hasCustomP = false
            for _, child in pairs(parent:GetChildren()) do
                if child:IsA("GuiObject") then
                    local internalName = key .. "." .. child.Name
                    local friendly = HUD.FriendlyNames[internalName] or internalName
                    if Config.HUDPositions and Config.HUDPositions[friendly] then
                        hasCustomP = true
                        break
                    end
                end
            end

            if HUD.IsUnlocked then
                l.Parent = nil
            elseif hasCustomP or (HUD.LayoutsRemoved and HUD.LayoutsRemoved[key]) then
                l.Parent = nil 
            else
                l.Parent = parent
            end
        end
    end
    
    toggleLayout(UI.Top, HUD.IsUnlocked)
    toggleLayout(UI.Under, HUD.IsUnlocked)
end

function applySavedPositions() end 
enterHUDEditor, exitHUDEditor = nil, nil

function updateSpeedBoxVisibility()
    if not UI.SpeedBox then return end
    if State.hudEditorActive then
        UI.SpeedBox.Visible = Config.SpeedVisible
    else
        UI.SpeedBox.Visible = (Config.SpeedVisible and State.speedEmoteEnabled)
    end
end

function ApplyUIVisibility()
    pcall(function()
        if UI.Search and UI.Top then UI.Top.Visible = Config.SearchVisible end
        if UI.Favorite then UI.Favorite.Visible = Config.FavVisible end
        if UI.FavoritesTab then UI.FavoritesTab.Visible = Config.FavVisible end
        if UI.Changepage then UI.Changepage.Visible = Config.ModeVisible end
        if UI.EmoteWalkButton then UI.EmoteWalkButton.Visible = Config.FreezeVisible end
        if UI.SpeedEmote then UI.SpeedEmote.Visible = Config.SpeedVisible end
        updateSpeedBoxVisibility()
        if UI.Under then UI.Under.Visible = Config.NavVisible end
        if UI.Reload then 
            if State.hudEditorActive then
                UI.Reload.Visible = true
            else
                UI.Reload.Visible = (State.currentMode == "animation" and Config.NavVisible) 
            end
        end
    end)
end

function SaveConfig()
    if type(writefile) ~= "function" then return false end
    if type(isfolder) == "function" and type(makefolder) == "function" then
        local folderOk, folderExists = pcall(isfolder, "dark")
        if folderOk and not folderExists then pcall(makefolder, "dark") end
    end
    return pcall(function()
        writefile(ConfigPath, HttpService:JSONEncode(Config))
    end)
end

function LoadConfig()
    if type(isfile) == "function" and type(readfile) == "function" then
        local fileOk, fileExists = pcall(isfile, ConfigPath)
        if fileOk and fileExists then
            local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ConfigPath)) end)
            if success and type(decoded) == "table" then
                for k, v in pairs(decoded) do Config[k] = v end
            end
        end
    end
    local environment = emotesDarkExecutorEnv()
    environment.autoReloadEnabled = Config.AutoReloadEnabled or false
    environment.lastPlayedAnimation = Config.LastPlayedAnimationData
end
LoadConfig()
if Config.ThemePresetVersion ~= 1 then
    Config.ThemePresetVersion = 1
    SaveConfig()
end

rawNotify = emotesDarkReadField(emotesDarkExecutorEnv(), "Notify")
emotesDarkNotify = function(data)
    if Config.NotifyEnabled and type(rawNotify) == "function" then
        pcall(rawNotify, emotesDarkTranslateNotificationPayload(data))
    end
end
emotesDarkExecutorEnv().Notify = emotesDarkNotify

do
ownerAlertSeen = {}
ownerAlertOrder = 0

local OWNER_ALERT_COPY = {
        en = {
            title = "👑 %s just arrived!",
            joined = "Experience owner · @%s",
            already = "Owner is already here · @%s",
            game = "Game",
            players = "Players",
        },
        pt = {
            title = "👑 %s chegou ao jogo!",
            joined = "Dono do jogo · @%s",
            already = "O dono já está no servidor · @%s",
            game = "Jogo",
            players = "Jogadores",
        },
        es = {
            title = "👑 ¡%s llegó al juego!",
            joined = "Creador del juego · @%s",
            already = "El creador ya está en el servidor · @%s",
            game = "Juego",
            players = "Jugadores",
        },
    }

    local function getOwnerAlertText(displayName, username, alreadyPresent, playerCount, maxPlayers)
        local language = detectUpdateInfoLanguage()
        local copy = OWNER_ALERT_COPY[language] or OWNER_ALERT_COPY.en
        local ownerLine = string.format(alreadyPresent and copy.already or copy.joined, username)
        local experienceName = tostring(game.Name or "")
        if experienceName == "" then experienceName = copy.game end
        local detailsLine = string.format("%s: %s · %s: %d/%d", copy.game, experienceName, copy.players, playerCount, maxPlayers)
        return string.format(copy.title, displayName), ownerLine .. "\n" .. detailsLine
    end

    function getOwnerAlertPalette()
    local theme = State.EmoteTheme
    return {
        background = (theme and theme.Background) or Color3.fromRGB(28, 30, 32),
        accent = (theme and theme.Accent) or Color3.fromRGB(0, 255, 150),
        text = (theme and theme.ImageColor) or Color3.fromRGB(255, 255, 255),
    }
end

function showThemedOwnerAlert(ownerUserId, titleText, contentText)
        local palette = getOwnerAlertPalette()
        local alertGui = CoreGui:FindFirstChild("EmotesDarkOwnerAlerts")
        if not alertGui then
            alertGui = Instance.new("ScreenGui")
            alertGui.Name = "EmotesDarkOwnerAlerts"
            alertGui.IgnoreGuiInset = true
            alertGui.ResetOnSpawn = false
            alertGui.DisplayOrder = 10001
            alertGui.Parent = CoreGui

            local stack = Instance.new("Frame")
            stack.Name = "Stack"
            stack.AnchorPoint = Vector2.new(1, 0)
            stack.Position = UDim2.new(1, -20, 0, 20)
            stack.Size = UDim2.fromOffset(360, 460)
            stack.BackgroundTransparency = 1
            stack.Parent = alertGui

            local layout = Instance.new("UIListLayout")
            layout.Padding = UDim.new(0, 8)
            layout.FillDirection = Enum.FillDirection.Vertical
            layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
            layout.SortOrder = Enum.SortOrder.LayoutOrder
            layout.Parent = stack
        end

        local stack = alertGui:FindFirstChild("Stack")
        if not stack then return end

        ownerAlertOrder = ownerAlertOrder + 1
        emotesDarkAttachAutoTranslationRoot(alertGui)

        local card = Instance.new("Frame")
        card.Name = "OwnerAlert_" .. tostring(ownerAlertOrder)
        card.LayoutOrder = ownerAlertOrder
        card.Size = UDim2.new(1, 0, 0, 104)
        card.BackgroundColor3 = palette.background
        card.BackgroundTransparency = 1
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = stack

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 14)
        corner.Parent = card

        local cardGradient = Instance.new("UIGradient")
        cardGradient.Color = ColorSequence.new(palette.background:Lerp(palette.accent, 0.10), palette.background)
        cardGradient.Rotation = 90
        cardGradient.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = palette.accent
        stroke.Thickness = 1.7
        stroke.Transparency = 1
        stroke.Parent = card

        local accentBar = Instance.new("Frame")
        accentBar.Name = "AccentBar"
        accentBar.Size = UDim2.new(0, 4, 1, -24)
        accentBar.Position = UDim2.fromOffset(8, 12)
        accentBar.BackgroundColor3 = palette.accent
        accentBar.BackgroundTransparency = 1
        accentBar.BorderSizePixel = 0
        accentBar.Parent = card

        local accentCorner = Instance.new("UICorner")
        accentCorner.CornerRadius = UDim.new(1, 0)
        accentCorner.Parent = accentBar

        local avatar = Instance.new("ImageLabel")
        avatar.Name = "OwnerAvatar"
        avatar.Position = UDim2.fromOffset(18, 24)
        avatar.Size = UDim2.fromOffset(48, 48)
        avatar.BackgroundColor3 = palette.background
        avatar.BackgroundTransparency = 0.08
        avatar.BorderSizePixel = 0
        avatar.ClipsDescendants = true
        avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. tostring(ownerUserId) .. "&w=100&h=100"
        avatar.ImageTransparency = 1
        avatar.ScaleType = Enum.ScaleType.Crop
        avatar.ZIndex = 2
        avatar.Parent = card

        local avatarCorner = Instance.new("UICorner")
        avatarCorner.CornerRadius = UDim.new(1, 0)
        avatarCorner.Parent = avatar

        local avatarStroke = Instance.new("UIStroke")
        avatarStroke.Color = palette.accent
        avatarStroke.Thickness = 1.4
        avatarStroke.Transparency = 1
        avatarStroke.Parent = avatar

        local icon = Instance.new("TextLabel")
        icon.Name = "CrownBadge"
        icon.BackgroundColor3 = palette.background
        icon.BackgroundTransparency = 1
        icon.Position = UDim2.fromOffset(50, 52)
        icon.Size = UDim2.fromOffset(22, 22)
        icon.Font = Enum.Font.GothamBold
        icon.Text = "👑"
        icon.TextColor3 = palette.accent
        icon.TextSize = 13
        icon.TextTransparency = 1
        icon.ZIndex = 3
        icon.Parent = card

        local iconCorner = Instance.new("UICorner")
        iconCorner.CornerRadius = UDim.new(1, 0)
        iconCorner.Parent = icon

        local iconStroke = Instance.new("UIStroke")
        iconStroke.Color = palette.accent
        iconStroke.Thickness = 1
        iconStroke.Transparency = 1
        iconStroke.Parent = icon

        local title = Instance.new("TextLabel")
        title.Name = "Title"
        title.BackgroundTransparency = 1
        title.Position = UDim2.fromOffset(78, 12)
        title.Size = UDim2.new(1, -92, 0, 24)
        title.Font = Enum.Font.GothamBold
        title.Text = titleText
        title.TextColor3 = palette.accent
        title.TextSize = 16
        title.TextTruncate = Enum.TextTruncate.AtEnd
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextTransparency = 1
        title.ZIndex = 2
        title.Parent = card

        local content = Instance.new("TextLabel")
        content.Name = "Content"
        content.BackgroundTransparency = 1
        content.Position = UDim2.fromOffset(78, 40)
        content.Size = UDim2.new(1, -92, 0, 54)
        content.Font = Enum.Font.GothamMedium
        content.Text = contentText
        content.TextColor3 = palette.text
        content.TextSize = 13
        content.TextWrapped = true
        content.TextTruncate = Enum.TextTruncate.AtEnd
        content.TextXAlignment = Enum.TextXAlignment.Left
        content.TextYAlignment = Enum.TextYAlignment.Top
        content.TextTransparency = 1
        content.ZIndex = 2
        content.Parent = card

        local fadeIn = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        TweenService:Create(card, fadeIn, { BackgroundTransparency = 0.08 }):Play()
        TweenService:Create(stroke, fadeIn, { Transparency = 0.28 }):Play()
        TweenService:Create(accentBar, fadeIn, { BackgroundTransparency = 0 }):Play()
        TweenService:Create(avatar, fadeIn, { ImageTransparency = 0 }):Play()
        TweenService:Create(avatarStroke, fadeIn, { Transparency = 0.18 }):Play()
        TweenService:Create(icon, fadeIn, { TextTransparency = 0, BackgroundTransparency = 0.05 }):Play()
        TweenService:Create(iconStroke, fadeIn, { Transparency = 0.25 }):Play()
        TweenService:Create(title, fadeIn, { TextTransparency = 0 }):Play()
        TweenService:Create(content, fadeIn, { TextTransparency = 0.06 }):Play()

        task.delay(OWNER_ALERT_DURATION, function()
            if not card.Parent then return end
            local fadeOut = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            TweenService:Create(card, fadeOut, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(stroke, fadeOut, { Transparency = 1 }):Play()
            TweenService:Create(accentBar, fadeOut, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(avatar, fadeOut, { ImageTransparency = 1 }):Play()
            TweenService:Create(avatarStroke, fadeOut, { Transparency = 1 }):Play()
            TweenService:Create(icon, fadeOut, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
            TweenService:Create(iconStroke, fadeOut, { Transparency = 1 }):Play()
            TweenService:Create(title, fadeOut, { TextTransparency = 1 }):Play()
            TweenService:Create(content, fadeOut, { TextTransparency = 1 }):Play()
            task.wait(0.24)
            if card then card:Destroy() end
        end)
    end



    function getExperienceOwnerUserId()
    local creatorType = game.CreatorType
    if creatorType == Enum.CreatorType.User then
        return tonumber(game.CreatorId)
    end

    if creatorType == Enum.CreatorType.Group then
        local ok, groupInfo = pcall(function()
            return game:GetService("GroupService"):GetGroupInfoAsync(game.CreatorId)
        end)
        if ok and groupInfo and groupInfo.Owner then
            return tonumber(groupInfo.Owner.Id)
        end
    end

    return nil
end

function isKnownOwnerPlayer(player)
    if not player then return false end
    if OWNER_USER_IDS[player.UserId] then return true end

    local experienceOwnerId = getExperienceOwnerUserId()
    return experienceOwnerId ~= nil and player.UserId == experienceOwnerId
end

function isOwnerPlayer(player)
    if not player or player == Players.LocalPlayer then return false end
    return isKnownOwnerPlayer(player)
end

emotesDarkKickListening = true
emotesDarkKickedMessage = ""
emotesDarkPendingKickCommand = nil
emotesDarkHandledKickCommands = {}

function emotesDarkNormalizeKickName(value)
    value = tostring(value or ""):lower():gsub("^@", "")
    return value:gsub("[^%w]", "")
end

function emotesDarkKickTargetMatches(target)
    local localPlayer = Players.LocalPlayer
    if not localPlayer or type(target) ~= "string" then return false end
    local normalizedTarget = emotesDarkNormalizeKickName(target)
    local username = emotesDarkNormalizeKickName(localPlayer.Name)
    local displayName = emotesDarkNormalizeKickName(localPlayer.DisplayName)
    return normalizedTarget ~= "" and (username:find(normalizedTarget, 1, true) ~= nil or displayName:find(normalizedTarget, 1, true) ~= nil)
end

EMOTES_DARK_KICK_TRANSLATIONS = {
    en = {
        title = "Dark | Emote",
        message = "You were kicked from the server by the owner.",
        reason = "Reason: ",
        defaultReason = "Removed by the owner.",
    },
    pt = {
        title = "Dark | Emote",
        message = "Você foi expulso do servidor pelo owner.",
        reason = "Motivo: ",
        defaultReason = "Removido pelo owner.",
    },
    es = {
        title = "Dark | Emote",
        message = "Fuiste expulsado del servidor por el owner.",
        reason = "Motivo: ",
        defaultReason = "Eliminado por el owner.",
    },
}

function emotesDarkKickSelf(reason)
    local localPlayer = Players.LocalPlayer
    if not localPlayer then return end

    local language = detectUpdateInfoLanguage()
    local translation = EMOTES_DARK_KICK_TRANSLATIONS[language] or EMOTES_DARK_KICK_TRANSLATIONS.en
    local kickReason = reason ~= "" and reason or translation.defaultReason
    local kickMessage = translation.title .. "\n" .. translation.message .. "\n" .. translation.reason .. kickReason
    pcall(function()
        localPlayer:Kick(kickMessage)
    end)
end

function emotesDarkFindRoot(player)
    local character = player and player.Character
    return character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso"))
end

function emotesDarkPullSelf(owner)
    local localPlayer = Players.LocalPlayer
    if not localPlayer or not owner then return end

    task.spawn(function()
        for _ = 1, 12 do
            local targetRoot = emotesDarkFindRoot(localPlayer)
            local ownerRoot = emotesDarkFindRoot(owner)
            if targetRoot and ownerRoot then
                pcall(function()
                    targetRoot.CFrame = ownerRoot.CFrame * CFrame.new(0, 0, -3)
                    targetRoot.AssemblyLinearVelocity = Vector3.zero
                    targetRoot.AssemblyAngularVelocity = Vector3.zero
                end)
                return
            end
            task.wait(0.1)
        end
    end)
end

function emotesDarkHandleKickCommand(sender, message)
    if not emotesDarkKickListening or State.scriptKicked or not sender or type(message) ~= "string" then return end
    if not isKnownOwnerPlayer(sender) then return end

    local command, arguments = message:match("^%s*/(%S+)%s*(.-)%s*$")
    command = command and command:lower() or ""
    if command ~= "kick" and command ~= "puxar" then return end

    local target, reason = arguments:match("^(%S+)%s*(.-)%s*$")
    if not target then return end

    if sender == Players.LocalPlayer then
        emotesDarkPendingKickCommand = {
            action = command,
            nonce = tostring(os.time()) .. string.format("%04d", math.random(1000, 9999)),
            senderUserId = sender.UserId,
            target = target,
            reason = reason or "",
            expiresAt = os.time() + 15,
        }
    end

    if command == "kick" and emotesDarkKickTargetMatches(target) then
        emotesDarkKickSelf(reason or "")
    elseif command == "puxar" and emotesDarkKickTargetMatches(target) then
        emotesDarkPullSelf(sender)
    end
end

function emotesDarkBindKickChat(player)
    if not player then return end
    pcall(function()
        player.Chatted:Connect(function(message)
            emotesDarkHandleKickCommand(player, message)
        end)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    emotesDarkBindKickChat(player)
end
Players.PlayerAdded:Connect(emotesDarkBindKickChat)

-- Registered slash commands are intercepted by TextChatService before SendingMessage/MessageReceived.
-- Bind existing game aliases when available; otherwise register client-local aliases so the owner can publish them through the bridge.
pcall(function()
    local textChatService = game:GetService("TextChatService")
    local commandDefinitions = {
        { alias = "/kick", name = "EmotesDarkKickCommand" },
        { alias = "/puxar", name = "EmotesDarkPullCommand" },
    }
    local boundCommands = {}

    local function bindOwnerCommand(command)
        if boundCommands[command] then return end
        boundCommands[command] = true
        command.Triggered:Connect(function(originTextSource, unfilteredText)
            local userId = originTextSource and originTextSource.UserId
            local sender = userId and Players:GetPlayerByUserId(userId)
            if sender then
                emotesDarkHandleKickCommand(sender, unfilteredText)
            end
        end)
    end

    for _, definition in ipairs(commandDefinitions) do
        local command
        for _, candidate in ipairs(textChatService:GetDescendants()) do
            if candidate:IsA("TextChatCommand") then
                local primaryAlias = tostring(candidate.PrimaryAlias or ""):lower()
                local secondaryAlias = tostring(candidate.SecondaryAlias or ""):lower()
                if primaryAlias == definition.alias or secondaryAlias == definition.alias then
                    command = candidate
                    break
                end
            end
        end

        if not command then
            command = Instance.new("TextChatCommand")
            command.Name = definition.name
            command.PrimaryAlias = definition.alias
            command.Enabled = true
            command.Parent = textChatService
        end
        bindOwnerCommand(command)
    end
end)

-- Capture the owner's outgoing slash commands before relying on chat delivery.
pcall(function()
    local textChatService = game:GetService("TextChatService")
    textChatService.SendingMessage:Connect(function(message)
        local localPlayer = Players.LocalPlayer
        if localPlayer then
            emotesDarkHandleKickCommand(localPlayer, message and message.Text or "")
        end
    end)
end)

pcall(function()
    local textChatService = game:GetService("TextChatService")
    textChatService.MessageReceived:Connect(function(message)
        local source = message and message.TextSource
        local sender = source and Players:GetPlayerByUserId(source.UserId)
        emotesDarkHandleKickCommand(sender, message and message.Text or "")
    end)
end)

function announceOwner(player, alreadyPresent)
        if not Config.OwnerAlertEnabled or not isOwnerPlayer(player) then return end
        if ownerAlertSeen[player.UserId] then return end
        ownerAlertSeen[player.UserId] = true

        local displayName = player.DisplayName ~= "" and player.DisplayName or player.Name
        local playerCount = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        local alertTitle, alertContent = getOwnerAlertText(displayName, player.Name, alreadyPresent, playerCount, maxPlayers)
        local ok = pcall(function()
            showThemedOwnerAlert(player.UserId, alertTitle, alertContent)
        end)
        if not alreadyPresent then
            pcall(playOwnerSound)
        end
        if not ok then
            local notify = emotesDarkExecutorEnv().Notify
            if type(notify) == "function" then
                notify({
                    Title = alertTitle,
                    Content = alertContent,
                    Duration = OWNER_ALERT_DURATION,
                })
            end
        end
    end

Players.PlayerAdded:Connect(function(player)
    task.defer(announceOwner, player, false)
end)

Players.PlayerRemoving:Connect(function(player)
    ownerAlertSeen[player.UserId] = nil
end)

for _, player in ipairs(Players:GetPlayers()) do
    task.defer(announceOwner, player, true)
end

-- Presença compartilhada: só jogadores que registraram esta execução recebem a nametag.
EMOTES_DARK_TAG_API_ENV_NAME = "EMOTES_DARK_PRESENCE_API"
EMOTES_DARK_TAG_DEFAULT_API = "https://emotes-bridge-sync.lovable.app/api"
EMOTES_DARK_TAG_LEGACY_APIS = {
    ["https://emotes-dark-presence-bridge--pega123.replit.app/api"] = true,
    ["https://imaginative-treacle-412930.netlify.app/api"] = true,
    ["https://dark-bridge-sync.base44.app/functions/api"] = true,
}
EMOTES_DARK_TAG_POLL_SECONDS = 0.5 -- sincronização rápida do kick e das tags
-- A Roblox BillboardGui deixa de renderizar fora desta distância e volta ao aproximar.
EMOTES_DARK_TAG_MAX_DISTANCE = 55
EMOTES_DARK_TAG_REFERENCE_DISTANCE = 20
EMOTES_DARK_TAG_MIN_SCALE = EMOTES_DARK_TAG_REFERENCE_DISTANCE / EMOTES_DARK_TAG_MAX_DISTANCE
-- Keep the tag's name and icon inside the fixed-size billboard at close range.
EMOTES_DARK_TAG_MAX_SCALE = 1
emotesDarkTagUsers = {}
emotesDarkTags = {}
emotesDarkTagRunning = true
emotesDarkTagSessionId = ""
emotesDarkTagMissingApiWarned = false
emotesDarkCommandTokenWarned = false

do
    local ok, generated = pcall(function()
        return HttpService:GenerateGUID(false)
    end)
    emotesDarkTagSessionId = ok and tostring(generated) or (tostring(os.clock()) .. ":" .. tostring({}))
end

function emotesDarkTagEnvironment()
    local env = _G
    if type(getgenv) == "function" then
        local ok, result = pcall(getgenv)
        if ok and type(result) == "table" then env = result end
    end
    return env
end

function emotesDarkTagApiUrl()
    local env = emotesDarkTagEnvironment()
    local configured = env and env[EMOTES_DARK_TAG_API_ENV_NAME]
    if type(configured) == "string" and configured:gsub("%s+", "") ~= "" then
        local normalized = configured:gsub("%s+", ""):gsub("/+$", "")
        if EMOTES_DARK_TAG_LEGACY_APIS[normalized] then
            return EMOTES_DARK_TAG_DEFAULT_API
        end
        return normalized
    end
    return EMOTES_DARK_TAG_DEFAULT_API
end

function emotesDarkTagDecode(response)
    local body = response and (response.Body or response.body)
    if type(body) ~= "string" or body == "" then return nil end
    local ok, decoded = pcall(function() return HttpService:JSONDecode(body) end)
    return ok and decoded or nil
end

function emotesDarkTagRequest(method, path, body)
    local httpClient = emotesDarkGetRequest()
    if type(httpClient) ~= "function" then return nil end
    local baseUrl = emotesDarkTagApiUrl()
    if not baseUrl then
        if not emotesDarkTagMissingApiWarned then
            emotesDarkTagMissingApiWarned = true
            pcall(warn, "[EmotesDark] Configure getgenv().EMOTES_DARK_PRESENCE_API with your bridge API URL.")
        end
        return nil
    end

    local requestData = {
        Url = baseUrl .. path,
        Method = method,
        Headers = { ["Content-Type"] = "application/json", ["Accept"] = "application/json" },
    }
    if type(body) == "table" and body.command then
        local env = emotesDarkTagEnvironment()
        local token = env and env.EMOTES_DARK_COMMAND_TOKEN
        if type(token) == "string" and #token >= 32 then
            requestData.Headers["X-Emotes-Dark-Command-Token"] = token
        end
    end
    if body ~= nil then requestData.Body = HttpService:JSONEncode(body) end

    local ok, response = pcall(httpClient, requestData)
    if not ok or not response then return nil end
    local statusCode = tonumber(response.StatusCode or response.Status or response.status_code or response.statusCode)
    if statusCode and (statusCode < 200 or statusCode >= 300) then return nil end
    return emotesDarkTagDecode(response) or {}
end

function emotesDarkDecodeKickField(value)
    value = tostring(value or ""):gsub("%+", " ")
    return value:gsub("%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
end

function emotesDarkTagBuildCommand()
    local localPlayer = Players.LocalPlayer
    local command = emotesDarkPendingKickCommand
    if command and command.expiresAt and command.expiresAt <= os.time() then emotesDarkPendingKickCommand = nil; command = nil end
    if not localPlayer or not command or not isKnownOwnerPlayer(localPlayer) then return nil end
    local target = emotesDarkNormalizeKickName(command.target):sub(1, 20)
    if target == "" then return nil end
    local reason = HttpService:UrlEncode(tostring(command.reason or "")):gsub("_", "%%5F")
    if #reason > 28 then reason = reason:sub(1, 28):gsub("%%[%x]?$", "") end
    return { action=command.action, nonce=tostring(command.nonce or ""), senderUserId=localPlayer.UserId, target=target, reason=reason }
end

function emotesDarkTagBuildCommandSessionId(command)
    if type(command) ~= "table" then return emotesDarkTagSessionId end

    local action = tostring(command.action or "")
    local nonce = tostring(command.nonce or "")
    local senderUserId = tostring(command.senderUserId or "")
    local target = tostring(command.target or "")
    local reason = tostring(command.reason or "")
    if (action ~= "kick" and action ~= "puxar") or nonce == "" or senderUserId == "" or target == "" then
        return emotesDarkTagSessionId
    end

    -- Keep the stable session ID and append the full bridge command for APIs that read it from sessionId.
    return table.concat({emotesDarkTagSessionId, "|DK|", action, "|", nonce, "|", senderUserId, "|", target, "|", reason})
end

function emotesDarkTagClientInfo()
    local localPlayer = Players.LocalPlayer
    local command = emotesDarkTagBuildCommand()
    return { userId=localPlayer and localPlayer.UserId or 0, username=localPlayer and localPlayer.Name or "", displayName=localPlayer and localPlayer.DisplayName or "", gameId=tostring(game.GameId or 0), placeId=tostring(game.PlaceId or 0), jobId=tostring(game.JobId or ""), sessionId=emotesDarkTagBuildCommandSessionId(command), command=command }
end

function emotesDarkTagRemove(userId)
    local key = tostring(userId or "")
    local tag = emotesDarkTags[key]
    if tag then pcall(function() tag:Destroy() end) end
    emotesDarkTags[key] = nil
end

function emotesDarkTagAttach(player)
    if not player then return end
    local key = tostring(player.UserId)
    if Players.LocalPlayer and player == Players.LocalPlayer then
        emotesDarkTagRemove(key)
        return
    end
    if not emotesDarkTagUsers[key] then
        emotesDarkTagRemove(key)
        return
    end

    local character = player.Character
    local head = character and (character:FindFirstChild("Head") or character:FindFirstChild("UpperTorso") or character:FindFirstChild("HumanoidRootPart"))
    if not head then return end

    local existing = emotesDarkTags[key]
    if existing and existing.Parent == head then return end
    emotesDarkTagRemove(key)

    local isOwner = isKnownOwnerPlayer(player)
    local tag = Instance.new("BillboardGui")
    tag.Name = isOwner and "EmotesDarkCreatorTag" or "EmotesDarkScriptTag"
    tag.Adornee = head
    tag.AlwaysOnTop = true
    tag.MaxDistance = EMOTES_DARK_TAG_MAX_DISTANCE
    tag.Size = UDim2.fromOffset(250, 58)
    tag.StudsOffset = Vector3.new(0, 3.25, 0)
    tag.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    tag.Parent = head

    local tagContentScale
    if isOwner then
        local creatorTag = Instance.new("Frame")
        creatorTag.Name = "CreatorTag"
        creatorTag.AnchorPoint = Vector2.new(0.5, 0.5)
        creatorTag.Position = UDim2.fromScale(0.5, 0.5)
        creatorTag.Size = UDim2.fromScale(1, 1)
        creatorTag.BackgroundTransparency = 1
        creatorTag.Parent = tag

        local creatorScale = Instance.new("UIScale")
        creatorScale.Scale = 1
        creatorScale.Parent = creatorTag
        tagContentScale = creatorScale

        local nameRow = Instance.new("Frame")
        nameRow.Name = "NameRow"
        nameRow.Size = UDim2.new(1, 0, 0, 34)
        nameRow.Position = UDim2.fromOffset(0, 0)
        nameRow.BackgroundTransparency = 1
        nameRow.Parent = creatorTag

        local nameLayout = Instance.new("UIListLayout")
        nameLayout.FillDirection = Enum.FillDirection.Horizontal
        nameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        nameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        nameLayout.Padding = UDim.new(0, 4)
        nameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        nameLayout.Parent = nameRow

        local nick = Instance.new("TextLabel")
        nick.Name = "CreatorNick"
        nick.BackgroundTransparency = 1
        nick.Position = UDim2.fromOffset(0, 0)
        nick.Size = UDim2.new(0, 0, 0, 34)
        nick.LayoutOrder = 1
        nick.AutomaticSize = Enum.AutomaticSize.X
        nick.Font = Enum.Font.GothamBlack
        nick.Text = player.Name
        nick.TextColor3 = Color3.fromRGB(255, 255, 255)
        nick.TextSize = 18
        nick.TextXAlignment = Enum.TextXAlignment.Center
        nick.TextYAlignment = Enum.TextYAlignment.Center
        nick.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        nick.TextStrokeTransparency = 0.05
        nick.TextTruncate = Enum.TextTruncate.AtEnd
        local nickSizeConstraint = Instance.new("UISizeConstraint")
        nickSizeConstraint.MaxSize = Vector2.new(190, 34)
        nickSizeConstraint.Parent = nick
        nick.Parent = nameRow

        local nickGradient = Instance.new("UIGradient")
        nickGradient.Name = "RGBGradient"
        nickGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 45, 95)),
            ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 220, 45)),
            ColorSequenceKeypoint.new(0.4, Color3.fromRGB(70, 255, 125)),
            ColorSequenceKeypoint.new(0.6, Color3.fromRGB(45, 220, 255)),
            ColorSequenceKeypoint.new(0.8, Color3.fromRGB(115, 80, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 45, 220)),
        })
        nickGradient.Rotation = 0
        nickGradient.Parent = nick

        local ownerIcon = Instance.new("ImageLabel")
        ownerIcon.Name = "OwnerIcon"
        ownerIcon.BackgroundTransparency = 1
        ownerIcon.Size = UDim2.fromOffset(30, 30)
        ownerIcon.LayoutOrder = 2
        ownerIcon.Image = "rbxassetid://11322089611"
        ownerIcon.ScaleType = Enum.ScaleType.Fit
        ownerIcon.Parent = nameRow

        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "CreatorSubtitle"
        subtitle.BackgroundTransparency = 1
        subtitle.Position = UDim2.fromOffset(0, 34)
        subtitle.Size = UDim2.new(1, 0, 0, 22)
        subtitle.Font = Enum.Font.GothamMedium
        subtitle.Text = "Creator Script"
        subtitle.TextColor3 = Color3.fromRGB(230, 230, 230)
        subtitle.TextSize = 12
        subtitle.TextXAlignment = Enum.TextXAlignment.Center
        subtitle.TextYAlignment = Enum.TextYAlignment.Center
        subtitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        subtitle.TextStrokeTransparency = 0.15
        subtitle.Parent = creatorTag

        task.spawn(function()
            while creatorTag.Parent do
                nickGradient.Rotation = (nickGradient.Rotation + 4) % 360
                task.wait(0.035)
            end
        end)
    else
        local darkTag = Instance.new("Frame")
        darkTag.Name = "DarkUserTag"
        darkTag.AnchorPoint = Vector2.new(0.5, 0.5)
        darkTag.Position = UDim2.fromScale(0.5, 0.5)
        darkTag.Size = UDim2.fromScale(1, 1)
        darkTag.BackgroundTransparency = 1
        darkTag.Parent = tag

        local darkScale = Instance.new("UIScale")
        darkScale.Scale = 1
        darkScale.Parent = darkTag
        tagContentScale = darkScale

        local darkNameRow = Instance.new("Frame")
        darkNameRow.Name = "DarkNameRow"
        darkNameRow.Size = UDim2.new(1, 0, 0, 34)
        darkNameRow.Position = UDim2.fromOffset(0, 0)
        darkNameRow.BackgroundTransparency = 1
        darkNameRow.Parent = darkTag

        local darkNameLayout = Instance.new("UIListLayout")
        darkNameLayout.FillDirection = Enum.FillDirection.Horizontal
        darkNameLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        darkNameLayout.VerticalAlignment = Enum.VerticalAlignment.Center
        darkNameLayout.Padding = UDim.new(0, 4)
        darkNameLayout.SortOrder = Enum.SortOrder.LayoutOrder
        darkNameLayout.Parent = darkNameRow

        local darkNick = Instance.new("TextLabel")
        darkNick.Name = "DarkUserNick"
        darkNick.BackgroundTransparency = 1
        darkNick.Position = UDim2.fromOffset(0, 0)
        darkNick.Size = UDim2.new(0, 0, 0, 34)
        darkNick.LayoutOrder = 1
        darkNick.AutomaticSize = Enum.AutomaticSize.X
        darkNick.Font = Enum.Font.GothamBlack
        darkNick.Text = player.Name
        darkNick.TextColor3 = Color3.fromRGB(255, 255, 255)
        darkNick.TextSize = 18
        darkNick.TextXAlignment = Enum.TextXAlignment.Center
        darkNick.TextYAlignment = Enum.TextYAlignment.Center
        darkNick.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        darkNick.TextStrokeTransparency = 0.05
        darkNick.TextTruncate = Enum.TextTruncate.AtEnd
        local darkNickSizeConstraint = Instance.new("UISizeConstraint")
        darkNickSizeConstraint.MaxSize = Vector2.new(190, 34)
        darkNickSizeConstraint.Parent = darkNick
        darkNick.Parent = darkNameRow

        local darkGradient = Instance.new("UIGradient")
        darkGradient.Name = "DarkGradient"
        darkGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 70, 80)),
            ColorSequenceKeypoint.new(0.25, Color3.fromRGB(180, 180, 195)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.75, Color3.fromRGB(115, 90, 180)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(35, 25, 55)),
        })
        darkGradient.Rotation = 0
        darkGradient.Parent = darkNick

        local darkIcon = Instance.new("ImageLabel")
        darkIcon.Name = "DarkIcon"
        darkIcon.BackgroundTransparency = 1
        darkIcon.Size = UDim2.fromOffset(30, 30)
        darkIcon.LayoutOrder = 2
        darkIcon.Image = "rbxassetid://81489458260315"
        darkIcon.ScaleType = Enum.ScaleType.Fit
        darkIcon.Parent = darkNameRow

        local darkSubtitle = Instance.new("TextLabel")
        darkSubtitle.Name = "DarkUserSubtitle"
        darkSubtitle.BackgroundTransparency = 1
        darkSubtitle.Position = UDim2.fromOffset(0, 34)
        darkSubtitle.Size = UDim2.new(1, 0, 0, 22)
        darkSubtitle.Font = Enum.Font.GothamMedium
        darkSubtitle.Text = "DARK USER"
        darkSubtitle.TextColor3 = Color3.fromRGB(220, 215, 240)
        darkSubtitle.TextSize = 12
        darkSubtitle.TextXAlignment = Enum.TextXAlignment.Center
        darkSubtitle.TextYAlignment = Enum.TextYAlignment.Center
        darkSubtitle.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        darkSubtitle.TextStrokeTransparency = 0.15
        darkSubtitle.Parent = darkTag

        task.spawn(function()
            while darkTag.Parent do
                darkGradient.Rotation = (darkGradient.Rotation + 4) % 360
                task.wait(0.035)
            end
        end)
    end
    emotesDarkTags[key] = tag

    task.spawn(function()
        while tag.Parent and tagContentScale and tagContentScale.Parent do
            local camera = workspace.CurrentCamera
            if camera then
                local distance = (camera.CFrame.Position - head.Position).Magnitude
                local scale = EMOTES_DARK_TAG_REFERENCE_DISTANCE / math.max(distance, 1)
                tagContentScale.Scale = math.clamp(
                    scale,
                    EMOTES_DARK_TAG_MIN_SCALE,
                    EMOTES_DARK_TAG_MAX_SCALE
                )
            end
            task.wait(0.05)
        end
    end)
end

function emotesDarkTagSync(activeClients)
    local nextUsers = {}
    for _, client in ipairs(activeClients or {}) do
        if type(client) == "table" and client.userId ~= nil then
            nextUsers[tostring(client.userId)] = client
        end
    end
    emotesDarkTagUsers = nextUsers

    for _, player in ipairs(Players:GetPlayers()) do
        local key = tostring(player.UserId)
        if emotesDarkTagUsers[key] then
            emotesDarkTagAttach(player)
        else
            emotesDarkTagRemove(key)
        end
    end
    for key in pairs(emotesDarkTags) do
        if not emotesDarkTagUsers[key] then emotesDarkTagRemove(key) end
    end
end

function emotesDarkTagWatchPlayer(player)
    if not player then return end
    player.CharacterAdded:Connect(function()
        task.defer(function() emotesDarkTagAttach(player) end)
    end)
end

Players.PlayerAdded:Connect(function(player)
    emotesDarkTagWatchPlayer(player)
    task.defer(function() emotesDarkTagAttach(player) end)
end)

Players.PlayerRemoving:Connect(function(player)
    emotesDarkTagRemove(player.UserId)
end)

for _, player in ipairs(Players:GetPlayers()) do
    emotesDarkTagWatchPlayer(player)
end

task.spawn(function()
    while emotesDarkTagRunning and Players.LocalPlayer do
        local info = emotesDarkTagClientInfo()
        local registration = emotesDarkTagRequest("POST", "/clients/register", info)
        if info.command and registration and registration.commandAccepted == false and not emotesDarkCommandTokenWarned then
            emotesDarkCommandTokenWarned = true
            emotesDarkNotify({ Title = "Dark | Commands", Content = "Configure EMOTES_DARK_COMMAND_TOKEN no bridge e no executor do owner para retransmitir comandos.", Duration = 10 })
        end
        local query = string.format(
            "/clients/active?gameId=%s&placeId=%s&jobId=%s",
            HttpService:UrlEncode(info.gameId),
            HttpService:UrlEncode(info.placeId),
            HttpService:UrlEncode(info.jobId)
        )
        local response = emotesDarkTagRequest("GET", query)
        if response and type(response.clients) == "table" then
            for _, client in ipairs(response.clients) do
                local command = type(client) == "table" and client.command or nil
                local action, nonce, senderUserId, encodedTarget, encodedReason
                if type(command) == "table" then
                    action, nonce = command.action, tostring(command.nonce or "")
                    senderUserId, encodedTarget, encodedReason = tostring(command.senderUserId or ""), tostring(command.target or ""), tostring(command.reason or "")
                else
                    local sessionId = type(client) == "table" and tostring(client.sessionId or "") or ""
                    local actionCode
                    _, actionCode, nonce, senderUserId, encodedTarget, encodedReason = sessionId:match("^(.-)_EDK_([KP])_(%d+)_(%d+)_([^_]*)_(.*)$")
                    if actionCode then action = actionCode == "K" and "kick" or "puxar"
                    else action, nonce, senderUserId, encodedTarget, encodedReason = sessionId:match("|DK|([^|]+)|([^|]+)|([^|]+)|([^|]*)|(.*)$") end
                end
                local sender = senderUserId and Players:GetPlayerByUserId(tonumber(senderUserId))
                if sender and isKnownOwnerPlayer(sender) and nonce and nonce ~= "" and not emotesDarkHandledKickCommands[nonce] then
                    emotesDarkHandledKickCommands[nonce] = true
                    local target = emotesDarkDecodeKickField(encodedTarget)
                    local reason = emotesDarkDecodeKickField(encodedReason)
                    if emotesDarkKickTargetMatches(target) then
                        if action == "kick" then emotesDarkKickSelf(reason)
                        elseif action == "puxar" then emotesDarkPullSelf(sender) end
                        break
                    end
                end
            end
            emotesDarkTagSync(response.clients)
        end
        task.wait(EMOTES_DARK_TAG_POLL_SECONDS)
    end
end)

end

SettingsLib = SafeLoad("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/Settings.lua", "Settings Library")

-- Mirror the selected palette into the external Settings library and its dialogs.
SettingsThemeOriginals = setmetatable({}, {__mode = "k"})
SettingsThemeApplied = setmetatable({}, {__mode = "k"})
SettingsThemeWatched = setmetatable({}, {__mode = "k"})
SettingsThemeRoots = setmetatable({}, {__mode = "k"})
SettingsThemeCurrentData = nil

function SettingsThemeTargetColor(object, property, originalColor, themeData)
    if not themeData then return nil end
    local objectName = string.lower(tostring(object.Name or ""))
    if (property == "BackgroundColor3" or property == "ImageColor3") and (objectName == "colorbtn" or objectName == "colorpreview" or objectName == "colorsquare" or objectName == "hue" or objectName == "saturation" or objectName == "preview") then return nil end
    local isDefault = themes and themeData == themes.Default
    local background = TableToColor(themeData.Background or {28, 30, 32})
    local accent = TableToColor(themeData.Accent or {0, 255, 150})
    local image = TableToColor(themeData.ImageColor or {255, 255, 255})
    local isHalloween = themes and themeData == themes.Halloween
    local surface = isHalloween and Color3.fromRGB(42, 26, 58) or background:Lerp(accent, 0.10)
    local input = background:Lerp(surface, 0.42)
    local inactive = background:Lerp(surface, 0.70)
    local dimText = isHalloween and Color3.fromRGB(205, 182, 220) or image:Lerp(background, 0.35)
    local brightAccent = accent:Lerp(image, 0.08)
    if property == "BackgroundColor3" and string.find(objectName, "musicicon", 1, true) == 1 and originalColor == Color3.new(1, 1, 1) then return isDefault and originalColor or image end
    if property == "BackgroundColor3" or property == "Color" then
        if originalColor == Color3.fromRGB(0, 0, 0) or originalColor == Color3.fromRGB(0, 3, 12) or originalColor == Color3.fromRGB(9, 11, 16) or originalColor == Color3.fromRGB(10, 12, 18) or originalColor == Color3.fromRGB(20, 10, 31) or originalColor == Color3.fromRGB(24, 25, 28) then return isDefault and originalColor or background end
        if originalColor == Color3.fromRGB(32, 34, 37) or originalColor == Color3.fromRGB(38, 38, 38) or originalColor == Color3.fromRGB(38, 45, 58) or originalColor == Color3.fromRGB(50, 66, 90) then return isDefault and originalColor or surface end
        if originalColor == Color3.fromRGB(25, 27, 30) or originalColor == Color3.fromRGB(35, 38, 41) or originalColor == Color3.fromRGB(37, 38, 45) or originalColor == Color3.fromRGB(24, 25, 31) then return isDefault and originalColor or input end
        if originalColor == Color3.fromRGB(55, 58, 62) or originalColor == Color3.fromRGB(55, 56, 65) then return isDefault and originalColor or inactive end
        if originalColor == Color3.fromRGB(0, 220, 130) then return isDefault and originalColor or brightAccent end
        if originalColor == Color3.fromRGB(0, 255, 150) or originalColor == Color3.fromRGB(85, 150, 255) or originalColor == Color3.fromRGB(255, 193, 7) or originalColor == Color3.fromRGB(112, 255, 188) or originalColor == Color3.fromRGB(125, 155, 205) then return isDefault and originalColor or accent end
    end
    if property == "TextColor3" or property == "PlaceholderColor3" then
        if originalColor == Color3.new(1, 1, 1) or originalColor == Color3.fromRGB(245, 245, 245) or originalColor == Color3.fromRGB(242, 242, 247) or originalColor == Color3.fromRGB(240, 240, 245) or originalColor == Color3.fromRGB(235, 235, 240) or originalColor == Color3.fromRGB(230, 234, 242) or originalColor == Color3.fromRGB(220, 220, 225) then return isDefault and originalColor or image end
        if originalColor == Color3.fromRGB(150, 150, 150) or originalColor == Color3.fromRGB(120, 120, 120) or originalColor == Color3.fromRGB(178, 196, 222) or originalColor == Color3.fromRGB(170, 171, 181) or originalColor == Color3.fromRGB(190, 191, 200) or originalColor == Color3.fromRGB(145, 146, 156) then return isDefault and originalColor or dimText end
        if originalColor == Color3.fromRGB(0, 255, 150) or originalColor == Color3.fromRGB(112, 255, 188) or originalColor == Color3.fromRGB(255, 193, 7) or originalColor == Color3.fromRGB(85, 150, 255) or originalColor == Color3.fromRGB(130, 225, 155) then return isDefault and originalColor or accent end
    end
    if property == "ImageColor3" or property == "ScrollBarImageColor3" then
        if property == "ImageColor3" and originalColor == Color3.new(1, 1, 1) then return isDefault and originalColor or image end
        if originalColor == Color3.fromRGB(0, 255, 150) or originalColor == Color3.fromRGB(85, 150, 255) or originalColor == Color3.fromRGB(125, 155, 205) then return isDefault and originalColor or accent end
        if originalColor == Color3.fromRGB(200, 200, 200) or originalColor == Color3.fromRGB(100, 115, 140) then return isDefault and originalColor or image:Lerp(background, 0.18) end
    end
    return nil
end

function SettingsThemeApplyObject(object)
    if not object or not SettingsThemeCurrentData then return end
    local originals = SettingsThemeOriginals[object]
    if not originals then return end
    local applied = SettingsThemeApplied[object]
    if not applied then applied = {}; SettingsThemeApplied[object] = applied end
    for property, originalColor in pairs(originals) do
        local okCurrent, currentColor = pcall(function() return object[property] end)
        if okCurrent and typeof(currentColor) == "Color3" and (applied[property] == nil or currentColor ~= applied[property]) then
            originals[property] = currentColor
            originalColor = currentColor
        end
        local targetColor = SettingsThemeTargetColor(object, property, originalColor, SettingsThemeCurrentData)
        if targetColor then
            local shouldSetColor = not okCurrent or currentColor ~= targetColor
            applied[property] = targetColor
            if shouldSetColor then
                local setSucceeded = pcall(function() object[property] = targetColor end)
                if not setSucceeded then applied[property] = nil end
            end
        else
            applied[property] = nil
        end
    end
end

function SettingsThemeWatchObject(object)
    if not object or SettingsThemeWatched[object] or (not object:IsA("GuiObject") and not object:IsA("UIStroke")) then return end
    SettingsThemeWatched[object] = true
    SettingsThemeOriginals[object] = {}
    local properties = {"BackgroundColor3", "TextColor3", "TextStrokeColor3", "PlaceholderColor3", "ImageColor3", "ScrollBarImageColor3", "Color"}
    for _, property in ipairs(properties) do
        local okValue, value = pcall(function() return object[property] end)
        if okValue and typeof(value) == "Color3" then SettingsThemeOriginals[object][property] = value end
        local okSignal, signal = pcall(function() return object:GetPropertyChangedSignal(property) end)
        if okSignal and signal then signal:Connect(function() SettingsThemeApplyObject(object) end) end
    end
end

function SettingsThemeRegisterRoot(root)
    if typeof(root) ~= "Instance" or SettingsThemeRoots[root] then return end
    SettingsThemeRoots[root] = true
    if root:IsA("GuiObject") or root:IsA("UIStroke") then
        SettingsThemeWatchObject(root)
        SettingsThemeApplyObject(root)
    end
    for _, object in ipairs(root:GetDescendants()) do
        SettingsThemeWatchObject(object)
        SettingsThemeApplyObject(object)
    end
    root.DescendantAdded:Connect(function(object)
        task.defer(function() SettingsThemeWatchObject(object); SettingsThemeApplyObject(object) end)
    end)
end

function SettingsThemeIsPopupRoot(root)
    return root and root:IsA("ScreenGui") and (root.Name == "EmotesDarkCredits" or root.Name == "EmotesDarkUpdateInfo")
end

function ApplySettingsLibraryPalette(themeData)
    if themeData then SettingsThemeCurrentData = themeData end
    if SettingsLib and SettingsLib.UI then SettingsThemeRegisterRoot(SettingsLib.UI) end
    for root in pairs(SettingsThemeRoots) do
        local okParent, hasParent = pcall(function() return root.Parent ~= nil end)
        if okParent and hasParent then
            if root:IsA("GuiObject") or root:IsA("UIStroke") then
                SettingsThemeWatchObject(root)
                SettingsThemeApplyObject(root)
            end
            for _, object in ipairs(root:GetDescendants()) do
                SettingsThemeWatchObject(object)
                SettingsThemeApplyObject(object)
            end
        end
    end
end

if SettingsLib and SettingsLib.UI then SettingsThemeRegisterRoot(SettingsLib.UI) end
if CoreGui then
    for _, root in ipairs(CoreGui:GetChildren()) do
        if SettingsThemeIsPopupRoot(root) then SettingsThemeRegisterRoot(root) end
    end
    CoreGui.ChildAdded:Connect(function(root)
        if SettingsThemeIsPopupRoot(root) then task.defer(function() SettingsThemeRegisterRoot(root) end) end
    end)
end
if type(SettingsLib) ~= "table" or type(SettingsLib.CreateTab) ~= "function" then
    emotesDarkNotify({ Title = "Dark | Error", Content = "Settings Library could not be loaded. Check the executor network permission.", Duration = 8 })
    return
end

if typeof(SettingsLib.UI) == "Instance" then
    emotesDarkAttachAutoTranslationRoot(SettingsLib.UI)
end

ToggleContainer = Instance.new("Frame")
ToggleContainer.Name = "open/Close"
ToggleContainer.Parent = SettingsLib.UI
ToggleContainer.BackgroundTransparency = 1
ToggleContainer.Size = UDim2.fromScale(1, 1)
ToggleContainer.ZIndex = 5000
ToggleContainer.Visible = false
ToggleContainer.Active = false
ToggleContainer.Selectable = false

ToggleBtn = Instance.new("ImageButton")
ToggleBtn.Name = "ToggleSettings"
ToggleBtn.Parent = ToggleContainer
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
ToggleBtn.BackgroundTransparency = 0.4
ToggleBtn.Position = UDim2.new(0, 10, 1, -52)
ToggleBtn.Size = UDim2.fromOffset(42, 42)
ToggleBtn.Image = "rbxassetid://79568054778195"


DiscordBtn = Instance.new("ImageButton")
DiscordBtn.Name = "DiscordButton"
DiscordBtn.Parent = ToggleContainer
DiscordBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
DiscordBtn.BackgroundTransparency = 0.4
DiscordBtn.Position = UDim2.new(0, 57, 1, -52)
DiscordBtn.Size = UDim2.fromOffset(42, 42)
DiscordBtn.Image = "rbxassetid://98681818461563"

BugBtn = Instance.new("ImageButton")
BugBtn.Name = "BugReportButton"
BugBtn.Parent = ToggleContainer
BugBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
BugBtn.BackgroundTransparency = 0.4
BugBtn.Position = UDim2.new(0, 104, 1, -52)
BugBtn.Size = UDim2.fromOffset(42, 42)
BugBtn.Image = "rbxassetid://7562374548"
BugBtn.ImageColor3 = Color3.fromRGB(255, 255, 255)
BugBtn.AutoButtonColor = true

MusicBtn = Instance.new("TextButton")
MusicBtn.Name = "MusicControlButton"
MusicBtn.Parent = ToggleContainer
MusicBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
MusicBtn.BackgroundTransparency = 0.4
MusicBtn.Position = UDim2.new(0, 10, 1, -99)
MusicBtn.Size = UDim2.fromOffset(42, 42)
MusicBtn.Text = ""
MusicBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MusicBtn.AutoButtonColor = true

MusicIconRoot = Instance.new("Frame")
MusicIconRoot.Name = "MusicIconRoot"
MusicIconRoot.AnchorPoint = Vector2.new(0.5, 0.5)
MusicIconRoot.Position = UDim2.fromScale(0.5, 0.5)
MusicIconRoot.Size = UDim2.fromOffset(30, 30)
MusicIconRoot.BackgroundTransparency = 1
MusicIconRoot.BorderSizePixel = 0
MusicIconRoot.ZIndex = MusicBtn.ZIndex + 1
MusicIconRoot.Parent = MusicBtn

for _, iconPartData in ipairs({
    {"MusicIconLeftStem", 3, 17, 9, 6, 0, false},
    {"MusicIconRightStem", 3, 15, 22, 2, 0, false},
    {"MusicIconBeam", 16, 4, 9, 3, -14, false},
    {"MusicIconLeftHead", 10, 7, 1, 19, -18, true},
    {"MusicIconRightHead", 10, 7, 14, 15, -18, true},
}) do
    MusicIconPart = Instance.new("Frame")
    MusicIconPart.Name = iconPartData[1]
    MusicIconPart.Size = UDim2.fromOffset(iconPartData[2], iconPartData[3])
    MusicIconPart.Position = UDim2.fromOffset(iconPartData[4], iconPartData[5])
    MusicIconPart.Rotation = iconPartData[6]
    MusicIconPart.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    MusicIconPart.BorderSizePixel = 0
    MusicIconPart.ZIndex = MusicIconRoot.ZIndex + 1
    MusicIconPart.Parent = MusicIconRoot
    if iconPartData[7] then
        MusicIconPartCorner = Instance.new("UICorner")
        MusicIconPartCorner.CornerRadius = UDim.new(1, 0)
        MusicIconPartCorner.Parent = MusicIconPart
    end
end


DiscordCorner = Instance.new("UICorner")
DiscordCorner.CornerRadius = UDim.new(0, 10)
DiscordCorner.Parent = DiscordBtn

BugCorner = Instance.new("UICorner")
BugCorner.CornerRadius = UDim.new(0, 10)
BugCorner.Parent = BugBtn

MusicCorner = Instance.new("UICorner")
MusicCorner.CornerRadius = UDim.new(0, 10)
MusicCorner.Parent = MusicBtn



ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleBtn

function getSettingsMainFrame()
    if SettingsLib and SettingsLib.UI then
        return SettingsLib.UI:FindFirstChild("MainFrame")
    end
    return nil
end

function applySettingsToggleStyle()
    local main = getSettingsMainFrame()
    local bgColor
    if main then
        bgColor = main.BackgroundColor3
    elseif State.EmoteTheme and State.EmoteTheme.Background then
        bgColor = State.EmoteTheme.Background
    end

    if bgColor then
        ToggleBtn.BackgroundColor3 = bgColor
        DiscordBtn.BackgroundColor3 = bgColor
        BugBtn.BackgroundColor3 = bgColor
        MusicBtn.BackgroundColor3 = bgColor
    end
end

if type(emotesDarkSetSettingsEmoteWheelLocked) == "function" then
    pcall(function() emotesDarkSetSettingsEmoteWheelLocked(false) end)
end
for _, connection in ipairs(emotesDarkSettingsBlockerWatchConnections or {}) do
    pcall(function() connection:Disconnect() end)
end
emotesDarkSettingsBlockerWatchConnections = {}
emotesDarkSettingsEmoteInteractionStates = nil
emotesDarkSetSettingsEmoteWheelLocked = nil

local settingsInputBlocker
local settingsBlockerActive = false
local settingsModalButtonStates = {}

local function setSettingsButtonModal(button)
    if not button or not button:IsA("GuiButton") then return end
    if settingsModalButtonStates[button] == nil then
        settingsModalButtonStates[button] = button.Modal
    end
    pcall(function() button.Modal = true end)
end

local function setSettingsButtonsModal(isModal)
    if isModal then
        if SettingsLib.UI then
            for _, object in ipairs(SettingsLib.UI:GetDescendants()) do setSettingsButtonModal(object) end
        end
        return
    end
    for button, originalModal in pairs(settingsModalButtonStates) do
        if button.Parent then pcall(function() button.Modal = originalModal end) end
    end
    settingsModalButtonStates = {}
end

local function ensureSettingsInputBlocker()
    if settingsInputBlocker and settingsInputBlocker.Parent and settingsInputBlocker.Parent.Name == "EmotesDarkSettingsBlockerLayer" then return end
    if settingsInputBlocker and settingsInputBlocker.Parent then settingsInputBlocker:Destroy() end
    local oldBlocker = SettingsLib.UI and SettingsLib.UI:FindFirstChild("EmotesDarkSettingsInputBlocker")
    if oldBlocker then oldBlocker:Destroy() end

    local blockerGui = CoreGui:FindFirstChild("EmotesDarkSettingsBlockerLayer")
    if not blockerGui or not blockerGui:IsA("ScreenGui") then
        blockerGui = Instance.new("ScreenGui")
        blockerGui.Name = "EmotesDarkSettingsBlockerLayer"
        blockerGui.IgnoreGuiInset = true
        blockerGui.ResetOnSpawn = false
        blockerGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        blockerGui.DisplayOrder = 0
        blockerGui.Enabled = false
        blockerGui.Parent = CoreGui
    end
    local existingBlocker = blockerGui:FindFirstChild("EmotesDarkSettingsInputBlocker")
    if existingBlocker then
        if existingBlocker:IsA("Frame") then
            settingsInputBlocker = existingBlocker
            return
        end
        existingBlocker:Destroy()
    end

    local blocker = Instance.new("Frame")
    blocker.Name = "EmotesDarkSettingsInputBlocker"
    blocker.Position = UDim2.fromScale(0, 0)
    blocker.Size = UDim2.fromScale(1, 1)
    blocker.BackgroundColor3 = Color3.new(0, 0, 0)
    blocker.BackgroundTransparency = 1
    blocker.BorderSizePixel = 0
    blocker.Active = true
    blocker.ZIndex = 1
    blocker.Visible = false
    blocker.Parent = blockerGui
    settingsInputBlocker = blocker
end

local function syncSettingsModalBlocker(main)
    ensureSettingsInputBlocker()
    local blockerGui = settingsInputBlocker.Parent
    if main and main.Visible then
        if not settingsBlockerActive then
            settingsBlockerActive = true
            setSettingsButtonsModal(true)
            if SettingsLib.UI and SettingsLib.UI:IsA("ScreenGui") then
                if SettingsLib.UI:GetAttribute("EmotesDarkSettingsOriginalDisplayOrder") == nil then
                    SettingsLib.UI:SetAttribute("EmotesDarkSettingsOriginalDisplayOrder", SettingsLib.UI.DisplayOrder)
                end

                local function updateDisplayOrders()
                    if not settingsBlockerActive then return end
                    local highestDisplayOrder = 0
                    for _, screen in ipairs(CoreGui:GetDescendants()) do
                        if screen:IsA("ScreenGui") and screen ~= SettingsLib.UI and screen ~= blockerGui then
                            highestDisplayOrder = math.max(highestDisplayOrder, screen.DisplayOrder)
                        end
                    end
                    local player = game:GetService("Players").LocalPlayer
                    local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
                    if playerGui then
                        for _, screen in ipairs(playerGui:GetDescendants()) do
                            if screen:IsA("ScreenGui") and screen ~= SettingsLib.UI and screen ~= blockerGui then
                                highestDisplayOrder = math.max(highestDisplayOrder, screen.DisplayOrder)
                            end
                        end
                    end
                    blockerGui.DisplayOrder = highestDisplayOrder + 1
                    SettingsLib.UI.DisplayOrder = highestDisplayOrder + 2
                end

                for _, connection in ipairs(emotesDarkSettingsBlockerWatchConnections) do
                    pcall(function() connection:Disconnect() end)
                end
                emotesDarkSettingsBlockerWatchConnections = {}
                updateDisplayOrders()

                local function watchRoot(root)
                    if not root then return end
                    local function watchScreen(screen)
                        if not screen:IsA("ScreenGui") or screen == SettingsLib.UI or screen == blockerGui then return end
                        table.insert(emotesDarkSettingsBlockerWatchConnections, screen:GetPropertyChangedSignal("DisplayOrder"):Connect(function()
                            if settingsBlockerActive then task.defer(updateDisplayOrders) end
                        end))
                    end
                    for _, screen in ipairs(root:GetDescendants()) do watchScreen(screen) end
                    table.insert(emotesDarkSettingsBlockerWatchConnections, root.DescendantAdded:Connect(function(object)
                        if not object:IsA("ScreenGui") then return end
                        watchScreen(object)
                        task.defer(updateDisplayOrders)
                    end))
                end

                watchRoot(CoreGui)
                local player = game:GetService("Players").LocalPlayer
                local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
                watchRoot(playerGui)
                table.insert(emotesDarkSettingsBlockerWatchConnections, SettingsLib.UI.DescendantAdded:Connect(function(object)
                    if settingsBlockerActive then setSettingsButtonModal(object) end
                end))
            end
        end
        blockerGui.Enabled = true
        settingsInputBlocker.Visible = true
    else
        settingsInputBlocker.Visible = false
        blockerGui.Enabled = false
        blockerGui.DisplayOrder = 0
        if settingsBlockerActive then
            settingsBlockerActive = false
            for _, connection in ipairs(emotesDarkSettingsBlockerWatchConnections) do
                pcall(function() connection:Disconnect() end)
            end
            emotesDarkSettingsBlockerWatchConnections = {}
            setSettingsButtonsModal(false)
            if SettingsLib.UI and SettingsLib.UI:IsA("ScreenGui") then
                local originalDisplayOrder = SettingsLib.UI:GetAttribute("EmotesDarkSettingsOriginalDisplayOrder")
                if type(originalDisplayOrder) == "number" then
                    SettingsLib.UI.DisplayOrder = originalDisplayOrder
                end
                SettingsLib.UI:SetAttribute("EmotesDarkSettingsOriginalDisplayOrder", nil)
            end
        end
    end
end

function syncToggleVisibility()
    local main = getSettingsMainFrame()
    if main then
        ToggleContainer.Visible = not main.Visible
    else
        ToggleContainer.Visible = true
    end
    syncSettingsModalBlocker(main)
end

function syncDiscordVisibility()
    DiscordBtn.Visible = Config.DiscordVisible
end

function syncBugReportVisibility()
    BugBtn.Visible = Config.BugReportVisible ~= false
end

bugReportWindow = nil
bugReportOverlay = nil
bugReportCooldownExpires = 0
suggestionCooldownExpires = 0
bugReportTimerToken = 0
bugReportSubmissionInProgress = false

function getBugReportEnvironment()
    local env = _G
    if type(getgenv) == "function" then
        local ok, result = pcall(getgenv)
        if ok and type(result) == "table" then
            env = result
        end
    end
    return env
end

function getBugReportWebhook(reportType)
    local env = getBugReportEnvironment()
    local isSuggestion = reportType == "suggestion"
    local envName = isSuggestion and SUGGESTION_WEBHOOK_ENV_NAME or BUG_REPORT_WEBHOOK_ENV_NAME
    local namedWebhook = env and env[envName]
    if type(namedWebhook) == "string" and namedWebhook ~= "" then
        return namedWebhook
    end

    if isSuggestion then
        if type(SUGGESTION_WEBHOOK_URL) == "string" and SUGGESTION_WEBHOOK_URL ~= "" then
            return SUGGESTION_WEBHOOK_URL
        end
        return ""
    end

    if type(BUG_REPORT_WEBHOOK_URL) == "string" and BUG_REPORT_WEBHOOK_URL ~= "" then
        return BUG_REPORT_WEBHOOK_URL
    end

    return ""
end

function getBugReportCooldownApi()
    local env = getBugReportEnvironment()
    local api = env and env[BUG_REPORT_COOLDOWN_API_ENV_NAME]
    if type(api) ~= "string" then return "" end
    return api:gsub("/+$", "")
end

function getBugReportHttpClient()
    return emotesDarkGetRequest()
end

function decodeBugReportApiResponse(response)
    if not response then return nil end
    local body = response.Body or response.body
    if type(body) ~= "string" or body == "" then return nil end
    local ok, decoded = pcall(function()
        return HttpService:JSONDecode(body)
    end)
    return ok and decoded or nil
end

bugReportGlobalStatusCheckedAt = 0

function queryGlobalBugReportCooldown()
    local api = getBugReportCooldownApi()
    if api == "" then return nil end

    local now = os.time()
    if now - bugReportGlobalStatusCheckedAt < 5 then
        return bugReportCooldownExpires
    end
    bugReportGlobalStatusCheckedAt = now

    local player = Players.LocalPlayer
    local httpClient = getBugReportHttpClient()
    if not player or type(httpClient) ~= "function" then return nil end

    local ok, response = pcall(function()
        return httpClient({
            Url = api .. "/bug-reports/status/" .. tostring(player.UserId),
            Method = "GET",
            Headers = { ["Content-Type"] = "application/json" },
        })
    end)
    if not ok then return nil end

    local decoded = decodeBugReportApiResponse(response)
    if type(decoded) ~= "table" or type(decoded.remainingSeconds) ~= "number" then return nil end
    bugReportCooldownExpires = decoded.remainingSeconds > 0 and now + decoded.remainingSeconds or 0
    return bugReportCooldownExpires
end

bugReportOwnerCache = nil

function isBugReportOwner()
    if bugReportOwnerCache ~= nil then
        return bugReportOwnerCache
    end

    local player = Players.LocalPlayer
    if not player then return false end
    if OWNER_USER_IDS[player.UserId] then
        bugReportOwnerCache = true
        return true
    end

    local experienceOwnerId = getExperienceOwnerUserId()
    bugReportOwnerCache = experienceOwnerId ~= nil and player.UserId == experienceOwnerId
    return bugReportOwnerCache
end

function getBugReportCooldown(reportType)
    local isSuggestion = reportType == "suggestion"
    if isBugReportOwner() then return 0 end

    if not isSuggestion then
        local globalCooldown = queryGlobalBugReportCooldown()
        if globalCooldown ~= nil then
            return globalCooldown
        end
    end

    local now = os.time()
    local cachedExpires = isSuggestion and suggestionCooldownExpires or bugReportCooldownExpires
    if cachedExpires > now then
        return cachedExpires
    end

    local player = Players.LocalPlayer
    if not player then return 0 end

    local cooldownPath = isSuggestion and SUGGESTION_COOLDOWN_PATH or BUG_REPORT_COOLDOWN_PATH
    local expires = 0
    if type(isfile) == "function" and type(readfile) == "function" and isfile(cooldownPath) then
        local ok, raw = pcall(readfile, cooldownPath)
        if ok and raw and raw ~= "" then
            local decodedOk, data = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if decodedOk and type(data) == "table" then
                expires = tonumber(data[tostring(player.UserId)]) or 0
            end
        end
    end

    if isSuggestion then
        suggestionCooldownExpires = expires > now and expires or 0
        return suggestionCooldownExpires
    end
    bugReportCooldownExpires = expires > now and expires or 0
    return bugReportCooldownExpires
end

function saveBugReportCooldown(expires, reportType)
    local isSuggestion = reportType == "suggestion"
    if isBugReportOwner() then
        if isSuggestion then
            suggestionCooldownExpires = 0
        else
            bugReportCooldownExpires = 0
        end
        return
    end

    if isSuggestion then
        suggestionCooldownExpires = expires
    else
        bugReportCooldownExpires = expires
    end

    local player = Players.LocalPlayer
    if not player or type(writefile) ~= "function" then return end

    local cooldownPath = isSuggestion and SUGGESTION_COOLDOWN_PATH or BUG_REPORT_COOLDOWN_PATH
    local data = {}
    if type(isfile) == "function" and type(readfile) == "function" and isfile(cooldownPath) then
        local ok, raw = pcall(readfile, cooldownPath)
        if ok and raw and raw ~= "" then
            local decodedOk, decoded = pcall(function()
                return HttpService:JSONDecode(raw)
            end)
            if decodedOk and type(decoded) == "table" then
                data = decoded
            end
        end
    end

    data[tostring(player.UserId)] = expires
    pcall(function()
        if type(isfolder) == "function" and type(makefolder) == "function" and not isfolder("dark") then
            makefolder("dark")
        end
        writefile(cooldownPath, HttpService:JSONEncode(data))
    end)
end

function formatBugCooldown(seconds)
    seconds = math.max(0, math.floor(seconds))
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60
    return string.format("%02dh %02dm %02ds", hours, minutes, remainingSeconds)
end

function getBugReportNotify()
    local env = getBugReportEnvironment()
    return env and env.Notify
end

function notifyBugReport(title, content)
    local notify = getBugReportNotify()
    if type(notify) == "function" then
        pcall(notify, { Title = title, Content = content, Duration = 5 })
    end
end

function reserveGlobalBugReportCooldown(reportType)
    if reportType == "suggestion" then return true end
    if isBugReportOwner() then return true end

    local api = getBugReportCooldownApi()
    if api == "" then return true end

    local player = Players.LocalPlayer
    local httpClient = getBugReportHttpClient()
    if not player or type(httpClient) ~= "function" then
        return false, emotesDarkBugText("globalConfig")
    end

    local ok, response = pcall(function()
        return httpClient({
            Url = api .. "/bug-reports/reserve",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode({ userId = player.UserId }),
        })
    end)
    if not ok then
        return false, emotesDarkBugText("globalUnavailable")
    end

    local decoded = decodeBugReportApiResponse(response)
    local statusCode = response and tonumber(response.StatusCode)
    if statusCode == 429 or (type(decoded) == "table" and decoded.allowed == false) then
        local remaining = type(decoded) == "table" and tonumber(decoded.remainingSeconds) or 0
        bugReportCooldownExpires = os.time() + math.max(0, remaining)
        bugReportGlobalStatusCheckedAt = os.time()
        return false, emotesDarkBugText("cooldown", formatBugCooldown(remaining))
    end

    if statusCode and statusCode >= 400 then
        return false, emotesDarkBugText("globalRejected")
    end
    if type(decoded) ~= "table" or decoded.allowed ~= true then
        return false, emotesDarkBugText("globalInvalid")
    end

    local remaining = tonumber(decoded.remainingSeconds) or BUG_REPORT_COOLDOWN_SECONDS
    bugReportCooldownExpires = os.time() + math.max(0, remaining)
    bugReportGlobalStatusCheckedAt = os.time()
    return true
end

function submitBugReport(description, reportType)
    local isSuggestion = reportType == "suggestion"
    if emotesDarkContainsLink(description) then
        local player = Players.LocalPlayer
        local ownerExempt = emotesDarkIsLinkKickExempt(player)
        emotesDarkRegisterLinkKick(player)
        if ownerExempt then
            return false, emotesDarkBugText("ownerLinks")
        end
        return false, emotesDarkBugText("kicked")
    end

    local webhook = getBugReportWebhook(reportType)
    if webhook == "" then
        return false, emotesDarkBugText(isSuggestion and "suggestionWebhook" or "webhook")
    end

    local player = Players.LocalPlayer
    if not player then return false, emotesDarkBugText("player") end

    local now = os.time()
    local cooldown = getBugReportCooldown(reportType)
    if cooldown > now then
        return false, emotesDarkBugText("wait", formatBugCooldown(cooldown - now))
    end

    local globalAllowed, globalMessage = reserveGlobalBugReportCooldown(reportType)
    if not globalAllowed then
        return false, globalMessage
    end

    local device, platform, input, resolution, graphics = auditClientInfo()
    local jobId = game.JobId ~= "" and game.JobId or "N/A (Studio)"
    local reportId = string.format("EMD-%d-%d", now, player.UserId)
    local profileUrl = string.format("https://www.roblox.com/users/%d/profile", player.UserId)
    local avatar = auditJson(string.format("https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%d&size=420x420&format=Png&isCircular=false", player.UserId))
    local playerName = auditSafe(player.DisplayName) .. " (@" .. auditSafe(player.Name) .. ")"
    local gameName = game.Name ~= "" and game.Name or "Desconhecida"
    if game.GameId and game.GameId > 0 then
        local universeInfo = auditJson(
            "https://games.roblox.com/v1/games?universeIds=" .. tostring(game.GameId)
        )
        if universeInfo
            and universeInfo.data
            and universeInfo.data[1]
            and universeInfo.data[1].name
            and universeInfo.data[1].name ~= "" then
            gameName = universeInfo.data[1].name
        end
    end
    gameName = auditSafe(gameName)

    local countryCode = auditCountryRegion(player)
    local reportMessage = auditTruncate(auditSafe(description), BUG_REPORT_MESSAGE_LIMIT)

    local fields = {
        {
            name = "👤 Reporter Profile",
            value = auditTruncate(string.format("[%s](%s)\nUser ID: %d", playerName, profileUrl, player.UserId), MAX_FIELD_LENGTH),
            inline = false,
        },
        {
            name = "🌍 Country",
            value = auditSafe(countryCode),
            inline = true,
        },
        {
            name = "🧪 Experience",
            value = auditTruncate(string.format("%s\nPlace ID: %d\nUniverse ID: %d", gameName, game.PlaceId, game.GameId), MAX_FIELD_LENGTH),
            inline = false,
        },
        {
            name = isSuggestion and "💡 Suggestion" or "📝 Bug message",
            value = auditTruncate(reportMessage, MAX_FIELD_LENGTH),
            inline = false,
        },
        {
            name = "💻 PC / Client Diagnostics",
            value = auditTruncate(string.format("Device: %s\nPlatform: %s\nInput: %s\nResolution: %s\nGraphics quality: %s", auditSafe(device), auditSafe(platform), auditSafe(input), auditSafe(resolution), auditSafe(graphics)), MAX_FIELD_LENGTH),
            inline = false,
        },
        {
            name = "🛰️ Server",
            value = auditTruncate("Job ID: " .. auditSafe(jobId), MAX_FIELD_LENGTH),
            inline = false,
        },
        {
            name = "🧩 Report Context",
            value = string.format("Report ID: %s\nScript version: emotes-dark-main\nDiagnostics: PC/mobile v2", reportId),
            inline = false,
        },
    }

    local embed = {
        title = isSuggestion and "New Suggestion: Mobile • Emote Dark" or "New Bug Report: Mobile • Emote Dark",
        description = reportMessage,
        color = 16755200,
        timestamp = DateTime.now():ToIsoDate(),
        footer = { text = (isSuggestion and "Emote Dark Suggestions • " or "Emote Dark Bug Reports • ") .. gameName .. " | Today at " .. os.date("%H:%M") },
        fields = fields,
    }

    if avatar and avatar.data and avatar.data[1] and avatar.data[1].imageUrl then
        embed.thumbnail = { url = avatar.data[1].imageUrl }
    end

    local httpClient = emotesDarkGetRequest()
    if type(httpClient) ~= "function" then
        return false, "Request function was not found in the executor."
    end

    local payload = {
        username = isSuggestion and "Emote Dark • Suggestions" or "Emote Dark • Bug Reports",
        content = auditTruncate(string.format("Game: %s\n%s: %s", gameName, isSuggestion and "Suggestion" or "Bug report", reportMessage), 1900),
        allowed_mentions = { parse = {} },
        embeds = { embed },
    }

    local ok, response = pcall(function()
        return httpClient({
            Url = webhook,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload),
        })
    end)

    if not ok then
        return false, "Failed to send the report: " .. auditTruncate(tostring(response), 180)
    end

    if not response then
        return false, "The executor did not receive a response from the webhook."
    end

    local statusCode = tonumber(response.StatusCode or response.Status or response.status_code or response.statusCode)
    local responseBody = response.Body or response.body or ""
    if not statusCode then
        return false, "Invalid response from the webhook."
    end
    if statusCode >= 400 then
        local detail = auditTruncate(tostring(responseBody), 180)
        if detail == "" then detail = "sem detalhes" end
        return false, "The webhook rejected the report (HTTP " .. tostring(statusCode) .. "): " .. detail
    end

    saveBugReportCooldown(now + (isSuggestion and SUGGESTION_COOLDOWN_SECONDS or BUG_REPORT_COOLDOWN_SECONDS), reportType)
    return true, reportId
end

function closeBugReportWindow()
    bugReportTimerToken = bugReportTimerToken + 1
    if bugReportWindow then
        bugReportWindow:Destroy()
        bugReportWindow = nil
    end
    if bugReportOverlay then
        bugReportOverlay:Destroy()
        bugReportOverlay = nil
    end
end

musicWindow = nil
musicOverlay = nil
musicInputConnections = {}
musicCurrentTrackId = nil
MUSIC_CONTROL_TRANSLATIONS = {
    en = {
        title = "EMOTES DARK PLAYER", idLabel = "Audio ID", idPlaceholder = "Paste a Roblox audio ID",
        track = "Track", noTrack = "Choose a track", resolving = "Loading track details...",
        invalidId = "Enter a valid numeric ID.", volume = "Volume", bass = "Bass",
        play = "Play", pause = "Pause", scaleHint = "Fine-tune volume and bass · Roblox audio ID",
        lookupFailed = "Details unavailable; playing by ID.", creator = "Creator", noCreator = "Creator unavailable",
        copyId = "Copy ID", copied = "Copied", copyUnavailable = "Clipboard is unavailable.",
    },
    pt = {
        title = "PLAYER DE MÚSICA", idLabel = "ID do áudio", idPlaceholder = "Cole um ID de áudio do Roblox",
        track = "Faixa", noTrack = "Escolha uma música", resolving = "Carregando detalhes da faixa...",
        invalidId = "Digite um ID numérico válido.", volume = "Volume", bass = "Grave",
        play = "Tocar", pause = "Pausar", scaleHint = "Ajuste volume e grave · ID de áudio do Roblox",
        lookupFailed = "Detalhes indisponíveis; reproduzindo pelo ID.", creator = "Criador", noCreator = "Criador não informado",
        copyId = "Copiar ID", copied = "Copiado", copyUnavailable = "Área de transferência indisponível.",
    },
    es = {
        title = "REPRODUCTOR DE MÚSICA", idLabel = "ID de audio", idPlaceholder = "Pega un ID de audio de Roblox",
        track = "Pista", noTrack = "Elige una canción", resolving = "Cargando detalles de la pista...",
        invalidId = "Escribe un ID numérico válido.", volume = "Volumen", bass = "Graves",
        play = "Reproducir", pause = "Pausar", scaleHint = "Ajusta volumen y graves · ID de audio de Roblox",
        lookupFailed = "Detalles no disponibles; reproduciendo por ID.", creator = "Creador", noCreator = "Creador no disponible",
        copyId = "Copiar ID", copied = "Copiado", copyUnavailable = "Portapapeles no disponible.",
    },
}

function getMusicControlTranslation()
    local language = tostring(emotesDarkDetectLanguage() or "en"):lower():match("^([a-z]+)") or "en"
    local known = MUSIC_CONTROL_TRANSLATIONS[language]
    if known then return known end

    local source = MUSIC_CONTROL_TRANSLATIONS.en
    local translated = {}
    for key, value in pairs(source) do
        translated[key] = emotesDarkTranslateText(value, language)
    end
    return translated
end

musicSound = SoundService:FindFirstChild("EmotesDarkMusicPlayer")
if not musicSound or not musicSound:IsA("Sound") then
    musicSound = Instance.new("Sound")
    musicSound.Name = "EmotesDarkMusicPlayer"
    musicSound.Parent = SoundService
end
musicSound.Looped = false

musicBassEffect = musicSound:FindFirstChild("EmotesDarkBass")
if not musicBassEffect or not musicBassEffect:IsA("EqualizerSoundEffect") then
    musicBassEffect = Instance.new("EqualizerSoundEffect")
    musicBassEffect.Name = "EmotesDarkBass"
    musicBassEffect.Parent = musicSound
end

function closeMusicControlWindow()
    for _, connection in ipairs(musicInputConnections) do
        pcall(function() connection:Disconnect() end)
    end
    musicInputConnections = {}
    if musicWindow then
        musicWindow:Destroy()
        musicWindow = nil
    end
    if musicOverlay then
        musicOverlay:Destroy()
        musicOverlay = nil
    end
end

local function closeOtherScriptWindows(exceptName)
    if exceptName ~= "MusicControlWindow" and (musicWindow or musicOverlay) then
        pcall(closeMusicControlWindow)
    end
    if exceptName ~= "BugReportWindow" and (bugReportWindow or bugReportOverlay) then
        pcall(closeBugReportWindow)
    end
    if exceptName ~= "CustomAnimOverlay" and State and State.customAnimationEditorActive and State.exitCustomAnimationEditor then
        pcall(State.exitCustomAnimationEditor)
    end
    if exceptName ~= "HUDEditorOverlay" and State and State.hudEditorActive and exitHUDEditor then
        pcall(exitHUDEditor)
    end
    if exceptName ~= "EmotesDarkSettingsPopup" and SettingsLib and SettingsLib.UI then
        for _, child in ipairs(SettingsLib.UI:GetChildren()) do
            if child.Name == "EmotesDarkSettingsPopup" then
                pcall(function() child:Destroy() end)
            end
        end
    end
end

function showMusicControlWindow()
    if musicWindow and musicWindow.Parent then return end
    closeOtherScriptWindows("MusicControlWindow")

    local translation = getMusicControlTranslation()
    local activeTheme = State and State.EmoteTheme
    local accentColor = activeTheme and activeTheme.Accent or Color3.fromRGB(255, 193, 7)
    local backgroundColor = activeTheme and activeTheme.Background or Color3.fromRGB(24, 25, 31)
    local textColor = activeTheme and activeTheme.ImageColor or Color3.fromRGB(242, 242, 247)
    local mutedTextColor = textColor:Lerp(backgroundColor, 0.35)
    local surfaceColor = backgroundColor:Lerp(accentColor, 0.11)
    local inputColor = backgroundColor:Lerp(accentColor, 0.07)
    local overlay = Instance.new("Frame")
    overlay.Name = "MusicControlWindow"
    overlay.Parent = SettingsLib.UI
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 7000
    overlay.Active = false
    overlay.Visible = false
    musicOverlay = overlay

    local card = Instance.new("Frame")
    card.Name = "MusicControlCard"
    card.Parent = SettingsLib.UI
    card.AnchorPoint = Vector2.new(0, 0.5)
    card.Position = UDim2.new(0.08, 0, 0.5, 0)
    card.Size = UDim2.fromOffset(290, 345)
    card.BackgroundColor3 = backgroundColor
    card.BorderSizePixel = 0
    card.Active = true
    card.ZIndex = 7001
    musicWindow = card

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card
    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 1
    cardScale.Parent = card

    local cardGradient = Instance.new("UIGradient")
    cardGradient.Color = ColorSequence.new(backgroundColor:Lerp(accentColor, 0.08), backgroundColor)
    cardGradient.Rotation = 90
    cardGradient.Parent = card
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = accentColor
    cardStroke.Thickness = 1.4
    cardStroke.Transparency = 0.2
    cardStroke.Parent = card
    local accentBar = Instance.new("Frame")
    accentBar.Name = "AccentBar"
    accentBar.Parent = card
    accentBar.BackgroundColor3 = accentColor
    accentBar.BorderSizePixel = 0
    accentBar.Position = UDim2.fromOffset(0, 0)
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.ZIndex = 7003

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Parent = card
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 14, 0, 12)
    title.Size = UDim2.new(1, -62, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.Text = translation.title
    title.TextColor3 = textColor
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 7002

    local close = Instance.new("TextButton")
    close.Name = "Close"
    close.Parent = card
    close.BackgroundTransparency = 1
    close.Position = UDim2.new(1, -40, 0, 7)
    close.Size = UDim2.fromOffset(28, 28)
    close.Font = Enum.Font.GothamBold
    close.Text = "×"
    close.TextColor3 = mutedTextColor
    close.TextSize = 24
    close.ZIndex = 7002
    close.MouseButton1Click:Connect(closeMusicControlWindow)

    local trackPanel = Instance.new("Frame")
    trackPanel.Name = "TrackPanel"
    trackPanel.Parent = card
    trackPanel.BackgroundColor3 = surfaceColor
    trackPanel.BorderSizePixel = 0
    trackPanel.Position = UDim2.fromOffset(12, 38)
    trackPanel.Size = UDim2.new(1, -24, 0, 72)
    trackPanel.ZIndex = 7001
    local trackPanelCorner = Instance.new("UICorner")
    trackPanelCorner.CornerRadius = UDim.new(0, 12)
    trackPanelCorner.Parent = trackPanel

    local artFallback = Instance.new("TextLabel")
    artFallback.Name = "ArtworkFallback"
    artFallback.Parent = trackPanel
    artFallback.BackgroundColor3 = inputColor
    artFallback.BorderSizePixel = 0
    artFallback.Position = UDim2.fromOffset(7, 8)
    artFallback.Size = UDim2.fromOffset(56, 56)
    artFallback.Font = Enum.Font.GothamBold
    artFallback.Text = "♫"
    artFallback.TextColor3 = accentColor
    artFallback.TextSize = 30
    artFallback.ZIndex = 7002
    local artCorner = Instance.new("UICorner")
    artCorner.CornerRadius = UDim.new(0, 10)
    artCorner.Parent = artFallback
    local artwork = Instance.new("ImageLabel")
    artwork.Name = "TrackArtwork"
    artwork.Parent = trackPanel
    artwork.BackgroundTransparency = 1
    artwork.Position = UDim2.fromOffset(7, 8)
    artwork.Size = UDim2.fromOffset(56, 56)
    artwork.ScaleType = Enum.ScaleType.Crop
    artwork.ZIndex = 7003
    local artworkCorner = Instance.new("UICorner")
    artworkCorner.CornerRadius = UDim.new(0, 10)
    artworkCorner.Parent = artwork

    local idLabel = Instance.new("TextLabel")
    idLabel.Parent = card
    idLabel.BackgroundTransparency = 1
    idLabel.Position = UDim2.new(0, 14, 0, 116)
    idLabel.Size = UDim2.new(1, -28, 0, 14)
    idLabel.Font = Enum.Font.Gotham
    idLabel.Text = translation.idLabel
    idLabel.TextColor3 = mutedTextColor
    idLabel.TextSize = 10
    idLabel.TextXAlignment = Enum.TextXAlignment.Left
    idLabel.ZIndex = 7002

    local idBox = Instance.new("TextBox")
    idBox.Name = "AudioId"
    idBox.Parent = card
    idBox.BackgroundColor3 = inputColor
    idBox.Position = UDim2.new(0, 14, 0, 131)
    idBox.Size = UDim2.new(1, -28, 0, 28)
    idBox.ClearTextOnFocus = false
    idBox.Font = Enum.Font.Gotham
    idBox.PlaceholderText = translation.idPlaceholder
    idBox.PlaceholderColor3 = mutedTextColor
    idBox.Text = ""
    idBox.TextColor3 = textColor
    idBox.TextSize = 11
    idBox.ZIndex = 7002
    local idCorner = Instance.new("UICorner")
    idCorner.CornerRadius = UDim.new(0, 7)
    idCorner.Parent = idBox

    local trackLabel = Instance.new("TextLabel")
    trackLabel.Name = "TrackName"
    trackLabel.Parent = card
    trackLabel.BackgroundTransparency = 1
    trackLabel.Position = UDim2.new(0, 82, 0, 44)
    trackLabel.Size = UDim2.new(1, -96, 0, 22)
    trackLabel.Font = Enum.Font.Gotham
    trackLabel.Text = translation.noTrack
    trackLabel.TextColor3 = textColor
    trackLabel.TextSize = 11
    trackLabel.TextWrapped = true
    trackLabel.TextXAlignment = Enum.TextXAlignment.Left
    trackLabel.TextYAlignment = Enum.TextYAlignment.Center
    trackLabel.ZIndex = 7004

    local creatorLabel = Instance.new("TextLabel")
    creatorLabel.Name = "TrackCreator"
    creatorLabel.Parent = card
    creatorLabel.BackgroundTransparency = 1
    creatorLabel.Position = UDim2.new(0, 82, 0, 67)
    creatorLabel.Size = UDim2.new(1, -96, 0, 14)
    creatorLabel.Font = Enum.Font.Gotham
    creatorLabel.Text = translation.creator .. ": " .. translation.noCreator
    creatorLabel.TextColor3 = mutedTextColor
    creatorLabel.TextSize = 10
    creatorLabel.TextXAlignment = Enum.TextXAlignment.Left
    creatorLabel.TextTruncate = Enum.TextTruncate.AtEnd
    creatorLabel.ZIndex = 7004

    local idInfoPrefix = Instance.new("TextLabel")
    idInfoPrefix.Name = "TrackIdLabel"
    idInfoPrefix.Parent = card
    idInfoPrefix.BackgroundTransparency = 1
    idInfoPrefix.Position = UDim2.new(0, 82, 0, 87)
    idInfoPrefix.Size = UDim2.fromOffset(18, 15)
    idInfoPrefix.Font = Enum.Font.GothamBold
    idInfoPrefix.Text = "ID"
    idInfoPrefix.TextColor3 = accentColor
    idInfoPrefix.TextSize = 9
    idInfoPrefix.TextXAlignment = Enum.TextXAlignment.Left
    idInfoPrefix.ZIndex = 7004
    local idInfoValue = Instance.new("TextLabel")
    idInfoValue.Name = "TrackId"
    idInfoValue.Parent = card
    idInfoValue.BackgroundTransparency = 1
    idInfoValue.Position = UDim2.new(0, 100, 0, 87)
    idInfoValue.Size = UDim2.new(1, -188, 0, 15)
    idInfoValue.Font = Enum.Font.Gotham
    idInfoValue.Text = "—"
    idInfoValue.TextColor3 = textColor
    idInfoValue.TextSize = 9
    idInfoValue.TextXAlignment = Enum.TextXAlignment.Left
    idInfoValue.TextTruncate = Enum.TextTruncate.AtEnd
    idInfoValue.ZIndex = 7004
    local copyIdButton = Instance.new("TextButton")
    copyIdButton.Name = "CopyTrackId"
    copyIdButton.Parent = card
    copyIdButton.BackgroundColor3 = inputColor
    copyIdButton.BorderSizePixel = 0
    copyIdButton.Position = UDim2.new(1, -80, 0, 84)
    copyIdButton.Size = UDim2.fromOffset(66, 20)
    copyIdButton.Font = Enum.Font.GothamBold
    copyIdButton.Text = translation.copyId
    copyIdButton.TextColor3 = accentColor
    copyIdButton.TextSize = 9
    copyIdButton.ZIndex = 7004
    local copyIdCorner = Instance.new("UICorner")
    copyIdCorner.CornerRadius = UDim.new(0, 7)
    copyIdCorner.Parent = copyIdButton

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Parent = card
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 14, 0, 161)
    status.Size = UDim2.new(1, -28, 0, 14)
    status.Font = Enum.Font.Gotham
    status.Text = ""
    status.TextColor3 = accentColor
    status.TextSize = 9
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.ZIndex = 7002

    local progressTrack = Instance.new("Frame")
    progressTrack.Name = "ProgressTrack"
    progressTrack.Parent = card
    progressTrack.Position = UDim2.new(0, 14, 0, 178)
    progressTrack.Size = UDim2.new(1, -28, 0, 7)
    progressTrack.BackgroundColor3 = surfaceColor
    progressTrack.BorderSizePixel = 0
    progressTrack.Active = true
    progressTrack.ZIndex = 7002
    local progressTrackCorner = Instance.new("UICorner")
    progressTrackCorner.CornerRadius = UDim.new(1, 0)
    progressTrackCorner.Parent = progressTrack
    local progressFill = Instance.new("Frame")
    progressFill.Name = "ProgressFill"
    progressFill.Parent = progressTrack
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = accentColor
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 7003
    local progressFillCorner = Instance.new("UICorner")
    progressFillCorner.CornerRadius = UDim.new(1, 0)
    progressFillCorner.Parent = progressFill
    local timeLabel = Instance.new("TextLabel")
    timeLabel.Name = "TrackTime"
    timeLabel.Parent = card
    timeLabel.BackgroundTransparency = 1
    timeLabel.Position = UDim2.new(0, 14, 0, 187)
    timeLabel.Size = UDim2.new(1, -28, 0, 13)
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.Text = "0:00 / --:--"
    timeLabel.TextColor3 = mutedTextColor
    timeLabel.TextSize = 9
    timeLabel.TextXAlignment = Enum.TextXAlignment.Right
    timeLabel.ZIndex = 7002

    local function createMusicSlider(key, initialValue, top, onValueChanged)
        local value = math.clamp(math.floor(initialValue + 0.5), 0, 1000)
        local label = Instance.new("TextLabel")
        label.Parent = card
        label.BackgroundTransparency = 1
        label.Position = UDim2.new(0, 14, 0, top)
        label.Size = UDim2.new(1, -28, 0, 17)
        label.Font = Enum.Font.Gotham
        label.TextColor3 = mutedTextColor
        label.TextSize = 10
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.ZIndex = 7002

        local track = Instance.new("Frame")
        track.Name = key .. "Slider"
        track.Parent = card
        track.Position = UDim2.new(0, 14, 0, top + 22)
        track.Size = UDim2.new(1, -28, 0, 10)
        track.BackgroundColor3 = surfaceColor
        track.BorderSizePixel = 0
        track.Active = true
        track.ZIndex = 7002
        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = track

        local fill = Instance.new("Frame")
        fill.Parent = track
        fill.Size = UDim2.new(value / 1000, 0, 1, 0)
        fill.BackgroundColor3 = accentColor
        fill.BorderSizePixel = 0
        fill.ZIndex = 7003
        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = fill

        local knob = Instance.new("Frame")
        knob.Parent = track
        knob.AnchorPoint = Vector2.new(0.5, 0.5)
        knob.Position = UDim2.new(value / 1000, 0, 0.5, 0)
        knob.Size = UDim2.fromOffset(16, 16)
        knob.BackgroundColor3 = Color3.fromRGB(245, 245, 245)
        knob.BorderSizePixel = 0
        knob.ZIndex = 7004
        local knobCorner = Instance.new("UICorner")
        knobCorner.CornerRadius = UDim.new(1, 0)
        knobCorner.Parent = knob

        local function applyValue(nextValue)
            value = math.clamp(math.floor(nextValue + 0.5), 0, 1000)
            label.Text = translation[key] .. ": " .. tostring(value) .. " / 1000"
            fill.Size = UDim2.new(value / 1000, 0, 1, 0)
            knob.Position = UDim2.new(value / 1000, 0, 0.5, 0)
            onValueChanged(value)
        end
        local function setValueFromX(x)
            local width = math.max(track.AbsoluteSize.X, 1)
            applyValue(((x - track.AbsolutePosition.X) / width) * 1000)
        end
        local dragging = false
        local dragInput = nil
        track.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragInput = input
                setValueFromX(input.Position.X)
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        dragInput = nil
                    end
                end)
            end
        end)
        local inputConnection = UserInputService.InputChanged:Connect(function(input)
            if not dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input == dragInput then
                setValueFromX(input.Position.X)
            end
        end)
        table.insert(musicInputConnections, inputConnection)
        applyValue(value)
        return value
    end

    local currentVolume = math.clamp(math.floor((tonumber(musicSound.Volume) or 1) * 100 + 0.5), 0, 1000)
    local currentBass = math.clamp(math.floor((tonumber(musicBassEffect.LowGain) or 0) * 100 + 0.5), 0, 1000)
    createMusicSlider("volume", currentVolume, 201, function(value)
        musicSound.Volume = value / 100
    end)
    createMusicSlider("bass", currentBass, 240, function(value)
        musicBassEffect.LowGain = value / 100
    end)

    local function createMusicButton(name, text, position, size, isPrimary)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Parent = card
        button.Position = position
        button.Size = size
        button.BackgroundColor3 = isPrimary and accentColor or surfaceColor
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.Text = text
        button.TextColor3 = isPrimary and backgroundColor or textColor
        button.TextSize = 11
        button.AutoButtonColor = true
        button.ZIndex = 7002
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 7)
        corner.Parent = button
        return button
    end
    local playButton = createMusicButton("Play", translation.play, UDim2.new(0, 14, 0, 280), UDim2.fromOffset(126, 34), true)
    local pauseButton = createMusicButton("Pause", translation.pause, UDim2.new(1, -140, 0, 280), UDim2.fromOffset(126, 34), false)

    local scaleHint = Instance.new("TextLabel")
    scaleHint.Parent = card
    scaleHint.BackgroundTransparency = 1
    scaleHint.Position = UDim2.new(0, 14, 0, 318)
    scaleHint.Size = UDim2.new(1, -28, 0, 16)
    scaleHint.Font = Enum.Font.Gotham
    scaleHint.Text = translation.scaleHint
    scaleHint.TextColor3 = mutedTextColor
    scaleHint.TextSize = 9
    scaleHint.TextXAlignment = Enum.TextXAlignment.Center
    scaleHint.ZIndex = 7002

    local function setMusicTrackInfo(assetId, name, creatorName)
        idInfoValue.Text = tostring(assetId or "—")
        trackLabel.Text = name or translation.noTrack
        creatorLabel.Text = translation.creator .. ": " .. (creatorName or translation.noCreator)
        artwork.Image = assetId and ("rbxthumb://type=Asset&id=" .. tostring(assetId) .. "&w=150&h=150") or ""
    end

    local function formatMusicTime(value)
        local total = math.max(0, math.floor(tonumber(value) or 0))
        return string.format("%d:%02d", math.floor(total / 60), total % 60)
    end

    local function lookupTrackName(assetId)
        task.spawn(function()
            local ok, info = pcall(function()
                return game:GetService("MarketplaceService"):GetProductInfo(tonumber(assetId), Enum.InfoType.Asset)
            end)
            if not (musicWindow and musicWindow.Parent) or musicCurrentTrackId ~= assetId then return end
            if ok and type(info) == "table" and type(info.Name) == "string" and info.Name ~= "" then
                local name = info.Name
                if #name > 72 then name = string.sub(name, 1, 69) .. "..." end
                local creatorName = type(info.Creator) == "table" and tostring(info.Creator.Name or "") or ""
                if creatorName == "" then creatorName = translation.noCreator end
                setMusicTrackInfo(assetId, name, creatorName)
                status.Text = ""
            else
                setMusicTrackInfo(assetId, translation.track .. " #" .. assetId, translation.noCreator)
                status.Text = translation.lookupFailed
            end
        end)
    end

    playButton.MouseButton1Click:Connect(function()
        local rawId = idBox.Text:gsub("%s+", "")
        local numericId = tonumber(rawId)
        if not numericId or numericId <= 0 or rawId:match("^%d+$") == nil then
            status.Text = translation.invalidId
            status.TextColor3 = Color3.fromRGB(255, 130, 130)
            return
        end
        local assetId = tostring(math.floor(numericId))
        musicCurrentTrackId = assetId
        status.TextColor3 = accentColor
        status.Text = translation.resolving
        setMusicTrackInfo(assetId, translation.resolving, translation.noCreator)
        musicSound:Stop()
        musicSound.SoundId = "rbxassetid://" .. assetId
        musicSound.TimePosition = 0
        musicSound:Play()
        lookupTrackName(assetId)
    end)

    pauseButton.MouseButton1Click:Connect(function()
        if musicSound.IsPlaying then
            musicSound:Pause()
            status.TextColor3 = mutedTextColor
            status.Text = translation.pause
        end
    end)

    copyIdButton.MouseButton1Click:Connect(function()
        local rawId = idBox.Text:gsub("%s+", "")
        local numericId = tonumber(rawId)
        if not numericId or numericId <= 0 or rawId:match("^%d+$") == nil then
            rawId = tostring(musicCurrentTrackId or "")
        else
            rawId = tostring(math.floor(numericId))
        end
        if rawId == "" then
            status.TextColor3 = Color3.fromRGB(255, 130, 130)
            status.Text = translation.invalidId
            return
        end
        local copied = pcall(function() setclipboard(rawId) end)
        if copied then
            copyIdButton.Text = translation.copied
            status.TextColor3 = accentColor
            status.Text = translation.copied
            task.delay(1.2, function()
                if copyIdButton and copyIdButton.Parent then copyIdButton.Text = translation.copyId end
            end)
        else
            status.TextColor3 = Color3.fromRGB(255, 130, 130)
            status.Text = translation.copyUnavailable
        end
    end)

    local seekConnection = progressTrack.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local duration = tonumber(musicSound.TimeLength) or 0
        if duration <= 0 then return end
        local width = math.max(progressTrack.AbsoluteSize.X, 1)
        local fraction = math.clamp((input.Position.X - progressTrack.AbsolutePosition.X) / width, 0, 1)
        pcall(function() musicSound.TimePosition = duration * fraction end)
    end)
    table.insert(musicInputConnections, seekConnection)

    task.spawn(function()
        while musicWindow == card and card.Parent do
            local duration = tonumber(musicSound.TimeLength) or 0
            local position = tonumber(musicSound.TimePosition) or 0
            progressFill.Size = UDim2.new(duration > 0 and math.clamp(position / duration, 0, 1) or 0, 0, 1, 0)
            timeLabel.Text = formatMusicTime(position) .. " / " .. (duration > 0 and formatMusicTime(duration) or "--:--")
            task.wait(0.25)
        end
    end)

    local function fitMusicCard()
        if not overlay.Parent then return end
        local viewport = overlay.AbsoluteSize
        local currentWidth = card.AbsoluteSize.X / math.max(cardScale.Scale, 0.01)
        local currentHeight = card.AbsoluteSize.Y / math.max(cardScale.Scale, 0.01)
        if viewport.X <= 0 or viewport.Y <= 0 or currentWidth <= 0 or currentHeight <= 0 then return end
        local desiredWidth = math.clamp(viewport.X * 0.25, 250, 300)
        local desiredHeight = math.clamp(viewport.Y * 0.5, 320, 360)
        cardScale.Scale = math.min(desiredWidth / currentWidth, desiredHeight / currentHeight)
        local margin = math.max(16, viewport.X * 0.04)
        local desiredX = math.min(math.max(viewport.X * 0.08, margin), math.max(margin, viewport.X - card.AbsoluteSize.X - margin))
        local parentWidth = viewport.X
        if overlay.Parent and overlay.Parent:IsA("GuiObject") and overlay.Parent.AbsoluteSize.X > 0 then
            parentWidth = overlay.Parent.AbsoluteSize.X
        end
        card.Position = UDim2.new(0, desiredX * parentWidth / viewport.X, 0.5, 0)
    end
    overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        task.defer(fitMusicCard)
    end)
    task.defer(fitMusicCard)

    local existingId = musicSound.SoundId:match("rbxassetid://(%d+)")
    if existingId then
        idBox.Text = existingId
        musicCurrentTrackId = existingId
        setMusicTrackInfo(existingId, translation.resolving, translation.noCreator)
        lookupTrackName(existingId)
    end
end

function showBugReportWindow()
    if bugReportWindow and bugReportWindow.Parent then return end
    closeOtherScriptWindows("BugReportWindow")

    local overlay = Instance.new("Frame")
    overlay.Name = "BugReportWindow"
    overlay.Parent = SettingsLib.UI
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 7000
    overlay.Active = false
    overlay.Visible = false
    bugReportOverlay = overlay

    local card = Instance.new("Frame")
    card.Name = "BugReportCard"
    card.Parent = SettingsLib.UI
    card.AnchorPoint = Vector2.new(0, 0.5)
    card.Position = UDim2.new(0.08, 0, 0.5, 0)
    card.Size = UDim2.fromOffset(270, 260)
    card.BackgroundColor3 = Color3.fromRGB(24, 25, 31)
    card.BackgroundTransparency = 0
    card.BorderSizePixel = 0
    card.Active = true
    card.ZIndex = 7001
    bugReportWindow = card

    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 10)
    cardCorner.Parent = card

    local cardScale = Instance.new("UIScale")
    cardScale.Scale = 1
    cardScale.Parent = card

    local title = Instance.new("TextLabel")
    title.Parent = card
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 18, 0, 12)
    title.Size = UDim2.new(1, -132, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.Text = emotesDarkBugText("title")
    title.TextColor3 = Color3.fromRGB(242, 242, 247)
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 7002
    title.Active = true

    local function createBugReportTab(name, position, textKey)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Parent = card
        button.Position = position
        button.Size = UDim2.new(0.5, -21, 0, 26)
        button.BackgroundColor3 = Color3.fromRGB(37, 38, 45)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.Text = emotesDarkBugText(textKey)
        button.TextColor3 = Color3.fromRGB(235, 235, 240)
        button.TextSize = 9
        button.ZIndex = 7002

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button
        return button
    end

    local suggestionTab = createBugReportTab("SuggestionTab", UDim2.new(0, 18, 0, 42), "suggestionsTab")
    local bugTab = createBugReportTab("BugReportTab", UDim2.new(0.5, 3, 0, 42), "bugsTab")

    local close = Instance.new("TextButton")
    close.Parent = card
    close.BackgroundTransparency = 1
    close.Position = UDim2.new(1, -40, 0, 9)
    close.Size = UDim2.fromOffset(28, 28)
    close.Font = Enum.Font.GothamBold
    close.Text = "×"
    close.TextColor3 = Color3.fromRGB(220, 220, 225)
    close.TextSize = 24
    close.ZIndex = 7002

    local cooldownLabel = Instance.new("TextLabel")
    cooldownLabel.Parent = card
    cooldownLabel.BackgroundTransparency = 1
    cooldownLabel.Position = UDim2.new(1, -116, 0, 14)
    cooldownLabel.Size = UDim2.fromOffset(72, 20)
    cooldownLabel.Font = Enum.Font.GothamBold
    cooldownLabel.Text = "00h 00m 00s"
    cooldownLabel.TextColor3 = Color3.fromRGB(130, 225, 155)
    cooldownLabel.TextSize = 9
    cooldownLabel.TextXAlignment = Enum.TextXAlignment.Right
    cooldownLabel.ZIndex = 7002

    local hint = Instance.new("TextLabel")
    hint.Parent = card
    hint.BackgroundTransparency = 1
    hint.Position = UDim2.new(0, 18, 0, 75)
    hint.Size = UDim2.new(1, -36, 0, 30)
    hint.Font = Enum.Font.Gotham
    hint.Text = emotesDarkBugText("hint")
    hint.TextColor3 = Color3.fromRGB(170, 171, 181)
    hint.TextSize = 10
    hint.TextWrapped = true
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.ZIndex = 7002

    local textBox = Instance.new("TextBox")
    textBox.Parent = card
    textBox.BackgroundColor3 = Color3.fromRGB(37, 38, 45)
    textBox.Position = UDim2.new(0, 18, 0, 109)
    textBox.Size = UDim2.new(1, -36, 0, 74)
    textBox.ClearTextOnFocus = false
    textBox.Font = Enum.Font.Gotham
    textBox.MultiLine = true
    textBox.PlaceholderText = emotesDarkBugText("placeholder")
    textBox.PlaceholderColor3 = Color3.fromRGB(120, 121, 130)
    textBox.Text = ""
    textBox.TextColor3 = Color3.fromRGB(240, 240, 245)
    textBox.TextSize = 11
    textBox.TextWrapped = true
    textBox.TextXAlignment = Enum.TextXAlignment.Left
    textBox.TextYAlignment = Enum.TextYAlignment.Top
    textBox.ZIndex = 7002

    local boxCorner = Instance.new("UICorner")
    boxCorner.CornerRadius = UDim.new(0, 7)
    boxCorner.Parent = textBox

    local function setBugReportInputEnabled(enabled)
        textBox.TextEditable = enabled
        if enabled then
            textBox.TextColor3 = Color3.fromRGB(240, 240, 245)
            textBox.PlaceholderColor3 = Color3.fromRGB(120, 121, 130)
        else
            textBox.TextColor3 = Color3.fromRGB(145, 145, 155)
            textBox.PlaceholderColor3 = Color3.fromRGB(95, 95, 105)
        end
    end

    local status = Instance.new("TextLabel")
    status.Parent = card
    status.BackgroundTransparency = 1
    status.Position = UDim2.new(0, 18, 0, 188)
    status.Size = UDim2.new(1, -36, 0, 26)
    status.Font = Enum.Font.Gotham
    status.Text = ""
    status.TextColor3 = Color3.fromRGB(255, 150, 150)
    status.TextSize = 10
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.ZIndex = 7002

    local send = Instance.new("TextButton")
    send.Parent = card
    send.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
    send.Position = UDim2.new(1, -122, 1, -44)
    send.Size = UDim2.fromOffset(104, 32)
    send.Font = Enum.Font.GothamBold
    send.Text = emotesDarkBugText("send")
    send.TextColor3 = Color3.fromRGB(30, 30, 35)
    send.TextSize = 10
    send.ZIndex = 7002

    local currentReportType = "bug"
    local reportTranslation = getBugReportTranslation(emotesDarkDetectLanguage()) or BUG_REPORT_TRANSLATIONS.en
    local function applyBugReportMode(translation)
        translation = translation or reportTranslation or BUG_REPORT_TRANSLATIONS.en
        reportTranslation = translation
        local isSuggestion = currentReportType == "suggestion"
        title.Text = translation[isSuggestion and "suggestionTitle" or "title"] or title.Text
        hint.Text = translation[isSuggestion and "suggestionHint" or "hint"] or hint.Text
        textBox.PlaceholderText = translation[isSuggestion and "suggestionPlaceholder" or "placeholder"] or textBox.PlaceholderText
        send.Text = translation[isSuggestion and "suggestionSend" or "send"] or send.Text
        suggestionTab.Text = translation.suggestionsTab or suggestionTab.Text
        bugTab.Text = translation.bugsTab or bugTab.Text
        suggestionTab.BackgroundColor3 = isSuggestion and Color3.fromRGB(255, 193, 7) or Color3.fromRGB(37, 38, 45)
        suggestionTab.TextColor3 = isSuggestion and Color3.fromRGB(30, 30, 35) or Color3.fromRGB(235, 235, 240)
        bugTab.BackgroundColor3 = isSuggestion and Color3.fromRGB(37, 38, 45) or Color3.fromRGB(255, 193, 7)
        bugTab.TextColor3 = isSuggestion and Color3.fromRGB(235, 235, 240) or Color3.fromRGB(30, 30, 35)
    end

    suggestionTab.MouseButton1Click:Connect(function()
        currentReportType = "suggestion"
        status.Text = ""
        applyBugReportMode()
    end)
    bugTab.MouseButton1Click:Connect(function()
        currentReportType = "bug"
        status.Text = ""
        applyBugReportMode()
    end)
    applyBugReportMode()

    task.spawn(function()
        local language = emotesDarkDetectLanguage()
        local translation = getBugReportTranslation(language)
        if not title.Parent then return end
        applyBugReportMode(translation)
    end)

    local sendCorner = Instance.new("UICorner")
    sendCorner.CornerRadius = UDim.new(0, 7)
    sendCorner.Parent = send

    local function fitBugReportCard()
        if not overlay.Parent then return end

        local viewport = overlay.AbsoluteSize
        local currentWidth = card.AbsoluteSize.X / math.max(cardScale.Scale, 0.01)
        local currentHeight = card.AbsoluteSize.Y / math.max(cardScale.Scale, 0.01)
        if viewport.X <= 0 or viewport.Y <= 0 or currentWidth <= 0 or currentHeight <= 0 then return end

        local desiredWidth = math.clamp(viewport.X * 0.25, 245, 290)
        local desiredHeight = math.clamp(viewport.Y * 0.50, 230, 265)
        cardScale.Scale = math.min(desiredWidth / currentWidth, desiredHeight / currentHeight)
    end

    local function positionBugReportCard()
        if not overlay.Parent then return end

        local viewport = overlay.AbsoluteSize
        if viewport.X <= 0 then return end

        local margin = math.max(16, viewport.X * 0.04)
        local desiredX = viewport.X * 0.08
        local maxX = math.max(margin, viewport.X - card.AbsoluteSize.X - margin)
        desiredX = math.min(math.max(desiredX, margin), maxX)

        local parent = overlay.Parent
        local parentWidth = viewport.X
        if parent and parent:IsA("GuiObject") and parent.AbsoluteSize.X > 0 then
            parentWidth = parent.AbsoluteSize.X
        end
        local localX = desiredX * parentWidth / viewport.X
        card.Position = UDim2.new(0, localX, 0.5, 0)
    end

    local function refreshBugReportLayout()
        fitBugReportCard()
        task.defer(positionBugReportCard)
    end

    overlay:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        task.defer(refreshBugReportLayout)
    end)
    task.defer(refreshBugReportLayout)

    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local dragStartPosition = nil

    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragInput = input
            dragStart = input.Position
            dragStartPosition = card.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    dragInput = nil
                end
            end)
        end
    end)

    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput or not dragStart or not dragStartPosition then return end
        local delta = input.Position - dragStart
        card.Position = UDim2.new(
            dragStartPosition.X.Scale,
            dragStartPosition.X.Offset + delta.X,
            dragStartPosition.Y.Scale,
            dragStartPosition.Y.Offset + delta.Y
        )
    end)

    local token = bugReportTimerToken + 1
    bugReportTimerToken = token
    local function refreshCooldown()
        if not overlay.Parent or bugReportTimerToken ~= token then return false end
        if bugReportSubmissionInProgress then
            setBugReportInputEnabled(false)
            send.Active = false
            send.AutoButtonColor = false
            pcall(function() send.Interactable = false end)
            send.BackgroundColor3 = Color3.fromRGB(95, 55, 55)
            return true
        end
        if isBugReportOwner() then
            setBugReportInputEnabled(true)
            cooldownLabel.Text = "00h 00m 00s"
            cooldownLabel.TextColor3 = Color3.fromRGB(130, 225, 155)
            send.Active = true
            send.AutoButtonColor = true
            pcall(function() send.Interactable = true end)
            send.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
            return true
        end

        local remaining = getBugReportCooldown(currentReportType) - os.time()
        if remaining > 0 then
            setBugReportInputEnabled(false)
            cooldownLabel.Text = formatBugCooldown(remaining)
            cooldownLabel.TextColor3 = Color3.fromRGB(255, 105, 105)
            send.Active = false
            send.AutoButtonColor = false
            pcall(function() send.Interactable = false end)
            send.BackgroundColor3 = Color3.fromRGB(95, 55, 55)
        else
            setBugReportInputEnabled(true)
            cooldownLabel.Text = "00h 00m 00s"
            cooldownLabel.TextColor3 = Color3.fromRGB(130, 225, 155)
            send.Active = true
            send.AutoButtonColor = true
            pcall(function() send.Interactable = true end)
            send.BackgroundColor3 = Color3.fromRGB(255, 193, 7)
        end
        return true
    end

    close.MouseButton1Click:Connect(closeBugReportWindow)
    send.MouseButton1Click:Connect(function()
        if bugReportSubmissionInProgress then return end
        bugReportSubmissionInProgress = true
        local reportType = currentReportType

        -- Apply the lock before any validation or HTTP work, then return control to the UI.
        send.Active = false
        send.AutoButtonColor = false
        send.BackgroundColor3 = Color3.fromRGB(95, 55, 55)
        setBugReportInputEnabled(false)
        suggestionTab.Active = false
        bugTab.Active = false
        pcall(function()
            send.Interactable = false
            suggestionTab.Interactable = false
            bugTab.Interactable = false
        end)
        status.TextColor3 = Color3.fromRGB(190, 191, 200)
        status.Text = emotesDarkBugText("sending")

        task.defer(function()
            -- Give Roblox a frame to render the disabled state before synchronous requests.
            task.wait()
            local processingOk, processingError = pcall(function()
                local description = textBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
                if emotesDarkContainsLink(description) then
                    status.TextColor3 = Color3.fromRGB(255, 105, 105)
                    local ownerExempt = emotesDarkIsLinkKickExempt(Players.LocalPlayer)
                    status.Text = ownerExempt and emotesDarkBugText("ownerLinks") or emotesDarkBugText("kicked")
                    emotesDarkRegisterLinkKick(Players.LocalPlayer)
                    return
                end

                if #description < BUG_REPORT_MIN_LENGTH then
                    status.TextColor3 = Color3.fromRGB(255, 150, 150)
                    status.Text = emotesDarkBugText("minLength")
                    return
                end

                local remaining = getBugReportCooldown(reportType) - os.time()
                if remaining > 0 then
                    status.TextColor3 = Color3.fromRGB(255, 105, 105)
                    status.Text = emotesDarkBugText("cooldown", formatBugCooldown(remaining))
                    return
                end

                local success, result = submitBugReport(description, reportType)
                if success then
                    status.TextColor3 = Color3.fromRGB(160, 220, 170)
                    local sentKey = reportType == "suggestion" and "suggestionSent" or "sent"
                    local notifyKey = reportType == "suggestion" and "suggestionSentNotify" or "sentNotify"
                    status.Text = emotesDarkBugText(sentKey, tostring(result))
                    notifyBugReport(reportType == "suggestion" and "Dark | Suggestion" or "Dark | Bug report", emotesDarkBugText(notifyKey))
                else
                    status.TextColor3 = Color3.fromRGB(255, 150, 150)
                    status.Text = tostring(result)
                end
            end)

            bugReportSubmissionInProgress = false
            pcall(function()
                suggestionTab.Active = true
                bugTab.Active = true
                suggestionTab.Interactable = true
                bugTab.Interactable = true
            end)
            if not processingOk and status.Parent then
                status.TextColor3 = Color3.fromRGB(255, 150, 150)
                status.Text = tostring(processingError)
            end
            pcall(refreshCooldown)
        end)
    end)

    refreshCooldown()
    task.spawn(function()
        while refreshCooldown() do
            task.wait(1)
        end
    end)
end



DiscordBtn.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/MVgAr2YYj4")
    emotesDarkExecutorEnv().Notify({Title = "Discord", Content = "The Discord invite has been copied", Duration = 3})
end)

BugBtn.MouseButton1Click:Connect(function()
    showBugReportWindow()
end)

MusicBtn.MouseButton1Click:Connect(function()
    if musicWindow and musicWindow.Parent then
        closeMusicControlWindow()
    else
        showMusicControlWindow()
    end
end)

ToggleBtn.MouseButton1Click:Connect(function()
    local main = getSettingsMainFrame()
    if main then
        main.Visible = not main.Visible
        syncToggleVisibility()
    else
        SettingsLib.UI.Enabled = not SettingsLib.UI.Enabled
    end
end)

applySettingsToggleStyle()
syncToggleVisibility()
syncDiscordVisibility()
syncBugReportVisibility()

do
    local main = getSettingsMainFrame()
    if main then
        main:GetPropertyChangedSignal("Visible"):Connect(syncToggleVisibility)
    end
end

TogglesUI, ApplyFavoriteButtonVisual, themes, currentThemeName = nil, nil, nil, nil

do
TogglesUI = {}
GeneralTab = SettingsLib.CreateTab("General", 1)
TogglesUI.NotifyEnabled = SettingsLib.AddToggle(GeneralTab, "Show Notifications", "Receive alerts and feedback", Config.NotifyEnabled, function(v)
    Config.NotifyEnabled = v
    SaveConfig()
end)

TogglesUI.OwnerAlertEnabled = SettingsLib.AddToggle(GeneralTab, "Owner Alert", "Show the owner arrival card with avatar, game, and server details", Config.OwnerAlertEnabled, function(v)
    Config.OwnerAlertEnabled = v
    SaveConfig()
end)

TogglesUI.AuthenticFirstPage = SettingsLib.AddToggle(GeneralTab, "Authentic Emotes Page", "Show owned emotes on page 1", Config.AuthenticFirstPage, function(v)
    Config.AuthenticFirstPage = v
    State.totalPages = calculateTotalPages()
    if State.currentPage > State.totalPages then
        State.currentPage = State.totalPages
    end
    updatePageDisplay()
    updateEmotes()
    SaveConfig()
end)

randomModes = { "All", "Favorites" }
randomDropdown = SettingsLib.AddDropdown(GeneralTab, "Random Source", randomModes, Config.RandomMode or "All", function(v)
    Config.RandomMode = v
    SaveConfig()
end)
if randomDropdown and randomDropdown.Button then
    randomDropdown.Button.Text = (Config.RandomMode or "All") .. "  ▼"
end

TogglesUI.RandomEnabled = SettingsLib.AddToggle(GeneralTab, "Random Enabled", "Enable/disable random", Config.RandomEnabled, function(v)
    Config.RandomEnabled = v
    if not v then
        pcall(function()
            local frontFrame = game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
            local slot1 = frontFrame and frontFrame:FindFirstChild("1")
            local slot2 = frontFrame and frontFrame:FindFirstChild("2")
            if slot1 and slot1:IsA("ImageLabel") and slot2 and slot2:IsA("ImageLabel") then
                local img2 = slot2.Image
                if img2 and img2 ~= "" then
                    slot1.Image = img2
                end
            end
        end)
    end
    State.totalPages = calculateTotalPages()
    if State.currentPage > State.totalPages then
        State.currentPage = State.totalPages
    end
    updatePageDisplay()
    updateEmotes()
    SaveConfig()
end)

CleanFavItem = SettingsLib.AddItem(GeneralTab, "Clean Deleted Favorites", "Scan all favorites (emotes + animations) and remove any that were deleted (click twice)")
CleanFavItem.LayoutOrder = 10
CleanFavBtn = SettingsLib:Create("TextButton", {
    Parent = CleanFavItem,
    BackgroundColor3 = Color3.fromRGB(220, 60, 60),
    Position = UDim2.new(1, -90, 0.5, -12),
    Size = UDim2.new(0, 80, 0, 24),
    Font = Enum.Font.GothamBold,
    Text = "CLEAN",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 11
}, { SettingsLib:Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })

cleanFavConfirm = false
cleanFavConfirmConn = nil
cleanFavCleaning = false

function resetCleanButton()
    cleanFavConfirm = false
    if cleanFavConfirmConn then
        pcall(function() cleanFavConfirmConn:Cancel() end)
        cleanFavConfirmConn = nil
    end
    if CleanFavBtn and CleanFavBtn.Parent then
        CleanFavBtn.Text = "CLEAN"
        CleanFavBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60)
    end
end

cleanDeletedFavorites = nil

cleanDeletedFavorites = function()
    if cleanFavCleaning then return end
    cleanFavCleaning = true

    local emoteIds = {}
    local animIds = {}

    local emotePages = (State.EmotePages and State.EmotePages.Sets) or {}
    for _, favList in pairs(emotePages) do
        if type(favList) == "table" then
            for _, fav in ipairs(favList) do
                if fav and fav.id and tonumber(fav.id) and tonumber(fav.id) > 0 then
                    emoteIds[tostring(fav.id)] = true
                end
            end
        end
    end

    for _, fav in ipairs(State.favoriteAnimations or {}) do
        if fav and fav.id and not fav.isCustomSet and tonumber(fav.id) and tonumber(fav.id) > 0 then
            animIds[tostring(fav.id)] = true
        end
    end

    local emoteIdList = {}
    for id in pairs(emoteIds) do table.insert(emoteIdList, id) end
    local animIdList = {}
    for id in pairs(animIds) do table.insert(animIdList, id) end

    local totalChecks = #emoteIdList + #animIdList
    if totalChecks == 0 then
        emotesDarkExecutorEnv().Notify({ Title = "Dark | Clean", Content = "No favorites to check!", Duration = 3 })
        cleanFavCleaning = false
        resetCleanButton()
        return
    end

    emotesDarkExecutorEnv().Notify({ Title = "Dark | Clean", Content = "Checking " .. totalChecks .. " favorites...", Duration = 3 })

    local deletedEmotes = {}
    local deletedAnims = {}
    local checked = 0

    local function updateProgress()
        if CleanFavBtn and CleanFavBtn.Parent then
            CleanFavBtn.Text = math.floor((checked / totalChecks) * 100) .. "%"
        end
    end

    local function checkBatch(ids, isBundle, deletedOut)
        local url
        if isBundle then
            url = "https://thumbnails.roblox.com/v1/bundles/thumbnails?bundleIds=" .. table.concat(ids, ",") .. "&size=420x420&format=Png"
        else
            url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. table.concat(ids, ",") .. "&size=420x420&format=Png"
        end
        local body = fetchBinary(url)
        local parsed = nil
        if body and #body > 0 then
            pcall(function()
                parsed = HttpService:JSONDecode(body)
            end)
        end
        if parsed and parsed.data and type(parsed.data) == "table" then
            for _, entry in ipairs(parsed.data) do
                local targetId = tostring(entry.targetId)
                if entry.state == "Blocked" or entry.state == "Error" or not entry.imageUrl or entry.imageUrl == "" then
                    deletedOut[targetId] = true
                end
            end
        end
        task.wait(0.05)
    end

    local BATCH = 50
    for i = 1, #emoteIdList, BATCH do
        local chunk = {}
        for j = i, math.min(i + BATCH - 1, #emoteIdList) do table.insert(chunk, emoteIdList[j]) end
        checkBatch(chunk, false, deletedEmotes)
        checked = checked + #chunk
        updateProgress()
    end
    for i = 1, #animIdList, BATCH do
        local chunk = {}
        for j = i, math.min(i + BATCH - 1, #animIdList) do table.insert(chunk, animIdList[j]) end
        checkBatch(chunk, true, deletedAnims)
        checked = checked + #chunk
        updateProgress()
    end

    local removedEmotes = 0
    for pageName, favList in pairs(emotePages) do
        if type(favList) == "table" then
            local newList = {}
            for _, fav in ipairs(favList) do
                if fav and fav.id and deletedEmotes[tostring(fav.id)] then
                    removedEmotes = removedEmotes + 1
                else
                    table.insert(newList, fav)
                end
            end
            State.EmotePages.Sets[pageName] = newList
        end
    end

    local removedAnims = 0
    local newAnims = {}
    for _, fav in ipairs(State.favoriteAnimations or {}) do
        if fav and fav.id and not fav.isCustomSet and deletedAnims[tostring(fav.id)] then
            removedAnims = removedAnims + 1
        else
            table.insert(newAnims, fav)
        end
    end
    State.favoriteAnimations = newAnims

    State.favoriteEmotes = DeepCopy(State.EmotePages.Sets[State.currentEmotePageName] or {}) or {}
    State.favoriteEmoteSet = {}
    for _, fav in pairs(State.favoriteEmotes) do
        State.favoriteEmoteSet[tostring(fav.id)] = true
    end
    State.favoriteAnimationSet = {}
    for _, fav in pairs(State.favoriteAnimations) do
        State.favoriteAnimationSet[tostring(fav.id)] = true
    end
    State.favoriteSetVersion = State.favoriteSetVersion + 1

    State.SaveEmotePages(State.EmotePages)
    pcall(function()
        if not isfolder("dark") then makefolder("dark") end
        writefile(State.favoriteAnimationsFileName, HttpService:JSONEncode(State.favoriteAnimations))
    end)

    _G.filteredFavoritesForDisplay = nil
    _G.filteredFavoritesAnimationsForDisplay = nil

    State.totalPages = calculateTotalPages()
    if State.currentPage > State.totalPages then
        State.currentPage = State.totalPages
    end
    updatePageDisplay()
    if State.currentMode == "animation" then
        updateAnimations()
    else
        updateEmotes()
    end
    updateAllFavoriteIcons()

    for _, fav in pairs(State.favoriteEmotes) do
        if fav and fav.id then
            preloadThumbnail("rbxthumb://type=Asset&id=" .. tostring(fav.id) .. "&w=420&h=420")
        end
    end
    for _, fav in pairs(State.favoriteAnimations) do
        if fav and fav.id and not fav.isCustomSet then
            preloadThumbnail("rbxthumb://type=BundleThumbnail&id=" .. tostring(fav.id) .. "&w=420&h=420")
        end
    end

    local cleanUpToken = State.imageUpdateToken
    task.delay(0.35, function()
        if State.imageUpdateToken ~= cleanUpToken then return end
        updatePageDisplay()
        if State.currentMode == "animation" then
            updateAnimations()
        else
            updateEmotes()
        end
        updateAllFavoriteIcons()
    end)

    emotesDarkExecutorEnv().Notify({
        Title = "Dark | Cleaned",
        Content = "Removed " .. removedEmotes .. " deleted emote" .. (removedEmotes == 1 and "" or "s") .. " & " .. removedAnims .. " deleted animation" .. (removedAnims == 1 and "" or "s"),
        Duration = 5
    })
    cleanFavCleaning = false
    resetCleanButton()
end

CleanFavBtn.MouseButton1Click:Connect(function()
    if cleanFavCleaning then return end
    if not cleanFavConfirm then
        cleanFavConfirm = true
        CleanFavBtn.Text = "CONFIRM?"
        CleanFavBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
        if cleanFavConfirmConn then
            pcall(function() cleanFavConfirmConn:Cancel() end)
        end
        cleanFavConfirmConn = task.delay(3, resetCleanButton)
        return
    end
    resetCleanButton()
    CleanFavBtn.Text = "0%"
    CleanFavBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 90)
    task.spawn(cleanDeletedFavorites)
end)

ButtonsTab = SettingsLib.CreateTab("Buttons", 2)

TogglesUI.SearchVisible = SettingsLib.AddToggle(ButtonsTab, "Search Bar", "Show/Hide the search input", Config.SearchVisible, function(v)
    Config.SearchVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.FavVisible = SettingsLib.AddToggle(ButtonsTab, "Favorites Button", "Show/Hide the star button", Config.FavVisible, function(v)
    Config.FavVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.ModeVisible = SettingsLib.AddToggle(ButtonsTab, "Mode Switcher", "Show/Hide animation mode button", Config.ModeVisible, function(v)
    Config.ModeVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.FreezeVisible = SettingsLib.AddToggle(ButtonsTab, "Freeze Button", "Show/Hide emote freeze button", Config.FreezeVisible, function(v)
    Config.FreezeVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.SpeedVisible = SettingsLib.AddToggle(ButtonsTab, "Speed Button", "Show/Hide the speed controller", Config.SpeedVisible, function(v)
    Config.SpeedVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.NavVisible = SettingsLib.AddToggle(ButtonsTab, "Page Controls", "Show/Hide navigation buttons", Config.NavVisible, function(v)
    Config.NavVisible = v
    ApplyUIVisibility()
    SaveConfig()
end)

TogglesUI.DiscordVisible = SettingsLib.AddToggle(ButtonsTab, "Discord Button", "Show/Hide the discord link button", Config.DiscordVisible, function(v)
    Config.DiscordVisible = v
    syncDiscordVisibility()
    SaveConfig()
end)

TogglesUI.BugReportVisible = SettingsLib.AddToggle(ButtonsTab, "Bug Report Button", "Show/Hide the bug report button", Config.BugReportVisible, function(v)
    Config.BugReportVisible = v
    syncBugReportVisibility()
    SaveConfig()
end)


cachedOverlay = nil
hudEditorItem = SettingsLib.AddItem(ButtonsTab, "HUD Editor", "Reposition buttons & UI elements")
hudEditorItem.LayoutOrder = -10
hudEditorBtn = SettingsLib:Create("TextButton", {
    Parent = hudEditorItem,
    BackgroundColor3 = Color3.fromRGB(0, 255, 150),
    Position = UDim2.new(1, -80, 0.5, -12),
    Size = UDim2.new(0, 70, 0, 24),
    Font = Enum.Font.GothamBold,
    Text = "EDIT",
    TextColor3 = Color3.fromRGB(24, 25, 28),
    TextSize = 11
}, { SettingsLib:Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })

hudEditorBtn.MouseButton1Click:Connect(function()
    if enterHUDEditor then enterHUDEditor() end
end)
function getBackgroundOverlay()
    if cachedOverlay and cachedOverlay.Parent then return cachedOverlay end
    
    local success, result = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Back.Background
                   .BackgroundCircleOverlay
    end)
    if success and result then
        cachedOverlay = result
        return result
    end
    return nil
end

function DeepCopy(t)
    local copy = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            copy[k] = DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

ApplyFavoriteButtonVisual = nil
function updateGUIColors()
    local backgroundOverlay = getBackgroundOverlay()
    if not backgroundOverlay then
        return
    end

    local theme = State.EmoteTheme
    if not theme then return end
    
    local bgColor = theme.Background
    local accentColor = theme.Accent
    local imgColor = theme.ImageColor
    local bgTransparency = backgroundOverlay.BackgroundTransparency

    local function getIconColor(key)
        if theme.IconColors and theme.IconColors[key] then
            return TableToColor(theme.IconColors[key])
        end
        return imgColor
    end

    if UI._1left then
        UI._1left.ImageColor3 = getIconColor("Left")
        UI._1left.ImageTransparency = bgTransparency
        UI._1left.BackgroundTransparency = 1 
    end

    if UI._9right then
        UI._9right.ImageColor3 = getIconColor("Right")
        UI._9right.ImageTransparency = bgTransparency
        UI._9right.BackgroundTransparency = 1
    end

    if UI._4pages then
        UI._4pages.TextColor3 = bgColor 
        UI._4pages.TextTransparency = bgTransparency
    end

    if UI._3TextLabel then
        UI._3TextLabel.TextColor3 = bgColor
        UI._3TextLabel.TextTransparency = bgTransparency
    end

    if UI._2Routenumber then
        UI._2Routenumber.TextColor3 = bgColor
        UI._2Routenumber.PlaceholderColor3 = bgColor
        UI._2Routenumber.TextTransparency = bgTransparency
    end

    if UI.Under then
        UI.Under.BackgroundTransparency = 1
    end

    if UI.Top then
        UI.Top.BackgroundColor3 = bgColor
        UI.Top.BackgroundTransparency = bgTransparency
    end

    if UI.EmoteWalkButton then
        UI.EmoteWalkButton.BackgroundColor3 = bgColor
        UI.EmoteWalkButton.BackgroundTransparency = bgTransparency
    end

    if UI.CustomFrames then
        for _, frame in pairs(UI.CustomFrames) do
            frame.BackgroundColor3 = bgColor
            frame.BackgroundTransparency = bgTransparency
        end
    end

    if UI.SpeedEmote then
        UI.SpeedEmote.BackgroundColor3 = bgColor
        UI.SpeedEmote.BackgroundTransparency = bgTransparency
    end

     if UI.Changepage then
        UI.Changepage.BackgroundColor3 = bgColor
        UI.Changepage.BackgroundTransparency = bgTransparency
    end

    if UI.SpeedBox then
        UI.SpeedBox.BackgroundColor3 = bgColor
        UI.SpeedBox.BackgroundTransparency = bgTransparency
    end

    if UI.Favorite then
        UI.Favorite.BackgroundColor3 = bgColor
        UI.Favorite.BackgroundTransparency = bgTransparency
    end

    if UI.FavoritesTab then
        UI.FavoritesTab.BackgroundColor3 = bgColor
        UI.FavoritesTab.BackgroundTransparency = bgTransparency
        UI.FavoritesTab.Image = State.favoriteIconId
        UI.FavoritesTab.ImageColor3 = Color3.fromHSV((tick() * FAVORITE_STAR_RGB_SPEED) % 1, 1, 1)
    end

    if UI.Reload then
        UI.Reload.BackgroundColor3 = bgColor
        UI.Reload.BackgroundTransparency = bgTransparency
    end
    
    if ApplyFavoriteButtonVisual then
        ApplyFavoriteButtonVisual()
    end

    local function applyHUDProperties()
        if not Config.HUDProperties then return end
        local allMovable = getAllHUDObjects()
        for name, uiExt in pairs(allMovable) do
            local props = Config.HUDProperties[name]
            if props then
                if props.ZIndex ~= nil then pcall(function() uiExt.ZIndex = props.ZIndex end) end
                if props.BgTrans ~= nil then pcall(function() uiExt.BackgroundTransparency = props.BgTrans end) end
                if props.ImgTrans ~= nil and (uiExt:IsA("ImageLabel") or uiExt:IsA("ImageButton")) then pcall(function() uiExt.ImageTransparency = props.ImgTrans end) end
                if props.BgColor and type(props.BgColor) == "table" then
                    local r, g, b = props.BgColor[1], props.BgColor[2], props.BgColor[3]
                    if r and g and b and not isThemeDefaultRGB(r, g, b) then
                        pcall(function() uiExt.BackgroundColor3 = Color3.fromRGB(r, g, b) end)
                    end
                end
                if props.ImgColor and type(props.ImgColor) == "table" and (uiExt:IsA("ImageLabel") or uiExt:IsA("ImageButton")) then
                    local r, g, b = props.ImgColor[1], props.ImgColor[2], props.ImgColor[3]
                    if r and g and b and not isThemeDefaultRGB(r, g, b) then
                        pcall(function() uiExt.ImageColor3 = Color3.fromRGB(r, g, b) end)
                    end
                end
                if props.TxtColor and type(props.TxtColor) == "table" and (uiExt:IsA("TextLabel") or uiExt:IsA("TextBox")) then
                    local r, g, b = props.TxtColor[1], props.TxtColor[2], props.TxtColor[3]
                    if r and g and b and not isThemeDefaultRGB(r, g, b) then
                        pcall(function() uiExt.TextColor3 = Color3.fromRGB(r, g, b) end)
                    end
                end
                if props.Radius and uiExt:FindFirstChildWhichIsA("UICorner") then
                    local s1, o1 = props.Radius:match("{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}")
                    if s1 then pcall(function() uiExt:FindFirstChildWhichIsA("UICorner").CornerRadius = UDim.new(tonumber(s1), tonumber(o1)) end) end
                end
            end
        end
    end
    
    applyHUDProperties()
    ApplyUIVisibility()
    applySettingsToggleStyle()
end

ApplyFavoriteButtonVisual = function()
    if not UI.Favorite then return end
    local isOn = State.favoriteEnabled
    local image = isOn and State.favoriteIconId or State.notFavoriteIconId
    if image and image ~= "" then
        UI.Favorite.Image = image
    end
    local colorKey = isOn and "Favorite" or "NotFavorite"
    UI.Favorite.ImageColor3 = AnimationSystem.GetIconColor(colorKey)
end

-- Optimizing performance: Removed RenderStepped loop
-- game:GetService("RunService").RenderStepped:Connect(function()
--     updateGUIColors()
-- end)

ThemeTab = SettingsLib.CreateTab("Theme", 3)

DiscordPromo = SettingsLib.AddItem(ThemeTab, "WANT THEMES?", "Join our Discord for themes!")
DiscordPromo.LayoutOrder = -1

CopyBtn = SettingsLib:Create("TextButton", {
    Parent = DiscordPromo,
    BackgroundColor3 = Color3.fromRGB(0, 255, 150),
    Position = UDim2.new(1, -95, 0.5, -12),
    Size = UDim2.new(0, 85, 0, 24),
    Font = Enum.Font.GothamBold,
    Text = "COPY LINK",
    TextColor3 = Color3.fromRGB(24, 25, 28),
    TextSize = 11
}, { SettingsLib:Create("UICorner", {CornerRadius = UDim.new(0, 6)}) })

CopyBtn.MouseButton1Click:Connect(function()
    setclipboard("https://discord.gg/MVgAr2YYj4")
    emotesDarkExecutorEnv().Notify({Title = "Discord", Content = "Link copied to clipboard!", Duration = 3})
end)

ThemeConfigPath = "dark/EmoteThemes.json"

lastSaveTime = 0
saveDebounce = 1
pendingSave = false

function SaveThemesImplementation(themes)
    if not isfolder("dark") then makefolder("dark") end
    local toSave = { Themes = {}, Order = {}, Selected = themes.Selected or AnimationSystem.currentThemeName }
    
    toSave.Order = themes.Order or {}
    
    for name, data in pairs(themes) do
        if name ~= "Default" and name ~= "Order" and name ~= "Selected" then
            toSave.Themes[name] = data
        end
    end
    writefile(ThemeConfigPath, HttpService:JSONEncode(toSave))
end

function SaveThemes(themes)
    if pendingSave then 
        pendingSave = "queued"
        return 
    end
    pendingSave = true
    task.delay(0.5, function()
        SaveThemesImplementation(themes)
        local wasQueued = pendingSave == "queued"
        pendingSave = false
        if wasQueued then
            SaveThemes(themes)
        end
    end)
end

function LoadThemes()
    local defaultTheme = {
        Background = {28, 30, 32},
        Accent = {0, 255, 150},
        ImageColor = {255, 255, 255},
        IconColors = {
            Left = {0, 0, 0},
            Right = {0, 0, 0}
        },
        Icons = {
            Left = "93111945058621",
            Right = "107938916240738",
            Walk = "71408678974152",
            Favorite = "97307461910825",
            NotFavorite = "124025954365505",
            Speed = "116056570415896",
            Page = "13285615740",
            Reload = "127493377027615"
        },
        Wheel = {
            BackgroundImage = "rbxasset://textures/ui/Emotes/Large/SegmentedCircle.png",
            BackgroundImageColor = {255, 255, 255},
            SelectionGradient = "rbxasset://textures/ui/Emotes/Large/SelectedGradient.png",
            SelectionGradientColor = {255, 255, 255},
            SelectionLine = "rbxasset://textures/ui/Emotes/Large/SelectedLine.png",
            SelectionLineColor = {255, 255, 255}
        }
    }

    local halloweenTheme = DeepCopy(defaultTheme)
    halloweenTheme.Background = {20, 10, 31}
    halloweenTheme.Accent = {255, 124, 42}
    halloweenTheme.ImageColor = {255, 232, 207}
    halloweenTheme.IconColors = { Left = {255, 165, 78}, Right = {255, 165, 78} }
    halloweenTheme.Wheel.BackgroundImageColor = {168, 119, 206}
    halloweenTheme.Wheel.SelectionGradientColor = {255, 128, 43}
    halloweenTheme.Wheel.SelectionLineColor = {255, 219, 158}

    local loaded = { Default = defaultTheme, Halloween = halloweenTheme, Order = {"Default", "Halloween"} }
    if isfile(ThemeConfigPath) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(ThemeConfigPath)) end)
        if success and type(decoded) == "table" then
            local themesTable = decoded.Themes or decoded 
            local orderTable = decoded.Order or {}
            
            for name, data in pairs(themesTable) do
                if not data.Icons then data.Icons = DeepCopy(defaultTheme.Icons) end
                if not data.Wheel then data.Wheel = DeepCopy(defaultTheme.Wheel) end
                loaded[name] = data
                
                if name == "Default" then
                    if not data.IconColors then data.IconColors = {} end
                    data.IconColors.Left = {0, 0, 0}
                    data.IconColors.Right = {0, 0, 0}
                end
                if not decoded.Order and name ~= "Default" and name ~= "Halloween" and not table.find(loaded.Order, name) then
                    table.insert(loaded.Order, name)
                end
            end
            
            if decoded.Order then
                loaded.Order = {"Default", "Halloween"}
                for _, name in ipairs(decoded.Order) do
                    if name ~= "Default" and name ~= "Halloween" and loaded[name] and not table.find(loaded.Order, name) then
                        table.insert(loaded.Order, name)
                    end
                end
            end
            
            if decoded.Selected and loaded[decoded.Selected] then
                loaded.Selected = decoded.Selected
            end

            loaded.Default = DeepCopy(defaultTheme)
            loaded.Halloween = DeepCopy(halloweenTheme)
            return loaded
        end
    end
    return loaded
end

State.pendingCustomAnimSave = false
State.SaveCustomAnimationsImplementation = function(animData)
    if not isfolder("dark") then makefolder("dark") end
    local toSave = { Sets = {}, Order = animData.Order or {"Default"}, Selected = animData.Selected or "Default" }
    for name, data in pairs(animData.Sets) do
        if name ~= "Default" then
            toSave.Sets[name] = data
        end
    end
    writefile(State.CustomAnimationPath, HttpService:JSONEncode(toSave))
end

State.SaveCustomAnimations = function(animData)
    if State.pendingCustomAnimSave then
        State.pendingCustomAnimSave = "queued"
        return
    end
    State.pendingCustomAnimSave = true
    task.delay(0.5, function()
        State.SaveCustomAnimationsImplementation(animData)
        local wasQueued = State.pendingCustomAnimSave == "queued"
        State.pendingCustomAnimSave = false
        if wasQueued then State.SaveCustomAnimations(animData) end
    end)
end

State.LoadCustomAnimations = function()
    local defaultAnim = {
        idle = { Animation1 = 0, Animation2 = 0 },
        walk = { WalkAnim = 0 },
        run = { RunAnim = 0 },
        jump = { JumpAnim = 0 },
        fall = { FallAnim = 0 },
        climb = { ClimbAnim = 0 },
        swimidle = { SwimIdle = 0 },
        swim = { Swim = 0 },
        __meta = { IconImage = DEFAULT_IDLE_ICON_ID, IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) }
    }
    local loaded = { Sets = { Default = defaultAnim }, Order = {"Default"}, Selected = "Default" }
    
    if isfile(State.CustomAnimationPath) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(State.CustomAnimationPath)) end)
        if success and type(decoded) == "table" then
            local setsTable = decoded.Sets or {}
            for name, data in pairs(setsTable) do
                loaded.Sets[name] = data
            end
            
            if decoded.Order then
                loaded.Order = {"Default"}
                for _, name in ipairs(decoded.Order) do
                    if name ~= "Default" and loaded.Sets[name] then
                        table.insert(loaded.Order, name)
                    end
                end
            end
            
            if decoded.Selected and loaded.Sets[decoded.Selected] then
                loaded.Selected = decoded.Selected
            end
        end
    end
    
    return loaded
end

State.SaveEmotePages = function(pageData)
    if not isfolder("dark") then makefolder("dark") end
    local toSave = { 
        Sets = {}, 
        Order = pageData.Order or {"Default"}, 
        Selected = pageData.Selected or "Default" 
    }
    for name, data in pairs(pageData.Sets) do
        if name ~= "Default" then
            toSave.Sets[name] = data
        end
    end
    writefile(State.EmotePagePath, HttpService:JSONEncode(toSave))
    
    if pageData.Sets["Default"] then
        writefile(State.favoriteFileName, HttpService:JSONEncode(pageData.Sets["Default"]))
    end
end

function SwitchEmotePage(pageName)
    if not State.EmotePages.Sets[pageName] then return end
    
    State.currentEmotePageName = pageName
    State.EmotePages.Selected = pageName
    
    local pageData = State.EmotePages.Sets[pageName]
    State.favoriteEmotes = DeepCopy(pageData) or {}
    
    State.favoriteEmoteSet = {}
    for _, fav in pairs(State.favoriteEmotes) do
        State.favoriteEmoteSet[tostring(fav.id)] = true
    end
    
    State.favoriteSetVersion = State.favoriteSetVersion + 1
    State.totalPages = calculateTotalPages()
    if State.currentPage > State.totalPages then
        State.currentPage = State.totalPages
    end
    
    updatePageDisplay()
    if State.currentMode == "emote" then
        updateEmotes()
    end
    updateAllFavoriteIcons()
end

State.LoadEmotePages = function()
    local defaultFavorites = {}
    
    if isfile(State.favoriteFileName) then
        local ok, decoded = pcall(function() return HttpService:JSONDecode(readfile(State.favoriteFileName)) end)
        if ok and type(decoded) == "table" then
            defaultFavorites = decoded
        end
    end

    local loaded = { Sets = { Default = defaultFavorites }, Order = {"Default"}, Selected = "Default" }
    
    if isfile(State.EmotePagePath) then
        local success, decoded = pcall(function() return HttpService:JSONDecode(readfile(State.EmotePagePath)) end)
        if success and type(decoded) == "table" then
            local setsTable = decoded.Sets or {}
            for name, data in pairs(setsTable) do
                if name ~= "Default" then
                    loaded.Sets[name] = data
                end
            end
            
            if decoded.Order then
                loaded.Order = {"Default"}
                for _, name in ipairs(decoded.Order) do
                    if name ~= "Default" and loaded.Sets[name] then
                        table.insert(loaded.Order, name)
                    end
                end
            end
            
            if decoded.Selected and (loaded.Sets[decoded.Selected] or decoded.Selected == "Default") then
                loaded.Selected = decoded.Selected
            end
        end
    end
    
    return loaded
end

State.EmotePages = State.LoadEmotePages()
State.currentEmotePageName = State.EmotePages.Selected or "Default"
if not State.EmotePages.Sets[State.currentEmotePageName] then 
    State.currentEmotePageName = "Default" 
end

State.favoriteEmotes = DeepCopy(State.EmotePages.Sets[State.currentEmotePageName]) or {}
State.favoriteEmoteSet = {}
for _, fav in pairs(State.favoriteEmotes) do
    State.favoriteEmoteSet[tostring(fav.id)] = true
end

State.favoriteAnimations = {}
pcall(function()
    if isfile and isfile(State.favoriteAnimationsFileName) then
        local json = readfile(State.favoriteAnimationsFileName)
        local decoded = HttpService:JSONDecode(json)
        if type(decoded) == "table" then
            State.favoriteAnimations = decoded
        end
    end
end)
State.favoriteAnimationSet = {}
for _, fav in pairs(State.favoriteAnimations) do
    State.favoriteAnimationSet[tostring(fav.id)] = true
end


State.CustomAnimations = State.LoadCustomAnimations()
State.currentCustomAnimationName = State.CustomAnimations.Selected or "Default"
if not State.CustomAnimations.Sets[State.currentCustomAnimationName] then 
    State.currentCustomAnimationName = "Default" 
end

themes = LoadThemes()
currentThemeName = Config.SelectedTheme or themes.Selected or "Halloween"
if not themes[currentThemeName] then currentThemeName = "Halloween" end

themeDropdown = nil

function GetNames()
    local n = {}
    if themes.Order then
        for _, name in ipairs(themes.Order) do
            if name ~= "Order" and name ~= "Selected" and themes[name] then 
                table.insert(n, name) 
            end
        end
    end
    for name, _ in pairs(themes) do
        if name ~= "Order" and name ~= "Selected" and not table.find(n, name) then
            table.insert(n, name)
        end
    end
    return n
end

UIElements = {
    Background = {},
    Accent = {},
    ImageColor = {},
    Icons = {},
    Wheel = {}
}

function ApplyWheelBackgroundImage(bgImg, wheel)
    if not bgImg or not wheel then return end
    local bgSrc = wheel.BackgroundImage or ""
    local isCustomBg = tostring(bgSrc) ~= DEFAULT_WHEEL_BG

    local gifUrl, sheetUrl = nil, nil
    if bgSrc and tostring(bgSrc):find("\n") then
        local lines = {}
        for line in tostring(bgSrc):gmatch("[^\r\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line ~= "" then table.insert(lines, line) end
        end
        gifUrl = lines[1]
        sheetUrl = lines[2]
    elseif tostring(bgSrc):find("|") then
        local parts = {}
        for part in tostring(bgSrc):gmatch("[^|]+") do
            part = part:match("^%s*(.-)%s*$")
            if part ~= "" then table.insert(parts, part) end
        end
        gifUrl = parts[1]
        sheetUrl = parts[2]
    elseif AnimationSystem.LooksLikeGif(bgSrc) then
        gifUrl = bgSrc
    end
 
    local targetUrl = AnimationSystem.NormalizeUrl(bgSrc)
    if gifUrl then gifUrl = AnimationSystem.NormalizeUrl(gifUrl) end
    if sheetUrl then sheetUrl = AnimationSystem.NormalizeUrl(sheetUrl) end
 
    if gifUrl and sheetUrl and sheetUrl ~= "" then
        if gifUrl:lower():find("%.png") and (sheetUrl:lower():find("%.gif") or sheetUrl:lower():find("format=gif")) then
            local temp = gifUrl
            gifUrl = sheetUrl
            sheetUrl = temp
        end

        local cacheKey = AnimationSystem.MakeKey(gifUrl, sheetUrl)
        local meta = wheel.Animation
        if meta and meta.GifUrl == gifUrl and meta.SheetUrl == sheetUrl then
            AnimationSystem.Cache[cacheKey] = meta
        else
            meta = AnimationSystem.Cache[cacheKey]
        end
 
        if meta and meta.Enabled == true then
            if (meta.FrameWidth or 0) > 0 and (meta.FrameHeight or 0) > 0 then
                local frames = tonumber(meta.Frames) or 0
                local cols = tonumber(meta.Cols) or 0
                local rows = tonumber(meta.Rows) or 0
                local frameW = tonumber(meta.FrameWidth) or 0
                local frameH = tonumber(meta.FrameHeight) or 0
                local fps = tonumber(meta.FPS) or 10
                local delay = fps > 0 and (1 / fps) or 0.1
                local rawSheetW = tonumber(meta.SheetWidth) or (cols * frameW)
                local rawSheetH = tonumber(meta.SheetHeight) or (rows * frameH)
                local sheetAsset = GetAsset(sheetUrl)
                if sheetAsset and sheetAsset ~= "" and not sheetAsset:find("^https?://") then
                    local resizedW, resizedH = estimateRobloxResizedSize(rawSheetW, rawSheetH)
                    local adjFrameW = frameW * (resizedW / rawSheetW)
                    local adjFrameH = frameH * (resizedH / rawSheetH)

                    local spriteData = {
                        sprite = sheetAsset,
                        frames = frames,
                        frameW = adjFrameW,
                        frameH = adjFrameH,
                        cols = cols,
                        rows = rows,
                        sheetW = resizedW,
                        sheetH = resizedH,
                        delay = delay
                    }
                    AnimationSystem.SetImageMode(bgImg, true)
                    AnimationSystem.StartGif(bgImg, spriteData)
                    return
                end
            end
        end

        task.spawn(function()
            local gifBytes = fetchBinary(gifUrl)
            local gifInfo = gifBytes and AnimationSystem.ParseGifInfo(gifBytes) or nil

            local sheetBytes = fetchBinary(sheetUrl)
            local sheetInfo = sheetBytes and AnimationSystem.ParsePngInfo(sheetBytes) or nil
            local sheetAsset = GetAsset(sheetUrl, sheetBytes)

            if gifInfo and sheetInfo and sheetAsset and sheetAsset ~= "" and not sheetAsset:find("^https?://") then
                local frameW = gifInfo.width
                local frameH = gifInfo.height
                local cols = math.max(1, math.floor(sheetInfo.width / frameW + 0.0001))
                local rows = math.max(1, math.floor(sheetInfo.height / frameH + 0.0001))
                local maxFrames = cols * rows
                local frames = math.min(gifInfo.frames or maxFrames, maxFrames)
                local fps = (gifInfo.avgDelayCs and gifInfo.avgDelayCs > 0) and (100 / gifInfo.avgDelayCs) or 10

                local resizedW, resizedH = estimateRobloxResizedSize(sheetInfo.width, sheetInfo.height)
                local scaleX = resizedW / sheetInfo.width
                local scaleY = resizedH / sheetInfo.height
                local adjFrameW = frameW * scaleX
                local adjFrameH = frameH * scaleY

                local spriteData = {
                    sprite = sheetAsset,
                    frames = frames,
                    frameW = adjFrameW,
                    frameH = adjFrameH,
                    cols = cols,
                    rows = rows,
                    sheetW = resizedW,
                    sheetH = resizedH,
                    gifInfo = gifInfo
                }

                local newMeta = {
                    Enabled = true,
                    FrameWidth = frameW,
                    FrameHeight = frameH,
                    FPS = math.floor(fps + 0.5),
                    Frames = frames,
                    Cols = cols,
                    Rows = rows,
                    SheetWidth = sheetInfo.width,
                    SheetHeight = sheetInfo.height,
                    GifUrl = gifUrl,
                    SheetUrl = sheetUrl
                }
                wheel.Animation = newMeta
                AnimationSystem.Cache[cacheKey] = newMeta
                if AnimationSystem.currentThemeName and AnimationSystem.currentThemeName ~= "Default" then
                    SaveThemes(themes)
                end

                AnimationSystem.SetImageMode(bgImg, true)
                AnimationSystem.StartGif(bgImg, spriteData)
                return
            else
                AnimationSystem.StopGif()
                AnimationSystem.SetImageMode(bgImg, isCustomBg)
                local fallback = GetAsset(sheetUrl, sheetBytes)
                if fallback and fallback ~= "" and not fallback:find("^https?://") then
                    bgImg.Image = fallback
                else
                    bgImg.Image = DEFAULT_WHEEL_BG
                end
                bgImg.ImageRectSize = Vector2.new(0, 0)
                bgImg.ImageRectOffset = Vector2.new(0, 0)
            end
        end)
        return
    end
 
    AnimationSystem.StopGif()
    AnimationSystem.SetImageMode(bgImg, isCustomBg)
    bgImg.Image = GetAsset(targetUrl)
    bgImg.ImageRectSize = Vector2.new(0, 0)
    bgImg.ImageRectOffset = Vector2.new(0, 0)
end

function ApplyTheme(themeData)
    if not themeData then
        warn("Dark | ApplyTheme: themeData is nil. Falling back to Default.")
        themeData = themes and themes["Default"] or nil
        if not themeData then return end
    end
    if State.isApplyingTheme then
        State.pendingThemeData = themeData
        return
    end
    
    State.isApplyingTheme = true
    State.pendingThemeData = nil
    
    local ok, err = pcall(function()
        if themeData.Background then
            State.EmoteTheme = {
                Background = TableToColor(themeData.Background),
                Accent = TableToColor(themeData.Accent or {0, 255, 150}),
                ImageColor = TableToColor(themeData.ImageColor or {255, 255, 255}),
                Icons = themeData.Icons or {},
                IconColors = themeData.IconColors or {},
                Wheel = themeData.Wheel or {}
            }
            
            local function getIconColor(key)
                if State.EmoteTheme.IconColors and State.EmoteTheme.IconColors[key] then
                    return TableToColor(State.EmoteTheme.IconColors[key])
                end
                return State.EmoteTheme.ImageColor 
            end
            
            State.favoriteIconId = GetAsset(State.EmoteTheme.Icons.Favorite)
            State.notFavoriteIconId = GetAsset(State.EmoteTheme.Icons.NotFavorite)
            
            updateGUIColors()
            ApplySettingsLibraryPalette(themeData)
            
            if UI._1left then UI._1left.Image = GetAsset(State.EmoteTheme.Icons.Left); UI._1left.ImageColor3 = getIconColor("Left") end
            if UI._9right then UI._9right.Image = GetAsset(State.EmoteTheme.Icons.Right); UI._9right.ImageColor3 = getIconColor("Right") end
            if UI.EmoteWalkButton then 
                UI.EmoteWalkButton.ImageColor3 = getIconColor("Walk") 
                ApplyFreezeButtonVisual()
            end
            if UI.SpeedEmote then UI.SpeedEmote.Image = GetAsset(State.EmoteTheme.Icons.Speed); UI.SpeedEmote.ImageColor3 = getIconColor("Speed") end
            if UI.Changepage then UI.Changepage.Image = GetAsset(State.EmoteTheme.Icons.Page); UI.Changepage.ImageColor3 = getIconColor("Page") end
            if UI.Reload then UI.Reload.Image = GetAsset(State.EmoteTheme.Icons.Reload); UI.Reload.ImageColor3 = getIconColor("Reload") end
            
            if UI.Favorite then ApplyFavoriteButtonVisual() end 

            
            if UI.Background and UI.Background.Main then UI.Background.Main.SetValue(State.EmoteTheme.Background) end
            
            for key, comp in pairs(UIElements.Icons) do
                local iconVal = State.EmoteTheme.Icons[key] or ""
                local specificColor = State.EmoteTheme.IconColors and State.EmoteTheme.IconColors[key]
                local colorVal
                
                if specificColor then
                    colorVal = TableToColor(specificColor)
                else
                    colorVal = State.EmoteTheme.ImageColor 
                end
                
                if comp then comp.SetValue(iconVal, colorVal) end
            end

            for name, data in pairs(themes) do
                if data == themeData then
                    AnimationSystem.currentThemeName = name
                    break
                end
            end

            local function applyWheel()
                pcall(function()
                    local coreGui = game:GetService("CoreGui")
                    local robloxGui = coreGui:FindFirstChild("RobloxGui")
                    if not robloxGui then return end
                    local emotesMenu = robloxGui:FindFirstChild("EmotesMenu")
                    if not emotesMenu then return end
                    local children = emotesMenu:FindFirstChild("Children")
                    local main = children and children:FindFirstChild("Main")
                    local emotesWheel = main and main:FindFirstChild("EmotesWheel")
                    local back = emotesWheel and emotesWheel:FindFirstChild("Back")
                    local root = back and back:FindFirstChild("Background")
                    if not root then return end
                    
                    local wheel = State.EmoteTheme.Wheel
                    if not wheel then return end

                    local function getAsset(id)
                        return GetAsset(id)
                    end

                    local bgImg = root:FindFirstChild("BackgroundImage")
                    if bgImg then
                        ApplyWheelBackgroundImage(bgImg, wheel)
                        bgImg.ImageColor3 = TableToColor(wheel.BackgroundImageColor or {255,255,255})
                    end

                    local gradContainer = root:FindFirstChild("BackgroundGradient")
                    local selectionGrad = gradContainer and gradContainer:FindFirstChild("SelectionGradient")
                    local grad = selectionGrad and selectionGrad:FindFirstChild("SelectedGradient")
                    if grad then
                        grad.Image = getAsset(wheel.SelectionGradient)
                        grad.ImageColor3 = TableToColor(wheel.SelectionGradientColor or {255,255,255})
                    end

                    local selection = root:FindFirstChild("Selection")
                    local selectionEffect = selection and selection:FindFirstChild("SelectionEffect")
                    local line = selectionEffect and selectionEffect:FindFirstChild("SelectedLine")
                    if line then
                        line.Image = getAsset(wheel.SelectionLine)
                        line.ImageColor3 = TableToColor(wheel.SelectionLineColor or {255,255,255})
                    end
                end)
            end
            applyWheel()

            for key, comp in pairs(UIElements.Wheel) do
                local imgVal = State.EmoteTheme.Wheel[key] or ""
                local colorVal = TableToColor(State.EmoteTheme.Wheel[key.."Color"] or {255, 255, 255})
                if comp then comp.SetValue(imgVal, colorVal) end
            end
        end
    end)
    
    State.isApplyingTheme = false
    
    if not ok then
        warn("Dark | ApplyTheme error: " .. tostring(err))
    end

    local pendingThemeData = State.pendingThemeData
    State.pendingThemeData = nil
    if pendingThemeData and pendingThemeData ~= themeData then
        ApplyTheme(pendingThemeData)
    end
end

checkEmotesMenuExists = function()
    local coreGui = game:GetService("CoreGui")
    local robloxGui = coreGui:FindFirstChild("RobloxGui")
    if not robloxGui then
        return false
    end

    local emotesMenu = robloxGui:FindFirstChild("EmotesMenu")
    if not emotesMenu then
        return false
    end

    local children = emotesMenu:FindFirstChild("Children")
    if not children then
        return false
    end

    local main = children:FindFirstChild("Main")
    if not main then
        return false
    end

    local emotesWheel = main:FindFirstChild("EmotesWheel")
    if not emotesWheel then
        return false
    end

    return true, emotesWheel
end

task.spawn(function()
    local attempts = 0
    while attempts < 30 do
        local exists, emotesWheel = checkEmotesMenuExists()
        if exists and emotesWheel then
            ApplyTheme(themes[currentThemeName])
            
            emotesWheel:GetPropertyChangedSignal("Visible"):Connect(function()
                if emotesWheel.Visible then
                    task.wait(0.05)
                    ApplyTheme(themes[currentThemeName])
                end
            end)
            break
        end
        attempts = attempts + 1
        task.wait(1)
    end
end)

themeDropdown = SettingsLib.AddDropdown(ThemeTab, "Select Theme", GetNames(), currentThemeName, function(v)
    currentThemeName = v
    Config.SelectedTheme = v
    Config.ThemePresetVersion = 1
    themes.Selected = v
    SaveConfig()
    if themes[v] then
        SaveThemes(themes)
        ApplyTheme(themes[v])
    end
end)
if themeDropdown and themeDropdown.Button and themeDropdown.Button.Parent and themeDropdown.Button.Parent.Parent then
   themeDropdown.Button.Parent.Parent.LayoutOrder = 0
end

BtnItem = SettingsLib.AddItem(ThemeTab, "Theme Management", "Manage your themes")
BtnItem.LayoutOrder = 1 
BtnItem.BackgroundColor3 = Color3.fromRGB(35, 38, 42)
BtnItem.Size = UDim2.new(0.95, 0, 0, 70) 

for _, v in pairs(BtnItem:GetChildren()) do if v.Name == "Title" or v.Name == "Desc" then v:Destroy() end end

ManagementContainer = Instance.new("Frame")
ManagementContainer.Parent = BtnItem
ManagementContainer.BackgroundTransparency = 1
ManagementContainer.Size = UDim2.new(1, 0, 1, 0)

Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Horizontal
Layout.Padding = UDim.new(0, 15)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.Parent = ManagementContainer

BtnRow = ManagementContainer 

function CreatePopup(title, size)
    closeOtherScriptWindows("EmotesDarkSettingsPopup")
    local previousPopup = SettingsLib.UI:FindFirstChild("EmotesDarkSettingsPopup")
    if previousPopup then previousPopup:Destroy() end
    local panel = Instance.new("Frame")
    panel.Name = "EmotesDarkSettingsPopup"
    panel.Size = size or UDim2.fromOffset(280, 140)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.BackgroundColor3 = Color3.fromHex("18191c")
    panel.ZIndex = 2000
    panel.Parent = SettingsLib.UI

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = panel

    local stroke = Instance.new("UIStroke")
    stroke.Parent = panel
    stroke.Color = (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5

    local lbl = Instance.new("TextLabel")
    lbl.Parent = panel
    lbl.Size = UDim2.new(1, 0, 0, 35)
    lbl.BackgroundTransparency = 1
    lbl.Text = title:upper()
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextColor3 = Color3.new(1,1,1)
    
    local content = Instance.new("Frame")
    content.Name = "Content"
    content.Parent = panel
    content.BackgroundTransparency = 1
    content.Position = UDim2.new(0, 0, 0, 35)
    content.Size = UDim2.new(1, 0, 1, -35)
    
    return panel, content
end

function CreateInput(parent, placeholder, text, isMulti)
    local box = Instance.new("TextBox")
    box.Size = isMulti and UDim2.new(0.9, 0, 0, 100) or UDim2.new(0.9, 0, 0, 35)
    box.Position = UDim2.new(0.05, 0, 0, 5)
    box.BackgroundColor3 = Color3.fromRGB(35, 38, 41)
    box.TextColor3 = Color3.new(1,1,1)
    box.PlaceholderText = placeholder or ""
    box.Text = text or ""
    box.Font = Enum.Font.Gotham
    box.TextSize = 12
    box.MultiLine = isMulti
    box.TextWrapped = isMulti
    box.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box
    
    return box
end

function CreateButton(parent, text, color, pos, size)
    local btn = Instance.new("TextButton")
    btn.Size = size or UDim2.new(0.4, 0, 0, 32)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = (color.R + color.G + color.B < 1.5) and Color3.new(1,1,1) or Color3.new(0,0,0)
    btn.TextSize = 12
    btn.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
    
    return btn
end

SettingsLib.AddIconButton(BtnRow, "108445456753346", function()
    local popup, content = CreatePopup("Create Theme")
    local In = CreateInput(content, "Theme Name...")
    
    local Save = CreateButton(content, "SAVE", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Cancel.TextColor3 = Color3.new(1,1,1)

    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not themes[In.Text] then
            themes[In.Text] = DeepCopy(themes[currentThemeName])
            if not themes[In.Text].IconColors then themes[In.Text].IconColors = {} end
            table.insert(themes.Order, In.Text)
            
            table.sort(themes.Order, function(a, b)
                if a == "Default" then return true end
                if b == "Default" then return false end
                return a:lower() < b:lower()
            end)
            
            SaveThemes(themes)
            currentThemeName = In.Text
            themeDropdown.Refresh(GetNames())
            themeDropdown.Button.Text = currentThemeName .. "  ▼"
            ApplyTheme(themes[currentThemeName])
            popup:Destroy()
        end
    end)
    
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(BtnRow, "71829270056766", function()
    if currentThemeName ~= "Default" then
        local idx = table.find(themes.Order, currentThemeName)
        if idx then table.remove(themes.Order, idx) end
        
        themes[currentThemeName] = nil
        SaveThemes(themes)
        currentThemeName = "Default"
        themeDropdown.Refresh(GetNames())
        themeDropdown.Button.Text = "Default  ▼"
        ApplyTheme(themes["Default"])
    end
end)

SettingsLib.AddIconButton(BtnRow, "117761881427472", function()
    if currentThemeName == "Default" then return end
    
    local popup, content = CreatePopup("Rename Theme")
    local In = CreateInput(content, "New Name...", currentThemeName)
    
    local Save = CreateButton(content, "RENAME", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Cancel.TextColor3 = Color3.new(1,1,1)

    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not themes[In.Text] then
            local idx = table.find(themes.Order, currentThemeName)
            if idx then themes.Order[idx] = In.Text end
            
            themes[In.Text] = themes[currentThemeName]
            themes[currentThemeName] = nil
            currentThemeName = In.Text
            SaveThemes(themes)
            themeDropdown.Refresh(GetNames())
            themeDropdown.Button.Text = currentThemeName .. "  ▼"
            popup:Destroy()
        end
    end)
    
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(BtnRow, "78317476576895", function()
    local popup, content = CreatePopup("Import Theme", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "Paste Theme JSON here...", "", true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    
    local imp = CreateButton(content, "IMPORT THEME", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

    imp.MouseButton1Click:Connect(function()
        local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
        if s and type(d) == "table" and d.name then
            if d.name == "Default" then
                emotesDarkExecutorEnv().Notify({Title = "Error", Content = "Cannot overwrite 'Default' theme.", Duration = 3})
                return
            end
            if not themes[d.name] then
                table.insert(themes.Order, d.name)
            end
            themes[d.name] = d.data
            SaveThemes(themes)
            themeDropdown.Refresh(GetNames())
            popup:Destroy()
        else
            emotesDarkExecutorEnv().Notify({Title = "Error", Content = "Invalid JSON Format!", Duration = 3})
        end
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(BtnRow, "107588515524752", function()
    local exportData = { name = currentThemeName, data = themes[currentThemeName] }
    local json = HttpService:JSONEncode(exportData)
    
    local popup, content = CreatePopup("Export Theme", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "", json, true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    box.TextEditable = false
    
    local copy = CreateButton(content, "COPY TO CLIPBOARD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

    copy.MouseButton1Click:Connect(function()
        setclipboard(json)
        copy.Text = "COPIED!"
        task.delay(1, function() copy.Text = "COPY TO CLIPBOARD" end)
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)


function SmartUpdate(key, subkey, val)
    if currentThemeName == "Default" then
        emotesDarkExecutorEnv().Notify({Title = "Theme", Content = "Cannot modify Default theme. Create a new one!", Duration = 2})
        return
    end

    if themes[currentThemeName] then
        if not themes[currentThemeName][key] then themes[currentThemeName][key] = {} end
        
        if subkey then
            themes[currentThemeName][key][subkey] = val
        else
            themes[currentThemeName][key] = val
        end
        SaveThemes(themes)
        ApplyTheme(themes[currentThemeName])
    end
end

WheelFolder = SettingsLib.AddFolder(ThemeTab, "Wheel Settings")
WheelFolder.Parent.LayoutOrder = 1.1

function AddWheelInput(title, wheelKey)
    local initialData = themes["Default"].Wheel[wheelKey]
    local initialColor = TableToColor(themes["Default"].Wheel[wheelKey.."Color"])
    
    local current = (themes[currentThemeName].Wheel and themes[currentThemeName].Wheel[wheelKey]) or initialData
    local currentColor = TableToColor((themes[currentThemeName].Wheel and themes[currentThemeName].Wheel[wheelKey.."Color"]) or themes["Default"].Wheel[wheelKey.."Color"])
    
    local comp = SettingsLib.AddAssetColor(WheelFolder, title, "Asset ID...", current, currentColor, function(text, color)
        if currentThemeName == "Default" then
            emotesDarkExecutorEnv().Notify({Title = "Theme", Content = "Cannot modify Default theme!", Duration = 2})
            return
        end
        
        if themes[currentThemeName] then
            if not themes[currentThemeName].Wheel then themes[currentThemeName].Wheel = {} end
            themes[currentThemeName].Wheel[wheelKey] = text
            themes[currentThemeName].Wheel[wheelKey.."Color"] = ColorToTable(color)
            
            SaveThemes(themes)
            ApplyTheme(themes[currentThemeName])
        end
    end)
    UIElements.Wheel[wheelKey] = comp

    local resetBtn = SettingsLib:Create("ImageButton", {
        Parent = comp.Item,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -120, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "rbxassetid://127493377027615",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10
    })
    
    resetBtn.MouseButton1Click:Connect(function()
        if currentThemeName == "Default" then return end
        comp.SetValue(initialData, initialColor)
        if themes[currentThemeName] then
            if not themes[currentThemeName].Wheel then themes[currentThemeName].Wheel = {} end
            themes[currentThemeName].Wheel[wheelKey] = initialData
            themes[currentThemeName].Wheel[wheelKey.."Color"] = ColorToTable(initialColor)
            SaveThemes(themes)
            ApplyTheme(themes[currentThemeName])
        end
    end)
end

AddWheelInput("Wheel Background", "BackgroundImage")
AddWheelInput("Selection Gradient", "SelectionGradient")
AddWheelInput("Selection Line", "SelectionLine")

BackgroundFolder = SettingsLib.AddFolder(ThemeTab, "Background Settings")
BackgroundFolder.Parent.LayoutOrder = 2
UIElements.Background.Main = SettingsLib.AddColorPicker(BackgroundFolder, "Main Background", TableToColor(themes[currentThemeName].Background), function(c)
    SmartUpdate("Background", nil, ColorToTable(c))
end)

IconSettingsFolder = SettingsLib.AddFolder(ThemeTab, "Icon Settings")
IconSettingsFolder.Parent.LayoutOrder = 3

function AddAssetInput(title, iconKey)
    local current = (themes[currentThemeName].Icons and themes[currentThemeName].Icons[iconKey]) or ""
    local defaultText = (themes["Default"].Icons and themes["Default"].Icons[iconKey]) or ""
    
    local currentColor = Color3.new(1,1,1)
    if themes[currentThemeName].IconColors and themes[currentThemeName].IconColors[iconKey] then
        currentColor = TableToColor(themes[currentThemeName].IconColors[iconKey])
    elseif themes[currentThemeName].ImageColor then
        currentColor = TableToColor(themes[currentThemeName].ImageColor)
    end
    
    local defaultColor = Color3.new(1,1,1)
    if themes["Default"].IconColors and themes["Default"].IconColors[iconKey] then
        defaultColor = TableToColor(themes["Default"].IconColors[iconKey])
    elseif themes["Default"].ImageColor then
        defaultColor = TableToColor(themes["Default"].ImageColor)
    end
    
    local comp = SettingsLib.AddInputWithColor(IconSettingsFolder, title, "Asset ID...", defaultText, defaultColor, function(text, color)
        local s, err = pcall(function()
            if currentThemeName == "Default" then
                emotesDarkExecutorEnv().Notify({Title = "Theme", Content = "Cannot modify Default theme!", Duration = 2})
                return
            end
            
            if themes[currentThemeName] then
                if not themes[currentThemeName].Icons then themes[currentThemeName].Icons = {} end
                if not themes[currentThemeName].IconColors then themes[currentThemeName].IconColors = {} end
                
                local cTable = ColorToTable(color)
                themes[currentThemeName].Icons[iconKey] = text
                themes[currentThemeName].IconColors[iconKey] = cTable
                
                SaveThemes(themes)
                ApplyTheme(themes[currentThemeName])
            end
        end)
        if not s then
            warn("Theme Save Error: " .. tostring(err))
            emotesDarkExecutorEnv().Notify({Title = "Error", Content = "Failed to save color!", Duration = 3})
        end
    end)
    comp.SetValue(current, currentColor)
    UIElements.Icons[iconKey] = comp
end

AddAssetInput("Left Arrow", "Left")
AddAssetInput("Right Arrow", "Right")
AddAssetInput("Walk Icon", "Walk")
AddAssetInput("Speed Icon", "Speed")
AddAssetInput("Page Icon", "Page")
AddAssetInput("Reload Icon", "Reload")
AddAssetInput("Favorite (Star)", "Favorite")
AddAssetInput("Not Favorite", "NotFavorite")

State.exitCustomAnimationEditor = function()
    if not State.customAnimationEditorActive then return end
    State.customAnimationEditorActive = false
    State.customAnimationEditingKey = nil
    State.customAnimationEditingName = nil

    for _, conn in pairs(State.CustomAnimEditorConnections or {}) do
        pcall(function() conn:Disconnect() end)
    end
    State.CustomAnimEditorConnections = {}

    if State.CustomAnimOverlay and State.CustomAnimOverlay.Parent then 
        State.CustomAnimOverlay:Destroy() 
    end
    State.CustomAnimOverlay = nil

    if State.CustomAnimForceVisibleConn then 
        State.CustomAnimForceVisibleConn:Disconnect()
        State.CustomAnimForceVisibleConn = nil 
    end

    if UI.Search then UI.Search.TextEditable = true; UI.Search.Active = true end
    if UI.SpeedBox then UI.SpeedBox.TextEditable = true; UI.SpeedBox.Active = true end
    if UI._2Routenumber then UI._2Routenumber.TextEditable = true; UI._2Routenumber.Active = true end
    
    pcall(function() game:GetService("GuiService"):SetEmotesMenuOpen(false) end)
    pcall(function() game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false end)

    local main = getSettingsMainFrame()
    if main then main.Visible = true end
    if syncToggleVisibility then syncToggleVisibility() end

    if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end

    if State.currentMode ~= "animation" then
        State.currentMode = "animation"
        State.suppressSearch = true
        if UI.Search then UI.Search.Text = State.animationSearchTerm end
        State.suppressSearch = false
        if State.animationSearchTerm ~= "" and searchAnimations then
            searchAnimations(State.animationSearchTerm)
        end
        State.currentPage = State.savedAnimPage
        State.totalPages = calculateTotalPages()
        updatePageDisplay()
        updateEmotes()
        if updateScriptPriorityOverlay then updateScriptPriorityOverlay() end
        State.animationMonitorToken = State.animationMonitorToken + 1
        local token = State.animationMonitorToken
        State.isMonitoringClicks = true
        if monitorAnimations then
            task.spawn(function() monitorAnimations(token) end)
        end
    end
end

State.enterCustomAnimationEditor = function(category, animName)
    if State.customAnimationEditorActive then return end
    if State.currentCustomAnimationName == "Default" then
        emotesDarkExecutorEnv().Notify({ Title = "Dark | Error", Content = "Cannot edit Default Animation set. Create a new one!", Duration = 3 })
        return
    end

    closeOtherScriptWindows("CustomAnimOverlay")
    State.customAnimationEditorActive = true
    State.customAnimationEditingKey = category
    State.customAnimationEditingName = animName
    
    if State.currentMode ~= "animation" then
        State.currentMode = "animation"
        State.suppressSearch = true
        if UI.Search then UI.Search.Text = State.animationSearchTerm end
        State.suppressSearch = false
        State.currentPage = State.savedAnimPage
        State.totalPages = calculateTotalPages()
        updatePageDisplay()
        updateEmotes()
        if updateScriptPriorityOverlay then updateScriptPriorityOverlay() end
        State.animationMonitorToken = State.animationMonitorToken + 1
        local token = State.animationMonitorToken
        State.isMonitoringClicks = true
        if monitorAnimations then
            task.spawn(function()
                monitorAnimations(token)
            end)
        end
        
        local beforeVersion = State.animationCacheVersion
        task.spawn(function()
            if fetchAllAnimations then
                fetchAllAnimations()
            else
                return
            end
            if State.currentMode ~= "animation" then return end
            if State.animationCacheVersion ~= beforeVersion then
                State.suppressSearch = true
                if UI.Search then UI.Search.Text = State.animationSearchTerm end
                State.suppressSearch = false
                if State.animationSearchTerm ~= "" and searchAnimations then
                    searchAnimations(State.animationSearchTerm)
                end
                State.currentPage = State.savedAnimPage
                State.totalPages = calculateTotalPages()
                updatePageDisplay()
                updateEmotes()
                if updateScriptPriorityOverlay then updateScriptPriorityOverlay() end
            end
        end)
    end

    GuiService:SetEmotesMenuOpen(false)
    task.wait(0.15)

    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then State.customAnimationEditorActive = false; return end
    emotesWheel.Visible = true

    State.CustomAnimForceVisibleConn = RunService.Heartbeat:Connect(function()
        if not State.customAnimationEditorActive then return end
        pcall(function()
            local _, ew = checkEmotesMenuExists()
            if ew then ew.Visible = true end
        end)
    end)

    local main = getSettingsMainFrame()
    if main then main.Visible = false end
    if syncToggleVisibility then syncToggleVisibility() end

    local overlay = Instance.new("Frame")
    overlay.Name = "CustomAnimOverlay"
    overlay.Parent = SettingsLib.UI
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 6000
    overlay.Active = false
    State.CustomAnimOverlay = overlay

    local bc = Instance.new("Frame")
    bc.Parent = overlay
    bc.BackgroundTransparency = 1
    bc.AnchorPoint = Vector2.new(1, 0)
    bc.Position = UDim2.new(1, -10, 0, 10)
    bc.Size = UDim2.fromOffset(42, 42)
    bc.ZIndex = 6000

    local backBtn = Instance.new("ImageButton")
    backBtn.Name = "CustomAnimBackBtn"
    backBtn.Size = UDim2.fromOffset(42, 42)
    backBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backBtn.BackgroundTransparency = 0.4
    backBtn.Image = "rbxassetid://79024388644722"
    backBtn.ZIndex = 6001
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = backBtn
    
    backBtn.Parent = bc
    
    State.CustomAnimEditorConnections = State.CustomAnimEditorConnections or {}
    table.insert(State.CustomAnimEditorConnections, backBtn.MouseButton1Click:Connect(function()
        State.exitCustomAnimationEditor()
    end))

    if UI._2Routenumber then UI._2Routenumber.TextEditable = false; UI._2Routenumber.Active = false; pcall(function() UI._2Routenumber:ReleaseFocus() end) end

    emotesDarkExecutorEnv().Notify({ Title = "Dark | Animation Editor", Content = "🖱️ Select an animation from the wheel to set for " .. animName, Duration = 5 })
end

State.CustomAnimTab = SettingsLib.CreateTab("Animation", 4)
State.CustomAnimDropdown = SettingsLib.AddDropdown(State.CustomAnimTab, "Select Animation", State.CustomAnimations.Order, State.currentCustomAnimationName, function(v)
    State.currentCustomAnimationName = v
    State.CustomAnimations.Selected = v
    State.SaveCustomAnimations(State.CustomAnimations)
    if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
    if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
    if refreshCustomAnimationState then refreshCustomAnimationState(false) end
end)
if State.CustomAnimDropdown and State.CustomAnimDropdown.Button and State.CustomAnimDropdown.Button.Parent and State.CustomAnimDropdown.Button.Parent.Parent then
   State.CustomAnimDropdown.Button.Parent.Parent.LayoutOrder = 0
end

CustomAnimBtnItem = SettingsLib.AddItem(State.CustomAnimTab, "Animation Management", "Manage your animations")
CustomAnimBtnItem.LayoutOrder = 1 
CustomAnimBtnItem.BackgroundColor3 = Color3.fromRGB(35, 38, 42)
CustomAnimBtnItem.Size = UDim2.new(0.95, 0, 0, 70) 
for _, v in pairs(CustomAnimBtnItem:GetChildren()) do if v.Name == "Title" or v.Name == "Desc" then v:Destroy() end end

CustomAnimMgtContainer = Instance.new("Frame")
CustomAnimMgtContainer.Parent = CustomAnimBtnItem
CustomAnimMgtContainer.BackgroundTransparency = 1
CustomAnimMgtContainer.Size = UDim2.new(1, 0, 1, 0)

CustomAnimLayout = Instance.new("UIListLayout")
CustomAnimLayout.FillDirection = Enum.FillDirection.Horizontal
CustomAnimLayout.Padding = UDim.new(0, 15)
CustomAnimLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
CustomAnimLayout.VerticalAlignment = Enum.VerticalAlignment.Center
CustomAnimLayout.Parent = CustomAnimMgtContainer

function NormalizeCustomAnimationData(animData)
    local defaultAnim = {
        idle = { Animation1 = 0, Animation2 = 0 },
        walk = { WalkAnim = 0 },
        run = { RunAnim = 0 },
        jump = { JumpAnim = 0 },
        fall = { FallAnim = 0 },
        swimidle = { SwimIdle = 0 },
        swim = { Swim = 0 },
        __meta = { IconImage = DEFAULT_IDLE_ICON_ID, IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) }
    }
    
    local result = { Sets = { Default = DeepCopy(defaultAnim) }, Order = {"Default"}, Selected = "Default" }
    if type(animData) ~= "table" then return result end
    
    local setsTable = animData.Sets or animData
    if type(setsTable) == "table" then
        for name, data in pairs(setsTable) do
            if type(data) == "table" then
                if name == "Default" then
                    result.Sets.Default = data
                else
                    result.Sets[name] = data
                end
                data.__meta = data.__meta or {}
                if data.__meta.IconImage == nil then data.__meta.IconImage = DEFAULT_IDLE_ICON_ID end
                if data.__meta.IconColor == nil then data.__meta.IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) end
            end
        end
    end
    
    local order = animData.Order
    if type(order) == "table" then
        for _, name in ipairs(order) do
            if name ~= "Default" and result.Sets[name] then
                table.insert(result.Order, name)
            end
        end
    else
        for name, _ in pairs(result.Sets) do
            if name ~= "Default" then table.insert(result.Order, name) end
        end
    end
    
    local selected = animData.Selected
    if type(selected) == "string" and result.Sets[selected] then
        result.Selected = selected
    end
    
    return result
end

function MakeUniqueSetName(baseSets, desiredName)
    if not baseSets[desiredName] then return desiredName end
    local i = 2
    local candidate = desiredName .. " (Imported)"
    if not baseSets[candidate] then return candidate end
    while true do
        candidate = desiredName .. " (Imported " .. i .. ")"
        if not baseSets[candidate] then return candidate end
        i = i + 1
    end
end

SettingsLib.AddIconButton(CustomAnimMgtContainer, "108445456753346", function()
    local popup, content = CreatePopup("Create Animation")
    local In = CreateInput(content, "Animation Name...")
    
    local Save = CreateButton(content, "SAVE", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Cancel.TextColor3 = Color3.new(1,1,1)

    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not State.CustomAnimations.Sets[In.Text] then
            local defaultAnim = {
                idle = { Animation1 = 0, Animation2 = 0 },
                walk = { WalkAnim = 0 },
                run = { RunAnim = 0 },
                jump = { JumpAnim = 0 },
                fall = { FallAnim = 0 },
                swimidle = { SwimIdle = 0 },
                swim = { Swim = 0 },
                __meta = { IconImage = DEFAULT_IDLE_ICON_ID, IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) }
            }
            State.CustomAnimations.Sets[In.Text] = defaultAnim
            table.insert(State.CustomAnimations.Order, In.Text)
            
            table.sort(State.CustomAnimations.Order, function(a, b)
                if a == "Default" then return true end
                if b == "Default" then return false end
                return a:lower() < b:lower()
            end)
            
            State.currentCustomAnimationName = In.Text
            State.CustomAnimations.Selected = In.Text
            State.SaveCustomAnimations(State.CustomAnimations)
            if State.CustomAnimDropdown then
                State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
                State.CustomAnimDropdown.Button.Text = State.currentCustomAnimationName .. "  ▼"
            end
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(false) end
            popup:Destroy()
        end
    end)
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(CustomAnimMgtContainer, "71829270056766", function()
    if State.currentCustomAnimationName ~= "Default" then
        local idx = table.find(State.CustomAnimations.Order, State.currentCustomAnimationName)
        if idx then table.remove(State.CustomAnimations.Order, idx) end
        
        State.CustomAnimations.Sets[State.currentCustomAnimationName] = nil
        State.currentCustomAnimationName = "Default"
        State.CustomAnimations.Selected = "Default"
        State.SaveCustomAnimations(State.CustomAnimations)
        if State.CustomAnimDropdown then
            State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
            State.CustomAnimDropdown.Button.Text = "Default  ▼"
        end
        if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
        if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
        if refreshCustomAnimationState then refreshCustomAnimationState(false) end
    end
end)

SettingsLib.AddIconButton(CustomAnimMgtContainer, "117761881427472", function()
    if State.currentCustomAnimationName == "Default" then return end
    
    local popup, content = CreatePopup("Rename Animation")
    local In = CreateInput(content, "New Name...", State.currentCustomAnimationName)
    
    local Save = CreateButton(content, "RENAME", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Cancel.TextColor3 = Color3.new(1,1,1)

    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not State.CustomAnimations.Sets[In.Text] then
            local idx = table.find(State.CustomAnimations.Order, State.currentCustomAnimationName)
            if idx then State.CustomAnimations.Order[idx] = In.Text end
            
            State.CustomAnimations.Sets[In.Text] = State.CustomAnimations.Sets[State.currentCustomAnimationName]
            State.CustomAnimations.Sets[State.currentCustomAnimationName] = nil
            State.currentCustomAnimationName = In.Text
            State.CustomAnimations.Selected = In.Text
            State.SaveCustomAnimations(State.CustomAnimations)
            if State.CustomAnimDropdown then
                State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
                State.CustomAnimDropdown.Button.Text = State.currentCustomAnimationName .. "  ▼"
            end
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(false) end
            popup:Destroy()
        end
    end)
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(CustomAnimMgtContainer, "107588515524752", function()
    local currentSet = State.CustomAnimations.Sets[State.currentCustomAnimationName]
    local data = {
        Type = "CustomAnimationSet",
        Name = State.currentCustomAnimationName,
        Data = currentSet
    }
    local json = HttpService:JSONEncode(data)
    
    local popup, content = CreatePopup("Export Animations", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "", json, true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    box.TextEditable = false
    
    local copy = CreateButton(content, "COPY TO CLIPBOARD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))
    copy.MouseButton1Click:Connect(function()
        setclipboard(json)
        copy.Text = "COPIED!"
        task.delay(1, function() copy.Text = "COPY TO CLIPBOARD" end)
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "X"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(CustomAnimMgtContainer, "78317476576895", function()
    local popup, content = CreatePopup("Import Animations", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "Paste Animation JSON here...", "", true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    
    local imp = CreateButton(content, "IMPORT DATA", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))
    imp.MouseButton1Click:Connect(function()
        local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
        if s and type(d) == "table" then
            if d.Type and d.Type ~= "CustomAnimationSet" then
                emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "Backup type mismatch!", Duration = 3 })
                return
            end
            if type(d.Data) ~= "table" then
                emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "Invalid JSON", Duration = 3 })
                return
            end
            State.CustomAnimations = NormalizeCustomAnimationData(State.CustomAnimations)
            local sourceName = d.Name or "Imported"
            local targetName = MakeUniqueSetName(State.CustomAnimations.Sets, sourceName)
            local imported = d.Data
            imported.__meta = imported.__meta or {}
            if imported.__meta.IconImage == nil then imported.__meta.IconImage = DEFAULT_IDLE_ICON_ID end
            if imported.__meta.IconColor == nil then imported.__meta.IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) end
            State.CustomAnimations.Sets[targetName] = imported
            table.insert(State.CustomAnimations.Order, targetName)
            State.currentCustomAnimationName = targetName
            State.CustomAnimations.Selected = targetName
            
            State.SaveCustomAnimations(State.CustomAnimations)
            if State.CustomAnimDropdown then
                State.CustomAnimDropdown.Refresh(State.CustomAnimations.Order)
                State.CustomAnimDropdown.Button.Text = State.currentCustomAnimationName .. "  ▼"
            end
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if State.ApplyCustomAnimIconUI then State.ApplyCustomAnimIconUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(false) end
            popup:Destroy()
            emotesDarkExecutorEnv().Notify({ Title = "Dark | Animation", Content = "✅ Imported custom animations", Duration = 3 })
        else
            emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "Invalid JSON", Duration = 3 })
        end
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "x"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

function GetCurrentCustomAnimMeta()
    local set = State.CustomAnimations.Sets[State.currentCustomAnimationName]
    if not set then return nil end
    set.__meta = set.__meta or {}
    if set.__meta.IconImage == nil then set.__meta.IconImage = DEFAULT_IDLE_ICON_ID end
    if set.__meta.IconColor == nil then set.__meta.IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR) end
    return set.__meta
end

State.ApplyCustomAnimIconUI = function()
    if not State.CustomAnimIconControl or not State.CustomAnimIconControl.SetValue then return end
    local meta = GetCurrentCustomAnimMeta()
    if not meta then return end
    State.CustomAnimIconControl.SetValue(meta.IconImage or DEFAULT_IDLE_ICON_ID, TableToColor(meta.IconColor or ColorToTable(DEFAULT_IDLE_ICON_COLOR)))
end

do
    local meta = GetCurrentCustomAnimMeta() or {}
    local currentImage = meta.IconImage or DEFAULT_IDLE_ICON_ID
    local currentColor = TableToColor(meta.IconColor or ColorToTable(DEFAULT_IDLE_ICON_COLOR))
    State.CustomAnimIconControl = SettingsLib.AddAssetColor(State.CustomAnimTab, "Icon", "Asset ID or URL...", currentImage, currentColor, function(text, color)
        local set = State.CustomAnimations.Sets[State.currentCustomAnimationName]
        if not set then return end
        set.__meta = set.__meta or {}
        set.__meta.IconImage = text
        set.__meta.IconColor = ColorToTable(color)
        State.SaveCustomAnimations(State.CustomAnimations)
        if refreshCustomAnimationState then refreshCustomAnimationState(false) end
    end)
    if State.CustomAnimIconControl and State.CustomAnimIconControl.Item then
        State.CustomAnimIconControl.Item.LayoutOrder = 1.5
    end
    
    local resetBtn = SettingsLib:Create("ImageButton", {
        Parent = State.CustomAnimIconControl.Item,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -120, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "rbxassetid://127493377027615",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10
    })
    resetBtn.MouseButton1Click:Connect(function()
        local set = State.CustomAnimations.Sets[State.currentCustomAnimationName]
        if not set then return end
        set.__meta = set.__meta or {}
        set.__meta.IconImage = DEFAULT_IDLE_ICON_ID
        set.__meta.IconColor = ColorToTable(DEFAULT_IDLE_ICON_COLOR)
        State.SaveCustomAnimations(State.CustomAnimations)
        if State.CustomAnimIconControl and State.CustomAnimIconControl.SetValue then
            State.CustomAnimIconControl.SetValue(DEFAULT_IDLE_ICON_ID, DEFAULT_IDLE_ICON_COLOR)
        end
        if refreshCustomAnimationState then refreshCustomAnimationState(false) end
    end)
end

State.CustomAnimUIElems = {}
function CreateAnimSetUI(folder, cat, name)
    local item = SettingsLib.AddItem(folder, cat .. " - " .. name, "Current ID: 0")
    
    local resetBtn = SettingsLib:Create("ImageButton", {
        Parent = item,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -70, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "rbxassetid://127493377027615",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10
    })
    
    local editBtn = SettingsLib:Create("ImageButton", {
        Parent = item,
        BackgroundTransparency = 1,
        Position = UDim2.new(1, -40, 0.5, -10),
        Size = UDim2.fromOffset(20, 20),
        Image = "rbxassetid://117761881427472",
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 10
    })
    
    resetBtn.MouseButton1Click:Connect(function()
        if State.currentCustomAnimationName == "Default" then return end
        if State.CustomAnimations.Sets[State.currentCustomAnimationName] then
            if not State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] then
                State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] = {}
            end
            State.CustomAnimations.Sets[State.currentCustomAnimationName][cat][name] = 0
            State.SaveCustomAnimations(State.CustomAnimations)
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(true) end
        end
    end)
    
    editBtn.MouseButton1Click:Connect(function()
        State.enterCustomAnimationEditor(cat, name)
    end)
    
    table.insert(State.CustomAnimUIElems, { item = item, cat = cat, name = name })
end

State.CustomAnimFolders = {}
State.CustomAnimFolders.Idle = SettingsLib.AddFolder(State.CustomAnimTab, "Idle Animations")
State.CustomAnimFolders.Idle.Parent.LayoutOrder = 2
CreateAnimSetUI(State.CustomAnimFolders.Idle, "idle", "Animation1")
CreateAnimSetUI(State.CustomAnimFolders.Idle, "idle", "Animation2")

State.CustomAnimFolders.Movement = SettingsLib.AddFolder(State.CustomAnimTab, "Movement Animations")
State.CustomAnimFolders.Movement.Parent.LayoutOrder = 3
CreateAnimSetUI(State.CustomAnimFolders.Movement, "walk", "WalkAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "run", "RunAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "jump", "JumpAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "fall", "FallAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "climb", "ClimbAnim")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "swimidle", "SwimIdle")
CreateAnimSetUI(State.CustomAnimFolders.Movement, "swim", "Swim")

State.RefreshCustomAnimUI = function()
    local set = State.CustomAnimations.Sets[State.currentCustomAnimationName]
    if not set then return end
    
    for _, elem in pairs(State.CustomAnimUIElems) do
        local desc = elem.item:FindFirstChild("Desc")
        if desc then
            local val = set[elem.cat] and set[elem.cat][elem.name] or 0
            desc.Text = "Current ID: " .. tostring(val)
        end
    end
end
State.RefreshCustomAnimUI()

State.PageTab = SettingsLib.CreateTab("Page", 5)

function GetEmotePageNames()
    return State.EmotePages.Order
end

SettingsLib.AddItem(State.PageTab, "Page Profiles", "Pages allow you to save different favorite sets. Switch pages to quickly change your favorite wheel loadout.")

SettingsLib.AddItem(State.PageTab, "Emote Profiles", "Manage your favorite emote profiles")

State.PageDropdown = SettingsLib.AddDropdown(State.PageTab, "Select Emote Page", GetEmotePageNames(), State.currentEmotePageName, function(v)
    SwitchEmotePage(v)
    State.SaveEmotePages(State.EmotePages)
end)

EmotePageMgtItem = SettingsLib.AddItem(State.PageTab, "Emote Page Management", " ")
EmotePageMgtItem.BackgroundColor3 = Color3.fromRGB(35, 38, 42)
EmotePageMgtItem.Size = UDim2.new(0.95, 0, 0, 70)
for _, v in pairs(EmotePageMgtItem:GetChildren()) do if v.Name == "Title" or v.Name == "Desc" then v:Destroy() end end

EmotePageMgtContainer = Instance.new("Frame")
EmotePageMgtContainer.Parent = EmotePageMgtItem
EmotePageMgtContainer.BackgroundTransparency = 1
EmotePageMgtContainer.Size = UDim2.new(1, 0, 1, 0)

EmotePageLayout = Instance.new("UIListLayout")
EmotePageLayout.FillDirection = Enum.FillDirection.Horizontal
EmotePageLayout.Padding = UDim.new(0, 15)
EmotePageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
EmotePageLayout.VerticalAlignment = Enum.VerticalAlignment.Center
EmotePageLayout.Parent = EmotePageMgtContainer

SettingsLib.AddIconButton(EmotePageMgtContainer, "108445456753346", function()
    local popup, content = CreatePopup("Create Emote Page")
    local In = CreateInput(content, "Page Name...")
    local Save = CreateButton(content, "SAVE", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not State.EmotePages.Sets[In.Text] then
            State.EmotePages.Sets[In.Text] = {}
            table.insert(State.EmotePages.Order, In.Text)
            table.sort(State.EmotePages.Order, function(a, b)
                if a == "Default" then return true end
                if b == "Default" then return false end
                return a:lower() < b:lower()
            end)
            State.SaveEmotePages(State.EmotePages)
            if State.PageDropdown then State.PageDropdown.Refresh(GetEmotePageNames()) end
            SwitchEmotePage(In.Text)
            if State.PageDropdown then State.PageDropdown.Button.Text = State.currentEmotePageName .. "  ▼" end
            popup:Destroy()
        end
    end)
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(EmotePageMgtContainer, "71829270056766", function()
    if State.currentEmotePageName ~= "Default" then
        local idx = table.find(State.EmotePages.Order, State.currentEmotePageName)
        if idx then table.remove(State.EmotePages.Order, idx) end
        State.EmotePages.Sets[State.currentEmotePageName] = nil
        State.currentEmotePageName = "Default"
        State.EmotePages.Selected = "Default"
        State.SaveEmotePages(State.EmotePages)
        if State.PageDropdown then
            State.PageDropdown.Refresh(GetEmotePageNames())
            State.PageDropdown.Button.Text = "Default  ▼"
        end
        SwitchEmotePage("Default")
    end
end)

SettingsLib.AddIconButton(EmotePageMgtContainer, "117761881427472", function()
    if State.currentEmotePageName == "Default" then return end
    local popup, content = CreatePopup("Rename Emote Page")
    local In = CreateInput(content, "New Name...", State.currentEmotePageName)
    local Save = CreateButton(content, "RENAME", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.6, 0))
    local Cancel = CreateButton(content, "CANCEL", Color3.fromRGB(50, 50, 50), UDim2.new(0.55, 0, 0.6, 0))
    Save.MouseButton1Click:Connect(function()
        if In.Text ~= "" and not State.EmotePages.Sets[In.Text] then
            local idx = table.find(State.EmotePages.Order, State.currentEmotePageName)
            if idx then State.EmotePages.Order[idx] = In.Text end
            State.EmotePages.Sets[In.Text] = State.EmotePages.Sets[State.currentEmotePageName]
            State.EmotePages.Sets[State.currentEmotePageName] = nil
            State.currentEmotePageName = In.Text
            State.EmotePages.Selected = In.Text
            State.SaveEmotePages(State.EmotePages)
            if State.PageDropdown then
                State.PageDropdown.Refresh(GetEmotePageNames())
                State.PageDropdown.Button.Text = State.currentEmotePageName .. "  ▼"
            end
            popup:Destroy()
        end
    end)
    Cancel.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(EmotePageMgtContainer, "107588515524752", function() 
    local currentSet = State.EmotePages.Sets[State.currentEmotePageName]
    local data = { Type = "EmotePageSet", Name = State.currentEmotePageName, Data = currentSet }
    local json = HttpService:JSONEncode(data)
    local popup, content = CreatePopup("Export Emote Page", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "", json, true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    box.TextEditable = false
    local copy = CreateButton(content, "COPY TO CLIPBOARD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))
    copy.MouseButton1Click:Connect(function()
        setclipboard(json)
        copy.Text = "COPIED!"
        task.delay(1, function() copy.Text = "COPY TO CLIPBOARD" end)
    end)
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddIconButton(EmotePageMgtContainer, "78317476576895", function() 
    local popup, content = CreatePopup("Import Emote Page", UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "Paste Page JSON here...", "", true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    local imp = CreateButton(content, "IMPORT DATA", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))
    imp.MouseButton1Click:Connect(function()
        local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
        if s and type(d) == "table" and d.Type == "EmotePageSet" and type(d.Data) == "table" then
            local targetName = MakeUniqueSetName(State.EmotePages.Sets, d.Name or "Imported")
            State.EmotePages.Sets[targetName] = d.Data
            table.insert(State.EmotePages.Order, targetName)
            State.currentEmotePageName = targetName
            State.EmotePages.Selected = targetName
            State.SaveEmotePages(State.EmotePages)
            if State.PageDropdown then
                State.PageDropdown.Refresh(GetEmotePageNames())
                State.PageDropdown.Button.Text = State.currentEmotePageName .. "  ▼"
            end
            SwitchEmotePage(targetName)
            popup:Destroy()
            emotesDarkExecutorEnv().Notify({ Title = "Dark | Page", Content = "✅ Imported Emote page", Duration = 3 })
        else
            emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "Invalid Emote Page JSON", Duration = 3 })
        end
    end)
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end)

SettingsLib.AddItem(State.PageTab, "Animation Profiles", "Manage your favorite animation profiles")


BackupTab = SettingsLib.CreateTab("Backup", 6)

BackupDesc = SettingsLib.AddItem(BackupTab, "What's included in a backup?", " ")
BackupDesc.LayoutOrder = 1
BackupDesc.Size = UDim2.new(0.95, 0, 0, 110)
for _, v in pairs(BackupDesc:GetChildren()) do if v.Name == "Title" or v.Name == "Desc" then v:Destroy() end end
BackupDesc.BackgroundTransparency = 0
BackupDesc.BackgroundColor3 = Color3.fromRGB(35, 38, 42)

BackupTitle = Instance.new("TextLabel")
BackupTitle.Parent = BackupDesc
BackupTitle.BackgroundTransparency = 1
BackupTitle.Position = UDim2.new(0, 12, 0, 6)
BackupTitle.Size = UDim2.new(1, -24, 0, 18)
BackupTitle.Font = Enum.Font.GothamBold
BackupTitle.Text = "What's included in a backup?"
BackupTitle.TextColor3 = Color3.fromRGB(200, 200, 200)
BackupTitle.TextSize = 12
BackupTitle.TextXAlignment = Enum.TextXAlignment.Left

DescList = Instance.new("Frame")
DescList.Parent = BackupDesc
DescList.BackgroundTransparency = 1
DescList.Position = UDim2.new(0, 12, 0, 28)
DescList.Size = UDim2.new(1, -24, 1, -28)

LayoutDesc = Instance.new("UIListLayout")
LayoutDesc.Parent = DescList
LayoutDesc.Padding = UDim.new(0, 4)

function MakeDescLine(text)
    local lbl = Instance.new("TextLabel")
    lbl.Parent = DescList
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 0, 15)
    lbl.AutomaticSize = Enum.AutomaticSize.Y
    lbl.TextWrapped = true
    lbl.Font = Enum.Font.Gotham
    lbl.Text = text
    lbl.TextColor3 = Color3.fromRGB(150, 150, 150)
    lbl.TextSize = 11
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.RichText = true
end

MakeDescLine("<b>• Theme:</b> Saves custom themes")
MakeDescLine("<b>• Settings:</b> Saves HUD layout & values")
MakeDescLine("<b>• Favorite:</b> Saves favorite emotes/anims")
MakeDescLine("<b>• All:</b> Includes everything above")

ExportItem = SettingsLib.AddItem(BackupTab, "Export Settings", "Save current settings to a file for sharing or later import.")
ExportItem.LayoutOrder = 2

ExportBtnContainer = Instance.new("Frame")
ExportBtnContainer.Parent = ExportItem
ExportBtnContainer.BackgroundTransparency = 1
ExportBtnContainer.Size = UDim2.new(1, -24, 0, 60)

expDesc = ExportItem:FindFirstChild("Desc")
if expDesc then
    expDesc.Size = UDim2.new(1, -24, 0, 0)
    local function updateExpPos()
        ExportBtnContainer.Position = UDim2.new(0, 12, 0, expDesc.Position.Y.Offset + expDesc.AbsoluteSize.Y + 12)
    end
    expDesc:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateExpPos)
    updateExpPos()
else
    ExportBtnContainer.Position = UDim2.new(0, 12, 0, 32)
end

ExportLayout = Instance.new("UIGridLayout")
ExportLayout.CellSize = UDim2.new(0.48, 0, 0, 26)
ExportLayout.CellPadding = UDim2.new(0.04, 0, 0, 8)
ExportLayout.SortOrder = Enum.SortOrder.LayoutOrder
ExportLayout.Parent = ExportBtnContainer

function CreateExportBtn(text, color, order)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 11
    btn.Parent = ExportBtnContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

btnColors = {
    dark = Color3.fromRGB(45, 48, 52),
    blue = Color3.fromRGB(88, 101, 242)
}

BtnExportAll = CreateExportBtn("Export All Settings", btnColors.dark, 1)
BtnExportThemes = CreateExportBtn("Export Themes", btnColors.blue, 2)
BtnExportSettings = CreateExportBtn("Export Settings", btnColors.blue, 3)
BtnExportFavorites = CreateExportBtn("Export Favorites", btnColors.blue, 4)

function GetFavoritesData()
    local favAnimsStr = "{}"
    if isfile and isfile(State.favoriteAnimationsFileName) then
        favAnimsStr = readfile(State.favoriteAnimationsFileName)
    end
    return {
        EmotePages = State.EmotePages,
        Animations = HttpService:JSONDecode(favAnimsStr) or {}
    }
end

BtnExportAll.MouseButton1Click:Connect(function()
    local data = {
        Type = "All",
        Themes = LoadThemes(),
        Settings = Config,
        Favorites = GetFavoritesData()
    }
    setclipboard(HttpService:JSONEncode(data))
    BtnExportAll.Text = "Copied!"
    task.delay(1, function() BtnExportAll.Text = "Export All Settings" end)
end)

BtnExportThemes.MouseButton1Click:Connect(function()
    local data = {
        Type = "Themes",
        Themes = LoadThemes()
    }
    setclipboard(HttpService:JSONEncode(data))
    BtnExportThemes.Text = "Copied!"
    task.delay(1, function() BtnExportThemes.Text = "Export Themes" end)
end)

BtnExportSettings.MouseButton1Click:Connect(function()
    local data = {
        Type = "Settings",
        Settings = Config
    }
    setclipboard(HttpService:JSONEncode(data))
    BtnExportSettings.Text = "Copied!"
    task.delay(1, function() BtnExportSettings.Text = "Export Settings" end)
end)

BtnExportFavorites.MouseButton1Click:Connect(function()
    local data = {
        Type = "Favorites",
        Favorites = GetFavoritesData()
    }
    setclipboard(HttpService:JSONEncode(data))
    BtnExportFavorites.Text = "Copied!"
    task.delay(1, function() BtnExportFavorites.Text = "Export Favorites" end)
end)


ImportItem = SettingsLib.AddItem(BackupTab, "Import Settings", "Select a backup file to restore your configuration and overwrite current settings.")
ImportItem.LayoutOrder = 3

ImportBtnContainer = Instance.new("Frame")
ImportBtnContainer.Parent = ImportItem
ImportBtnContainer.BackgroundTransparency = 1
ImportBtnContainer.Size = UDim2.new(1, -24, 0, 60)

impDesc = ImportItem:FindFirstChild("Desc")
if impDesc then
    impDesc.Size = UDim2.new(1, -24, 0, 0)
    local function updateImpPos()
        ImportBtnContainer.Position = UDim2.new(0, 12, 0, impDesc.Position.Y.Offset + impDesc.AbsoluteSize.Y + 12)
    end
    impDesc:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateImpPos)
    updateImpPos()
else
    ImportBtnContainer.Position = UDim2.new(0, 12, 0, 32)
end

ImportLayout = Instance.new("UIGridLayout")
ImportLayout.CellSize = UDim2.new(0.48, 0, 0, 26)
ImportLayout.CellPadding = UDim2.new(0.04, 0, 0, 8)
ImportLayout.SortOrder = Enum.SortOrder.LayoutOrder
ImportLayout.Parent = ImportBtnContainer

function CreateImportBtn(text, color, order)
    local btn = Instance.new("TextButton")
    btn.LayoutOrder = order
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 11
    btn.Parent = ImportBtnContainer
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = btn
    
    return btn
end

BtnImportAll = CreateImportBtn("Import All Settings", btnColors.dark, 1)
BtnImportThemes = CreateImportBtn("Import Themes", btnColors.blue, 2)
BtnImportSettings = CreateImportBtn("Import Settings", btnColors.blue, 3)
BtnImportFavorites = CreateImportBtn("Import Favorites", btnColors.blue, 4)

function HandleImportPrompt(typeStr)
    local popup, content = CreatePopup("Import " .. typeStr, UDim2.fromOffset(320, 240))
    local box = CreateInput(content, "Paste Backup JSON here...", "", true)
    box.Size = UDim2.new(0.9, 0, 0, 130)
    
    local imp = CreateButton(content, "IMPORT DATA", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

    imp.MouseButton1Click:Connect(function()
        local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
        if s and type(d) == "table" and d.Type then
            if typeStr ~= "All" and d.Type ~= "All" and typeStr ~= d.Type then
                 emotesDarkExecutorEnv().Notify({Title = "Error", Content = "Backup type mismatch!", Duration = 3})
                 return
            end
            
            if d.Themes and (typeStr == "All" or typeStr == "Themes") then
                themes = d.Themes
                currentThemeName = themes.Selected or Config.SelectedTheme or "Default"
                SaveThemesImplementation(themes)
                themeDropdown.Refresh(GetNames())
                if themeDropdown and themeDropdown.Button then
                    themeDropdown.Button.Text = currentThemeName .. "  ▼"
                end
                local themeToApply = themes[currentThemeName] or themes["Default"]
                if themeToApply then
                    State.isApplyingTheme = false
                    ApplyTheme(themeToApply)
                else
                    warn("Dark | Missing Default theme during import fallback")
                end
            end
            if d.Settings and (typeStr == "All" or typeStr == "Settings") then
                for k, v in pairs(d.Settings) do Config[k] = v end
                SaveConfig()
                ApplyUIVisibility()
                if applySavedPositions then applySavedPositions() end
                if State.RefreshSettingsUI then State.RefreshSettingsUI() end
            end
            if (d.Favorites or d.EmotePages) and (typeStr == "All" or typeStr == "Favorites") then
                local emotesData = d.EmotePages
                if not emotesData and type(d.Favorites) == "table" then
                    emotesData = d.Favorites.EmotePages or d.Favorites.Emotes
                end
                if emotesData then
                    if emotesData.Sets then
                        State.EmotePages = emotesData
                    else
                        State.EmotePages.Sets.Default = emotesData
                    end
                    State.SaveEmotePages(State.EmotePages)
                    local targetPage = State.EmotePages.Selected
                    if not State.EmotePages.Sets[targetPage] then targetPage = "Default" end
                    SwitchEmotePage(targetPage)
                end
                
                if d.Favorites and d.Favorites.Animations then
                     State.favoriteAnimations = d.Favorites.Animations
                     writefile(State.favoriteAnimationsFileName, HttpService:JSONEncode(d.Favorites.Animations))
                     State.favoriteSetVersion = State.favoriteSetVersion + 1
                end
                if State.RefreshUI then State.RefreshUI() end
            end
            
            emotesDarkExecutorEnv().Notify({Title = "Success", Content = "Data imported successfully!", Duration = 3})
            popup:Destroy()
        else
            emotesDarkExecutorEnv().Notify({Title = "Error", Content = "Invalid Backup JSON Format!", Duration = 3})
        end
    end)
    
    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(24, 24)
    close.Position = UDim2.new(1, -30, 0, 5)
    close.Text = "×"
    close.Font = Enum.Font.GothamBold
    close.TextSize = 20
    close.BackgroundTransparency = 1
    close.TextColor3 = Color3.new(1,1,1)
    close.Parent = popup
    close.MouseButton1Click:Connect(function() popup:Destroy() end)
end

BtnImportAll.MouseButton1Click:Connect(function() HandleImportPrompt("All") end)
BtnImportThemes.MouseButton1Click:Connect(function() HandleImportPrompt("Themes") end)
BtnImportSettings.MouseButton1Click:Connect(function() HandleImportPrompt("Settings") end)
BtnImportFavorites.MouseButton1Click:Connect(function() HandleImportPrompt("Favorites") end)

emotesDarkExecutorEnv().Notify({
    Title = 'Dark | Emote',
    Content = '⚠️ Script loading...',
    Duration = 5,
    _EmotesDarkNoTranslate = true
})

end

local Players = game:GetService("Players")
player = Players.LocalPlayer
if not player then
    player = Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
end
character = player.Character or player.CharacterAdded:Wait()
humanoid = character:WaitForChild("Humanoid")

emotesDarkExecutorEnv().OwnedAuthenticEmotes = emotesDarkExecutorEnv().OwnedAuthenticEmotes or {}
function gatherAuthenticEmotes(char)
    if not char then return end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    local desc = hum:WaitForChild("HumanoidDescription", 5)
    if not desc then return end
    local allEmotes = desc:GetEmotes()
    local owned = {}
    
    for _, e in ipairs(desc:GetEquippedEmotes()) do
        local id = allEmotes[e.Name] and allEmotes[e.Name][1]
        if id then
            local idNum = tonumber((tostring(id):gsub("rbxassetid://", "")))
            if idNum then
                table.insert(owned, {
                    name = e.Name,
                    id = idNum
                })
            end
        end
    end
    if #owned > 0 then
        emotesDarkExecutorEnv().OwnedAuthenticEmotes = owned
    end
end

task.spawn(function() gatherAuthenticEmotes(character) end)
player.CharacterAdded:Connect(gatherAuthenticEmotes)

local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

lastEmoteMenuSync = 0
EMOTE_MENU_SYNC_INTERVAL = 0.1
RunService.Heartbeat:Connect(function()
    if State.scriptKicked then return end
    local now = os.clock()
    if now - lastEmoteMenuSync < EMOTE_MENU_SYNC_INTERVAL then return end
    lastEmoteMenuSync = now

    local success, menu = pcall(function() return CoreGui.RobloxGui.EmotesMenu.Children end)
    if not (success and menu) then return end
    
    pcall(function()
        local wheelVisible = menu.Main.EmotesWheel.Visible
        if wheelVisible then
            State.lastWheelVisibleTime = tick()
        end
        ToggleContainer.Visible = wheelVisible
    end)

    local errorMsg = menu:FindFirstChild("ErrorMessage")

    if errorMsg and errorMsg.Visible then
        if player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.RigType == Enum.HumanoidRigType.R6 then
            errorMsg.ErrorText.Text = "Only r15 does not work r6"
        elseif tick() - State.lastRadialActionTime < 2 then
            errorMsg.Visible = false
        end
    end
end)


function ErrorMessage(text, duration)

    if State.currentTimer then
        task.cancel(State.currentTimer)
        State.currentTimer = nil
    end
    
    local errorMessage = CoreGui.RobloxGui.EmotesMenu.Children.ErrorMessage
    local errorText = errorMessage.ErrorText
    
    errorText.Text = text
    
    errorMessage.Visible = true
    
    State.currentTimer = task.delay(duration, function()
        errorMessage.Visible = false
        State.currentTimer = nil
    end)
end

function stopEmotes()
    stopCurrentEmote()
end

function getCharacterAndHumanoid()
    local character = player.Character
    if not character then
        return nil, nil
    end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return nil, nil
    end
    return character, humanoid
end

function urlToId(animationId)
    animationId = string.gsub(animationId, "http://www%.roblox%.com/asset/%?id=", "")
    animationId = string.gsub(animationId, "rbxassetid://", "")
    return animationId
end

function resolveEmoteToAnimationId(emoteId)
    local fallbackId = tonumber(emoteId)
    if not emoteId or emoteId == "" then return fallbackId end

    local objects
    local ok = false
    local idStr = tostring(emoteId)
    for _, url in ipairs({
        "rbxassetid://" .. idStr,
        "http://www.roblox.com/asset/?id=" .. idStr
    }) do
        ok, objects = pcall(function()
            return game:GetObjects(url)
        end)
        if ok and type(objects) == "table" and #objects > 0 then
            break
        end
    end
    if ok and type(objects) == "table" then
        local function findAnimId(obj)
            if obj:IsA("Animation") then
                local animId = tonumber(urlToId(obj.AnimationId))
                if animId and animId > 0 then
                    return animId
                end
            end
            for _, child in ipairs(obj:GetChildren()) do
                local found = findAnimId(child)
                if found then return found end
            end
            return nil
        end

        local rootObj = objects[1]
        if rootObj and rootObj.Parent == nil then
            pcall(function() rootObj.Parent = workspace end)
        end
        if rootObj then
            local foundRoot = findAnimId(rootObj)
            if foundRoot then
                pcall(function() rootObj:Destroy() end)
                return foundRoot
            end
        end
        for _, obj in ipairs(objects) do
            local found = findAnimId(obj)
            pcall(function() obj:Destroy() end)
            if found then
                return found
            end
        end
    end
    return fallbackId
end

function saveFavoritesAnimations()
    if writefile then
        local jsonData = HttpService:JSONEncode(State.favoriteAnimations)
        writefile(State.favoriteAnimationsFileName, jsonData)
    end
end

function loadFavoritesAnimations()
    if readfile and isfile and isfile(State.favoriteAnimationsFileName) then
        local success, result = pcall(function()
            local fileContent = readfile(State.favoriteAnimationsFileName)
            return HttpService:JSONDecode(fileContent)
        end)
        if success and type(result) == "table" then
            local filtered = {}
            for _, fav in pairs(result) do
                local idNum = fav and tonumber(fav.id)
                if fav and idNum and (idNum > 0 or idNum < -1000) then
                    if fav.isCustomSet == nil and idNum < 0 then
                        fav.isCustomSet = true
                    end
                    if IsCustomSetData(fav) and not fav.customSetName and type(fav.name) == "string" then
                        local baseName = fav.name:gsub("%s*%-.*$", "")
                        fav.customSetName = baseName
                    end
                    table.insert(filtered, fav)
                end
            end
            State.favoriteAnimations = filtered
            State.favoriteSetVersion = State.favoriteSetVersion + 1
        end
    end
end

function disconnectAllConnections()
    for _, connection in pairs(State.guiConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    State.guiConnections = {}
    if ContextActionService then
        ContextActionService:UnbindAction("dark_EmoteWheelHotkeys")
    end
end

function loadSpeedEmoteConfig()
    State.speedEmoteEnabled = Config.EmoteSpeedEnabled
    if UI.SpeedBox then
        UI.SpeedBox.Text = tostring(Config.EmoteSpeed)
        updateSpeedBoxVisibility()
    end
end

function extractAssetId(imageUrl)
    local assetId = string.match(imageUrl, "Asset&id=(%d+)")
    return assetId
end

isRandomSlotEnabled = nil
isRandomSlotActive = nil

function isEmoteSearchActive()
    return State.currentMode == "emote" and State.emoteSearchTerm and State.emoteSearchTerm ~= ""
end

function isAnimationSearchActive()
    return State.currentMode == "animation" and State.animationSearchTerm and State.animationSearchTerm ~= ""
end

function isSearchActive()
    return isEmoteSearchActive() or isAnimationSearchActive()
end

function shouldRandomSlotBeShown()
    if Config.RandomEnabled ~= true then return false end
    if State.currentMode == "emote" then
        return not isEmoteSearchActive()
    elseif State.currentMode == "animation" then
        return not isAnimationSearchActive()
    end
    return false
end

function getFirstPageSize()
    if shouldRandomSlotBeShown() then
        return math.max(State.itemsPerPage - 1, 1)
    end
    return State.itemsPerPage
end

isRandomSlotEnabled = function()
    return Config.RandomEnabled == true
end

function calcPagesForList(count, isFirstList)
    if count <= 0 then return 0 end
    if isFirstList then
        local first = getFirstPageSize()
        if count <= first then return 1 end
        return 1 + math.ceil((count - first) / State.itemsPerPage)
    end
    return math.ceil(count / State.itemsPerPage)
end

function getCategoryStats()
    local stats = {}
    local randomCaptured = false
    local shouldShowRandom = shouldRandomSlotBeShown()

    local authenticEmotes = (Config.AuthenticFirstPage and State.currentMode == "emote") and (emotesDarkExecutorEnv().OwnedAuthenticEmotes or {}) or {}
    if #authenticEmotes > 0 then
        local pages = calcPagesForList(#authenticEmotes, false)
        table.insert(stats, { name = "Authentic", list = authenticEmotes, pages = pages, hasRandom = false })
    end

    local favoritesToUse = (State.currentMode == "animation") and (_G.filteredFavoritesAnimationsForDisplay or State.favoriteAnimations) or (_G.filteredFavoritesForDisplay or State.favoriteEmotes)
    if State.favoritesTabActive and #favoritesToUse > 0 then
        local hasRandom = not randomCaptured and shouldShowRandom
        if hasRandom then randomCaptured = true end
        local pages = calcPagesForList(#favoritesToUse, hasRandom)
        table.insert(stats, { name = "Favorites", list = favoritesToUse, pages = pages, hasRandom = hasRandom })
    end

    local normalList = {}
    if State.currentMode == "animation" then
        normalList = State.animationPageCache.normal or {}
    else
        normalList = State.emotePageCache.normal or {}
    end

    if not State.favoritesTabActive and #normalList > 0 then
        local hasRandom = not randomCaptured and shouldShowRandom
        if hasRandom then randomCaptured = true end
        local pages = calcPagesForList(#normalList, hasRandom)
        table.insert(stats, { name = "Normal", list = normalList, pages = pages, hasRandom = hasRandom })
    end

    return stats
end

isRandomSlotActive = function()
    if not shouldRandomSlotBeShown() then return false end
    local categories = getCategoryStats()
    local totalPages = 0
    for _, cat in ipairs(categories) do
        if cat.hasRandom then
            return State.currentPage == totalPages + 1
        end
        totalPages = totalPages + cat.pages
    end
    return false
end

function getPageSize(pageNumber, isFirstList)
    if isFirstList and pageNumber == 1 then
        return getFirstPageSize()
    end
    return State.itemsPerPage
end

function getListSlice(list, pageNumber, isFirstList)
    local pageSize = getPageSize(pageNumber, isFirstList)
    local startIndex
    if isFirstList and pageNumber == 1 then
        startIndex = 1
    elseif isFirstList then
        startIndex = getFirstPageSize() + (pageNumber - 2) * State.itemsPerPage + 1
    else
        startIndex = (pageNumber - 1) * State.itemsPerPage + 1
    end
    local endIndex = math.min(startIndex + pageSize - 1, #list)
    local items = {}
    for i = startIndex, endIndex do
        if list[i] then table.insert(items, list[i]) end
    end
    return items
end

function getRandomSourceList()
    if Config.RandomEnabled == false then
        return {}
    end
    if State.favoritesTabActive then
        if State.currentMode == "animation" then
            return _G.filteredFavoritesAnimationsForDisplay or State.favoriteAnimations
        end
        return _G.filteredFavoritesForDisplay or State.favoriteEmotes
    end
    if State.favoriteEnabled then
        if State.currentMode == "animation" then
            return State.filteredAnimations
        end
        return State.filteredEmotes
    end
    if Config.RandomMode == "Favorites" then
        if State.currentMode == "animation" then
            return _G.filteredFavoritesAnimationsForDisplay or State.favoriteAnimations
        end
        return _G.filteredFavoritesForDisplay or State.favoriteEmotes
    end
    if State.currentMode == "animation" then
        return State.filteredAnimations
    end
    return State.filteredEmotes
end

function pickRandomItem()
    local list = getRandomSourceList() or {}
    if #list == 0 then return nil end
    return list[math.random(1, #list)]
end

function pickRandomItemForMode()
    local list = getRandomSourceList() or {}
    if #list == 0 then return nil end
    if State.currentMode == "animation" then
        local filtered = {}
        for _, item in ipairs(list) do
            if item.bundledItems then
                table.insert(filtered, item)
            end
        end
        if #filtered == 0 then return nil end
        return filtered[math.random(1, #filtered)]
    end
    return list[math.random(1, #list)]
end
function updateRandomSlotBlocker(frontFrame, enable)
    if not frontFrame then return end
    local slot = frontFrame:FindFirstChild("1")
    if not slot or not slot:IsA("ImageLabel") then return end

    local blocker = slot:FindFirstChild("RandomBlocker")
    if enable then
        if not blocker then
            blocker = Instance.new("ImageButton")
            blocker.Name = "RandomBlocker"
            blocker.BackgroundTransparency = 1
            blocker.Size = UDim2.new(1, 0, 1, 0)
            blocker.Position = UDim2.new(0, 0, 0, 0)
            blocker.AutoButtonColor = false
            blocker.ZIndex = slot.ZIndex + 10
            blocker.Parent = slot
        else
            blocker.ZIndex = slot.ZIndex + 10
        end
        blocker.Active = true
    else
        if blocker then blocker:Destroy() end
        if State.randomSlotBlockerConn then
            State.randomSlotBlockerConn:Disconnect()
            State.randomSlotBlockerConn = nil
        end
    end
end

function clearCustomHitboxes()
    if State.randomSlotBlockerConn then
        State.randomSlotBlockerConn:Disconnect()
        State.randomSlotBlockerConn = nil
    end
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then return end
    local slot1 = frontFrame:FindFirstChild("1")
    if slot1 then
        local blocker = slot1:FindFirstChild("RandomBlocker")
        if blocker then blocker:Destroy() end
    end
    for _, child in pairs(frontFrame:GetChildren()) do
        if child:IsA("ImageLabel") then
            child.Active = false
        end
    end
    frontFrame.Active = true   
end

function applyEmotesButtonsActiveState()
end

function setEmotesButtonsActiveForFavorites()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then return end
    for _, child in pairs(frontFrame:GetChildren()) do
        if child:IsA("ImageLabel") then
            child.Active = true
        end
    end
    frontFrame.Active = true
end

function updateScriptPriorityOverlay()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then return end

    local enable = (State.favoriteEnabled or State.currentMode == "animation" or State.customAnimationEditorActive)
    local blocker = frontFrame:FindFirstChild("ScriptPriorityBlocker")
    if enable then
        if not blocker then
            blocker = Instance.new("ImageButton")
            blocker.Name = "ScriptPriorityBlocker"
            blocker.BackgroundTransparency = 1
            blocker.Size = UDim2.new(1, 0, 1, 0)
            blocker.Position = UDim2.new(0, 0, 0, 0)
            blocker.AutoButtonColor = false
            blocker.ZIndex = 9999
            blocker.Parent = frontFrame
            
            blocker.InputBegan:Connect(function(input)
                if State.hudEditorActive then return end
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                
                local okWheel, emotesWheel = pcall(function()
                    return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel
                end)
                if not (okWheel and emotesWheel) then return end
                if not emotesWheel.Visible then return end

                local actualPos = Vector2.new(input.Position.X, input.Position.Y)
                local absPos = emotesWheel.AbsolutePosition
                local absSize = emotesWheel.AbsoluteSize

                local inXBounds = (actualPos.X >= absPos.X) and (actualPos.X <= absPos.X + absSize.X)
                local inYBounds = (actualPos.Y >= absPos.Y) and (actualPos.Y <= absPos.Y + absSize.Y)
                if not (inXBounds and inYBounds) then return end

                local center = absPos + (absSize / 2)
                local dx = actualPos.X - center.X
                local dy = actualPos.Y - center.Y

                local distance = math.sqrt(dx*dx + dy*dy)
                local radius = math.min(absSize.X, absSize.Y) * 0.5
                if distance > radius then return end
                local dynamicDeadzone = radius * 0.2
                if distance < dynamicDeadzone then return end

                local sectorAngle = 360 / 8
                local angle = math.deg(math.atan2(dy, dx))
                local correctedAngle = (angle + 90 + (sectorAngle / 2)) % 360
                local index = math.floor(correctedAngle / sectorAngle) + 1
                if not (State.customAnimationEditorActive or State.favoriteEnabled or State.currentMode == "animation" or (index == 1 and isRandomSlotActive())) then return end

                handleSectorAction(index)
            end)
        end
        blocker.Active = true
    else
        if blocker then blocker:Destroy() end
    end
end

function applyRandomSlotVisual(frontFrame)
    if not frontFrame then return end
    local slot = frontFrame:FindFirstChild("1")
    if slot and slot:IsA("ImageLabel") then
        if not isRandomSlotEnabled() then
            AnimationSystem.ResetRandomSlot(frontFrame)
            return
        end
        if slot.Image ~= RANDOM_SLOT_ICON then
            slot.Image = RANDOM_SLOT_ICON
        end
        if slot.ImageColor3 ~= RANDOM_SLOT_COLOR then
            slot.ImageColor3 = RANDOM_SLOT_COLOR
        end
        if State.currentMode == "emote" then
            updateRandomSlotBlocker(frontFrame, true)
        else
            updateRandomSlotBlocker(frontFrame, false)
        end
        local idValue = slot:FindFirstChild("AnimationID")
        if idValue then idValue:Destroy() end
        local favoriteIcon = slot:FindFirstChild("FavoriteIcon")
        if favoriteIcon then favoriteIcon:Destroy() end
    end
end

function resetRandomSlotColor(frontFrame)
    if not frontFrame then return end
    local slot = frontFrame:FindFirstChild("1")
    if slot and slot:IsA("ImageLabel") then
        if slot.ImageColor3 == RANDOM_SLOT_COLOR then
            slot.ImageColor3 = Color3.new(1, 1, 1)
        end
        if slot.Image == RANDOM_SLOT_ICON then
            slot.Image = ""
        end
    end
    updateRandomSlotBlocker(frontFrame, false)
    if State.randomSpamConn then
        State.randomSpamConn:Disconnect()
        State.randomSpamConn = nil
    end
end

function applySearchSlot1Image()
    pcall(function()
        local frontFrame = game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
        local slot1 = frontFrame and frontFrame:FindFirstChild("1")
        local slot2 = frontFrame and frontFrame:FindFirstChild("2")
        if slot1 and slot1:IsA("ImageLabel") and slot2 and slot2:IsA("ImageLabel") then
            local img2 = slot2.Image
            if img2 and img2 ~= "" then
                slot1.Image = img2
            end
        end
    end)
end

function bumpImageUpdateToken()
    State.imageUpdateToken = State.imageUpdateToken + 1
end

local ContentProvider = game:GetService("ContentProvider")
function preloadThumbnail(url)
    if not url or url == "" then return end
    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync({Instance.new("ImageLabel", {Image = url})})
        end)
    end)
end

function enforceImages()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then return end
    
    local token = State.imageUpdateToken
    for slotName, targetImg in pairs(State.targetImages) do
        local slot = frontFrame:FindFirstChild(slotName)
        if slot and slot:IsA("ImageLabel") then
            if slot.Image ~= targetImg then
                slot.Image = targetImg
            end
            if slotName == "1" and isRandomSlotActive() then
                if slot.ImageColor3 ~= RANDOM_SLOT_COLOR then
                    slot.ImageColor3 = RANDOM_SLOT_COLOR
                end
            end
        end
    end
end

function spamRandomSlotVisual(frontFrame, token)
    if not frontFrame then return end
    State.targetImages["1"] = RANDOM_SLOT_ICON
    enforceImages()
end

function spamAnimationImages(frontFrame, imageMap, token)
    if not frontFrame then return end
    for k, v in pairs(imageMap or {}) do
        State.targetImages[k] = v
    end
    enforceImages()
end


function getEmoteName(assetId)
    local success, productInfo = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(tonumber(assetId))
    end)
    
    if success and productInfo then
        return productInfo.Name
    else
        return "Emote_" .. tostring(assetId)
    end
end

isInFavorites = function(assetId)
    if not assetId then return false end
    if State.favoriteSetBuiltVersion ~= State.favoriteSetVersion then
        State.favoriteEmoteSet = {}
        for _, favorite in pairs(State.favoriteEmotes) do
            if favorite.id then
                State.favoriteEmoteSet[tostring(favorite.id)] = true
            end
        end
        State.favoriteAnimationSet = {}
        for _, favorite in pairs(State.favoriteAnimations) do
            if favorite.id then
                State.favoriteAnimationSet[tostring(favorite.id)] = true
            end
        end
        State.favoriteSetBuiltVersion = State.favoriteSetVersion
    end
    if State.currentMode == "animation" then
        return State.favoriteAnimationSet[tostring(assetId)] == true
    end
    return State.favoriteEmoteSet[tostring(assetId)] == true
end

function rebuildEmoteNormalCache()
    if State.emotePageCache.version == State.emoteCacheVersion and State.emotePageCache.favVersion == State.favoriteSetVersion then
        return
    end
    if State.favoriteSetBuiltVersion ~= State.favoriteSetVersion then
        State.favoriteEmoteSet = {}
        for _, favorite in pairs(State.favoriteEmotes) do
            State.favoriteEmoteSet[tostring(favorite.id)] = true
        end
        State.favoriteAnimationSet = {}
        for _, favorite in pairs(State.favoriteAnimations) do
            State.favoriteAnimationSet[tostring(favorite.id)] = true
        end
        State.favoriteSetBuiltVersion = State.favoriteSetVersion
    end
    local normal = {}
    for _, emote in ipairs(State.filteredEmotes) do
        if not State.favoriteEmoteSet[tostring(emote.id)] then
            table.insert(normal, emote)
        end
    end
    State.emotePageCache.normal = normal
    State.emotePageCache.version = State.emoteCacheVersion
    State.emotePageCache.favVersion = State.favoriteSetVersion
end

function rebuildAnimationNormalCache()
    if State.animationPageCache.version == State.animationCacheVersion and State.animationPageCache.favVersion == State.favoriteSetVersion then
        return
    end
    if State.favoriteSetBuiltVersion ~= State.favoriteSetVersion then
        State.favoriteEmoteSet = {}
        for _, favorite in pairs(State.favoriteEmotes) do
            State.favoriteEmoteSet[tostring(favorite.id)] = true
        end
        State.favoriteAnimationSet = {}
        for _, favorite in pairs(State.favoriteAnimations) do
            State.favoriteAnimationSet[tostring(favorite.id)] = true
        end
        State.favoriteSetBuiltVersion = State.favoriteSetVersion
    end
    local normal = {}
    for _, animation in ipairs(State.filteredAnimations) do
        if not State.favoriteAnimationSet[tostring(animation.id)] then
            table.insert(normal, animation)
        end
    end
    State.animationPageCache.normal = normal
    State.animationPageCache.version = State.animationCacheVersion
    State.animationPageCache.favVersion = State.favoriteSetVersion
end

function getCustomSetIcon(setName)
    local set = State.CustomAnimations and State.CustomAnimations.Sets and State.CustomAnimations.Sets[setName]
    local meta = set and set.__meta or {}
    local iconImage = meta.IconImage or DEFAULT_IDLE_ICON_ID
    local iconColor = TableToColor(meta.IconColor or ColorToTable(DEFAULT_IDLE_ICON_COLOR))
    return iconImage, iconColor
end

function IsCustomSetData(data)
    if not data then return false end
    if data.isCustomSet then return true end
    local idNum = tonumber(data.id)
    return idNum and idNum < 0 or false
end

function GetCustomSetName(data)
    if not data then return nil end
    local name = data.customSetName or data.name
    if type(name) == "string" then
        name = name:gsub("%s*%-.*$", "")
    end
    return name
end

function updateAnimationImages(currentPageAnimations, randomActive)
    local token = State.imageUpdateToken
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if not success or not frontFrame then
        return
    end

    if randomActive then
        applyRandomSlotVisual(frontFrame)
        State.targetImages = {["1"] = RANDOM_SLOT_ICON}
        spamRandomSlotVisual(frontFrame, token)
    else
        State.targetImages = {}
        resetRandomSlotColor(frontFrame)
    end

    local startSlot = randomActive and 2 or 1
    local imageMap = {}
    local newTargetImages = {}
    if randomActive then
        newTargetImages["1"] = RANDOM_SLOT_ICON
    end

    for i = 1, 12 do
        if i >= startSlot then
            local listIndex = randomActive and (i - 1) or i
            local animationData = currentPageAnimations[listIndex]
            if animationData and animationData.id then
                local idStr = tostring(animationData.id)
                local image
                if IsCustomSetData(animationData) then
                    local customImage = getCustomSetIcon(GetCustomSetName(animationData) or animationData.name)
                    image = GetAsset(customImage)
                else
                    image = "rbxthumb://type=BundleThumbnail&id=" .. idStr .. "&w=420&h=420"
                end
                newTargetImages[tostring(i)] = image
                imageMap[tostring(i)] = image
            else
                newTargetImages[tostring(i)] = ""
                imageMap[tostring(i)] = ""
            end
        end
    end
    
    State.targetImages = newTargetImages

    for slotName, image in pairs(imageMap) do
        local child = frontFrame:FindFirstChild(slotName)
        if child and child:IsA("ImageLabel") then
            preloadThumbnail(image)
            child.Image = image
            
            local listIndex = randomActive and (tonumber(slotName) - 1) or tonumber(slotName)
            local animationData = currentPageAnimations[listIndex]
            if animationData and animationData.id then
                local idValue = child:FindFirstChild("AnimationID") or Instance.new("IntValue")
                idValue.Name = "AnimationID"
                idValue.Value = tonumber(animationData.id) or 0
                idValue.Parent = child
                
                if IsCustomSetData(animationData) then
                    local _, customColor = getCustomSetIcon(GetCustomSetName(animationData) or animationData.name)
                    child.ImageColor3 = customColor
                else
                    child.ImageColor3 = Color3.new(1, 1, 1)
                end
            elseif not randomActive and child.ImageColor3 == RANDOM_SLOT_COLOR then
                child.ImageColor3 = Color3.new(1, 1, 1)
            end
        end
    end
    
    applyEmotesButtonsActiveState()
end


function updateFavoriteIcon(imageLabel, assetId, isFavorite)
    local favoriteIcon = imageLabel:FindFirstChild("FavoriteIcon")
    
    if not favoriteIcon then
        favoriteIcon = Instance.new("ImageLabel")
        favoriteIcon.Name = "FavoriteIcon"
        favoriteIcon.Size = UDim2.new(0.3, 0, 0.3, 0) 
        favoriteIcon.Position = UDim2.new(0.7, 0, 0, 0)
        favoriteIcon.AnchorPoint = Vector2.new(0, 0)
        favoriteIcon.BackgroundTransparency = 1
        favoriteIcon.ZIndex = imageLabel.ZIndex + 5
        favoriteIcon.ScaleType = Enum.ScaleType.Fit
        favoriteIcon.Parent = imageLabel
    end
    
    if isFavorite then
        favoriteIcon.Image = State.favoriteIconId
    else
        favoriteIcon.Image = State.notFavoriteIconId 
    end
end

function updateAllFavoriteIcons()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if success and frontFrame then
        if not State.favoriteEnabled then
            for _, child in pairs(frontFrame:GetChildren()) do
                if child:IsA("ImageLabel") then
                    local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                    if favoriteIcon then favoriteIcon:Destroy() end
                end
            end
            return
        end
        local randomActive = isRandomSlotActive()
        for _, child in pairs(frontFrame:GetChildren()) do
            if child:IsA("ImageLabel") and child.Image ~= "" and (not randomActive or child.Name ~= "1") then
                local assetId
                if State.currentMode == "animation" then
                    local idValue = child:FindFirstChild("AnimationID")
                    if idValue then
                        assetId = idValue.Value
                    end
                else
                    assetId = extractAssetId(child.Image)
                end
                
                if assetId then
                    local isFavorite = isInFavorites(assetId)
                    updateFavoriteIcon(child, assetId, isFavorite)
                end
            end
        end
        applyEmotesButtonsActiveState()
    end
end

function updateAnimations()
    local character, humanoid = getCharacterAndHumanoid()
    if not character or not humanoid then
        return
    end

    local humanoidDescription = humanoid.HumanoidDescription
    if not humanoidDescription then
        if not State.pendingAnimRetry then
            State.pendingAnimRetry = true
            task.delay(0.2, function()
                State.pendingAnimRetry = false
                if State.currentMode == "animation" then
                    updateAnimations()
                end
            end)
        end
        return
    end

    bumpImageUpdateToken()
    rebuildAnimationNormalCache()

    local currentPageAnimations = {}
    local animationTable = {}
    local equippedAnimations = {}

    local categories = getCategoryStats()
    local accumulatedPages = 0
    local currentCat = nil
    
    for _, cat in ipairs(categories) do
        if State.currentPage <= accumulatedPages + cat.pages then
            local adjustedPage = State.currentPage - accumulatedPages
            currentPageAnimations = getListSlice(cat.list, adjustedPage, cat.hasRandom)
            currentCat = cat
            break
        end
        accumulatedPages = accumulatedPages + cat.pages
    end

    local randomActive = isRandomSlotActive()
    if randomActive then
        local randomFallback = currentPageAnimations[1] or (State.filteredAnimations and State.filteredAnimations[1])
        if randomFallback then
            animationTable["Random Animation"] = {randomFallback.id}
            table.insert(equippedAnimations, "Random Animation")
        end
    end

    State.animImageRetry = 0
    for _, animation in pairs(currentPageAnimations) do
        local animationName = animation.name
        local animationId = animation.id
        animationTable[animationName] = {animationId}
        table.insert(equippedAnimations, animationName)
    end

    humanoidDescription:SetEmotes(animationTable)
    humanoidDescription:SetEquippedEmotes(equippedAnimations)
    
    updateAnimationImages(currentPageAnimations, randomActive)
    if State.favoriteEnabled then
        setEmotesButtonsActiveForFavorites()
    end

    task.delay(0.2, function()
        if State.favoriteEnabled then
            setEmotesButtonsActiveForFavorites()
        end
        if State.favoriteEnabled then
            updateAllFavoriteIcons()
        end
    end)
end

updateEmotes = function()
    local character, humanoid = getCharacterAndHumanoid()
    if not character or not humanoid then
        return
    end

    if State.currentMode == "animation" then
        updateAnimations()
        return
    end
    
    bumpImageUpdateToken()
    local token = State.imageUpdateToken
    
    if State.animImageSpamConn then
        State.animImageSpamConn:Disconnect()
        State.animImageSpamConn = nil
        State.animImageSpamMap = nil
        State.animImageSpamTicks = nil
        State.animImageSpamToken = State.animImageSpamToken + 1
    end

    local humanoidDescription = humanoid.HumanoidDescription
    if not humanoidDescription then
        return
    end

    local currentPageEmotes = {}
    local emoteTable = {}
    local equippedEmotes = {}

    rebuildEmoteNormalCache()
    local categories = getCategoryStats()
    local accumulatedPages = 0
    local currentCat = nil
    
    for _, cat in ipairs(categories) do
        if State.currentPage <= accumulatedPages + cat.pages then
            local adjustedPage = State.currentPage - accumulatedPages
            currentPageEmotes = getListSlice(cat.list, adjustedPage, cat.hasRandom)
            currentCat = cat
            break
        end
        accumulatedPages = accumulatedPages + cat.pages
    end

    local randomActive = isRandomSlotActive()
    if randomActive then
        local randomFallback = currentPageEmotes[1] or (State.filteredEmotes and State.filteredEmotes[1])
        if randomFallback then
            emoteTable["Random Emote"] = {randomFallback.id}
            table.insert(equippedEmotes, "Random Emote")
        end
    end

    for _, emote in pairs(currentPageEmotes) do
        local emoteName = emote.name
        local emoteId = emote.id
        emoteTable[emoteName] = {emoteId}
        table.insert(equippedEmotes, emoteName)
    end

    humanoidDescription:SetEmotes(emoteTable)
    humanoidDescription:SetEquippedEmotes(equippedEmotes)
    
    local newTargetImages = {}
    if randomActive then
        newTargetImages["1"] = RANDOM_SLOT_ICON
    end

    local startSlot = randomActive and 2 or 1
    for i = 1, 12 do
        if i >= startSlot then
            local listIndex = randomActive and (i - 1) or i
            local emoteData = currentPageEmotes[listIndex]
            if emoteData and emoteData.id then
                local idStr = tostring(emoteData.id)
                newTargetImages[tostring(i)] = "rbxthumb://type=Asset&id=" .. idStr .. "&w=420&h=420"
            else
                newTargetImages[tostring(i)] = ""
            end
        end
    end
    
    State.targetImages = newTargetImages

    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if success and frontFrame then
        for slotName, image in pairs(newTargetImages) do
            local child = frontFrame:FindFirstChild(slotName)
            if child and child:IsA("ImageLabel") then
                child.Image = image
                if slotName == "1" and randomActive then
                    child.ImageColor3 = RANDOM_SLOT_COLOR
                else
                    child.ImageColor3 = Color3.new(1, 1, 1)
                end
            end
        end
        
        if State.favoriteEnabled then
            setEmotesButtonsActiveForFavorites()
        end
        if randomActive then
            applyRandomSlotVisual(frontFrame)
            spamRandomSlotVisual(frontFrame, token)
        else
            resetRandomSlotColor(frontFrame)
        end
    end

    task.delay(0.2, function()
        if State.favoriteEnabled then
            setEmotesButtonsActiveForFavorites()
        end
        if State.favoriteEnabled then
            updateAllFavoriteIcons()
        end
    end)
end

calculateTotalPages = function()
    if State.currentMode == "animation" then
        rebuildAnimationNormalCache()
    else
        rebuildEmoteNormalCache()
    end

    local categories = getCategoryStats()
    local total = 0
    for _, cat in ipairs(categories) do
        total = total + cat.pages
    end
    return math.max(total, 1)
end

function isGivenAnimation(animationHolder, animationId)
    for _, animation in animationHolder:GetChildren() do
        if animation:IsA("Animation") and urlToId(animation.AnimationId) == animationId then
            return true
        end
    end
    return false
end

function isToolAnimation(animationTrack)
    local animation = animationTrack and animationTrack.Animation
    if not animation then return false end
    local current = animation.Parent
    while current do
        if current:IsA("Tool") then
            return true
        end
        current = current.Parent
    end
    return false
end

function findAnimationInDescendants(folder, animationId)
    if not folder then return false end
    for _, obj in ipairs(folder:GetDescendants()) do
        if obj:IsA("Animation") and urlToId(obj.AnimationId) == animationId then
            return true
        end
    end
    return false
end

toolAnimationIds = {}

function refreshToolAnimationIds()
    local newSet = {}
    local function addFrom(container)
        if not container then return end
        for _, tool in ipairs(container:GetChildren()) do
            if tool:IsA("Tool") then
                for _, obj in ipairs(tool:GetDescendants()) do
                    if obj:IsA("Animation") then
                        local animId = urlToId(obj.AnimationId)
                        if animId ~= "" and animId ~= "0" then
                            newSet[animId] = true
                        end
                    end
                end
            end
        end
    end
    addFrom(player.Character)
    addFrom(player.Backpack)
    toolAnimationIds = newSet
end

function isDancing(character, animationTrack)
    if not character or not character.Animate or not animationTrack or not animationTrack.Animation then
        return false
    end
    if isToolAnimation(animationTrack) then
        return false
    end
    local animationId = urlToId(animationTrack.Animation.AnimationId)
    if toolAnimationIds[animationId] then
        return false
    end
    if findAnimationInDescendants(character.Animate:FindFirstChild("Tools"), animationId) then
        return false
    end
    for _, animationHolder in character.Animate:GetChildren() do
        if animationHolder:IsA("StringValue") then
            local sharesAnimationId = isGivenAnimation(animationHolder, animationId)
            if sharesAnimationId then
                return false
            end
        end
    end
    return true
end

function createGUIElements()
    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then
        return false
    end

    if UI.CustomFrames then
        for _, frame in pairs(UI.CustomFrames) do
            if frame and frame.Parent then frame:Destroy() end
        end
    end
    UI.CustomFrames = {}

    if emotesWheel:FindFirstChild("Under") then
        emotesWheel.Under:Destroy()
    end
    if emotesWheel:FindFirstChild("Top") then
        emotesWheel.Top:Destroy()
    end
    if emotesWheel:FindFirstChild("EmoteWalkButton") then
        emotesWheel.EmoteWalkButton:Destroy()
    end
    if emotesWheel:FindFirstChild("Favorite") then
        emotesWheel.Favorite:Destroy()
    end
    if emotesWheel:FindFirstChild("FavoritesTab") then
        emotesWheel.FavoritesTab:Destroy()
    end
    if emotesWheel:FindFirstChild("SpeedEmote") then
        emotesWheel.SpeedEmote:Destroy()
    end
    if emotesWheel:FindFirstChild("Changepage") then
        emotesWheel.Changepage:Destroy()
    end
    if emotesWheel:FindFirstChild("SpeedBox") then
        emotesWheel.SpeedBox:Destroy()
    end
    if emotesWheel:FindFirstChild("Reload") then
        emotesWheel.Reload:Destroy()
    end

    UI.Under = Instance.new("Frame")
    local UIListLayout = Instance.new("UIListLayout")
    UI._1left = Instance.new("ImageButton")
    UI._9right = Instance.new("ImageButton")
    UI._4pages = Instance.new("TextLabel")
    UI._3TextLabel = Instance.new("TextLabel")
    UI._2Routenumber = Instance.new("TextBox")
    UI.EmoteWalkButton = Instance.new("ImageButton")
    local UICorner_Left = Instance.new("UICorner")
    UICorner_Left.CornerRadius = UDim.new(0, 10)
    UICorner_Left.Parent = UI._1left
    
    local UICorner_Right = Instance.new("UICorner")
    UICorner_Right.CornerRadius = UDim.new(0, 10)
    UICorner_Right.Parent = UI._9right

    local UICorner1 = Instance.new("UICorner")
    UI.Top = Instance.new("Frame")
    local UIListLayout_2 = Instance.new("UIListLayout")
    local UICorner = Instance.new("UICorner")
    UI.Search = Instance.new("TextBox")
    UI.Favorite = Instance.new("ImageButton")
    local UICorner2 = Instance.new("UICorner")
    UI.FavoritesTab = Instance.new("ImageButton")
    local UICorner3 = Instance.new("UICorner")
    UI.SpeedBox = Instance.new("TextBox")
    local UICorner_4 = Instance.new("UICorner")
    UI.SpeedEmote = Instance.new("ImageButton")
    local UICorner_2 = Instance.new("UICorner")
    UI.Changepage = Instance.new("ImageButton")
    local UICorner_5 = Instance.new("UICorner")
    UI.Reload = Instance.new("ImageButton")
    local UICorner_6 = Instance.new("UICorner")

    UI.Under.Name = "Under"
    UI.Under.Parent = emotesWheel
    UI.Under.BackgroundTransparency = 1.000
    UI.Under.BorderSizePixel = 0
    UI.Under.Position = UDim2.new(0.129999995, 0, 1, 0)
    UI.Under.Size = UDim2.new(0.737500012, 0, 0.132499993, 0)

    UIListLayout.Parent = UI.Under
    UIListLayout.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Center

    UI._1left.Name = "1left"
    UI._1left.Parent = UI.Under
    UI._1left.BackgroundTransparency = 1.000
    UI._1left.BorderSizePixel = 0
    UI._1left.Size = UDim2.new(0.169491529, 0, 0.94339627, 0)
    UI._1left.Image = "rbxassetid://93111945058621"
    UI._1left.ImageColor3 = Color3.fromRGB(0, 0, 0)
    UI._1left.ImageTransparency = 0.400

    UI._9right.Name = "9right"
    UI._9right.Parent = UI.Under
    UI._9right.BackgroundTransparency = 1.000
    UI._9right.BorderSizePixel = 0
    UI._9right.Size = UDim2.new(0.169491529, 0, 0.94339627, 0)
    UI._9right.Image = "rbxassetid://107938916240738"
    UI._9right.ImageColor3 = Color3.fromRGB(0, 0, 0)
    UI._9right.ImageTransparency = 0.400

    UI._4pages.Name = "4pages"
    UI._4pages.Parent = UI.Under
    UI._4pages.BackgroundTransparency = 1.000
    UI._4pages.BorderSizePixel = 0
    UI._4pages.Size = UDim2.new(0.159322038, 0, 0.811320841, 0)
    UI._4pages.Font = Enum.Font.SourceSansBold
    UI._4pages.Text = "1"
    UI._4pages.TextColor3 = Color3.fromRGB(0, 0, 0)
    UI._4pages.TextScaled = true
    UI._4pages.TextSize = 14.000
    UI._4pages.TextTransparency = 0.400
    UI._4pages.TextWrapped = true

    UI._3TextLabel.Name = "3TextLabel"
    UI._3TextLabel.Parent = UI.Under
    UI._3TextLabel.BackgroundTransparency = 1.000
    UI._3TextLabel.BorderSizePixel = 0
    UI._3TextLabel.Size = UDim2.new(0.338983059, 0, 0.94339627, 0)
    UI._3TextLabel.Font = Enum.Font.SourceSansBold
    UI._3TextLabel.Text = " ------ "
    UI._3TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
    UI._3TextLabel.TextScaled = true
    UI._3TextLabel.TextSize = 14.000
    UI._3TextLabel.TextTransparency = 0.400
    UI._3TextLabel.TextWrapped = true

    UI._2Routenumber.Name = "2Route-number"
    UI._2Routenumber.Parent = UI.Under
    UI._2Routenumber.Active = true
    UI._2Routenumber.BackgroundTransparency = 1.000
    UI._2Routenumber.BorderSizePixel = 0
    UI._2Routenumber.Size = UDim2.new(0.159322038, 0, 0.811320841, 0)
    UI._2Routenumber.Font = Enum.Font.SourceSansBold
    UI._2Routenumber.PlaceholderColor3 = Color3.fromRGB(0, 0, 0)
    UI._2Routenumber.Text = "1"
    UI._2Routenumber.TextColor3 = Color3.fromRGB(0, 0, 0)
    UI._2Routenumber.TextScaled = true
    UI._2Routenumber.TextSize = 14.000
    UI._2Routenumber.TextTransparency = 0.400
    UI._2Routenumber.TextWrapped = true

    UI.Top.Name = "Top"
    UI.Top.Parent = emotesWheel
    UI.Top.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.Top.BackgroundTransparency = 0.400
    UI.Top.BorderSizePixel = 0
    UI.Top.Position = UDim2.new(0.22, 0, -0.109999999, 0)
    UI.Top.Size = UDim2.new(0.645, 0, 0.0949999914, 0)

    UIListLayout_2.Parent = UI.Top
    UIListLayout_2.FillDirection = Enum.FillDirection.Horizontal
    UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_2.VerticalAlignment = Enum.VerticalAlignment.Center

    UICorner.CornerRadius = UDim.new(0, 20)
    UICorner.Parent = UI.Top

    UI.Search.Name = "Search"
    UI.Search.Parent = UI.Top
    UI.Search.BackgroundTransparency = 1.000
    UI.Search.Size = UDim2.new(0.864406765, 0, 0.81578958, 0)
    UI.Search.Font = Enum.Font.SourceSansBold
    UI.Search.PlaceholderText = "Search/ID"
    UI.Search.Text = ""
    UI.Search.TextColor3 = Color3.fromRGB(255, 255, 255)
    UI.Search.TextScaled = true
    UI.Search.TextSize = 14.000
    UI.Search.TextWrapped = true

    UI.EmoteWalkButton.Name = "EmoteWalkButton"
    UI.EmoteWalkButton.Parent = emotesWheel
    UI.EmoteWalkButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.EmoteWalkButton.BackgroundTransparency = 0.400
    UI.EmoteWalkButton.BorderSizePixel = 0
    UI.EmoteWalkButton.Position = UDim2.new(0.889999986, 0, -0.107500002, 0)
    UI.EmoteWalkButton.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    UI.EmoteWalkButton.Image = State.defaultButtonImage

    UICorner1.CornerRadius = UDim.new(0, 10)
    UICorner1.Parent = UI.EmoteWalkButton

    UI.Favorite.Name = "Favorite"
    UI.Favorite.Parent = emotesWheel
    UI.Favorite.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.Favorite.BackgroundTransparency = 0.400
    UI.Favorite.BorderSizePixel = 0
    UI.Favorite.Position = UDim2.new(0.1145, 0, -0.108000003, 0)
    UI.Favorite.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    UI.Favorite.Image = "rbxassetid://124025954365505"

    UICorner2.CornerRadius = UDim.new(0, 10)
    UICorner2.Parent = UI.Favorite

    UI.FavoritesTab.Name = "FavoritesTab"
    UI.FavoritesTab.Parent = emotesWheel
    UI.FavoritesTab.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.FavoritesTab.BackgroundTransparency = 0.400
    UI.FavoritesTab.BorderSizePixel = 0
    UI.FavoritesTab.Position = UDim2.new(0.019, 0, -0.108000003, 0)
    UI.FavoritesTab.Size = UDim2.new(0.0875, 0, 0.0875, 0)
    UI.FavoritesTab.Image = State.favoriteIconId
    UI.FavoritesTab.ImageColor3 = Color3.fromRGB(255, 0, 0)
    UI.FavoritesTab.ZIndex = 4

    UICorner3.CornerRadius = UDim.new(0, 10)
    UICorner3.Parent = UI.FavoritesTab

    task.spawn(function()
        local favoriteTab = UI.FavoritesTab
        while favoriteTab and favoriteTab.Parent do
            favoriteTab.ImageColor3 = Color3.fromHSV((tick() * FAVORITE_STAR_RGB_SPEED) % 1, 1, 1)
            task.wait(0.05)
        end
    end)

    UI.SpeedBox.Name = "SpeedBox"
    UI.SpeedBox.Parent = emotesWheel
    UI.SpeedBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.SpeedBox.BackgroundTransparency = 0.400
    UI.SpeedBox.BorderSizePixel = 0
    UI.SpeedBox.Position = UDim2.new(0.0189999398, 0, -0.000499992399, 0)
    UI.SpeedBox.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    UI.SpeedBox.Visible = false
    UI.SpeedBox.Font = Enum.Font.SourceSansBold
    UI.SpeedBox.PlaceholderColor3 = Color3.fromRGB(178, 178, 178)
    UI.SpeedBox.Text = "1"
    UI.SpeedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    UI.SpeedBox.TextScaled = true
    UI.SpeedBox.TextWrapped = true
    UI.SpeedBox:GetPropertyChangedSignal("Text"):Connect(function()
       UI.SpeedBox.Text = UI.SpeedBox.Text:gsub("[^%d.]", "")
    end)
    UI.SpeedBox.ZIndex = 2

    UICorner_4.CornerRadius = UDim.new(0, 10)
    UICorner_4.Parent = UI.SpeedBox

    UI.SpeedEmote.Name = "SpeedEmote"
    UI.SpeedEmote.Parent = emotesWheel
    UI.SpeedEmote.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.SpeedEmote.BackgroundTransparency = 0.400
    UI.SpeedEmote.BorderSizePixel = 0
    UI.SpeedEmote.Position = UDim2.new(0.888999999, 0, -0, 0)
    UI.SpeedEmote.Size = UDim2.new(0.0874999985, 0, 0.0874999985, 0)
    UI.SpeedEmote.Image = "rbxassetid://116056570415896"
    UI.SpeedEmote.ZIndex = 2

    UICorner_2.CornerRadius = UDim.new(0, 10)
    UICorner_2.Parent = UI.SpeedEmote

UI.Changepage.Name = "Changepage"
UI.Changepage.Parent = emotesWheel
UI.Changepage.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
UI.Changepage.BackgroundTransparency = 0.400
UI.Changepage.BorderColor3 = Color3.fromRGB(0, 0, 0)
UI.Changepage.BorderSizePixel = 0
UI.Changepage.Position = UDim2.new(0.019, 0,1.021, 0)
UI.Changepage.Size = UDim2.new(0.087, 0,0.087, 0)
UI.Changepage.ZIndex = 3
UI.Changepage.Image = "rbxassetid://13285615740"

UICorner_5.CornerRadius = UDim.new(0, 10)
UICorner_5.Parent = UI.Changepage

    UI.Reload.Name = "Reload"
    UI.Reload.Parent = emotesWheel
    UI.Reload.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    UI.Reload.BackgroundTransparency = 0.400
    UI.Reload.BorderSizePixel = 0
    UI.Reload.Position = UDim2.new(0.888999999, 0, 1.02100003, 0)
    UI.Reload.Size = UDim2.new(0.0869999975, 0, 0.0869999975, 0)
    UI.Reload.ZIndex = 3
    UI.Reload.Image = "rbxassetid://127493377027615"

    UICorner_6.CornerRadius = UDim.new(0, 10)
    UICorner_6.Parent = UI.Reload

    local function spawnCustomFrame(name, zIndex)
        local cf = Instance.new("Frame")
        cf.Name = name
        cf.Parent = emotesWheel
        cf.BackgroundColor3 = Color3.fromRGB(0,0,0)
        cf.BackgroundTransparency = 0.4
        cf.ZIndex = zIndex or 3
        cf.BorderSizePixel = 0
        cf.Active = true
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = cf

        if not UI.CustomFrames then UI.CustomFrames = {} end
        UI.CustomFrames[name] = cf

        return cf
    end

    local function recordDefaults()
        local allMovable = getMovableElements()
        for name, el in pairs(allMovable) do
             HUD.DefaultPositions[name] = el.Position
             HUD.DefaultSizes[name] = el.Size
             if el:IsA("TextLabel") or el:IsA("TextBox") then
                 HUD.DefaultTexts[name] = el.Text
                 if el:IsA("TextBox") then
                     HUD.DefaultPlaceholders[name] = el.PlaceholderText
                 end
             end
        end
    end
    
    if Config.CustomFrames then
        for name, data in pairs(Config.CustomFrames) do
            spawnCustomFrame(name, data.ZIndex or 3)
        end
    end
    
    recordDefaults()
    loadSpeedEmoteConfig()

    connectEvents()
    State.isGUICreated = true
    
    ApplyTheme(themes[currentThemeName] or themes.Default)
    
    updateGUIColors()
    
    ApplyUIVisibility()
    
    if ApplyFreezeButtonVisual then ApplyFreezeButtonVisual() end
    if applySavedPositions then applySavedPositions() end
    if updateHUDLayouts then updateHUDLayouts() end

    -- Entrada suave dos controles superiores ao criar a interface.
    local topEntranceInfo = TweenInfo.new(1.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local topEntranceTargets = {
        { object = UI.Top, property = "BackgroundTransparency", value = 0.4 },
        { object = UI.EmoteWalkButton, property = "BackgroundTransparency", value = 0.4 },
        { object = UI.Favorite, property = "BackgroundTransparency", value = 0.4 },
        { object = UI.FavoritesTab, property = "BackgroundTransparency", value = 0.4 },
        { object = UI.SpeedEmote, property = "BackgroundTransparency", value = 0.4 },
    }
    for _, target in ipairs(topEntranceTargets) do
        if target.object then
            target.object.BackgroundTransparency = 1
            TweenService:Create(target.object, topEntranceInfo, { [target.property] = target.value }):Play()
            if target.object:IsA("ImageButton") then
                target.object.ImageTransparency = 1
                TweenService:Create(target.object, topEntranceInfo, { ImageTransparency = 0 }):Play()
            end
        end
    end
    if UI.Search then
        UI.Search.TextTransparency = 1
        TweenService:Create(UI.Search, topEntranceInfo, { TextTransparency = 0 }):Play()
    end
    
    return true
end

updatePageDisplay = function()
    if UI._4pages and UI._2Routenumber then
        UI._4pages.Text = tostring(State.totalPages)
        UI._2Routenumber.Text = tostring(State.currentPage)
    end
end

favoriteEmoteSaveToken = 0

function queueFavoriteEmoteSave()
    favoriteEmoteSaveToken = favoriteEmoteSaveToken + 1
    local saveToken = favoriteEmoteSaveToken

    task.spawn(function()
        task.wait()
        if saveToken ~= favoriteEmoteSaveToken then return end

        local pageSnapshot = DeepCopy(State.EmotePages)
        local ok, saveError = pcall(function()
            State.SaveEmotePages(pageSnapshot)
        end)
        if not ok then
            warn("[Emotes Dark] Failed to save favorites: " .. tostring(saveError))
        end
    end)
end

favoriteEmoteRefreshToken = 0

function queueFavoriteEmoteRefresh()
    favoriteEmoteRefreshToken = favoriteEmoteRefreshToken + 1
    local refreshToken = favoriteEmoteRefreshToken

    task.defer(function()
        if refreshToken ~= favoriteEmoteRefreshToken then return end

        State.totalPages = calculateTotalPages()
        updatePageDisplay()
        updateEmotes()
        updateAllFavoriteIcons()
    end)
end


toggleFavorite = function(emoteId, emoteName)
    local found = false
    local index = 0

    for i, fav in pairs(State.favoriteEmotes) do
        if tostring(fav.id) == tostring(emoteId) then
            found = true
            index = i
            break
        end
    end

    if found then
        table.remove(State.favoriteEmotes, index)
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Favorite System',
            Content = '🗑️ Removed "' .. emoteName .. '" from favorites',
            Duration = 3
        })
    else
        table.insert(State.favoriteEmotes, {
            id = emoteId,
            name = emoteName .. " - ⭐"
        })
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Favorite System',
            Content = '✅ Added "' .. emoteName .. '" to favorites',
            Duration = 3
        })
    end

    State.EmotePages.Sets[State.currentEmotePageName] = DeepCopy(State.favoriteEmotes)

    State.favoriteSetVersion = State.favoriteSetVersion + 1
    updateAllFavoriteIcons()
    queueFavoriteEmoteSave()
    queueFavoriteEmoteRefresh()
end


toggleFavoriteAnimation = function(animationData)
    local found = false
    local index = 0

    for i, fav in pairs(State.favoriteAnimations) do
        if fav.id == animationData.id then
            found = true
            index = i
            break
        end
    end

    if found then
        table.remove(State.favoriteAnimations, index)
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Favorite System',
            Content = '🗑️ Removed "' .. animationData.name .. '" from favorites',
            Duration = 3
        })
    else
        table.insert(State.favoriteAnimations, {
            id = animationData.id,
            name = animationData.name .. " - ⭐",
            bundledItems = animationData.bundledItems,
            isCustomSet = IsCustomSetData(animationData),
            customSetName = IsCustomSetData(animationData) and (type(animationData.name) == "string" and animationData.name:gsub("%s*%-.*$", "") or animationData.name) or nil
        })
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Favorite System',
            Content = '✅ Added "' .. animationData.name .. '" to favorites',
            Duration = 3
        })
    end

    State.favoriteSetVersion = State.favoriteSetVersion + 1
    
    pcall(function()
        if not isfolder("dark") then makefolder("dark") end
        writefile(State.favoriteAnimationsFileName, HttpService:JSONEncode(State.favoriteAnimations))
    end)

    State.totalPages = calculateTotalPages()
    updatePageDisplay()
    updateAnimations()
    updateAllFavoriteIcons()
end



function setupEmoteClickDetection()
    if State.isMonitoringClicks then
        return
    end
    
    State.emoteMonitorToken = State.emoteMonitorToken + 1
    local token = State.emoteMonitorToken

    local function monitorEmotes()
        while State.favoriteEnabled and State.currentMode == "emote" and State.emoteMonitorToken == token do
            local success, frontFrame = pcall(function()
                return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
            end)

            if success and frontFrame then
                for _, connection in pairs(State.emoteClickConnections) do
                    if connection then
                        connection:Disconnect()
                    end
                end
                State.emoteClickConnections = {}

                local randomActive = isRandomSlotActive()
                for _, child in pairs(frontFrame:GetChildren()) do
                    if child:IsA("ImageLabel") and child.Image ~= "" and (not randomActive or child.Name ~= "1") then
                        local imageUrl = child.Image
                        local assetId = extractAssetId(imageUrl)
                        if assetId then
                            local isFavorite = isInFavorites(assetId)
                            updateFavoriteIcon(child, assetId, isFavorite)
                        end
                    end
                end

                applyEmotesButtonsActiveState()
            end

            task.wait(0.25)
        end
    end

    if State.favoriteEnabled then
        State.isMonitoringClicks = true
        task.spawn(monitorEmotes)
    end
end

applyAnimation = function(animationData)
    local player = game.Players.LocalPlayer
    local character = player.Character or player.CharacterAdded:Wait()
    local humanoid = character:FindFirstChild("Humanoid")
    local animate = character:FindFirstChild("Animate")
    
    if not animate or not humanoid then
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Animation Error',
            Content = '❌ Animate or Humanoid not found',
            Duration = 3
        })
        return
    end
    
    local bundleId = animationData.id
    local bundledItems = animationData.bundledItems

    emotesDarkExecutorEnv().lastPlayedAnimation = animationData
    Config.LastPlayedAnimationData = animationData
    task.spawn(SaveConfig)
    
        if not bundledItems and not animationData.isCustomSet then
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Animation Error', 
            Content = '??? No bundled items found',
            Duration = 3
        })
        return
    end
    
    if animationData.isCustomSet and not bundledItems then
        bundledItems = {"Custom-Animation"}
    end
    
    stopCurrentEmote()
    
    local cacheKey = tostring(bundleId)
    local mappings = State.AnimationCache[cacheKey]
    
    if mappings and #mappings > 0 and mappings._version ~= 2 then
        mappings = nil
    end
    
        if animationData.isCustomSet then
            mappings = buildCustomSetMappings(GetCustomSetName(animationData) or animationData.name)
            if #mappings > 0 then
                mappings._version = 2
                State.AnimationCache[cacheKey] = mappings
                task.spawn(saveAnimationCache)
            end
    elseif not mappings then
        mappings = resolveAnimationMappings(bundledItems)
        if #mappings > 0 then
            mappings._version = 2
            State.AnimationCache[cacheKey] = mappings
            task.spawn(saveAnimationCache)
        end
    end
    
    if #mappings == 0 then return end
    
    local sorted = {}
    for _, m in ipairs(mappings) do
        if m.category:lower() == "idle" then
            table.insert(sorted, 1, m)
        else
            table.insert(sorted, m)
        end
    end
    
    local function applyAnimationToObject(animObj, animId, weights)
        if not animObj or not animObj:IsA("Animation") then return end

        animObj.AnimationId = animId

        if weights ~= nil then
            for _, child in ipairs(animObj:GetChildren()) do
                if child:IsA("NumberValue") and child.Name == "Weight" then
                    child:Destroy()
                end
            end
            for _, wVal in ipairs(weights) do
                local w = Instance.new("NumberValue")
                w.Name = "Weight"
                w.Value = wVal
                w.Parent = animObj
            end
        end
    end

    local mappingMap = {}
    for _, m in ipairs(sorted) do
        local cat = m.category:lower()
        if not mappingMap[cat] then
            mappingMap[cat] = { folderName = m.category, items = {} }
        end
        mappingMap[cat].items[m.name:lower()] = m
    end

    for cat, data in pairs(mappingMap) do
        local categoryFolder = animate:FindFirstChild(data.folderName)
        if not categoryFolder then
            continue
        end

        local items = data.items

        local sourceByName = {}
        for name, m in pairs(items) do
            sourceByName[name] = m
        end

        for _, animObj in ipairs(categoryFolder:GetChildren()) do
            if animObj:IsA("Animation") then
                local lowerName = animObj.Name:lower()
                local m = sourceByName[lowerName]
                if m then
                    sourceByName[lowerName] = nil
                    applyAnimationToObject(animObj, m.animationId, m.weights)
                    if animObj.Name ~= m.name then
                        animObj.Name = m.name
                    end
                else
                    animObj:Destroy()
                end
            end
        end

        for name, m in pairs(sourceByName) do
            local animObj = Instance.new("Animation")
            animObj.Name = m.name
            applyAnimationToObject(animObj, m.animationId, m.weights)
            animObj.Parent = categoryFolder
        end
    end
    
    if humanoid.MoveDirection.Magnitude == 0 then
        animate.Disabled = true
        animate.Disabled = false
    end
end

function playAnimationPreview(animationData)
    local _, humanoid = getCharacterAndHumanoid()
    if not humanoid then return false end
    local animator = humanoid:FindFirstChild("Animator")
    if not animator then return false end

    local bundledItems = animationData and animationData.bundledItems
    if not bundledItems then return false end
    
    local bundleId = animationData.id
    local cacheKey = tostring(bundleId)
    local mappings = State.AnimationCache[cacheKey]
    
    if not mappings then
        mappings = resolveAnimationMappings(bundledItems)
        if #mappings > 0 then
            State.AnimationCache[cacheKey] = mappings
            task.spawn(saveAnimationCache)
        end
    end
    
    if #mappings == 0 then return false end
    
    local m = mappings[1]
    local animation = Instance.new("Animation")
    animation.AnimationId = m.animationId
    local ok, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    if ok and track then
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        if State.speedEmoteEnabled or State.emotesWalkEnabled then
            track:Play()
        end
        State.currentEmoteTrack = track
        if State.speedEmoteEnabled then
            local speedVal = tonumber(UI.SpeedBox.Text) or Config.EmoteSpeed or 1
            track:AdjustSpeed(speedVal)
        end
        return true
    end

    return false
end

handleSectorAction = function(index)
    if tick() - State.lastActionTick < 0.25 then return end
    State.lastActionTick = tick()

    if State.customAnimationEditorActive and (not State.customAnimationEditingKey or not State.customAnimationEditingName or not (State.CustomAnimOverlay and State.CustomAnimOverlay.Parent)) then
        if State.exitCustomAnimationEditor then
            State.exitCustomAnimationEditor()
        else
            State.customAnimationEditorActive = false
        end
    end

    local randomActive = isRandomSlotActive()
    if index == 1 and randomActive then
        local itemData = pickRandomItemForMode()
        if not itemData then
            emotesDarkExecutorEnv().Notify({
                Title = 'Dark | Random',
                Content = '? No valid random item found',
                Duration = 3
            })
            return
        end
        State.lastRadialActionTime = tick()

        if State.customAnimationEditorActive then
            local animIdToSave = itemData.id
            local cat = State.customAnimationEditingKey
            local name = State.customAnimationEditingName
            if State.CustomAnimations.Sets[State.currentCustomAnimationName] and cat and name then
                if State.currentMode == "emote" or (State.currentMode == "animation" and not itemData.bundledItems) then
                    local resolved = resolveEmoteToAnimationId(itemData.id)
                    if resolved then animIdToSave = resolved end
                end
                if not State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] then
                    State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] = {}
                end
                State.CustomAnimations.Sets[State.currentCustomAnimationName][cat][name] = animIdToSave
                State.SaveCustomAnimations(State.CustomAnimations)
                emotesDarkExecutorEnv().Notify({ Title = "Dark | Saved", Content = "✅ Saved " .. name, Duration = 3 })
                if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
                if refreshCustomAnimationState then refreshCustomAnimationState(true) end
                State.exitCustomAnimationEditor()
            end
            return
        end

        if State.favoriteEnabled then
            if State.currentMode == "animation" then
                if not isInFavorites(itemData.id) then
                    toggleFavoriteAnimation(itemData)
                end
            else
                if not isInFavorites(itemData.id) then
                    toggleFavorite(itemData.id, itemData.name)
                end
            end
            return
        end

        if State.currentMode == "animation" then
            if stopCurrentEmote then stopCurrentEmote() end
            applyAnimation(itemData)
            State.lastRandomAnimationId = itemData.id
            if not State.favoriteEnabled then
                pcall(function()
                    game:GetService("GuiService"):SetEmotesMenuOpen(false)
                end)
                pcall(function()
                    game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false
                end)
            end
        else
            local _, hum = getCharacterAndHumanoid()
            if hum then
                pcall(function()
                    game:GetService("GuiService"):SetEmotesMenuOpen(false)
                end)
                pcall(function()
                    game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false
                end)
                playRandomEmote(hum, itemData.id)
                State.lastRandomEmoteId = itemData.id
            end
        end
        return
    end

    if State.currentMode == "animation" then
        rebuildAnimationNormalCache()
    else
        rebuildEmoteNormalCache()
    end

    local function getEmoteAtIndex(idx)
        local categories = getCategoryStats()
        local accumulatedPages = 0
        
        for _, cat in ipairs(categories) do
            if State.currentPage <= accumulatedPages + cat.pages then
                local adjustedPage = State.currentPage - accumulatedPages
                local pageItems = getListSlice(cat.list, adjustedPage, cat.hasRandom)
                return pageItems[idx]
            end
            accumulatedPages = accumulatedPages + cat.pages
        end
        return nil
    end

    local slotOffset = randomActive and 1 or 0
    local itemData = getEmoteAtIndex(index - slotOffset)
    if not itemData then return end

    State.lastRadialActionTime = tick()

    if State.customAnimationEditorActive then
        local animIdToSave = itemData.id
        local cat = State.customAnimationEditingKey
        local name = State.customAnimationEditingName

        if State.currentMode == "emote" or (State.currentMode == "animation" and not itemData.bundledItems) then
            local resolved = resolveEmoteToAnimationId(itemData.id)
            if resolved then animIdToSave = resolved end
        end

        if State.currentMode == "animation" and itemData.bundledItems then
            local resolved = resolveAnimationMappings(itemData.bundledItems)
            if resolved and #resolved > 0 then
                local match
                for _, m in ipairs(resolved) do
                    if m.category:lower() == cat:lower() and m.name:lower() == name:lower() then
                        match = m
                        break
                    end
                end
                if not match then
                    for _, m in ipairs(resolved) do
                        if m.category:lower() == cat:lower() then
                            match = m
                            break
                        end
                    end
                end
                if match then
                    local extractedId = tonumber(urlToId(match.animationId))
                    if extractedId then
                        animIdToSave = extractedId
                    end
                end
                
                if animIdToSave == itemData.id and resolved[1] then
                    animIdToSave = tonumber(urlToId(resolved[1].animationId)) or itemData.id
                end
            end
        end

        if State.CustomAnimations.Sets[State.currentCustomAnimationName] and cat and name then
            if not State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] then
                State.CustomAnimations.Sets[State.currentCustomAnimationName][cat] = {}
            end
            State.CustomAnimations.Sets[State.currentCustomAnimationName][cat][name] = animIdToSave
            State.SaveCustomAnimations(State.CustomAnimations)
            emotesDarkExecutorEnv().Notify({ Title = "Dark | Saved", Content = "✅ Saved " .. name, Duration = 3 })
            
            if State.RefreshCustomAnimUI then State.RefreshCustomAnimUI() end
            if refreshCustomAnimationState then refreshCustomAnimationState(true) end
            State.exitCustomAnimationEditor()
        end
        return
    end

    if State.favoriteEnabled then
        if State.currentMode == "animation" then
            toggleFavoriteAnimation(itemData)
        else
            toggleFavorite(itemData.id, itemData.name)
        end
    else
        if State.currentMode == "animation" then
            applyAnimation(itemData)
            pcall(function()
                game:GetService("GuiService"):SetEmotesMenuOpen(false)
            end)
            pcall(function()
                game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false
            end)
        else
            local _, hum = getCharacterAndHumanoid()
            if hum then
                if playRandomEmote then
                    playRandomEmote(hum, itemData.id)
                elseif playEmote then
                    playEmote(hum, itemData.id)
                end
            end
        end
    end

end

function clearAnimationSlotImages()
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    if not success or not frontFrame then
        return
    end

    for i = 1, State.itemsPerPage do
        local child = frontFrame:FindFirstChild(tostring(i))
        if child and child:IsA("ImageLabel") then
            local idValue = child:FindFirstChild("AnimationID")
            if idValue then
                idValue:Destroy()
            end
            if child.Image and child.Image:find("rbxthumb://type=BundleThumbnail") then
                child.Image = ""
            end
        end
    end
end


function monitorAnimations(token)
    while State.currentMode == "animation" and State.animationMonitorToken == token do
        local success, frontFrame = pcall(function()
            return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
        end)
        
        if success and frontFrame then
            for _, connection in pairs(State.emoteClickConnections) do
                if connection then
                    connection:Disconnect()
                end
            end
            State.emoteClickConnections = {}
            
            local favoritesToUse = _G.filteredFavoritesAnimationsForDisplay or State.favoriteAnimations
            local hasFavorites = #favoritesToUse > 0
            local favoritePagesCount = hasFavorites and calcPagesForList(#favoritesToUse, true) or 0
            local isInFavoritesPages = State.currentPage <= favoritePagesCount
            
            local currentPageAnimations = {}
            
            if isInFavoritesPages and hasFavorites then
                currentPageAnimations = getListSlice(favoritesToUse, State.currentPage, true)
            else
                local normalAnimations = {}
                for _, animation in pairs(State.filteredAnimations) do
                    if not isInFavorites(animation.id) then
                        table.insert(normalAnimations, animation)
                    end
                end
                
                local adjustedPage = State.currentPage - favoritePagesCount
                local isFirstNormalList = (favoritePagesCount == 0)
                currentPageAnimations = getListSlice(normalAnimations, adjustedPage, isFirstNormalList)
            end
            
            local randomActive = isRandomSlotActive()
            local buttonIndex = 1
            for _, child in pairs(frontFrame:GetChildren()) do
                if child:IsA("ImageLabel") and (not randomActive or child.Name ~= "1") then
                    if buttonIndex <= #currentPageAnimations then
                        local animationData = currentPageAnimations[buttonIndex]
                        
                        if State.favoriteEnabled then
                            local isFavorite = isInFavorites(animationData.id)
                            updateFavoriteIcon(child, animationData.id, isFavorite)
                        else
                            local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                            if favoriteIcon then
                                favoriteIcon:Destroy()
                            end
                        end
                        buttonIndex = buttonIndex + 1
                    else
                        local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                        if favoriteIcon then
                            favoriteIcon:Destroy()
                        end
                    end
                end
            end

        end
        
        task.wait(0.25)
    end
end

function stopEmoteClickDetection()
    State.isMonitoringClicks = false
    State.emoteMonitorToken = State.emoteMonitorToken + 1
    State.animationMonitorToken = State.animationMonitorToken + 1
    
    for _, connection in pairs(State.emoteClickConnections) do
        if connection then
            connection:Disconnect()
        end
    end
    State.emoteClickConnections = {}
    
    local success, frontFrame = pcall(function()
        return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
    end)
    
    if success and frontFrame then
        for _, child in pairs(frontFrame:GetChildren()) do
            if child:IsA("ImageLabel") then
                local clickDetector = child:FindFirstChild("ClickDetector")
                if clickDetector then
                    clickDetector:Destroy()
                end
                
                local favoriteIcon = child:FindFirstChild("FavoriteIcon")
                if favoriteIcon then
                    favoriteIcon:Destroy()
                end
            end
        end
        applyEmotesButtonsActiveState()
    end
end


function fetchAllEmotes()
    if State.isLoading then
        return
    end
    State.isLoading = true

    local function applyData(data, total)
        State.emotesData = data
        State.totalEmotesLoaded = total
        State.originalEmotesData = State.emotesData
        State.filteredEmotes = State.emotesData
        State.emoteCacheVersion = State.emoteCacheVersion + 1
        State.totalPages = calculateTotalPages()
        State.currentPage = 1
        updatePageDisplay()
        updateEmotes()
        State.isLoading = false
    end

    local function fetchFromUrl()
        local success, result = pcall(function()
            local jsonContent = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/EmoteSniper.json")
            if jsonContent and jsonContent ~= "" then
                local data = HttpService:JSONDecode(jsonContent)
                return data.data or {}
            else
                return nil
            end
        end)

        if success and result then
            local emoteData = {}
            local total = 0
            for _, item in pairs(result) do
                local id = tonumber(item.id)
                if id and id > 0 then
                    table.insert(emoteData, {id = id, name = item.name or ("Emote_" .. id)})
                    total = total + 1
                end
            end
            if #emoteData > 0 then
                pcall(function()
                    if not isfolder("dark") then makefolder("dark") end
                    writefile(State.EmoteDataCachePath, HttpService:JSONEncode(emoteData))
                end)
                return emoteData, total
            end
        end
        return nil, nil
    end

    local cacheData = nil
    pcall(function()
        if isfile and isfile(State.EmoteDataCachePath) then
            local json = readfile(State.EmoteDataCachePath)
            local decoded = HttpService:JSONDecode(json)
            if type(decoded) == "table" and #decoded > 0 then
                cacheData = decoded
            end
        end
    end)

    if cacheData then
        applyData(cacheData, #cacheData)
    else
        State.emotesData = {{id = 3360686498, name = "Stadium"},{id = 3360692915, name = "Tilt"},{id = 3576968026, name = "Shrug"},{id = 3360689775, name = "Salute"}}
        State.totalEmotesLoaded = #State.emotesData
        State.originalEmotesData = State.emotesData
        State.filteredEmotes = State.emotesData
        State.emoteCacheVersion = State.emoteCacheVersion + 1
        State.totalPages = calculateTotalPages()
        State.currentPage = 1
        updatePageDisplay()
        updateEmotes()
        State.isLoading = false
    end

    task.spawn(function()
        while true do
            local emoteData, total = fetchFromUrl()
            if emoteData then
                applyData(emoteData, total)
                emotesDarkExecutorEnv().Notify({Title = 'Dark | Emote', Content = "📦 Emotes loaded", Duration = 3})
                return
            end
            task.wait(3)
        end
    end)
end

function fetchAllAnimations()
    if State.isLoading then
        return
    end
    State.isLoading = true
    State.animationsData = {}

    local function processCustomSets()
        if State.CustomAnimations and State.CustomAnimations.Order then
            for idx, customSetName in ipairs(State.CustomAnimations.Order) do
                if customSetName ~= "Default" and State.CustomAnimations.Sets[customSetName] then
                    local fakeId = -1000 - idx
                    local customSetData = State.CustomAnimations.Sets[customSetName]
                    local mappings = {}
                    for cat, anims in pairs(customSetData) do
                        if cat ~= "__meta" then
                            for name, id in pairs(anims) do
                                if tostring(id) ~= "0" then
                                    table.insert(mappings, {category = cat, name = name, animationId = "rbxassetid://" .. id})
                                end
                            end
                        end
                    end
                    mappings._version = 2
                    State.AnimationCache[tostring(fakeId)] = mappings

                    local customAnimationData = {
                        id = fakeId,
                        name = customSetName,
                        bundledItems = {"Custom-Animation"},
                        isCustomSet = true
                    }
                    table.insert(State.animationsData, 1, customAnimationData)
                end
            end
        end
    end

    local function finalize()
        State.originalAnimationsData = State.animationsData
        State.filteredAnimations = State.animationsData
        State.animationCacheVersion = State.animationCacheVersion + 1
        State.isLoading = false
    end

    processCustomSets()
    finalize()

    task.spawn(function()
        local success, result = pcall(function()
            local jsonContent = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniper.json")
            if jsonContent and jsonContent ~= "" then
                local data = HttpService:JSONDecode(jsonContent)
                return data.data or {}
            end
            return nil
        end)

        local offsaleSuccess, offsaleResult
        if offsaleAnimationJson then
            offsaleSuccess, offsaleResult = pcall(function()
                local jsonContent = game:HttpGet("https://raw.githubusercontent.com/7yd7/sniper-Emote/refs/heads/test/AnimationSniperoffsale.json")
                if jsonContent and jsonContent ~= "" then
                    local data = HttpService:JSONDecode(jsonContent)
                    return data.data or {}
                end
                return nil
            end)
        end

        if success or offsaleSuccess then
            local animationsData = {}
            local seenIds = {}

            if success and result then
                for _, item in pairs(result) do
                    local id = tonumber(item.id)
                    if id and id > 0 then
                        seenIds[id] = true
                        table.insert(animationsData, {
                            id = id,
                            name = item.name or ("Animation_" .. id),
                            bundledItems = item.bundledItems
                        })
                    end
                end
            end

            if offsaleSuccess and offsaleResult then
                for _, item in pairs(offsaleResult) do
                    local id = tonumber(item.id)
                    if id and id > 0 and not seenIds[id] then
                        seenIds[id] = true
                        table.insert(animationsData, {
                            id = id,
                            name = item.name or ("Animation_Offsale_" .. id),
                            bundledItems = item.bundledItems
                        })
                    end
                end
            end

            local prevMode = State.currentMode
            State.animationsData = animationsData
            processCustomSets()
            finalize()
            State.totalPages = calculateTotalPages()
            if State.currentPage > State.totalPages then
                State.currentPage = State.totalPages
            end
            if prevMode == "animation" then
                if State.animationSearchTerm ~= "" and searchAnimations then
                    searchAnimations(State.animationSearchTerm)
                else
                    updatePageDisplay()
                    updateAnimations()
                end
            end
        end
    end)
end

function smartSearchMatch(name, searchTerm)
    if not searchTerm or searchTerm == "" then return true end
    name = name:lower()
    searchTerm = searchTerm:lower()
    
    for word in searchTerm:gmatch("%S+") do
        if not name:find(word, 1, true) then
            return false
        end
    end
    return true
end

function searchEmotes(searchTerm)
    if State.isLoading then
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Emote',
            Content = '⚠️ Loading please wait...',
            Duration = 5
        })
        return
    end

    searchTerm = searchTerm:lower()

    if searchTerm == "" then
        State.filteredEmotes = State.originalEmotesData
        State.emoteCacheVersion = State.emoteCacheVersion + 1
        if _G.originalFavoritesBackup then
            _G.originalFavoritesBackup = nil
        end
        _G.filteredFavoritesForDisplay = nil
    else
        local isIdSearch = searchTerm:match("^%d+$")
        
        local newFilteredList = {}
        
        if isIdSearch then
            for _, emote in pairs(State.originalEmotesData) do
                if tostring(emote.id) == searchTerm then
                    table.insert(newFilteredList, emote)
                end
            end
        else
            for _, emote in pairs(State.originalEmotesData) do
                if smartSearchMatch(emote.name, searchTerm) then
                    table.insert(newFilteredList, emote)
                end
            end
        end
        
        State.filteredEmotes = newFilteredList
        State.emoteCacheVersion = State.emoteCacheVersion + 1

        if not isIdSearch then
            if not _G.originalFavoritesBackup then
                _G.originalFavoritesBackup = {}
                for i, favorite in pairs(State.favoriteEmotes) do
                    _G.originalFavoritesBackup[i] = {
                        id = favorite.id,
                        name = favorite.name
                    }
                end
            end

            _G.filteredFavoritesForDisplay = {}
            for _, favorite in pairs(State.favoriteEmotes) do
                if smartSearchMatch(favorite.name, searchTerm) then
                    table.insert(_G.filteredFavoritesForDisplay, favorite)
                end
            end
        end
        applySearchSlot1Image()
    end

    State.totalPages = calculateTotalPages()
    State.currentPage = 1
    updatePageDisplay()
    updateEmotes()
end

function searchAnimations(searchTerm)
    if State.isLoading then
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Animation',
            Content = '⚠️ Loading please wait...',
            Duration = 5
        })
        return
    end

    searchTerm = searchTerm:lower()

    if searchTerm == "" then
        State.filteredAnimations = State.originalAnimationsData
        State.animationCacheVersion = State.animationCacheVersion + 1
        if _G.originalAnimationFavoritesBackup then
            _G.originalAnimationFavoritesBackup = nil
        end
        _G.filteredFavoritesAnimationsForDisplay = nil
    else
        local isIdSearch = searchTerm:match("^%d+$")
        
        local newFilteredList = {}
        
        if isIdSearch then
            for _, animation in pairs(State.originalAnimationsData) do
                if tostring(animation.id) == searchTerm then
                    table.insert(newFilteredList, animation)
                end
            end
        else
            for _, animation in pairs(State.originalAnimationsData) do
                if smartSearchMatch(animation.name, searchTerm) then
                    table.insert(newFilteredList, animation)
                end
            end
        end
        
        State.filteredAnimations = newFilteredList
        State.animationCacheVersion = State.animationCacheVersion + 1

        if not isIdSearch then
            if not _G.originalAnimationFavoritesBackup then
                _G.originalAnimationFavoritesBackup = {}
                for i, favorite in pairs(State.favoriteAnimations) do
                    _G.originalAnimationFavoritesBackup[i] = {
                        id = favorite.id,
                        name = favorite.name,
                        bundledItems = favorite.bundledItems
                    }
                end
            end

            _G.filteredFavoritesAnimationsForDisplay = {}
            for _, favorite in pairs(State.favoriteAnimations) do
                if smartSearchMatch(favorite.name, searchTerm) then
                    table.insert(_G.filteredFavoritesAnimationsForDisplay, favorite)
                end
            end
        end
        applySearchSlot1Image()
    end

    State.totalPages = calculateTotalPages()
    State.currentPage = 1
    updatePageDisplay()
    updateAnimations()
end

findCustomAnimationDataByName = function(setName)
    if not setName or setName == "Default" then
        return nil
    end

    for _, animationData in ipairs(State.originalAnimationsData or {}) do
        if animationData.isCustomSet and animationData.name == setName then
            return animationData
        end
    end

    for _, animationData in ipairs(State.animationsData or {}) do
        if animationData.isCustomSet and animationData.name == setName then
            return animationData
        end
    end

    return nil
end

refreshCustomAnimationState = function(applySelectedSet)
    local activeSearch = State.animationSearchTerm or ""
    local previousPage = State.currentPage

    fetchAllAnimations()

    if activeSearch ~= "" then
        searchAnimations(activeSearch)
    else
        State.filteredAnimations = State.originalAnimationsData
        State.animationCacheVersion = State.animationCacheVersion + 1
        State.totalPages = calculateTotalPages()
        local maxPage = math.max(State.totalPages, 1)
        if previousPage < 1 then
            State.currentPage = 1
        elseif previousPage > maxPage then
            State.currentPage = maxPage
        else
            State.currentPage = previousPage
        end
        updatePageDisplay()
        if State.currentMode == "animation" then
            updateAnimations()
        end
    end

    if applySelectedSet and State.currentCustomAnimationName ~= "Default" then
        local selectedAnimationData = findCustomAnimationDataByName(State.currentCustomAnimationName)
        if selectedAnimationData then
            pcall(function()
                applyAnimation(selectedAnimationData)
            end)
        end
    end
end

function goToPage(pageNumber)
    bumpImageUpdateToken()
    if pageNumber < 1 then
        State.currentPage = 1
    elseif pageNumber > State.totalPages then
        State.currentPage = State.totalPages
    else
        State.currentPage = pageNumber
    end
    updatePageDisplay()
    updateEmotes()
end

function previousPage()
    bumpImageUpdateToken()
    if State.currentPage <= 1 then
        State.currentPage = State.totalPages
    else
        State.currentPage = State.currentPage - 1
    end
    updatePageDisplay()
    updateEmotes()
end

function nextPage()
    bumpImageUpdateToken()
    if State.currentPage >= State.totalPages then
        State.currentPage = 1
    else
        State.currentPage = State.currentPage + 1
    end
    updatePageDisplay()
    updateEmotes()
end

function stopCurrentEmote()
    if State.currentEmoteTrack then
        State.currentEmoteTrack:Stop()
        State.currentEmoteTrack = nil
    end
end

playEmote = function(humanoid, emoteId)
    stopCurrentEmote()
    stopEmotes()

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. emoteId

    local success, animTrack = pcall(function()
        return humanoid.Animator:LoadAnimation(animation)
    end)

    if success and animTrack then
        State.currentEmoteTrack = animTrack
        playEmoteSound()
        State.currentEmoteTrack.Priority = Enum.AnimationPriority.Action
        State.currentEmoteTrack.Looped = true
        task.wait(0.1)
        if State.speedEmoteEnabled or State.emotesWalkEnabled then
            State.currentEmoteTrack:Play()

            if State.speedEmoteEnabled then
                local speedValue = tonumber(UI.SpeedBox.Text) or 1
                State.currentEmoteTrack:AdjustSpeed(speedValue)
            end
        end
    end
end

playRandomEmote = function(humanoid, emoteId)
    stopCurrentEmote()
    stopEmotes()

    local ok, track = pcall(function()
        return humanoid:PlayEmoteAndGetAnimTrackById(emoteId)
    end)
    if ok and track and typeof(track) == "Instance" and track:IsA("AnimationTrack") then
        State.currentEmoteTrack = track
        playEmoteSound()
        if State.speedEmoteEnabled then
            local speedVal = tonumber(UI.SpeedBox.Text) or Config.EmoteSpeed or 1
            track:AdjustSpeed(speedVal)
        end
    end
end

function onCharacterAdded(character)
    State.currentCharacter = character
    stopCurrentEmote()

    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    animator.AnimationPlayed:Connect(function(animationTrack)
        local playedEmoteId = ""
        local isEmoteTrack = false
        local ok = pcall(function()
            isEmoteTrack = isDancing(character, animationTrack)
            if isEmoteTrack and animationTrack.Animation then
                playedEmoteId = urlToId(animationTrack.Animation.AnimationId)
            end
        end)
        if not ok or not isEmoteTrack or playedEmoteId == "" or playedEmoteId == "0" then return end
        if State.toolEquipped then return end
        if not (State.emotesWalkEnabled or State.speedEmoteEnabled) then return end

        local currentTrack = State.currentEmoteTrack
        if currentTrack then
            local currentEmoteId = ""
            pcall(function()
                if currentTrack.Animation then
                    currentEmoteId = urlToId(currentTrack.Animation.AnimationId)
                end
            end)
            if currentEmoteId == playedEmoteId then return end
            stopCurrentEmote()
        end

        playEmote(humanoid, playedEmoteId)
    end)

    if emotesDarkExecutorEnv().autoReloadEnabled and emotesDarkExecutorEnv().lastPlayedAnimation then
        task.spawn(function()
            local player = game.Players.LocalPlayer
            if not player:HasAppearanceLoaded() then
                player.CharacterAppearanceLoaded:Wait()
            end
            local animate = character:WaitForChild("Animate")
            character:WaitForChild("HumanoidRootPart")
            applyAnimation(emotesDarkExecutorEnv().lastPlayedAnimation)
            emotesDarkExecutorEnv().Notify({
                Title = 'Dark | Auto Reload Animation',
                Content = '🔄 The last animation was automatically \n reapplied',
                Duration = 3
            })
            
            local lastAnim = emotesDarkExecutorEnv().lastPlayedAnimation
            local cacheKey = tostring(lastAnim.id)
            local changed = false
            for i = 1, 7 do
                task.wait(0.01)
                if not character or not character.Parent or not humanoid then break end
                local mappings = State.AnimationCache[cacheKey]
                if not mappings and lastAnim.isCustomSet then
                    mappings = buildCustomSetMappings(GetCustomSetName and GetCustomSetName(lastAnim) or lastAnim.name)
                end
                if mappings and animate and animate.Parent then
                    for _, m in ipairs(mappings) do
                        local categoryFolder = animate:FindFirstChild(m.category)
                        if categoryFolder then
                            for _, animObj in ipairs(categoryFolder:GetChildren()) do
                                if animObj:IsA("Animation") and animObj.Name:lower() == m.name:lower() then
                                    if animObj.AnimationId ~= m.animationId then
                                        animObj.AnimationId = m.animationId
                                        if m.weights ~= nil then
                                            for _, child in ipairs(animObj:GetChildren()) do
                                                if child:IsA("NumberValue") and child.Name == "Weight" then
                                                    child:Destroy()
                                                end
                                            end
                                            for _, wVal in ipairs(m.weights) do
                                                local w = Instance.new("NumberValue")
                                                w.Name = "Weight"
                                                w.Value = wVal
                                                w.Parent = animObj
                                            end
                                        end
                                        changed = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
            if changed and humanoid.MoveDirection.Magnitude == 0 then
                animate.Disabled = true
                animate.Disabled = false
            end
        end)
    end

    local function isAnyEmoteEnhanceActive()
        return State.emotesWalkEnabled or State.speedEmoteEnabled
    end

    local function handleFrozenToolEquip()
        State.toolEquipped = true
        refreshToolAnimationIds()
    end

    local function handleFrozenToolUnequip()
        State.toolEquipped = false
        refreshToolAnimationIds()
    end

    if character:FindFirstChildOfClass("Tool") then
        State.toolEquipped = true
    end
    refreshToolAnimationIds()

    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            handleFrozenToolEquip()
        end
    end)

    character.ChildRemoved:Connect(function(child)
        if child:IsA("Tool") and not character:FindFirstChildOfClass("Tool") then
            handleFrozenToolUnequip()
        end
    end)

    humanoid.Died:Connect(function()
    if State.hudEditorActive and exitHUDEditor then exitHUDEditor() end
    State.emotesWalkEnabled = false
    State.speedEmoteEnabled = false
    State.favoriteEnabled = false
    State.toolEquipped = false
    stopCurrentEmote()
    State.currentEmoteTrack = nil
    end)
end

function toggleEmoteWalk()
    State.emotesWalkEnabled = not State.emotesWalkEnabled
    ApplyFreezeButtonVisual()

    local notificationContent
    if State.emotesWalkEnabled then
        notificationContent = "Emote freeze ON"
        task.wait(0.1)
        stopCurrentEmote()
        if State.currentEmoteTrack and State.currentEmoteTrack.IsPlaying then
            State.currentEmoteTrack:AdjustSpeed(1)
        end
    else
        notificationContent = "Emote freeze OFF"
        task.wait(0.1)
        stopCurrentEmote()
        if State.currentEmoteTrack and State.currentEmoteTrack.IsPlaying and State.speedEmoteEnabled then
            State.currentEmoteTrack:AdjustSpeed(tonumber(UI.SpeedBox.Text) or 1)
        elseif State.currentEmoteTrack and State.currentEmoteTrack.IsPlaying then
            State.currentEmoteTrack:AdjustSpeed(1)
        end
    end

    local notify = emotesDarkExecutorEnv().Notify
    if type(notify) == "function" then
        task.spawn(function(callback, content)
            pcall(callback, {
                Title = "Dark | Emote Freeze",
                Content = content,
                Duration = 5
            })
        end, notify, notificationContent)
    end
end

function toggleSpeedEmote()
    State.speedEmoteEnabled = not State.speedEmoteEnabled
    updateSpeedBoxVisibility()

    local notificationContent
    if State.speedEmoteEnabled then
        notificationContent = "Speed Emote ON"
        task.wait(0.1)
        stopCurrentEmote()
    else
        notificationContent = "Speed Emote OFF"
        task.wait(0.1)
        stopCurrentEmote()
    end

    Config.EmoteSpeedEnabled = State.speedEmoteEnabled
    Config.EmoteSpeed = tonumber(UI.SpeedBox.Text) or 1
    SaveConfig()

    local notify = emotesDarkExecutorEnv().Notify
    if type(notify) == "function" then
        task.spawn(function(callback, content)
            pcall(callback, {
                Title = "Dark | Speed Emote",
                Content = content,
                Duration = 5
            })
        end, notify, notificationContent)
    end
end

function toggleFavoriteMode()
    State.favoriteEnabled = not State.favoriteEnabled

    if State.favoriteEnabled then
        ApplyFavoriteButtonVisual()
        updateScriptPriorityOverlay()
        setEmotesButtonsActiveForFavorites()

        if State.currentMode == "emote" then
            setupEmoteClickDetection()
        else 
            updateAllFavoriteIcons()
        end
    else
        ApplyFavoriteButtonVisual()

        if State.currentMode == "emote" then
            stopEmoteClickDetection()
        else
            updateAllFavoriteIcons()
        end
        clearCustomHitboxes()
        updateScriptPriorityOverlay()
    end

    pcall(function()
        local frontFrame = CoreGui.RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
        applyEmotesButtonsActiveState()
    end)
end

function toggleFavoritesTab()
    State.favoritesTabActive = not State.favoritesTabActive

    if State.favoritesTabActive then
        State.favoriteTabSavedPage = State.currentPage
        State.currentPage = 1
    else
        State.currentPage = State.favoriteTabSavedPage or 1
    end

    State.totalPages = calculateTotalPages()
    State.currentPage = math.max(1, math.min(State.currentPage, State.totalPages))
    updatePageDisplay()
    updateEmotes()
    updateScriptPriorityOverlay()

    emotesDarkExecutorEnv().Notify({
        Title = 'Dark | Favorite Tab',
        Content = State.favoritesTabActive and '⭐ Favorites tab ON' or '⭐ Favorites tab OFF',
        Duration = 3
    })
end

clickCooldown = {}
CLICK_COOLDOWN_TIME = 0.1

function safeButtonClick(buttonName, callback)
    if State.hudEditorActive then return end
    if type(getSettingsMainFrame) == "function" then
        local ok, settingsMain = pcall(getSettingsMainFrame)
        if ok and settingsMain and settingsMain.Visible then return end
    end
    local currentTime = tick()
    if not clickCooldown[buttonName] or (currentTime - clickCooldown[buttonName]) > CLICK_COOLDOWN_TIME then
        clickCooldown[buttonName] = currentTime
        callback()
    end
end

function setupAnimationClickDetection()
    if State.isMonitoringClicks then
        return
    end
    
    if State.currentMode == "animation" then
        State.animationMonitorToken = State.animationMonitorToken + 1
        local token = State.animationMonitorToken
        State.isMonitoringClicks = true
        task.spawn(function()
            monitorAnimations(token)
        end)
    end
end

function toggleAutoReload()
    emotesDarkExecutorEnv().autoReloadEnabled = not emotesDarkExecutorEnv().autoReloadEnabled
    Config.AutoReloadEnabled = emotesDarkExecutorEnv().autoReloadEnabled
    task.spawn(SaveConfig)
    
    if emotesDarkExecutorEnv().autoReloadEnabled then
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Auto Reload Animation',
            Content = "🔄 Auto Reload ON",
            Duration = 5
        })
    else
        emotesDarkExecutorEnv().Notify({
            Title = 'Dark | Auto Reload Animation',
            Content = '🔄 Auto Reload OFF',
            Duration = 3
        })
    end
end

function connectEvents()
    disconnectAllConnections()

    if UI._1left then
        table.insert(State.guiConnections, UI._1left.MouseButton1Click:Connect(function()
            safeButtonClick("PrevPage", previousPage)
        end))
    end

    if UI._9right then
        table.insert(State.guiConnections, UI._9right.MouseButton1Click:Connect(function()
            safeButtonClick("NextPage", nextPage)
        end))
    end

    if UI._2Routenumber then
        table.insert(State.guiConnections, UI._2Routenumber.FocusLost:Connect(function(enterPressed)
            if State.hudEditorActive then return end
            local pageNum = tonumber(UI._2Routenumber.Text)
            if pageNum then
                goToPage(pageNum)
            else
                UI._2Routenumber.Text = tostring(State.currentPage)
            end
        end))
    end

    if UI.Search then
        table.insert(State.guiConnections, UI.Search.Changed:Connect(function(property)
            if State.hudEditorActive then return end
            if property == "Text" then
                if State.suppressSearch then
                    return
                end
                if State.currentMode == "emote" then
                    State.emoteSearchTerm = UI.Search.Text
                    searchEmotes(State.emoteSearchTerm)
                else
                    State.animationSearchTerm = UI.Search.Text
                    searchAnimations(State.animationSearchTerm)
                end
            end
        end))
    end

    local SECTOR_COUNT = 8
    local SECTOR_ANGLE = 360 / SECTOR_COUNT
    
    local function isAuthenticPageActive()
        if not (Config.AuthenticFirstPage and State.currentMode == "emote") then
            return false
        end
        local authenticEmotes = emotesDarkExecutorEnv().OwnedAuthenticEmotes or {}
        local authenticPagesCount = calcPagesForList(#authenticEmotes, false)
        return #authenticEmotes > 0 and State.currentPage <= authenticPagesCount
    end

    table.insert(State.guiConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if State.hudEditorActive then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        
        local exists, emotesWheel = checkEmotesMenuExists()
        local isRecentlyVisible = (tick() - State.lastWheelVisibleTime < 0.15)
        if not (exists and (emotesWheel.Visible or isRecentlyVisible)) then return end

        
        local actualPos = Vector2.new(input.Position.X, input.Position.Y)

        local absPos = emotesWheel.AbsolutePosition
        local absSize = emotesWheel.AbsoluteSize

        local inXBounds = (actualPos.X >= absPos.X) and (actualPos.X <= absPos.X + absSize.X)
        local inYBounds = (actualPos.Y >= absPos.Y) and (actualPos.Y <= absPos.Y + absSize.Y)
        if not (inXBounds and inYBounds) then return end

        local center = absPos + (absSize / 2)
        local dx = actualPos.X - center.X
        local dy = actualPos.Y - center.Y

        local distance = math.sqrt(dx*dx + dy*dy)
        local radius = math.min(absSize.X, absSize.Y) * 0.5
        if distance > radius then return end
        local dynamicDeadzone = radius * 0.2
        if distance < dynamicDeadzone then return end

        local angle = math.deg(math.atan2(dy, dx))
        local correctedAngle = (angle + 90 + (SECTOR_ANGLE / 2)) % 360
        local index = math.floor(correctedAngle / SECTOR_ANGLE) + 1
        if not (State.favoriteEnabled or State.currentMode == "animation" or isAuthenticPageActive() or (index == 1 and isRandomSlotActive())) then return end

        handleSectorAction(index)
    end))

    local function bindWheelHotkeys()
        if not ContextActionService then return end

        local keyToIndex = {
            [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3, [Enum.KeyCode.Four] = 4,
            [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6, [Enum.KeyCode.Seven] = 7, [Enum.KeyCode.Eight] = 8,
            [Enum.KeyCode.KeypadOne] = 1, [Enum.KeyCode.KeypadTwo] = 2, [Enum.KeyCode.KeypadThree] = 3, [Enum.KeyCode.KeypadFour] = 4,
            [Enum.KeyCode.KeypadFive] = 5, [Enum.KeyCode.KeypadSix] = 6, [Enum.KeyCode.KeypadSeven] = 7, [Enum.KeyCode.KeypadEight] = 8
        }

        local function onHotkey(actionName, inputState, inputObject)
            if inputState ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
            if State.hudEditorActive then return Enum.ContextActionResult.Pass end
            if UserInputService:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
            if State.customAnimationEditorActive and (not State.customAnimationEditingKey or not State.customAnimationEditingName or not (State.CustomAnimOverlay and State.CustomAnimOverlay.Parent)) then
                if State.exitCustomAnimationEditor then
                    State.exitCustomAnimationEditor()
                else
                    State.customAnimationEditorActive = false
                end
            end

            local index = keyToIndex[inputObject.KeyCode]
            if not index then return Enum.ContextActionResult.Pass end
            
            if isAuthenticPageActive() then
                return Enum.ContextActionResult.Pass
            end

            if not (State.favoriteEnabled or State.currentMode == "animation" or (index == 1 and isRandomSlotActive())) then
                return Enum.ContextActionResult.Pass
            end

            local exists, emotesWheel = checkEmotesMenuExists()
            local isRecentlyVisible = (tick() - State.lastWheelVisibleTime < 0.15)
            if not (exists and (emotesWheel.Visible or isRecentlyVisible)) then return Enum.ContextActionResult.Pass end

            local success, frontFrame = pcall(function()
                return game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Front.EmotesButtons
            end)
            if success and frontFrame then
                local target = frontFrame:FindFirstChild(tostring(index))
                if target and target:IsA("ImageLabel") and target.Image ~= "" then
                    handleSectorAction(index)
                    if State.currentMode == "animation" and not State.favoriteEnabled then
                        pcall(function()
                            game:GetService("GuiService"):SetEmotesMenuOpen(false)
                        end)
                        pcall(function()
                            game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false
                        end)
                    end
                    return Enum.ContextActionResult.Sink
                end
            end

            return Enum.ContextActionResult.Pass
        end

        ContextActionService:UnbindAction("dark_EmoteWheelHotkeys")
        ContextActionService:BindActionAtPriority(
            "dark_EmoteWheelHotkeys",
            onHotkey,
            false,
            (Enum.ContextActionPriority.High.Value + 50),
            Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
            Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight,
            Enum.KeyCode.KeypadOne, Enum.KeyCode.KeypadTwo, Enum.KeyCode.KeypadThree, Enum.KeyCode.KeypadFour,
            Enum.KeyCode.KeypadFive, Enum.KeyCode.KeypadSix, Enum.KeyCode.KeypadSeven, Enum.KeyCode.KeypadEight
        )
    end

    bindWheelHotkeys()

    if UI.EmoteWalkButton then
        table.insert(State.guiConnections, UI.EmoteWalkButton.MouseButton1Click:Connect(function()
            safeButtonClick("EmoteWalk", toggleEmoteWalk)
        end))
    end

    if UI.Favorite then
        table.insert(State.guiConnections, UI.Favorite.MouseButton1Click:Connect(function()
            safeButtonClick("Favorite", toggleFavoriteMode)
        end))
    end

    if UI.FavoritesTab then
        table.insert(State.guiConnections, UI.FavoritesTab.MouseButton1Click:Connect(function()
            safeButtonClick("FavoritesTab", toggleFavoritesTab)
        end))
    end

    if UI.SpeedEmote then
        table.insert(State.guiConnections, UI.SpeedEmote.MouseButton1Click:Connect(function()
            safeButtonClick("SpeedEmote", toggleSpeedEmote)
        end))
    end

    if UI.Reload then
        table.insert(State.guiConnections, UI.Reload.MouseButton1Click:Connect(function()
            safeButtonClick("AutoReload", toggleAutoReload)
        end))
    end

    if UI.Changepage then
        table.insert(State.guiConnections, UI.Changepage.MouseButton1Click:Connect(function()
            safeButtonClick("ChangePage", function()
                stopEmoteClickDetection()
                if State.animImageSpamConn then
                    State.animImageSpamConn:Disconnect()
                    State.animImageSpamConn = nil
                    State.animImageSpamMap = nil
                    State.animImageSpamTicks = nil
                    State.animImageSpamToken = State.animImageSpamToken + 1
                end
                
                if State.currentMode == "emote" then
                    State.savedEmotePage = State.currentPage
                    State.currentMode = "animation"
                    
                    local function applyAnimationModeUI()
                        State.suppressSearch = true
                        UI.Search.Text = State.animationSearchTerm
                        State.suppressSearch = false
                        if State.animationSearchTerm ~= "" then
                            searchAnimations(State.animationSearchTerm)
                        end
                        State.currentPage = State.savedAnimPage
                        State.totalPages = calculateTotalPages()
                        updatePageDisplay()
                        updateEmotes() 
                        updateScriptPriorityOverlay()
                        State.animationMonitorToken = State.animationMonitorToken + 1
                        local token = State.animationMonitorToken
                        State.isMonitoringClicks = true
                        task.spawn(function()
                            monitorAnimations(token)
                        end)
                    end

                    applyAnimationModeUI()
                    
                    local beforeVersion = State.animationCacheVersion
                    task.spawn(function()
                        fetchAllAnimations()
                        if State.currentMode ~= "animation" then return end
                        if State.animationCacheVersion ~= beforeVersion then
                            applyAnimationModeUI()
                        end
                    end)
                    
                    emotesDarkExecutorEnv().Notify({
                        Title = 'Dark | Animation',
                        Content = '📄 Changed to Emote > Animation Mode',
                        Duration = 3
                    })

                else
                    State.savedAnimPage = State.currentPage
                    State.currentMode = "emote"
                    clearCustomHitboxes()
                    State.suppressSearch = true
                    UI.Search.Text = State.emoteSearchTerm
                    State.suppressSearch = false
                    if State.emoteSearchTerm ~= "" and searchEmotes then
                        searchEmotes(State.emoteSearchTerm)
                    end
                    State.currentPage = State.savedEmotePage
                    State.totalPages = calculateTotalPages()
                    updatePageDisplay() 
                    updateEmotes()
                    updateScriptPriorityOverlay()
                    
                    if State.favoriteEnabled then
                        setupEmoteClickDetection()
                    end
                    
                    emotesDarkExecutorEnv().Notify({
                        Title = 'Dark | Emote', 
                        Content = '📄 Changed to Animation > Emote Mode',
                        Duration = 3
                    })
                end
            end)
        end))
    end



    if UI.SpeedBox then
        table.insert(State.guiConnections, UI.SpeedBox.FocusLost:Connect(function()
            if State.hudEditorActive then return end
            local speedValue = tonumber(UI.SpeedBox.Text) or 1
            Config.EmoteSpeed = speedValue
            SaveConfig()
        end))
    end

    table.insert(State.guiConnections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if State.hudEditorActive then return end
        local exists, emotesWheel = checkEmotesMenuExists()
        if not (exists and emotesWheel.Visible) then return end

        if input.KeyCode == Enum.KeyCode.Q then
            if UserInputService:GetFocusedTextBox() then return end
            previousPage()
        elseif input.KeyCode == Enum.KeyCode.E then
            if UserInputService:GetFocusedTextBox() then return end
            nextPage()
        elseif (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
            if not UserInputService:GetFocusedTextBox() and UI.Search then
                UI.Search:CaptureFocus()
            end
        end
    end))
end






function calculateSnap(element, newPos, currentName, allMovable)
    local SNAP_THRESHOLD = 8
    local parent = element.Parent
    if not parent then return newPos, nil, nil end
    local ps = parent.AbsoluteSize
    local pp = parent.AbsolutePosition
    local absX = pp.X + newPos.X.Scale * ps.X + newPos.X.Offset
    local absY = pp.Y + newPos.Y.Scale * ps.Y + newPos.Y.Offset
    local absW = element.AbsoluteSize.X
    local absH = element.AbsoluteSize.Y
    local sX, sY = absX, absY
    local didX, didY = false, false
    local guideX, guideY
    for oName, oEl in pairs(allMovable) do
        if oName ~= currentName then
            local oX = oEl.AbsolutePosition.X
            local oY = oEl.AbsolutePosition.Y
            local oW = oEl.AbsoluteSize.X
            local oH = oEl.AbsoluteSize.Y
            if not didX then
                if math.abs(absX - oX) < SNAP_THRESHOLD then sX = oX; didX = true; guideX = oX end
                if math.abs(absX - (oX + oW)) < SNAP_THRESHOLD then sX = oX + oW; didX = true; guideX = oX + oW end
                if math.abs((absX + absW) - oX) < SNAP_THRESHOLD then sX = oX - absW; didX = true; guideX = oX end
                if math.abs((absX + absW) - (oX + oW)) < SNAP_THRESHOLD then sX = oX + oW - absW; didX = true; guideX = oX + oW end
                if math.abs((absX + absW/2) - (oX + oW/2)) < SNAP_THRESHOLD then sX = oX + oW/2 - absW/2; didX = true; guideX = oX + oW/2 end
            end
            if not didY then
                if math.abs(absY - oY) < SNAP_THRESHOLD then sY = oY; didY = true; guideY = oY end
                if math.abs(absY - (oY + oH)) < SNAP_THRESHOLD then sY = oY + oH; didY = true; guideY = oY + oH end
                if math.abs((absY + absH) - oY) < SNAP_THRESHOLD then sY = oY - absH; didY = true; guideY = oY end
                if math.abs((absY + absH) - (oY + oH)) < SNAP_THRESHOLD then sY = oY + oH - absH; didY = true; guideY = oY + oH end
                if math.abs((absY + absH/2) - (oY + oH/2)) < SNAP_THRESHOLD then sY = oY + oH/2 - absH/2; didY = true; guideY = oY + oH/2 end
            end
        end
    end
    local fsx = (sX - pp.X) / ps.X
    local fsy = (sY - pp.Y) / ps.Y
    return UDim2.new(fsx, newPos.X.Offset, fsy, newPos.Y.Offset), guideX, guideY
end

function hudColorToRGB(c)
    return {math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5)}
end

function copyProps(name)
    local src = Config.HUDProperties and Config.HUDProperties[name]
    if not src then return {} end
    local out = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            local t = {}
            for i, sv in pairs(v) do
                t[i] = sv
            end
            out[k] = t
        else
            out[k] = v
        end
    end
    return out
end

function captureHUDState(n, el)
    if not n or not el then return nil end
    local cR = el:FindFirstChildWhichIsA("UICorner")
    local s = {
        name = n,
        pos = el.Position,
        size = el.Size,
        z = el.ZIndex,
        bgTrans = el.BackgroundTransparency,
        bgColor = el.BackgroundColor3,
        radius = cR and cR.CornerRadius or nil
    }
    if el:IsA("ImageLabel") or el:IsA("ImageButton") then
        s.imgTrans = el.ImageTransparency
        s.imgColor = el.ImageColor3
    end
    if el:IsA("TextLabel") or el:IsA("TextBox") then
        s.text = el.Text
        s.textTrans = el.TextTransparency
        s.textColor = el.TextColor3
        if el:IsA("TextBox") then
            s.placeholder = el.PlaceholderText
        end
    end
    s.props = copyProps(n)
    return s
end

function pushUndo(state)
    if not state then return end
    if not HUD.UndoStack then HUD.UndoStack = {} end
    table.insert(HUD.UndoStack, state)
    if #HUD.UndoStack > 50 then
        table.remove(HUD.UndoStack, 1)
    end
end

function sameUDim2(a, b)
    return a.X.Scale == b.X.Scale and a.X.Offset == b.X.Offset and a.Y.Scale == b.Y.Scale and a.Y.Offset == b.Y.Offset
end

function sameUDim(a, b)
    return a.Scale == b.Scale and a.Offset == b.Offset
end

function sameColor(a, b)
    return math.abs(a.R - b.R) < 0.001 and math.abs(a.G - b.G) < 0.001 and math.abs(a.B - b.B) < 0.001
end

function applyHUDState(state)
    if not state or not state.name then return end
    local all = getAllHUDObjects()
    local el = all[state.name]
    if not el then return end

    if state.pos then
        el.Position = state.pos
        if not Config.HUDPositions then Config.HUDPositions = {} end
        Config.HUDPositions[state.name] = {state.pos.X.Scale, state.pos.X.Offset, state.pos.Y.Scale, state.pos.Y.Offset}
    end
    if state.size then
        el.Size = state.size
        if not Config.HUDSizes then Config.HUDSizes = {} end
        Config.HUDSizes[state.name] = {state.size.X.Scale, state.size.X.Offset, state.size.Y.Scale, state.size.Y.Offset}
    end
    if state.z ~= nil then el.ZIndex = state.z end
    if state.props and state.props.BgTrans ~= nil then el.BackgroundTransparency = state.bgTrans end
    if state.props and state.props.BgColor then el.BackgroundColor3 = state.bgColor end
    if el:IsA("ImageLabel") or el:IsA("ImageButton") then
        if state.props and state.props.ImgTrans ~= nil then el.ImageTransparency = state.imgTrans end
        if state.props and state.props.ImgColor then el.ImageColor3 = state.imgColor end
    end
    if el:IsA("TextLabel") or el:IsA("TextBox") then
        if state.props and state.props.Text ~= nil then el.Text = state.text end
        if state.props and state.props.TextTransparency ~= nil then el.TextTransparency = state.textTrans end
        if state.props and state.props.TxtColor then el.TextColor3 = state.textColor end
        if el:IsA("TextBox") and state.placeholder ~= nil then
            el.PlaceholderText = state.placeholder
        end
    end
    if state.radius then
        local cR = el:FindFirstChildWhichIsA("UICorner")
        if cR then cR.CornerRadius = state.radius end
    end

    if not Config.HUDProperties then Config.HUDProperties = {} end
    Config.HUDProperties[state.name] = state.props or {}
    SaveConfig()
    pcall(function() updateGUIColors() end)
end

function undoLastHUD()
    if not State.hudEditorActive then return end
    if not HUD.UndoStack or #HUD.UndoStack == 0 then return end
    local state = table.remove(HUD.UndoStack)
    applyHUDState(state)
end

function normalizeUDim2(u, ps)
    if not u or not ps or ps.X <= 0 or ps.Y <= 0 then
        return nil
    end
    local sx = u.X.Scale + (u.X.Offset / ps.X)
    local sy = u.Y.Scale + (u.Y.Offset / ps.Y)
    return sx, 0, sy, 0
end

function tableToUDim2(v)
    if type(v) ~= "table" or #v ~= 4 then return nil end
    return UDim2.new(v[1], v[2], v[3], v[4])
end

function normalizeHUDScale()
    local elems = getAllHUDObjects()
    for name, el in pairs(elems) do
        local parent = el and el.Parent
        if parent then
            local hasLayout = parent:FindFirstChildOfClass("UIListLayout")
            if hasLayout and not HUD.IsUnlocked then
                return
            end
            local ps = parent.AbsoluteSize
            if Config.HUDPositions and Config.HUDPositions[name] then
                local v = Config.HUDPositions[name]
                if type(v) == "table" and #v == 4 then
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local nsx, nox, nsy, noy = normalizeUDim2(UDim2.new(sx, ox, sy, oy), ps)
                        if nsx then
                            Config.HUDPositions[name] = {nsx, nox, nsy, noy}
                            el.Position = UDim2.new(nsx, nox, nsy, noy)
                        end
                    end
                end
            end
            if Config.HUDSizes and Config.HUDSizes[name] then
                local v = Config.HUDSizes[name]
                if type(v) == "table" and #v == 4 then
                    local def = HUD.DefaultSizes and HUD.DefaultSizes[name]
                    local isDefault = def and sameUDim2(def, tableToUDim2(v) or UDim2.new(0,0,0,0))
                    if isDefault then
                        return
                    end
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local nsx, nox, nsy, noy = normalizeUDim2(UDim2.new(sx, ox, sy, oy), ps)
                        if nsx then
                            Config.HUDSizes[name] = {nsx, nox, nsy, noy}
                            el.Size = UDim2.new(nsx, nox, nsy, noy)
                        end
                    end
                end
            end
        end
    end
    SaveConfig()
end

function normalizeHUDScaleForElement(name, el, normalizePos, normalizeSize)
    if not name or not el or not el.Parent then return end
    if normalizePos == nil then normalizePos = true end
    if normalizeSize == nil then normalizeSize = true end
    local parent = el.Parent
    local hasLayout = parent:FindFirstChildOfClass("UIListLayout")
    if hasLayout and not HUD.IsUnlocked then return end
    local ps = parent.AbsoluteSize
    if ps.X <= 0 or ps.Y <= 0 then return end

    if normalizePos then
        local nsx, nox, nsy, noy = normalizeUDim2(el.Position, ps)
        if nsx then
            el.Position = UDim2.new(nsx, nox, nsy, noy)
            if not Config.HUDPositions then Config.HUDPositions = {} end
            Config.HUDPositions[name] = {nsx, nox, nsy, noy}
        end
    end

    if normalizeSize then
        local nsx, nox, nsy, noy = normalizeUDim2(el.Size, ps)
        if nsx then
            el.Size = UDim2.new(nsx, nox, nsy, noy)
            if not Config.HUDSizes then Config.HUDSizes = {} end
            Config.HUDSizes[name] = {nsx, nox, nsy, noy}
        end
    end

    SaveConfig()
end

function selectHUDElement(name, element)
    if HUD.SelectedElement == element then return end
    HUD.SelectedElement = element
    HUD.LastTouchedElement = element
    HUD.LastTouchedName = name

    local parent = element.Parent
    if UI and parent and (parent == UI.Top or parent == UI.Under) then
        local key = parent.Name
        local l = parent:FindFirstChildOfClass("UIListLayout") or (HUD.Layouts and HUD.Layouts[key])
        if l then
            HUD.Layouts[key] = l
            HUD.LayoutsRemoved[key] = true
            l.Parent = nil
        end
    end

    for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
    HUD.ResizeHandles = {}
    for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
    HUD.ResizeConnections = {}

    local selectionGui = HUD.SelectionGui
    local wrapper = Instance.new("Frame")
    wrapper.Name = "SelectionWrapper"
    wrapper.BackgroundTransparency = 1
    wrapper.ZIndex = 1
    wrapper.Parent = selectionGui

    table.insert(HUD.ResizeHandles, wrapper)
    table.insert(HUD.ResizeConnections, RunService.RenderStepped:Connect(function()
        if HUD.SelectedElement == element and element.Parent then
            wrapper.Size = UDim2.fromOffset(element.AbsoluteSize.X, element.AbsoluteSize.Y)
            wrapper.Position = UDim2.fromOffset(element.AbsolutePosition.X, element.AbsolutePosition.Y)
        end
    end))

    local handlePositions = {
        TopLeft = {UDim2.new(0,0,0,0), Vector2.new(-1, -1)},
        Top = {UDim2.new(0.5,0,0,0), Vector2.new(0, -1)},
        TopRight = {UDim2.new(1,0,0,0), Vector2.new(1, -1)},
        Left = {UDim2.new(0,0,0.5,0), Vector2.new(-1, 0)},
        Right = {UDim2.new(1,0,0.5,0), Vector2.new(1, 0)},
        BottomLeft = {UDim2.new(0,0,1,0), Vector2.new(-1, 1)},
        Bottom = {UDim2.new(0.5,0,1,0), Vector2.new(0, 1)},
        BottomRight = {UDim2.new(1,0,1,0), Vector2.new(1, 1)}
    }

    for dir, data in pairs(handlePositions) do
        local h = Instance.new("Frame")
        h.Name = "Resize_"..dir
        h.Size = UDim2.new(0, 8, 0, 8)
        h.AnchorPoint = Vector2.new(0.5, 0.5)
        h.Position = data[1]
        h.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
        h.BorderColor3 = Color3.fromRGB(0, 0, 0)
        h.ZIndex = 11000
        h.Parent = wrapper

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 4, 1, 4)
        btn.Position = UDim2.new(0.5, 0, 0.5, 0)
        btn.AnchorPoint = Vector2.new(0.5, 0.5)
        btn.BackgroundTransparency = 1
        btn.Text = ""
        btn.ZIndex = 11001
        btn.Parent = h

        local resizing = false
        local dragStart
        local startAbsSize
        local startAbsPos
        local resizeUndo

        table.insert(HUD.ResizeConnections, btn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                resizing = true
                resizeUndo = captureHUDState(name, element)
                dragStart = input.Position
                startAbsSize = element.AbsoluteSize
                startAbsPos = element.AbsolutePosition
            end
        end))

        table.insert(HUD.ResizeConnections, UserInputService.InputChanged:Connect(function(input)
            if not resizing then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                local delta = input.Position - dragStart
                local pSize = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
                
                local dirVec = data[2]
                local newW = startAbsSize.X + (dirVec.X == 1 and delta.X or (dirVec.X == -1 and -delta.X or 0))
                local newH = startAbsSize.Y + (dirVec.Y == 1 and delta.Y or (dirVec.Y == -1 and -delta.Y or 0))
                local newX = startAbsPos.X + (dirVec.X == -1 and delta.X or 0)
                local newY = startAbsPos.Y + (dirVec.Y == -1 and delta.Y or 0)

                if newW < 20 then
                    if dirVec.X == -1 then newX = newX - (20 - newW) end
                    newW = 20
                end
                if newH < 20 then
                    if dirVec.Y == -1 then newY = newY - (20 - newH) end
                    newH = 20
                end

                local parentPos = element.Parent and element.Parent.AbsolutePosition or Vector2.new(0,0)
                local relX = (newX - parentPos.X) / pSize.X
                local relY = (newY - parentPos.Y) / pSize.Y

                element.Size = UDim2.new(newW / pSize.X, 0, newH / pSize.Y, 0)
                element.Position = UDim2.new(relX, 0, relY, 0)
            end
        end))

        table.insert(HUD.ResizeConnections, UserInputService.InputEnded:Connect(function(input)
             if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                 if resizing then
                     resizing = false
                     if resizeUndo and (not sameUDim2(resizeUndo.pos, element.Position) or not sameUDim2(resizeUndo.size, element.Size)) then
                         pushUndo(resizeUndo)
                     end
                     local rPs = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
                     local pXs = element.Position.X.Scale + (element.Position.X.Offset / rPs.X)
                     local pYs = element.Position.Y.Scale + (element.Position.Y.Offset / rPs.Y)
                     Config.HUDPositions[name] = {pXs, 0, pYs, 0}
                     if not Config.HUDSizes then Config.HUDSizes = {} end
                     local sXs = element.Size.X.Scale + (element.Size.X.Offset / rPs.X)
                     local sYs = element.Size.Y.Scale + (element.Size.Y.Offset / rPs.Y)
                     Config.HUDSizes[name] = {sXs, 0, sYs, 0}
                 end
             end
        end))
    end
end

function setupElementDragging(name, element, allMovable, snapGuideV, snapGuideH)
    element.Visible = true
    local stroke = Instance.new("UIStroke")
    stroke.Name = "HUDEditorStroke"
    stroke.Color = Color3.fromRGB(0, 255, 100)
    stroke.Thickness = 2
    stroke.Parent = element
    table.insert(HUD.Strokes, stroke)

    local isChild = false
    for _, friendly in pairs(HUD.FriendlyNames) do
        if name == friendly then
            isChild = true
            break
        end
    end

    local inputTarget = Instance.new("TextButton")
    inputTarget.Name = "HUDDragHandle_" .. name
    inputTarget.BackgroundTransparency = 1
    inputTarget.Text = ""
    inputTarget.ZIndex = isChild and 10 or 5
    inputTarget.Active = true
    inputTarget.Parent = HUD.SelectionGui

    table.insert(HUD.Connections, RunService.RenderStepped:Connect(function()
        if element and element.Parent then
            inputTarget.Size = UDim2.fromOffset(element.AbsoluteSize.X, element.AbsoluteSize.Y)
            inputTarget.Position = UDim2.fromOffset(element.AbsolutePosition.X, element.AbsolutePosition.Y)
        end
    end))

    local dragging = false
    local dragStart, startPos
    local dragUndo
    table.insert(HUD.Connections, inputTarget.InputBegan:Connect(function(input)
        if not State.hudEditorActive then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragUndo = captureHUDState(name, element)
            dragStart = input.Position
            startPos = element.Position
            stroke.Color = Color3.fromRGB(255, 255, 255)
            selectHUDElement(name, element)
        end
    end))

    table.insert(HUD.Connections, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            if not dragStart then return end
            local delta = input.Position - dragStart
            local ps = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
            local rawPos = UDim2.new(
                startPos.X.Scale + delta.X / ps.X, startPos.X.Offset,
                startPos.Y.Scale + delta.Y / ps.Y, startPos.Y.Offset
            )
            local snapped, gx, gy = calculateSnap(element, rawPos, name, allMovable)
            element.Position = snapped
            local ovP = HUD.Overlay and HUD.Overlay.AbsolutePosition or Vector2.new(0, 0)
            if snapGuideV then snapGuideV.Visible = (gx ~= nil); if gx then snapGuideV.Position = UDim2.fromOffset(gx - ovP.X, 0) end end
            if snapGuideH then snapGuideH.Visible = (gy ~= nil); if gy then snapGuideH.Position = UDim2.fromOffset(0, gy - ovP.Y) end end
        end
    end))

    table.insert(HUD.Connections, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                stroke.Color = Color3.fromRGB(0, 255, 100)
                if snapGuideV then snapGuideV.Visible = false end
                if snapGuideH then snapGuideH.Visible = false end
                if dragUndo and not sameUDim2(dragUndo.pos, element.Position) then
                    pushUndo(dragUndo)
                end
                    local dPs = element.Parent and element.Parent.AbsoluteSize or Vector2.new(1, 1)
                    local dpXs = element.Position.X.Scale + (element.Position.X.Offset / dPs.X)
                    local dpYs = element.Position.Y.Scale + (element.Position.Y.Offset / dPs.Y)
                    element.Position = UDim2.new(dpXs, 0, dpYs, 0)
                    Config.HUDPositions[name] = {dpXs, 0, dpYs, 0}
                end
        end
    end))
end

applySavedPositions = function()
    local elems = getAllHUDObjects()
    for name, el in pairs(elems) do
        local customPos = Config.HUDPositions and Config.HUDPositions[name]
        if customPos and type(customPos) == "table" and #customPos == 4 then
            el.Position = UDim2.new(customPos[1], customPos[2], customPos[3], customPos[4])
        elseif HUD.DefaultPositions and HUD.DefaultPositions[name] then
             el.Position = HUD.DefaultPositions[name]
        end

        local customSz = Config.HUDSizes and Config.HUDSizes[name]
        if customSz and type(customSz) == "table" and #customSz == 4 then
            el.Size = UDim2.new(customSz[1], customSz[2], customSz[3], customSz[4])
        elseif HUD.DefaultSizes and HUD.DefaultSizes[name] then
             el.Size = HUD.DefaultSizes[name]
        end

        local props = Config.HUDProperties and Config.HUDProperties[name]
        if props then
            for k, v in pairs(props) do
                pcall(function()
                    if k == "Radius" or k == "CornerRadius" then
                        local cR = el:FindFirstChildWhichIsA("UICorner")
                        if cR and type(v) == "table" then
                             cR.CornerRadius = UDim.new(tonumber(v[1]) or 0, tonumber(v[2]) or 0)
                        end
                    elseif k == "RadiusString" or k == "PlaceholderTransparency" then
                    else
                        el[k] = v
                    end
                end)
            end
        end
    end
end

exitHUDEditor = function()
    if not State.hudEditorActive then return end
    State.hudEditorActive = false
    if SettingsLib and SettingsLib.UI and SettingsLib.UI:IsA("ScreenGui") and HUD.SettingsDisplayOrderPrev ~= nil then
        pcall(function()
            SettingsLib.UI.DisplayOrder = HUD.SettingsDisplayOrderPrev
        end)
        HUD.SettingsDisplayOrderPrev = nil
    end
    for _, conn in pairs(HUD.Connections) do pcall(function() conn:Disconnect() end) end
    HUD.Connections = {}
    for _, conn in pairs(HUD.ResizeConnections) do pcall(function() conn:Disconnect() end) end
    HUD.ResizeConnections = {}
    for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
    HUD.ResizeHandles = {}
    HUD.SelectedElement = nil
    for _, stroke in pairs(HUD.Strokes) do
        pcall(function() if stroke and stroke.Parent then stroke:Destroy() end end)
    end
    HUD.Strokes = {}

    if HUD.SelectionGui then
        pcall(function() HUD.SelectionGui:Destroy() end)
        HUD.SelectionGui = nil
    end
    for _, el in pairs(getMovableElements()) do
        local h = el:FindFirstChild("HUDDragHandle")
        if h then h:Destroy() end
        if el:FindFirstChildOfClass("UIListLayout") then
            for _, child in pairs(el:GetChildren()) do
                if child:IsA("GuiButton") or child:IsA("TextBox") then
                    child.Active = true
                end
            end
        end
    end
    if HUD.Overlay then
        for _, g in pairs(HUD.Overlay:GetChildren()) do
            if g.Name == "SnapGuide" then g:Destroy() end
        end
    end
    if HUD.Overlay and HUD.Overlay.Parent then HUD.Overlay:Destroy() end
    HUD.Overlay = nil
    if HUD.ForceVisibleConn then HUD.ForceVisibleConn:Disconnect(); HUD.ForceVisibleConn = nil end
    if UI.Search then UI.Search.TextEditable = true; UI.Search.Active = true end
    if UI.SpeedBox then UI.SpeedBox.TextEditable = true; UI.SpeedBox.Active = true end
    if UI._2Routenumber then UI._2Routenumber.TextEditable = true; UI._2Routenumber.Active = true end
    pcall(function() game:GetService("GuiService"):SetEmotesMenuOpen(false) end)
    pcall(function() game:GetService("CoreGui").RobloxGui.EmotesMenu.Children.Main.EmotesWheel.Visible = false end)
end

enterHUDEditor = function()
    if State.hudEditorActive then return end
    closeOtherScriptWindows("HUDEditorOverlay")
    State.hudEditorActive = true
    HUD.UndoStack = {}

    GuiService:SetEmotesMenuOpen(false)
    task.wait(0.15)

    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then State.hudEditorActive = false; return end
    emotesWheel.Visible = true

    HUD.ForceVisibleConn = RunService.Heartbeat:Connect(function()
        if not State.hudEditorActive then return end
        pcall(function()
            local _, ew = checkEmotesMenuExists()
            if ew then ew.Visible = true end
        end)
    end)

    local main = getSettingsMainFrame()
    if main then main.Visible = false end
    syncToggleVisibility()
    if SettingsLib and SettingsLib.UI and SettingsLib.UI:IsA("ScreenGui") then
        if HUD.SettingsDisplayOrderPrev == nil then
            HUD.SettingsDisplayOrderPrev = SettingsLib.UI.DisplayOrder
        end
        pcall(function() SettingsLib.UI.DisplayOrder = 99998 end)
    end
    ApplyUIVisibility()

    local selectionGui = game:GetService("CoreGui"):FindFirstChild("dark_HUDSelection")
    if not selectionGui then
        selectionGui = Instance.new("ScreenGui")
        selectionGui.Name = "dark_HUDSelection"
        selectionGui.IgnoreGuiInset = false
        selectionGui.DisplayOrder = 99999
        selectionGui.Parent = game:GetService("CoreGui")
    else
        selectionGui.IgnoreGuiInset = false
        selectionGui.DisplayOrder = 99999
    end
    HUD.SelectionGui = selectionGui
    emotesDarkAttachAutoTranslationRoot(selectionGui)

    local overlay = Instance.new("Frame")
    overlay.Name = "HUDEditorOverlay"
    overlay.Parent = SettingsLib.UI
    overlay.BackgroundTransparency = 1
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.ZIndex = 6000
    overlay.Active = false
    HUD.Overlay = overlay
    table.insert(HUD.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if not State.hudEditorActive then return end
        if input.KeyCode == Enum.KeyCode.Z then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
                undoLastHUD()
            end
        end
    end))
    table.insert(HUD.Connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local p = input.Position
            if HUD.SelectedElement then
                local e = HUD.SelectedElement
                local pos = e.AbsolutePosition
                local sz = e.AbsoluteSize
                if p.X < pos.X - 25 or p.X > pos.X + sz.X + 25 or p.Y < pos.Y - 25 or p.Y > pos.Y + sz.Y + 25 then
                    task.delay(0.1, function()
                        if HUD.SelectedElement == e then
                            HUD.SelectedElement = nil
                            for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
                            HUD.ResizeHandles = {}
                            for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
                            HUD.ResizeConnections = {}
                        end
                    end)
                end
            end
        end
    end))

    local bc = Instance.new("Frame")
    bc.Parent = overlay
    bc.BackgroundTransparency = 1
    bc.AnchorPoint = Vector2.new(1, 0)
    bc.Position = UDim2.new(1, -10, 0, 10)
    bc.Size = UDim2.fromOffset(360, 42)
    bc.ZIndex = 6000

    local bl = Instance.new("UIListLayout")
    bl.FillDirection = Enum.FillDirection.Horizontal
    bl.Padding = UDim.new(0, 8)
    bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
    bl.VerticalAlignment = Enum.VerticalAlignment.Center
    bl.Parent = bc

    local propertiesBtn = Instance.new("ImageButton")
    propertiesBtn.Parent = bc
    propertiesBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    propertiesBtn.BackgroundTransparency = 0.4
    propertiesBtn.Size = UDim2.fromOffset(42, 42)
    propertiesBtn.Image = "rbxassetid://111026029750357"
    propertiesBtn.ZIndex = 6001
    local propCorner = Instance.new("UICorner")
    propCorner.CornerRadius = UDim.new(0, 10)
    propCorner.Parent = propertiesBtn

    local exportBtn = Instance.new("ImageButton")
    exportBtn.Parent = bc
    exportBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    exportBtn.BackgroundTransparency = 0.4
    exportBtn.Size = UDim2.fromOffset(42, 42)
    exportBtn.Image = "rbxassetid://107588515524752"
    exportBtn.ZIndex = 6001
    local exportCorner = Instance.new("UICorner")
    exportCorner.CornerRadius = UDim.new(0, 10)
    exportCorner.Parent = exportBtn

    local importBtn = Instance.new("ImageButton")
    importBtn.Parent = bc
    importBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    importBtn.BackgroundTransparency = 0.4
    importBtn.Size = UDim2.fromOffset(42, 42)
    importBtn.Image = "rbxassetid://78317476576895"
    importBtn.ZIndex = 6001
    local importCorner = Instance.new("UICorner")
    importCorner.CornerRadius = UDim.new(0, 10)
    importCorner.Parent = importBtn

    local resetBtn = Instance.new("ImageButton")
    resetBtn.Parent = bc
    resetBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    resetBtn.BackgroundTransparency = 0.4
    resetBtn.Size = UDim2.fromOffset(42, 42)
    resetBtn.Image = "rbxassetid://123088523596870"
    resetBtn.ZIndex = 6001
    local resetCorner = Instance.new("UICorner")
    resetCorner.CornerRadius = UDim.new(0, 10)
    resetCorner.Parent = resetBtn

    local lockBtn = Instance.new("ImageButton")
    lockBtn.Parent = bc
    lockBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    lockBtn.BackgroundTransparency = 0.4
    lockBtn.Size = UDim2.fromOffset(42, 42)
    lockBtn.Image = HUD.IsUnlocked and "rbxassetid://137042445663198" or "rbxassetid://137985778533954"
    lockBtn.ZIndex = 6001
    local lockCorner = Instance.new("UICorner")
    lockCorner.CornerRadius = UDim.new(0, 10)
    lockCorner.Parent = lockBtn

    local addBtn = Instance.new("ImageButton")
    addBtn.Parent = bc
    addBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    addBtn.BackgroundTransparency = 0.4
    addBtn.Size = UDim2.fromOffset(42, 42)
    addBtn.Image = "rbxassetid://108445456753346"
    addBtn.ZIndex = 6001
    local addCorner = Instance.new("UICorner")
    addCorner.CornerRadius = UDim.new(0, 10)
    addCorner.Parent = addBtn

    local backBtn = Instance.new("ImageButton")
    backBtn.Parent = bc
    backBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backBtn.BackgroundTransparency = 0.4
    backBtn.Size = UDim2.fromOffset(42, 42)
    backBtn.Image = "rbxassetid://79024388644722"
    backBtn.ZIndex = 6001
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(0, 10)
    backCorner.Parent = backBtn



    local function rebuildHUDOverlays()
        for _, conn in pairs(HUD.ResizeConnections) do pcall(function() conn:Disconnect() end) end
        HUD.ResizeConnections = {}
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, stroke in pairs(HUD.Strokes) do pcall(function() stroke:Destroy() end) end
        HUD.Strokes = {}
        if selectionGui then selectionGui:ClearAllChildren() end
        HUD.SelectedElement = nil
        
        local allMovable = getMovableElements()
        
        local snapGuideH = Instance.new("Frame")
        snapGuideH.Name = "SnapGuide"
        snapGuideH.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        snapGuideH.BorderSizePixel = 0
        snapGuideH.Size = UDim2.new(1, 0, 0, 1)
        snapGuideH.ZIndex = 6002
        snapGuideH.Visible = false
        snapGuideH.Parent = selectionGui

        local snapGuideV = Instance.new("Frame")
        snapGuideV.Name = "SnapGuide"
        snapGuideV.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
        snapGuideV.BorderSizePixel = 0
        snapGuideV.Size = UDim2.new(0, 1, 1, 0)
        snapGuideV.ZIndex = 6002
        snapGuideV.Visible = false
        snapGuideV.Parent = selectionGui

        for name, element in pairs(allMovable) do
            setupElementDragging(name, element, allMovable, snapGuideV, snapGuideH)
        end
        
        updateHUDLayouts()
        
        applySavedPositions()
    end

    local function rebuildCustomFramesFromConfig()
        if UI.CustomFrames then
            for _, frame in pairs(UI.CustomFrames) do
                if frame and frame.Parent then frame:Destroy() end
            end
        end
        UI.CustomFrames = {}

        if not Config.CustomFrames then return end
        local _, emotesWheel = checkEmotesMenuExists()
        if not emotesWheel then return end

        for name, data in pairs(Config.CustomFrames) do
            local cf = Instance.new("Frame")
            cf.Name = name
            cf.Parent = emotesWheel
            cf.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            cf.BackgroundTransparency = 0.4
            cf.ZIndex = data and data.ZIndex or 3
            cf.BorderSizePixel = 0
            cf.Active = true

            local pos = Config.HUDPositions and Config.HUDPositions[name]
            local size = Config.HUDSizes and Config.HUDSizes[name]
            if pos and type(pos) == "table" and #pos == 4 then
                cf.Position = UDim2.new(pos[1], pos[2], pos[3], pos[4])
            else
                cf.Position = UDim2.new(0.5, 0, 0.5, 0)
            end
            if size and type(size) == "table" and #size == 4 then
                cf.Size = UDim2.new(size[1], size[2], size[3], size[4])
            else
                cf.Size = UDim2.new(0.3, 0, 0.3, 0)
            end

            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = cf

            UI.CustomFrames[name] = cf
            HUD.DefaultPositions[name] = cf.Position
            HUD.DefaultSizes[name] = cf.Size
        end
    end

    local function applyHUDSettingsReplace(settings)
        local function normalizeImportTable(tbl)
            if type(tbl) ~= "table" then return {} end
            local allElems = getAllHUDObjects()
            for eName, v in pairs(tbl) do
                if type(v) == "table" and #v == 4 then
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local el = allElems[eName]
                        local ps = el and el.Parent and el.Parent.AbsoluteSize
                        if ps and ps.X > 0 and ps.Y > 0 then
                            tbl[eName] = {sx + (ox / ps.X), 0, sy + (oy / ps.Y), 0}
                        end
                    end
                end
            end
            return tbl
        end
        Config.HUDPositions = normalizeImportTable(settings.HUDPositions or {})
        Config.HUDSizes = normalizeImportTable(settings.HUDSizes or {})
        Config.HUDProperties = settings.HUDProperties or {}
        Config.CustomFrames = settings.CustomFrames or {}
        HUD.LayoutsRemoved = {}
        SaveConfig()
        rebuildCustomFramesFromConfig()
        applySavedPositions()

        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        pcall(function() updateGUIColors() end)
    end

    table.insert(HUD.Connections, lockBtn.MouseButton1Click:Connect(function()
        HUD.IsUnlocked = not HUD.IsUnlocked
        lockBtn.Image = HUD.IsUnlocked and "rbxassetid://137042445663198" or "rbxassetid://137985778533954"
        rebuildHUDOverlays()
        pcall(function() updateGUIColors() end)
        emotesDarkExecutorEnv().Notify({ 
            Title = "Dark | HUD Editor", 
            Content = HUD.IsUnlocked and "🔓 Interior Unlocked! Children are now editable." or "🔒 Interior Locked! Top-level only.", 
            Duration = 2 
        })
    end))

    rebuildHUDOverlays()

    table.insert(HUD.Connections, exportBtn.MouseButton1Click:Connect(function()
        local function normalizeExportTable(tbl)
            if type(tbl) ~= "table" then return {} end
            local out = {}
            local allElems = getAllHUDObjects()
            for eName, v in pairs(tbl) do
                if type(v) == "table" and #v == 4 then
                    local sx, ox, sy, oy = v[1], v[2], v[3], v[4]
                    if ox ~= 0 or oy ~= 0 then
                        local el = allElems[eName]
                        local ps = el and el.Parent and el.Parent.AbsoluteSize
                        if ps and ps.X > 0 and ps.Y > 0 then
                            sx = sx + (ox / ps.X)
                            sy = sy + (oy / ps.Y)
                        end
                    end
                    out[eName] = {sx, 0, sy, 0}
                else
                    out[eName] = v
                end
            end
            return out
        end
        local function normalizeExportProps(props)
            if type(props) ~= "table" then return {} end
            local out = {}
            local allElems = getAllHUDObjects()
            for eName, p in pairs(props) do
                local ep = {}
                for k, v in pairs(p) do
                    if (k == "CornerRadius" or k == "Radius") and type(v) == "table" and #v == 2 then
                        local rs, ro = v[1], v[2]
                        if ro ~= 0 and rs == 0 then
                            local el = allElems[eName]
                            if el then
                                local minDim = math.min(el.AbsoluteSize.X, el.AbsoluteSize.Y)
                                if minDim > 0 then
                                    rs = ro / minDim
                                    ro = 0
                                end
                            end
                        end
                        ep[k] = {rs, ro}
                    else
                        ep[k] = v
                    end
                end
                out[eName] = ep
            end
            return out
        end
        local data = {
            Type = "HUD",
            Settings = {
                HUDPositions = normalizeExportTable(Config.HUDPositions or {}),
                HUDSizes = normalizeExportTable(Config.HUDSizes or {}),
                HUDProperties = normalizeExportProps(Config.HUDProperties or {}),
                CustomFrames = Config.CustomFrames or {}
            }
        }
        setclipboard(HttpService:JSONEncode(data))
        emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "✅ HUD settings copied", Duration = 2 })
    end))

    table.insert(HUD.Connections, importBtn.MouseButton1Click:Connect(function()
        local popup, content = CreatePopup("Import HUD", UDim2.fromOffset(320, 240))
        local popupRoot = HUD.SelectionGui or SettingsLib.UI
        if popupRoot and popup.Parent ~= popupRoot then
            popup.Parent = popupRoot
        end

        local baseZ = 7000
        popup.ZIndex = baseZ

        local backdrop = Instance.new("TextButton")
        backdrop.Name = "HUDImportBackdrop"
        backdrop.Parent = popup.Parent
        backdrop.Size = UDim2.fromScale(1, 1)
        backdrop.BackgroundTransparency = 1
        backdrop.Text = ""
        backdrop.AutoButtonColor = false
        backdrop.ZIndex = baseZ - 1
        backdrop.Active = true

        local scroll = Instance.new("ScrollingFrame")
        scroll.Parent = content
        scroll.BackgroundTransparency = 1
        scroll.BorderSizePixel = 0
        scroll.Position = UDim2.new(0.05, 0, 0, 5)
        scroll.Size = UDim2.new(0.9, 0, 0, 130)
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        scroll.ScrollBarThickness = 4
        scroll.Active = true
        scroll.ScrollingEnabled = true
        scroll.ScrollingDirection = Enum.ScrollingDirection.Y
        scroll.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable

        local box = CreateInput(scroll, "Paste HUD JSON here...", "", true)
        box.Size = UDim2.new(1, -8, 0, 130)
        box.Position = UDim2.new(0, 0, 0, 0)
        box.TextYAlignment = Enum.TextYAlignment.Top
        box.ClearTextOnFocus = false

        local function updateCanvas()
            local padding = 8
            local h = math.max(130, (box.TextBounds.Y or 0) + padding)
            scroll.CanvasSize = UDim2.new(0, 0, 0, h)
        end
        box:GetPropertyChangedSignal("Text"):Connect(updateCanvas)
        box:GetPropertyChangedSignal("TextBounds"):Connect(updateCanvas)
        updateCanvas()

        local imp = CreateButton(content, "IMPORT HUD", (State.EmoteTheme and State.EmoteTheme.Accent) or Color3.fromRGB(0, 255, 150), UDim2.new(0.05, 0, 0.8, 0), UDim2.new(0.9, 0, 0, 35))

        imp.MouseButton1Click:Connect(function()
            local s, d = pcall(function() return HttpService:JSONDecode(box.Text) end)
            if s and type(d) == "table" then
                local settings = d.Settings or d
                if d.Type and d.Type ~= "HUD" then
                    emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "HUD import type mismatch!", Duration = 3 })
                    return
                end
                if type(settings) ~= "table" then
                    emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "Invalid HUD JSON", Duration = 3 })
                    return
                end
                applyHUDSettingsReplace(settings)
                HUD.UndoStack = {}
                if backdrop then backdrop:Destroy() end
                popup:Destroy()
                emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "✅ HUD settings imported", Duration = 2 })
            else
                emotesDarkExecutorEnv().Notify({ Title = "Error", Content = "Invalid HUD JSON", Duration = 3 })
            end
        end)

        local close = Instance.new("TextButton")
        close.Size = UDim2.fromOffset(24, 24)
        close.Position = UDim2.new(1, -30, 0, 5)
        close.Text = "×"
        close.Font = Enum.Font.GothamBold
        close.TextSize = 20
        close.BackgroundTransparency = 1
        close.TextColor3 = Color3.new(1,1,1)
        close.ZIndex = baseZ + 2
        close.Active = true
        close.AutoButtonColor = false
        close.Parent = popup
        close.MouseButton1Click:Connect(function()
            if backdrop then backdrop:Destroy() end
            popup:Destroy()
        end)
        backdrop.MouseButton1Click:Connect(function()
            if backdrop then backdrop:Destroy() end
            popup:Destroy()
        end)

        local function bumpPopupZIndex(panel, z)
            if not panel then return end
            panel.ZIndex = z
            for _, d in ipairs(panel:GetDescendants()) do
                if d:IsA("GuiObject") then
                    d.ZIndex = z + 1
                end
            end
        end
        bumpPopupZIndex(popup, baseZ)
        close.ZIndex = baseZ + 2
    end))

    table.insert(HUD.Connections, backBtn.MouseButton1Click:Connect(function()
        exitHUDEditor()
    end))

    table.insert(HUD.Connections, resetBtn.MouseButton1Click:Connect(function()
        Config.HUDPositions = {}
        Config.HUDSizes = {}
        Config.CustomFrames = {}
        Config.HUDProperties = {}
        HUD.LayoutsRemoved = {}
        SaveConfig()
        
        local allElements = getAllHUDObjects()
        for name, el in pairs(allElements) do
            if name:match("^CustomFrame_") then
                el:Destroy()
                if UI.CustomFrames then UI.CustomFrames[name] = nil end
            else
                if HUD.DefaultPositions[name] then el.Position = HUD.DefaultPositions[name] end
                if HUD.DefaultSizes[name] then el.Size = HUD.DefaultSizes[name] end
                
                for internal, friendly in pairs(HUD.FriendlyNames) do
                    if name == friendly then
                        if internal:match("^Under%.") then
                            el.Parent = UI.Under
                        elseif internal:match("^Top%.") then
                            el.Parent = UI.Top
                        end
                        break
                    end
                end

                el.ZIndex = (name == "Top" or name == "Under") and 3 or (el:IsA("ImageButton") and 4 or 3)
                if name == "Under" then
                    el.BackgroundTransparency = 1
                else
                    el.BackgroundTransparency = (name == "Top" or name == "Reload" or name == "Changepage" or name == "EmoteWalkButton" or name == "SpeedBox" or name == "SpeedEmote" or name == "Favorite") and 0.4 or 1
                end
                
                if el:IsA("ImageButton") or el:IsA("ImageLabel") then
                    el.ImageTransparency = 0
                end
                
                if el:IsA("TextLabel") or el:IsA("TextBox") then
                    el.TextTransparency = 0.4
                    if HUD.DefaultTexts and HUD.DefaultTexts[name] then
                        el.Text = HUD.DefaultTexts[name]
                    end
                    if el:IsA("TextBox") and HUD.DefaultPlaceholders and HUD.DefaultPlaceholders[name] then
                        el.PlaceholderText = HUD.DefaultPlaceholders[name]
                    end
                end

                local cR = el:FindFirstChildWhichIsA("UICorner")
                if cR then
                    cR.CornerRadius = UDim.new(0, 10)
                end
            end
        end

        pcall(function() updateGUIColors() end)
        
        HUD.SelectedElement = nil
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
        HUD.ResizeConnections = {}
        
        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        State.totalPages = calculateTotalPages()
        if State.currentPage > State.totalPages then
            State.currentPage = State.totalPages
        end
        updatePageDisplay()
        
        emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "🔄 All designs and frames have been fully reset", Duration = 3 })
    end))

    local propertiesPanel = Instance.new("Frame")
    propertiesPanel.Name = "HUDPropertiesPanel"
    propertiesPanel.Parent = overlay
    propertiesPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    propertiesPanel.BackgroundTransparency = 0.4
    propertiesPanel.Size = UDim2.fromOffset(260, 150)
    propertiesPanel.AnchorPoint = Vector2.new(1, 0)
    propertiesPanel.Position = UDim2.new(1, -10, 0, 60)
    propertiesPanel.Visible = false
    propertiesPanel.ZIndex = 6005
    propertiesPanel.ClipsDescendants = true
    local panelCorner = Instance.new("UICorner")
    panelCorner.CornerRadius = UDim.new(0, 10)
    panelCorner.Parent = propertiesPanel
    
    local title = Instance.new("TextLabel")
    title.Parent = propertiesPanel
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 0, 26)
    title.Position = UDim2.new(0, 0, 0, 2)
    title.Font = Enum.Font.SourceSansBold
    title.Text = "No Element"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 14
    title.TextScaled = true
    title.ZIndex = 6006

    local propContent = Instance.new("ScrollingFrame")
    propContent.Parent = propertiesPanel
    propContent.BackgroundTransparency = 1
    propContent.Position = UDim2.new(0, 0, 0, 28)
    propContent.Size = UDim2.new(1, 0, 1, -32)
    propContent.CanvasSize = UDim2.new(0, 0, 0, 0)
    propContent.ScrollBarThickness = 2
    propContent.Active = true
    propContent.ScrollingEnabled = true
    propContent.ZIndex = 6006

    local propLayout = Instance.new("UIListLayout")
    propLayout.Parent = propContent
    propLayout.SortOrder = Enum.SortOrder.LayoutOrder
    propLayout.Padding = UDim.new(0, 6)
    propLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    HUD.LastTouchedElement = nil
    HUD.LastTouchedName = nil

    local function createPropRow(label, lOrder, isLarge)
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(0.92, 0, 0, isLarge and 50 or 26)
        row.LayoutOrder = lOrder
        row.ZIndex = 6006
        row.Parent = propContent

        local lbl = Instance.new("TextLabel")
        lbl.Parent = row
        lbl.Size = UDim2.new(0, 70, 0, 26)
        lbl.BackgroundTransparency = 1
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Font = Enum.Font.SourceSansBold
        lbl.TextSize = 12
        lbl.ZIndex = 6007

        local tbox = Instance.new("TextBox")
        tbox.Parent = row
        tbox.Size = UDim2.new(1, -75, 1, -4)
        tbox.Position = UDim2.new(0, 75, 0, 2)
        tbox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tbox.BackgroundTransparency = 0.3
        tbox.TextColor3 = Color3.fromRGB(255, 255, 255)
        tbox.Font = Enum.Font.Code
        tbox.TextSize = 12
        tbox.TextXAlignment = isLarge and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
        tbox.TextYAlignment = isLarge and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center
        tbox.ClearTextOnFocus = false
        tbox.TextWrapped = isLarge
        tbox.PlaceholderText = ""
        tbox.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
        tbox.ZIndex = 6007
        local tc = Instance.new("UICorner"); tc.CornerRadius = UDim.new(0, 6); tc.Parent = tbox

        return row, tbox
    end

    local _, posBox = createPropRow("Position", 1)
    local _, sizeBox = createPropRow("Size", 2)
    local zRow, zBox = createPropRow("ZIndex", 3)
    local bgRow, bgBox = createPropRow("BgTrans", 4)
    local bgcRow, bgcBox = createPropRow("BgColor", 5)
    local imgRow, imgBox = createPropRow("ImgTrans", 6)
    local imgcRow, imgcBox = createPropRow("ImgColor", 7)
    local radRow, radBox = createPropRow("Radius", 8)
    local txtRow, txtBox = createPropRow("Text", 9, true)
    local phRow, phBox = createPropRow("Placeholder", 10, true)
    local ttrRow, ttrBox = createPropRow("TxtTrans", 11)
    local txtcRow, txtcBox = createPropRow("TxtColor", 12)

    local deleteRow = Instance.new("Frame")
    deleteRow.BackgroundTransparency = 1
    deleteRow.Size = UDim2.new(0.92, 0, 0, 28)
    deleteRow.LayoutOrder = 13
    deleteRow.ZIndex = 6006
    deleteRow.Parent = propContent

    local deleteBtn = Instance.new("TextButton")
    deleteBtn.Parent = deleteRow
    deleteBtn.Size = UDim2.new(1, 0, 1, 0)
    deleteBtn.BackgroundColor3 = Color3.fromRGB(170, 60, 60)
    deleteBtn.BackgroundTransparency = 0.1
    deleteBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    deleteBtn.Font = Enum.Font.GothamBold
    deleteBtn.TextSize = 12
    deleteBtn.Text = "Delete Custom Frame"
    deleteBtn.ZIndex = 6007
    local delCorner = Instance.new("UICorner"); delCorner.CornerRadius = UDim.new(0, 6); delCorner.Parent = deleteBtn



    local function parseUDim2(text)
        local s1, o1, s2, o2 = text:match("{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}%s*,%s*{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}")
        if s1 and o1 and s2 and o2 then
            return tonumber(s1), tonumber(o1), tonumber(s2), tonumber(o2)
        end
        local a, b = text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)")
        if a and b then
            local va, vb = tonumber(a), tonumber(b)
            if va and vb then
                return 0, va, 0, vb
            end
        end
        return nil
    end

    local function formatUDim2(udim)
        return string.format("{%g, %g},{%g, %g}", udim.X.Scale, udim.X.Offset, udim.Y.Scale, udim.Y.Offset)
    end

    table.insert(HUD.Connections, propertiesBtn.MouseButton1Click:Connect(function()
        propertiesPanel.Visible = not propertiesPanel.Visible
    end))

    local function formatUDim(udim)
        return string.format("{%g, %g}", udim.Scale, udim.Offset)
    end

    local function formatRGB(c)
        return string.format("%d, %d, %d", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
    end

    local function parseRGB(text)
        local a, b, c = text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)")
        if not a then return nil end
        local r, g, b2 = tonumber(a), tonumber(b), tonumber(c)
        if not r or not g or not b2 then return nil end
        local maxv = math.max(r, g, b2)
        if maxv <= 1 then
            r, g, b2 = r * 255, g * 255, b2 * 255
        end
        r = math.clamp(r, 0, 255)
        g = math.clamp(g, 0, 255)
        b2 = math.clamp(b2, 0, 255)
        return r, g, b2
    end

    table.insert(HUD.Connections, RunService.RenderStepped:Connect(function()
        if not propertiesPanel.Visible then return end
        local e = HUD.LastTouchedElement
        local eName = HUD.LastTouchedName
        if e and e.Parent then
            title.Text = string.format("[%s] %s", e.ClassName, eName or "Unknown")
            if not posBox:IsFocused() then posBox.Text = formatUDim2(e.Position) end
            if not sizeBox:IsFocused() then sizeBox.Text = formatUDim2(e.Size) end
            
            zRow.Visible = true
            if not zBox:IsFocused() then zBox.Text = tostring(e.ZIndex) end

            bgRow.Visible = true
            if not bgBox:IsFocused() then bgBox.Text = tostring(math.floor(e.BackgroundTransparency * 100) / 100) end

            if e:IsA("ImageLabel") or e:IsA("ImageButton") then
                imgRow.Visible = true
                if not imgBox:IsFocused() then imgBox.Text = tostring(math.floor(e.ImageTransparency * 100) / 100) end
            else
                imgRow.Visible = false
            end
            
            bgcRow.Visible = true
            if not bgcBox:IsFocused() then bgcBox.Text = formatRGB(e.BackgroundColor3) end
            
            if e:IsA("ImageLabel") or e:IsA("ImageButton") then
                imgcRow.Visible = true
                if not imgcBox:IsFocused() then imgcBox.Text = formatRGB(e.ImageColor3) end
            else
                imgcRow.Visible = false
            end
            
            if e:IsA("TextLabel") or e:IsA("TextBox") then
                ttrRow.Visible = true
                if not ttrBox:IsFocused() then ttrBox.Text = tostring(math.floor(e.TextTransparency * 100) / 100) end
                
                txtRow.Visible = true
                if not txtBox:IsFocused() then txtBox.Text = e.Text end

                txtcRow.Visible = true
                if not txtcBox:IsFocused() then txtcBox.Text = formatRGB(e.TextColor3) end
                
                if e:IsA("TextBox") then
                    phRow.Visible = true
                    if not phBox:IsFocused() then phBox.Text = e.PlaceholderText end
                else
                    phRow.Visible = false
                end
            else
                ttrRow.Visible = false
                txtRow.Visible = false
                phRow.Visible = false
                txtcRow.Visible = false
            end

            deleteRow.Visible = (eName and eName:match("^CustomFrame_")) and true or false


            local cR = e:FindFirstChildWhichIsA("UICorner")
            if cR then
                radRow.Visible = true
                if not radBox:IsFocused() then radBox.Text = formatUDim(cR.CornerRadius) end
            else
                radRow.Visible = false
            end
        else
            title.Text = "No Element Selected"
            zRow.Visible = false
            bgRow.Visible = false
            imgRow.Visible = false
            bgcRow.Visible = false
            imgcRow.Visible = false
            radRow.Visible = false
            ttrRow.Visible = false
            txtRow.Visible = false
            phRow.Visible = false
            txtcRow.Visible = false
            deleteRow.Visible = false
            if not posBox:IsFocused() then posBox.Text = "" end
            if not sizeBox:IsFocused() then sizeBox.Text = "" end
        end
        
        local totalH = propLayout.AbsoluteContentSize.Y + 10
        propContent.CanvasSize = UDim2.new(0, 0, 0, totalH)
        local vpY = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 800
        local maxH = math.floor(vpY * 0.55)
        propertiesPanel.Size = UDim2.fromOffset(260, math.min(maxH, totalH + 40))
    end))

    local function saveHUDProp(eName, propKey, val)
        if not Config.HUDProperties then Config.HUDProperties = {} end
        if not Config.HUDProperties[eName] then Config.HUDProperties[eName] = {} end
        Config.HUDProperties[eName][propKey] = val
        SaveConfig()
    end

    table.insert(HUD.Connections, deleteBtn.MouseButton1Click:Connect(function()
        local eName = HUD.LastTouchedName
        if not eName or not eName:match("^CustomFrame_") then return end
        local frame = UI.CustomFrames and UI.CustomFrames[eName]
        if frame and frame.Parent then frame:Destroy() end
        if UI.CustomFrames then UI.CustomFrames[eName] = nil end
        if Config.CustomFrames then Config.CustomFrames[eName] = nil end
        if Config.HUDPositions then Config.HUDPositions[eName] = nil end
        if Config.HUDSizes then Config.HUDSizes[eName] = nil end
        if Config.HUDProperties then Config.HUDProperties[eName] = nil end
        if HUD.DefaultPositions then HUD.DefaultPositions[eName] = nil end
        if HUD.DefaultSizes then HUD.DefaultSizes[eName] = nil end
        if HUD.DefaultTexts then HUD.DefaultTexts[eName] = nil end
        if HUD.DefaultPlaceholders then HUD.DefaultPlaceholders[eName] = nil end
        SaveConfig()

        HUD.SelectedElement = nil
        HUD.LastTouchedElement = nil
        HUD.LastTouchedName = nil
        for _, h in pairs(HUD.ResizeHandles) do pcall(function() h:Destroy() end) end
        HUD.ResizeHandles = {}
        for _, c in pairs(HUD.ResizeConnections) do pcall(function() c:Disconnect() end) end
        HUD.ResizeConnections = {}

        rebuildHUDOverlays()
        updateHUDLayouts()
        ApplyUIVisibility()
        pcall(function() updateGUIColors() end)
        emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "🗑️ Custom Frame deleted", Duration = 2 })
    end))



    table.insert(HUD.Connections, posBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local s1, o1, s2, o2 = parseUDim2(posBox.Text)
        if s1 then
            local prev = captureHUDState(eName, e)
            e.Position = UDim2.new(s1, o1, s2, o2)
            if prev and not sameUDim2(prev.pos, e.Position) then
                pushUndo(prev)
            end
            Config.HUDPositions[eName] = {s1, o1, s2, o2}
        end
    end))

    table.insert(HUD.Connections, sizeBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local s1, o1, s2, o2 = parseUDim2(sizeBox.Text)
        if s1 then
            local prev = captureHUDState(eName, e)
            e.Size = UDim2.new(s1, o1, s2, o2)
            if prev and not sameUDim2(prev.size, e.Size) then
                pushUndo(prev)
            end
            if not Config.HUDSizes then Config.HUDSizes = {} end
            Config.HUDSizes[eName] = {s1, o1, s2, o2}
        end
    end))

    table.insert(HUD.Connections, zBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(zBox.Text)
        if v then
            local prev = captureHUDState(eName, e)
            e.ZIndex = v
            if prev and prev.z ~= e.ZIndex then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ZIndex", v)
        end
    end))

    table.insert(HUD.Connections, bgBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(bgBox.Text)
        if v then
            local prev = captureHUDState(eName, e)
            e.BackgroundTransparency = math.clamp(v, 0, 1)
            if prev and prev.bgTrans ~= e.BackgroundTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "BgTrans", e.BackgroundTransparency)
        end
    end))

    table.insert(HUD.Connections, imgBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(imgBox.Text)
        if v and (e:IsA("ImageLabel") or e:IsA("ImageButton")) then
            local prev = captureHUDState(eName, e)
            e.ImageTransparency = math.clamp(v, 0, 1)
            if prev and prev.imgTrans ~= e.ImageTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ImgTrans", e.ImageTransparency)
        end
    end))
    
    table.insert(HUD.Connections, bgcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local r, g, b = parseRGB(bgcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].BgColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.BackgroundColor3 = c end)
            if prev and not sameColor(prev.bgColor, e.BackgroundColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "BgColor", {r, g, b})
        end
    end))
    
    table.insert(HUD.Connections, imgcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if not (e:IsA("ImageLabel") or e:IsA("ImageButton")) then return end
        local r, g, b = parseRGB(imgcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].ImgColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.ImageColor3 = c end)
            if prev and prev.imgColor and not sameColor(prev.imgColor, e.ImageColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "ImgColor", {r, g, b})
        end
    end))

    table.insert(HUD.Connections, radBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local a, b = radBox.Text:match("{%s*([%d%.%-]+)%s*,%s*([%d%.%-]+)%s*}")
        if not a and not b then a, b = radBox.Text:match("([%d%.%-]+)%s*,%s*([%d%.%-]+)") end
        if a and b then
            local va, vb = tonumber(a), tonumber(b)
            if va and vb then
                local cR = e:FindFirstChildWhichIsA("UICorner")
                if cR then
                    local prev = captureHUDState(eName, e)
                    if vb ~= 0 and va == 0 then
                        local minDim = math.min(e.AbsoluteSize.X, e.AbsoluteSize.Y)
                        if minDim > 0 then
                            va = vb / minDim
                            vb = 0
                        end
                    end
                    cR.CornerRadius = UDim.new(va, vb)
                    if prev and prev.radius and not sameUDim(prev.radius, cR.CornerRadius) then
                        pushUndo(prev)
                    end
                    saveHUDProp(eName, "CornerRadius", {va, vb})
                end
            end
        end
    end))

    table.insert(HUD.Connections, txtBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if e:IsA("TextLabel") or e:IsA("TextBox") then
            local prev = captureHUDState(eName, e)
            e.Text = txtBox.Text
            if prev and prev.text ~= e.Text then
                pushUndo(prev)
            end
            saveHUDProp(eName, "Text", txtBox.Text)
        end
    end))

    table.insert(HUD.Connections, phBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if e:IsA("TextBox") then
            local prev = captureHUDState(eName, e)
            e.PlaceholderText = phBox.Text
            if prev and prev.placeholder ~= e.PlaceholderText then
                pushUndo(prev)
            end
            saveHUDProp(eName, "PlaceholderText", phBox.Text)
        end
    end))

    table.insert(HUD.Connections, ttrBox.FocusLost:Connect(function(enter)
        if not enter then return end
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        local v = tonumber(ttrBox.Text)
        if v and (e:IsA("TextLabel") or e:IsA("TextBox")) then
            local prev = captureHUDState(eName, e)
            e.TextTransparency = math.clamp(v, 0, 1)
            if prev and prev.textTrans ~= e.TextTransparency then
                pushUndo(prev)
            end
            saveHUDProp(eName, "TextTransparency", e.TextTransparency)
        end
    end))

    table.insert(HUD.Connections, txtcBox.FocusLost:Connect(function()
        local e, eName = HUD.LastTouchedElement, HUD.LastTouchedName
        if not e or not e.Parent or not eName then return end
        if not (e:IsA("TextLabel") or e:IsA("TextBox")) then return end
        local r, g, b = parseRGB(txtcBox.Text)
        if r then
            if isThemeDefaultRGB(r, g, b) then
                if Config.HUDProperties and Config.HUDProperties[eName] then
                    Config.HUDProperties[eName].TxtColor = nil
                    if next(Config.HUDProperties[eName]) == nil then
                        Config.HUDProperties[eName] = nil
                    end
                    SaveConfig()
                end
                pcall(function() updateGUIColors() end)
                return
            end
            local prev = captureHUDState(eName, e)
            local c = Color3.fromRGB(r, g, b)
            pcall(function() e.TextColor3 = c end)
            if prev and prev.textColor and not sameColor(prev.textColor, e.TextColor3) then
                pushUndo(prev)
            end
            saveHUDProp(eName, "TxtColor", {r, g, b})
        end
    end))




    if UI.Search then UI.Search.TextEditable = false; UI.Search.Active = false; pcall(function() UI.Search:ReleaseFocus() end) end
    if UI.SpeedBox then UI.SpeedBox.TextEditable = false; UI.SpeedBox.Active = false; pcall(function() UI.SpeedBox:ReleaseFocus() end) end
    if UI._2Routenumber then UI._2Routenumber.TextEditable = false; UI._2Routenumber.Active = false; pcall(function() UI._2Routenumber:ReleaseFocus() end) end

    local allMovable = getMovableElements()
    local snapGuideH = Instance.new("Frame")
    snapGuideH.Name = "SnapGuide"
    snapGuideH.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    snapGuideH.BorderSizePixel = 0
    snapGuideH.Size = UDim2.new(1, 0, 0, 1)
    snapGuideH.ZIndex = 6002
    snapGuideH.Visible = false
    snapGuideH.Parent = overlay

    local snapGuideV = Instance.new("Frame")
    snapGuideV.Name = "SnapGuide"
    snapGuideV.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    snapGuideV.BorderSizePixel = 0
    snapGuideV.Size = UDim2.new(0, 1, 1, 0)
    snapGuideV.ZIndex = 6002
    snapGuideV.Visible = false
    snapGuideV.Parent = overlay

    for name, element in pairs(allMovable) do
        setupElementDragging(name, element, getMovableElements(), snapGuideV, snapGuideH)
    end

    table.insert(HUD.Connections, addBtn.MouseButton1Click:Connect(function()
        local nameIndex = 1
        while UI.CustomFrames and UI.CustomFrames["CustomFrame_"..nameIndex] do
            nameIndex = nameIndex + 1
        end
        local newName = "CustomFrame_"..nameIndex
        
        local _, emotesWheel = checkEmotesMenuExists()
        local cf = Instance.new("Frame")
        cf.Name = newName
        cf.Parent = emotesWheel
        cf.BackgroundTransparency = 0.4
        cf.ZIndex = 3
        cf.BorderSizePixel = 0
        cf.Active = true
        cf.Size = UDim2.new(0.3, 0, 0.3, 0)
        cf.Position = UDim2.new(0.5, 0, 0.5, 0)
        
        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = cf

        if not UI.CustomFrames then UI.CustomFrames = {} end
        UI.CustomFrames[newName] = cf

        HUD.DefaultSizes[newName] = UDim2.new(0.3, 0, 0.3, 0)
        HUD.DefaultPositions[newName] = UDim2.new(0.5, 0, 0.5, 0)

        Config.HUDPositions[newName] = {0.5, 0, 0.5, 0}
        if not Config.HUDSizes then Config.HUDSizes = {} end
        Config.HUDSizes[newName] = {0.3, 0, 0.3, 0}
        if not Config.CustomFrames then Config.CustomFrames = {} end
        Config.CustomFrames[newName] = {ZIndex = 3}

        pcall(function() updateGUIColors() end)

        setupElementDragging(newName, cf, getMovableElements(), snapGuideV, snapGuideH)
        selectHUDElement(newName, cf)
        
        emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "➕ Custom Frame added!", Duration = 2 })
    end))

    emotesDarkExecutorEnv().Notify({ Title = "Dark | HUD Editor", Content = "✏️ Drag elements to reposition", Duration = 5 })
end

State.RefreshUI = function()
    State.totalPages = calculateTotalPages()
    updatePageDisplay()
    if State.currentMode == "animation" then
        updateAnimations()
    else
        updateEmotes()
    end
end

State.RefreshSettingsUI = function()
    if TogglesUI then
        for key, toggle in pairs(TogglesUI) do
            if Config[key] ~= nil and toggle.SetState then
                toggle.SetState(Config[key])
            end
        end
    end
end

function checkAndRecreateGUI()
    if State.scriptKicked then return end
    local exists, emotesWheel = checkEmotesMenuExists()
    if not exists then
        State.isGUICreated = false
        return
    end

    if not emotesWheel:FindFirstChild("Under") or not emotesWheel:FindFirstChild("Top") or
        not emotesWheel:FindFirstChild("EmoteWalkButton") or not emotesWheel:FindFirstChild("Favorite") or
        not emotesWheel:FindFirstChild("FavoritesTab") or
        not emotesWheel:FindFirstChild("SpeedEmote") or not emotesWheel:FindFirstChild("SpeedBox") or
        not emotesWheel:FindFirstChild("Changepage") or not emotesWheel:FindFirstChild("Reload") then
        State.isGUICreated = false
        if createGUIElements() then
            updatePageDisplay()
            updateEmotes()
            loadSpeedEmoteConfig()
        end
    end
end

if player.Character then
    onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    onCharacterAdded(char)
    
    task.spawn(function()
        local attempts = 0
        while attempts < 20 do
            if checkEmotesMenuExists() then
                task.wait(0.2)
                if createGUIElements() then
                    updatePageDisplay()
                    updateEmotes()
                    updateGUIColors()
                    loadSpeedEmoteConfig()
                end
                break
            end
            attempts = attempts + 1
            task.wait(0.1)
        end
    end)
end)


lastHudVisualRefresh = 0
HUD_VISUAL_REFRESH_INTERVAL = 0.15
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    if now - lastHudVisualRefresh < HUD_VISUAL_REFRESH_INTERVAL then return end
    lastHudVisualRefresh = now

    if not State.isGUICreated then
        checkAndRecreateGUI()
    else
        updateGUIColors()
        enforceImages()
    end
end)

RunService.Stepped:Connect(function()
    if humanoid and State.currentEmoteTrack and typeof(State.currentEmoteTrack) == "Instance" and State.currentEmoteTrack:IsA("AnimationTrack") and State.currentEmoteTrack.IsPlaying then
        if humanoid.MoveDirection.Magnitude > 0 then
            if State.toolEquipped or (State.speedEmoteEnabled and not State.emotesWalkEnabled) then
                State.currentEmoteTrack:Stop()
                State.currentEmoteTrack = nil
            end
        end
    end
end)

task.spawn(function()
    loadFavoritesAnimations()
    fetchAllEmotes()
    fetchAllAnimations()
    loadSpeedEmoteConfig()
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
task.spawn(function()
    while true do
        local robloxGui = game:GetService("CoreGui"):FindFirstChild("RobloxGui")
        local emotesMenu = robloxGui and robloxGui:FindFirstChild("EmotesMenu")
        if emotesMenu then
            emotesDarkAttachAutoTranslationRoot(emotesMenu)
            local children = emotesMenu:FindFirstChild("Children")
            local main = children and children:FindFirstChild("Main")
            local wheel = main and main:FindFirstChild("EmotesWheel")
            if wheel then
                local front = wheel:FindFirstChild("Front")
                local back = wheel:FindFirstChild("Back")
                bindDarkEmoteClickSounds(front and front:FindFirstChild("EmotesButtons"))
                bindDarkEmoteClickSounds(back and back:FindFirstChild("EmotesButtons"))
            end
        end

        if not emotesMenu then
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)

        else
            local exists = emotesMenu:FindFirstChild("Children") and emotesMenu.Children:FindFirstChild("Main") and
                               emotesMenu.Children.Main:FindFirstChild("EmotesWheel")

            if exists and not State.scriptKicked then
                local emotesWheel = emotesMenu.Children.Main.EmotesWheel
                if not emotesWheel:FindFirstChild("Under") or not emotesWheel:FindFirstChild("Top") then
                    if createGUIElements then
                        createGUIElements()
                        loadSpeedEmoteConfig()
                    end
                    updateGUIColors()
                    updatePageDisplay()
                end
            end
        end

        task.wait(0.3)
    end
end)

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
    SafeLoad("https://raw.githubusercontent.com/7yd7/Hub/refs/heads/Branch/GUIS/OpenEmote.lua", "Open Emote")
    emotesDarkExecutorEnv().Notify({
        Title = 'Dark | Emote Mobile',
        Content = '📱 Added emote open button for ease of use',
        Duration = 10
    })
end

if UserInputService.KeyboardEnabled then
    emotesDarkExecutorEnv().Notify({
        Title = 'Dark | Emote PC',
        Content = '💻 Open menu press button "."',
        Duration = 10
    })
end
