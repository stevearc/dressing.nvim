# Changelog

## [2.0.1](https://github.com/stevearc/dressing.nvim/compare/v2.0.0...v2.0.1) (2023-08-13)


### Bug Fixes

* restore float title padding for nvim 0.9 ([#109](https://github.com/stevearc/dressing.nvim/issues/109)) ([169877d](https://github.com/stevearc/dressing.nvim/commit/169877dbcae54b23b464b219e053e92854bbb37f))

## [2.0.0](https://github.com/stevearc/dressing.nvim/compare/v1.0.0...v2.0.0) (2023-08-08)


### ⚠ BREAKING CHANGES

* deprecate the "anchor" config option ([#106](https://github.com/stevearc/dressing.nvim/issues/106))

### Features

* built-in select implementation binds number keymaps ([#104](https://github.com/stevearc/dressing.nvim/issues/104)) ([cc69bfe](https://github.com/stevearc/dressing.nvim/commit/cc69bfed36863a2ffdf1b9c4fd2ed59445a51629))


### Bug Fixes

* inconsistent mode after selecting with fzf-lua ([3961185](https://github.com/stevearc/dressing.nvim/commit/39611852fd7bbac117e939a26759bb37361f0c90))
* increase buffer time for fzf-lua mode switching ([713b56e](https://github.com/stevearc/dressing.nvim/commit/713b56e13c58ad519920e0e634763345cb4fc832))


### Code Refactoring

* deprecate the "anchor" config option ([#106](https://github.com/stevearc/dressing.nvim/issues/106)) ([bcaf0d3](https://github.com/stevearc/dressing.nvim/commit/bcaf0d3d6e5cc6e8ecb8df3a7df7d98c567d36e6))

## 1.0.0 (2023-06-26)


### ⚠ BREAKING CHANGES

* drop support for Neovim 0.7
* expose generic way to set window/buffer options in config ([#75](https://github.com/stevearc/dressing.nvim/issues/75))
* update vim.ui.input to match nvim 0.9 API
* This drops support for Neovim versions earlier than 0.7. For earlier versions of Neovim, use the nvim-0.5 branch.
* drop specialized text highlight groups ([#30](https://github.com/stevearc/dressing.nvim/issues/30))
* deprecate telescope 'theme' option
* more layout options for input and builtin select ([#19](https://github.com/stevearc/dressing.nvim/issues/19))
* Remove prompt buffer implementation for ui.input

### Features

* add an unpatch() function ([6487acd](https://github.com/stevearc/dressing.nvim/commit/6487acdf93702c0abddfeb715d414e1ba83ecbb9))
* add config options for setting winhighlight ([#8](https://github.com/stevearc/dressing.nvim/issues/8)) ([c856074](https://github.com/stevearc/dressing.nvim/commit/c8560747712d95c093956abfd74fb8ca804886ff))
* add DressingInputText highlight group ([#8](https://github.com/stevearc/dressing.nvim/issues/8)) ([2856055](https://github.com/stevearc/dressing.nvim/commit/28560556f1b89845dc321e93a8b577b8c406487a))
* add DressingSelectText highlight group ([#8](https://github.com/stevearc/dressing.nvim/issues/8)) ([f854223](https://github.com/stevearc/dressing.nvim/commit/f8542237f3bb581a0e3a351c30c8d7d428286080))
* add FloatTitle highlight group ([#8](https://github.com/stevearc/dressing.nvim/issues/8)) ([264874e](https://github.com/stevearc/dressing.nvim/commit/264874eb7bed86a1b22bf3eb738fc864a005c7c2))
* add support for more telescope themes ([edbae09](https://github.com/stevearc/dressing.nvim/commit/edbae09ec4024c7bd1d802d23ca20f6ff76b31b3))
* allow get_config to modify enabled ([#29](https://github.com/stevearc/dressing.nvim/issues/29)) ([31f12ff](https://github.com/stevearc/dressing.nvim/commit/31f12fff6e71a14ddce30bfc7ec9b29a2137ccde))
* allow to pass extra opts to vim.keymap.set() ([2257c3e](https://github.com/stevearc/dressing.nvim/commit/2257c3e36765e3a2fd154f8c8e8b1af9514c7c7a))
* bind &lt;Esc&gt; to cancel dialog in input (fix [#1](https://github.com/stevearc/dressing.nvim/issues/1)) ([27d1ea0](https://github.com/stevearc/dressing.nvim/commit/27d1ea0a15614a19d17e2016f477188bb4778248))
* built-in select has winblend option ([f57f0f3](https://github.com/stevearc/dressing.nvim/commit/f57f0f35876b9cd6df77dbbec553629c947c4db9))
* config option to disable specific ui modules ([ed37836](https://github.com/stevearc/dressing.nvim/commit/ed378363a03414957e61b0012efd214960005d96))
* customize the code action UI for telescope ([#6](https://github.com/stevearc/dressing.nvim/issues/6)) ([e3b31d4](https://github.com/stevearc/dressing.nvim/commit/e3b31d45bc65d1b1c48615110373e7e375104d6f))
* enable cmp omni autocomplete in vim.ui.input ([#55](https://github.com/stevearc/dressing.nvim/issues/55)) ([4436d6f](https://github.com/stevearc/dressing.nvim/commit/4436d6f41e2f6b8ada57588acd1a9f8b3d21453c))
* enable telescope customization for vim.ui.select caller ([e607dd9](https://github.com/stevearc/dressing.nvim/commit/e607dd99aeb5ce21e9a3d8f4c028650db12bd3af))
* error message when passing associative table to select ([18a3548](https://github.com/stevearc/dressing.nvim/commit/18a35482055a7d18f5150e1e33e8c0d29af124ac))
* expose mappings to user via config ([b1c0814](https://github.com/stevearc/dressing.nvim/commit/b1c08146eeb9690d9e31c6b8e22afadf31dd496c))
* history for ui.input ([#12](https://github.com/stevearc/dressing.nvim/issues/12)) ([d5918d0](https://github.com/stevearc/dressing.nvim/commit/d5918d0475e2d8c4ad1812c807fbe0561592f0c0))
* **input:** add start_in_insert option ([28cb494](https://github.com/stevearc/dressing.nvim/commit/28cb494b613ebcb2feb1478ad2fbbe83822e2e6d))
* **input:** add winblend as a config option ([dbfca4d](https://github.com/stevearc/dressing.nvim/commit/dbfca4da6a1b57f7744bd8590444d7f978efc6e7))
* **input:** option prompt_align ([#27](https://github.com/stevearc/dressing.nvim/issues/27)) ([079e5d7](https://github.com/stevearc/dressing.nvim/commit/079e5d7df8030aa33661c8eada12d1e1105a1b83))
* **input:** option to allow normal mode ([#3](https://github.com/stevearc/dressing.nvim/issues/3)) ([08c0cf3](https://github.com/stevearc/dressing.nvim/commit/08c0cf3217d0c426bb4eb16190ad251dc31b008d))
* **input:** support cancelreturn ([fb46379](https://github.com/stevearc/dressing.nvim/commit/fb4637995e76d298ad0607dfe78f65214676ced6))
* **input:** support the completion option ([5caa867](https://github.com/stevearc/dressing.nvim/commit/5caa867d3dd559b0613ec286cec56ee9a72fb83a))
* more layout options for input and builtin select ([#19](https://github.com/stevearc/dressing.nvim/issues/19)) ([1e529b8](https://github.com/stevearc/dressing.nvim/commit/1e529b8cdb90f2c79122b76e6fbbbdc0bd3cffab))
* more lazy loading for faster startup ([f38eb33](https://github.com/stevearc/dressing.nvim/commit/f38eb335729162905687becdd4e200a294772ff5))
* pass items to get_config for vim.ui.select ([d886a1b](https://github.com/stevearc/dressing.nvim/commit/d886a1bb0b43a81af58e0331fedbe8b02ac414fa))
* provide better default window options for vim.ui.input ([#94](https://github.com/stevearc/dressing.nvim/issues/94)) ([324f8f1](https://github.com/stevearc/dressing.nvim/commit/324f8f16e0743fe09735d77d4aeb538d28ee30cc))
* **select:** add support for fzf-lua ([#14](https://github.com/stevearc/dressing.nvim/issues/14)) ([c2208c3](https://github.com/stevearc/dressing.nvim/commit/c2208c3e5c5537fd63de3f004938cd4bb74daa99))
* **select:** allow user to override format_item ([#6](https://github.com/stevearc/dressing.nvim/issues/6)) ([4848f85](https://github.com/stevearc/dressing.nvim/commit/4848f851f67eb3c9976571f74208f28dbee7994b))
* **select:** override telescope config ([43f325b](https://github.com/stevearc/dressing.nvim/commit/43f325b65434147662981c312ba1d0c32bbb5cad))
* set unique filetype on built-in modals ([#3](https://github.com/stevearc/dressing.nvim/issues/3)) ([a3255df](https://github.com/stevearc/dressing.nvim/commit/a3255df4a53995bb74dd9da957c6de19c3c69a02))
* trim trailing colon from prompt ([59cd93b](https://github.com/stevearc/dressing.nvim/commit/59cd93b99459e812b10e416a700d0b78c99a6566))


### Bug Fixes

* apply filetype option after setting keymaps ([#25](https://github.com/stevearc/dressing.nvim/issues/25)) ([01afd7b](https://github.com/stevearc/dressing.nvim/commit/01afd7b01fa76b3cf0a8375d8bf916d0bd498db5))
* bad default value handling in vim.ui.input ([5f44f82](https://github.com/stevearc/dressing.nvim/commit/5f44f829481640be0f96759c965ae22a3bcaf7ce))
* bad nui parameter in last commit ([#45](https://github.com/stevearc/dressing.nvim/issues/45)) ([d394a25](https://github.com/stevearc/dressing.nvim/commit/d394a2591c5453c699fc799b164fa578e327f07a))
* change default cursor-relative row/col to 0/0 ([be2ef16](https://github.com/stevearc/dressing.nvim/commit/be2ef16ddb86be798f76b476c94467b1575b7026))
* close input window when entering cmdline window ([#99](https://github.com/stevearc/dressing.nvim/issues/99)) ([f16d758](https://github.com/stevearc/dressing.nvim/commit/f16d7586fcdd8b2e3850d0abb7e46f944125cc25))
* drop specialized text highlight groups ([#30](https://github.com/stevearc/dressing.nvim/issues/30)) ([e14e35a](https://github.com/stevearc/dressing.nvim/commit/e14e35a9d46575882f7d2df5b7a051563d1b7b16))
* ensure telescope win is closed before calling callback ([f19cbd5](https://github.com/stevearc/dressing.nvim/commit/f19cbd56f7f8cad212c58a7285d09c5d9c273896))
* format_item doesn't have to return a string ([7d0e85f](https://github.com/stevearc/dressing.nvim/commit/7d0e85f00b09a93e5583447b21db50342b71eadb))
* **fzf-lua:** pass prompt option to fzf ([fa73233](https://github.com/stevearc/dressing.nvim/commit/fa732334c50a38094399b5d29895bc57d73dc89f))
* hide deprecation notice when option not used ([#26](https://github.com/stevearc/dressing.nvim/issues/26)) ([96552c9](https://github.com/stevearc/dressing.nvim/commit/96552c9199dc4e169d1c54a21300365ffa483da9))
* **input:** adjust implementation to avoid bugs in prompt buffer ([#2](https://github.com/stevearc/dressing.nvim/issues/2)) ([189bbc6](https://github.com/stevearc/dressing.nvim/commit/189bbc6562c700ec64b80e0b3f5c823568c231ff))
* **input:** change the default_prompt to Input: ([2f8a001](https://github.com/stevearc/dressing.nvim/commit/2f8a001ae5751b6f32b87424566af23879e35602))
* **input:** close completion window more reliably ([7e6e962](https://github.com/stevearc/dressing.nvim/commit/7e6e962341cb11401057894e93aafe24e964303c))
* **input:** disable mini completion ([#38](https://github.com/stevearc/dressing.nvim/issues/38)) ([a476efd](https://github.com/stevearc/dressing.nvim/commit/a476efd3f372d6b5b0df431cac36911fb84c515e))
* **input:** Don't trigger autocmds when opening input modal ([#13](https://github.com/stevearc/dressing.nvim/issues/13)) ([d5eaf13](https://github.com/stevearc/dressing.nvim/commit/d5eaf13b803da8623b1fded4c94f6a7ee4751639))
* **input:** empty string is converted to nil ([a0196a4](https://github.com/stevearc/dressing.nvim/commit/a0196a49e49944f2db9cb09213741cf6a73e1f05))
* **input:** error on history_prev when no history ([fc790e4](https://github.com/stevearc/dressing.nvim/commit/fc790e426ae40a6c8364fd242f2974e0018d93a0))
* **input:** expand width to fit prompt & default ([f03962c](https://github.com/stevearc/dressing.nvim/commit/f03962c6170819300d703bd542fff4a01b8429e6))
* **input:** lua function completion ([96b09a0](https://github.com/stevearc/dressing.nvim/commit/96b09a0e3c7c457140303c796bd84f13cfd9dbc0))
* **input:** mode detection in special insert modes ([1f91d26](https://github.com/stevearc/dressing.nvim/commit/1f91d264bfda52488f6186a7c7c38227a99c6509))
* **input:** opening input while existing input is open ([4dc2ca3](https://github.com/stevearc/dressing.nvim/commit/4dc2ca3fff34dc4df8cb5135e5a9e09c90f77633))
* **input:** race condition with multiple prompts in quick succession ([6be518b](https://github.com/stevearc/dressing.nvim/commit/6be518ba4cd1ce8c15728884ba626442cfaf897c))
* **input:** Remove debug print from completion logic ([362cc2c](https://github.com/stevearc/dressing.nvim/commit/362cc2c54b10ebc95550aad093f4fe43f8e8578e))
* **input:** restore previous mode after leaving modal ([25b7262](https://github.com/stevearc/dressing.nvim/commit/25b72621af45b5f457382b9aded7ee6b1c80b427))
* **input:** set nowrap on window ([#28](https://github.com/stevearc/dressing.nvim/issues/28)) ([8c42b8f](https://github.com/stevearc/dressing.nvim/commit/8c42b8f854f9007abd2b572923b6ce757e26340d))
* minor tweaks to fix LSP type errors ([2f17eee](https://github.com/stevearc/dressing.nvim/commit/2f17eee4d7709dacfad2a28f35e2acfe9a6cb09d))
* only schedule_wrap when necessary ([#58](https://github.com/stevearc/dressing.nvim/issues/58)) ([232b6b3](https://github.com/stevearc/dressing.nvim/commit/232b6b3021e74d39bad0db55e6c2657746873b54))
* race condition produces broken state in input modal ([304d73f](https://github.com/stevearc/dressing.nvim/commit/304d73f037515eb172999759007840b4f4bedb20))
* re-add safety nil check ([8d19119](https://github.com/stevearc/dressing.nvim/commit/8d19119476484ad12d4ca1d25bc69dba97a11de0))
* remove defer_fn hack in fzf select (fix [#10](https://github.com/stevearc/dressing.nvim/issues/10)) ([0ad4d1e](https://github.com/stevearc/dressing.nvim/commit/0ad4d1e6b90f9c74dd95100271f2ad52b8c5f12d))
* replace defer_fn hack with redraw hack ([#18](https://github.com/stevearc/dressing.nvim/issues/18)) ([8e8f7e5](https://github.com/stevearc/dressing.nvim/commit/8e8f7e525941ee2080a39b98c1b1f5466a6ea187))
* restore cursor position after select ([b188b77](https://github.com/stevearc/dressing.nvim/commit/b188b7750c78c0dbe0c61d79d824673a53ff82db))
* restore normal mode and cursor position when exiting input ([7705013](https://github.com/stevearc/dressing.nvim/commit/770501336f9111b95eb2619c56fb208f3a20e067))
* sanitize newlines in entries and prompts ([#88](https://github.com/stevearc/dressing.nvim/issues/88)) ([55fd604](https://github.com/stevearc/dressing.nvim/commit/55fd604006e2859b829ac1e6a537cc3c39db3ff8))
* **select/telescope:** check for nil selection ([c84bf85](https://github.com/stevearc/dressing.nvim/commit/c84bf85c2832343c2bedc1920917cb7c9572cee3))
* **select:** off-by-one error in text highlighting ([4b677be](https://github.com/stevearc/dressing.nvim/commit/4b677be05609c8b454b744e86a612d988b41ba67))
* **select:** use original vim.ui.select if enabled is false ([4bd4167](https://github.com/stevearc/dressing.nvim/commit/4bd4167a77fa6d5feb16db40c5e34fd04da0d263))
* skipping config.theme when it's a table ([dbceda6](https://github.com/stevearc/dressing.nvim/commit/dbceda630344fc7b464dab983b6ba05a5a936476))
* stack overflow in telescope ([#36](https://github.com/stevearc/dressing.nvim/issues/36)) ([f68a91a](https://github.com/stevearc/dressing.nvim/commit/f68a91a2817f9c766a6ab8990a74a255c4cbb413))
* stop using vim.wo to set window options ([154f223](https://github.com/stevearc/dressing.nvim/commit/154f22393bf68043159a3503a6103b2e8a2b7d2d))
* telescope codeaction properly columnates and indexes client name ([#6](https://github.com/stevearc/dressing.nvim/issues/6)) ([b2406a0](https://github.com/stevearc/dressing.nvim/commit/b2406a0ea7b88177219ed475a14bc490a4653323))
* **telescope:** allow passing theme options ([c49854a](https://github.com/stevearc/dressing.nvim/commit/c49854aa5da470d720ba5ffc197f0e5494ec8826))
* update vim.ui.input to match nvim 0.9 API ([202bcf6](https://github.com/stevearc/dressing.nvim/commit/202bcf6bdb05ad833b2b2a869399a06699dd8b63))
* use schedule_wrap for select again ([#59](https://github.com/stevearc/dressing.nvim/issues/59)) ([#58](https://github.com/stevearc/dressing.nvim/issues/58)) ([9cdb3e0](https://github.com/stevearc/dressing.nvim/commit/9cdb3e0f0973447b940b35d3175dc780301de427))
* vim.ui.input can accept string as its first arg ([37349af](https://github.com/stevearc/dressing.nvim/commit/37349af9e152a2ce981e0fb3c71608a31dd56427))
* work around neovim open_win bug ([#15](https://github.com/stevearc/dressing.nvim/issues/15)) ([3f23266](https://github.com/stevearc/dressing.nvim/commit/3f23266f0c623415ab8051c6e05c35e0981025b5))


### cleanup

* Remove prompt buffer implementation for ui.input ([f487c89](https://github.com/stevearc/dressing.nvim/commit/f487c89b56e5fb4b86d50b5b136402089e0958c7))


### Code Refactoring

* deprecate telescope 'theme' option ([4542292](https://github.com/stevearc/dressing.nvim/commit/45422928547f25ed36e9394c9c55e9cc0f9e1b6d))
* drop support for Neovim 0.7 ([63cfd55](https://github.com/stevearc/dressing.nvim/commit/63cfd55eb2573bd37886866de98ae8b8c4e8604c))
* expose generic way to set window/buffer options in config ([#75](https://github.com/stevearc/dressing.nvim/issues/75)) ([c7eda5a](https://github.com/stevearc/dressing.nvim/commit/c7eda5a68e7d0f9dfa0669c1f2664bf813d845a1))
* use newer APIs for setting keymaps and autocmds ([47b95c1](https://github.com/stevearc/dressing.nvim/commit/47b95c1eab5902b8ea7216cda036e413d6ea5da5))
