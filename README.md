# render-md.nvim

Neovim 内で Markdown ファイルを Notion のようなスタイルでリアルタイムにレンダリングするプラグインです。プレビューウィンドウを別に開くことなく、編集中のバッファ上で直接リッチな装飾を実現します。

![render-md-demo](https://user-images.githubusercontent.com/example/demo.png) *(画像はイメージです)*

## ✨ 特徴

- **リアルタイム・レンダリング**: タイピングに合わせて即座に装飾が更新されます。
- **Notionライクな装飾**:
  - 見出し（H1, H2, H3）の背景色とアイコン付与。
  - 箇条書きリストのドットをカスタムアイコン（•）に置換。
  - チェックボックス（タスクリスト）のアイコン化（☐, ☑）。
  - 引用ブロック（Blockquote）のサイドバー表示。
  - コードブロックの背景色変更と言語アイコンの表示。
  - インライン装飾（太字、斜体、打ち消し線）の記号を隠蔽（Conceal）。
- **Treesitter連携**: 高精度な構文解析に基づいた安定した表示。

## 📋 必要条件

- Neovim 0.9.0 以上
- `nvim-treesitter` (markdown および markdown_inline パーサー)
- [Nerd Fonts](https://www.nerdfonts.com/) (アイコン表示に推奨)

## 📦 インストール

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "your-username/render-md.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    config = function()
        require("render-md").setup({
            -- オプション設定（任意）
        })
    end
}
```

## ⚙️ 設定

`setup()` 関数にテーブルを渡すことで、ハイライト色やアイコンをカスタマイズできます。

```lua
require("render-md").setup({
    enabled = true,
    highlights = {
        h1 = { bg = "#3d2b1f", fg = "#ffaa88" },
        h2 = { bg = "#1f2b3d", fg = "#88aaff" },
        h3 = { bg = "#2b3d1f", fg = "#aaff88" },
        bullet = { fg = "#569cd6" },
        quote = { fg = "#6a9955" },
        checkbox = { fg = "#ce9178" },
        code = { bg = "#1e1e1e" },
    },
    icons = {
        h1 = "󰉫 ",
        h2 = "󰉫 ",
        h3 = "󰉫 ",
        bullet = "• ",
        unchecked = "☐ ",
        checked = "☑ ",
        quote = "▎",
        code = "󰨰 ",
    }
})
```

## ⌨️ コマンド

- `:RenderMDEnable` - レンダリングを有効にする
- `:RenderMDDisable` - レンダリングを無効にする
- `:RenderMDToggle` - レンダリングの有効/無効を切り替える

## 🛠️ トラブルシューティング

もし装飾（記号の隠蔽など）が正しく表示されない場合は、以下の設定を確認してください：

```vim
" 手動で設定する場合
set conceallevel=2
set concealcursor=nc
```

このプラグインは、`setup()` 実行時にこれらを自動的に設定します。
