local helpers = require('test.functional.helpers')(after_each)
local clear, feed, insert = helpers.clear, helpers.feed, helpers.insert
local command = helpers.command
local exec_lua = helpers.exec_lua
local eval = helpers.eval
local expect = helpers.expect
local funcs = helpers.funcs
local eq = helpers.eq

describe('meta-keys #8226 #13042', function()
  before_each(function()
    clear()
  end)

  it('ALT/META, normal-mode', function()
    -- Unmapped ALT-chord behaves as ESC+c.
    insert('hello')
    feed('0<A-x><M-x>')
    expect('llo')
    -- Unmapped ALT-chord resolves isolated (non-ALT) ESC mapping. #13086 #15869
    command('nnoremap <ESC> A<lt>ESC><Esc>')
    command('nnoremap ; A;<Esc>')
    feed('<A-;><M-;>')
    expect('llo<ESC>;<ESC>;')
    -- Mapped ALT-chord behaves as mapped.
    command('nnoremap <M-l> Ameta-l<Esc>')
    command('nnoremap <A-j> Aalt-j<Esc>')
    feed('<A-j><M-l>')
    expect('llo<ESC>;<ESC>;alt-jmeta-l')
  end)

  it('ALT/META, visual-mode', function()
    -- Unmapped ALT-chords behave as ESC+c
    insert('peaches')
    feed('viw<A-x>viw<M-x>')
    expect('peach')
    -- Unmapped ALT-chord resolves isolated (non-ALT) ESC mapping. #13086 #15869
    command('vnoremap <ESC> A<lt>ESC>')
    feed('viw<A-;><ESC>viw<M-;><ESC>')
    expect('peach<ESC>;<ESC>;')
    -- Mapped ALT-chord behaves as mapped.
    command('vnoremap <M-l> Ameta-l<Esc>')
    command('vnoremap <A-j> Aalt-j<Esc>')
    feed('viw<A-j>viw<M-l>')
    expect('peach<ESC>;<ESC>;alt-jmeta-l')
  end)

  it('ALT/META insert-mode', function()
    -- Mapped ALT-chord behaves as mapped.
    command('inoremap <M-l> meta-l')
    command('inoremap <A-j> alt-j')
    feed('i<M-l> xxx <A-j><M-h>a<A-h>')
    expect('meta-l xxx alt-j')
    eq({ 0, 1, 14, 0, }, funcs.getpos('.'))
    -- Unmapped ALT-chord behaves as ESC+c.
    command('iunmap <M-l>')
    feed('0i<M-l>')
    eq({ 0, 1, 2, 0, }, funcs.getpos('.'))
    -- Unmapped ALT-chord has same `undo` characteristics as ESC+<key>
    command('0,$d')
    feed('ahello<M-.>')
    expect('hellohello')
    feed('u')
    expect('hello')
  end)

  it('ALT/META terminal-mode', function()
    exec_lua([[
      _G.input_data = ''
      vim.api.nvim_open_term(0, { on_input = function(_, _, _, data)
        _G.input_data = _G.input_data .. vim.fn.strtrans(data)
      end })
    ]])
    -- Mapped ALT-chord behaves as mapped.
    command('tnoremap <M-l> meta-l')
    command('tnoremap <A-j> alt-j')
    feed('i<M-l> xxx <A-j>')
    eq('meta-l xxx alt-j', exec_lua([[return _G.input_data]]))
    -- Unmapped ALT-chord is sent to terminal as-is. #16220
    exec_lua([[_G.input_data = '']])
    command('tunmap <M-l>')
    feed('<M-l>')
    local meta_l_seq = exec_lua([[return _G.input_data]])
    command('tnoremap <Esc> <C-\\><C-N>')
    feed('yyy<M-l><A-j>')
    eq(meta_l_seq .. 'yyy' .. meta_l_seq .. 'alt-j', exec_lua([[return _G.input_data]]))
    eq('t', eval('mode(1)'))
    feed('<Esc>j')
    eq({ 0, 2, 1, 0, }, funcs.getpos('.'))
    eq('nt', eval('mode(1)'))
  end)
end)
