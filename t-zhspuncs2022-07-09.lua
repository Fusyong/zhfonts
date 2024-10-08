Thirddata = Thirddata or {}
Thirddata.zhspuncs = Thirddata.zhspuncs or {}

local hlist = nodes.nodecodes.hlist
local glyph   = nodes.nodecodes.glyph --node.id ('glyph')
local fonthashes = fonts.hashes
local fontdata   = fonthashes.identifiers --字体身份表
local quaddata   = fonthashes.quads --空铅宽度（em）表（xheight指ex）
-- local node_count = node.count
-- local node_dimensions = node.dimensions
-- local node_traverse_id = node.traverseid
local node_traverse = node.traverse
local insert_before = node.insertbefore
local insert_after = node.insertafter
local new_kern = nodes.pool.kern
local tasks = nodes.tasks
local node_hasattribute = node.hasattribute
local node_getattribute = node.getattribute


-- 前两个：正常(理想)左、右的预期留字宽；
-- 后两个：压缩时，左、右留空对正常留空的比率
-- 比如`“`，单用时左、右留空0.5字、0.1字，在标点组中左右留空0.5*0.5字、0.1*1.0字
-- TODO：
-- 按字体信息逐一计算，使得正常标点宽度与字体设计一致；
-- 调整为c-p-c、c-p--p-c六种数据（目前缺cp--pc两种）；
-- 再左、右、中标点分组
local puncs = {
    -- 左半标点
    [0x2018] = {0.5, 0.1, 0.4, 1.0}, -- ‘
    [0x201C] = {0.5, 0.1, 0.4, 1.0}, -- “
    [0x3008] = {0.25, 0.1, 0.4, 1.0}, -- 〈
    [0x300A] = {0.5, 0.1, 0.4, 1.0}, -- 《
    [0x300C] = {0.5, 0.1, 0.4, 1.0}, -- 「
    [0x300E] = {0.5, 0.1, 0.4, 1.0}, -- 『
    [0x3010] = {0.5, 0.1, 0.4, 1.0}, -- 【
    [0x3014] = {0.5, 0.1, 0.4, 1.0}, -- 〔
    [0x3016] = {0.5, 0.1, 0.4, 1.0}, -- 〖
    [0xFF08] = {0.5, 0.1, 0.4, 1.0}, -- （
    [0xFF3B] = {0.5, 0.1, 0.4, 1.0}, -- ［
    [0xFF5B] = {0.5, 0.1, 0.4, 1.0}, -- ｛
    -- 右半标点
    [0x2019] = {0.1, 0.5, 1.0, 0.4}, -- ’
    [0x201D] = {0.1, 0.5, 1.0, 0.4}, -- ”
    [0x3009] = {0.1, 0.25, 1.0, 0.4}, -- 〉
    [0x300B] = {0.1, 0.5, 1.0, 0.4}, -- 》
    [0x300D] = {0.1, 0.5, 1.0, 0.4}, -- 」
    [0x300F] = {0.1, 0.5, 1.0, 0.4}, -- 』
    [0x3011] = {0.1, 0.5, 1.0, 0.4}, -- 】
    [0x3015] = {0.1, 0.5, 1.0, 0.4}, -- 〕
    [0x3017] = {0.1, 0.5, 1.0, 0.4}, -- 〗
    [0xFF09] = {0.1, 0.5, 1.0, 0.4}, -- ）
    [0xFF3D] = {0.1, 0.5, 1.0, 0.4}, -- ］
    [0xFF5D] = {0.1, 0.5, 1.0, 0.4}, -- ｝
    -- 独立右标点
    [0x3001] = {0.15, 0.6, 1.0, 0.3},   -- 、
    [0x3002] = {0.15, 0.6, 1.0, 0.3},   -- 。
    [0xFF0C] = {0.15, 0.6, 1.0, 0.3},   -- ，
    [0xFF0E] = {0.15, 0.6, 1.0, 0.3},   -- ．
    [0xFF1A] = {0.15, 0.6, 1.0, 0.5},   -- ：
    [0xFF1B] = {0.15, 0.6, 1.0, 0.5},   -- ；
    [0xFF01] = {0.15, 0.6, 1.0, 0.5},   -- ！
    [0xFF1F] = {0.15, 0.6, 1.0, 0.5},   -- ？
    [0xFF05] = {0.00, 0.0, 1.0, 0.5},    -- ％
    [0x2500] = {0.00, 0.0, 1.0, 1.0},    -- ─
    -- 双用左右皆可，单用仅在文右
    [0x2014] = {0.00, 0.0, 1.0, 1.0}, -- — 半字线
    [0x2026] = {0.10, 0.1, 1.0, 1.0},    -- …
}

