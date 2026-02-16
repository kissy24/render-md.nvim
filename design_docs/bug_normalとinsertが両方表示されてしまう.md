# バグ報告: ノーマルモードとインサートモードの内容が同時に表示される

## 現象
Markdownファイルを開いた際、またはバッファを切り替えた際に、レンダリングされたアイコン等と、元のMarkdown記法（`###` や `*` など）が同時に表示されてしまう。

## 原因
`lua/render-md/init.lua` において、`conceallevel` の設定が `setup` 時（正確には `enable` 呼び出し時）に現在のバッファに対してのみ行われており、後から開いたMarkdownバッファに対して `conceallevel` が設定されていないため。

`BufEnter` 時に `render()` は呼ばれるが、`conceallevel` がデフォルトの `0` のままであるため、`conceal` 設定が効かずに元のテキストが表示されたまま、`virt_text`（インライン仮想テキスト）が表示されてしまっている。

## 対策
`BufEnter` 時のオートコマンド内で、`conceallevel` と `concealcursor` を適切に設定するように修正する。

### 修正箇所 (`lua/render-md/init.lua`)
`BufEnter` イベントのコールバック内で以下を実行するようにする：
- `vim.opt_local.conceallevel = 2`
- `vim.opt_local.concealcursor = "nc"`
