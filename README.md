# translate.nvim

A standalone Neovim translation plugin. Select a word (or visual
selection), translate it, and surface the result via `echo`, a
scratch buffer, or inline extmarks. An optional immersive mode
re-translates only the changed nodes as you edit.

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'phanen/translate.nvim',
  cmd = { 'Translate' },
  config = function()
    require('translate').setup({ target_lang = 'zh-Hans' })
  end,
  keys = {
    { '<leader>tt', function() require('translate').region() end, mode = { 'n', 'v' } },
    { '<leader>ti', function() require('translate').immer.enable() end },
  },
}
```

## Configuration

| key           | default     | notes |
| ------------- | ----------- | ----- |
| target_lang   | `zh-Hans`   | BCP-47 target language |
| source_lang   | `auto`      | `auto` lets the backend detect |
| target        | `eol`       | `echo` / `buffer` / `eol` / `below` / `inline` / `replace` |
| http_timeout  | `30000`     | curl `--max-time` in ms |

## API

```lua
require('translate').setup({ ... })
require('translate').region()              -- cword / visual
require('translate').immer.enable()        -- immersive on current buffer
require('translate').immer.disable()
require('translate').immer.resync()
```

## Development

```sh
make test               # run the test suite (nvim-test)
make test-all           # 0.11.7 / 0.12.0 / nightly
make format-run         # stylua
make emmylua-check      # type-check
```

Tests are under `test/`. HTTP is mocked through
`require('translate.http').set_transport(fn)`; specs never hit the
network.

## License

MIT.