-- 旋转过的标点/竖排标点（装在hlist中）
local puncs_r = {
    [0x3001] = {0.15, 0.7, 1.0, 0.6},   -- 、
    [0x3002] = {0.15, 0.7, 1.0, 0.6},   -- 。
    [0xFF0C] = {0.15, 0.7, 1.0, 0.6},   -- ，
    [0xFF0E] = {0.15, 0.7, 1.0, 0.6},   -- ．
    [0xFF1A] = {0.10, 0.4, 1.0, 1.0},   -- ：
    [0xFF01] = {0.10, 0.4, 1.0, 1.0},   -- ！
    [0xFF1B] = {0.10, 0.4, 1.0, 1.0},   -- ；
    [0xFF1F] = {0.10, 0.4, 1.0, 1.0},   -- ？
}

-- 是标点结点(false, glyph:1, hlist:2)
-- @glyph | hlist n 结点
-- @return false | 1 | 2
local function is_punc_glyph_or_hlist(n)
    local v = node_getattribute(n, 1) -- 竖排模块中设置的属性{1: n.char}
    if n.id == glyph and puncs[n.char] then
        return 1
    -- elseif n.id == hlist and node.getproperty(n) and puncs[node.getproperty(n).char] then
    elseif n.id == hlist and v and puncs_r[v] then
        return 2
    else
        return false
    end
end

-- 左标点在行头时的左移比例(数据暂用puncs第一个代替)
local left_puncs = {
    [0x2018] = 0.35, -- ‘
    [0x201C] = 0.35, -- “
    [0x3008] = 0.35, -- 〈
    [0x300A] = 0.35, -- 《
    [0x300C] = 0.35, -- 「
    [0x300E] = 0.35, -- 『
    [0x3010] = 0.35, -- 【
    [0x3014] = 0.35, -- 〔
    [0x3016] = 0.35, -- 〖
    [0xFF08] = 0.35, -- （
    [0xFF3B] = 0.35, -- ［
    [0xFF5B] = 0.35  -- ｛
}

-- 是左标点
local function is_left_punc(n)
    local type_flag = is_punc_glyph_or_hlist(n)
    if (type_flag == 1 and left_puncs[n.char]) or (type_flag == 2 and left_puncs[n.head.char]) then
        return true
    else
        return false
    end
end

-- 后一个字符节点（包括包含旋转标点的hlist）是标点
local function next_is_punc(n)
    local next_n = n.next
    while next_n do
        if next_n.id == glyph or next_n.id == hlist then
            if is_punc_glyph_or_hlist(next_n) then
                return true
            else
                return false
            end
        end
        next_n = next_n.next
    end
end

-- 前一个字符节点（包括包含旋转标点的hlist）是标点
local function pre_is_punc(n)
    local prev_n = n.prev
    while prev_n do
        if prev_n.id == glyph or prev_n.id == hlist then
            if is_punc_glyph_or_hlist(prev_n) then
                return true
            else
                return false
            end
        end
        prev_n = prev_n.prev
    end
end

-- 本结点与前后是不是标点：false，only，with_pre， with_next，all
local function is_zhcnpunc_node_group (n)
    local pre = pre_is_punc(n)
    local current = is_punc_glyph_or_hlist(n)
    local next = next_is_punc(n)
    if current then
        if next and pre then
            return "all"
        elseif next then
            return "with_next"
        elseif pre then
            return "with_pre"
        else
            return "only"
        end
    else
        return false
    end
end

-- r个空铅/嵌块(quad)的宽度（？？用结点宽度似乎更恰当）
local function quad_multiple (font, r)
    -- local quad = quaddata[font]
    local quad = fontdata[font].parameters.quad
    return r * quad
end

-- 处理每个标点前后的kern
local function process_punc (head, n, punc_flag)
    local is_glyph = (is_punc_glyph_or_hlist(n) == 1)
    local is_hlist = (is_punc_glyph_or_hlist(n) == 2)
    local glyph_n = nil -- 当前字模结点
    local puncs_t = nil -- 当前标点表
    
    -- 取得结点字体的描述（未缩放的原始字模信息）
    local char
    local font
    local desc
    
    local l_space_rate
    local r_space_tate
    if is_glyph then -- 一般标点
        glyph_n = n
        char = glyph_n.char
        font = glyph_n.font
        desc = fontdata[font].descriptions[char]
        if not desc then return end
        puncs_t = puncs
        l_space_rate = desc.boundingbox[1] / desc.width --左空比例
        r_space_tate = (desc.width - desc.boundingbox[3]) / desc.width --右空比例
    elseif is_hlist then --旋转的标点
        glyph_n = n.head
        char = glyph_n.char
        font = glyph_n.font
        desc = fontdata[font].descriptions[char]
        if not desc then return end
        puncs_t = puncs_r
        l_space_rate = desc.boundingbox[1] / desc.width --左空比例(与未旋转前一样)
        -- r_space_tate = (desc.vheight - desc.height - desc.depth) / desc.vheight - l_space_rate --右空比例
        r_space_tate = (desc.vheight - desc.height - desc.depth) / desc.width - l_space_rate --右空比例
    end
    
    local l_kern, r_kern = 0.0, 0.0
    local quad = quad_multiple (font, 1) --空铅/单字尺寸
    if punc_flag == "only" then
        l_kern = (puncs_t[char][1] - l_space_rate) * quad --c-pc
        r_kern = (puncs_t[char][2] - r_space_tate) * quad --cp-c
    elseif punc_flag == "with_next" then
        l_kern = (puncs_t[char][1] - l_space_rate) * quad --c-ppc
        r_kern = (puncs_t[char][2] * puncs_t[char][4] - r_space_tate) * quad --cp-pc
    elseif punc_flag == "with_pre" then
        l_kern = (puncs_t[char][1] * puncs_t[char][3] - l_space_rate) * quad -- c-ppc
        r_kern = (puncs_t[char][2] * puncs_t[char][4] - r_space_tate) * quad --cpp-c
    elseif punc_flag == "all" then
        l_kern = (puncs_t[char][1] * puncs_t[char][3] - l_space_rate) * quad -- c-ppc
        r_kern = (puncs_t[char][2] * puncs_t[char][4] - r_space_tate) * quad --cpp-c
    end

    insert_before (head, n, new_kern (l_kern))
    insert_after (head, n, new_kern (r_kern))
end

-- 迭代段落结点列表，处理标点组
local function compress_punc (head)
    for n in node_traverse(head) do
        if is_punc_glyph_or_hlist(n) then
            local n_flag = is_zhcnpunc_node_group (n)
            -- 至少本结点是标点
            if n_flag then
                process_punc (head, n, n_flag)
            end
        end
    end
end

-- 包装回调任务：分行前的过滤器
function Thirddata.zhspuncs.my_linebreak_filter (head, is_display)
    compress_punc (head)
    -- print(":::压缩标点后nodes.tosequence(head):::")
    -- print(nodes.tosequence(head))
    return head, true
end

-- 分行后处理对齐
function Thirddata.zhspuncs.align_left_puncs(head)
    local it = head
    while it do
        if it.id == hlist then
            local e = it.head
            local neg_kern = nil
            local hit = nil
            while e do
                if is_punc_glyph_or_hlist(e) then
                    if is_left_punc(e) then
                        hit = e
                    end
                    break
                end
                e = e.next
            end
            if hit ~= nil then
                -- 文本行整体向左偏移
                neg_kern = -puncs[hit.char][1] * quad_multiple(hit.font, 1) * 0.7 --ah21
                -- neg_kern = -left_puncs[hit.char] * quad_multiple(hit.font, 1) --ah21
                insert_before(head, hit, new_kern(neg_kern))
                -- 统计字符个数
                local w = 0
                local x = hit
                while x do
                    if is_punc_glyph_or_hlist(x) then w = w + 1 end
                    x = x.next
                end
                if w == 0 then w = 1 end
                -- 将 neg_kern 分摊出去
                x = it.head -- 重新遍历
                local av_neg_kern = -neg_kern/w
                local i = 0
                while x do
                    if is_punc_glyph_or_hlist(x) then
                        i = i + 1
                        -- 最后一个字符之后不插入 kern
                        if i < w then 
                            insert_after(head, x, new_kern(av_neg_kern))
                        end
                    end
                    x = x.next
                end
            end
        end
        it = it.next
    end
    -- print(":::分摊行头压缩后nodes.tosequence(head):::")
    -- print(nodes.tosequence(head))
    return head, done
end

-- 挂载任务
function Thirddata.zhspuncs.opt ()
    -- 段落分行前回调（最后调用）
    tasks.appendaction("processors","after","Thirddata.zhspuncs.my_linebreak_filter")
    -- 段落分行后回调（最后调用）
    nodes.tasks.appendaction("finalizers", "after", "Thirddata.zhspuncs.align_left_puncs")
end

-- 标点悬挂/突出
local classes = fonts.protrusions.classes
local vectors = fonts.protrusions.vectors
-- 挂载悬挂表、注册悬挂类
classes.myvector = {
vector = 'myvector',
factor = 1,
}
-- 合并两表到新表myvector，而不是修改font-ext.lua中的vectors.quality
-- 横排时不一样
vectors.myvector = table.merged (vectors.quality, {
    [0xFF0c] = { 0, 0.55 },  -- ，
    [0x3002] = { 0, 0.60 },  -- 。
    [0x2018] = { 0.60, 0 },  -- ‘
    [0x2019] = { 0, 0.60 },  -- ’
    [0x201C] = { 0.50, 0 },  -- “
    [0x201D] = { 0, 0.35 },  -- ”
    [0xFF1F] = { 0, 0.60 },  -- ？
    [0x300A] = { 0.60, 0 },  -- 《
    [0x300B] = { 0, 0.60 },  -- 》
    [0xFF08] = { 0.50, 0 },  -- （
    [0xFF09] = { 0, 0.50 },  -- ）
    [0x3001] = { 0, 0.60 },  -- 、
    [0xFF0E] = { 0, 0.50 },  -- ．
    -- [0xFF01] = { 0, 0.10 },   -- ！
    -- [0xFF1B] = { 0, 0.17 },   -- ；
})

-- 扩展原有的字体特性default(后)为default(前)
context.definefontfeature({"default"},{"default"},{mode="node",protrusion="myvector",liga="yes"})
-- 在字体定义中应用或立即应用（ 注意脚本的引用时机; 只能一种字体？？ TODO）
context.definedfont({"Serif*default"})
--[[
% 扩展原有的字体特性default(后)为default(前)
\definefontfeature[default][default][mode=node,protrusion=myvector,liga=yes]
% 或立即应用（只能一种字体？？注意脚本的引用时机）
\definedfont[Serif*default]
--]]

return Thirddata.zhspuncs


